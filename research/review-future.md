---
title: A Detail of future
date: 2020-03-19
---

# Overview {#sec:overview}
\nocite{bengtsson19:_futur_r}

future is introduced with the following summary:

The purpose of this package is to provide a lightweight and unified future API for sequential and parallel processing of R expression via futures.
The simplest way to evaluate an expression in parallel is to use `x %<-% { expression `{.R}} with `plan(multiprocess)`{.R}. This package implements sequential, multicore, multisession, and cluster futures.
With these, R expressions can be evaluated on the local machine, in parallel a set of local machines, or distributed on a mix of local and remote machines.
Extensions to this package implement additional backends for processing futures via compute cluster schedulers etc.
Because of its unified API, there is no need to modify any code in order switch from sequential on the local machine to, say, distributed processing on a remote compute cluster.
Another strength of this package is that global variables and functions are automatically identified and exported as needed, making it straightforward to tweak existing code to make use of futures.[@bengtsson20]}

futures are abstractions for values that may be available at some point in the future, taking the form of objects possessing state, being either resolved and therefore available immediately, or unresolved, wherein the process blocks until resolution.

futures find their greatest use when run asynchronously.
The future package has the inbuilt capacity to resolve futures asynchronously, including in parallel and through a cluster, making use of the parallel package.
This typically runs a separate process for each future, resolving separately to the current R session and modifying the object state and value according to it's resolution status.

# Comparison with Substitution and Quoting {#sec:comparison-with-non}

R lays open a powerful set of metaprogramming functions, which bear similarity to future.
R expressions can be captured in a `quote()`{.R}, then evaluated in an environment with `eval()`{.R} at some point in the future. Additionally, `substitute()`{.R}
substitutes any variables in the expression passed to it with the values bound in an environment argument, thus allowing "non-standard evaluation" in functions.

future offers a delay of evaluation as well, however such a delay is not due to manual control of the programmer through `eval()`{.R} functions and the like, but due to background computation of an expression instead.

# Example Usage {#sec:examples}

Through substitution and quoting, R can, for example, run a console within the language.
Futures allows the extension of this to a parallel evaluation scheme.
[@lst:console] gives a simple implementation of this idea: a console that accepts basic expressions, evaluating them in the background and presenting them upon request when complete.
Error handling and shared variables are not implemented.

```{#lst:console caption="Usage of future to implement a basic multicore console"}
library(future)

multicore.console <- function(){
    get.input <- function(){
        cat("Type \"e\" to enter an expression for",
            "evaluation \nand \"r\" to see",
            "resolved expressions\n", sep="")
        readline()
    }

    send.expr <- function(){
        cat("Multicore Console> ")
        input <- readline()
        futs[[i]] <<- future(eval(str2expression(input)))
        cat("\nResolving as: ", as.character(i), "\n")
    }

    see.resolved <- function(){
        for (i in 1:length(futs)){
            if (is(futs[[i]], "Future") &
                resolved(futs[[i]])) {
                cat("Resolved: ", as.character(i), " ")
                print(value(futs[[i]]))
            }
        }
    }

    plan(multicore)
    futs <- list()
    i <- 1
    while(TRUE){
        input <- get.input()
        if (input == "e") {
            send.expr()
            i <- i + 1
        } else if (input == "r") {
            see.resolved()
        } else {
            cat("Try again")
        }
    }
}

multicore.console()
```

# Extension Packages {#sec:extension-packages}

doFuture
: [@bengtsson20do] provides an adapter for foreach[@microsoft20] that works on a future-based backend.
  Note that this does does not return foreach() calls as futures.
  The multicore features enabled with future are redundant over the existing parallel package, but because future backends can include other clusters, such as those provided by batchtools, there is some additional functionality, including additional degrees of control over backends.

future.batchtools
: [@bengtsson19batch] provides a future API for batchtools[@lang17], or equivalently, a batchtools backend for future.
  This allows the use of various cluster schedulers such as TORQUE, Slurm, Docker Swarm, as well as custom cluster functions.

future.apply
: [@bengtsson20apply] provides equivalent functions to R's `apply`{.R} procedures, with a future backend enabling parallel, cluster, and other functionality as enabled by backends such as batchtools through future.batchtools.

future.callr
: [@bengtsson19callr] provides a callr[@csardi20] backend to future, with all of the associated advantages and overhead.
  Callr "call[s] R from R".
  It provides functions to run expressions in a background R process, beginning a new session.
  An advantage of callr is that it allows more than 125 connections, due to not making use of R-specific connections.
  Additionally, no ports are made use of, unlike the SOCKcluster provided by the snow component of parallel.

furrr
: [@vaughan18] allows the use of future as a backend to purrr functions.
  purrr is a set of functional programming tools for R, including map, typed map, reduce, predicates, and monads.
  Much of it is redundant to what already exists in R, but it has the advantage and goal of adhering to a consistent standard.

# Further Considerations {#sec:further-considerations}

One initial drawback to future is the lack of callback functionality, which would open enormous potential.
However, this feature is made available in the *promises* package, which has been developed by Joe Cheng at RStudio, which allows for user-defined handlers to be applied to futures upon resolution[@Cheng19].

Issues that aren't resolved by other packages include the copying of objects referenced by future, with mutable objects thereby unable to be directly updated by future (though this may be ameliorated with well-defined callbacks).
This also means that data movement is mandatory, and costly; future raises an error if the data to be processed is over 500Mb, though this can be overridden.

Referencing variables automatically is a major unsung feature of future, though it doesn't always work reliably; future relies on code inspection, and allows a `global`{.R} parameter to have manual variable specification.

It seems likely that the future package will have some value to it's use, especially if asynchronous processing is required on the R end; it is the simplest means of enabling asynchrony in R without having to manipulate networks or threads.
