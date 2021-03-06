---
title: DistObj Non-Assigned Data Return
date: 2020-10-07
---

# Introduction

While most operations over the distributed system explicitly produce values that are to be assigned and saved, there comes a point, particularly with interactive data analysis, where values are to be explicitly returned without assignment.
Many high-level operations implicitly depend on value returns, such as map-reduce style operations as part of the data collation prior to the reduce step.

While the structure of assigned operations is well-defined, there remains plenty of room for discussion of value-return architecture.

# Current Implementation

As it currently stands, assignment or not is indicated through an argument to the `do.call.distObjRef()`{.R} function, with a similar procedure being followed to assignment, in terms of messaging and the like, though instead of returning a reference to the new distributed object, `do.call.distObjRef()`{.R} waits for a message containing values to be returned, and returning those.
This pattern, while reasonable in the macro scale, sits on an inefficient and ad-hoc implementation where value-containing messages pass as queues through the redis server.
This means that an extra node is added to the journey of the value from server to client, as well as potentially overloading the redis server and slowing all communication down at the central point of failure.

# Proposed Form

An improved form would make use of the osrv package to enable point-to-point data movement.
There is more work than just replacing messages with polling the server for the value, due to polling being an expensive operation for both sides.
A better form would involve going through the regular assignment procedure, then waiting for resolution and taking advantage of the existing `emerge()`{.R} function to transfer the result, followed by a new command to delete the unnecessary values from the server.
