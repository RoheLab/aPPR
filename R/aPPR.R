#' Approximate personalized pageranks
#'
#' Computes the personalized pagerank for specified seeds using the
#' `ApproximatePageRank` algorithm of Andersen et al. (2006). Computes
#' degree-adjustments and degree-regularization of personalized
#' pagerank vectors as described in Algorithms 3 and 4 of Chen et al. (2019).
#' These algorithms are randomized; if results are unstable across
#' multiple runs, decrease `epsilon`.
#'
#' @param graph An [abstract_graph()] object, such as those created by
#'   [rtweet_graph()] and [twittercache_graph()], and [igraph::igraph()]
#'   object. This argument is required.
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
#'   a valid probabilty; that is, between zero and one. Defaults to `1e-6`.
#'   Runtime is proportional to `1 / (epsilon * alpha)`, so small `epsilon`
#'   can result in long runtimes.
#'
#' @param tau Regularization term. Additionally inflates the in-degree
#'   of each observation by this term by performing the degree
#'   adjustment described in Algorithm 3 and Algorithm 4, which
#'   are described in `vignette("Mathematical details")`. Defaults to
#'   `NULL`, in which case `tau` is set to the average in-degree of
#'   the observed nodes. In general, setting it's reasonable to
#'   set `tau` to the average in-degree of the graph.
#'
#' @param verbose Logical indicating whether to report on the algorithms
#'   progress. Defaults to `TRUE`.
#'
#' @param ... Ignored. Passing arguments to `...` results in a warning.
#'
#' @return A [Tracker()] object. Most relevant is the `stats` field,
#'    a [tibble::tibble()] with the following columns:
#'
#'   - `name`: Name of a node (character).
#'   - `p`: Estimated personalized pagerank of a node.
#'   - `r`: Estimated error of pagerank estimate for a node.
#'   - `in_degree`: Number of incoming edges to a node.
#'   - `out_degree`: Number of outcoming edges from a node.
#'   - `degree_adjusted`: The personalized pagerank divided by the
#'     node in-degree.
#'   - `regularized`: The personalized pagerank divide by the node
#'     in-degree plus `tau`.
#'
#' When computing personalized pageranks for Twitter users (either
#' via [rtweet_graph()] or [twittercache_graph()]), `name` is given
#' as a user ID, not a screen name, regardless of how the seed nodes
#' were specified.
#'
#' @export
#'
#' @references Chen, F., Zhang, Y. & Rohe, K. Targeted sampling from massive Blockmodel graphs with personalized PageRank. 23. <http://arxiv.org/abs/1910.12937>
#'
#' Andersen, R., Chung, F. & Lang, K. Local Graph Partitioning using PageRank Vectors. in 2006 47th Annual IEEE Symposium on Foundations of Computer Science (FOCS’06) 475–486 (IEEE, 2006). doi:10.1109/FOCS.2006.44. <http://ieeexplore.ieee.org/document/4031383/>
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
                 verbose = TRUE) {
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
                                verbose = FALSE) {
  tracker <- Tracker$new(graph, alpha, epsilon, tau)

  for (seed in seeds) {

    if (!(seed %in% check(graph, seed))) {
      stop(
        glue("Seed {seed} must be available and have positive out degree."),
        call. = FALSE
      )
    }

    tracker$add_seed(seed, preference = 1 / length(seeds))

    if (verbose) {
      message(glue("Adding seed {seed} to tracker."))
    }
  }

  tracker$calculate_ppr(verbose)
  tracker$regularize()
  tracker
}
