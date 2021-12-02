---
title: Considerations on Distributed Objects
date: 2020-06-08
---

# Introduction

Distributed objects are a means of access to objects on a distributed system.
They typically take the form of a reference (*stub*) that acts as a transparent handle to fragmented referents (*skeletons*) over a distributed system.
Details of their methods of interaction can vary enormously; distributed objects can exist anywhere on the spectrum of lazy/eager evaluation, for example.
Greater transparency in distributed objects is exemplified best in R with pbdDMAT, which provides distributed matrix objects, implementing nearly all standard Matrix methods on them.
pbdDMAT is discussed further in [Review of pbdR](review-pbdr.html).
The foundations of an implementation of distributed objects, focussing on vectors, can be found in [R/experiment-eager-dist-obj.R](github.com/jcai849/phd/R/experiment-eager-dist-obj.R).

# Benefits

The benefits of distributed objects grow commensurately with their degree of transparency.
At the closest state to ideal, a distributed object would be manipulated equivalently to its local equivalent.
More ...

# Contrary Recommendations
Experience has found the state of transparency to be impossible to achieve completely; ultimately, it is an abstraction, replete with the leaks inherent in such a physically-dependent abstraction.
This was noted with respect to pbdR in [Review of pbdR](review-pbdr.html).

Further initial research has revealed strong skepticism from some commentators [@waldo1996note; @rotem2006fallacies], with Martin Fowler declaring his First Law of Distributed Object Design;

> don't distribute your objects [@fowler2003patterns]

# Next Steps

Despite the criticism, it is a very strong idea, with plenty of examples of effective real world usage.
It would be worth going into more detail on distributed objects, their implementations in other languages (esp. CORBA), what prompted such skepticism, and whether it is justified.
