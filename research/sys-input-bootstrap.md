---
title: distObj System Initialisation and Input
date: 2020-10-07
---

# Introduction

The problem of initialising the system and populating it with data has been largely abstracted over thus far, with all development and experimentation making use of a manually specified running system.
Naturally, it is an essential aspect of the system, and worth turning our attention to, now that object movement and distributed evaluations are at a sufficient level of functionality.
This document first considers how similar systems handle their input and startup along with an evaluation, before turning to a description of requirements for the distObj interface, followed by a suggestion for implementation and an evaluation thereof.
A particular focus is given on interface, due to the massive difference in algorithms that is to be expected with the systems being entirely different.

# Other Systems

SNOW is a related system that enables distributed operations in parallel,
though differs in not maintaining distributed objects as in our system, though does allow for cluster-wide global variables with `clusterExport()`{.R}[@tierney18].
A cluster must be initialised, using a `makeCluster()`{.R} function, which takes as minimum arguments some cluster specification, and the type of cluster.
Further options allow shoosing ports, timeout, and other additional options.
Data is always originated from the master node, and so is not pulled into the system in any distributed manner, rather using existing objects imported in a standard single-node manner, and exported as arguments to the various operative functions provided by SNOW.

Foreach is another package that is commonly used for high(er)-performance work in R, which possesses a different means of initialisation when using parallel backends; foreach has a variety of `register()`{.R} functions which are intended for the end user to specify the desired parallel backend, and all subsequent `foreach()`{.R} functions then make use of that backend[@microsoft20; @corporation19].
In this way, initialisation takes place once, with no additional objects required to be kept in userspace.

Sparklyr provides a means of connecting to Spark from R[@luraschi20].
While a means of connecting to external distributed file and data systems is highly desirable, given that the focus is on very large data, and that data typically resides in such systems, Spark's RDDs and DataFrames are lower priority targets than the more general HDFS, due to HDFS being more ubiquitous and flexible.
Sparklyr follows a similar setup procedure to SNOW, with `spark_connect()`{.R} returning a connection object with which to use in subsequent operations.
One difference is that sparklyr requires a running spark instance, whereas SNOW will create new R sessions as needed.
Data is input through several different methods; it can be created locally and fed to the spark cluster, using the `copy_to()`{.R} function.
Alternatively, external tabular data can be read into spark through `spark_read_csv()`{.R} (or `json()`{.R}, or `parquet()`{.R}), which takes as primary arguments the spark connection, a name, and a path to a particular file which can be local, HDFS, or Amazon S3-based, depending on the scheme indicated in the URI.
There is also the option to take a pre-existing Spark table into memory through the `tbl_cache()`{.R} function.

DSL: Distributed Storage and List, provides the capacity to store serialised R objects in distributed storage, as well as a means of operation on such objects[@theussl2020dsl].
The distObj project differs from DSL in locating the distributed objects in memory, with storage primarily serving for initial input or final output.
DSL has the capacity to interface with HDFS as well as a standard local file systems.
A distributed storage object is instantiated with details on the storage system, such as the type, directory, and chunk size, with the `DStorage()`{.R} constructor function.
This is then used as an argument to the `DList()`{.R} function, which behaves much like a standard list, including the associated behaviour with key-value pairs to the dots argument.
There exists no single function for reading in external data, though an example is given in the vignette of a construct using DSL to perform such an action.

iotools is a package providing high-performance I/O tools, serving particularly to allow for streaming data[@urbanek20].
It provides functions such as the `read.csv()`{.R} replacement, `read.csv.raw()`{.R}, as well as chunk processing from binary connections, using the `read.chunk()`{.R} function.
The `read.chunk()`{.R} function is paired with a `chunk.reader()`{.R} function, which creates a reader that reads from a binary connection, and is passed as an argument to `read.chunk()`{.R}.
iotools is closely related to another package, hmr[@urbanek20b].
hmr has hadoop as it's specific target for computation, allowing easy access to hadoop map-reduce jobs through R.
It provides the `hmr()`{.R} function, which takes as arguments, `input()`{.R}, `output()`{.R}, `map()`{.R}, and `reduce()`{.R}.
Most relevant to this discussion is the `input()`{.R} argument, which take the form of hadoop filepaths, as constructed using the `hpath()`{.R} or `hinput()`{.R} functions.
It is hinted by error messages that future versions may allow for local input.

# Evaluation of Other Systems

While the descriptions of the input and startup of other systems focussed largely on interface, greater aspects of the packages can be drawn out.

The central provision within R of most of these systems is data movement; SNOW, foreach, and DSL all enable ways of dispersing data such that memory is not saturated.
The complement to this is having computation as a central provision, as in sparklyr and hmr, where the data is stored externally, and functions as described in R are used to operate on the data.
Of the two, it is good to offer both, as most of these do in varying measures, but an ideal system would allow interfacing with data in distributed storage, combined with movement of that data into memory for direct manipulation with R.

The level of explicitness in setup varies significantly among these packages as well.
Some, as in SNOW, sparklyr, and DSL, require "system objects", where a reference to the system and its configuration must be kept and passed as an argument to all system-specific functions.
iotools \& hmr require no setup beyond the external hadoop process, working without any need for initialisation.
foreach sits somewhere in between, where it runs with no explicit initialisation calls, but different backends can be "registered" with a single function that is used only for its side effect, and doesn't produce a system object as in many of the other packages.
Naturally, the less setup that is required the better, but sometimes the system absolutely requires configuration, such as lists of hosts to be included; in this case, producing and maintaining a system object entails more effort and overhead than using an initialisation function once for it's side effects; an analogy may be made between by comparison of using the double colon for access to R objects in a namespace, or the `library()`{.R} function to attach an add-on package.

# Interface

Based on the analysis of other systems, an attempt can be made at describing a reasonable initialisation and input system for distObj.

In this system, initialisation is implicit in the input, so can be coupled together at a high level for ease of use.
This renders a system object as unnecessary. Updates, including elastic, can be run through a side-effect producing function.

With the large size of data targeted by the system, the data source has a higher probability of coming from HDFS, and this must be accommodated for.
Nodes already serving as nodes for HDFS can therefore be put to use as distObj nodes, due to their proximity to the data

# Implementation

# Evaluation
