---
title: Report on Current Chunk Architecture
date: 2020-09-07
---

N.B. There were originally some TiKz figures that have since been lost; the document may make less sense without them.

# Introduction

The purpose of this report is to outline the workings of the present architecture at the chunk layer.
This follows the experiments recorded in [Initial chunk message queue experiments](init-chunk-msg-q-exp.html), with the final experiment providing the basis for modifications allowing a self-sufficient distObj package, along with the modifications recommended by [Chunk ID Origination](chunk-id-orig.html).

The functionality of the package can be demonstrated through installing distObj and it's prerequisites, and, with a running `redis-server`, evaluating `demo("chunk-server", package="distObj")`{.R} in one R process, and `demo("chunk-client", package="distObj")`{.R} in another process on the same host, stepping through the `chunk-client` demo to control operation, with the results appearing similar to those recorded in [@tbl:chunk-comm].

# Overview

The central units of this distributed system are a client, a queue server, and a chunk server.
The client contains chunk references, which can be passed as arguments to `do.call.chunkRef`{.R}, alongside some function, in order to begin the process of evaluation, and if assignment is desired, producing a new chunk reference to continue computation with on the client end while the evaluation continues on the other units.
`do.call.chunkRef` composes a message based on the request, pushing that to the queue identified by the chunk ID contained in the chunk reference, with the queue existing on some central queue server.
The chunk server concurrently monitors all queues identified by the chunk ID's of the chunks that the chunk server stores in a local chunk table.
It pops the message off the related queue, and has `do.call.chunk` evaluate the function on the chunk, with various options determined by the content of the received message.
The chunk server pushes some response message to the queue associated with that particular job through a unique job ID, which may be picked up later by the client later.

# Object Formats

The fields belonging to a `chunkRef` object are the following:

`CHUNK_ID`
: The name of the queue to post messages to, as well as the name of the chunk existing on the server to perform operations upon.

`JOB_ID`
: The name of the queue to pop a response from.

`RESOLUTION`
: The status of whether a response has been heard from the server, taking the values ``UNRESOLVED'', ``RESOLVED'', or a condition object signalling an error.

`PREVIEW`
: A small preview of thcomplete object for use in printing.

Messages all belong to the `msg` class, and are currently categorised as either requests, or responses, with the following fields:

Request:

`OP`
: Directive for server to carry out, e.g. `ASSIGN`.

`FUN`
: Function object or character naming function to perform on the chunk.

`CHUNK`
: Chunk Reference for the server to attain information from.

`JOB_ID`
: The name of the queue to push a response to.

`DIST_ARGS`
: Additional distributed arguments to the function.

`STATIC_ARGS`
: Additional static arguments to thfunction.

Response:

`RESOLUTION`
:  Resolution status; either `RESOLVED`, or a condition object detailing failure due to error.

`PREVIEW`
: A small snapshot of the completed object for use in printing chunk references.

# Demonstration of Communication

[@tbl:chunk-comm] shows a demonstration of verbose communication between a client and a server.
In this demo, the server was started immediately prior to the client, being backgrounded, and initial setup was performed in both as per the listings referred to prior.


Time (secs)  Message
-----------  -------
0            Assigned chunk to ID: chunk1 in chunk table
	     `x <- do.call.chunkRef(what="expm1", chunkArg=chunk1)`{.R}
0.001664     Attained job ID:  J1
0.002719     Attained Chunk ID:  C1
0.00292      Requesting to perform function expm1 on chunk chunk1 with assignment
0.003521     writing message: ASSIGN expm1 <environment: 0x55cc164cb8c8> NULL NULL J1 C1 to queue belonging to chunk" chunk1 "
0.0051       Producing new chunk reference with chunk ID: C1 and job ID: J1
	     `y <- do.call.chunkRef("as.Date", x)`{.R}
0.005679     Attained job ID:  J2
0.005986     Attained Chunk ID:  C2
0.006159     Requesting to perform function as.Date on chunk C1 with assignment
0.006622     writing message: ASSIGN as.Date <environment: 0x55cc165d0808> NULL NULL J2 C2 to queue belonging to chunk" C1 "
0.007351     Producing new chunk reference with chunk ID: C2 and job ID: J2
	     `expm1(1:10)`{.R}
	     `x`{.R}
0.007811     Chunk not yet resolved. Resolving...
0.008025     Awaiting message on queues: J1
0.028962     Awaiting message on queues: chunk1
0.029668     Received message: ASSIGN expm1 <environment: 0x55a7a47917e0> NULL NULL J1 C1
0.030912     Requested to perform function expm1
0.031777     writing message: RESOLVED 1.718282, 6.389056, ..., to queue belonging to chunk" J1 "
0.03237      Assigned chunk to ID: C1 in chunk table
0.032679     Awaiting message on queues: C1     chunk1
0.032695     Received message: RESOLVED 1.718282, 6.389056, ...
0.033206     Received message: ASSIGN as.Date <environment: 0x55a7a4863308> NULL NULL J2 C2
	     `do.call.chunkRef("identity", x, assign=FALSE)`{.R}
0.033662     Attained job ID:  J3
0.033825     Requested to perform function as.Date
0.033893     Requesting to perform function identity on chunk C1 with no assignment
0.034363     writing message: DOFUN identity <environment: 0x55cc165d0808> NULL NULL J3 NULL to queue belonging to chunk" C1 "
0.034363     Error occured: 'origin' must be supplied
0.034655     writing message: 'origin' must be supplied, as.Date.numeric(c(...)) to queue belonging to chunk" J2 "
0.03519      Awaiting message on queues: J3
0.035544     Assigned chunk to ID: C2 in chunk table
0.035747     Awaiting message on queues: C1     C2     chunk1
0.036224     Received message: DOFUN identity <environment: 0x55a7a48ed380> NULL NULL J3 NULL
0.036737     Requested to perform function identity
0.037004     writing message: 1.718282, 6.389056, ..., to queue belonging to chunk" J3 "
0.03742      Awaiting message on queues: C1     C2     chunk1
0.037675     Received message: 1.718282, 6.389056, ...
	     `resolve(y)`{.R}
0.038197     Chunk not yet resolved. Resolving...
0.038325     Awaiting message on queues: J2
0.038825     Received message: 'origin' must be supplied, as.Date.numeric(c(...))

Table: Communication between a client and server {#tbl:chunk-comm}

# Next Steps

The next step is to experiment with aggregates of chunks, as distributed objects.
A significant component of this involves point-to-point chunk movement, between multiple servers.
The package `osrv` looks to satisfy much of the infrastructure required for this, with particular experiments to be dedicated specifically to establishing a fast and reliable mechanism for co-ordination and data movement in the system.
