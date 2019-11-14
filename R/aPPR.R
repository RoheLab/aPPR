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
#' @param alpha Teleportation constant. The teleportation constant is the
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
#' appr(graph2, seeds = "5")
#'
appr <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6, tau = NULL, ...) {
  ellipsis::check_dots_used()
  UseMethod("appr")
}

#' @include abstract-graph.R
#' @export
appr.abstract_graph <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                                tau = NULL, verbose = FALSE, ...) {

  if (verbose)
    message("Initializing the tracker.")

  alpha_prime <- alpha / (2 - alpha)

  tracker <- Tracker$new()

  for (seed in seeds) {

    if (!check(graph, seed))
      stop(
        paste("Seed", seed, "must be available and have positive out degree."),
        call. = FALSE
      )

    tracker$add_seed(graph, seed, preference = 1 / length(seeds))

    if (verbose)
      message(paste("Adding seed", seed, "to tracker."))
  }

  remaining <- seeds

  if (verbose)
    message(paste("There are", length(remaining), "remaining nodes."))

  while (length(remaining) > 0) {

    u <- if (length(remaining) == 1) remaining else sample(remaining, size = 1)

    if (verbose)
      message(paste("Updating p for node", u))

    tracker$update_p(u, alpha_prime)

    # here we come into contact with reality and must depart from the
    # warm embrace of algorithm 3

    # this is where we learn about new nodes. there are two kinds of new
    # nodes: "good" nodes that we can visit, and "bad" nodes that we can't
    # visit, such as protected Twitter accounts or nodes that the API fails
    # to get for some reason. we want to:
    #
    #   - update the good nodes are we typically would
    #   - pretend the bad nodes don't exist
    #
    # also note that we only want to *check* each node once

    if (verbose)
      message(paste("Sampling the neighborhood for node", u))

    for (v in neighborhood(graph, u)) {

      if (verbose)
        message(paste("Processing item", v, "in neighborhood of", u))

      # two cases if we've already seen v

      if (tracker$in_tracker(v)) {

        if (verbose)
          message(paste("Case:", v, "is in the tracker"))

        # we've already seen v and know v is good because
        # we never add bad v into the tracker

        tracker$update_r_neighbor(graph, u, v, alpha_prime)

      } else if (tracker$in_failed(v)) {

        if (verbose)
          message(paste("Case:", v, "is in the failed list"))

      } else if (check(graph, v)) {

        if (verbose)
          message(paste("Case:", v, "is a good new node"))

        # v is not in the tracker, or the failed list,
        # so v is a new node. we then check v and v turns out
        # to be good, so we can add it to the tracker

        tracker$update_r_neighbor(graph, u, v, alpha_prime)

        # v is a new node, and we can't access information
        # about it, so we pretend that it doesn't exist and

      } else {

        if (verbose)
          message(paste("Case:", v, "is a bad new node"))

      }

      if (verbose)
        print(dplyr::arrange(tracker$stats, desc(r)))
    }

    if (verbose)
      message(paste("Successfully dealt with neighborhood of", u))

    tracker$update_r_self(u, alpha_prime)

    if (verbose)
      message(paste("Successfully updated r for", u))

    remaining <- tracker$remaining(epsilon)

    if (verbose)
      message(paste("There are", length(remaining), "remaining nodes."))
  }

  ppr <- tracker$stats

  if (is.null(tau)) {
    tau <- mean(ppr$in_degree)  # TODO: in_degree or out_degree here?
  }

  ppr$degree_adjusted <- ppr$p / ppr$in_degree      # might divide by 0 here
  ppr$regularized <- ppr$p / (ppr$in_degree + tau)
  ppr
}

