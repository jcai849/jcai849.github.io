---
title: Distributed Architecture Informal Assumptions and Considerations
date: 2020-07-26
---

# Introduction
Following several weeks of development on a prototype distributed platform, a large number of architectural choices have had to be made, covered in the series of reports, [Experiment: Eager Distributed Object](experiment-eager-dist-obj-supp.pdf).
An attempt to outline some of the assumptions leading to these decisions is made in [@sec:assumptions], as a means of making explicit what is otherwise left implicit and potentially unquestioned.
Potential future assumptions with interesting consequences are considered in [@sec:potential].

At the current iteration of this text, only a few assumptions are laid out, however more will be progressively added following further development and consideration.

# Present Assumptions {#sec:assumptions}

Assumption: The large data made use of in the platform originates externally and comes pre-distributed.
If the data were instead being originated entirely locally, as in a simulation, the memory required would soon be excessive for a single computer.
Data appropriate for this platform is too large for a single machine, so it can't have been originated all at once from a single machine.
There may be room in the future ofor consideration of streaming data recording and generation that distributes local *ex nihilo* data, but that is a separate concern to that of the platform for modelling on that data.
Beyond the slightly tautological argument, experience shows that most large-scale data dealt with by a standard statistician is sourced externally.
Consequences of this assumption include the complete removal of `as.distributed` from user-space, as it is at odds with such an assumption.
Combined with a means of deriving locations of data chunks for import, such as through user-provided file URI's, or hadoop locations, this enables the removal of the concept of cluster objects from user-space.
A removal of cluster objects may lead to potential difficulties upon attempting operations involving multiple independently-read objects, as they may be unaligned, existing in different locations.
This leads to the consideration that alignment of distributed objects should be an operation with side-effects, thereby ideally letting the expensive operation of data movement occur only once between a pair of unaligned objects.
A corollary of removing cluster objects is a change in semantics; if, for example, a library is to be loaded across all nodes on a cluster, the declaration is no longer, "load the library at these specific locations." rather it becomes, "load the library everywhere relevent to this distributed object."

Asumption: The platform makes use of parallelism as a means for handling large data, in order to cope with memory constraints, and any potential speed-ups are a secondary side-effect.
Consider the counterfactual, that the principal concern was not large data, but parallelism for speed: CPU-bound, not memory-bound operations.
In this kind of system, high levels of communication are acceptable and likely beneficial.
Conversely, under our assumption, communication is required to be kept to a minimum, given the high cost associated with transferring large swaths of data across a network

# Potential Future Assumptions {#sec:potential}

Assumption: Arbitrary classes can be distributed.
Generalisation to arbitrary classes is an interesting pursuit, for the obvious increases in flexibility, as well as forcing clarity in the existing concepts of the system.
The user offering a class to the system to distribute would be required to define methods for splitting, combining, as well as some other functions to aid special cases such as indexing.
A marker of success would be the capacity to distribute matrices, with an extension to different types of matrices, such as sparse, diagonal, etc.
Already some generalisation between classes is necessary; vectors and data frames are broken into chunks for distribution using a `split` method in order to abstract over their differences in structure.
The proposed auxiliary functions are given in [@tbl:aux].

Function    Purpose
--------    -------
`measure`   A count of the number of elements within an object
`split`     A means of breaking an object into chunks
`combine`   A means of recombining the chunks locally
`reftype`   A means of determining the appropriate class of distributed object to serve as a reference to the distributed chunks
`sizes`     A count of the number of elements  within each distributed chunk

Table: Proposed auxiliary functions {#tbl:aux}

Assumption: Point-to-point communication is necessary.
Point-to-point communication, directly between nodes without master involvement is essential to the efficient movement of data between workers, but the implementation involves walking a tightrope of user-friendliness.
At face value, it is antithetical to the expectation that locations should remain unknown to the user.
This sees a fairly simple resolution in layering the platform, with explicit reference to locations existing only at the level of co-ordination and below; ideally lower.
See [@tbl:layers] for more detail on platform layering.
An ideal outcome of point-to-point communication is the implementation of a sorting algorithm, with a more pedestrian, but still useful outcome in direct alignment of objects on different nodes.


Layer 	        Definitive Examples
-----           -------------------
User 	        `table`, `dist.read.csv`, `dist.scan`, `Math` group (`+` etc.), `[<-`
Programming     `dist.do.call`
Co-ordination   `which.align`, `align`, `index`
Movement        `send`, `p2p`
Communication   RServe

Table: An outline of layers in the distributed architecture {#tbl:layers}
