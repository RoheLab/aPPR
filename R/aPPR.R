#' Approximate personalized pageranks
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
#' @param alpha Teleporting factor. The teleportation factor is the
#'   probability of returning to a seed node at each node transition.
#'   Defaults to `0.15`. This is the inverse of the "dampening factor"
#'   in the original PageRank paper, so `alpha = 0.15` corresponds
#'   to a dampening factor of `0.85`.
#'
#' @param epsilon Desired accuracy of approximation. Small `epsilon`
#'   can result in long runtimes. Defaults to `1e-6`.
#'
#' @param tau Regularization term. Additionally inflates the in degree
#'   of each observation by this term by performing the degree
#'   adjustment described in Algorithm 3 and Algorithm 4, which
#'   are described in `vignette("Mathematical details")`. Defaults to
#'   `NULL`, in which case `tau` is set to the average in degree of
#'   the observed nodes. In general, setting it's reasonable to
#'   set `tau` to the average degree of the graph.
#'
#' @param ... Ignored. Passing arguments to `...` results in a warning.
#'
#' @return A [tibble::tibble()] with the following columns:
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
#' When `graph` is an
#'
#'   - `rtweet_graph` get `user_id` not screen names
#'
#'
#'
#' @export
#'
#' @details
#'
#' Note that, due to the inspection paradox, the average observed
#' degree of the network will be higher than the average degree of
#' the entire network. This means that the default value for `tau`
#' many be a bit high. In practice, we do not observe that the
#' small changes in the value of `tau` substantively changes results,
#' you really just need to regularize enough so that low in degree
#' nodes don't look overly important after degree correction.
#'
#' @examples
#'
#' #### on a concrete, local igraph object
#'
#' library(igraph)
#'
#' set.seed(27)
#'
#' ig <- sample_pa(100)
#'
#' gcon <- igraph_connection(ig)
#'
#' in_degree(gcon, "1")
#' out_degree(gcon, "1")
#' neighborhood(gcon, "1")
#'
#' ##### on the twitter graph via rtweet
#'
#' # TODO
#'
#' ##### on the twitter graph via twittercache
#'
#' # TODO
#'
appr <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6, tau = NULL, ...) {
  ellipsis::check_dots_used()
  UseMethod("appr")
}

#' @include abstract-graph.R
#' @export
appr.abstract_graph <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                                tau = NULL, ...) {

  alpha_prime <- alpha / (2 - alpha)

  tracker <- Tracker$new()

  for (seed in seeds) {
    tracker$add_node(graph, seed, preference = 1 / length(seeds))
  }

  remaining <- tracker$remaining(epsilon)

  while (length(remaining) > 0) {

    u <- if (length(remaining) == 1) remaining else sample(remaining, size = 1)

    tracker$update_p(u, alpha_prime)  # u is a node name

    for (v in neighborhood(graph, u)) {
      tracker$update_r_neighbor(graph, u, v, alpha_prime)
    }

    tracker$update_r_self(u, alpha_prime)

    remaining <- tracker$remaining(epsilon)
  }

  ppr <- tracker$stats

  if (is.null(tau)) {
    tau <- mean(ppr$in_degree)  # TODO: in_degree or out_degree here?
  }

  ppr$degree_adjusted <- ppr$p / ppr$in_degree      # might divide by 0 here
  ppr$regularized <- ppr$p / (ppr$in_degree + tau)
}

