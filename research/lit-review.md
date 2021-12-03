---
title: Literature Review
date: 2021-02-17
---

# Prose Form

## Introduction

Statistics is concerned with the analysis of datasets, which are continually growing bigger, and at a faster rate; the global datasphere is expected to grow from 33 zettabytes in 2018 to 175 zettabytes by 2025[@rydning2018digitization].

The scale of this growth is staggering, and continues to outpace attempts to engage meaningfully with such large datasets.
By one measure, information storage capacity has grown at a compound annual rate of 23% per capita over recent decades[@hilbert2011world].
In spite of such massive growths in storage capacity, they are far outstripped by computational capacity over time [@fontana2018moore].
Specifically, the number of components comprising an integrated circuit for computer processing have been exponentially increasing, with an additional exponential decrease in their cost[@moore1975progress].
This observation, known as Moore's Law, has been the root cause for much of computational advancement over the past half-century.
The corresponding law for computer storage posits increase in bit density of storage media along with corresponding decreases in price, which has been found to track lower than expected by Moore's law metrics.
Such differentials, between the generation of data, computational capacity for data processing, and constraints on data storage, have forced new techniques in computing for the analysis of large-scale data.

The architecture of a computer further constrains the required approach for analysis of big data.
Most general-purpose PC's are modelled by a random-access stored-program machine, wherein a program and data are stored in registers, and data must move in and out of registers to a processing element, most commonly a Central Processing Unit (CPU).
The movement takes at least one cycle of a computer's clock, thereby leading to larger processing time for larger data.

Reality dictates many different forms of data storage, with a Memory Hierarchy ranking different forms of computer storage based on their response times[@toy1986computer].
The volatility of memory (whether or not it persists with no power) and the expense of faster storage forms dictates the design of commodity computers.
An example of a standard build is given by the Dell Optiplex 5080, with 16Gb of Random Access Memory (RAM) for fast main memory, to be used as a program data store; and a 256Gb Solid State Drive (SSD) for slow long-term disk storage[@cornell2021standardcomp].
For reasonable speed when accessing data, a program would prioritise main memory over disk storage - something not always possible when dataset size exceeds memory capacity, larger-than-memory datasets being a central issue in big data.
A program that is primarily slowed by data movement is described as I/O-bound, or memory-bound.
Much of the issue in modelling large data is the I/O-bound nature of much statistical computation.

The complement to I/O-bound computation is computation-bound, wherein the speed (or lack thereof) is determined primarily through the performance of the processing unit.
This is less significant in large-scale applications than memory-bound, but remains an important design consideration when the number of computations scale with the dataset size in any nontrivial algorithm with greater than $\mathcal{O}(1)$ complexity.

The solution to both memory- and computation-bound problems has largely been that of using more hardware; more memory, and more CPU cores.
Even with this in place, more complex software is required to manage the more complex systems.
As an example, with additional CPU cores, constructs such as multithreading are used to perform processing across multiple CPU cores simultaneously (in parallel).

The means for writing software for large-scale data is typically through the use of a structured, high-level programming language.
Of the myriad programming languages, the most widespread language used for statistics is R.
As of 2021, R increased in popularity to rank 9th in the TIOBE index.
R also has a special relevance for this proposal, having been initially developed at the University of Auckland by Ross Ihaka and Robert Gentleman in 1991[@ihaka1996r].

Major developments in contemporary statistical computing are typically published alongside R code implementation, usually in the form of an R package, which is a mechanism for extending R and sharing functions.
As of March 2021, the Comprehensive R Archive Network (CRAN) hosts over 17000 available packages[@team20:_r].
Several of these packages are oriented towards managing large datasets, and will be assessed in [@sec:local; @sec:dist] below.
This project aims to develop an R package that provides a means for writing software to analyse very large data on clusters consisting of multiple general-purpose computers.

## Parallelism as a Strategy {#sec:parallel}

The central strategy for manipulating large datasets, from which most other patterns derive, is parallelisation.
To parallelise is to engage in many computations simultaneously - this typically takes the form of either task parallelism, wherein tasks are distributed across different processors; data parallelism, where the same task operates on different pieces of data across different processors; or some mix of the two.

Parallelisation of a computational process can potentially offer speedups proportional to the number of processors available to take on work, and with recent improvements in multiprocessor hardware, the number of processors available is increasing over time.
Most general-purpose personal computers produced in the past 5 years have multiple processor cores to enable parallel computation.

Parallelism can afford major speedups, albeit with certain limitations.
Amdahl's law, formulated in 1967, aims to capture the speedup limitations, with a model derived from the argument given below in [@eqn:amdahlsform][@amdahl1967law; @gustafson1988law]:

$$
	\textrm{Speedup} = \frac{1}{s+\frac{p}{N}}
$$ {#eqn:amdahlsform}

Where,

- $Speedup$ total speedup of whole task
- $s$ time spend by serial processor on inherently serial part of program
- $p$ time spent by serial processor on parallelisable part of program
- $N$ number of processors

The implication is that speedup of an entire task when parallelised is granted only through the portion of the task that is otherwise constrained by singular system resources, at the proportion of execution time spent in that task.
Thus a measure of skepticism is contained in Amdahl's argument, with many tasks predicted to show no benefit to parallelise - and in reality, some likely to slow down with increased overhead given in parallelisation.

The major response to the skepticism of Amdahl's law is given by Gustafson's law, generated from timing results in a highly parallelised system.
Gustafson's law presents a scaled speedup as per [@eqn:gustafsonsform]

$$
	\textrm{Scaled speedup} = s' + p'N = N + (1-N)s'
$$ {#eqn:gustafsonsform}

Where,

- $s'$ serial time spent on the parallel system
- $p'$ parallel time spent on the parallel system

This law implies far higher potential parallel speedup, varying linearly with the number of processors.

An example of an ideal task for parallelisation is the category of embarassingly parallel workload.
Such a problem is one where the separation into parallel tasks is trivial, such as performing the same operation over a dataset independently[@foster1995parallel].
Many problems in statistics fall into this category, such as tabulation, monte-carlo simulation and many matrix manipulation tasks.

## Local Solutions {#sec:local}

While not specifically engaging with larger-than-memory data, a number of packages take advantage of various parallel strategies in order to process large datasets efficiently.
**multicore** is one such package, now subsumed into the **parallel** package, that grants functions that can make direct use of multiprocessor systems, thereby reducing the processing time in proportionality to the number of processors available on the system.

**data.table** also makes use of multi-processor systems, with many operations involving threading in order to rapidly perform operations on it's dataframe equivalent, the data.table.

In spite of all of these potential solutions, a major constraint remains in that only a single machine is used.
As long as there is only one machine available, bottlenecks form and no redundancy protection is offered in real-time in the event of a crash or power outage.

The first steps typically taken to manage larger-than-memory data is to shift part of the data into secondary storage, which generally possesses significantly more space than main memory.

This is the approach taken by the **disk.frame** package, developed by Dai ZJ.
**disk.frame** provides an eponymously named dataframe replacement class, which is able to represent a dataset far larger than RAM, constrained now only by disk size[@zj20].

The mechanism of disk.frame is introduced on it's homepage with the
following explanation:

> {disk.frame} works by breaking large datasets into smaller
> individual chunks and storing the chunks in fst files inside a
> folder.
> Each chunk is a fst file containing a data.frame/data.table.
> One can construct the original large dataset by loading all the
> chunks into RAM and row-bind all the chunks into one large
> data.frame.
> Of course, in practice this isn't always possible; hence
> why we store them as smaller individual chunks.
> {disk.frame} makes it easy to manipulate the underlying chunks by
> implementing dplyr functions/verbs and other convenient functions
> (e.g. the `cmap(a.disk.frame, fn, lazy = F)`{.R} function which
> applies the function fn to each chunk of a.disk.frame in parallel).
> So that {disk.frame} can be manipulated in a similar fashion to
> in-memory data.frames.

It works through two main principles: chunking, and an array of methods taking advantage of data.frame generics, including **dplyr** and **data.table** functions.

Another component that isn't mentioned in the explanation, but is crucial to performance, is the parallelisation offered transparently by the package.

disk.frames are actually references to numbered `fst` files in a folder, with each file serving as a chunk.

This is made use of through manipulation of each chunk separately, sparing RAM from dealing with a single monolithic file[@zj19:_inges_data].

Fst is a means of serialising dataframes, as an alternative to RDS files[@klik19].

It makes use of an extremely fast compression algorithm developed at facebook.

Functions are usually mapped over chunks using some functional, but more complex functions such as those implementing a glm require custom solutions; as an example the direct modelling function of `dfglm()`{.R}{.R} is implemented to allow for fitting glms to the data.

From inspection of the source code, the function is a utility wrapper for streaming disk.frame data by default into bigglm, a biglm derivative.

For grouped or aggregated functions, there is more complexity involved, due to the chunked nature of disk.frame.

When functions are applied, they are by default applied to each chunk.

If groups don't correspond injectively to chunks, then the syntactic chunk-wise summaries and their derivatives may not correspond to the semantic group-wise summaries expected.

For example, summarising the median is performed by using a median-of-medians method; finding the overall median of all chunks' respective medians.

Therefore, computing grouped medians in disk.frame result in estimates only --- this is also true of other software, such as spark, as noted in [@zj19:_group_by].

For parallelisation, future is used as the backend package, with most function mappings on chunks making use of `future::future_lapply()`{.R}{.R} to have each chunk mapped with the intended function in parallel.


future is initialised with access to cores through the wrapper function, `setup_disk.frame()`{.R}{.R} [@zj19:_key].

This sets up the correct number of workers, with the minimum of workers and chunks being processed in parallel.

An important aspect to parallelisation through future is that, for purposes of cross-platform compatibility, new R processes are started for each worker[@zj19:_using].

Each process will possess it's own environment, and disk.frame makes use of future's detection capabilities to capture external variables referred to in calls, and send them to each worker.

The strategy taken by **disk.frame** has several inherent limitations, however.
**disk.frame** allows only embarassingly parallel operations for custom operations as part of a split-apply-combine (MapReduce) pattern.

While there may theoretically be future provision for non-embarrassingly parallel operations, a significant limitation to real-time operation is the massive slowdown brought by the data movement from disk to RAM and back.

# Distributed Computing as a Strategy {#sec:dist}

The specs of a single contemporary commodity computer are higher than those that were used in the Apollo lunar landing, yet the management of large datasets still creates major issues, driven by a simple lack of  capacity to hold them in memory.
Supercomputers can surmount this by holding orders of magnitude higher memory, though only a few organisations or individuals can bear the financial costs of purchasing and maintaining a supercomputer.

In a similar form, cloud computing is not a universal solution, owing to expense, security issues, and data transportation problems.
Despite this, systems rivalling supercomputers can be formed through combining many commodity computers.
An amusing illustration of this was given in 2004, when a flash mob connected hundreds of laptops to attempt running the linpack benchmark, achieving 180 gigaflops in processing output[@perry2004flashcomp].

The combination of multiple independent computers to form one cohesive computing system forms part of what is known as distributed computing.
More serious efforts to connect multiple commodity computers into a larger computational system is now standard, with software such as Hadoop and Spark being commonplace in large companies for the purpose of creating distributed systems.

Distributed systems make possible the real-time manipulation of datasets larger than a single computer's RAM, by splitting up data and holding it in the RAM of multiple computers.
A factor strongly serving in favour of distributed computing is that commodity hardware exists in large quantities in most offices, oftentimes completely unused.
This means that many organisations already have the necessary base infrastructure to create a distributed system, likely only requiring some software and configuration to set it all up.
Beyond the benefit of pre-existing infrastructure, a major feature commonly offered by distributed systems, and lacking in high-powered single computer systems, is that of fault tolerance - when one computer goes down, as does happen, another computer in the system had redundant copies of much of the information of the crashed computer, and computation can resume with very little inconvenience.
A single computer, even very high-powered, doesn't usually offer fault-tolerance to this degree.

All of the packages examined the above [@sec:local] have no immediate capability to create a distributed system, and have all of the ease-of-use benefits and all of the drawbacks as discussed.

# Distributed Large-Scale Computing

R does have some well-established packages used for distributed large-scale computing.
Of these, the **parallel** package is contained in the standard R image, and encapsulates **SNOW** (Simple Network Of Workstations), which provides support for distributed computing over a simple network of compputers.
The general architecture of **SNOW** makes use of a master process that holds the data and launches the cluster, pushing the data to worker processes that operate upon it and return the results to the master.
**SNOW** makes use of several different communications mechanisms, including sockets or the greater MPI distributed computing library.
Some shortcomings of the described architecture is the difficulty of persisting data, meaning the expense of data transportation every time operations are requested by the master process.
In addition, as the data must originate from the master (barring generated data etc.), the master's memory size serves as a bottleneck for the whole system.

The **pbdR** (programming with big data in R) project provides persistent data, with the **pbdDMAT** (programming with big data Distributed MATrices) package offering a user-friendly distributed matrix class to program with over a distributed system.
It is introduced on it's main page with the
following description:

> The "Programming with Big Data in R" project (pbdR) is a set of highly scalable
> R packages for distributed computing and profiling in data science.
> Our packages include high performance, high-level interfaces to MPI, ZeroMQ,
> ScaLAPACK, NetCDF4, PAPI, and more.
> While these libraries shine brightest on
> large distributed systems, they also work rather well on small clusters and
> usually, surprisingly, even on a laptop with only two cores.
> Winner of the Oak Ridge National Laboratory 2016 Significant Event Award for
> "Harnessing HPC Capability at OLCF with the R Language for Deep Data Science."
> OLCF is the Oak Ridge Leadership Computing Facility, which currently includes
> Summit, the most powerful computer system in the world.[@pbdR2012]

The project seeks especially to serve minimal wrappers around the BLAS and LAPACK libraries along with their distributed derivatives, with the intention of introducing as little overhead as possible.
Standard R also uses routines from the library for most matrix operations, but suffers from numerous inefficiencies relating to the structure of the language; for example, copies of all objects being manipulated will be typically be created, often having devastating performance aspects unless specific functions are used for linear
algebra operations, as discussed in [@schmidt2017programming] (e.g., `crossprod(X)`{.R} instead of `t(X) %*% X`{.R})

Distributed linear algebra operations in pbdR depend further on the ScaLAPACK library, which can be provided through the pbdSLAP package [@Chen2012pbdSLAPpackage].
The principal interface for direct distributed computations is the pbdMPI package, which presents a simplified API to MPI through R [@Chen2012pbdMPIpackage].
All major MPI libraries are supported, but the project tends to make use of openMPI in explanatory documentation. A very
important consideration that isn't immediately clear  is that pbdMPI can only be used in batch mode through MPI, rather than any interactive option as in Rmpi [@yu02:_rmpi].

The actual manipulation of distributed matrices is enabled through the pbdDMAT package, which offers S4 classes encapsulating distributed matrices [@pbdDMATpackage].
These are specialised for dense matrices through the `ddmatrix` class, though the project offers some support for other matrices.
The `ddmatrix` class has nearly all of the standard matrix generics implemented for it, with nearly identical syntax for all.

The package is geared heavily towards matrix operations in a statistical programming language, so a test of it's capabilities would quite reasonably involve statistical linear algebra.
An example non-trivial routine is that of generating data, to test randomisation capability, then fitting a generalised linear model to the data through iteratively reweighted least squares.
In this way, not only are the basic algebraic qualities considered, but communication over iteration on distributed objects is tested.

To work comparatively, a simple working local-only version of the algorithm is produced in listing [@lst:local-rwls].

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

Were pbdDMAT matrices to function perfectly transparently as regular matrices, then all that would be required to convert a local algorithm to distributed would be to prefix a `dd` to every `matrix` call, and bracket the program with a template as per listing [@lst:bracket].

```{#lst:bracket .R caption="Idealised Common Wrap for Local to Distributed Matrices"}
suppressMessages(library(pbdDMAT))
init.grid()

# program code with `dd` prefixed to every `matrix` call

finalize()
```

The program halts however, as forms of matrix creation other than through explicit `matrix()`{.R}{.R} calls are not necessarily picked up by that process; `cbind` requires a second formation of a `ddmatrix`.

The first issue comes when performing conditional evaluation; predicates involving distributed matrices are themselves distributed matrices, and can't be mixed in logical evaluation with local predicates.

Turning local predicates to distributed matrices, then converting them all back to a local matrix for the loop to understand, finally results in a program run, however the results are still not accurate.

This is due to `diag()<-`{.R} assignment not having been implemented, so several further changes are necessary, including specifying return type of the diag matrix as a replacement.

This serves to outline the difficulty of complete distributed transparency.

The final working code of pbdDMAT GLM through RWLS is given in listing [@lst:dmat]

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

Decidedly more user-friendly is the **sparklyr** package, which meshes **dplyr** syntax with a **Spark** backend.
Simple analyses are made very simple (assuming a well-configured and already running **Spark** instance), but custom iterative models are extremely difficult to create through the package in spite of **Spark's** support for it.

Given that iteration is cited by a principal author of Spark as a motivating factor in it's development when compared to Hadoop, it is reasonable to consider whether the most popular R interface to Spark, sparklyr, has support for iteration[@zaharia2010spark][@luraschi20].
One immediate hesitation to the suitability of sparklyr to iteration is the syntactic rooting in dplyr; dplyr is a "Grammar of Data Manipulation" and part of the tidyverse, which in turn is an ecosystem of packages with a shared philosophy[@wickham2019welcome][@wickham2016r].
The promoted paradigm is functional in nature, with iteration using for loops in R being described as "not as important" as in other languages; map functions from the tidyverse purrr package are instead promoted as providing greater abstraction and taking much less time to solve iteration problems.
Maps do provide a simple abstraction for function application over elements in a collection, similar to internal iterators, however they offer no control over the form of traversal, and most importantly, lack mutable state between iterations that standard loops or generators allow[@cousineau1998functional].

A common functional strategy for handling a changing state is to make use of recursion, with tail-recursive functions specifically referred to as a form of iteration in [@abelson1996structure].
Reliance on recursion for iteration is naively non-optimal in R however, as it lacks tail-call elimination and call stack optimisations[@rcore2020lang]; at present the elements for efficient, idiomatic functional iteration are not present in R, given that it is not as functional a language as the tidyverse philosophy considers it to be, and sparklyr's attachment to the the ecosystem prevents a cohesive model of iteration until said elements are in place.

Iteration takes place in Spark through caching results in memory, allowing faster access speed and decreased data movement than MapReduce[@zaharia2010spark].
sparklyr can use this functionality through the `tbl_cache()`{.R} function to cache Spark dataframes in memory, as well as caching upon import with `memory=TRUE` as a formal parameter to `sdf_copy_to()`{.R}.
Iteration can also make use of persisting Spark Dataframes to memory, forcing evaluation then caching; performed in sparklyr through `sdf_persist()`{.R}.

An important aspect of consideration is that sparklyr methods for dplyr generics execute through a translation of the formal parameters to Spark SQL.
This is particularly relevant in that separate Spark Data Frames can't be accessed together as in a multivariable function.
In addition, very R-specific functions such as those from the **stats** and **matrix** core libraries are not able to be evaluated, as there is no Spark SQL cognate for them.

Canned models are the only option for most users, due to **sparklyr's** reliance on Spark SQL rather than the Spark core API made available through the official **SparkR** interface.

sparklyr is excellent when used for what it is designed for.
Iteration, in the form of an iterated function, does not appear to be part of this design.

Furthermore, all references to "iteration" in the primary sparklyr literature refer either to the iteration inherent in the inbuilt Spark ML functions, or the "wrangle-visualise-model" process popularised by Hadley Wickham[@luraschi2019mastering; @wickham2016r].
None of such references connect with iterated functions.

## Other Systems

In the search for a distributed system for statistics, the world outside of R is not entirely barren.
The central issue with non-R distributed systems is that their focus is very obviously not statistics, and this shows in the level of support the platforms provide for statistical purposes.

The classical distributed system for high-performance computing is MPI.
R actually has a high-level interface to MPI through the **rmpi** package.
This package is excellent, but extremely low-level, offering little more than wrappers around MPI functions.
For the statistician who just wants to implement a model for a large dataset, such concern with minutiae is prohibitive.

Hadoop and Spark are two closely related systems which were mentioned earlier.

Apache Hadoop is a collection of utilities that facilitates cluster computing.

Jobs can be sent for parallel processing on the cluster directly to the utilities using .jar files, "streamed" using any executable file, or accessed through language-specific APIs.

The project began in 2006, by Doug Cutting, a Yahoo employee, and Mike Cafarella.

The inspiration for the project was a paper from Google describing the Google File System (described in [@ghemawat2003google]), which was followed by another Google paper detailing the MapReduce programming model, [@dean2004mapreduce].

Hadoop consists of a file-store component, known as Hadoop Distributed File System (HDFS), and a processing component, known as MapReduce.

In operation, Hadoop splits files into blocks, then distributes them across nodes in a cluster (HDFS), where they are then processed by the node in parallel (MapReduce).
This creates the advantage of data locality, wherein data is processed by the node they exist in.

Hadoop has seen extensive industrial use as the premier big data platform upon it's release.

In recent years it has been overshadowed by Spark, due to the greater speed gains offered by Spark for many problem sets.

Spark was developed with the shortcomings of Hadoop in mind;  Much of it's definition is in relation to Hadoop, which it intended to improve upon in terms of speed and usability for certain tasks[@zaharia2010spark].

It's fundamental operating concept is the Resiliant Distributed Dataset (RDD), which is immutable, and generated through external data, as well as actions and transformations on prior RDD's.

The RDD interface is exposed through an API in various languages, including R, however it appears to be abandoned to some degree, having removed from the CRAN repository at 2020-07-10 due to failing checks.

Spark requires a distributed storage system, as well as a cluster manager; both can be provided by Hadoop, among others.

Spark is known for possessing a fairly user-friendly API, intended to improve upon the MapReduce interface.

Another major selling point for Spark is the libraries available that have pre-made functions for RDD's, including many iterative algorithms.

The availability of broadcast variables and accumulators allow for custom iterative programming.

Spark has seen major use since it's introduction, with effectively all major big data companies having some use of Spark.

In the python world, the closest match to a high-level distributed system that could have statistical application is given by the python library **dask**[@rocklin2015dask].
**dask** offers dynamic task scheduling through a central task graph, as well as a set of classes that encapsulate standard data manipulation structures such as NumPy arrays and Pandas dataframes.

The main difference is that the **dask** classes take advantage of the task scheduling, including online persistence across multiple nodes.
**dask** is a large and mature library, catering to many use-cases, and exists largely in the Pythonic "Machine Learning" culture in comparison to the R "Statistics" culture.
Accordingly, the focus is more tuned to the Python software developer putting existing ML models into a large-scale capacity.
Of all the distributed systems assessed so far, **dask** comes the closest to what an ideal platform would look like for a statistician, but it misses out on the statistical ecosystem of R, provides only a few select classes, and is tied entirely to the structure of the task graph.

# A Survey of Large-Scale Platform Features

## Introduction {#sec:intro}

To guide the development of the platform, desirable features are drawn from
existing platforms; inferred as logical extensions; and arrived at through
identification of needs.
Some features are mutually exclusive, others are
suggestive of each other, but are worth considering and contrasting their
merits.

## Feature List {#sec:feature-list}

A list of features and their descriptions follows:

Distributed Computation
: The ability to spread computation and data over separate computers.
  The value of distributed computing is well recognised for large-scale computing, in the increased capacity for processing, memory, and storage.
  Distributed computing typically gains latency speedup through parallel processing; both Amdahl's law and Gustafson's law give theoretical speedups for parallel jobs [@amdahl1967law; @gustafson1988law].
  In addition, each node typically adds more working memory to the distributed system, allowing for larger datasets to be manipulated in-memory.
  For exceedingly large datasets, the benefits of distributed file systems commonly allow for resiliant storage, with well-regarded examples including HDFS and the Google File System it is based upon [@shvachko2010hadoop; @ghemawat2003google].

Evaluation of User-Specified Code
: The ability to make use of user-specified code in processing.
  Most R packages for large-scale computing interact well with arbitrary code, however they typically have some limitations, such as an inability to recognise global variables, as is the case with sparklyr and to a lesser extent future [@sparklyr2020limitations; @microsoft20].

Native Support for Iteration
: The ability to process user-specified code involving iteration over the whole dataset natively, keeping results in memory between iterations.
  This reflects the inherently iterative nature of many statistical algorithms.
  Furthermore, this shouldn't initiate a new job or process for every new iteration.
  This is seen as important enough that it serves as a major motivating factor behind Spark's development, overcoming a perceived major deficiency of Hadoop by Spark's developers [@zaharia2010spark].

Object Persistence at Nodes
: The ability to retain objects in-memory at their point of processing.
  The standard motivation for such a feature revolves around a reduction in data movement, which serves to slow down processing enormously through forcing programs to be I/O bound.
  In-memory persistence is closely related to the capacity for iterative code evaluation in a distributed system, and was similarly referenced by the Spark developers as an apparent benefit of Spark[@zaharia2010spark].

Support for Distributed File Systems
: Capacity to work with data and computation on distributed file systems, with a particular target of Hadoop Distributed File System (HDFS).
  As a well-established distributed file system, HDFS is targeted by a number of R packages, as well as serving as a file system base for other platforms such as spark [@analytics:_rhadoop_wiki; @deltarho:_rhipe; @urbanek20; @zaharia2016apache].
  HDFS offers several features that make it particularly attractive as a filesystem for a large-scale statistical analysis;
  being distributed and capable of running on commodity hardware allows for truly big data analysis.
  In addition, the system is built to be resiliant to hardware failure, so long-running analyses aren't cut short or forced to revert to a checkpoint because of singular component failure [@shvachko2010hadoop].

Ease of Setup
: Is setup suitable for a computationally-focussed statistician, or does it require a system administrator?
  At it's base, R is a statistical programming language [@rcore2020intro].
  The particular skills of statisticians seldom correspond to the those requisite of system administration, with such a focus unlikely to compete successfully with their main research.
  Ease of deployment can determine a platform's success, with such a feature being one of the many motivations for the use and development of tools such as docker in recent years.
  The easiest possible setup would be a regular `install.packages()`{.R}, with no more than several lines specifying the platform configuration.

Inter-Node Communication
: Can any pair of nodes communicate with each other, or do they only report to a master node?
  While many tasks process efficiently within a standard master-slave architecture, and inter-node communication is inherently expensive, there is still a large class of tasks that benefit from inter-node communication[@walker1996mpi]; particularly graph-based statistical methods.

Interactive Usage
: The ability to make use of the package in an interactive R session, without mandatory batch execution.
  A major benefit of R as being interpreted is the availability of the REPL.
  The benefits of interactivity stemming from a REPL are well-documented, most notably aiding debugging [@mccarthy1978history].
  For statistical analysese in particular, interactive analyses play a major role in exploratory data analysis, wherein insights can be tested and arrived at rapidly with an interactive session.

Backend Decoupling
: The implementation is maintained entirely separately to the interface.
  This is standard in most of the performant parallel R systems as described by [@eddelbuettel2019parallel], including foreach as a key example[@microsoft20].
  As a software pattern, this is a case of separation of concerns, described in detail by [@dijkstra1982role].
  Such a pattern fosters modularity and allows for a broader range of backends to be made use of, maximising the uptake of the platform.
  The ability for a system to adhere to a similar interface despite changes in internal behaviour is additionally useful for the sake of referential transparency, which prevents the need to rewrite programs upon making changes, as well as for human-computer interaction considerations [@sondergaard1990Rtda; @norman2013design].
  For example, the foreach package can change parallel adaptors in a single line of setup, without needing any changes made in the code referencing future, despite making use of a different internal interface [@weston19:_using].

Evaluation of Arbitrary Classes
: Any class, including user-defined classes, can be used in evaluation.
  There is proven value in rich user-defined objects, with the weight of much of the object-oriented programming paradigm serving to further that point [@dahl2004simula].
  Conversely, many major packages limit themselves through provisioning only a few classes, such as pbdDMAT with distributed matrices, or the tidyverse and it's derivatives including sparklyr with "tibbles" [@pbdDMATpackage; @wickham2019welcome]

Package-specific API
: The platform is primarily explicitly programmed against at a package-specific interface.
  This is in contrast to packages mostly providing methods which overload standard generics or language structure;
  at a loss of general transparency, direct API's can ensure greater encapsulation and a closer mapping of code with the underlying implementation, thus potentially resulting in performance gains [@bierhoff2009api].
  An example in R is the interface to the foreach package not overloading the existing for-loop syntax in R, but defining it's own specific interface [@microsoft20].

Methods for Standard Generics
: The platform is primarily programmed against using a polymorphic interface, with the package methods taking advantage of common generics.
  pbdDMAT takes this approach, as well as bigmemory, in providing matrix-like classes which are operated upon using standard matrix generics [@pbdDMATpackage; @kane13:bigmemory].

Methods for dplyr Generics
: The platform makes use of dplyr functions as the primary set of generics to program over.
  Using a dplyr interface is a common trend in several R packages including sparklyr, disk.frame, and many database interfaces [@luraschi20; @zj20].
  Such an interface is claimed by the dplyr creators to aid beginners through being simple to remember [@wickham2019welcome].
  In this way, it may serve to ease the learning curve for the platform.

## Comparison Table {#sec:comp-tab}

| Feature                              | RHadoop        | sparklyr         | pbdR             | disk.frame  | foreach      |
|--------------------------------------|----------------|------------------|------------------|-------------|--------------|
| Distributed Computation              | yes[^1x1]      | yes[^1x2]        | yes[^1x3]        | no          | yes[^0x5]    |
| Evaluation of User-Specified Code    | yes[^2x1]      | mostly[^2x2]     | mostly[^2x3]     | some[^2x4]  | mostly[^2x5] |
| Native Support for Iteration         | no             | no[^3x2]         | yes              | no[^3x4]    | no[^3x5]     |
| Object Persistence at Nodes          | no             | yes[^4x2]        | yes              | NA          | no           |
| Support for Distributed File Systems | yes[^5x1]      | yes[^5x2]        | no               | no          | yes[^5x5]    |
| Ease of Setup                        | mediocre[^6x1] | acceptable[^6x3] | acceptable[^6x3] | simple      | simple       |
| Inter-Node Communication             | no             | no               | yes[^7x3]        | NA          | no           |
| Interactive Usage                    | yes            | yes              | no               | yes         | yes          |
| Backend Decoupling                   | no[^9x1]       | no[^9x2]         | no[^9x3]         | no          | yes          |
| Evaluation of Arbitrary Classes      | yes[^10x1]     | some[^10x2]      | yes[^10x3]       | no          | yes[^10x5]   |
| Package-specific API                 | yes[^11x1]     | yes              | yes[^11x3]       | no          | yes          |
| Methods for Standard Generics        | no             | no               | some[^12x3]      | no          | no           |
| Methods for dplyr Generics           | no[^13x1]      | yes[^12x2]       | no               | yes         | no           |

[^1x1]: Use of HDFS through rhdfs[@revo2013rhdfs], and MapReduce through rmr2[@revo2014plyrmr]
[^2x1]: rmr2[@revo2015rmr2] allows for arbitrary R code to be executed through MapReduce
[^5x1]: Direct access to HDFS through rhdfs[@revo2013rhdfs]
[^6x1]: Source repositories only exist on GitHub, following a non-standard package structure at the root level, and Hadoop is required to be set up beforehand
[^9x1]: While the collection is separate from Hadoop, it is entirely tied to Hadoop and MapReduce, and can't be switched to any other distributed platform
[^10x1]: Within the `mapreduce()`{.R} function from rmr2, no prescription is given for any particular class over another
[^11x1]: rmr2 has the package-specific `mapreduce()`{.R} function as the primary interface
[^13x1]: The collection has suffered from the lack of updates; plyrmr provides functionality that is near-transparent to plyr, but this is still some distance from dplyr[@revo2014plyrmr].

[^1x2]: Use of Spark[@luraschi20]
[^2x2]: Provides `mutate()`{.R} function to enable user-defined code, however there are limitations in not being capable of parsing global variables
[^3x2]: See doc/review-sparklyr-iteration.tex
[^4x2]: See [^2x3]
[^5x2]: Allows for Spark over HDFS, but offers no HDFS-specific filesystem manipulation functions
[^6x2]: Installs from CRAN, requires Spark set up beforehand and environmental variables configured
[^9x2]: Package tied to Spark as evaluative backend
[^10x2]: S3 Objects that have an `sdf_import()`{.R} method implemented can make use of the `sdf_copy_to()`{.R} function to copy objects from R to Spark
[^12x2]: The principal interaction is via dplyr generics, albeit with a difference of lazy evaluation

[^1x3]: Distributed computation performed by pbdMPI, with support for several remote messaging protocols[@Chen2012pbdMPIpackage; @Schmidt2015pbdCSpackage]
[^2x3]: Adhering to a SPMD paradigm
[^6x3]: Installation can be performed with `install.packages()`{.R} alongside the installation of `openmpi` externally
[^7x3]: Inter-node communication facilitated through pbdMPI wrappers to standard MPI communication functions such as `scatter`, `gather`, `send`, etc.
[^9x3]: Tied to the usage of the MPI protocol
[^10x3]: Arbitrary classes may be made use of and passed through the communicator generics when methods are defined for them, using pbdMPI
[^11x3]: pbdMPI provides package-specific generics to use and define further methods for
[^12x3]: pbdDMAT provides a distributed matrix class with methods defined to make transparent usage of standard matrix manipulation generics

[^2x4]: Many functions used for grouped summarisation are only estimates, such as `median`[@zj19:_group_by]

[^1x5]: Through the use of additional packages such as doMPI and sparklyr[@weston17][@luraschi20]
[^2x5]: `\%dopar\%` accepts any expression, and tries its best to handle references to global variables, however it is still recommended to manually define the global references as well as packages used
[^3x5]: foreach makes use of iterators, which can be defined to perform recurrance relations (see doc/review-foreach.tex, subsection "Form of Iteration") but these rely on closures and may in fact be slower than serial relations
[^5x5]: Through sparklyr as a backend
[^10x5]: foreach makes use of iterator objects, which any class can inherit from to define `nextElem()`{.R}

# A Survey of Distributed Computing Systems

## Hadoop {#sec:hadoop-1}

Apache Hadoop is a collection of utilities that facilitates cluster computing.
Jobs can be sent for parallel processing on the cluster directly to the utilities using .jar files, "streamed" using any executable file, or accessed through language-specific APIs.

The project began in 2006, by Doug Cutting, a Yahoo employee, and Mike Cafarella.
The inspiration for the project was a paper from Google describing the Google File System (described in [@ghemawat2003google]), which was followed by another Google paper detailing the MapReduce programming model, [@dean2004mapreduce].

Hadoop consists of a memory part, known as Hadoop Distributed File System (HDFS), described in subsection~[@sec:hdfs], and a processing part, known as MapReduce, described in subsection[@sec:mapreduce].

In operation, Hadoop splits files into blocks, then distributes them across nodes in a cluster, where they are then processed by the node. This creates the advantage of data locality, wherein data is processed by the node they exist in.

Hadoop has seen extensive industrial use as the premier big data platform upon it's release. In recent years it has been overshadowed by Spark, due to the greater speed gains offered by spark.
The key reason Spark is so much faster than Hadoop comes down to their different processing approaches: Hadoop MapReduce requires reading from disk and writing to it, for the purposes of fault-tolerance, while Spark can run processing entirely in-memory.
However, in-memory MapReduce is provided by another Apache project, Ignite[@zheludkov2017high].

### Hadoop Distributed File System {#sec:hdfs}

The file system has 5 primary services.

Name Node
: Contains all of the data and manages the system.
  The master node.

Secondary Name Node
: Creates checkpoints of the metadata from the main name node, to potentially restart the single point of failure that is the name node.
  Not the same as a backup, as it only stores metadata.

Data Node
: Contains the blocks of data.
  Sends "Heartbeat Message" to the name node every 3 seconds.
  If two minutes passes with no heartbeat message from a particular data node, the name node marks it as dead, and sends it's blocks to another data node.

Job Tracker
: Receives requests for MapReduce from the client, then queries the name node for locations of the data.

Task Tracker
: Takes tasks, code, and locations from the job tracker, then applies such code at the location.
  The slave node for the job tracker.

HDFS is written in Java and C.
It is described in more detail in [@shvachko2010hadoop]

### MapReduce {#sec:mapreduce}

MapReduce is a programming model consisting of map and reduce staps, alongside making use of keys.

Map
: applies a "map" function to a dataset, in the mathematical sense of the word.
  The output data is temporarily stored before being shuffled based on output key, and sent to the reduce step.

Reduce
: produces a summary of the dataset yielded by the map operation

Keys
: are associated with the data at both steps.
  Prior to the application of mapping, the data is sorted and distributed among data nodes by the data's associated keys, with each key being mapped as a logical unit.
  Likewise, mapping produces output keys for the mapped data, and the data is shuffled based upon these keys, before being reduced.

After sorting, mapping, shuffling, and reducing, the output is collected, sorting by the second keys and given as final output.

The implementation of MapReduce is provided by the HDFS services of job tracker and task tracker.
The actual processing is performed by the task trackers, with scheduling using the job tracker, but other scheduling systems are available to be made use of.

Development at Google no longer makes as much use of MapReduce as they originally did, using stream processing technologies such as MillWheel, rather than the standard batch processing enabled by MapReduce[@akidau2013millwheel].

## Spark {#sec:spark}

Spark is a framework for cluster computing[@zaharia2010spark].
Much of it's definition is in relation to Hadoop, which it intended to improve upon in terms of speed and usability for certain tasks.

It's fundamental operating concept is the Resiliant Distributed Dataset (RDD), which is immutable, and generated through external data, as well as actions and transformations on prior RDD's.
The RDD interface is exposed through an API in various languages, including R.

Spark requires a distributed storage system, as well as a cluster manager; both can be provided by Hadoop, among others.

Spark is known for possessing a fairly user-friendly API, intended to improve upon the MapReduce interface.
Another major selling point for Spark is the libraries available that have pre-made functions for RDD's, including many iterative algorithms.
The availability of broadcast variables and accumulators allow for custom iterative programming.

Spark has seen major use since it's introduction, with effectively all major big data companies having some use of Spark.
It's features and implementations are outlined in [@zaharia2016apache].

## H2O {#sec:h2o}

The H2O software bills itself as,

> an in-memory platform for distributed, scalable machine learning.
> H2O uses familiar interfaces like R, Python, Scala, Java, JSON and
> the Flow notebook/web interface, and works seamlessly with big data
> technologies like Hadoop and Spark.
> H2O provides implementations of
> many popular algorithms such as GBM, Random Forest, Deep Neural
> Networks, Word2Vec and Stacked Ensembles.
> H2O is extensible so that
> developers can add data transformations and custom algorithms of
> their choice and access them through all of those clients.

H2O typically runs on HDFS, along with spark for computation and bespoke data structures serving as the backbone of the architecture.

H2O can communicate with R through a REST api.
Users write functions in R, passing user-made functions to be applied on the objects existing in the H2O system[@h2o.ai:_h2o].

The company H2O is backed by \$146M in funding, partnering with large institutions in the financial and tech world.
Their business model follows an open source offering with the same moniker as the company, and a small set of heavily-marketed proprietary software in aid of it.
They have some important figures working with them, such as Matt Dowle, creator of data.table.

# A Survey of R Packages for Local Large-Scale Computing

## Bigmemory Collection {#sec:bigmemory-collection}

The bigmemory package enables the creation of "massive matrices" through a "big.matrix" S4 class with a similar interface to 'matrix'[@kane13:bigmemory].
These matrices may take up gigabytes of memory, typically larger than RAM, and have simple operations defined that speed up their usage.
A variety of extension packages are also available that provide more functionality for big.matrices.
The massive capacity of big.matrices is given through their default memory allocation to shared memory, rather than working memory as in most R objects.
The objects in R are therefore pointers, and the big.matrix "show" method prints a description and memory location instead of a standard matrix display, given that it is likely far too big a matrix to print reasonably.
Parallel processing is made use of for the advantage of computations and subsetting of matrices.
Development on the package is still active, however it is stable enough that updates are intermittent.
Some of the main extension packages:

biganalytics
: Extends bigmemory with matrix summary statistics such as `colmeans`, `apply`, as well as integration with the biglm package[@emerson16].
  Biganalytics is authored by the same creators of the main bigmemory package.

bigtabulate
: Extends bigmemory with tabulation functions and `tapply`, allowing for contingency tables and `summary` of big.matrix objects [@kane16].

biglasso
: Extends bigmemory matrices to allow for lasso, ridge and elastic-net model fitting.
  It can be take advantage of multicore machines, with the ability to be run in parallel.
  Biglasso is authored by Yaohui Zeng, and described in detail in [@zeng2017biglasso].

bigalgebra
: Provides BLAS routines for bigmemory and native R matrices.
  Linear Algebra functionality is given through matrix arithmetic methods, such as the standard `%*%`{.R}.
  The package is archived on CRAN as of February 2020, only being accessible through R-Forge.
  This is likely due to a merger with the main bigmemory package (must investigate).

bigstatsr
: Was originally a set of functions for complex statistical analyses on big.matrices, having since implemented and provided it's own "filebacked big matrices"[@prive2018efficient].
  The provided functions include matrix operations particularly relating to bioinformatics, such as PCA, sparse linear supervised models, etc.
  Bigstatsr is described in detail in [@prive2018efficient].

### LAPACK, BLAS, ATLAS {#sec:blas-lapack}

BLAS is a specification for a set of low-level "building block" linear algebra routines[@lawson1979basic].
Most linear algebra libraries conform to the BLAS specifications, including the most prominent linear algebra library, LAPACK, with it's own set of extensions[@demmel1989lapack].
LAPACK has been extended in turn to support a variety of systems, with implementations such as ScaLAPACK being introduced to attend to distributed memory systems[@choi1992scalapack].

## disk.frame {#sec:disk.frame}

The package description outlines disk.frame with the following:

> A disk-based data manipulation tool for working with large-than-RAM
> datasets.
> Aims to lower the barrier-to-entry for manipulating large
> datasets by adhering closely to popular and familiar data
> manipulation paradigms like dplyr verbs and data.table syntax.

disk.frame provides a disk.frame class and derivatives, which model a data.frame.
The primary functional difference is that disk.frames can be far larger than total RAM.
This is enabled through the disk.frame objects being allocated to shared memory, rather than working memory as in data.frames.
The transparency offered by the class is well-known to be at a very high level, with most standard manipulations of dataframes being applicable to disk.frame objects.
I have written more on disk.frame in the document, [A disk.frame Case Study](case-study-disk.frame.html)

## data.table {#sec:data.table}

data.table is another dataframe alternative, focussing on speed through multithreading and well-tuned database algorithms[@dowle19].
The package has introduced a unique syntax for data.table manipulation, which is also made available in disk.frame.
data.table objects are held in RAM, so big data processing is not easily enabled, however the package allows for serialisation of data.tables, and chunking is possible through splitting via the `shard` function.
The package is authored by Matt Dowle, currently an employee at H2O.ai.
An overview is given in [@dowle19:_introd], with extensive benchmarking available in [@dowle19:_bench].

## fst {#sec:fst}

fst is a means of serialising dataframes, as an alternative to RDS files[@klik19].
Serialisation takes place extremely fast, using compression to minimise disk usage.
The package speed is increased through parallel computation.
Author Mark Klik and Yann Collet, of Facebook, Inc.
fst is a dependency of disk.frame, performing some of the background functionality.

## iotools {#sec:iotools}

iotools is a set of tools for managing big I/O, with an emphasis on speed and efficiency for big data through chunking[@urbanek20b].
The package provides several functions for creating and manipulating chunks directly.
Authored by Simon Urbanek and Taylor Arnold.

## ff {#sec:ff}

The package description outlines ff with the following:

> The ff package provides atomic data structures that are stored on
> disk but behave (almost) as if they were in RAM by mapping only a
> subsection (pagesize) into main memory (the effective main memory
> consumption per ff object).
> Several access optimization techniques
> such as Hyrid Index Preprocessing (as.hi, update.ff) and
> Virtualization (virtual, vt, vw) are implemented to achieve good
> performance even with large datasets.

The package provides a disk-based storage for most base types in R.
This also enables sharing of objects between different R processes.
ff is authored by a German-based team, and maintained by Jens Oehlschlägel, the author of True Cluster.
First introduced in 2008[@adler08:_large_r], there have been no updates since mid-2018.

ffbase[@jonge20]
: is an extension to ff, providing standard statistical methods for ff objects.
  The package is still actively maintained.
  The package has been the subject of several talks, most notably the author's overview, [@wijffels13].
  The package is currently being revised for a second version that provides generics functionality for dplyr on ff objects, under the title, "ffbase2"[@jonge15].

# A Survey of R Packages for Distributed Large-Scale Computing

## DistributedR {#sec:distributedr}

DistributedR offers cluster access for various R data structures, particularly arrays, and providing S3 methods for a fair range of standard functions.
It has no regular cluster access interface, such as with Hadoop or MPI, being made largely from scratch.

The package creators have ceased development as of December 2015.
The company, Vertica, has moved on to offering an enterprise database platform[@vertica:_distr].

## foreach and doX {#sec:foreach-doc}

foreach offers a high-level looping construct compatible with a variety of backends[@microsoft20].
The backends are provided by other packages, typically named with some form of "Do*X*".
Parallelisation is enabled by some backends, with doParallel allowing parallel computations[@corporation19], doSNOW enabling cluster access through the SNOW package[@dosnow19], and doMPI allowing for direct MPI access[@weston17].

foreach is managed by Revolution Analytics, with many of the Do*X* corollary packages also being produced by them.
Further information of foreach is given in [@weston19:_using].

I have written more on future in [A Detail of foreach](detail-foreach.html)

## future {#sec:future-furrr}

future captures R expressions for evaluation, allowing them to be passed on for parallel and ad-hoc cluster evaluation, through the parallel package[@bengtsson20].
Such parallelisation uses the standard MPI or SOCK protocols.

The author of future is Henrik Bengtsson, Associate Professor at UCSF.
Development on the package remains strong, with Dr. Bengtsson possessing a completely full commit calendar and 81,328 contributions on GitHub.
I have written more on future in the document, [A Detail of future](detail-future.html).
future has many aspects to it, captured in it's extensive series of vignettes[@bengtsson20:_futur_r; @bengtsson20:_futur_r2; @bengtsson20:_futur_r3; @bengtsson20:_futur_r4; @bengtsson20:_futur_r5; @bengtsson20:_futur_r6].

Furrr is a frontend to future, amending the functions from the package purrr to be compatible with future, thus enabling parallelisation in a similar form to multicore, though with a tidyverse style[@vaughan18].

Furrr is developed by Matt Dancho, and Davis Vaughn, an employee at RStudio.

## Parallel, snow, and multicore {#sec:parall-snow-mult}

Parallel is a package included with R, born from the merge of the packages snow and multicore[@core:_packag].
Parallel enables various means of performing computations in R in parallel, allowing not only multiple cores in a node, but multiple nodes through snow's interfaces to MPI and SOCK[@tierney18].

Parallel takes from multicore the ability to perform multicore processing, with the mcapply function.
multicore creates forked R sessions, which is very resource-efficient, but not supported by windows.

From snow, distributed computing is enabled for multiple nodes.

multicore was developed by Simon Urbanek (!).
snow was developed by Luke Tierney, a professor at the University of Iowa, who also originated the byte-compiler for R

## pbdR {#sec:pbdr}

pbdR is a collection of packages allowing for distributed computing with R[@pbdBASEpackage], with the name being the abbreviation of Programming with Big Data in R.
The packages include high-performance communication and computation capabilities, including RPC, ZeroMQ, and MPI interfaces.

The collection is extensive, offering several packages for each of the main categories of application functionality, communication, computation, development, I/O, and profiling.

Some selected packages of interest include the following:

pbdBASE
: Includes the base utilities for distributed matrices used in the project, including bindings and extensions to ScaLAPACK[@pbdBASEpackage].

pbdDMAT
: Higher level classes and methods for distributed matrices, including manipulation, linear algebra, and statistics routines.
  Uses the same syntax as base R through S4[@pbdDMATpackage].

pbdMPI
: Offers a high-level interface to MPI, using the S4 system to program in the SPMD style, with no "master" nodes[@Chen2012pbdMPIpackage].

pbdCS
: A client/server framework for pbdR packages[@Schmidt2015pbdCSpackage].

pbdML
: Offers machine learning algorithms, consisting at present of only PCA and similar linear algebra routines, primarily for demonstration purposes[@schmidt20].

hpcvis
: Provides profiler visualisations generated by the other profiler packages within the collection[@hpcvis].

The project is funded by major government sources and research labs in the US.
In 2016, the project won the Oak Ridge National Laboratory 2016 Significant Event Award; as per [@pbdR2012],

> OLCF is the Oak Ridge Leadership Computing Facility, which currently includes Summit, the most powerful computer system in the world.

More detail is given in [@pbdBASEvignette].

## RHadoop {#sec:rhadoop}

RHadoop is a collection of five packages to run Hadoop directly from R[@analytics:_rhadoop_wiki].
The packages are divided by logical function, including rmr2, which runs MapReduce jobs, and rhdfs, which can access the HDFS.
The packages also include plyrmr, which makes available plyr-like data manipulation functions, in a similar vein to sparklyr.

It is offered and developed by Revolution Analytics.

## RHIPE and DeltaRho {#sec:rhipe-deltarho}

RHIPE is a means of "using Hadoop from R"[@deltarho:_rhipe].
The provided functions primarily attain this through interfacing and manipulating HDFS, with a function, rhwatch, to submit MapReduce jobs.
The easiest means of setup for it is to use a VM, and for all Hadoop computation, MapReduce is directly programmed for by the user.

There is currently no support for the most recent version of Hadoop, and it doesn't appear to be under active open development, with the last commit being 2015.
RHIPE has mostly been subsumed into the backend of DeltaRho, a simple frontend.

## sparklyr {#sec:sparklyr}

sparklyr is an interface to Spark from within R[@luraschi20].
The user connects to spark and accumulates instructions for the manipulation of a Spark DataFrame object using dplyr commands, then executing the request on the Spark cluster.

Of particular interest is the capacity to execute arbitrary R functions on the Spark cluster.
This can be performed directly, with the `spark_apply()`{.R} function, taking a user-defined function as a formal parameter.
It can also be used as part of a dplyr chain through the `mutate()`{.R} function.
Extending these, Spark-defined hive functions and windowing functions are enabled for use in `mutate()`{.R} calls.
Limitations to arbitrary code execution include the lack of support for global references due to the underlying lack in the `serialize` package.

Some support for graphs and graph manipulation is enabled via usage with the *graphframes* package, which follows the Tidyverse pattern of working solely with dataframes and dataframe derivatives[@kuo18].
This binds to the GraphX component of Spark, enabling manipulation of graphs in Spark through pre-defined commands.

sparklyr is managed and maintained by RStudio, who also manage the rest of the Tidyverse (including dplyr).

## SparkR {#sec:sparklyr}

SparkR provides a front-end to Spark from R[@venkataraman20:_spark].
Like sparklyr, it provides the DataFrame as the primary object of interest.
However, there is no support for the dplyr model of programming, with functions closer resembling base R being provided by the package instead.

SparkR is maintained directly by Apache Spark, with ongoing regular maintenance provided.
Usage of the package is described in the vignette, [@venktaraman19:_spark_pract_guide], with implementation explained in [@venkataraman2016sparkr].

## hmr {#sec:hmr}

hmr is an interface to MapReduce from R[@urbanek20]. It runs super fast, making use of chunked data.
Much of the process is handled by the package, with automatic R object conversion.
hmr integrates with iotools, of which it is based upon.
The author, like that of iotools, is Simon Urbanek.

## big.data.table {#sec:big.data.table}

big.data.table runs data.table over many nodes in an ad-hoc cluster[@gorecki16].
This allows for big data manipulation using a data.table interface.
The package makes use of Rserve (authored by Simon Urbanek) to facilitate communication between nodes when running from R.
Alternatively, the nodes can be run as docker services, for fast remote environment setup, using RSclient for connections.
Beyond greater storage capacity, speed is increased through manipulations on big.data.tables occurring in parallel.
The package is authored by Jan Gorecki, but hasn't been actively developed since mid-2016.

# A Survey of R Derivatives for Large-Scale Computing

## ML Services on HDInight {#sec:r-server-hdinsight}

ML Services on HDInsight, also referred to as R Server, is a distribution of R with particular emphasis on parallel and capabilities[@azure16:_r_server_hdins_r_analy].
Specific parallel capabilities advertised include multi-threaded mathematics libraries.
R Server for HDInsight was previously named Revolution R, and developed by Revolution Analytics, before being bought out by Microsoft, renamed Microsoft R, before acquiring the name R server for HDInsight, before changing to ML Services.

## IBM Big R {#sec:ibm-big-r}

IBM Big R is a library of functions integrating R with the IBM InfoSphere BigInsights platform[@inc.14:_infos_bigin_big_r].
This is implemented through the introduction of various bigr classes replicating base R types.
These are then run in the background on the BigInsights platform, which is in turn powered by Apache Hadoop.
The user is therefore able to run MapReduce jobs without having to explicitly write MapReduce-specific code.

## MapR {#sec:mapr}

MapR initially provided R access to Hadoop, being mainly HDFS access[@mapr19:_indus_next_gener_data_platf_ai_analy].
It was then bought out by HP in May 2019, pivoting to selling an enterprise database platform and analytics services, running on Hadoop among other backends.
Development has ceased on R access.

# A Survey of R Packages for Large-Scale Statistical Modelling

## partools {#sec:partools}

partools provides utilities for the parallel package[@matloff16softw_alchemy].
It offers functions to split files and process the splits across nodes provided by parallel, along with bespoke statistical functions.

It consists mainly of wrapper functions, designed to follow it's philosophy of "keep it distributed".

It is authored by Norm Matloff, a professor at UC, Davis and current Editor-in-Chief of the R Journal.

In more detail, [@matloff15] and [@matloff17] presents the motivation behind partools with reference to Hadoop and Spark.
Matloff describes partools as more "sensible" for large data sets than Hadoop and Spark, due to their difficulty of setup, abstract programming paradigms, and the overhead caused by their fault tolerance.
The alternative approach favoured by partools, termed "software alchemy", is to use base R to split the data into distributed chunks, run analyses on each chunk, then average the results.
This is proven to have asymptotic equivalence to standard analyses under certain assumptions, such as iid data.
Effectively, it is a map-reduce, with map being some analysis, and reduce being an average.

The analyses amenable to software alchemy have bespoke functions for them in the package, typically consisting of their base R name with the prefix "ca" alluding to "chunk averaging", such as `calm()`{.R}.
Other functions in which it doesn't make sense to average are also supported, such as column sums, which also have specific functions made for them.
Complex cases such as fitting LASSO models, in which each chunk may have settled on different explanatory variables, are catered for in partools through subsetting them.
Finally, aggregate functions, akin to R's aggregate function, provide for arbitrary functions to be applied to distributed data.

In terms of applications of the package, it is difficult to estimate the usage of it; as it has a more complex setup than a simple `library` call, it won't be included in many other packages.
Similarly, the nature of the work skews towards interactive usage, and custom business-specific programs that are difficult to attain data on.
The reverse dependencies/imports have all been authored by Matloff, so aren't entirely informative, but their usage is interesting: one package (cdparcoord) to plot coordinates for large datasets in parallel, and one (polyreg) to form and evaluate polynomial regression models.

## biglm {#sec:biglm}

biglm is described succinctly as

> bounded memory linear and generalized linear models[@lumley13].

biglm has been extended by other packages, and can integrate with bigmemory matrices through biganalytics.
The package is developed by Dr.Thomas Lumley of the University of Auckland.

# A Review of Iteration with sparklyr

## Introduction

Given that iteration is cited by a principal author of Spark as a motivating factor in it's development when compared to Hadoop, it is reasonable to consider whether the most popular R interface to Spark, sparklyr, has support for iteration[@zaharia2010spark; @luraschi20].
One immediate hesitation to the suitability of sparklyr to iteration is the syntactic rooting in dplyr; dplyr is a "Grammar of Data Manipulation" and part of the tidyverse, which in turn is an ecosystem of packages with a shared philosophy[@wickham2019welcome; @wickham2016r].

The promoted paradigm is functional in nature, with iteration using for loops in R being described as "not as important" as in other languages;
map functions from the tidyverse purrr package are instead promoted as providing greater abstraction and taking much less time to solve iteration problems.
Maps do provide a simple abstraction for function application over elements in a collection, similar to internal iterators, however they offer no control over the form of traversal, and most importantly, lack mutable state between iterations that standard loops or generators allow[@cousineau1998functional].
A common functional strategy for handling a changing state is to make use of recursion, with tail-recursive functions specifically referred to as a form of iteration in [@abelson1996structure].
Reliance on recursion for iteration is naively non-optimal in R however, as it lacks tail-call elimination and call stack optimisations[@rcore2020lang]; at present the elements for efficient, idiomatic functional iteration are not present in R, given that it is not as functional a language as the tidyverse philosophy considers it to be, and sparklyr's attachment to the the ecosystem prevents a cohesive model of iteration until said elements are in place.

## Iteration

Iteration takes place in Spark through caching results in memory, allowing faster access speed and decreased data movement than MapReduce[@zaharia2010spark].
sparklyr can use this functionality through the `tbl_cache()`{.R} function to cache Spark dataframes in memory, as well as caching upon import with `memory=TRUE` as a formal parameter to `sdf_copy_to()`{.R}.

Iteration can also make use of persisting Spark Dataframes to memory, forcing evaluation then caching; performed in sparklyr through `sdf_persist()`{.R}.

The Babylonian method for calculating a square root is a simple iterative procedure, used here as an example. A standard form in R with non-optmimised initial value is given in [@lst:basicbab].

```{#lst:basicbab .R caption="Simple Iteration with the Babylonian Method"}
basic_sqrt <- function(S, frac_tolerance=0.01, initial=1){
	x <- initial
	while(abs(x\^2 - S)/S > frac_tolerance){
		x <- (x + S/x)/2
	}
	x
}
```

This iterative function is trivial, but translation to sparklyr is not entirely so.

The first aspect that must be considered is that sparklyr works on Spark Data Frames; `x` and `S` must be copied to Spark with the aforementioned `sdf_copy_to()`{.R} function.

The execution of the function in Spark is the next consideration, and sparklyr provides two means for this to occur; `spark_apply()`{.R} evaluates arbitrary R code over an entire data frame.
The means of operation vary across Spark versions, ranging from launching and running RScripts in Spark 1.5.2, to Apache Arrow conversion in Spark 3.0.0.

The evaluation strategy of 1.5.2 is unsuitable in this instance as it is excessive overhead to launch RScripts every iteration.

The other form of evaluation is through using dplyr generics, which is what will be made use of in this example.

An important aspect of consideration is that sparklyr methods for dplyr generics execute through a translation of the formal parameters to Spark SQL.
This is particularly relevant in that separate Spark Data Frames can't be accessed together as in a multivariable function.
In addition, very R-specific functions such as those from the `stats` and `matrix` core libraries are not able to be evaluated, as there is no Spark SQL cognate for them.
The SQL query generated by the methods can be accessed and "explained" through `show_query()`{.R} and `explain()`{.R} respectively;
When attempting to combine two Spark Data Frames in a single query without  joining them, `show_query()`{.R} reveals that the Data Frame that is referenced through the `.data` variable is translated, but the other Data Frame has it's list representation passed through, which Spark SQL doesn't have the capacity to parse; 
an example is given in [@lst:computer-no] (generated through listing [@lst:bad]), showing an attempt to create a new column from the difference between two seperate Data Frames

```{#lst:bad .R caption="Attempt in R to form new column from the difference between two separate Spark data frames S and x"}
show_query(mutate(S, S = S - x)
```

```{#lst:computer-no .sql caption="Spark SQL query generated from attempt to form the difference from two seperate data frames"}
SELECT `S` - list(con = list(master = "yarn", method = "shell", app_name =
	"sparklyr", config = list(spark.env.SPARK_LOCAL_IP.local = "127.0.0.1",
	sparklyr.connect.csv.embedded = "\^1.*",
	spark.sql.legacy.utcTimestampFunc.enabled = TRUE,
	sparklyr.connect.cores.local = 4, spark.sql.shuffle.partitions.local =
	4), state = <environment>, extensions = list(jars = character(0),
	packages = character(0), initializers = list(), catalog_jars =
	character(0)), spark_home =
	"/shared/spark-3.0.0-preview2-bin-hadoop3.2", backend = 4, monitoring =
	5, gateway = 3, output_file =
	"/tmp/Rtmpbi2dqk/file44ec187daaf4_spark.log", sessionId = 58600,
	home_version = "3.0.0")) AS `S1`, `S` - list(x = "x", vars = "initial")
	AS `S2` FROM `S`
```

Global variables that evaluate to SQL-friendly objects can be passed and are evaluated prior to translation.
An example is given through [@lst:global-ok], generated through [@lst:ok-generator], where the difference between a variable holding a numeric and a Spark Data Frame is translated into the evaluation of the variable, transformed to a float for Spark SQL, and its difference with the Spark Data Frame, referenced directly.

\begin{listing}
\begin{minted}{sql}
```{#lst:global-ok .sql caption="Spark SQL query generated from attempt to form the difference between a data frame and a numeric"}
SELECT `S` - 3.0 AS `S`
FROM `S`
```


\begin{listing}
\begin{minted}{r}
```{#lst:ok-generator .R caption="Capacity in sparklyr to form new column from the difference between a spark data frame and a numeric"}
S
# Source: spark<S> [?? x 1]
#      S
#  <dbl>
#     9
x = 3
mutate(S, S = S - x)
# Source: spark<?> [?? x 1]
#      S
#  <dbl>
#     6
```

A reasonable approach to implementing a Babylonian method in sparklyr is then
to combine `S` and `x` in one dataframe, and iterate within
columns.

\begin{listing}
\begin{minted}{R}
```{#lst:sparklyr-bab .R caption="Babylonian method implementation using sparklyr"}
library(sparklyr)

sc <- spark_connect(master = "yarn")

sparklyr_sqrt <- function(S, sc, frac_tolerance=0.01, initial=1){
        bab = sdf_copy_to(sc,
                          data.frame(x=initial, S=S, unfinished=TRUE),
                          "bab", memory = TRUE, overwrite = TRUE)
	while(any(collect(bab)\$unfinished)){
                compute(mutate(bab, x = (x + S/x)/2,
                               unfinished = abs(x^2 - S)/S > frac_tolerance),
                        "bab")
        }
        collect(bab)\$x
}
```

## Conclusion {#sec:conclusion}

sparklyr is excellent when used for what it is designed for.
Iteration, in the form of an iterated function, does not appear to be part of this design;
this was clear in the abuse required to implement a simple iterated function in the form of the Babylonian Method.
Furthermore, all references to "iteration" in the primary sparklyr literature refer either to the iteration inherent in the inbuilt Spark ML functions, or the "wrangle-visualise-model" process popularised by Hadley Wickham[@luraschi2019mastering; @wickham2016r].
None of such references connect with iterated functions.

Thus, it is fair to conclude that sparklyr is incapable of sensible iteration of arbitrary R code beyond what maps directly to SQL;
even with mutate, it is a very convoluted interface for attempting any iteration more complex than the Babylonian Method.
Implementation of a GLM function with sparklyr iteration was initially planned, but the point was already proven by something far simpler, and the point is one that did not need to be laboured.

Ultimately, sparklyr is excellent at what it does, but convoluted and inefficient when abused, as when attempting to implement iterated functions.

# A Review of pbdR

## Introduction {#sec:pbdr}

pbdR is a collection of packages allowing for distributed computing with R[@pbdBASEpackage].
The name is an acronym for the collection's purpose; Programming with Big Data in R.
It is introduced on it's main page with the following description:

> The "Programming with Big Data in R" project (pbdR) is a set of highly scalable
> R packages for distributed computing and profiling in data science.
> > Our packages include high performance, high-level interfaces to MPI, ZeroMQ,
> ScaLAPACK, NetCDF4, PAPI, and more.
> While these libraries shine brightest on
> large distributed systems, they also work rather well on small clusters and
> usually, surprisingly, even on a laptop with only two cores.
> > Winner of the Oak Ridge National Laboratory 2016 Significant Event Award for
> "Harnessing HPC Capability at OLCF with the R Language for Deep Data Science."
> OLCF is the Oak Ridge Leadership Computing Facility, which currently includes
> Summit, the most powerful computer system in the world.[@pbdR2012]

## Interface and Backend

The project seeks especially to serve minimal wrappers around the BLAS and LAPACK libraries along with their distributed derivatives, with the intention of introducing as little overhead as possible.
Standard R also uses routines from the library for most matrix operations, but suffers from numerous inefficiencies relating to the structure of the language; for example, copies of all objects being manipulated will be typically be created, often having devastating performance aspects unless specific functions are used for linear algebra operations, as discussed in [@schmidt2017programming] (e.g., `crossprod(X)`{.R} instead of `t(X) %*% X`{.R})

Distributed linear algebra operations in pbdR depend further on the ScaLAPACK
library, which can be provided through the pbdSLAP package [@Chen2012pbdSLAPpackage].

The principal interface for direct distributed computations is the pbdMPI
package, which presents a simplified API to MPI through R
[@Chen2012pbdMPIpackage].
All major MPI libraries are supported, but the
project tends to make use of openMPI in explanatory documentation.
A very
important consideration that isn't immediately clear  is that pbdMPI can only
be used in batch mode through MPI, rather than any interactive option as in
Rmpi [@yu02:_rmpi].

The actual manipulation of distributed matrices is enabled through the pbdDMAT
package, which offers S4 classes encapsulating distributed matrices
[@pbdDMATpackage].
These are specialised for dense matrices through the
`ddmatrix` class, though the project offers some support for other
matrices.
The `ddmatrix` class has nearly all of the standard matrix
generics implemented for it, with nearly identical syntax for all.

## Package Interaction

The packages can be made to interact directly, for example with pbdDMAT
constructing and performing basic manipulations on distributed matrices, and
pbdMPI being used to perform further fine-tuned processing through
communicating results across nodes manually, taking advantage of the
persistence of objects at nodes through MPI.

## pbdR in Practice

The package is geared heavily towards matrix operations in a statistical
programming language, so a test of it's capabilities would quite reasonably
involve statistical linear algebra.
An example non-trivial routine is that of
generating data, to test randomisation capability, then fitting a generalised
linear model to the data through iteratively reweighted least squares.
In this
way, not only are the basic algebraic qualities considered, but communication
over iteration on distributed objects is tested.

To work comparatively, a simple working local-only version of the algorithm is
produced in listing [@lst:local-rwls].

\begin{listing}
\inputminted{r}{R/review-rwls.R}
	\caption{Local GLM with RWLS}
	\label{lst:local-rwls}
\end{listing}

It outputs a $\hat{\beta}$ matrix after several seconds of computation.

Were pbdDMAT to function transparently as regular matrices, as the package
README implies, then all that would be required to convert a local algorithm to
distributed would be to prefix a `dd` to every `matrix` call, and
bracket the program with a template as per listing [@lst:bracket].

\begin{listing}
\begin{minted}{r}
suppressMessages(library(pbdDMAT))
init.grid()

# program code with `dd` prefixed to every `matrix` call

finalize()
\end{minted}
\caption={Idealised Common Wrap for Local to Distributed Matrices}\label{lst:bracket}
\end{listing}

This is the form of transparency offered by packages such as *parallel*,
*foreach*, or *sparklyr* in relation to dplyr.
The program would then be written to disk, then executed, for example with the
following:

\begin{listing}
\begin{minted}{bash}
mpirun -np <# of cores> Rscript <script name>
\end{minted}
\end{listing}

The program halts however, as forms of matrix creation other than through
explicit `matrix()`{.R} calls are not necessarily picked up by that process;
`cbind` requires a second formation of a `ddmatrix`.
The first
issue comes when performing conditional evaluation;
predicates involving distributed matrices are themselves distributed matrices,
and can't be mixed in logical evaluation with local predicates.

Turning local predicates to distributed matrices, then converting them all back
to a local matrix for the loop to understand, finally results in a program run,
however the results are still not accurate.
This is due to `diag()<-`
assignment not having been implemented, so several further changes are
necessary, including specifying return type of the diag matrix as a replacement.
The final working code of pbdDMAT GLM through RWLS is given in listing
[@lst:dmat], with the code diff given in listing [@lst:diff].
Execution time was longer for the pbdR code on a dual-core laptop, however it
is likely faster over a cluster.

\begin{listing}
\inputminted{r}{R/review-pbdr.R}
	\caption{pbdDMAT GLM with RWLS}
	\label{lst:dmat}
\end{listing}

\begin{listing}
\inputminted{r}{R/review-pbdr.diff}
	\caption{Diff between local and pbdR code}
	\label{lst:diff}
\end{listing}

It is worth noting that options for optimisation and tuning are far more
extensive than those utilised in this example, including the capacity to set
grid parameters, blocking factors, and BLACS contexts, among others.

## Setup

The setup for pbdR is simple, being no more than a CRAN installation, but a
well tuned environment, which is the main purpose for using the package in the
first place, requires BLAS, LAPACK and derivatives, a parallel file system with
data in an appropriate format such as HDF5, and a standard MPI library.
Much of
the pain of setup is ameliorated with a docker container, provided by the
project.

# A Detail of future

## Overview {#sec:overview}
\nocite{bengtsson19:_futur_r}

future is introduced with the following summary: \blockquote{The
purpose of this package is to provide a lightweight and unified
future API for sequential and parallel processing of R expression
via futures.
The simplest way to evaluate an expression in parallel
is to use `x \%<-\% { expression `} with
`plan(multiprocess)`.
This package implements sequential,
multicore, multisession, and cluster futures.
With these, R
expressions can be evaluated on the local machine, in parallel a set
of local machines, or distributed on a mix of local and remote
machines.
Extensions to this package implement additional backends
for processing futures via compute cluster schedulers etc.
Because
of its unified API, there is no need to modify any code in order
switch from sequential on the local machine to, say, distributed
processing on a remote compute cluster.
Another strength of this
package is that global variables and functions are automatically
identified and exported as needed, making it straightforward to
tweak existing code to make use of futures.[@bengtsson20]}
futures are abstractions for values that may be available at some
point in the future, taking the form of objects possessing state,
being either resolved and therefore available immediately, or
unresolved, wherein the process blocks until resolution.

futures find their greatest use when run asynchronously.
The future
package has the inbuilt capacity to resolve futures asynchronously,
including in parallel and through a cluster, making use of the
parallel package.
This typically runs a separate process for each
future, resolving separately to the current R session and modifying
the object state and value according to it's resolution status.

## Comparison with Substitution and Quoting {#sec:comparison-with-non}

R lays open a powerful set of metaprogramming functions, which bear
similarity to future.
R expressions can be captured in a
`quote()`{.R}, then evaluated in an environment with `eval()`{.R}
at some point in the future.
Additionally, `substitute()`{.R}
substitutes any variables in the expression passed to it with the
values bound in an environment argument, thus allowing "non-standard
evaluation" in functions.

future offers a delay of evaluation as well, however such a delay is
not due to manual control of the programmer through `eval()`{.R}
functions and the like, but due to background computation of an
expression instead.

## Example Usage {#sec:examples}

Through substitution and quoting, R can, for example, run a console within the
language.
Futures allows the extension of this to a parallel evaluation scheme.
Listing [@lst:console] gives a simple implementation of this idea: a console
that accepts basic expressions, evaluating them in the background and
presenting them upon request when complete.
Error handling and shared
variables are not implemented.

\begin{listing}
\inputminted{r}{R/review-future.R}
\caption{Usage of future to implement a basic multicore console} {#lst:console}
\end{listing}

## Extension Packages {#sec:extension-packages}

\begin{description}
doFuture
: [@bengtsson20do] provides an adapter for
	      foreach[@microsoft20] that works on a future-based backend.
	      Note
	      that this does does not return foreach() calls as futures.
	      The
	      multicore features enabled with future are redundant over the
	      existing parallel package, but because future backends can include
	      other clusters, such as those provided by batchtools, there is some
	      additional functionality, including additional degrees of control
	      over backends.
future.batchtools
: [@bengtsson19batch] provides a future API
	      for batchtools[@lang17], or equivalently, a batchtools backend
	      for future.
	      This allows the use of various cluster schedulers such
	      as TORQUE, Slurm, Docker Swarm, as well as custom cluster functions.
future.apply
: [@bengtsson20apply] provides equivalent
	      functions to R's `apply` procedures, with a future backend
	      enabling parallel, cluster, and other functionality as enabled by
	      backends such as batchtools through future.batchtools.
future.callr
: [@bengtsson19callr] provides a
	      callr[@csardi20] backend to future, with all of the associated
	      advantages and overhead.
	      Callr \enquote{call[s] R from R}.
	      It
	      provides functions to run expressions in a background R process,
	      beginning a new session.
	      An advantage of callr is that it allows
	      more than 125 connections, due to not making use of R-specific
	      connections.
	      Additionally, no ports are made use of, unlike the
	      SOCKcluster provided by the snow component of parallel.
furrr
: [@vaughan18] allows the use of future as a backend to
	      purrr functions.
	      purrr is a set of functional programming tools for
	      R, including map, typed map, reduce, predicates, and monads.
	      Much of
	      it is redundant to what already exists in R, but it has the
	      advantage and goal of adhering to a consistent standard.
\end{description}

## Further Considerations {#sec:further-considerations}

One initial drawback to future is the lack of callback functionality, which
would open enormous potential.
However, this feature is made available in the
*promises* package, which has been developed by Joe Cheng at RStudio,
which allows for user-defined handlers to be applied to futures upon
resolution[@Cheng19].

Issues that aren't resolved by other packages include the copying of objects
referenced by future, with mutable objects thereby unable to be directly
updated by future (though this may be ameliorated with well-defined callbacks).
This also means that data movement is mandatory, and costly; future raises an
error if the data to be processed is over 500Mb, though this can be overridden.

Referencing variables automatically is a major unsung feature of future, though
it doesn't always work reliably; future relies on code inspection, and allows a
`global` parameter to have manual variable specification.

It seems likely that the future package will have some value to it's use,
especially if asynchronous processing is required on the R end; it is the
simplest means of enabling asynchrony in R without having to manipulate
networks or threads.

# A Review of foreach

## Introduction {#sec:introduction}

foreach introduces itself on CRAN with the following description:
\begin{displaycquote}{microsoft20}
	Support for the foreach looping construct.
	Foreach is an idiom that
	allows for iterating over elements in a collection, without the use
	of an explicit loop counter.
	This package in particular is intended
	to be used for its return value, rather than for its side effects.
	In that sense, it is similar to the standard lapply function, but
	doesn't require the evaluation of a function.
	Using foreach without
	side effects also facilitates executing the loop in parallel.
\end{displaycquote}

From the user end, the package is conceptually simple, revolving
entirely around a looping construct and the one-off backend
registration.

The principal goal of the package, which it hasn't strayed from, is
the enabling of parallelisation through backend transparency within
the foreach construct.
Notably, more complex functionality, such as
side effects and parallel recurrance, are not part of the package's
intention.

Thus, the primary driver for the practicality of the package, beyond
the support offered for parallel backends, is the backends themselves,
currently enabling a broad variety of parallel systems.

foreach is developed by Steve Weston and Hoong Ooi.

## Usage {#sec:usage}

foreach doesn't require setup for simple serial execution, but
parallel backends require registration by the user, typically with a
single function as in the registration for doParallel,
`registerDoParallel()`{.R}.

The syntax of foreach consists of a `foreach()`{.R} function call
next to a `\%do\%` operator, and some expression to the
right[@weston19:_using].
Without loss in generality, the syntactic
form is given in Listing~[@lst:syntax].

\begin{listing}
\begin{minted}{r}
foreach(i=1:n) %do% {expr}
\end{minted}
\caption{Standard foreach syntax}\label{lst:syntax}
\end{listing}

The `foreach()`{.R} function can take other arguments including
changing the means of combination along iterations, whether iterations
should be performed in order, as well as the export of environmental
variables and packages to each iteration instance.

In addition to `\%do\%`, other binary operators can be appended
or substituted.
Parallel iteration is performed by simply replacing
`\%do\%` with `\%dopar\%`.
Nested loops can be created
by inserting `\%:\%` between main and nested foreach functions,
prior to the `\%do\%` call[@weston19:_nestin_loops].
The
last step to composition of foreach as capable of list comprehension
is the filtering function `\%when\%`, which filters iterables
based on some predicate to control evaluation.


## Implementation {#sec:implementation}

The mechanism of action in foreach is often forgotten in the face of
the atypical form of the standard syntax.
Going one-by-one, the
`foreach()`{.R} function returns an iterable object,
`\%do\%` and derivatives are binary functions operating on the
iterable object returned by `foreach()`{.R} on the left, and the
expression on the right; the rightmost expression is simply captured
as such in `\%do\%`.
Thus, the main beast of burder is the
`\%do\%` function, where the evaluation of the iteration takes
place.

In greater detail, `\%do\%` captures and creates environments, enabling
sequential evaluation.
`\%dopar\%` captures the environment of an
expression, as well taking as a formal parameter a vector of names of libraries
used in the expression, then passing that to the backend, which will in turn do
additional work on capturing references to variables in expressions and adding
them to evaluation environment, as well as ensure packages are loaded on worker
nodes.

`\%do\%` and `\%dopar\%`, after correct error checking,
send calls to `getDoSeq()`{.R} and `getDoPar()`{.R}
respectively, which return lists determined by the registered backend,
which contain a function used backend, used to operate on the main
expression along with other environmental data.

foreach depends strongly upon the iterators package, which gives the
ability to construct custom iterators.
These custom iterators can be
used in turn with the `foreach()`{.R} function, as the interface to
them is transparent.

## Form of Iteration}\label{sec:form-iter

The name of the package and function interface refer to the `foreach`
programming language construct, present in many other languages.
By definition, the `foreach` construct performs traversal over some
collection, not necessarily requiring any traversal order.
In this case, the collection is an iterator object or an object coercible to
one, but in other languages with foreach as part of the core language, such as
python (whose for loop is actually only a foreach loop), collections can
include sets, lists, and a variety of other classes which have an
`__iter__` and `__next__` defined[@python2020iter].

Due to the constraints imposed by a foreach construct, loop optimisation is
simplified relative to a for loop, and the lack of explicit traversal ordering
permits parallelisation, which is the primary reason for usage of the
`foreach` package.
The constraints are not insignificant however, and they do impose a limit on
what can be expressed through their usage.
Most notably, iterated functions, wherein the function depends on it's prior
output, are not necessarily supported, and certainly not supported in parallel.
This is a result of the order of traversal being undefined, and when order is
essential to maintain coherent state, as in iterated functions, the two
concepts are mutually exclusive.

In spite of the constraints, iterated functions can actually be emulated in
foreach through the use of destructive reassignment within the passed
expression, or through the use of stateful iterators.
Examples of both are given in listings [@lst:serial] and [@lst:serial-iter].

\begin{listing}
\begin{minted}{R}
x <- 10
foreach(i=1:5) %do% {x <- x+1}
\end{minted}
\caption{Serial iterated function through destructive reassignment}\label{lst:serial}
\end{listing}

\begin{listing}
\begin{minted}{R}
addsone <- function(start, to) {
	nextEl <- function(){
		start <<- start + 1
		if (start >= to) {
			stop('StopIteration')
		}
		start}
	obj <- list(nextElem=nextEl)
	class(obj) <- c('addsone', 'abstractiter', 'iter')
	obj
}

it <- addsone(10, 15)
nextElem(it)

foreach(i = addsone(10, 15), .combine = c) %do% i
\end{minted}
\caption{Serial iterated function through creation of a stateful iterator}\label{lst:serial-iter}
\end{listing}

As alluded to earlier, the functionality breaks down when attempting to run
them in parallel.
Listings [@lst:parallel] and [@lst:parallel-iter] demonstrate attempts to
evaluate these iterated functions in parallel.
They only return a list of 5 repetitions of the same "next" number, not
iterating beyond it.

\begin{listing}
\begin{minted}{R}
cl <- makeCluster(2)
doParallel::registerDoParallel(cl)
x <- 10
foreach(i=1:5) %dopar% {x <- x+1}
\end{minted}
\caption{Parallel Iteration attempt through destructive reassignment}\label{lst:parallel}
\end{listing}

\begin{listing}
\begin{minted}{R}
doParallel::registerDoParallel
foreach(i = addsone(10, 15), .combine = c) %dopar% i
\end{minted}
\caption{Parallel Iteration attempt through a stateful iterator}\label{lst:parallel-iter}
\end{listing}

## Extensions {#sec:extensions}

The key point of success in foreach is it's backend extensibility,
without which, foreach would lack any major advantages over a standard
`for` loop.

Other parallel backends are enabled through specific functions made
available by the foreach package.
The packages define their parallel
evaluation procedures with reference to the iterator and accumulator
methods from foreach.

Numerous backends exist, most notably:
\begin{description}
doParallel
: the primary parallel backend for foreach, using the
	      parallel package[@corporation19].
doRedis
: provides a Redis backend, through the redux package[@lewis20].
doFuture
: uses the future package to make use of future's many
	      backends[@bengtsson20do].
doAzureParallel
: allows for direct submission of parallel
	      workloads to an Azure Virtual Machine[@hoang20].
doMPI
: provides MPI access as a backend, using Rmpi[@weston17].
doRNG
: provides for reproducible random number usage within
	      parallel iterations, using L'Ecuyer's method; provides
	      `\%dorng\%`[@gaujoux20].
doSNOW
: provides an ad-hoc cluster backend, using the snow
	      package[@dosnow19].
\end{description}

## Relevance {#sec:relevance}

foreach serves as an example of a well-constructed package supported
by it's transparency and extensibility.

For packages looking to provide any parallel capabilities, a foreach
extension would certainly aid it's potential usefulness and
visibility.

# A Disk.Frame Case Study

## Introduction {#sec:introduction}

The mechanism of disk.frame is introduced on it's homepage with the
following explanation:

\begin{displaycquote}{zj20:_larger_ram_disk_based_data}
	{disk.frame} works by breaking large datasets into smaller
	individual chunks and storing the chunks in fst files inside a
	folder.
	Each chunk is a fst file containing a data.frame/data.table.
	One can construct the original large dataset by loading all the
	chunks into RAM and row-bind all the chunks into one large
	data.frame.
	Of course, in practice this isn't always possible; hence
	why we store them as smaller individual chunks.

		{disk.frame} makes it easy to manipulate the underlying chunks by
	implementing dplyr functions/verbs and other convenient functions
	(e.g.
	the (`cmap(a.disk.frame, fn, lazy = F)` function which
	applies the function fn to each chunk of a.disk.frame in parallel).
	So that {disk.frame} can be manipulated in a similar fashion to
	in-memory data.frames.
\end{displaycquote}

It works through two main principles: chunking, and generic function
implementation (alongside special functions).
Another component that
isn't mentioned in the explanation, but is crucial to performance, is
the parallelisation offered transparently by the package.

disk.frame is developed by Dai ZJ.

## Chunks and Chunking {#sec:chunking}

### Chunk Representation {#sec:chunk-representation}
% \item files in folder (https://diskframe.com/articles/04-ingesting-data.html#exploiting-the-structure-of-a-disk-frame)

disk.frames are actually references to numbered `fst` files in
a folder, with each file serving as a chunk.
This is made use of
through manipulation of each chunk separately, sparing RAM from
dealing with a single monolithic file[@zj19:_inges_data].

% \item Fst
Fst is a means of serialising dataframes, as an alternative to RDS
files[@klik19].
It makes use of an extremely fast compression
algorithm developed at facebook, with the R package enabling fst
written on in \href{survey-r-packages-for-local-large-scale-computing.pdf}{R
	Packages for Local Large-Scale Computing}.

% \item fst [ interface for disk.frame using fst backend, see internals
From inspection of the source code, data.table manipulations are
enabled directly through transformations of each chunk to data.tables
through the fst backend.

### Chunk Usage {#sec:making-chunks}

% \item ingesting data (https://diskframe.com/articles/04-ingesting-data.html),
% \item lazy evaluation
%   (https://diskframe.com/articles/02-intro-disk-frame.html#simple-dplyr-verbs-and-lazy-evaluation)
Chunks are created transparently by disk.frame; the user can
theoretically remain ignorant of chunking.
In R, the disk.frame object
serves as a reference to the chunk files.
Operations on disk.frame
objects are by default lazy, waiting until the `collect()`{.R}
command to perform the collected operations and pull the chunks into R
as a single data.table.
As noted in
[@zj19:_simpl_verbs_lazy_evaluat], this form of lazy evaluation is
similar to the implementation of sparklyr.

Chunks are by default assigned rows through hashing the source rows,
but can be composed of individual levels of some source column, which
can provide an enormous efficiency boost for grouped operations, where
the computation visits the data, rather than the other way around.

% \item add_chunk()
% \item get_chunk()
% \item remove_chunk()
Chunks can be manipulated individually, having individual ID's,
through `get_chunk()`{.R}, as well as added or removed from
additional fst files directly, through `add_chunk()`{.R} and
`remove_chunk()`{.R}, respectively.

% \item rechunk()
In a computationally intensive procedure, the rows can be rearranged
between chunks based on a particular column level as a hash, through
functions such as `rechunk()`{.R}.

## Functions {#sec:functions}

% \item constructor (as.disk.frame(), csv_to_disk.frame() (shard()) etc., and
%   accessors (collect())
The disk.frame object has standard procedures for construction and
access.
disk.frame can be constructed from data.frames and data.tables
through `as.disk.frame()`{.R}, single or multiple csv files through
`csv_to_disk.frame()`{.R}, as well as zip files holding csv files.
Time can be saved later on through the application of functions to the
data during the conversion, as well as specifying what to chunk by,
keeping like data together.
The process of breaking up data into
chunks is referred to by disk.frame as "sharding", enabled for
data.frames and data.tables through the `shard()`{.R} function.

% \item mapping: applying same function to all chunks cmap()
After creating a disk.frame object, functions can be applied directly
to all chunks invisibly through using the `cmap()`{.R} family of
functions in a form similar to base R `*apply()`{.R}

% \item dplyr verbs
A highly publicised aspect of disk.frame is the functional
cross-compatibility with dplyr verbs.
These operate on disk.frame
objects lazily, and are applied through translation by disk.frame;
they are just S3 methods defined for the disk.frame class.
They are
fully functioning, with the exception of `group_by` (and it's
data.table cognate, `[by=]`, considered in more detail in
subsection [@sec:spec-cons-group-by].

% \item dfglm()
Beyond higher-order functions and dplyr or data.table analogues for
data manipulation, the direct modelling function of `dfglm()`{.R}
is implemented to allow for fitting glms to the data.
From inspection
of the source code, the function is a utility wrapper for streaming
disk.frame data by default into bigglm, a biglm derivative.

### Grouping {#sec:spec-cons-group-by}

% \item group_by (https://diskframe.com/articles/group-by.html)
For a select set of functions, disk.frame offers a transparent grouped
\textrm{summarise()}.
These are mainly composed of simple statistics
such as `mean()`{.R}, `min()`{.R}, etc.

For other grouped functions, there is more complexity involved, due to
the chunked nature of disk.frame.
When functions are applied, they are
by default applied to each chunk.
If groups don't correspond
injectively to chunks, then the syntactic chunk-wise summaries and
their derivatives may not correspond to the semantic group-wise
summaries expected.
For example, summarising the median is performed
by using a median-of-medians method; finding the overall median of all
chunks' respective medians.
Therefore, computing grouped medians in
disk.frame result in estimates only --- this is also true of other
software, such as spark, as noted in [@zj19:_group_by].

% \item chunk_summarize(), chunk_group_by()
Grouped functions are thereby divided into one-stage and two-stage;
one-stage functions "just work" with the `group_by()`{.R}
function, and two-stage functions requiring manual chunk aggregation
(using `chunk_group_by` and `chunk_summarize`),
followed by an overall collected aggregation (using regular
`group_by()`{.R} and `summarise()`{.R}).
[@zj19:_group_by] points out that explicit two-stage approach
is similar to a MapReduce operation.

% \item custom one stage functions (https://diskframe.com/articles/custom-group-by.html )
Custom one-stage functions can be created, where user-defined chunk
aggregation and collected aggregation functions are converted into
one-stage functions by
disk.frame[@zj19:_custom_one_stage_group_by_funct].
These take the
forms `fn_df.chunk_agg.disk.frame()`{.R} and
`fn_df.collected_agg.disk.frame()`{.R} respectively, where
"`fn`" is used as the name of the function, and appended to
the defined name by disk.frame, through meta-programming.

% \item hard group-by
To de-complicate the situation, but add one-off computational
overhead, chunks can be rearranged to correspond to groups, thereby
allowing for one-stage summaries just through
`chunk_summarize()`{.R}, and exact computations of group medians.

## Parallelism {#sec:parallelisation}

An essential component of disk.frame's speed is parallelisation; as
chunks are conceptually separate entities, function application to
each can take place with no side effects to other chunks, and can
therefore be trivially parallelised.

% \item future
For parallelisation, future is used as the backend package, with most
function mappings on chunks making use of
`future::future_lapply()`{.R} to have each chunk mapped with the
intended function in parallel.
Future is a package with complexities
in it's own right; I have written more on future in the document,
\href{detail-future.pdf}{A Detail of Future}

% \item setup_disk.frame()
% \item https://diskframe.com/articles/concepts.html
future is initialised with access to cores through the wrapper
function, `setup_disk.frame()`{.R}[@zj19:_key].
This sets up
the correct number of workers, with the minimum of workers and chunks
being processed in parallel.

% \item
%   https://diskframe.com/articles/data-table-syntax.html#external-variables-are-captured:
%   external variables are captured
An important aspect to parallelisation through future is that, for
purposes of cross-platform compatibility, new R processes are started
for each worker[@zj19:_using].
Each process will possess it's own
environment, and disk.frame makes use of future's detection
capabilities to capture external variables referred to in calls, and
send them to each worker.

## Relevance {#sec:relevance}

disk.frame serves as an example of a very well-received and used
package for larger-than-RAM processing.
The major keys to it's success
have been it's chart-topping performance, even in comparison with dask
and Julia, and it's user-friendliness enabled through procedural
transparency and well-articulated concepts.

disk.frame as a concept also lends itself well to extension:

The storage of chunks is currently file-based and managed by an
operating system; if fault tolerance was desired, HDFS support for
chunk storage would likely serve this purpose well.

Alternatively, OS-based file manipulation could be embraced in greater
depth, focussing on interaction with faster external tools for file
manipulation; this would lead to issues with portability, but with
reasonable checks, could enable great speedups through making use of
system utilities such as `sort` on UNIX-based systems.

The type of file may also be open to extension, with other file
formats competing for high speeds and cross-language communication
including \href{https://github.com/wesm/feather}{feather}, developed
by Wes McKinney and Hadley Wickham[@wes16].

In terms of finer-grained extension, more functionality for direct
manipulation of individual chunks would potentially aid computation
when performing iterative algorithms and others of greater complexity.
% \item inspiration: transparency (find better word); disconnect between
% interface and implementation, with good access to internals
% \item good performance (https://diskframe.com/articles/vs-dask-juliadb.html)
% \item extension: HDFS storage of chunks
% \item single-chunk applications? map_chunk_id() map function on
%   individual chunk by id
% \item more external file operations on fst files outside R

# A Survey of s-u

## Introduction

%  Why s-u
%  overview of major areas
%  relevance to research

## iotools and DistributedR

% purpose and place
% download and run examples
% https://github.com/s-u/iotools
% https://github.com/s-u/iotools/wiki
% https://github.com/s-u/iotools/wiki/DistributedR
% read source

## Rserve and RSclient

% purpose and place
% download and run examples
% http://rforge.net/Rserve/doc.html
% https://github.com/s-u/RSclient
% read source

## hmr, hdfsc, and hbase

% purpose and place
% download and run examples
% https://github.com/s-u/hmr
% http://rforge.net/hmr/
% http://www.rforge.net/hdfsc/
% https://github.com/s-u/hbase
% http://www.rforge.net/hdfsc/
% read source

## roctopus

% purpose and place
% download and run examples
% https://github.com/s-u/roctopus
% read source

\printbibliography
\end{document}
