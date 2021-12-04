---
title: Project Overview
date: 2020-10-20
---

# Introduction

How does a statistician compose and fit a novel modelling algorithm in R for a dataset consisting of over 165 million flight datapoints?
More generally, how does one perform a statistical analysis in R over a dataset too large to fit in computer memory?
There are many solutions to this problem, all involving a variety of tradeoffs.

What is needed is a platform that is fast and robust, with a focus on a simple interface for fitting statistical models, and the flexibility for implementation of arbitrary new models within R.

In this document I will provide some context of other solutions to the problem of large datasets for R, before describing *distObj*, the focus of my project which aims to provide a powerful platform for large-scale statistical modelling with R; the interface, architecture, and further development goals of distObj will be explained in detail.

# State of the Field

R provides a means of shared extensions called packages, similar to libraries or modules in other languages. Several packages exist which answer some of the need for large-scale statistical analysis.

The most integral data structure for data analysis in R is the data frame; it can be conceived of as effectively a table, wherein each column may be of differing type.
The package *disk.frame* provides a class which interfaces transparently as data frames, with the data being stored on disk[@zj20].
In this way, the dataset size may be expanded to as large as disk capacity, along with the associated speed drawbacks[@zj19:_key].
Other limitations exist, including the fact that grouped data operations require shuffling of the data on disk, making performance somewhat unpredictable, as well as many operations being of practical necessity estimates, such as determination of median, as such an operation is too slow to perform out of core[@zj19:_group_by; @zj19:_custom_one_stage_group_by_funct].

While keeping the data on disk presents some solution to the lower end of large-scale, the speed losses and lack of resilience offered by a single machine are excessive once the statistician is presented with truly large data.
For this, external distributed systems are typically relied upon.

The R package *sparklyr* presents an R interface to Spark[@luraschi20].
The user connects to Spark and accumulates instructions for the manipulation of Spark DataFrame objects, before executing the request on the Spark cluster.
This is implemented primarily through translation of the instructions to SparkSQL in the backend.
While the package opens up enormous capabilities for the R world, it shares Sparks limitations, with most of the statistical analyses that are available being pre-made, with little room for novel algorithms written in R, especially in an iterative context.

The *pbdR* project also provides interfaces to external distributed systems, including MPI, ZeroMQ, and others[@pbdR2012; @pbdBASEpackage].
Of the many packages delivered by the project, they also provide a user-end package, *pbdDMAT*, which offers classes encapsulating distributed matrices, which have near-identical interfaces to standard R matrices.
Like *sparklyr*, *pbdDMAT* shares equivalent limitations with the systems it depends upon, including most notably, a lack of interactivity, being only able to run in batch mode through MPI.

Another group of packages attempting to solve the problem of large-scale data has taken the approach of leaving backends more general, and providing new constructs in R to handle big data.
*SNOW* is foremost among these packages, allowing a cluster to be initialised through R, typically with socket connections, then providing mapping commands and the like to automatically process data through the cluster[@tierney18].
This is a powerful capability, though it suffers from having a lack of persistence in the distributed data.

*foreach* is a package that follows and builds upon *SNOW*, providing a foreach construct in R[@microsoft20].
foreach is a fairly well-known concept in most other high-level programming languages, behaving in a similar manner to a for-loop, with the generalisation that the order of iterations is left arbitrary.
From such a generalisation, parallelisation of the loop is trivial, and the *foreach* package allows for a variety of backends to be registered to handle the loop processing, with *SNOW* among these.
In spite of the incredibly simple user interface, the limitations are the same as those of the backend that it rests upon, and there is no persistence of distributed objects.

Outside of the R package ecosystem, an enormously capable distributed system that satisfies many of the necessities of large-scale data analysis is provided in the Python world with Dask[@rocklin2015dask].
Dask provides a platform for large-scale computations, though like most Python modules, it was not built with statistical analysis as it's central aim, and falls short for such an aim because of it.

# System Interface

What dictates the success of many of the existing platforms is the interface to the system.
At the basic level, R is a statistical programming language, for statisticians, not system administrators, and a large-scale platform demanding admin skills to set up and use is bound for failure.
Beyond the negative determinants of success in a distributed system interface, it should ideally go further and offer as user-friendly an interface as possible.
Taken to the ideal extreme, the statistician using the system may forget for most tasks that they are using a distributed platform.
Realistically, multiple levels of control should be offered, with more serious programming taking place at an explicitly distributed level.

As it currently stands, the prototype *distObj* packages does have such delineation between levels, with most work having been done at the programmer level, rather than the user level.
A description of some of the more important features follows.

At the heart of the system are the distributed objects.
These objects encapsulate information on various distributed chunks, and aim to emulate the underlying objects they reference, through taking advantage of R's S3 generic object system.
Specifically, the value returned by some arbitrary function, with the distributed object taken as an argument, should be precisely the same were that distributed object replaced with it's referent object.

At a lower level, such a claim is relaxed, by offering future-like behaviour in distributed objects, wherein rather than the computed value being returned immediately, a new distributed object is returned with information on the computation of the new value, and can at some point be resolved to produce the value.
The future aspect allows for extremely powerful capabilities, such as asynchrony in the distributed computation, though such asynchrony introduces thorny new problems, with some solutions to be discussed in [@sec:sys-arch]

The principal function enabling computation over distributed objects is a variant on R's `do.call()`{.R} function.
`do.call()`{.R} takes the function that is to be performed as it's first argument, followed by a list of objects to pass in as arguments to that function.
In this way, something of a lisp-like operator-operand manner of specifying computation can be performed, and nearly every function in R can be computed using `do.call()`{.R}.
Therefore, the point of entry for computation over distributed objects is through derivatives of `do.call()`{.R}, which have the capacity to ensure computation on all of the chunks and return the appropriate distributed objects.

At some point, the records pointed to by distributed objects will be desired by the user, and so an `emerge()`{.R} exists to pull all of the distributed data into the currently running local session.

Individual chunks may also be addressed, and routines run on them, with a simple opening available at the programmer level.

Finally, this system is highly extensible. Nearly any new class with methods to split into chunks can be represented in this platform, again taking advantage of R's S3 generic object system.

# System Architecture {#sec:sys-arch}

The architecture of the system is both the point of departure from other systems, as well as the source of speed and stability.

Again, the distributed object is core to the system, defined by the following:

> A distributed object is a set \(D\) of chunks \(c_1, c_2, \dots, c_n\), with some total ordering defined on the chunks.
> In a corresponding manner, distributed object \textit{references} are sets of chunk references, along with an ordering on the chunk references to match that of the chunks composing the referent distributed object.

The general layout of the system follows a mostly decentralised structure, with chunks of distributed objects being held in nodes that hold roles of both client and server.
There is one main initiator and controlling session that holds references to the distributed objects, and sends initial requests for computation.
A central feature is the usage of message queues to co-ordinate computation; each chunk in the system has a unique ID, and the nodes holding the chunk monitor queues identified by that same ID.
Every computation involving a particular chunk has relevant information pushed to said chunk's queue, and a node holding that chunk will pop from the queue and perform whatever is requested, including pushing to other chunk's queues.
This is currently implemented using Redis lists.
Computations requiring chunks that exist on disparate nodes will naturally demand relocation of some chunks so that computation can procede at one single location; this is managed through a threaded object server, using the *osrv* package[@urbanek2020osrv].

The nature of R also produces other considerations; most notably, R is a vectorised language, with computation commonly occuring directly over vectors where in most other languages would require looping over an array. Thus what may be represented in C as 

```{#lst:cvec .C}
	int i;
	int x[] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
	int y[] = { 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 };

	for (i=0; i < 10; i++)
		sum += x[i] + y[i]; 
	mean = sum / 10;
```

can be given in R simply as

```{#lst:rvec .R}
	x = 1:10
	y = 11:20
	mean(x+y)
```

The vector-oriented programming paradigm is extremely valuable for statistical computation, with some other languages, notably Fortran and APL, also having similar features.
Functions involving multiple vectors are where the capacities truly shine, however problems are raised when vectors have differing lengths, with a trivial example being `1:10 + 1:2`{.R}, where two vectors of length 10 and 2 are attempted to be summed together.
The standard R mechanism of response is to "recycle" the shorter vectors, repeating them end-to-end to match the length of the longest vector.

This is particularly difficult to implement in an efficient distributed manner, as the pieces of chunks that are involved in computation together may exist in entirely seperate locations.
It is solved by selecting one distributed object to be the target object, based on some metric including length, then sending computation messages to the queues representing the chunks composing the distributed object.
At the node hosting the chunks, the correct indices of the other objects to be recycled are determined, and are then requested from their host nodes and subset appropriately.


1. The process is initialised on a node which will act as a client, with `do.call.distObjRef()`{.R} call, using at least one distributed object reference in the arguments.
2. Of the distributed object references, one is picked as a target, for which the nodes hosting the chunks making up the referent distributed object will serve as the points of evaluation, with all other distributed object chunks eventually transported to these nodes.
3. One message for each chunk reference within the distributed object reference is sent to the corresponding nodes hosting the chunks, via the chunk queues.
   The message contains information including the requested function, the arguments to the function in the form of a list of distributed object references as well as other non-distributed arguments, and the name with which to assign the results to, which the client also keeps as an address to send messages to for any future work on the results.
   The client may continue with the remainder of its process, including producing a future reference for the expected final results of evaluation.
4. Concurrent to the initialisers further work after sending a message, the node hosting a target chunk receives the message, unpacks it and feeds the relevant information to `do.call.msg()`{.R}.
5. All distributed reference arguments are replaced in the list of arguments by their actual referents, using the alignment and object-sending process described above.
6. `do.call()`{.R} is then used to perform the terminal evaluation of the given function over the argument list.
7. The server then assigns the value of the `do.call()`{.R} to the given chunk name within an internal chunk store environment, sending relevant details such as size and error information back to the initial requesting node.
   The object server is also supplied with a reference to the chunk, used to send the chunk point-to-point upon request.

A diagram depicting the primary calls is given in figure (MISSING)

As it currently stands, return communication to the requester from the node performing the computation on the chunk takes place through job queues, the access information encapsulated in the new distributed object on the requester end; any tasks on the new distributed objects require task completion, signalled through the job queues, with any further information on the job queues cached locally in the distributed object.
It has been determined that there are some mixed semantics and potential issues with asynchrony in using job queues, and these are to be replaced with distributed keys and job interest queues (to be described in the next section), along with an appropriate garbage collection routine to delete old keys.

# Next Steps

There is still significant work that needs to be done, even for prototypical features.

The problem of enabling asynchrony without the system itself facing inherent race conditions is decidedly nontrivial.
Asynchronous evaluation in this system is foundationally dependent on when computation on distributed objects is complete, and equivalently, when the new distributed objects acting as futures can be resolved.
Sending resolution status via a job queue is insufficient if multiple nodes are interested in the result of compuation, as only one node will receive the message.
Thus I have proposed a two-part system, where nodes register interest in the results as part of a queue monitored by the server, as well as check a key, with a specific ordering of events as depicted in figure (MISSING) to ensure atomicity.
Garbage collection of resolution keys, beyond a simple timeout, is still to be determined.

A feature of nearly all modern distributed systems for data processing is the capacity for resilience in the face of hardware failure.
This is, likewise, a necessity for the platform described herein, and has been implicitly allowed for in the flexibility entailed by chunk queues.
This concept requires further development and refinement before being added as a system component.

With the high level of decentralisation given by such an architecture, especially relative to the original RPC-based master-worker paradigm explored in a previous incarnation, it is worth exploring how much further such decentralisation can be pushed.
If it proves to not impact performance to heavily, many emergent effects of decentralisation may imbue themselves in the system, such as high scalability and further resilience.
