---
title: Chunk ID Origination and Client-Server Communication
date: 2020-09-03
---

N.B. There were originally some TiKz figures that have since been lost; the document may make less sense without them.

# Introduction

The problem of chunk ID origination as discussed in [Initial Chunk Message Queue Experiments](init-chunk-msg-q-exp.html) dictates much of the client-server communication, as well as the state of knowledge in the network, given that chunk ID is used as the key to send messages relevant to a particular chunk.
This document serves to model the differences between naive client-originated chunk ID's, and server-originated chunk ID's, with an evaluation and proposal that aims at overcoming the limitations involved in the models.

# Modelling {#sec:cid-model}

The models consist of communication over time between a client and a server, intermediated by a queue server.
The client runs the pseudo-program described in [@lst:client-p],
where variables `x`{.R}, `y`{.R}, and `z`{.R} are chunk references, and variables `i`{.R} and `j`{.R} are local.
Every action on distributed chunk references entails pushing a message to the queue named by the associated chunk ID, requesting the relevant action to be performed.

```{#lst:client-p .R caption="Modelled Client Program"}
	y <- f(x)	# dist, no wait
	f(i)		# local
	z <- f(y)	# dist, no wait
	f(j)		# local
	f(z)		# dist, wait
```

The server follows a loop of listening on queues relevant to the chunks that it stores and performing requests from the messages popped in order from them, through taking the function relayed in the message and performing it on the local object identified by the chunk ID given by the queue name the message was popped from.
Without loss of generality, the function `f`{.R} is considered to take constant time on local objects, and messages likewise have constant latency; the ratio of latency to operation time is irrelevent to what is demonstrated in these models.
Assignment, message listening, and message switching by the queue are considered to be instantaneous events.
The models are depicted as space-time diagrams, with modifications to the
original styling[@lamport1978ordering], including colour coding, where the colours aim to make each job more distinct.

## Client-Originated Chunk ID

In the client-originated chunk ID  model, in addition to the generic model description posed in [@sec:cid-model], the client sends a chunk ID as part of its messages if the result of the function on the distributed object includes assignment.
If there is no assignment, the message includes a job ID instead, naming a job queue to be monitored by the client.
If the server receives a job ID, it sends the value of the computed function to the queue with that job ID as it's key, sending no messages otherwise.

## Server-Originated Chunk ID

In the server-originated chunk ID model, given that the client doesn't know the chunk ID of created chunk references, leaving that to the server, it sends out messages with job IDs, creating chunks references that at first reference the job ID, but when the actual chunk ID is required, waiting on the job ID queue for a message containing it's chunk ID.
The server correspondingly sends chunk IDs of each newly assigned chunk to the job ID queue specified in the request, sending values instead if not directed to perform assignment.

# Evaluation {#sec:mod-eval}

Clearly, the server-originated chunks result in significantly more waiting on the client end, as the chunk ID needs to be attained for every operation on the associated chunk, which is only able to be acquired after completing the function.

The server could in theory send the chunk ID prior to performing the requested operation, but that leads to significant issues when the operation results in error, as it is difficult to communicate such a result back to the client after performing the function.
Despite the reduced time spent blocking, the client-originated chunk ID modelled also has issue with errors; consider if the `x <- f(y)`{.R} had been faulty, with the resultant operation of \texttt{f(C1)} rendering an error.
This would not be determined by the client untile the completion of `f(z)`{.R}, in which an error would presumably result.
Worse, if the chunk reference `x`{.R} was given as an additional argument to another server, which in turn requested the chunk `C1`{.R} from the node `C1`{.R} resided upon, the error would propagate, with the source of the error being exceedingly difficult to trace.

# Proposal

A potential solution to the problems of the models posed in [@sec:mod-eval] is to treat chunk reference objects somewhat like futures, which have a state of `resolved`{.R} or `unresolved`{.R}, with failures also encapsulated in the object upon resolution [@bengtsson19:_futur_r].

If chunk ID is client-originated, then its outgoing messages can also supply a job ID for the server to push a message to upon completion that the client can in turn refer to, in order to check resolution status as well as any potential errors.

This would capture the benefits of the modelled client-originated chunk ID in reduces wait time, with the robustness of server-originated ID in signalling of errors.
The introduction of future terminology of `resolved()`{.R}, as well as additional slots in a chunk to determine resolution state, as well as the use of job ID queues for more than just value returns will be sufficient to implement such a design.
The asynchrony may lead to non-deterministic outcomes in the case of failure, but the use of `resolved()`{.R} and it's associated barrier procedure, `resolve()`{.R} will enable the forcing of a greater degree of synchrony, and allow tracing of errors back to their source in a more reliable manner.
