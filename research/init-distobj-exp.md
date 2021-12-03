---
title: Initial Distributed Object Experimentation with a Message Queue Communication System
date: 2020-09-08
---

# Introduction

Building on the infrastructure outlined in [the Report on Current Chunk Architecture](chunk-report.html), the aggragation of chunks as a distributed object is a logical continuation, and this document serves to record experimentation in the creation of such a feature.

For our purposes, a distributed object and it's reference is defined conceptually as the following:

> A distributed object is a set $D$ of chunks $c_1, c_2, \dots, c_n$, with some total ordering defined on the chunks.
> In a corresponding manner, distributed object *references* are sets of chunk references, along with an ordering on the chunk references to match that of the chunks composing the referent distributed object.

This definition will be expanded upon and serve to inform the nature of the following experiments.

# Formation

The first experiment is the most important, in composing a basic distributed object reference along with sufficient infrastructure to allow for operations to take place on the referent chunks composing the conceptual distributed object.
This section sees an informal description of the initial model, as well as issues in such a model, along with proposed solutions and an example implementation.

## Model Description

Following the given definition, as well as the existing infrastructure provided and outlined in [Chunk Report](chunk-report.html), the distributed object reference consists of an environment containing a list of chunk references.
The capacity for further components is reserved, however the prime information is encapsulated within the chunk references.

Some changes are made to the chunk references as described in [Chunk Report](chunk-report.html), based on the need for decoupling data from process when communicating among client and server.
This takes the principal form of removing the job ID in favour of posting chunk information directly to the distributed table as keys.
In this manner, all necessary information relating to a chunk ID is encapsulated in the chunk reference, with no need to couple this with job ID's and the implied necessity of a job reference.
As an example, the resolution status of a chunk ID (whether it has actually been created) is posted as a resolution key identified by the chunk ID in the distributed table, rather than being rolled into a message object and sent to a job ID queue.
This change has further motivations in allowing access to attributes of a chunk that may resolve asynchronously, by nodes other than the original requesting client.
For example, an as-yet undefined alignment process requires knowledge of chunk sizes, and may be taking place on a node separate and prior to determination of such information on another node, which upon realisation, posts the chunk size data to the distributed table, and the node performing alignment may now have access to that information despite not being the original requesting client.
This would not be possible were the job queue concept still used, as the chunk reference on the aligning node wouldn't have the ability to access the job queue, for lack of knowledge as well as the destruction it would cause by obstructing the original client in it's intended pop of the jobID queue.

In addition to the changes to the chunk reference, there is now the essential need for further information in the way chunks relate to each other as parts of a greater whole.
This is a heavily language-dependent aspect, as it relies on R's paradigmatic nature of being array-oriented.
R takes it's array-oriented style from S, which was in turn influenced by Iverson's APL and Backus' FORTRAN, both heavily array-oriented[@becker1994shistory; @iverson2007notation].
A central feature of array-oriented languages involves "parallel" (in array, not computational terms) operation on arrays with elements in corresponding indices; beyond serving as a store of information, arrays can be comparable with each other, and operations performed on associated elements between them.
This is obvious even in simple expressions such as `1:10 + 11:20`{.R}, wherein vectors are operated upon in adjacently.
This expectation raises a problem for operations on multiple distributed objects, where if the chunks holding adjacent elements are required for a multivariate operation yet exist on entirely separate nodes, there is no possibility for executing the operation absent movement of data.

The movement of data is to a degree not the most difficult aspect, but an immediate issue is the efficient co-ordination of such data movement, a process described here as *alignment*.
Alignment requires all elements adjacent and relevant to other elements in an operation to be located on the same node for processing.
Such a task is further compounded by the standard operation of recycling, wherein arrays of shorter length than others are copied end-to-end in order to achieve the same size.
An example is given in the expression `1:10 + 1:2`{.R}, where the second vector of length 2 is repeated 4 additional times in order to match the size of the larger.
This is a sufficiently common task that the system should provide it by default when moving data.

With these problems stated, a fuller description of the base model can now be entered into, with figure (MISSING) accompanying.

Similarly to chunk manipulation, the central function for performing operations is the `do.call()`{.R} function, with a method defined for
`distObjRef`. It possesses similar formal parameters to the standard `do.call()`{.R}, being `what`, `args`, and `assign`, which respectively describe the function to be called, a list of arguments to serve as arguments to `what`, and whether to return a value or to save the result and monitor it as a distributed object.

A node acting in the role of client will call a `do.call.distObjRef()`{.R} on a list of distributed object references, as well as non-distributed.
Of this list, one distributed object reference will be chosen as the target with which all alignment is to be performed relative to, with the function `findTarget()`{.R}.
From this target, `do.call.chunkRef()`{.R} is called with an additional `target` argument relating the target chunk, on all of the chunk references within the target, with the standard resultant messages being sent to the appropriate chunk queues.

The queues are monitored and popped by the nodes holding the chunks, and `do.call.msg()`{.R} is called on the popped message, taking the same arguments as `do.call.chunkRef()`{.R}.
Within `do.call.msg()`{.R}, `refToRec()`{.R} and `alignment()`{.R} are called to replace the reference objects in the `args` list with copies of their referent objects at indices analogous to the target chunk, thereby ensuring correctness in adjacent operations between arrays.

The standard `do.call()`{.R} is then used on the list of whole, aligned objects, with the results sent to keys in the distributed table associated with the new chunk ID, completing work on the server side.

## Model Issues

As presented, the model suffers from a fatal flaw when used asynchronously.
Alignment necessarily depends on knowing the indices of where in a distributed object a chunk belongs.
This information is attained from the distributed keys which the server sets based on the resultant chunk's size after `do.call.msg()`{.R}.
Upon receiving this information, a node holding a distributed object containing the appropriate chunk reference can cache this information within the chunk reference object, to avoid future lookups.

Therefore the distributed object references forming the list of `args` in `do.call.distObjRef()`{.R} can either have all of the index information cached inside, as a fully resolved object, avoiding any need for lookup in the table, or they may lack some of the information, being unresolved, and a lookup will have to be performed during alignment on the server end.

A race condition arises when the size of an unresolved object is needed during alignment, but that object is to be computed on that same node some time after completing the evaluation of the current `do.call.msg()`{.R}.

Formulated as a counter example:

Consider some distributed object containing fully resolved chunks belonging to a set ${c_1, c_2, \dots, c_n}$ for some finite $n$, all of which reside on a singular node $S$.
Let this object have reference `x` with full resolution on a node $K$.
1. The node $K$ may execute the expression  `y <- do.call.distObjRef(what=f1, args=list(x))()`{.R}, returning an unresolved distributed object reference and assigning it to the symbol `y`.
2. Following the model description, messages containing sufficient information on the request are pushed to all of the target chunk queues, which in this case, given that there is only one distributed object reference in `args`, are chunks $c_1, c_2, \dots, c_n$.
3. Node $S$ may pop from any of these queues in any order, so consider the first popped message to relate to chunk $c_m$ for some $1 \geq m \geq n$.
4. The server-side expression will take the form,  `do.call.msg(what=f1, args=list(<distObjRef x>), target=Cm, assign=TRUE)()`{.R}, where `<obj>` refers to the value of `obj`.
5. The expression will in turn call `refToRec()`{.R} and `alignment()`{.R} on `Cm` and the `args` list, which, given the resolved state of all chunks, will replace the `<distObjRef x>` in `args` with it's corresponding emerged object, in this case the referent of `Cm`.
6. Upon completion of performing `f1` on the new `args` list, the resultant chunk $c_{n+k}$ for $k > 0 $ is
7. added to the local chunk table of node $S$ for later retrieval, with it's queue also monitored, and
8. information on the size and other metadata of $c_{n+k}$ are obtained and sent to the distributed table for future reference.

9. If the node $K$ sent out another batch of requests based on the expression `do.call.distObjRef(what=f2, args=list(x, y))()`{.R}, and `x` is given as the target, then
10. with node $S$ popping from queue $c_m$ once again,
11. the following expression is then formed on $S$: `do.call.msg(what=f2, args=list(<distObjRef x>, <distObjRef y>), target=Cm, assign=TRUE)()`{.R}.
12. As before, the expression will call `refToRec()`{.R} and `alignment()`{.R} on `Cm` and the `args` list, but the relevant index information on the chunks belonging to the value of distributed object reference `y` is missing, and will be blocked indefinitely, as there is no means of determining where in the distributed object $y$ is the chunk adjacent to chunk `Cm`. The algorithm therefore never terminates in such a situation.

## Model Solutions

A client-side solution exists in forcing resolution of distributed object references prior to sending any messages to the chunk queues.
This guarantees that any information relating to chunk alignment is cached with each chunk reference, and that the server will always have access to this information.
This would be immediately implementable, but will have a significant corresponding drawback in removing prior asynchrony on the client end, blocking a `do.call.distObjRef()`{.R} until full chunk resolution of the underlying arguments.
It is therefore not a full solution in itself, but removes race conditions until a more complete solution is implemented.

The node acting as server presents a more likely candidate for the location of a solution to the race condition.
If the `do.call.msg()`{.R} was made concurrent through a backgrounding-like operation, the blocking until alignment data was available would remain, but with a guarantee of eventual availability of the data, thus allowing for termination.

## Solution Implementation

Implementation of server-side concurrency in the `do.call.msg()`{.R} and it's surrounding constructs implies a parallel operation such as that provided by the `parallel` package, located principally in the `mcparallel()`{.R} function.
An initial problem with reliance on `mcparallel()`{.R} is the fork produces copy-on-write semantics, and so storing chunks in the local chunk table becomes impossible when the chunk table is forked.
This may be overcome by removing the concept of a local chunk table, and storing all objects in the local `osrv` server, which, being a separate process, would not be forked itself.
A potential problem in this solution is in the memory management of `osrv`, and what would be done if references to the R objects are forked away, but the data is intended to remain on the server.

# Conclusion and Next Steps

TODO after implementing the above...

Initialisation

Chunk subset transfers

Decision Tree

Data Redundancy

With point to point data movement, full decentralisation possible if using a
distributed hash table to track chunk locations (apache cassandra etc.) in
order to have no central point of failure, along with local queues.

Randomly ordered distributed objects and their properties
