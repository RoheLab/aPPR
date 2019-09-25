
<!-- README.md is generated from README.Rmd. Please edit that file -->

# aPPR

<!-- badges: start -->

<!-- badges: end -->

The goal of aPPR is to …

## Installation

You can install the released version of aPPR from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("aPPR")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("RoheLab/aPPR")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(aPPR)
#> Loading required package: R6

graph <- twittercache_graph()

# seed <- rtweet::lookup_users("alexpghayes")$user_id

seed <- "780429268866052096"  # @alexpghayes

p <- appr(graph, seed)
#> Error in tracker$update_r_neighbor(graph, u, v): object 'alpha_prime' not found
```

``` r
alpha = 0.15
epsilon = 1e-6
adjust = TRUE
tau = 0

alpha_prime <- alpha / (2 - alpha)

tracker <- Tracker$new()
#> Error in eval(expr, envir, enclos): object 'Tracker' not found

for (seed in seeds) {
  tracker$add_node(graph, seed, preference = 1 / length(seeds))
}
#> Error in eval(expr, envir, enclos): object 'seeds' not found

remaining <- tracker$remaining(epsilon)
#> Error in eval(expr, envir, enclos): object 'tracker' not found

while (length(remaining) > 0) {
  
  # TODO: test edge case when remaining is a single integer node
  # TODO: second issue: returning a tibble, not a character vector
  u <- if (length(remaining) == 1) u else sample(remaining, size = 1)
  
  tracker$update_p(u, alpha_prime)  # u is a node name
  
  for (v in neighborhood(graph, u)) {
    tracker$update_r_neighbor(graph, u, v)
  }
  
  tracker$update_r_self(u, alpha_prime)
  
  remaining <- tracker$remaining(epsilon)
}
#> Error in eval(expr, envir, enclos): object 'remaining' not found

if (!adjust)
  return(tracker$stats$p)

# TODO: maybe there is a smarter way to guestimate tau
# based on the observed nodes

tracker$stats$p / (tracker$stats$in_degree + tau)
#> Error in eval(expr, envir, enclos): object 'tracker' not found
```
