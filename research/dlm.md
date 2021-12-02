---
title: "dlm: Distributed Linear Models"
date: 2021-07-05
---

# Overview

To serve as a demonstration and test of modelling using the *largeScaleR* system, the canonical statistical model, the linear model, was chosen for implementation.
While simple to derive the mathematics detailing a linear model, the naive method doesn't map straightforwardly to a distributed system.
This is due to matrix inversion and multiplication operations requiring more than isolated chunkwise information.
Conveniently, the common method of decomposing a matrix, typically for computationally simplified inversion, is given in a chunked form as part of Algorithm AS274 [@miller1992as274].
This algorithm is in turn implemented and wrapped through the *biglm* package in R with several additional features such as such as sandwiching [@lumley2013biglm].
The *biglm* package creates a linear model object from some initial row-wise chunk of data with a space complexity of $mathcal{O}(p^2)$ for $p$ variables.
The linear model object is then updated sequentially with further chunks of the data, until all of the data has been read, yielding a final linear model object with methods available for standard linear model object inspection, including summaries and predictions.
This sequential rolling update over chunked data is able to be captured succinctly in a `Reduce()` pattern typical of the functional programming paradigm.
Using the \textit{iris} dataset as an example, a linear model of the form,
$$ Petal.Length_i = Sepal.Width_i + Sepal.Length_i + Sepal.Width \times Sepal.Length + \epsilon_i$$
is fitted using *biglm* as part of a demonstrative non-distributed `Reduce()` in [@lst:lm-reduce].

```{#lst:lm-reduce .R caption="Splitting the iris dataframe into 15 chunks stored as elements of a list and reducing over the list with the biglm update function."}
library(biglm)

nc <- 15
cs <- split(iris, cumsum((seq(nrow(iris)) - 1) %% nc == 0)) # split to chunks
model <- Reduce(f = update, x = cs[-1],
		init = biglm(Petal.Length ~ Sepal.Width * Sepal.Length, cs[[1]]))
```

The *largeScaleR* package provides the distributed Reduce, `dreduce`, as discussed in the dreduce document.
The `dreduce` is therefore to be used as an equivalent structural backbone for the implementation of a distributed linear model.

# Implementation Details

The implementation of the distributed linear model is succinct enough to be given in it's entireity in [@lst:dlm].

```{#lst:dlm .R caption="Full listing of distributed linear model implementation."}
dlm <- function(formula, data, weights=NULL, sandwich=FALSE) {
	stopifnot(largeScaleR::is.distObjRef(data))
	chunks <- largeScaleR::chunkRef(data)
	stopifnot(length(chunks) > 0L)
	dblm <- dbiglm(formula, chunks[[1]], weights, sandwich)
	if (length(chunks) != 1L)
		largeScaleR::dreduce(f="biglm::update.biglm",
				     x=largeScaleR::distObjRef(chunks[-1]),
				     init=dblm)
	else init
}

dbiglm <- function(formula, data, weights=NULL, sandwich=FALSE) {
	stopifnot(largeScaleR::is.chunkRef(data))
	sys.call <- largeScaleR::currCallFun(-1)
	largeScaleR::do.ccall(what="biglm::biglm",
			      args=list(formula=largeScaleR::envBase(formula),
					data=data,
					weights=largeScaleR::envBase(weights),
					sandwich=sandwich),
			      target=data,
			      insert=list(sys.call=largeScaleR::envBase(sys.call)))
}
```

This implementation includes several important aspects.
Mapping to the list of chunks, an existing distributed object must be transformed to a list of chunks for the reduce function.
The reduce function itself is accessed through a light wrapper `dreduce()`, with all of the internal code operating transparently on chunks without concern for the type of object.
A major divergence is given in the generation of the initial reduction object.
This uses a `do.ccall` function to create the initial biglm linear model object, which is then passed to the `dreduce()` function.

## The Special Case of Call Capturing

A more significant divergence than different initialisation, with severe performance implications, is shown through the intercept and insertion of the function call.
This is made necessary by the fact that *biglm* captures the call it was called with, and stores it as part of the model object -- this is not unique to *biglm*, and this behaviour is common to most modelling functions in R.
Due to actually enacting the call to construct the inital *biglm* linear model object on the worker process, rather than the master process, with worker processes evaluating requests through construction with the `do.call()` function, rather than exact replication of the initial call, the call as seen by the function is not necessarily the same as that issued on the master process.
This presents two problems: inaccuracy, and unbounded call sizes.
Inaccuracy is not an enormous problem, as the call isn't typically used for anything other than rendering a portion of the string representation of the model object.
The greater issue is that as calls are constructed on the worker, all arguments are evaluated, and the captured call will include fully expanded objects in a `dump()`-like form.
This object may very well have a larger memory footprint than all of the arguments to the call combined, and will lead to memory limitations and slowdowns, particularly when transferring the model object from process to process.

The solution to this is twofold: allow new insertion environments to be inserted to the requested function on the worker for the purpose of non-destructive masking; and capture the call on the master end, wrapped into a function returning the call, and insert into the new insertion environment to take the place of the previous call capture function.

An insertion environment follows the simple concept of being placed between some function and the function's original enclosing environment for the purpose of having it's objects first on the search path, for masking or perhaps making previously global variables available.
Its form is given in the diagram at Figure \ref{fig:ins-env}.\img[caption={Newly inserted environment mimicking the insertion procedure of a linked list, with pointers given by arrows, and the old pointer in dashed line.}]{ins-env}

The call is captured on the master end, with a function constructed to return this call, given by the *largeScaleR*-provided `currCallFun()`, and this is then sent to the worker to be inserted as `sys.call()` in the insertion environment, thus effectively masking the call capture function at the top level of the requested *biglm* function.
Depending on perspective, the fact that this only works at the top level can be a feature, as it doesn't messily mask further along the call stack, however it has the associated limitation.

Worth noting is that call capture is notoriously messy, with *biglm* itself featuring source code directly manipulating the call as part of some functions.
