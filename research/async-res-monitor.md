---
title: Asynchronous Server-Side Resolution Monitoring
date: 2020-09-24
---

N.B. There were originally some TiKz figures that have since been lost; the document may make less sense without them.

# Introduction

The advantages of asynchrony in the system come with significant costs, with an example of a race condition arising from asynchrony examined in [Initial Distributed Object Experiments](ini-distobj-exp.html).
The correctness of this system is not altered by asynchrony in itself, but the object models and the state of resolution in particular are clear derivatives of errors.
In the general case, every message containing a list of distributed references for arguments contains the implicit dependency on the resolution of those distributed arguments which must be forced prior to emerging and aligning them as part of standard server operations.
When unresolved references are sent through to a node that can only resolve them after evaluating the current message, rather than being able to rely on another node for generating a resolution, a deadlock situation arises.
This document shows some potential solutions to the issues associated with the model in asynchronous flow.

# Alternating Recursive Blocking Pop and Evaluation {#sec:recurs-stack}

Rather than blocking and waiting for resolution of distributed references, an alternative model recurses on the `server`{.R} function upon encountering unresolved references, returning upon an evaluation which possibly serves to resolve the relevant distributed reference.
Given that resolution dependencies form a directed acyclic graph, due to references only being created out of existing references, and assuming a fixed set of messages, any unresolved reference that leads to recursion will eventually be resolved upon evaluation of it's associated message by either another node, or more importantly, by the same node at some deeper level of recursion.
This solution uses the call stack as a central data structure.
It is equivalent to performing a blocking pop on the message queues, then pushing the message on a stack, and either evaluating the content of the message or returning to the message queues, depending on whether the references in the message are in the state of being resolved or not, respectively.

Potential for a problem arises when a node is at some recursive step, having unresolved references, and is in the state of waiting on the message queues.
If the references contained on the node's stack all depend on jobs that are evaluated by other nodes, thereby being marked for resolution themselves, and no more messages come through in any of the monitored queues, the server is in a state of having the messages on the stack ready for evaluation, yet it will instead stay listening on it's queues indefinitely, never terminating.

This issue can be weakened by changing the pop of the message queues to be non-blocking.
With this in place, given a message with unresolved references, a server would recurse, perform a pop on the message queues, and either receive an element, and perform as previously specified, or receive no element and return to check if the message has references resolved yet, repeating the process until resolution of the original message has taken place, thereby ideally servicing every message that arrives to the node.

The stack data structure serves to limit even this change, in association with the fact that popped message queues have no ordering defined between them, with such an ordering having no means of imposition.
An example of non-termination can be given by constructing a directed acyclic graph of dependencies, then having the stack filled in such a manner that the ability to move to a state of evaluation is impossible.

# Inbox List Controlling Finite State Machine {#sec:inbox-list}

The example issue given in [@sec:recurs-stack] is intrinsic to the use of the call stack as a data structure.
Were this to be replaced with an alternative, such as a list, ideally circular, there is the potential for overcoming the problem.
For example, if popped messages were placed on a list and paired with an associated procedure which iterates along them, checking their resolution status and evaluating if possible, returning eventually to read the queues, then assuming finite messages, there will be no issues as in [@sec:recurs-stack].

One very obvious issue with such an approach is the inefficiency of polling, which this solution relies upon.
In addition, the number of polls for checking resolution are bounded only by the evaluation time of the relevant prerequisites, which is theoretically unbounded - making the poll particularly inefficient.

# Job Completion Queues

An amendment to the solution proferred in section [@sec:inbox-list] is to have the resolution status of chunks propagated to every relevant node while they were listening to queues already.
This may take several forms.

Possibly the simplest is to have resolution queues, as clarified job queues, associated with each chunk reference to listen to for its resolution status, if unresolved.
A problem occurs if multiple nodes are interested in the same chunk reference's resolution status, and one nodes' pop will result in no information reaching the other, though a gossip-like protocol of immediately pushing the information back on the list after popping can get around this, ensuring that all interested parties attain the information.
This has the cost of a large number of messages moving back and forth, as well as the forced serialisation of one node strictly popping after another, waiting for every round-trip.

Alternatively, a two-part solution, could be performed with all interested nodes posting their interest to some queue, and upon resolution the server first posts the resolution status as a key for all interested future nodes, then pushing directly to relevant queues for all of the nodes on the interest queue.
Resolution lookup will reflect this in first posting interest on the interest queue, then checking for a key, before monitoring the interest queue and performing associated cleanup afterwards.
The unusual ordering of operations as part of resolution lookup ensures atomicity, with there being no possibility of missing either a key or a queue on the client end, as given through the following proof:

Consider the moment a client has successfully posted interest on the interest queue.
At this point, there are two relevent states for server communication, dependent on whether the server has posted a key or not.

If the server has not yet posted the key, then the client is guaranteed notification via either the server posting a key just before the client scans for one, or the server pushing to the client's queue after the server posts the key, were the client to move past the operation of scanning for a key, prior to the server posting one.

If the server has posted the key, the client will then pick it up as part of the next operation.

The solution is well paired with a local inbox with tracking of dependencies associated with messages in the inbox.
This solution ensures none of the documented race conditions, no polling inefficiencies, and a reasonable number of messages sent.
