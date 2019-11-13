
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

appr(graph2, seeds = "5")
#> # A tibble: 3 x 7
#>   name            r     p in_degree out_degree degree_adjusted regularized
#>   <chr>       <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#> 1 5     0.000000833 0.150         2          1         0.0750      0.0105 
#> 2 4     0.000000579 0.127         4          1         0.0319      0.00781
#> 3 1     0           0.108        31          0         0.00350     0.00250
```

## Find the personalized pagerank of a Twitter user using `rtweet`

``` r
graph <- rtweet_graph()

appr(graph, "alexpghayes")
```

# References

1.  Targeted sampling from massive Blockmodel graphs with personalized
    PageRank

2.  [Local Graph Partitioning using PageRank
    Vectors](http://www.leonidzhukov.net/hse/2015/networks/papers/andersen06localgraph.pdf)
