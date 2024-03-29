#' Approximate personalized pageranks
#'
#' Computes the personalized pagerank for specified seeds using the
#' `ApproximatePageRank` algorithm of Andersen et al. (2006). Computes
#' degree-adjustments and degree-regularization of personalized
#' pagerank vectors as described in Algorithms 3 and 4 of Chen et al. (2019).
#' These algorithms are randomized; if results are unstable across
#' multiple runs, decrease `epsilon`.
#'
#' @param graph An [abstract_graph()] object, such as that created by
#'   [rtweet_graph()]. This argument is required.
#'
#' @param seeds A character vector of seeds for the personalized pagerank.
#'   The personalized pagerank will return to each of these seeds with
#'   probability `alpha` at each node transition. At the moment,
#'   all seeds are given equal weighting. This argument is required.
#'
#' @param alpha Teleportation constant. The teleportation constant is the
#'   probability of returning to a seed node at each node transition.
#'   `alpha` must be a valid probabilty; that is, between zero and one.
#'   Defaults to `0.15`. This is the inverse of the "dampening factor"
#'   in the original PageRank paper, so `alpha = 0.15` corresponds
#'   to a dampening factor of `0.85`. Runtime is proportional to
#'   `1 / (epsilon * alpha)`, so small `alpha` can result in long
#'   runtimes.
#'
#' @param epsilon Desired accuracy of approximation. `epsilon` must be
#'   a small positive number. Defaults to `1e-6`. `aPPR` guarantees that
#'   approximated personalized pageranks are uniformly within `epsilon` of
#'   their true value. That is, the approximation is guaranteed to be good
#'   in an L-infinity sense. This does not guarantee, however, that
#'   a ranking of nodes by aPPR is close to a ranking of nodes by PPR.
#'
#'   For Twitter graphs, we recommend testing your code with `1e-4` or `1e-5`,
#'   using `1e-6` for exploration, and `1e-7` to `1e-8` for final results,
#'   although these numbers are very rough. It also perfectly reasonable
#'   to run `aPPR` for a given number of steps (set via `max_visits`),
#'   and then note the approximation accuracy of your results. Internally,
#'   `aPPR` keeps a running estimate of achieved accuracy that is always valid.
#'
#'   Anytime you would like to explore more of the graph, you can simply
#'   decrease `epsilon`. So you can start with `epsilon = 1e-5` and then
#'   gradually decrease `epsilon` until you have a sample of the graph
#'   that you are happy with.
#'
#'   Also note that runtime is proportional to `1 / (epsilon * alpha)`,
#'   so small `epsilon` can result in long runtimes.
#'
#' @param tau Regularization term. Additionally inflates the in-degree
#'   of each observation by this term by performing the degree
#'   adjustment described in Algorithm 3 and Algorithm 4, which
#'   are described in `vignette("Mathematical details")`. Defaults to
#'   `NULL`, in which case `tau` is set to the average in-degree of
#'   the observed nodes. In general, setting it's reasonable to
#'   set `tau` to the average in-degree of the graph.
#'
#' @param max_visits Maximum number of unique nodes to visit. Should be a
#'   positive integer. Defaults to `Inf`, such that there is no upper bound
#'   on the number of unique nodes to visit. Useful when you want to specify a
#'   fixed amount of computation (or API calls) to use rather than an
#'   error tolerance. We recommend debugging with `max_visits ~ 20`,
#'   exploration with `max_visits` in the hundreds, and `max_visits` in the
#'   thousands to ten of thousands for precise results, although this is a
#'   very rough heuristic.
#'
#' @param ... Ignored. Passing arguments to `...` results in a warning.
#'
#'
#' @return A [Tracker()] object. Most relevant is the `stats` field,
#'    a [tibble::tibble()] with the following columns:
#'
#'   - `name`: Name of a node (character).
#'   - `p`: Current estimate of residual per out-degree for a node.
#'   - `r`: Estimated error of pagerank estimate for a node.
#'   - `in_degree`: Number of incoming edges to a node.
#'   - `out_degree`: Number of outcoming edges from a node.
#'   - `degree_adjusted`: The personalized pagerank divided by the
#'     node in-degree.
#'   - `regularized`: The personalized pagerank divide by the node
#'     in-degree plus `tau`.
#'
#' When computing personalized pageranks for Twitter users (either
#' via [rtweet_graph()], `name` is given
#' as a user ID, not a screen name, regardless of how the seed nodes
#' were specified.
#'
#' @export
#'
#' @references
#'
#' 1. Chen, Fan, Yini Zhang, and Karl Rohe. “Targeted Sampling from Massive Block Model Graphs with Personalized PageRank.” Journal of the Royal Statistical Society: Series B (Statistical Methodology) 82, no. 1 (February 2020): 99–126. https://doi.org/10.1111/rssb.12349.
#' 2. Andersen, Reid, Fan Chung, and Kevin Lang. “Local Graph Partitioning Using PageRank Vectors.” In 2006 47th Annual IEEE Symposium on Foundations of Computer Science (FOCS’06), 475–86. Berkeley, CA, USA: IEEE, 2006. https://doi.org/10.1109/FOCS.2006.44.
#'
#' @examples
#'
#' library(aPPR)
#' library(igraph)
#'
#' set.seed(27)
#'
#' graph <- rtweet_graph()
#'
#' \dontrun{
#' appr(graph, "alexpghayes")
#' }
#'
#' graph2 <- sample_pa(100)
#'
#' # this creates a Tracker object
#' ppr_results <- appr(graph2, seeds = "5")
#'
#' # the portion of the Tracker object you probably care about
#' ppr_results$stats
#'
appr <- function(graph, seeds, ..., alpha = 0.15, epsilon = 1e-6, tau = NULL,
                 max_visits = Inf) {
  ellipsis::check_dots_used()

  if (alpha <= 0 || alpha >= 1)
    stop("`alpha` must be strictly between zero and one.", call. = FALSE)

  if (epsilon <= 0 || epsilon >= 1)
    stop("`epsilon` must be strictly between zero and one.", call. = FALSE)

  if (!is.null(tau) && tau < 0)
    stop("`tau` must be greater than zero.", call. = FALSE)

  UseMethod("appr")
}

#' @include abstract-graph.R
#' @export
appr.abstract_graph <- function(graph, seeds, ..., alpha = 0.15,
                                epsilon = 1e-6, tau = NULL,
                                max_visits = Inf) {
  tracker <- Tracker$new(graph, alpha, epsilon, tau, max_visits)

  log_debug("Checking seed nodes ... ")
  good_seeds <- check(graph, seeds)
  log_debug(glue("Checking seed nodes ... good_seeds: {good_seeds}"))
  log_debug("Checking seed nodes ... done")

  for (seed in seeds) {

    if (!(seed %in% good_seeds)) {
      stop(
        glue("Seed {seed} must be available and have positive out degree."),
        call. = FALSE
      )
    }

    log_info(glue("Adding seed {seed} to tracker ..."))
    tracker$add_seed(seed, preference = 1 / length(seeds))
    log_info(glue("Adding seed {seed} to tracker ... done"))

  }

  tracker$calculate_ppr()
  tracker$regularize()
  tracker
}
