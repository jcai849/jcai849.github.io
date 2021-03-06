---
title: Considerations on the Value of Point-to-Point Communication
date: 2020-05-22
---

# Introduction

Point-to-point communication refers to communication directly from on node to another.
It allows for fine-grained transfer of data and directives, potentially attaining high levels of efficiency in computations that stand to gain from such a form of communication.
In addition, point-to-point communication consumes significantly less bandwidth than that required for a complete broadcast among all nodes.

# Implementations

Point-to-point communication finds its most notable implementation in MPI, primarily through the use of `MPI_Send` and `MPI_Recv` functions.
I'm not sure yet about others - Hadoop, YARN, Spark??

# Applications

The capacity for point-to-point communication enables many applications;
[Wes Kendall](https://mpitutorial.com/tutorials/point-to-point-communication-application-random-walk) demonstrates random walks and parallel particle tracing as some applications that can take advantage of point-to-point communication [@kendall2014mpi].
A generalisation of such applications would be any where a large amount of static data exists in distributed memory, and nodes perform iterative computation on the main data in conjunction with small pieces of data that are then transferred and received based on the output of the computation.

Applications in the domain of statistical modelling (beyond a random walk) are unclear, but there are likely to be some in the domains of graphical models, Bayesian networks, undirected Markov blankets, Hidden Markov Models, potentially even neural networks wherein each node contains several consecutive layers that are a part of a larger network spanned by all of the nodes.

# Conclusion

Point-to-point communication adds huge performance capabilities to a distributed system.
This comes at the potential for deadlock, which must be carefully managed by both the implementation and the user.
A large-scale platform for statistical modelling in R will benefit from such a capability, but there will be at least the following difficulties:

- Determining an appropriate interface
- Avoiding the reinvention of the wheel
- Clean implementation avoiding excess communication
