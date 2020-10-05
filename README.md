
<!-- README.md is generated from README.Rmd. Please edit that file -->

# aPPR

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/aPPR)](https://CRAN.R-project.org/package=aPPR)
[![Codecov test
coverage](https://codecov.io/gh/RoheLab/aPPR/branch/master/graph/badge.svg)](https://codecov.io/gh/RoheLab/aPPR?branch=master)
[![R build
status](https://github.com/RoheLab/aPPR/workflows/R-CMD-check/badge.svg)](https://github.com/RoheLab/aPPR/actions)
<!-- badges: end -->

`aPPR` helps you calculate approximate personalized pageranks from large
graphs, including those that can only be queried via an API. `aPPR`
additionally performs degree correction and regularization, allowing you
to recover blocks from stochastic blockmodels.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("RoheLab/aPPR")
```

## Find the personalized pagerank of a node in an `igraph` graph

``` r
library(aPPR)
library(igraph)

set.seed(27)

erdos_renyi_graph <- sample_gnp(n = 100, p = 0.5)

erdos_tracker <- appr(
  erdos_renyi_graph,   # the graph to work with
  seeds = "5",         # name of seed node (character)
  epsilon = 0.0005,    # convergence criterion (see below)
  verbose = FALSE
)
#> Error in igraph::`V<-`(`*tmp*`, value = `*vtmp*`): invalid indexing

erdos_tracker
#> Error in eval(expr, envir, enclos): object 'erdos_tracker' not found
```

## Find the personalized pagerank of a Twitter user using `rtweet`

``` r
fchen365_ppr <- appr(
  rtweet_graph(),
  "fchen365",
  epsilon = 1e-3,
  verbose = TRUE
)

fchen365_ppr$stats
#> # A tibble: 94 x 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 7752257741314~ 0.0970  0.135        47         97         0.00288 0.000000116
#>  2 759249         0.00791 0         13313       1359         0       0          
#>  3 97505313       0.00791 0          1280       2551         0       0          
#>  4 35109534       0.00791 0          1743        345         0       0          
#>  5 1225146797049~ 0.00791 0             6         11         0       0          
#>  6 7804292688660~ 0.00791 0          4159       1244         0       0          
#>  7 14897792       0.00791 0         17836       5542         0       0          
#>  8 165678616      0.00791 0         58259       1206         0       0          
#>  9 9095302874905~ 0.00791 0           191        637         0       0          
#> 10 16549997       0.00791 0         72320       1540         0       0          
#> # ... with 84 more rows
```

## Find the personalized pagerank of a Twitter user and cache the following network in the process

``` r
alexpghayes_ppr <- appr(
  twittercache_graph(),
  "alexpghayes",
  epsilon = 1e-4,
  verbose = TRUE
)

alexpghayes_ppr$stats
#> # A tibble: 1,243 x 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 7804292688660~ 9.71e-2 0.135      4069       1241       0.0000333 0.000000909
#>  2 628745609      6.19e-4 0           129        216       0         0          
#>  3 780934633      6.19e-4 0         19471       2878       0         0          
#>  4 20406724       6.19e-4 0         33816       8344       0         0          
#>  5 1152655010871~ 6.19e-4 0           552       1150       0         0          
#>  6 302667955      6.19e-4 0          3917       1724       0         0          
#>  7 2768346873     6.19e-4 0          6304       1376       0         0          
#>  8 3147524537     6.19e-4 0          1353        712       0         0          
#>  9 43261106       6.19e-4 0          1317        723       0         0          
#> 10 31241437       6.19e-4 0       4492431        215       0         0          
#> # ... with 1,233 more rows
```

**README beyond this point is really just scratch for myself**

## Sink nodes and unreachable nodes

``` r
citation_graph <- sample_pa(100)

citation_tracker <- appr(citation_graph, seeds = "5")
#> Error in igraph::`V<-`(`*tmp*`, value = `*vtmp*`): invalid indexing
citation_tracker
#> Error in eval(expr, envir, enclos): object 'citation_tracker' not found
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

See `?Tracker` for details.

## Ethical considerations

people have a right to choose how public / visible / discoverable their
information is. if you come across interesting users who are not in the
public eye, do not elevate them into the public eye or increase
attention on their accounts without their permission.

# References

1.  Chen, F., Zhang, Y. & Rohe, K. *Targeted sampling from massive
    Blockmodel graphs with personalized PageRank*. 2019.
    [pdf](https://arxiv.org/abs/1910.12937)

2.  Andersen, R., Chung, F. & Lang, K. *Local Graph Partitioning using
    PageRank Vectors*. 2006.
    [pdf](http://www.leonidzhukov.net/hse/2015/networks/papers/andersen06localgraph.pdf)
