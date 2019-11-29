
<!-- README.md is generated from README.Rmd. Please edit that file -->

# aPPR

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/aPPR)](https://CRAN.R-project.org/package=aPPR)
<!-- badges: end -->

`aPPR` helps you calculate approximate personalized pageranks from large
graphs, including those that can only be queried via an API. `aPPR`
additionally performs degree correction and regularization, allowing
users to recover blocks from stochastic blockmodels.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("RoheLab/aPPR")
```

## Find the personalized pagerank of a node in an `igraph` graph

This is a basic example which shows you how to solve a common problem:

``` r
library(aPPR)
library(igraph)

set.seed(27)

graph2 <- sample_pa(100)

appr(graph2, seeds = "5", verbose = TRUE)
#> # A tibble: 2 x 7
#>   name            r     p in_degree out_degree degree_adjusted regularized
#>   <chr>       <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#> 1 5     0.000000833 0.150         2          1          0.0750      0.0300
#> 2 4     0.000000537 0.127         4          1          0.0319      0.0182
```

## Why should I use aPPR?

  - curious about nodes important to the community around a particular
    user who you wouldn’t find without algorithmic help

  - 1 hop network is too small, 2-3 hop networks are too large (recall
    diameter of twitter graph is 3.7\!\!\!)

  - want to study a particular community but don’t know exactly which
    accounts to investigate, but you do have a good idea of one or two
    important accounts in that community

## `aPPR` calculates an *approximation*

comment on `p = 0` versus `p != 0`

## Find the personalized pagerank of a Twitter user using `rtweet`

``` r
appr_rtweet(graph, "fchen365", epsilon = 1e-4, verbose = TRUE)
```

## Advice on choosing `epsilon`

Number of unique visits as a function of `epsilon`, wait times, runtime
proportion to `1 / (alpha * epsilon)`, etc, etc

speaking strictly in terms of the `p != 0` nodes

1e-4 and 1e-5: finishes quickly, neighbors with high degree get visited
1e-6: visits most of 1-hop neighborhood. finishes in several hours for
accounts who follow thousands of people with \~10 tokens. 1e-7: visits
beyond the 1-hop neighbor by ???. takes a couple days to run with \~10
tokens. 1e-8: visits *a lot* beyond the 1-hop neighbor, presumably the
important people in the 2-hop neighbor, ???

the most disparate a users interests, and the less connected their
neighborhood, the longer it will take to run aPPR

## Limitations

  - Connected graph assumption, what results look like when we violate
    this assumption
  - Sampling is one node at a time

## Speed ideas

compute is not an issue relative to actually getting data

Compute time \~ access from Ram time \<\< access from disk time \<\<
access from network time.

Make requests to API in bulk, memoize everything, cache / write to disk
in a separate process?

General pattern: cache on disk, and also in RAM

## Working with `Tracker` objects

TODO

## Ethical considerations

people have a right to choose how public / visible / discoverable their
information is. if you come across interesting users who are not in the
public eye, do not elevate them into the public eye or increase
attention on their accounts without their permission.

# References

1.  Andersen, R., Chung, F. & Lang, K. *Local Graph Partitioning using
    PageRank Vectors*. 2006.
    [pdf](http://www.leonidzhukov.net/hse/2015/networks/papers/andersen06localgraph.pdf)

2.  Chen, F., Zhang, Y. & Rohe, K. *Targeted sampling from massive
    Blockmodel graphs with personalized PageRank*. 2019.
    [pdf](https://arxiv.org/abs/1910.12937)
