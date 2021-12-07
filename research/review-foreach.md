---
title: A Review of foreach
date: 2020-04-02
---

# Introduction {#sec:introduction}

foreach introduces itself on CRAN with the following description:

> Support for the foreach looping construct. Foreach is an idiom that
> allows for iterating over elements in a collection, without the use
> of an explicit loop counter. This package in particular is intended
> to be used for its return value, rather than for its side effects.
> In that sense, it is similar to the standard lapply function, but
> doesn't require the evaluation of a function. Using foreach without
> side effects also facilitates executing the loop in parallel.[@microsoft20]

From the user end, the package is conceptually simple, revolving entirely around a looping construct and the one-off backend registration.

The principal goal of the package, which it hasn't strayed from, is the enabling of parallelisation through backend transparency within the foreach construct. Notably, more complex functionality, such as side effects and parallel recurrance, are not part of the package's intention.

Thus, the primary driver for the practicality of the package, beyond the support offered for parallel backends, is the backends themselves, currently enabling a broad variety of parallel systems.

foreach is developed by Steve Weston and Hoong Ooi.

# Usage {#sec:usage}

foreach doesn't require setup for simple serial execution, but parallel backends require registration by the user, typically with a single function as in the registration for doParallel, `registerDoParallel()`{.R}.

The syntax of foreach consists of a `foreach()`{.R} function call next to a `%do%`{.R} operator, and some expression to the right[@weston19:_using].
Without loss in generality, the syntactic form is given in [@lst:syntax].

```{#lst:syntax .R caption="Standard foreach syntax"}
foreach(i=1:n) %do% {expr}
```

The `foreach()`{.R} function can take other arguments including changing the means of combination along iterations, whether iterations should be performed in order, as well as the export of environmental variables and packages to each iteration instance.

In addition to `%do%`{.R}, other binary operators can be appended or substituted.
Parallel iteration is performed by simply replacing `%do%`{.R} with `%dopar%`{.R}.
Nested loops can be created by inserting `%:%`{.R} between main and nested foreach functions, prior to the `%do%`{.R} call[@weston19:_nestin_loops].
The last step to composition of foreach as capable of list comprehension is the filtering function `%when%`{.R}, which filters iterables based on some predicate to control evaluation.

# Implementation {#sec:implementation}

The mechanism of action in foreach is often forgotten in the face of the atypical form of the standard syntax.
Going one-by-one, the `foreach()`{.R} function returns an iterable object, `%do%`{.R} and derivatives are binary functions operating on the iterable object returned by `foreach()`{.R} on the left, and the expression on the right; the rightmost expression is simply captured as such in `%do%`{.R}.
Thus, the main beast of burder is the `%do%`{.R} function, where the evaluation of the iteration takes place.

In greater detail, `%do%`{.R} captures and creates environments, enabling sequential evaluation.
`%dopar%`{.R} captures the environment of an expression, as well taking as a formal parameter a vector of names of libraries used in the expression, then passing that to the backend, which will in turn do additional work on capturing references to variables in expressions and adding them to evaluation environment, as well as ensure packages are loaded on worker nodes.

`%do%`{.R} and `%dopar%`{.R}, after correct error checking, send calls to `getDoSeq()`{.R} and `getDoPar()`{.R} respectively, which return lists determined by the registered backend, which contain a function used backend, used to operate on the main expression along with other environmental data.

foreach depends strongly upon the iterators package, which gives the ability to construct custom iterators.
These custom iterators can be used in turn with the `foreach()`{.R} function, as the interface to them is transparent.

# Form of Iteration {#sec:form-iter}

The name of the package and function interface refer to the `foreach`{.R} programming language construct, present in many other languages.
By definition, the `foreach`{.R} construct performs traversal over some collection, not necessarily requiring any traversal order.
In this case, the collection is an iterator object or an object coercible to one, but in other languages with foreach as part of the core language, such as python (whose for loop is actually only a foreach loop), collections can include sets, lists, and a variety of other classes which have an `__iter__`{.R} and `__next__`{.R} defined[@python2020iter].

Due to the constraints imposed by a foreach construct, loop optimisation is simplified relative to a for loop, and the lack of explicit traversal ordering permits parallelisation, which is the primary reason for usage of the `foreach`{.R} package.
The constraints are not insignificant however, and they do impose a limit on what can be expressed through their usage.
Most notably, iterated functions, wherein the function depends on it's prior output, are not necessarily supported, and certainly not supported in parallel.
This is a result of the order of traversal being undefined, and when order is essential to maintain coherent state, as in iterated functions, the two concepts are mutually exclusive.

In spite of the constraints, iterated functions can actually be emulated in foreach through the use of destructive reassignment within the passed expression, or through the use of stateful iterators.
Examples of both are given in listings [@lst:serial] and [@lst:serial-iter].

```{#lst:serial .R caption="Serial iterated function through destructive reassignment"}
x <- 10
foreach(i=1:5) %do% {x <- x+1}
```

```{#lst:serial-iter .R caption="Serial iterated function through creation of a stateful iterator"}
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
```

As alluded to earlier, the functionality breaks down when attempting to run them in parallel.
Listings [@lst:parallel] and [@lst:parallel-iter] demonstrate attempts to evaluate these iterated functions in parallel. They only return a list of 5 repetitions of the same "next" number, not iterating beyond it.

\begin{listing}
```{#lst:parallel .R caption="Parallel Iteration attempt through destructive reassignment"}
cl <- makeCluster(2)
doParallel::registerDoParallel(cl)
x <- 10
foreach(i=1:5) %dopar% {x <- x+1}
```

```{#lst:parallel-iter .R caption="Parallel Iteration attempt through a stateful iterator"}
doParallel::registerDoParallel
foreach(i = addsone(10, 15), .combine = c) %dopar% i
```

# Extensions {#sec:extensions}

The key point of success in foreach is it's backend extensibility, without which, foreach would lack any major advantages over a standard `for`{.R} loop.

Other parallel backends are enabled through specific functions made available by the foreach package.
The packages define their parallel evaluation procedures with reference to the iterator and accumulator methods from foreach.

doParallel
: the primary parallel backend for foreach, using the parallel package[@corporation19].

doRedis
: provides a Redis backend, through the redux package[@lewis20].

doFuture
: uses the future package to make use of future's many backends[@bengtsson20do].

doAzureParallel
: allows for direct submission of parallel workloads to an Azure Virtual Machine[@hoang20].

doMPI
: provides MPI access as a backend, using Rmpi[@weston17].

doRNG
: provides for reproducible random number usage within parallel iterations, using L'Ecuyer's method; provides `%dorng%`{.R}[@gaujoux20].

doSNOW
: provides an ad-hoc cluster backend, using the snow package[@dosnow19].

# Relevance {#sec:relevance}

foreach serves as an example of a well-constructed package supported by it's transparency and extensibility.

For packages looking to provide any parallel capabilities, a foreach extension would certainly aid it's potential usefulness and visibility.
