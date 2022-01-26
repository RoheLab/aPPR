
<!-- README.md is generated from README.Rmd. Please edit that file -->

# aPPR

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/aPPR)](https://CRAN.R-project.org/package=aPPR)
[![Codecov test
coverage](https://codecov.io/gh/RoheLab/aPPR/branch/main/graph/badge.svg)](https://codecov.io/gh/RoheLab/aPPR?branch=main)
[![R build
status](https://github.com/RoheLab/aPPR/workflows/R-CMD-check/badge.svg)](https://github.com/RoheLab/aPPR/actions)
[![R-CMD-check](https://github.com/RoheLab/aPPR/workflows/R-CMD-check/badge.svg)](https://github.com/RoheLab/aPPR/actions)
<!-- badges: end -->

`aPPR` helps you calculate approximate personalized pageranks from large
graphs, including those that can only be queried via an API. `aPPR`
additionally performs degree correction and regularization, allowing you
to recover blocks from stochastic blockmodels.

To learn more about `aPPR` you can:

1.  Glance through slides the
    [JSM2021](https://github.com/alexpghayes/JSM2021) talk
2.  Read the accompanying [paper](https://arxiv.org/abs/1910.12937)

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
#> # A tibble: 51 × 7
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
#> # … with 41 more rows
```

## Find the personalized pagerank of a Twitter user using `rtweet`

``` r
ftrevorc_ppr <- appr(
  rtweet_graph(),
  "ftrevorc",
  epsilon = 1e-3,
  verbose = TRUE
)

ftrevorc_ppr$stats
#> # A tibble: 112 × 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 7752257741314… 0.0970  0.135        69        117         0.00196     7.67e-8
#>  2 76228303       0.00656 0          7263       2266         0           0      
#>  3 1024298722828… 0.00656 0           378        924         0           0      
#>  4 1264590946144… 0.00656 0           110        183         0           0      
#>  5 1107711818997… 0.00656 0          3234        395         0           0      
#>  6 1217315090     0.00656 0         20635        402         0           0      
#>  7 1120701503763… 0.00656 0           349        243         0           0      
#>  8 661613         0.00656 0         21236       4569         0           0      
#>  9 2492016278     0.00656 0          2604        430         0           0      
#> 10 237572207      0.00656 0           511        188         0           0      
#> # … with 102 more rows
```

## Find the personalized pagerank of a Twitter user and cache the following network in the process

**NOTE**: As of January 2022, the following does not work due to a
change in the `rtweet` dev version that we have not yet updated
`neocache` to accommodate.

``` r
alexpghayes_ppr <- appr(
  neocache_graph(),
  "alexpghayes",
  epsilon = 1e-4,
  verbose = TRUE
)

alexpghayes_ppr$stats
```

## Ethical considerations

People have a right to choose how public and discoverable their
information is. `aPPR` will often lead you to accounts that interesting,
but also small and out of sights. Do not change the public profile or
attention towards these the people running these accounts, or any other
accounts, without their permission.

# References

1.  Chen, F., Zhang, Y. & Rohe, K. *Targeted sampling from massive
    Blockmodel graphs with personalized PageRank*. 2019.
    [pdf](https://arxiv.org/abs/1910.12937)

2.  Andersen, R., Chung, F. & Lang, K. *Local Graph Partitioning using
    PageRank Vectors*. 2006.
    [pdf](http://www.leonidzhukov.net/hse/2015/networks/papers/andersen06localgraph.pdf)
