---
title: Self-healing Data in Largerscale
date: 2021-09-20
---

# Introduction

[This demonstration](https://github.com/jcai849/largerscale/blob/b3bd66fd42f2d4b984026c280298dc8e7c943492/demo/recover.Rmd) continues on from the previous [general](general.html)
demonstration. Here, self-healing of missing data is performed

## REMOTE MACHINE

From the previous demonstration, a remote dataframe was initially
generated. From this dataframe and a formula, a linear model was fit. A
summary was derived from the linear model, and from the summary,
coefficients were extracted. The variables made use of were `cdata`{.R},
`sdata`{.R}, `lmdata`{.R}, and `dfdata`{.R}. `cfdata`{.R} depended on `sdata`{.R}, which
depended on `lmdata`{.R}, depending on `dfdata`{.R} in turn. Let’s remove the
fixed value for `cdata`{.R}, which is equivalent to removing the machine
storing `cdata`{.R}.

```{.R}
    computationqueue()
```

```
    ## Queue: 0 Elements
```

```{.R}
    datapool()
```

```
    ## Pool: 16 Items
```

```{.R}
    unstore(cdata)
    datapool()
```

```
    ## Pool: 15 Items
```

## LOCAL MACHINE

Upon `cdata`{.R} being removed, an error is thrown if access is attempted,
and a recovery signal is sent.

```{.R}
    tryCatch(value(cdata), error=identity)
```

```
    ## <simpleError in value.data(cdata): Data lost. Recovering...>
```

## REMOTE MACHINE

A remote machine storing the computation resulting in `cdata`{.R} performs
the recovery.

```{.R}
    str(computationqueue())
```

```
    ## Queue: 1 Elements 
    ## [ Back to Front ]
    ##  $ :Computation:
    ## Identifier: Identifier:  139053  
    ## Input:   List of 1
    ##    $ :Computation:
    ##   Identifier: Identifier:  722666  
    ##   Input:   List of 1
    ##      $ :Data:
    ##     Identifier: Identifier:  876653  
    ##     Computation Identifier: Identifier:  365220  
    ##   Value: function (object, ...)   
    ##   Output: Identifier:  995977  
    ## Value: function (x, ...)   
    ## Output:  NULL
```

```{.R}
    do(receive())
```

```
    ##                  Estimate   Std. Error       t value     Pr(>|t|)
    ## (Intercept) -5.684342e-14 5.598352e-15 -1.015360e+01 5.618494e-17
    ## x            1.000000e+00 9.624477e-17  1.039018e+16 0.000000e+00
```

```{.R}
    computationqueue()
```

```
    ## Queue: 0 Elements
```

```{.R}
    datapool()
```

```
    ## Pool: 17 Items
```

## LOCAL MACHINE

And `cdata`{.R} is now accessible again.

```{.R}
    tryCatch(value(cdata), error=identity)

    ##                  Estimate   Std. Error       t value     Pr(>|t|)
    ## (Intercept) -5.684342e-14 5.598352e-15 -1.015360e+01 5.618494e-17
    ## x            1.000000e+00 9.624477e-17  1.039018e+16 0.000000e+00
```

## REMOTE MACHINE

If the entire chain of dependencies is deleted, recovery is still
possible, as long as there is some self-sufficient computation,
equivalent to checkpointing. Here, the initial computation leading to
`dfdata`{.R} has no dependencies, so it is able to regenerate `dfdata`{.R} as
well as the chain.

```{.R}
    unstore(cdata)
    unstore(sdata)
    unstore(lmdata)
    unstore(dfdata)
    datapool()
```

```
    ## Pool: 13 Items
```

## LOCAL MACHINE

An error occurs if trying to access the now-deleted data

```{.R}
    tryCatch(value(cdata), error=identity)
```

```
    ## <simpleError in value.data(cdata): Data lost. Recovering...>
```

## REMOTE MACHINE

And the regeneration process takes place, making use of continuations to
return control in the case of missing dependencies. Note that the choice
of queue as data structure is exceedingly inefficient; a stack will be
used in place next week, with only *O*(*n*) operations required for
recovery.

```{.R}
    while(!is.null(r <- receive())) {
                print(computationqueue())
            callCC(function(k) do(r, k))
    }
```

```
    ## Queue: 0 Elements 
    ## Queue: 1 Elements 
    ## Queue: 2 Elements 
    ## Queue: 3 Elements 
    ## Queue: 4 Elements 
    ## Queue: 5 Elements 
    ## Queue: 6 Elements 
    ## Queue: 7 Elements 
    ## Queue: 6 Elements 
    ## Queue: 5 Elements 
    ## Queue: 4 Elements 
    ## Queue: 3 Elements 
    ## Queue: 2 Elements 
    ## Queue: 1 Elements 
    ## Queue: 0 Elements
```

## LOCAL MACHINE

After recovery, the value is available again.

```{.R}
    tryCatch(value(cdata), error=identity)
```

```
    ##                  Estimate   Std. Error       t value     Pr(>|t|)
    ## (Intercept) -5.684342e-14 5.598352e-15 -1.015360e+01 5.618494e-17
    ## x            1.000000e+00 9.624477e-17  1.039018e+16 0.000000e+00
```
