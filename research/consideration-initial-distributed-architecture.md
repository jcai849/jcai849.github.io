---
title: Initial Considerations on a Distributed R Architecture
date: 2020-05-26
---

# General Thoughts

NOTE: Further work to still be done in correctly referencing attributes of the idealised system with respect to existing systems and concepts

The system takes the form out of highest concern for the minimisation of data movement.
A master-worker paradigm is favoured over SPMD, given that SPMD often ends up emulating master-slave anyway.
Operation on the data is among the larger concerns;
How are thes objects to be interacted with?
Do we implement transparent distributed objects, as alluded to in the idealised R session, as well as by pbdDMAT, or do we allow interaction only through an interface as in sparklyr via dplyr?
Furthermore, how are the operations to be carried out by the cluster, especially in a manner congenial to different backends?
Do we translate everything to a language capable of natively handling distributed objects, as sparklyr does in its `mutate()` to Spark SQL, do
we launch R sessions across the cluster, or do we define methods for a class
that talk directly to a cluster?
Do I look at a long list of standard generics in R and just set to work getting them to run on distributed objects?
Obvious risks include missing just one of them, as pbdDMAT does with `diag()<-` !
However, a very pleasant result is achieved when it does actually run transparently.
Most importantly, how is iteration to work?
Through special directives to whatever is handling the cluster operations?
Through synchronisation to a master loop?

My initial answers to these questions are illustrated to a degree in [@sec:idealised_r_session].

# Idealised R Session {#sec:idealised_r_session}

[@lst:ideal-r] gives an idealised R session running and testing a distributed R architecture, with favourable attributes taken from other distributed packages, as well as some new concepts introduced.

```{#lst:ideal-r .R caption="Idealised R session"}
> c <- makeCluster(hosts = paste0("host", 1:10, type = "SOCK")	<1>
> c

socket cluster with x nodes on host xx

> c$host1	<2>

R process on host host1

> ls(c$host1)	<3>

character(0)

> x <- 1:10
> x <- send(to = c$host1, obj = x)	<4>
> x

Distributed Integer
## Further details ...

> y <- cluster.read.csv(cluster = c,
			file = "hdfs://xxx.csv",
			partitionFUN = NULL)	<5>
> y

Distributed Data Frame
## Further details ...

> head(y)	<6>

	Sepal.Length	Sepal.Width	...
	1	5.1		3.5
	2	4.9		3.0
	3	4.7		3.2
	...

> y$Sepal.Length	<7>

Distributed Integer
## Further details ...

> z <- x + y$Sepal.Length	<8>
> z

Distributed Integer
## Further details ...

> send(from = c, to = "master", obj = z)	<9>
> z

[1]	6.1	6.9	7.7	...

> x + 1	<10>

Distributed Integer
## Further details ...

> a <- x + 1
> receive(a)
> a

[1]	2	3	4	6	...

> cont = TRUE
> while (cont) {
	x <- x + 1
	cont <- any(x < 70)	<11>
	receive(cont)
}
```

1.  Possible alternative: `makeYARNcluster()`. `makeCluster` can be made using RServe and RSclient. If using a YARN cluster, RServe may need to be embedded in Java - not sure
2.  The cluster takes a list structure, with each node holding a reference as a node object, as an element in the list
3.  Not accurate, but if `ls()` was generic, then the idea is that it would return the global environment of the node given as argument. Of course, a function with any other name can be created
4.  Blocks until sent, modifies environment of `host1`, based on the name of assignment locally. Communicates serial object.  Distributed object referenced locally. `c` acts as namenode or virtual memory, determining and retaining where the chunks are distributed among the nodes. `x` then only references it's location in `c`
5.  Distributed csv read by slave process on `c` directly, locally referenced by `y`, but environment again modified on all cluster nodes.
6.  Methods defined for standard generics. Can potentially be simplified through inheritence of a general distributed class
7.  Attributes (such as `names`) of distributed data frames and lists may be saved locally
8.  Again, transparent operation on distributed object, assignment is carried into the cluster as well
9.  maybe aliased to `receive()` or the like
10. Implicit coersion to distributed objects
11. Perhaps functions which always return scalars can be implicitly `receive()`'d.
