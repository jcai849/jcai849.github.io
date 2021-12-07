---
title: A Review of pbdR
date: 2020-04-17
---

# Introduction {#sec:pbdr}

pbdR is a collection of packages allowing for distributed computing with R[@pbdBASEpackage].
The name is an acronym for the collection's purpose; Programming with Big Data in R.
It is introduced on it's main page with the following description:

> The "Programming with Big Data in R" project (pbdR) is a set of highly scalable
> R packages for distributed computing and profiling in data science.
> > Our packages include high performance, high-level interfaces to MPI, ZeroMQ,
> ScaLAPACK, NetCDF4, PAPI, and more. While these libraries shine brightest on
> large distributed systems, they also work rather well on small clusters and
> usually, surprisingly, even on a laptop with only two cores.
> > Winner of the Oak Ridge National Laboratory 2016 Significant Event Award for
> "Harnessing HPC Capability at OLCF with the R Language for Deep Data Science."
> OLCF is the Oak Ridge Leadership Computing Facility, which currently includes
> Summit, the most powerful computer system in the world.[@pbdR2012]

# Interface and Backend

The project seeks especially to serve minimal wrappers around the BLAS and LAPACK libraries along with their distributed derivatives, with the intention of introducing as little overhead as possible.
Standard R also uses routines from the library for most matrix operations, but suffers from numerous inefficiencies relating to the structure of the language; for example, copies of all objects being manipulated will be typically be created, often having devastating performance aspects unless specific functions are used for linear algebra operations, as discussed in [@schmidt2017programming] (e.g., `crossprod(X)`{.R} instead of `t(X) %*% X`{.R})

Distributed linear algebra operations in pbdR depend further on the ScaLAPACK library, which can be provided through the pbdSLAP package [@Chen2012pbdSLAPpackage].

The principal interface for direct distributed computations is the pbdMPI package, which presents a simplified API to MPI through R [@Chen2012pbdMPIpackage].
All major MPI libraries are supported, but the project tends to make use of openMPI in explanatory documentation.
A very important consideration that isn't immediately clear  is that pbdMPI can only be used in batch mode through MPI, rather than any interactive option as in Rmpi [@yu02:_rmpi].

The actual manipulation of distributed matrices is enabled through the pbdDMAT package, which offers S4 classes encapsulating distributed matrices [@pbdDMATpackage].
These are specialised for dense matrices through the `ddmatrix`{.R} class, though the project offers some support for other matrices.
The `ddmatrix`{.R} class has nearly all of the standard matrix generics implemented for it, with nearly identical syntax for all.

# Package Interaction

The packages can be made to interact directly, for example with pbdDMAT constructing and performing basic manipulations on distributed matrices, and pbdMPI being used to perform further fine-tuned processing through communicating results across nodes manually, taking advantage of the persistence of objects at nodes through MPI.

# pbdR in Practice

The package is geared heavily towards matrix operations in a statistical programming language, so a test of it's capabilities would quite reasonably involve statistical linear algebra.
An example non-trivial routine is that of generating data, to test randomisation capability, then fitting a generalised linear model to the data through iteratively reweighted least squares.
In this way, not only are the basic algebraic qualities considered, but communication over iteration on distributed objects is tested.

To work comparatively, a simple working local-only version of the algorithm is produced in [@lst:local-rwls].

```{#lst:local-rwls .R caption="Local GLM with RWLS"}
set.seed(1234)
# Generate the data

n <- 1000
B <- matrix(c(1,3))
x0 <- rep(1, n)
x1 <- rnorm(n, 0, 1)
X <- cbind(x0, x1)
p <- 1 / (1 + exp(- X %*% B))
y <- rbinom(n, 1, p)

# Base comparison
#glm(y ~ x1, family = "binomial")

# RWLS as Newton-Raphson for GLM (logistic regression here)

logReg <- function(X, y, maxIter=80, tolerance=0.01){
	pr <- function(X, B){
		1 / (1 + exp(-X  %*% B))
	}
	##
	weights <- function(X, B, y){
		diag(as.vector(pr(X, B)))
	}
	##
	oldB <- matrix(c(Inf,Inf))
	newB <- matrix(c(0, 0))
	nIter <- 0
	while (colSums((newB - oldB)^2) > tolerance &&
	       nIter < maxIter) {
		oldB <- newB
	## N-R as RWLS
		W <- weights(X, oldB, y)
		hessian <- - t(X) %*% W %*% X
		z <- X %*% oldB + solve(W) %*% (y - pr(X, oldB))
		newB <- solve(-hessian) %*% crossprod(X, W %*% z)
	##
		nIter <- nIter + 1
	}
	newB
}

print(logReg(X, y, tolerance=1E-6, maxIter=100))
```

It outputs a $\hat{\beta}$ matrix after several seconds of computation.

Were pbdDMAT to function transparently as regular matrices, as the package README implies, then all that would be required to convert a local algorithm to distributed would be to prefix a `dd` to every `matrix()`{.R} call, and bracket the program with a template as per [@lst:bracket].

```{#lst:bracket .R caption="Idealised Common Wrap for Local to Distributed Matrices"}
suppressMessages(library(pbdDMAT))
init.grid()

# program code with `dd` prefixed to every `matrix` call

finalize()
```

This is the form of transparency offered by packages such as *parallel*, *foreach*, or *sparklyr* in relation to dplyr.
The program would then be written to disk, then executed, for example with the following:

```{.bash}
mpirun -np <# of cores> Rscript <script name>
```

The program halts however, as forms of matrix creation other than through explicit `matrix()`{.R} calls are not necessarily picked up by that process; `cbind`{.R} requires a second formation of a `ddmatrix`{.R}.
The first issue comes when performing conditional evaluation; predicates involving distributed matrices are themselves distributed matrices, and can't be mixed in logical evaluation with local predicates.

Turning local predicates to distributed matrices, then converting them all back to a local matrix for the loop to understand, finally results in a program run, however the results are still not accurate.
This is due to `diag()<-`{.R} assignment not having been implemented, so several further changes are necessary, including specifying return type of the diag matrix as a replacement.
The final working code of pbdDMAT GLM through RWLS is given in [@lst:dmat], with the code diff given in [@lst:diff].
Execution time was longer for the pbdR code on a dual-core laptop, however it is likely faster over a cluster.

```{#lst:dmat .R caption="pbdDMAT GLM with RWLS"}
suppressMessages(library(pbdDMAT))
init.grid()

set.seed(1234)
# Generate the data

n <- 1000
B <- ddmatrix(c(1,3))
x0 <- rep(1, n)
x1 <- rnorm(n, 0, 1)
X <- as.ddmatrix(cbind(x0, x1))
p <- 1 / (1 + exp(- X %*% B))
y <- ddmatrix(rbinom(n, 1, as.vector(p)))

# Base comparison
#glm(y ~ x1, family = "binomial")

# RWLS as Newton-Raphson for GLM (logistic regression here)

logReg <- function(X, y, maxIter=80, tolerance=0.01){
	pr <- function(X, B){
		1 / (1 + exp(-X  %*% B))
	}
	##
	weights <- function(X, B, y){
		diag(as.vector(pr(X, B)), type="ddmatrix")
	}
	##
	oldB <- ddmatrix(c(Inf,Inf))
	newB <- ddmatrix(c(0, 0))
	nIter <- ddmatrix(0)
	maxIter <- as.ddmatrix(maxIter)
	while (as.matrix(colSums((newB - oldB)^2) > tolerance &
	       nIter < maxIter)) {
		oldB <- newB
	## N-R as RWLS
		W <- weights(X, oldB, y)
		hessian <- - t(X) %*% W %*% X
		z <- X %*% oldB + solve(W) %*% (y - pr(X, oldB))
		newB <- solve(-hessian) %*% crossprod(X, W %*% z)
	##
		nIter <- nIter + 1
	}
	newB
}

print(logReg(X, y, tolerance=1E-6, maxIter=100))

finalize()
```

```{#lst:diff .diff caption="Diff between local and pbdR code"}
0a1,3
> suppressMessages(library(pbdDMAT))
> init.grid()
> 
5c8
< B <- matrix(c(1,3))
---
> B <- ddmatrix(c(1,3))
8c11
< X <- cbind(x0, x1)
---
> X <- as.ddmatrix(cbind(x0, x1))
10c13
< y <- rbinom(n, 1, p)
---
> y <- ddmatrix(rbinom(n, 1, as.vector(p)))
23c26
< 		diag(as.vector(pr(X, B)))
---
> 		diag(as.vector(pr(X, B)), type="ddmatrix")
26,30c29,34
< 	oldB <- matrix(c(Inf,Inf))
< 	newB <- matrix(c(0, 0))
< 	nIter <- 0
< 	while (colSums((newB - oldB)^2) > tolerance &&
< 	       nIter < maxIter) {
---
> 	oldB <- ddmatrix(c(Inf,Inf))
> 	newB <- ddmatrix(c(0, 0))
> 	nIter <- ddmatrix(0)
> 	maxIter <- as.ddmatrix(maxIter)
> 	while (as.matrix(colSums((newB - oldB)^2) > tolerance &
> 	       nIter < maxIter)) {
43a48,49
> 
> finalize()
```

It is worth noting that options for optimisation and tuning are far more extensive than those utilised in this example, including the capacity to set grid parameters, blocking factors, and BLACS contexts, among others.

# Setup

The setup for pbdR is simple, being no more than a CRAN installation, but a well tuned environment, which is the main purpose for using the package in the first place, requires BLAS, LAPACK and derivatives, a parallel file system with data in an appropriate format such as HDF5, and a standard MPI library. Much of
the pain of setup is ameliorated with a docker container, provided by the project.
