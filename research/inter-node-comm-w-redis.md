---
title: Inter-node communication with Redis
date: 2020-08-07
---

# Introduction

For a cluster to effectively co-ordinate operations among nodes, a means of communication is essential.
To assess the capabilities of Redis for use in communication in R, the R interface package rediscc will be used to construct some simple communication programs, with the aim being to illustrate how an architecture making use of such packages could be structured, as well as which principal concepts arise as relevant[@yu02:_rmpi; @urbanek2020rediscc].

Redis is a data structure store, used extensively as a message broker, particularly for web services.
It has an R interface in the package rediscc, authored by Simon Urbanek.
Its principal data structure exposed by rediscc is Redis' linked list, with push and pop operations to treat it as a queue.

The following tests aim to demonstrate some standard communication operations.
The first test is a direct echo request, wherein a node "pings" a simple message to another node, attaining some response from the node in return.
A second test performs the "ping" routed through another node, as an indirect echo request.
The code for the tests is given by [@lst:redis-echo].

# Direct Echo Request

The direct echo request is a standard operation within a computer network[@rfc1122].
In this test, an initiator node will send a "ping" message to some node, whereupon reception of the message, the receptive node will message back acknowledgement to the initiator, such as "pong", following an IRC tradition[@rfc1459].

As a result of the simplicity of Redis, there is massive flexibility in the implementation of an echo request.
This test makes use of an initiator node acting as master, which starts the process and sends the character message "ping".
The response comes from a message detector node, which sends the message "pong" to the initiator node upon reception of any message.
Message passing between the nodes is implemented through Redis lists where each node monitors the list associated with the Redis key of the same name as their host name, and posts messages to the list associated with the key of their intended recipient.

The main function consists in instantiating an initiator node and a message detector node; directing a ping from the initiator node to the message detector node; then finalising the message detector node.
Instantiating the initiator requires connecting to the Redis server; setting the hostnames of the initiator node in the Redis table; then returning an initiator node object.
Instantiating the message detector is slightly more involved.
The actual referent node is spawned as a remote RServe instance, with a main routine injected into the RServe session through RSclient, where it is then run.
The main function of the message detector in turn consists of connecting to the Redis server; getting the hostname of the initiator node in order to phone home; entering a loop to perform a blocking pop of the Redis list under it's own hostname key; then pushing the predefined response upon reception of a message in the list belonging to the initiator node.

Pinging operates through pushing the "ping" message to the Redis list with the key named by the intended recipient (the message detector node).
A message is printed, then a blocking pop is entered into on the initiator node, to wait on it's own message list.
Upon reception of the message acknowledging the ping on the list, the initiator node prints out reception.

# Indirect Echo Request

An indirect echo request sends a message to acknowledge through other nodes which act to forward messages onwards.
It serves to test point-to-point communications independent of direct action by the master node.

The structure of the indirect echo request for Redis is largely the same as that for the direct request.
The primary difference is an altered main routine, further changes to the ping function, and an additional forwarder class.

The forwarder node is instantiated in a very similar manner to the message detector node, with the main difference being in the main routine.
In the main routine for the forwarder, it looks for mail on it's designated list with a blocking pop, then parses the mail into a message component and a next-host component.
It then pushes the message on the queue corresponding to the next host.
Ping also acts in a similar manner to the direct ping, except that it pushes a message to the forwarder queue, with the message containing fields specifying the next host as well as the content of the message.

```{#lst:redis-echo .R caption="Echo request with rediscc"}
library(RSclient)
library(rediscc)

REDIS_SERVER_HOST <- "hdp"
INITIATOR_HOST <- "hdp"
MSG_DETECTOR_HOST <- "hadoop1"
FORWARDER_HOST <- "hadoop2"

main.direct <- function() {
	initiatorNode <- newInitiatorNode()
	msgDetectorNode <- newMsgDetectorNode()
	ping(to=msgDetectorNode, from=initiatorNode)
	exit(msgDetectorNode)
}

main.indirect <- function() {
	initiatorNode <- newInitiatorNode()
	forwarderNode <- newForwarderNode()
	msgDetectorNode <- newMsgDetectorNode()
	ping(to=msgDetectorNode, from=initiatorNode, via=forwarderNode)
	exit(msgDetectorNode, forwarderNode)
}

newInitiatorNode <- function(initiatorHost=INITIATOR_HOST,
			 redisServerHost=REDIS_SERVER_HOST) {
	rc <- redis.connect(redisServerHost)
	redis.set(rc, "INITIATOR_HOST", initiatorHost)
	initiatorNode <- list(rc=rc, host=initiatorHost)
	class(initiatorNode) <- c("initiatorNode", "node")
	initiatorNode
}

newMsgDetectorNode <- function(msgDetectorHost=MSG_DETECTOR_HOST,
			   redisServerHost=REDIS_SERVER_HOST,
			   response="pong") {
	rsc <- RS.connect(msgDetectorHost)
	msgDetectorMain <- substitute({
		library(rediscc)
		rc <- redis.connect(redisServerHost)
		initiatorHost <- redis.get(rc, "INITIATOR_HOST")
		while (TRUE) {
			redis.pop(rc, msgDetectorHost, timeout=Inf)
			redis.push(rc, initiatorHost, response)
	}},
	list(redisServerHost=redisServerHost,
	     msgDetectorHost=msgDetectorHost,
	     response=response))
	eval(bquote(RS.eval(rsc, .(msgDetectorMain), wait = FALSE)))
	msgDetectorNode <- list(rsc=rsc, host=msgDetectorHost)
	class(msgDetectorNode) <- c("msgDetectorNode", "node")
	msgDetectorNode
}

newForwarderNode <- function(forwarderHost=FORWARDER_HOST,
			     redisServerHost=REDIS_SERVER_HOST) {
	rsc <- RS.connect(forwarderHost)
	forwarderMain <- substitute({
		library(rediscc)
		rc <- redis.connect(redisServerHost)
		while (TRUE) {
			mail <- redis.pop(rc, forwarderHost, timeout=Inf)
			m <- regmatches(mail,
					regexec("^SENDTO(.*?)MSG(.*)", mail))
			nextHost <- m[[1]][2]; msg <- m[[1]][3]
			redis.push(rc, nextHost, msg)
	}},
	list(redisServerHost=redisServerHost,
	     forwarderHost=forwarderHost))
	eval(bquote(RS.eval(rsc, .(forwarderMain), wait = FALSE)))
	forwarderNode <- list(rsc=rsc, host=forwarderHost)
	class(forwarderNode) <- c("forwarderNode", "node")
	forwarderNode
}

ping <- function(to, from, via, msg="ping") {
	msg <- as.character(msg)
	if (missing(via)) {
		redis.push(from$rc, to$host, msg)
		cat(sprintf("sending message \"%s\" to host \"%s\"...\n",
			    msg, to$host))
	} else {
		redis.push(from$rc, via$host, paste0("SENDTO",to$host,
						     "MSG", msg))
		cat(sprintf("sending message \"%s\" to host \"%s\" via host \"%s\"...\n",
		    msg, to$host, via$host))
	}
	response <- redis.pop(from$rc, from$host, timeout=Inf)
	cat(sprintf("received message \"%s\"...\n",
		    response))
}

exit <- function(...) lapply(list(...), function(node) RS.close(node$rsc))
```

