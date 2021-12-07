---
title: A Disk.Frame Case Study
date: 2020-04-01
---

# Introduction {#sec:introduction}

The mechanism of disk.frame is introduced on it's homepage with the following explanation:

> {disk.frame} works by breaking large datasets into smaller
> individual chunks and storing the chunks in fst files inside a
> folder. Each chunk is a fst file containing a data.frame/data.table.
> One can construct the original large dataset by loading all the
> chunks into RAM and row-bind all the chunks into one large
> data.frame. Of course, in practice this isn’t always possible; hence
> why we store them as smaller individual chunks.
>
> 	{disk.frame} makes it easy to manipulate the underlying chunks by
> implementing dplyr functions/verbs and other convenient functions
> (e.g. the (`cmap(a.disk.frame, fn, lazy = F)`{.R} function which
> applies the function fn to each chunk of a.disk.frame in parallel).
> So that {disk.frame} can be manipulated in a similar fashion to
> in-memory data.frames.[@zj20:_larger_ram_disk_based_data]

It works through two main principles: chunking, and generic function implementation (alongside special functions).
Another component that isn't mentioned in the explanation, but is crucial to performance, is the parallelisation offered transparently by the package.

disk.frame is developed by Dai ZJ.

# Chunks and Chunking {#sec:chunking}

## Chunk Representation {#sec:chunk-representation}

disk.frames are actually references to numbered `fst`{.R} files in a folder, with each file serving as a chunk.
This is made use of through manipulation of each chunk separately, sparing RAM from dealing with a single monolithic file[@zj19:_inges_data].

Fst is a means of serialising dataframes, as an alternative to RDS files[@klik19].
It makes use of an extremely fast compression algorithm developed at facebook, with the R package enabling fst written on in [R Packages for Local Large-Scale Computing](survey-r-packages-for-local-large-scale-computing.html).

From inspection of the source code, data.table manipulations are enabled directly through transformations of each chunk to data.tables through the fst backend.

## Chunk Usage {#sec:making-chunks}

Chunks are created transparently by disk.frame; the user can theoretically remain ignorant of chunking.
In R, the disk.frame object serves as a reference to the chunk files.
Operations on disk.frame objects are by default lazy, waiting until the `collect()`{.R} command to perform the collected operations and pull the chunks into R as a single data.table.
As noted in [@zj19:_simpl_verbs_lazy_evaluat], this form of lazy evaluation is similar to the implementation of sparklyr.

Chunks are by default assigned rows through hashing the source rows, but can be composed of individual levels of some source column, which can provide an enormous efficiency boost for grouped operations, where the computation visits the data, rather than the other way around.

Chunks can be manipulated individually, having individual ID's, through `get_chunk()`{.R}, as well as added or removed from additional fst files directly, through `add_chunk()`{.R} and `remove_chunk()`{.R}, respectively.

In a computationally intensive procedure, the rows can be rearranged between chunks based on a particular column level as a hash, through functions such as `rechunk()`{.R}.

# Functions {#sec:functions}

The disk.frame object has standard procedures for construction and access. disk.frame can be constructed from data.frames and data.tables through `as.disk.frame()`{.R}, single or multiple csv files through `csv_to_disk.frame()`{.R}, as well as zip files holding csv files.
Time can be saved later on through the application of functions to the data during the conversion, as well as specifying what to chunk by, keeping like data together.
The process of breaking up data into chunks is referred to by disk.frame as "sharding", enabled for data.frames and data.tables through the `shard()`{.R} function.

After creating a disk.frame object, functions can be applied directly to all chunks invisibly through using the `cmap()`{.R} family of functions in a form similar to base R `*apply()`{.R}.

A highly publicised aspect of disk.frame is the functional cross-compatibility with dplyr verbs.
These operate on disk.frame objects lazily, and are applied through translation by disk.frame; they are just S3 methods defined for the disk.frame class.
They are fully functioning, with the exception of `group_by`{.R} (and it's data.table cognate, `[by=]`{.R}, considered in more detail in Section [@sec:spec-cons-group-by].

Beyond higher-order functions and dplyr or data.table analogues for data manipulation, the direct modelling function of `dfglm()`{.R} is implemented to allow for fitting glms to the data.
From inspection of the source code, the function is a utility wrapper for streaming disk.frame data by default into bigglm, a biglm derivative.

## Grouping {#sec:spec-cons-group-by}

For a select set of functions, disk.frame offers a transparent grouped `summarise()`{.R}.
These are mainly composed of simple statistics such as `mean()`{.R}, `min()`{.R}, etc.

For other grouped functions, there is more complexity involved, due to the chunked nature of disk.frame.
When functions are applied, they are by default applied to each chunk.
If groups don't correspond injectively to chunks, then the syntactic chunk-wise summaries and their derivatives may not correspond to the semantic group-wise summaries expected.
For example, summarising the median is performed by using a median-of-medians method; finding the overall median of all chunks' respective medians.
Therefore, computing grouped medians in disk.frame result in estimates only -- this is also true of other software, such as spark, as noted in [@zj19:_group_by].

Grouped functions are thereby divided into one-stage and two-stage; one-stage functions "just work" with the `group_by()`{.R} function, and two-stage functions requiring manual chunk aggregation (using `chunk_group_by`{.R} and `chunk_summarize`{.R}), followed by an overall collected aggregation (using regular `group_by()`{.R} and `summarise()`{.R}).
[@zj19:_group_by] points out that explicit two-stage approach is similar to a MapReduce operation.

Custom one-stage functions can be created, where user-defined chunk aggregation and collected aggregation functions are converted into one-stage functions by disk.frame[@zj19:_custom_one_stage_group_by_funct].
These take the forms `fn_df.chunk_agg.disk.frame()`{.R} and `fn_df.collected_agg.disk.frame()`{.R} respectively, where "`fn`{.R}" is used as the name of the function, and appended to the defined name by disk.frame, through meta-programming.

To de-complicate the situation, but add one-off computational overhead, chunks can be rearranged to correspond to groups, thereby allowing for one-stage summaries just through `chunk_summarize()`{.R}, and exact computations of group medians.

# Parallelism {#sec:parallelisation}

An essential component of disk.frame's speed is parallelisation; as chunks are conceptually separate entities, function application to each can take place with no side effects to other chunks, and can therefore be trivially parallelised.

For parallelisation, future is used as the backend package, with most function mappings on chunks making use of `future::future_lapply()`{.R} to have each chunk mapped with the intended function in parallel. Future is a package with complexities in it's own right; I have written more on future in the document, [A Detail of Future](review-future.html)

future is initialised with access to cores through the wrapper function, `setup_disk.frame()`{.R}[@zj19:_key].
This sets up the correct number of workers, with the minimum of workers and chunks being processed in parallel.

An important aspect to parallelisation through future is that, for purposes of cross-platform compatibility, new R processes are started for each worker[@zj19:_using].
Each process will possess it's own environment, and disk.frame makes use of future's detection capabilities to capture external variables referred to in calls, and send them to each worker.

# Relevance {#sec:relevance}

disk.frame serves as an example of a very well-received and used package for larger-than-RAM processing.
The major keys to it's success have been it's chart-topping performance, even in comparison with dask and Julia, and it's user-friendliness enabled through procedural transparency and well-articulated concepts.

disk.frame as a concept also lends itself well to extension:

The storage of chunks is currently file-based and managed by an operating system; if fault tolerance was desired, HDFS support for chunk storage would likely serve this purpose well.

Alternatively, OS-based file manipulation could be embraced in greater depth, focussing on interaction with faster external tools for file manipulation; this would lead to issues with portability, but with reasonable checks, could enable great speedups through making use of system utilities such as `sort`{.R} on UNIX-based systems.

The type of file may also be open to extension, with other file formats competing for high speeds and cross-language communication including [feather](https://github.com/esm/feather) developed by Wes McKinney and Hadley Wickham[@wes16].

In terms of finer-grained extension, more functionality for direct manipulation of individual chunks would potentially aid computation when performing iterative algorithms and others of greater complexity.
