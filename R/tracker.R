#' R6 class to manage personalized pagerank calculations
#'
Tracker <- R6Class("Tracker", list(

  #' @field seeds A character vector of the seed nodes.
  seeds = character(0),

  #' @field stats A [tibble::tibble()] with one row for each visited
  #'   node and the following columns:
  #'
  #'   - `name`: Name of a node (character).
  #'   - `r`: Current estimate of residual for a node.
  #'   - `p`: Current estimate of the pagerank for a node.
  #'   - `in_degree`: Number of incoming edges to a node.
  #'   - `out_degree`: Number of outcoming edges from a node.
  #'
  stats = NULL,

  #' @field failed A character vector of nodes that could not be visited.
  failed = character(0),

  #' @description
  #'
  #' Create a new Tracker object.
  #'
  #' @return A new `Tracker` object.
  #'
  initialize = function() {
    self$stats <- tibble::tibble(
      name = character(0),
      r = numeric(0),
      p = numeric(0),
      in_degree = numeric(0),
      out_degree = numeric(0)
    )
  },

  #' @description
  #'
  #' Print the tibble containing the current state of the pagerank
  #' calculation.
  #'
  print = function() {
    print(self$stats)
    invisible(self)
  },

  #' @description
  #'
  #' Determine nodes that need to be visited
  #'
  #' @param epsilon The error tolerance / convergence parameter in
  #'   Algorithm 3.
  #'
  #' @return A character vector of node names with current residuals
  #'   greater than `epsilon`.
  #'
  remaining = function(epsilon) {
    s <- self$stats
    s[s$r > epsilon * s$out_degree, ]$name
  },

  #' @description
  #'
  #' Check if there is already a row for a particular node
  #'
  #' @param node Character name of a node in the graph.
  #'
  #' @return `TRUE` if there is a row for `node`, `FALSE` if there
  #'   is not a row for `node`.
  #'
  in_tracker = function(node) {
    node %in% self$stats$name
  },

  #' @description
  #'
  #' Check if we previously failed to visit a node
  #'
  #' @param node Character name of a node in the graph.
  #'
  #' @return `TRUE` if we failed to visit `node`, `FALSE` otherwise.
  #'   Note that this function will return `FALSE` if `node` is new
  #'   and we haven't seen it before.
  #'
  in_failed = function(node) {
    node %in% self$failed
  },

  #' @description
  #'
  #' Create an entry for `node` in the tracker. Assumes that
  #' `node` is not in the tracker yet, and does not check if
  #' this is the case.
  #'
  #' @param graph The graph object.
  #' @param node The name of the node in the graph as a length 1
  #'   character vector.
  #'
  #' @param preference TODO: recall what on earth this is.
  #'
  add_seed = function(graph, node, preference) {
    self$seeds <- c(self$seeds, node)
    self$add_node(graph = graph, node = node, preference = preference)
  },

  #' @description
  #'
  #' Create an entry for `node` in the tracker. Assumes that
  #' `node` is not in the tracker yet, and does not check if
  #' this is the case.
  #'
  #' @param graph The graph object.
  #' @param node The name of the node in the graph as a length 1
  #'   character vector.
  #'
  #' @param preference TODO: recall what on earth this is.
  #'
  add_node = function(graph, node, preference = 0) {

    self$stats <- tibble::add_row(
      self$stats,
      name  = node,
      p = 0,
      r = preference,
      in_degree = in_degree(graph, node),
      out_degree = out_degree(graph, node)
    )

  },

  #' @description
  #'
  #' Add `node` to the list of nodes we failed to visit.
  #' Assumes that `node` is not in the failed list yet, and
  #' does not check if this is the case.
  #'
  #' @param node The name of the node in the graph as a length 1
  #'   character vector.
  #'
  add_failed = function(node) {

    self$failed <- c(self$failed, node)

  },

  #' @description
  #'
  #' Update the estimate of the personalized pagerank for a given node
  #'
  #' @param node Character name of a node in the graph.
  #' @param alpha_prime Transformed teleportation constant from Algorithm 3.
  #'
  update_p = function(node, alpha_prime) {

    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "p"]] <- self$stats[[node_index, "p"]] +
      alpha_prime * self$stats[[node_index, "r"]]
  },

  #' @description
  #'
  #' Update the residual of a *good* node in the neighborhood of
  #' the current node, adding it to the tracker if necessary
  #'
  #' @param graph The graph object.
  #' @param u Character name of the node we are currently visiting.
  #' @param v Character name of a neighborhor of `u`.
  #' @param alpha_prime Transformed teleportation constant from Algorithm 3.
  #'
  update_r_neighbor = function(graph, u, v, alpha_prime) {

    if (!self$in_tracker(v))
      self$add_node(graph, v)

    u_index <- which(self$stats$name == u)
    v_index <- which(self$stats$name == v)

    self$stats[[v_index, "r"]] <- self$stats[[v_index, "r"]] +
      (1 - alpha_prime) * self$stats[[u_index, "r"]] /
      (2 * self$stats[[u_index, "out_degree"]])

  },

  #' @description
  #'
  #' Update residuals based on a *bad* node in the neighborhood
  #' of the current node by updating the residuals of the seeds
  #' and adding the bad node to the list of failed nodes
  #'
  #' @param graph The graph object.
  #' @param u Character name of the node we are currently visiting.
  #' @param v Character name of a neighborhor of `u`.
  #' @param alpha_prime Transformed teleportation constant from Algorithm 3.
  #'
  update_r_bad_v = function(graph, u, v, alpha_prime) {

    if (!self$in_failed(v))
      self$add_failed(graph, v)

    # sometimes adding a node will fail (for example, attempting to
    # sample a protected user). in this case, we just pretend this user
    # isn't in the neighborhood of u

    u_index <- which(self$stats$name == u)

    # give all the residual that would have gone to v to u, for
    # the time being

    self$stats[[u_index, "r"]] <- self$stats[[u_index, "r"]] +
      (1 - alpha_prime) * self$stats[[u_index, "r"]] /
      (2 * self$stats[[u_index, "out_degree"]])

  },

  #' @description
  #'
  #' Update the residual of current node
  #'
  #' @param node Character name of the node we are currently visiting.
  #' @param alpha_prime Transformed teleportation constant from Algorithm 3.
  #'
  update_r_self = function(node, alpha_prime) {
    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "r"]] <- (1 - alpha_prime) *
      self$stats[[node_index, "r"]] / 2
  }
))
