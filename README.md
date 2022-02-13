
<!-- README.md is generated from README.Rmd. Please edit that file -->

# aPPR

<!-- badges: start -->

[![R-CMD-check](https://github.com/RoheLab/aPPR/workflows/R-CMD-check/badge.svg)](https://github.com/RoheLab/aPPR/actions)
[![Codecov test
coverage](https://codecov.io/gh/RoheLab/aPPR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/RoheLab/aPPR?branch=main)
<!-- badges: end -->

`aPPR` helps you calculate approximate personalized pageranks from large
graphs, including those that can only be queried via an API. `aPPR`
additionally performs degree correction and regularization, allowing you
to recover blocks from stochastic blockmodels.

To learn more about `aPPR` you can:

1.  Glance through slides the
    [JSM2021](https://github.com/alexpghayes/JSM2021) talk
2.  Read the accompanying [paper](https://arxiv.org/abs/1910.12937)

### Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("RoheLab/aPPR")
```

### Find the personalized pagerank of a node in an `igraph` graph

``` r
library(aPPR)
library(igraph)

set.seed(27)

erdos_renyi_graph <- sample_gnp(n = 100, p = 0.5)

erdos_tracker <- appr(
  erdos_renyi_graph,   # the graph to work with
  seeds = "5",         # name of seed node (character)
  epsilon = 0.0005     # desired approximation quality (see ?appr)
)

erdos_tracker
#> Personalized PageRank Approximator
#> ----------------------------------
#> 
#>   - number of seeds: 1
#>   - visits so far: 5
#>   - unique nodes visited so far: 1 out of maximum of Inf
#>   - bad nodes so far: 0
#> 
#>   - teleportation constant (alpha): 0.15
#>   - desired approximation error (epsilon): 5e-04
#>   - achieved bound on approximation error: 0.000416297883029663
#>   - current length of to-visit list: 0
#> 
#> PPR table (see $stats field):
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

You can access the Personalized PageRanks themselves via the `stats`
field of `Tracker` objects.

``` r
erdos_tracker$stats
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

Sometimes you may wish to limit computation time by limiting the number
of nodes to visit, which you can do as follows:

``` r
limited_visits_tracker <- appr(
  erdos_renyi_graph,   
  seeds = "5",         
  epsilon = 1e-10,     
  max_visits = 20      # max unique nodes to visit during approximation
)
#> Warning: Maximum visits reached. Finishing aPPR calculation early.
limited_visits_tracker
#> Personalized PageRank Approximator
#> ----------------------------------
#> 
#>   - number of seeds: 1
#>   - visits so far: 22
#>   - unique nodes visited so far: 20 out of maximum of 20
#>   - bad nodes so far: 0
#> 
#>   - teleportation constant (alpha): 0.15
#>   - desired approximation error (epsilon): 1e-10
#>   - achieved bound on approximation error: 0.00423832387327568
#>   - current length of to-visit list: 100
#> 
#> PPR table (see $stats field):
#> # A tibble: 100 × 7
#>    name       r     p in_degree out_degree degree_adjusted regularized
#>    <chr>  <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 5     0.212  0.118        50         50         0.00237     0.00119
#>  2 3     0.0140 0            51         51         0           0      
#>  3 6     0.0140 0            59         59         0           0      
#>  4 8     0.0140 0            41         41         0           0      
#>  5 15    0.0136 0            46         46         0           0      
#>  6 16    0.0138 0            52         52         0           0      
#>  7 17    0.0138 0            48         48         0           0      
#>  8 19    0.0137 0            54         54         0           0      
#>  9 20    0.0135 0            51         51         0           0      
#> 10 21    0.0138 0            55         55         0           0      
#> # … with 90 more rows
```

### Find the personalized pagerank of a Twitter user using `rtweet`

``` r
ftrevorc_ppr <- appr(
  rtweet_graph(),
  "ftrevorc",
  epsilon = 1e-4,
  max_visits = 5
)
#> Warning: Maximum visits reached. Finishing aPPR calculation early.
ftrevorc_ppr
#> Personalized PageRank Approximator
#> ----------------------------------
#> 
#>   - number of seeds: 1
#>   - visits so far: 6
#>   - unique nodes visited so far: 5 out of maximum of 5
#>   - bad nodes so far: 10
#> 
#>   - teleportation constant (alpha): 0.15
#>   - desired approximation error (epsilon): 1e-04
#>   - achieved bound on approximation error: 0.00175980395529336
#>   - current length of to-visit list: 5
#> 
#> PPR table (see $stats field):
#> # A tibble: 210 × 7
#>    name                 r     p in_degree out_degree degree_adjusted regularized
#>    <chr>            <dbl> <dbl>     <dbl>      <dbl>           <dbl>       <dbl>
#>  1 7752257741314… 0.211   0.118        69        120         0.00172     5.50e-8
#>  2 17163639       0.00559 0         20033       1596         0           0      
#>  3 9381208958721… 0.00559 0           372        179         0           0      
#>  4 1359003756063… 0.00559 0           230        116         0           0      
#>  5 76228303       0.00559 0          7253       2274         0           0      
#>  6 1024298722828… 0.00559 0           382        829         0           0      
#>  7 1264590946144… 0.00559 0           116        189         0           0      
#>  8 1107711818997… 0.00559 0          3404        410         0           0      
#>  9 1217315090     0.00559 0         20660        402         0           0      
#> 10 1120701503763… 0.00559 0           354        243         0           0      
#> # … with 200 more rows
```

### Logging

`aPPR` uses [`logger`](https://daroczig.github.io/logger/) for
displaying information to the user. By default, `aPPR` is quite verbose.
You can control verbosity by loading `logger` and setting the logging
threshold.

``` r
library(logger)

# hide basically all messages (not recommended)
log_threshold(FATAL, namespace = "aPPR")

appr(
  erdos_renyi_graph,   # the graph to work with
  seeds = "5",         # name of seed node (character)
  epsilon = 0.0005     # desired approximation quality (see ?appr)
)
```

If you submit a bug report, please please please include a log file
using the TRACE threshold. You can set up this kind of detailed logging
via the following:

``` r
set.seed(528491)  # be sure to set seed for bug reports

log_appender(
  appender_file(
    "/path/to/logfile.log"  ## TODO: choose a path to log to
  ),
  namespace = "aPPR"
)

log_threshold(TRACE, namespace = "aPPR")

tracker <- appr(
  rtweet_graph(),
  seed = c("hadleywickham", "gvanrossum"),
  epsilon = 1e-6
)
```

### Ethical considerations

People have a right to choose how public and discoverable their
information is. `aPPR` will often lead you to accounts that interesting,
but also small and out of sight. Do not change the public profile or
attention towards these the people running these accounts, or any other
accounts, without their permission.

### References

1.  Chen, Fan, Yini Zhang, and Karl Rohe. “Targeted Sampling from
    Massive Block Model Graphs with Personalized PageRank.” Journal of
    the Royal Statistical Society: Series B (Statistical Methodology)
    82, no. 1 (February 2020): 99–126.
    <https://doi.org/10.1111/rssb.12349>.
    [arxiv](https://arxiv.org/abs/1910.12937)

2.  Andersen, Reid, Fan Chung, and Kevin Lang. “Local Graph Partitioning
    Using PageRank Vectors.” In 2006 47th Annual IEEE Symposium on
    Foundations of Computer Science (FOCS’06), 475–86. Berkeley, CA,
    USA: IEEE, 2006. <https://doi.org/10.1109/FOCS.2006.44>.
