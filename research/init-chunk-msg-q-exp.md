---
title: Initial Chunk Experimentation with a Message Queue Communication System
date: 2020-08-19
---

# Introduction

Given the simplicity and promise of flexibility as demonstrated in the documents [Inter-node Communication with Redis](inter-node-comm-w-redis.html) and [Message Queue Communications](message-queues-comms.html), further experimentation around the concept is undertaken and documented herein.
The experiments are built successively upon it's prior, with the aim of rapidly approximating a functioning prototype via experimentation.

# General Function on Single Chunk

While the RPC-based architecture as described in [Experiment: Eager Distributed Object](experiment-eager-dist-obj-pre.html) had significant limitations, a particularly powerful construct was the higher order function `distributed.do.call`{.R}, which took functions as arguments to be performed on the distributed chunks.

This construct is powerful in that it can serve as the basis for nearly every function on distributed chunks, and this section serves to document experiments relating to the creation of a general function that will perform a function at the node hosting a particular chunk.

## With Value Return {#sec:val-ret}

Regardless of performing the actual function, some means of returning the value of a function must be provided; this section focuses on getting a function to be performed on a server node, with the result send back to the client.
Listings of an implementation of these concepts are given by [@lst:vr-client; @lst:vr-server].

```{#lst:vr-client .R caption="Value return to request for client Node"}
#!/usr/bin/env R

library(rediscc)

RSC <- redis.connect(host="localhost", port=6379L)
SELF_ADDR <- list(host="localhost", port=12345L)
chunk <- structure("chunk1", class = "chunk")

main <- function() {
	doFunAt(fun=exp, chunk=chunk)
}

doFunAt <- function(fun, chunk, conn) {
	msg <- bquote(list(fun=.(fun),
			   chunk=.(chunk),
			   returnAddr=.(SELF_ADDR)))
	writeMsg(msg, chunk)
	cat("wrote message: ", format(msg), " to ", chunk, "\n")
	listenReply()
}

listenReply <- function() {
	replySock <- socketConnection(getHost(), getPort(), server=TRUE)
	response <- character(0)
	while (length(response) < 1) {
		response <- tryCatch(unserialize(replySock),
				     error = function(e) {
		cat("no reply, trying again in 1 sec\n")
		Sys.sleep(1); NULL})
	}
	cat("received response: ", format(response), "\n")
	close(replySock)
	response
}

getHost <- function() SELF_ADDR$host
getPort <- function() SELF_ADDR$port

writeMsg <- function(msg, to) {
	serializedMsg <- rawToChar(serialize(msg, NULL, T))
	redis.push(RSC, to, serializedMsg)
}

main()
```

```{#lst:vr-server .R caption="Value return to request for server Node"}
#!/usr/bin/env R

library(rediscc)

RSC <- redis.connect(host="localhost", port=6379L)
chunk1 <- seq(10)
QUEUE <- "chunk1"

main <- function() {
	while (TRUE) {
		msg <- readMessage(QUEUE)
		cat("read message:", format(msg), "\n")
		result <- doFun(msg)
		cat("result is: ", format(result), "\n")
		reply(result, getReturnAddr(msg))
	}
}

doFun <- function(msg) {
	fun <- getFun(msg); arg <- getArg(msg)
	do.call(fun, list(arg))
}

reply <- function(result, returnAddr) {
	replySock <- NULL
	while (is.null(replySock))
		replySock <- tryCatch(socketConnection(getHost(returnAddr),
						       getPort(returnAddr)),
			      error = function(e) {
				      cat("Failed to connect to return address",
					  ", trying again..\n")
				      NULL})
	cat("replying to request...\n")
	serialize(result, replySock)
	cat("replied\n")
	close(replySock)
}

getFun <- function(msg) msg$fun
getArg <- function(msg) get(msg$chunk)
getReturnAddr <- function(msg) msg$returnAddr
getHost <- function(addr) addr$host
getPort <- function(addr) addr$port

readMessage <- function(queues) {
	serializedMsg <- redis.pop(RSC, queues, timeout=Inf)
	unserialize(charToRaw(serializedMsg))
}

main()
```

To this end, the client node has a function defined as `doFunAt(fun, chunk)`{.R}, which takes in any function, and the ID of a chunk to perform the function on.
An implementation is given by [@lst:vr-client].
`doFunAt()`{.R} first composes a message to send to the chunk's queue, being a list consisting of the function, the chunk name, and a return address, which contains sufficient information for the node performing the operation on the chunk to send the results back to via socket connection.
The message is then serialised and pushed to the chunk's queue, and the requesting node sits listening on the socket that it has set up and advertised.

On the server node end, it sits waiting on it's preassigned queues, each of which correspond to a chunk that it holds.
Upon a message coming through, it runs a `doFun()` function on the message, which in turn runs the function on the chunk named in the message.
An implementation is given by [@lst:vr-server].
It then creates a socket connected to the clients location as advertised in the message, and sends the serialised results through.

A problem with this approach is the fickle aspect of creating and removing sockets for every request; beyond the probability of missed connections and high downtime due to client waiting on a response, R only has a very limited number of connections available to it, so it is impossible to scale beyond that limit.

## With Assignment

Assigning the results of distributed operation to a new chunk is a far more common operation in a distributed system in order to minimise data movement.
This will involve specifying additional directions as part of the request message, in order to specify that assignment, and not merely the operation, is desired.

It will be clear from the previous example that the problem of point-to-point data movement, somewhat solved via direct sockets in that previous example, is largely an implementation issue, and a problem entirely distinct to the remainder of the logic of the system.
From this experiment onwards, the mechanism of data movement is abstracted out, with the assumption that there will exist some additional tool that can serve as a sufficient backend for data movement.
In reality, until that tool is developed, data will be sent through redis; not a solution, but something that can be ignored without loss of generality.

The actual creation of a chunk ID in itself demands a system-wide unique identifier; this is a solved problem with a central message server, in redis providing an `INCR` operation, which can be used to generate a new chunk ID that is globally unique.

The name origination and option of blocking until a chunk is formed will dictate different algorithms in the creation of the distributed chunk object, as well as the structure of the distributed chunk object.
[@tbl:name-orig-block] shows potential forms these may take.
In addition, the "jobID" referred to in the table may take the concrete form of a simple key-value store, with the key being passed and monitored by the client node.

|                        | Client-Originated chunk ID                                                                                                                                              | Server-Originated chunk ID                                                                                                                                                                                                                                                                                                            |
|------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Blocking Algorithm     | client attains chunk ID, sends operation request withchunk ID to server, creating chunk reference concurrently, blocking until direct signal of completion from server. | client sends operation request with reference to some common information repository and the job ID to server. server attains chunk ID, performs operation, and sends chunk chunk ID to thejob ID at the common information repository, which client watches, releasing chunk object after attaining chunk ID from repository.         |
| Blocking Structure     | String name of chunk.                                                                                                                                                   | String name of chunk.                                                                                                                                                                                                                                                                                                                 |
| Non-Blocking Algorithm | client attains chunk ID, sends operation request withchunk ID to server, creating chunk reference concurrently. Nowaiting for server signal of completion.              | client sends operation request with reference to some common information repository and the job ID to server. server attains chunk ID, performs operation, and sends chunk ID to the job ID at common information repository. Before server completion, client releases chunk object, not waiting for reception of chunk information. |
| Non-Blocking Structure | String name of chunk                                                                                                                                                    | Initially, reference to common information repository. Mutable; can become string name of chunk upon accessing that information in the common information repository.                                                                                                                                                                 |

Table: Description of Algorithms and Data Structure of chunk reference object, by blocking status in creation, and origination of chunk ID. {#tbl:name-orig-block}

While it is clearly more straightforward for a client node to originate a chunk ID, with blocking, the opposite will possibly be the most flexible; server-originated chunk ID with no blocking.
This is because the very existence of a chunk is presupposed when a client node originates a chunk ID, while that may not be true in reality.
For instance, the result may be an unexpected `NULL`, zero-length vector, or even an error.
In addition, the server-originated chunk ID with no blocking has every feature common to that of a future, from the future package; it can be checked for completion, and accessed as a value, allowing for many asynchronous and parallel operations.

### Client-Originated Chunk ID

The logic of the client in assigning the result of a distributed operation on a chunk is largely encapsulated in a new function, `assignFunAt()`{.R}, as demonstrated in [@lst:ro-ass-client].
The function attains a chunk ID, generates a unique return address, sends a message to the operand chunk queue, and waits for a reply, before returning the id as a string belonging to the "chunk" class.
There is more information in the message relative the the function-only message of section [@sec:val-ret]; the chunk ID, request for acknowledgement of completion, return address, as well as an operation specifier to direct the intent of the message.

```{#lst:ro-ass-client .R caption="Demonstration of assignment in client Node, with client-Originated chunk name"}
#!/usr/bin/env R

library(rediscc)
library(uuid)

RSC <- redis.connect(host="localhost", port=6379L)
redis.rm(RSC, "chunkID")
chunk1 <- structure("chunk1", class = "chunk")
redis.rm(RSC, "chunk1")
redis.rm(RSC, as.character(1:10))

main <- function() {
	x = assignFunAt(fun=expm1, chunk=chunk1, wait=F)
	y = assignFunAt(fun=log1p, chunk=x, wait=T)
}

assignFunAt <- function(fun, chunk, wait=TRUE) {
	id <- getChunkID();
	returnAddr <- UUIDgenerate()
	sendMsg("ASSIGN", fun, chunk, returnAddr, id, ack = wait)
	if (wait) readReply(returnAddr)
	structure(id, class = "chunk")
}

doFunAt <- function(fun, chunk) {
	returnAddr <- UUIDgenerate()
	sendMsg("DOFUN", fun, chunk, returnAddr)
	readReply(returnAddr)
}

getChunkID <- function() as.character(redis.inc(RSC, "chunkID"))

readReply <- function(addr, clear=TRUE) {
	reply <- redis.pop(RSC, addr, timeout = Inf);
	if (clear) redis.rm(RSC, addr)
	unserialize(charToRaw(reply))
}

sendMsg <- function(op, fun, chunk, returnAddr, id=NULL, ack=NULL) {
	msg <- newMsg(op, fun, chunk, id, ack, returnAddr)
	writeMsg(msg, chunk)
}

newMsg <- function(op, fun, chunk, id, ack, returnAddr) {
	structure(list(op = op, fun = fun, chunk = chunk,
		       id = id, ack = ack, returnAddr = returnAddr),
		  class = "msg")
}

writeMsg <- function(msg, to) {
	serializedMsg <- rawToChar(serialize(msg, NULL, T))
	redis.push(RSC, to, serializedMsg)
}

format.chunk <- function(x, ...) {
	obj <- doFunAt(identity, x)
	format(obj)
}

main()
```

The server, as shown in [@lst:ro-ass-server], consists in a loop of reading the message and performing an operation dependent on the operation specifier of the message.
For an operation of `DOFUN`, all that is run is a `do.call()`{.R} on the function and chunk specified, with a message being returned to the client with the value of the `do.call()`{.R}.
An operation of `ASSIGN` runs the same as `DOFUN`, with the addition of assigning the value to the ID as passed in the message, adding the ID to the array of queues to monitor, and potentially sending acknowledgement back to the client node.

```{#lst:ro-ass-server .R caption="Demonstration of assignment in server Node, with client-Originated chunk name"}
#!/usr/bin/env R

library(rediscc)

RSC <- redis.connect(host="localhost", port=6379L)
chunk1 <- seq(10)
QUEUE <- "chunk1"

main <- function() {
	while (TRUE) {
		msg <- readMessage(QUEUE)
		cat("read message:", format(msg), "\n")
		switch(getOp(msg),
		       "ASSIGN" = {assignFun(getFun(msg), getChunk(msg),
					     getChunkID(msg))
				   if (getAck(msg))
				     writeMsg("Complete", getReturnAddr(msg))},
		       "DOFUN" = writeMsg(doFun(getFun(msg), getChunk(msg)),
					  getReturnAddr(msg)))
	}
}

assignFun <- function(fun, chunk, id) {
	val <- doFun(fun, chunk)
	assign(id, val, envir = .GlobalEnv)
	assign("QUEUE", c(QUEUE, id), envir = .GlobalEnv)
}

doFun <- function(fun, chunk) {
	do.call(fun, list(chunk))
}

getMsgField <- function(field) function(msg) msg[[field]]
getOp <- getMsgField("op"); getFun <- getMsgField("fun")
getChunk <- function(msg) get(getMsgField("chunk")(msg))
getChunkID <- getMsgField("id"); getAck <- getMsgField("ack")
getReturnAddr <- getMsgField("returnAddr")

readMessage <- function(queues) {
	serializedMsg <- redis.pop(RSC, queues, timeout=Inf)
	unserialize(charToRaw(serializedMsg))
}

writeMsg <- function(msg, to) {
	serializedMsg <- rawToChar(serialize(msg, NULL, T))
	redis.push(RSC, to, serializedMsg)
	cat("wrote message: ", format(msg),
	    " to queue belonging to chunk \"", to, "\"\n")
}

main()
```

### Server-Originated chunk ID

By this point the client ([@lst:wo-ass-client]) and server ([@lst:wo-ass-server]) come to increasingly resemble each other, and most of the functions are shared, as in listings [@lst:wo-ass-chunk; @lst:wo-ass-shared; @lst:wo-ass-messages].

The principal mechanism of action is best demonstrated via a logical time diagram, given by figure (missing), following a Lamport form of event ordering [@lamport1978ordering].
The first message, shown by the **a** arrow in the diagram, involves a client sending a message to a server regarding the request, including the job ID naming a queue in a shared information reference for the server to later place the chunk ID into.

Optionally, the client can immediately create a chunk object with no direct knowledge of the chunk ID, holding the job ID at the information reference instead, and the client continues whatever work it was doing.
Only when the chunk ID is required, the chunk object, triggers a blocking pop on it's associated information reference queue, which the server may at any point push the chunk ID to.
The chunk object then has the associate the ID associated with it, and the information reference queue can be deleted.

```{#lst:wo-ass-client .R caption="Demonstration of assignment in client Node, with server-Originated chunk name"}
#!/usr/bin/env R

source("shared.R")
source("messages.R")
source("chunk.R")

distInit()
rediscc::redis.rm(conn(), c("distChunk1", paste0("C", 1:10), paste0("J", 1:10),
		"JOB_ID", "CHUNK_ID"))
distChunk1 <- structure(new.env(), class = "distChunk")
chunkID(distChunk1) <- "distChunk1"

main <- function() {
	cat("Value of distChunk1:", format(distChunk1), "\n")
	x <- do.call.distChunk(what=expm1, chunkArg=distChunk1,
			       assign=T, wait=F)
	cat("Value of x:", format(x), "\n")
	y <- do.call.distChunk(log1p, x, assign=T, wait=T)
	cat("Value of y:", format(y), "\n")
}

main()
```

```{#lst:wo-ass-server .R caption="Demonstration of assignment in server Node, with server-Originated chunk name"}
#!/usr/bin/env R

source("shared.R")
source("messages.R")
source("chunk.R")

distInit()
distChunk1 <- seq(10)
QUEUE <- "distChunk1"

main <- function() {
	repeat {
		m <- read.queue(QUEUE)
		switch(op(m),
		       "ASSIGN" = {cID <- do.call.chunk(what=fun(m),
							chunkArg=chunk(m),
							distArgs=dist(m),
							staticArgs=static(m),
							assign=TRUE)
			           send(CHUNK_ID = cID, to = jobID(m))},
		       "DOFUN" = {v <- do.call.chunk(what=fun(m),
						     chunkArg=chunk(m),
						     distArgs=dist(m),
						     staticArgs=static(m),
						     assign=FALSE)
			          send(VAL = v, to = jobID(m))})
	}
}

do.call.chunk <- function(what, chunkArg, distArgs, staticArgs, assign=TRUE) {
	if (assign) {
		cID <- chunkID()
		v <- do.call(what, list(chunkArg))
		cat("Assigning value", format(v), "to identifier",
		    format(cID), "\n")
		assign(cID, v, envir = .GlobalEnv)
		assign("QUEUE", c(QUEUE, cID), envir = .GlobalEnv)
		return(cID)
	} else do.call(what, list(chunkArg))
}

main()
```

```{#lst:wo-ass-chunk .R caption="Chunk functions of client and server in server-Originated chunk names for assignment"}
# distChunk methods

jobID.distChunk <- function(x, ...) get("JOB_ID", x)

chunkID.distChunk <- function(x, ...) {
	if (! exists("CHUNK_ID", x)) {
		jID <- jobID(x)
		cat("chunkID not yet associated with distChunk; checking jobID",
		    jID, "\n")
		cID <- chunkID(read.queue(jID, clear=TRUE))
		cat("chunkID \"", format(cID), "\" found; associating...\n",
		    sep="")
		chunkID(x) <- cID
	}
	get("CHUNK_ID", x)
}

do.call.distChunk <- function(what, chunkArg, distArgs=NULL, staticArgs=NULL,
			      assign=TRUE, wait=FALSE) {
	jID <- jobID()
	cat("Requesting to perform function", format(what), "on chunk",
	    chunkID(chunkArg), "with",
	    if (assign) "assignment" else "no assignment", "\n")
	send(OP = if (assign) "ASSIGN" else "DOFUN", FUN = what,
	     CHUNK = chunkArg, DIST_ARGS = distArgs, STATIC_ARGS = staticArgs,
	     JOB_ID = jID, to = chunkID(chunkArg))

	dc <- if (assign) {
		if (!wait){
			cat("not waiting, using job ID", format(jID), "\n")
			distChunk(jID)
		} else {
			distChunk(chunkID(read.queue(jID, clear=TRUE)))
	} } else {
		val(read.queue(jID, clear=TRUE))
	}
	dc
}

format.distChunk <- function(x, ...) {
	c <- do.call.distChunk(identity, x, assign=FALSE)
	format(c)
}
```

```{#lst:wo-ass-shared .R caption="Shared functions of client and server in server-Originated chunk names for assignment"}
# Generics and setters

distChunk <- function(x, ...) {
	if (missing(x)) {
		dc <- new.env()
		class(dc) <- "distChunk"
		return(dc)
	}
	UseMethod("distChunk", x)
}

chunkID <- function(x, ...) {
	if (missing(x)) {
		cID <- paste0("C", rediscc::redis.inc(conn(), "CHUNK_ID"))
		class(cID) <- "chunkID"
		return(cID)
	}
	UseMethod("chunkID", x)
}

`chunkID<-` <- function(x, value) {
	assign("CHUNK_ID", value, x)
	x
}

jobID <- function(x, ...) {
	if (missing(x)) {
		jID <- paste0("J", rediscc::redis.inc(conn(), "JOB_ID"))
		class(jID) <- "jobID"
		return(jID)
	}
	UseMethod("jobID", x)
}

`jobID<-` <- function(x, value) {
	assign("JOB_ID", value, x)
	x
}

chunk <- function(x, ...) UseMethod("chunk", x)

dist <- function(x, ...) UseMethod("dist", x)

dist.default <- stats::dist

# jobID methods

distChunk.jobID <- function(x, ...) {
	dc <- distChunk()
	jobID(dc) <- x
	dc
}

# chunkID methods

distChunk.chunkID <- function(x, ...) {
	dc <- distChunk()
	chunkID(dc) <- x
	dc
}

# Initialisation

init <- local({
	rsc <- NULL

	distInit <- function(queueHost="localhost", queuePort=6379L, ...) {
		# Place for starting up worker nodes
		rsc <<- rediscc::redis.connect(queueHost, queuePort)
	}

	conn <- function() {
		if (is.null(rsc))
			stop("Redis connection not found. Use `distInit` to initialise.")
		rsc
	}
})

distInit <- get("distInit", environment(init))
conn <- get("conn", environment(init))
```

```{#lst:wo-ass-messages .R caption="Message functions of client and server in server-Originated chunk names for assignment"}
# messaging functions

msg <- function(...) {
	structure(list(...), class = "msg")
}

send <- function(..., to) {
	items <- list(...)
	m <- do.call(msg, items)
	write.msg(m, to)
}

write.msg <- function(m, to) {
	serializedMsg <- rawToChar(serialize(m, NULL, T))
	rediscc::redis.push(conn(), to, serializedMsg)
	cat("wrote message: ", format(m),
	    " to queue belonging to chunk \"", to, "\"\n", sep="")
}

read.queue <- function(queue, clear = FALSE) {
	cat("Awaiting message on queues: ", format(queue),  "\n", sep="")
	serializedMsg <- rediscc::redis.pop(conn(), queue, timeout=Inf)
	if (clear) rediscc::redis.rm(conn(), queue)
	m <- unserialize(charToRaw(serializedMsg))
	cat("Received message:", format(m), "\n")
	m
}

# message field accessors

msgField <- function(field) function(x, ...) x[[field]]
# Requesters
op <- msgField("OP"); fun <- msgField("FUN")
static <- msgField("STATIC_ARGS")
chunk.msg <- function(x, ...) get(chunkID(msgField("CHUNK")(x)))
jobID.msg <- msgField("JOB_ID"); dist.msg <- msgField("DIST_ARGS")
# Responders
val <- msgField("VAL"); chunkID.msg <- msgField("CHUNK_ID")
```
