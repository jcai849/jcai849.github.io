---
title: Considerations on a Functional Iterative Interface
date: 2020-05-19
---

# Introduction

A *functional* iterative interface may be a suitable interface to the platform.
An explicit interface has benefits over recursion in that R has little optimisation for recursion either through tail call elimination or call stack manipulation [@rcore2020lang].
Being *functional* entails referential transparency, purity, and operational access through functions [@cousineau1998functional].
The benefits brought by referential transparency include most notably for this platform, sufficient encapsulation such that backends can be switched out without requiring alteration of the code [@strachey2000fundamental].
Additionally, the design and terminology of the function offers a close mapping to the mathematical notation of a recurrence relation.

This can be contrasted with a non-functional approach, which in it's most efficient form in R would entail defining an iterator object, which pulls the act of implementation closer to the details of object definition rather than, as on paper, the function definition [@analytics19].

This particular interface attempts to emulate notation of iterated functions of the following form:

$$
x_{n+1} = x_n
$$

With the function body aiming to map as closely as possible a standard mathematical notion of iterated functions:

$$
f^0 = id_x
$$
$$
f^{n+1} = f \circ f^n
$$

# A Higher-Order Model for Iterative Functions

A draft interface sees a function taking the following form:

`iter(x0, ..., P, fn)`

Where the formal parameters include,

- `x0`  as the initial object to iterate upon;
- `...` as additional objects to iterate upon;
- `P`   as the predicate to cease iteration upon evaluating false, and;
- `fn`  as the iterated function

A means of referring to prior returned objects of `fn` within `P` and `fn` would have to be defined.
This could take the form of reserved names such as `xn`, `xn\_1`, ... `xn\_n` to refer to the output of `fn`, the prior output of `fn`, and so on, respectively, as well as `x1`, `x2`, ... `xn` to refer to the output of the $n$th iteration.
Memory could be spared through parsing `P` and `fn` and only keeping the value of those names which are referenced in `P` and `fn`.

Through this interface, iterated functions are clearly defined without the need for explicit loop control structures, and through the transparancy of the function, may swap in backend-specific mechanisms of action.
This function may be defined as a generic, with appropriate backend-specific methods dispatched based on the class of `x0`.

As an example of an iterated function, a GLM can be defined using this interface, as outlined in [@lst:glm]:

```{#lst:glm .R caption="GLM Implementation"}
# include definitions for X and y

pr <- function(X, B){
		1 / (1 + exp(-X  %*% B))
		}

fn <- function(B){
	W <- diag(as.vector(pr(X, B)))
	hessian <- - t(X) %*% W %*% X
	z <- X %*% B + solve(W) %*% (y - pr(X, B))
	B <- solve(-hessian) %*% crossprod(X, W %*% z)
	B
}

x0 <- matrix(x(0,0))

P <- quote(colSums(xn_1 - xn)^2) > tolerance)

iter(x0, P, fn)
```

# Implementation Details

Internally, a while loop with predicate `P` runs function `fn` on it's returned output, starting with `x0`.
A basic, non-generic implementation could take the form of [@lst:basic-imp]:

```{#lst:basic-imp .R caption="Implementation structure"}
iter <- function(x0, P, fn){
	ModifyBaseEnv(P, fn)
	while (P) {
		xn <- fn(xn)
		ModifyLoopEnv(P)
	}
	xn
}
```

Note:
- `ModifyBaseEnv(P, fn)` is required in the case that `P` or `fn` references variables such as `xn\_1`; In this case, the reserved names are linked to the initial input variables up to the n'th input variable.
- `ModifyLoopEnv(P)` is required in the same case as the previous, wherein the environment is modified to hold the additional variable references.

Optimisations can include inlining the function through substitution in order to minimise object movement.

Various backends could be used.
As an example, sparklyr could be run through being passed an `x0` of class `spark\_tbl`, wherein the appropriate method would be dispatched.
This method would enclose the `fn` function calls within `mutate`, and perform other enhancements such as caching directives.
sparklyr could just as easily be bypassed, with some serialisation of the closure `fn` performed and sent directly to Spark, if Spark allows for such an operation.

# Potential Further Developments

Explicit embarrassing parallel sections may be specified as additional arguments;
With an appropriate backend, these parallel functions are changed to be processed in parallel, with the converted functions fed into the environment of the iterated function.
As a corollary, the partitioning of data may be manually specified to ensure good performance under parallelisation.

Communicative parallelism is significantly more difficult to capture in the design of such an interface, with most parallel R packages ignoring such a construct [@bengtsson20}; @core:_packag}; @matloff16softw_alchemy}; @vaughan18].
However, it is conceivable that such functions can also be delivered as formal parameters to the `iter` function, though it is as yet unclear how to integrate this cleanly.

# Conclusion

While this functional API does provide a simple abstract interface, it comes at the cost of lacking clear communication directives.
Multivariable iterated functions are also difficult to manage; they can be contained in a list as a single formal parameter, but this limits the generic capability of the function to dispatch methods based on the class of the initial object `x0`.
Such a cost is bearable by some applications, but limits the platform excessively at this early stage;
In addition, the necessity of reference to prior and named output has led to the usage of a set of reserved names, beginning to create something of a domain-specific language.
This can be powerful if executed perfectly, but will be difficult to implement and may prove difficult to debug and make use of if not expertly implemented.
it may be better to pursue this idea at a later point in time, pending development of the more primitive platform details.
