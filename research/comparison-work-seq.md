---
title: A Comparison of Work Sequences
date: 2022-03-17
---

# Introduction

This is an expansion of the previous report demonstrating a standard sequence of work that may take place in the system.
The sequence is compared with it's equivalents in a single session in serial, as well as the previous version of largescaler, and SNOW.
The work sequence consists of three calls and an examination.

A topologically sorted graph of arguments for the calls is given in [@fig:workseq].

![Graph of call dependencies. `d0` and `d1` are given, and `d4` has no prerequisites, but will be executed after calling `d3` in these examples](workseq.svg){#fig:workseq}

# Single, serial R session

![Sequence diagram of example session in serial R](rsesswork.svg){#fig:rsesswork}

# SNOW

![Sequence diagram of example session in SNOW](snowseq.svg){#fig:snowseq}

# Previous largescaler

# New largescaler

![Sequence diagram of example interaction between client, workers, a nd locator](sysinteract.svg){#fig:sysinteract}
