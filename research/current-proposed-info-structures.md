---
title: Current and Proposed Information Structures
date: 2020-08-03
---

# Motivation

Central to the implementation of the definitive features of a distributed system are the forms of structuring the data inherent to it.
This is due to the fact that the primary constraint on such a system is the distribution of data, along with the essential consideration of message timing between nodes.
While the algorithms in this particular statistical system are equally necessary for functionality in the stated aim of modelling and manipulation of large data, they are completely dependent on the structure of the data such algorithms operate upon, hence the primality placed on the system's information structures.

# Overview

The first questions asked of a distributed system's information structures relate to it's topology and mechanism of message passing.
This particular system answers that necessarily through it's context and aims; that it is currently intended to exist as a largely transparent platform within R, which necessitates interactivity and other standard R development practices.
Thus, a centralised structure must be chosen for the system, with the node associated with the user's R session acting as the master.
This is the form of operation of other distributed packages currently existing in R, such as `sparklyr` and `SNOW` [@luraschi20; @tierney18].
This can be contrasted with a decentralised system as in `pbdR` and it's underlying `MPI` implementation [@pbdR2012], which requires R programs to be written in a manner agnostic to the nodes in which they are executed upon, resulting in the same program being distributed to all nodes in the system.
In this way, the program is not capable of being run interactively, something undesirable to the goals of our system.
The master will therefore always be local, all other nodes remote.

# Local

## Description of Current System

As it currently stands, the local information structures are entirely described by S3 classes, the instances of which act as references to the payload data being held remotely.
These classes are composed as environments, used for their mutable hash table properties, and contain three elements:

`locs`
: a list of `Rserve` connections through which the remote payload data resides in discrete chunks

`name`
: a UUID character scalar, which corresponds to the symbol which the chunks are assigned to in the remote environment

`size`
: an integer vector of the same length as `locs`, describing the size (as in `nrow` or `length`) of the chunk at each location

This is coupled with a garbage collection system consisting of a hook to the removal of the reference object through `reg.finalize`.
Upon triggering the hook, a directive is issued to all chunks in `locs` to remove `name`, thereby closing the loop between creation and deletion on local and remote nodes.

## Motivation for Current System

The system exists in it's current form primarily through motivations of simplicity; minimising complexity in the system until further additions are required.
By themselves, `loc` and `name` are sufficient for referencing any distributed chunks.
`size` is maintained for the regular need to know lengths of objects as part of many standard operations, thereby reducing the lookup cost by keeping the static information locally and directly attached to the reference.

The mechanism of garbage collection is likewise borne of simplicity and necessity; it requires the least possible steps, and without it, distributed chunks would accumulate remotely with no means of further access if their reference is removed, essentially forming a high-level memory leak.

## Insufficiency of Current Structures

In spite of, and indeed because of, the simple information structure of the local system, there remain aspects of the design that inhibit the development of important features, many of them essential.
In addition, clarification in system semantics has revealed a need for greater focus in areas presently under-served by the system.

A major feature lacking in this system is a global awareness of existing connections, which can be used in preference to creating new connections upon instantiation of a distributed object.
Take for example, the act of reading in successive distributed `csv`s into the system.
The first read takes in file location arguments, among others, then creates new connections, finally returning a reference.
The next read performs exactly the same actions, and so on.
This ignores the highly likely situation where files are situated in the same locations, and connections at those locations can be reused, thus potentially saving from the overhead of extraneous connections and unnecessary data movement of aligning objects with each other.

Another issue is the closing of connections; as it currently stands, there is no appropriate garbage collection for connections.

The single name for all chunks also cuts out any possibility of having multiple chunks belong to the same object referenced via a singular connection, thereby cutting out a potential mechanism for arbitrary indexing of objects.

## Proposal for New Structures {#sec:localproposal}

Significant enhancements to the system can be attained through additional structures addressing the present deficits.
Principally, the introduction of a central table of connections will serve as a single source of truth, avoiding issues of non-knowledge in creation, deletion, and usage of channels.
This would require a change in the structure of reference objects, and can consist in changing literal `RSclient` channel pointers to identifiers to be searched for in the central location table.
In this way it provides a solution in the manner of the fundamental theorem of software engineering:

> All problems in computer science can be solved by adding another level of indirection [@oram2007beautiful].

The table slots correspoinding to each identifier may also contain relevant information to the connection such as host name, rack, etc., in order to optimise data movement, as well as aid in the decision of whether or not to create new connections for newly read or instantiated objects.

Additional improvements, though unrelated, include changes to the reference classes to allow for globally unique names for each chunk, which will allow the same connection to house multiple chunks of a cohesive distributed object, thereby enabling arbitrary indexing operations.
With such changes in structure, garbage collection is able to be enhanced through centralising the objects of garbage collection within the central table of locations.

One potential algorithm for garbage collection could involve marking table elements with chunks to be removed, at their associated channel, as part of a reference garbage collection hook.
The marked objects can then be used as part of a directive for remote removal at the next convenience.
This can be combined with a reference counter of the number of extant objects at the referent environment of each channel; upon complete emptying of the environment, signified by a counter of zero, that channel itself may then be closed and removed.

## Relation to Existing Systems {#sec:localrel}

Most other distributed systems in R require manual specification of a cluster that then operates either in the background or as an object that must be retained and manipulated.
What is described here bears closer resemblance to a file system than any particular distributed R package, with particular relation to the `UNIX` file system [@ritchie1979evolution; @thompson1974unix].
In the `UNIX` file system, files contain no additional information beyond what is written to them by the user or file generation program.
Directories are also files and consist solely of a regular textual mapping from a file name to it's entry (*inode*) in a central system table (*ilist*).
The inode contains metadata associated with a file such as access times and permissions, as well as the physcical address of the file on disk.

To analogise, references in our system are equivalent to directories. They provide a mapping from connection names (files) to their entries (inodes) in a central table (ilist).
Furthermore, the table entry contains an `RSclient` pointer, analogous to a disk address, as well as metadata.
The form of the metadata differs due to separate priorities; a list of chunk names in the place of permission bits, etc.
In theory this also allows copies of references to behave as hard links, though this will introduce major issues involving synchronisation, and is therefore be avoided for now.
This form of garbage collection bears some resemblance to the file system garbage collection as well, in that inodes count the number of links to them, issuing a removal directive at zero links, though our system supplements this through collecting specific names of chunks for second degree removal.
In this manner, the "marking" via name collection is closer to the method of marked garbage collection, in conjunction with reference counting [@knuth1].

# Remote

## Description and Motivation for Current System

The remote end of the system is the simplest component of the entire setup. Currently, each remote R process is hosted through `RServe`, and accessed through `RSclient` on the local end.
The remote R process holds chunks of data in it's global environment, and performs whichever operations on that data as are directed to it from the master R session.
The data possesses no more structure than what was already in the chunk following reading, operation upon, or reception by the node.
This has again been due to reasons of simplicity, as no presuppositions of structure suggested themselves at the outset.

## Insufficiency of Current Structures

The system works very well for something general purpose.
However, it ignores much of the structure inherent in common primitive R objects such as vectors.
For example, to numerically index elements of a distributed vector, an indexing algorithm currently translates the index numbers into node-specific indices, and forwards those translated indices on as part of a call to the relevant nodes.
This sees issue when there are disparate elements at a particular node selected between the elements of other nodes, and the mechanism for numerical translation breaks down.

## Proposal for New Structures

A potential mechanism for improvement is to attach index attributes corresponding to the overall index to the chunks.
In combination with remotely-run routines, the local session simply needs to send out a request for particular indices to all of it's connections, and they can work out themselves which elements, if any, they correspond to, returning a vector of elements matched, for us in the creation of a new reference locally.

This would certainly solve the problem, however it may be redundant to simply allowing local index translation to account for multiple chunks at a single connection (as described in section [@sec:localproposal]).
It certainly uses significantly more messaging bandwidth, though by distributing processing of index translation across nodes, it may be faster in practice.
In addition, the additional structure forced on data chunks by attaching indices is somewhat contrary to the lack thereof in the analogous `UNIX` filesystem described in section [@sec:localrel].

# Further Research

Further work involves the actual implementation and assessment of the proposed information structures, as part of a general rewrite.
Additional research may also involve other garbage collection systems, with especial interest in file systems, such as those of the Inferno and Plan 9, distributed operating systems borrowing heavily from `UNIX` [@dorward1997inferno; @pike1995plan].
