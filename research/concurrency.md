---
title: An Exploration of Concurrency in R
date: 2021-11-29
---

> Quod est superius est sicut quod inferius, et quod inferius est sicut quod est superius.
>
> That which is above is like to that which is below, and that which is below is like to that which is above.[@steele1928table]

# Introduction

In a complex distributed system of coarse or fine grain, I/O by way of inter-node communication leads to major constraints on the individual nodes.
Synchronous blocking I/O is more than just a speed bottleneck; it has the potential to lock and completely prevent essential sections of program execution.
Distributed systems are invariably concurrent at a system-level.
A concurrent system in the macro scale (inter-node) is well supported by concurrency in the micro scale (in-process).

While not utterly essential, concurrency in R would be exceptionally useful in the implementation of the project distributed system.
If lacking, perhaps it can be added.
This report follows the investigation into what exists, and what the possibilities are for concurrency in R.
The TL;DR is given in [@sec:no].
Note that this report follows the definition of concurrency in the strict sense, and is not to be conflated with parallelism, as described by Rob Pike[@pike2012concurrency].

# Promises

Promises are a data structure-based mechanism of handling concurrency[@liskov1988promises].
Promise objects serve to represent operations that may occur at some point in time, with the completion of the operation marking a change in state of the promise object from "unresolved" to "resolved".
Most importantly, promise objects posses a `then()`{.R} method, which registers a callback to be run at some point following the resolution of the associated promise, itself returning a promise representing the completion of said callback.
Chains of `then()`{.R}s are then used to cleanly compose concurrent operations.

R has a *promises* package, clearly influenced by JavaScript's A+ promises[@cheng2021promises].
If it can do as "promised", much of the problem of concurrency is solved in R.

An initial test is given in [@lst:promise-work].
Note in this listing that there is a very mild race condition in that the prompt is printed in the final line, with the operation of the `then()`{.R} immediately following.
So far it looks like it is functioning.

```{#lst:promise-work .R caption="A fully-functioning promise"}
> library(promises)
> p <- promise(function(resolve, reject) resolve(TRUE))
> print(p)
<Promise [fulfilled: logical]>
> then(p, onFulfilled = function(value) print(value))
> [1] TRUE
```

Attempting a simple equivalent outside of an empty stack leads to problems, as shown in [@lst:promise-not-work].
Here, as long as there are frames on the stack, the `then()`{.R} callback is never triggered.
This may make sense in the avoidance of re-entrancy problems, though it is hardly very well advertised.

```{#lst:promise-not-work .R caption="A non-functioning promise"}
> {function() {
+     p <- promise(function(resolve, reject) resolve(TRUE))
+     print(p)
+     then(p, onFulfilled = function(value) print(value))
+     repeat {}
+ }}()
<Promise [fulfilled: logical]>

^C
> [1] TRUE
```

Can this be worked around?
[Promise domains](https://gist.github.com/jcheng5/b1c87bb416f6153643cd0470ac756231) appear to be an immediate answer to this, however it remains unsatisfactory, due to the requirement that they are eventually called at the top level; forcing evaluation on a busy stack isn't what they were designed for.
Perhaps this can be solved by investigating the reason for this constraint.
If `then()`{.R}s could just be evaluated anywhere in the stack, race conditions far more serious than a prompt mis-print are certain to manifest.
If it were possible to [explicitly state](http://ithare.com/eight-ways-to-handle-non-blocking-returns-in-message-passing-programs-with-script/) where evaluation may be safe to take place, perhaps this could be avoided.

Analysis of the *promises* source code reveals a dependency on the *later* package for asynchronous execution, and this is what has lead to the leaky abstraction [@chang2021later].
The central `later()`{.R} function offered by the package is equivalent to JavaScript's `setTimout()`{.JavaScript} function, and also only executes when there is no other R code on the execution stack.
Operations may be forced in *later* with `run_now()`, however, and this may serve as an appropriate mechanism for forcing evaluation.
This is shown in [@lst:promise-forced].

```{#lst:promise-forced .R caption="A forced promise"}
> {function() {
+     p <- promise(function(resolve, reject) resolve(TRUE))
+     print(p)
+     then(p, onFulfilled = function(value) print(value))
+     repeat {
+     later::run_now()
+     }
+ }}()
<Promise [fulfilled: logical]>
[1] TRUE
```

Jumping down a layer of abstraction does appear to solve this problem.
However, given that `run_now()`{.R} must be manually called, a new problem is added; scheduling of `then()`{.R}s is now partially in "userspace".
At this point it is worth looking at alternatives, because the code is starting to become complex, with manual event-loop cycling guaranteed to lead to bugs.

A layer up is the *coro* package[@henry21coro].
This makes use of *promises* as part of an emulation of coroutines.
Analysing the source code reveals the creation of a state machine that attempts to replicate R's evaluator, but with allowances for re-entrancy.
This is an impressive piece of work, but to build a serious platform on such a Rube Goldberg contraption is to massively constrain the platform to very implementation-dependent details.
At this point, it is worth considering custom solutions.

# Attempted Solution

An initial attempt at a solution was to use continuations in R to implement promises, with coroutines as a base [in a similar manner to how it may be implemented in scheme](https://ds26gte.github.io/tyscheme/index-Z-H-15.html#TAG:__tex2page_sec_13.4).
Unfortunately, continuations in R are downwards-only, and so can't be relied upon for proper coroutine or promise implementation.

I [attempted a solution without continuations](https://github.com/jcai849/promise): replicate promises, but have the `then()`{.R} run at any point, without needing to force it or be on the top level.
This involved the creation of a package that was mostly written in C, to create Promise types, as given in [@lst:promise-struct], and perform their evaluation.

```{#lst:promise-struct .C caption="Internal structure of promises"}
typedef struct Promise {
    int fd;
    char state[STATE_SIZE+1];
    SEXP value;

    struct Promise *then[MAX_THENS]; /* private */
    int then_i;		             /* private */

    SEXP onFulfilled; /* used only for then */
    SEXP onRejected;  /* used only for then */
} Promise;
```

The intention was to attach it to R's event loop, using the `addInputHandler()`{.C} function from `R_ext/eventloop.h`.
This didn't achieve the goal, as R's event loop only scans the input handlers at the top level (or when `Sys.sleep()`{.R}ing), leaving us back to where we started.

At this point I decided to look at how other languages enabled concurrency, as the options had run dry within R.

# Other Concurrency Paradigms

Most other mainstream languages have explicit concurrency as a part of the language.
This isn't necessarily a failing of R.
Much of the uptake of concurrency among languages only began in earnest relatively recently, motivated by web servers and services.
Furthermore, R is still at heart a DSL for statistics - it is not teleologically dependent on concurrency as a feature of the language.

Regardless, concurrency has proven to be extremely useful, and it's value is clear in a distributed system;
it is worth exploring further models in detail.

## Threading

Threading is a very low-level model of [preemptive multitasking](https://en.wikipedia.org/wiki/Preemption_(computing)), where independent "threads" run within a process and are interrupted and context switched by some scheduler, typically the operating system.
R is strictly single-threaded.
Foreign C functions can be called that themselves involve threading, but all direct interaction with R must remain single-threaded.

[pthreads](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html) is the standard option for threading in C for R.
The library offers aspects that may enable concurrency with R, such as mutexes for critical regions involving R code.

However, it remains very low-level, not lending itself well to the rapid prototyping required for research computing.
Furthermore, the scalability of threads is poor, with each thread taking up nontrivial memory, and facing operating system restrictions on total number.

Threads certainly have their place, but can't be depended upon as the central mechanism for concurrency.

## Async/Await

Async/await is a recent pattern in many programming languages.
The name stems from the syntactic constructs which between them enable [cooperative multitasking](https://en.wikipedia.org/wiki/Cooperative_multitasking).
A function defined with an `async`{.python} keyword may be `await`{.python}ed upon in certain contexts.
As explained well by [BBC's Cloudfit](https://bbc.github.io/cloudfit-public-docs/asyncio/asyncio-part-1.html), what takes place is that when a scheduler or event loop encounters an `await`{.python}, the scheduler may be thought of as "bookmarking" the position in program execution, and may jump to any other position that is being `await`{.python}ed, and so on until one of the functions being `await`{.python}ed returns, whereupon execution will continue from that point to the next `await`{.python}.
Key examples, though with very different implementations, include [Python asyncio](https://docs.python.org/3/library/asyncio.html) and [JavaScript's async/await](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function).
The async/await paradigm has had massive uptake, with nearly all major programming languages supporting it, though it is not without [criticism](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/).

An example of how async/await may appear within R in the context of the node in the distributed system, is given as [@lst:aior]

```{#lst:aior .R caption="Imaginary async/await in R"}
# N.B. await sleep immediately prior to non-blocking io is roughly equivalent to awaits on async io

main <- async(function() repeat { # this spins; see main2 for a more efficient implementation
    await(async_sleep(0))
    request <- nonblocking_read()
    if (anything_read(request))
        create_task(process_request(request))
})

process_request <- async(function(request) {
    args <- await_lapply(prereqs(request), emerge)
    result <- tryCatch(do.call(computation(request), args), error=identity) # todo: parallel optimisation
    if (response_needed(request))
        send(address(request),result)
})

emerge <- async(function(id) { # Also spinning
    val <- NULL
    while (is.null(val)) {
        await(async_sleep(0))
        val <- get_from_local_cache()
        if (is.null(val))
            val <- non_blocking_get_from_other_host() # a la aiohttp
    }
    store(id, val)
    val
})

async_run(main())

# Non-spinning; relying on some imaginary external async io functions

main2 <- async(function() repeat {
    request <- await(async_read(in_sock)) # c.f. aiohttp
    if (anything_read(request))
        create_task(process_request(request))
})

emerge2 <- async(function(id) {
    val <- async_gather(async_get_from_local_cache(id),
                        async_get_from_other_host(id))
    store(id, val)
    val
})
```

This depends on the ability to re-enter a context in R.
Before exploring the potential for this, there is one other model to be investigated.

## Communicating Sequential Processes

*Communicating Sequential Processes* as a model for concurrency stems from Tony Hoare's formal language for describing interaction in a concurrent system[@hoare1978communicating].
In this model, "processes" may be spawned, and can communicate between each other over channels.
Upon sending a message, a process must wait for the receiver to read the message - channels are unbuffered, and the point of execution at a message being received from a sender is known as a "rendezvous" between sender and receiver.
Like async/await, the rendezvous point is a signal for the scheduler or event loop to transfer control to any other point of rendezvous, thereby enabling asynchrony.
The rendezvous is therefore a point of synchronisation, a powerful feature that implicitly sweeps away whole categories of race conditions.
Go has made famous it's goroutines as taking inspiration from CSP[@gomem2014].
More recently, Java is experimentally overhauling it's threading model to use similar concepts in it's ["Project Loom"](https://cr.openjdk.java.net/~rpressler/loom/loom/sol1_part1.html), and GNU Guile has recently included ["fibers"](https://wingolog.org/archives/2017/06/27/growing-fibers) as a variation on CSP as inspired by Concurrent ML.

An example of how a CSP-based concurrency may appear in a node of the distributed system is given in [@lst:csp].
Notably, it is the cleanest and clearest of all the concurrency models assessed thus far.

```{#lst:csp .R caption="CSP as imagined in R"}
main <- function() {

    server <- channel()
    storage <- channel()
    waiting_worker <- channel()
    complete_worker <- channel()
    spawn(routine=serve, channel=server)
    spawn(routine=store, channel=storage)
    repeat {
        select(
            server = function(request) {
                spawn(routine=work, channel=waiting_worker)
                send(channel=waiting_worker, value=c(request, complete_worker))
            },
            complete_worker = function(resolution) {
                send(channel=storage, value=value(resolution))
                if (response_needed(resolution))
                    send(channel=return_address(resolution),
                         value=value(resolution))
            }
        )
    }
}

serve <- function(channel) {
    outside_world <- socket_init()
    repeat send(channel, receive(outside_world))
}

work <- function(channel) {
    send_to_emerger <- function(x) {
        emerger <- channel()
        spawn(routine=emerge, channel=emerger)
        send(channel=emerger, value=x)
        emerger
    }
    request_and_main <- receive(channel)
    request <- request_and_main[[1]]
    main <- request_and_main[[2]]
    prereq_count <- length(prerequisites(request))
    emergers <- lapply(prerequisites(request), send_to_emerger)
    prereqs <- select(list=emergers)
    result <- do.call(computation(request), prereqs)
    send(main, result)
}

store <- function(channel) {
    storage <- new.env()
    repeat {
        item <- receive(channel)
        assign(id(item), value(item), storage)
    }
}

emerge <- function(channel) {
    item <- receive(channel)
    send(channel, GET(id(item), address(item)))
}
```

# Coroutines

This all lead to my grand realisation about cooperative multitasking (nothing new; apparently everyone else already knew this): Under the hood, it's effectively all coroutines, and these models of asynchrony are largely just variations on access to coroutines.
Jumping in and out of a function at will is exactly what a coroutine offers.
Surprisingly few languages possessed coroutines until recently, in spite of the clear need.
I was actually familiar with coroutines as introduced by the Art of Computer Programming, but didn't quite recognise them in this context until late.
Amusingly, Donald Knuth used a [constructed assembly language](https://www-cs-faculty.stanford.edu/~knuth/mmix.html) for his Art of Computer Programming series, with a major contributing factor to this choice being the lack of coroutines in higher-level languages[@knuth1].
Perhaps if coroutines were more common at the time of writing, several decades of computer science research could have been spared, TAOCP would have been infinitely more readable and delivered in it's final form, along with Knuth's proof of his belief that $P=NP$.

# R will never be concurrent {#sec:no}

So, is it fixable?
According to Simon Urbanek of the R core team, effectively...

> No.

The implementation of evaluation in R precludes any chance of re-entering contexts, and will remain that way unless there is a near-complete rewrite. Dr. Urbanek elaborates:

> I had a quick look at R and having non-linear contexts is by definition (close to) impossible. The contexts contain many global variables that are stacks themselves, so they can only be unwound linearly down. Hence you cannot have "forks" in contexts due to the stack nature of many things in R (handlers stacks, promise stacks, byte-compiler stacks, ...). To make it even more fun, some are actually local C stack variables, so both R design and C stack is involved here. So allowing this would require some serious re-write of R internals... :/

# References
