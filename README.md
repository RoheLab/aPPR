
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

## Find the personalized pagerank of a Twitter user using `rtweet`

``` r
fchen365_ppr <- appr(
  rtweet_graph(),
  "fchen365",
  epsilon = 1e-3,
  verbose = TRUE
)

fchen365_ppr$stats
#> # A tibble: 41 x 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 77522577413145~ 0.0205 0.147        38         41         0.00387  0.00000133
#>  2 13712792        0.0203 0         73006        143         0        0         
#>  3 20855386        0.0203 0           711        746         0        0         
#>  4 14204987        0.0203 0          1960        933         0        0         
#>  5 3239447303      0.0203 0            71        127         0        0         
#>  6 24355706        0.0203 0          1270        935         0        0         
#>  7 2347049341      0.0203 0        910840        282         0        0         
#>  8 573817445       0.0203 0           803        265         0        0         
#>  9 82424157570642~ 0.0203 0          2672       1086         0        0         
#> 10 3729520335      0.0203 0          4849        225         0        0         
#> # ... with 31 more rows
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
#> # A tibble: 1,150 x 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 7804292688660~ 9.70e-2 0.135      3205       1147       0.0000423 0.000000853
#>  2 1228948889694~ 6.69e-4 0            45        197       0         0          
#>  3 705281586      6.69e-4 0          3030       2052       0         0          
#>  4 358612981      6.69e-4 0         13312       1166       0         0          
#>  5 853839421      6.69e-4 0           247        386       0         0          
#>  6 1225800762447~ 6.69e-4 0          1256         43       0         0          
#>  7 1053314314155~ 6.69e-4 0            21         68       0         0          
#>  8 24340604       6.69e-4 0         73527        935       0         0          
#>  9 8882821340198~ 6.69e-4 0            71         46       0         0          
#> 10 547407850      6.69e-4 0          2222         42       0         0          
#> # ... with 1,140 more rows
```

**README beyond this point is really just scratch for myself**

## Sink nodes and unreachable nodes

``` r
citation_graph <- sample_pa(100)

citation_tracker <- appr(citation_graph, seeds = "5")
citation_tracker
#> A Tracker R6 object with PPR table: 
#> 
#> # A tibble: 2 x 7
#>   name            r     p in_degree out_degree degree_adjusted regularized
#>   <chr>       <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#> 1 5     0.000000833 0.150         1          1          0.150       0.0273
#> 2 2     0.000000837 0.127         8          1          0.0159      0.0102
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
