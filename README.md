
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

erdos_tracker
#> A Tracker R6 object with PPR table: 
#> 
#> # A tibble: 51 x 7
#>    name       r     p in_degree out_degree degree_adjusted regularized
#>    <chr>  <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 5     0.0205 0.147        50         50         0.00294     0.00147
#>  2 3     0.0167 0            51         51         0           0      
#>  3 6     0.0167 0            59         59         0           0      
#>  4 8     0.0167 0            41         41         0           0      
#>  5 15    0.0167 0            46         46         0           0      
#>  6 16    0.0167 0            52         52         0           0      
#>  7 17    0.0167 0            48         48         0           0      
#>  8 19    0.0167 0            54         54         0           0      
#>  9 20    0.0167 0            51         51         0           0      
#> 10 21    0.0167 0            55         55         0           0      
#> # ... with 41 more rows
```

## Sink nodes and unreachable nodes

``` r
citation_graph <- sample_pa(100)

citation_tracker <- appr(citation_graph, seeds = "5")
citation_tracker
#> A Tracker R6 object with PPR table: 
#> 
#> # A tibble: 1 x 7
#>   name            r     p in_degree out_degree degree_adjusted regularized
#>   <chr>       <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#> 1 5     0.000000833 0.150         0          1             Inf         Inf
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
appr(
  rtweet_graph(),
  "fchen365",
  epsilon = 1e-3,
  verbose = TRUE
)
#> A Tracker R6 object with PPR table: 
#> 
#> # A tibble: 40 x 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 77522577413145~ 0.0205 0.147        36         40         0.00408  0.00000132
#>  2 20855386        0.0208 0           700        744         0        0         
#>  3 14204987        0.0208 0          1955        919         0        0         
#>  4 3239447303      0.0208 0            71        125         0        0         
#>  5 24355706        0.0208 0          1220        901         0        0         
#>  6 2347049341      0.0208 0        904769        283         0        0         
#>  7 573817445       0.0208 0           784        262         0        0         
#>  8 82424157570642~ 0.0208 0          2654       1076         0        0         
#>  9 3729520335      0.0208 0          4762        211         0        0         
#> 10 567273827       0.0208 0         61988       1387         0        0         
#> # ... with 30 more rows
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

1.  Chen, F., Zhang, Y. & Rohe, K. *Targeted sampling from massive
    Blockmodel graphs with personalized PageRank*. 2019.
    [pdf](https://arxiv.org/abs/1910.12937)

2.  Andersen, R., Chung, F. & Lang, K. *Local Graph Partitioning using
    PageRank Vectors*. 2006.
    [pdf](http://www.leonidzhukov.net/hse/2015/networks/papers/andersen06localgraph.pdf)
