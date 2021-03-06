---
title: "Experiment: Distributed Decision Tree"
date: 2020-06-08
---

# Introduction and Motivation

The intention of this experiment is to train a decision tree on data physically distributed across separate nodes, with the result being capable of prediction.
This is motivated by the need for the demonstration of practical use of eager distributed objects, themselves detailed in the [Precursory](experiment-eager-dist-obj-pre.html) and [Supplementary](experiment-eager-dist-obj-supp.pdf) reports.

Ideally, the decision tree represents the hard part of ensemble methods such as random forest or adaboost, and such methods could form the basis of later experiments.

# Theory

The following brief description of decision trees follows [@breiman1993trees] very closely.
Decision trees operate on the principal of recursively splitting and subsetting initial explanatory data based on predicates operating on variables within the data, under some measure of goodness of each split; the resultant model corresponds to a tree, with predictions on new data performed through traversing based on the evaluation of the predicates within each node of the tree, and the terminal nodes corrresponding to some prediction.

The predicates with which to split the data are referred to as questions, and operate through determining whether particular variables hold specific values, or within some other relation to a particular splitting value, such as being less than some number for numeric data.
The tree is constructed through building the set of all possible questions, then running the data through the questions to generate the resulting splits.
These splits are then analysed under some measure of goodness of split, then subset by that particular predicate, and the process again applied to the resulting subsets.

The goodness of each split is drawn from the measure of lack of impurity within the parent and two descendant nodes.
Impurity itself is a measure of differentiation among the response variables corresponding to the subset explanatory variables; a perfectly pure dataset has a response variable of only one type of value, and a perfectly impure dataset has every value unique.
In this way, goodness of the split is equivalent to the minimisation of impurity:

$$
	\delta i (s, t) = i(t) - p_L i(t_L) - p_R i(t_R)
$$

Where $i$ is the measure of impurity on some node $t$ and the conditional proportions of the data split into the left and right nodes $t_L$, $t_R$) are given by $p_L$ and $p_R$ respectively.

The metric used in this case is the gini impurity measure, on the basis of ease of computation and little variance in impurity measures as described by Breiman.
Gini impurity is given as the probability of misclassification under arbitrary assignment for each possible class of response variable within the subset:

$$
	i(t) = \sum_{j \neq i} p(j \bar t) p(i \bar t)
$$

where the variables $i$ and $j$ stand for all possible classes belonging to
a response.
This is further simplified to:

$$
	i(t) = 1 - \sum_j p^2(j \bar t)
$$

# Implementation

# Outcome
