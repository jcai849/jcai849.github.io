---
title: Application Performance Management
date: 2021-02-19
---

# Introduction

Upon attaining a level of complexity greater than trivial, a performance management system becomes essential for understanding and aiding in the runtime control as well as development of the platform.
Most mainstream distributed computing systems come bundled with performance management utilities, and a case study of Hadoop and Spark is considered in section [@sec:hscs].
The performance management system required for largeScaleR must be largely monitoring-focussed, with a simple architecture capable of adapting to changes in the architecture of the main platform.
The user interface will necessarily differ in some respects and emphases from existing systems, in order to accomodate the unique architecture of largeScaleR, with considerations on the valid metrics, control, and access explored in [@sec:metr; @sec:conto; @sec:acces] respectively.

# Case Study: Hadoop & Spark {#sec:hscs}

Both Hadoop and Spark include extensive monitoring and control systems, centralised in a convenient user-friendly web interface [@spark2021monitoring].
The origin of their monitoring systems is through the various Hadoop daemons and Spark executors.
The Java Metrics framework is used by both for the generation of metrics, triggered by any event[@hadoop2021metrics; @dropwizard2021metrics].
The metrics are stored in event logs, which are then parsed and available for reporting.
The web interface is decoupled from the information necessary for reporting, and it is common practice to use alternative user interfaces such as Ganglia or DataDog[@massie2012monitoring; @datadog2021hdfs; @datadog2021spark].

The metrics generated are extensive, including hardware statuses, RPC contexts, JVM, memory usage, as well as job and task completion, among others.

# Metrics {#sec:metr}

The metrics necessary for collection in other platforms have a heavy gearing toward hardware monitoring, however the main use for users is in tracking progress of the application; this is something that can be focussed on in largeScaleR, at least initially.
The metrics that would be of most interest are task and data tracking.
For task metrics to be implemented, information around task events such as reception, progress, and completion, are necessary, as well as metadata such as dependencies.
Data tracking would follow a similar path, in recording data transfer and alignment events, as well as location.

# Control {#sec:conto}

A good monitoring system should be capable of controlling the platform - basic tasks may include initialisation, manual job/data removal, and cluster shutdown. These may be implemented client-side through language-agnostic signals, thereby enabling an arbitrary monitoring system to have control.

# Access: UI \& API {#sec:acces}

Spark includes a REST API for monitoring - the efficiency of such an approach is questionable in real-time monitoring, and the alternative of webSockets may be considered. However, if REST is acceptable, it may be easier to implement as an outward-facing interface of a headless finite-state machine capable of parsing event syslogs.
