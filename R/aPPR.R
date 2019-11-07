#' Approximate personalized pageranks
#'
#' @param graph TODO
#' @param seeds TODO
#' @param alpha TODO
#' @param epsilon TODO
#' @param adjust TODO
#' @param tau TODO
#' @param ... Ignored. Passing arguments to `...` results in a warning.
#'
#' @return TODO
#' @export
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
appr <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                 adjust = TRUE, tau = 0, ...) {
  ellipsis::check_dots_used()
  UseMethod("appr")
}

#' @include abstract-graph.R
#' @export
appr.abstract_graph <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                                adjust = TRUE, tau = 0, ...) {

  alpha_prime <- alpha / (2 - alpha)

  tracker <- Tracker$new()

  for (seed in seeds) {
    tracker$add_node(graph, seed, preference = 1 / length(seeds))
  }

  remaining <- tracker$remaining(epsilon)

  while (length(remaining) > 0) {

    # TODO: test edge case when remaining is a single integer node
    u <- if (length(remaining) == 1) remaining else sample(remaining, size = 1)

    tracker$update_p(u, alpha_prime)  # u is a node name

    for (v in neighborhood(graph, u)) {
      tracker$update_r_neighbor(graph, u, v, alpha_prime)
    }

    tracker$update_r_self(u, alpha_prime)

    remaining <- tracker$remaining(epsilon)
  }

  tracker$stats
  #
  # if (!adjust)
  #   return(tracker$stats$p)
  #
  # # TODO: maybe there is a smarter way to guestimate tau
  # # based on the observed nodes
  #
  # # TODO: divide by zero issue -- will this happen?
  # #   what if you get a graph with a singleton node
  #
  # trackertracker$stats$p / (tracker$stats$in_degree + tau)
}

Tracker <- R6Class("Tracker", list(
  stats = NULL,

  initialize = function() {
    self$stats <- tibble::tibble(
      name = character(0),
      r = numeric(0),
      p = numeric(0),
      in_degree = numeric(0),
      out_degree = numeric(0)
    )
  },

  print = function() {
    print(self$stats)
    invisible(self)
  },

  remaining = function(epsilon) {
    s <- self$stats
    s[s$r > epsilon * s$out_degree, ]$name
  },

  in_tracker = function(node) {
    node %in% self$stats$name
  },

  # assumes that node is not in the tracker yet
  add_node = function(graph, node, preference = 0) {

    # add a step to check whether data is available on node
    # this should be a generic

    self$stats <- tibble::add_row(
      self$stats,
      name  = node,
      p = 0,
      r = preference,
      in_degree = in_degree(graph, node),
      out_degree = out_degree(graph, node)
    )

  },

  update_p = function(node, alpha_prime) {

    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "p"]] <- self$stats[[node_index, "p"]] +
      alpha_prime * self$stats[[node_index, "r"]]
  },

  update_r_neighbor = function(graph, u, v, alpha_prime) {

    if (!self$in_tracker(v))
      self$add_node(graph, v)

    # sometimes adding a node will fail (for example, attempting to
    # sample a protected user). in this case, we just pretend this user
    # isn't in the neighborhood of u

    # TODO: add some sort of boolean update

    u_index <- which(self$stats$name == u)
    v_index <- which(self$stats$name == v)

    self$stats[[v_index, "r"]] <- self$stats[[v_index, "r"]] +
      (1 - alpha_prime) * self$stats[[u_index, "r"]] /
      (2 * self$stats[[u_index, "out_degree"]])

  },

  update_r_self = function(node, alpha_prime) {
    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "r"]] <- (1 - alpha_prime) *
      self$stats[[node_index, "r"]] / 2
  }
))
