#' R6 class to manage personalized pagerank calculations
#'
Tracker <- R6Class("Tracker", list(

  #' @field seeds A character vector of the seed nodes.
  seeds = character(0),

  #' @field path A character vector of nodes whose neighborhoods we
  #'   examine.
  path = character(0),

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

  #' @field alpha Teleportation constant from Algorithm 3.
  alpha = numeric(0),

  #' @field alpha_prime Transformed teleportation constant from Algorithm 3.
  alpha_prime = numeric(0),

  #' @field epsilon Error tolerance.
  epsilon = numeric(0),

  #' @field tau Regularization parameter used in Algorithm 4.
  tau = numeric(0),

  #' @description
  #'
  #' Create a new Tracker object.
  #'
  #' @return A new `Tracker` object.
  #'
  initialize = function(alpha, epsilon, tau) {

    self$alpha <- alpha
    self$alpha_prime <- alpha / (2 - alpha)
    self$epsilon <- epsilon
    self$tau <- tau

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

    cat("A Tracker R6 object with PPR table: \n\n")

    print(self$stats)
    invisible(self)
  },

  #' @description
  #'
  #' Determine nodes that need to be visited. Note that,
  #' if there is a node with zero out degree, you will always
  #' need to visit that node. So it is important to make sure
  #' we never add nodes with zero out degree into the tracker.
  #'
  #' @return A character vector of node names with current residuals
  #'   greater than `epsilon`.
  #'
  remaining = function() {
    s <- self$stats
    s[s$r > self$epsilon * s$out_degree, ]$name
  },

  #' @description
  #'
  #' Check if there is already a row for a particular node
  #'
  #' @param nodes Character name of node(s) in the graph.
  #'
  #' @return `TRUE` if there is a row for `node`, `FALSE` if there
  #'   is not a row for `node`.
  #'
  in_tracker = function(nodes) {
    nodes %in% self$stats$name
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
  #' @param seeds The name of the node in the graph as a length 1
  #'   character vector.
  #'
  #' @param preference TODO: recall what on earth this is.
  #'
  add_seed = function(graph, seeds, preference) {
    self$seeds <- c(self$seeds, seeds)
    self$add_nodes(graph = graph, nodes = seeds, preference = preference)
  },

  #' @description
  #'
  #' TODO
  #'
  #' @param node The name of the node in the graph as a length 1
  #'   character vector.
  #'
  add_to_path = function(node) {
    self$path <- c(self$path, node)
  },

  #' @description
  #'
  #' Create an entry for `node` in the tracker. Assumes that
  #' `node` is not in the tracker yet, and does not check if
  #' this is the case.
  #'
  #' @param graph The graph object.
  #' @param nodes The name(s) of node(s) in the graph as a character vector.
  #'
  #' @param preference TODO: recall what on earth this is.
  #'
  add_nodes = function(graph, nodes, preference = 0) {

    degree <- node_degrees(graph, nodes)

    self$stats <- tibble::add_row(
      self$stats,
      name  = nodes,
      p = 0,
      r = preference,
      in_degree = degree$in_degree,
      out_degree = degree$out_degree
    )

  },

  #' @description
  #'
  #' Add `node` to the list of nodes we failed to visit.
  #' Assumes that `node` is not in the failed list yet, and
  #' does not check if this is the case.
  #'
  #' @param nodes The name of the node in the graph as a length 1
  #'   character vector.
  #'
  add_failed = function(nodes) {
    self$failed <- c(self$failed, nodes)
  },

  #' @description
  #'
  #' Update the estimate of the personalized pagerank for a given node
  #'
  #' @param node Character name of a node in the graph.
  #'
  update_p = function(node) {

    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "p"]] <- self$stats[[node_index, "p"]] +
      self$alpha_prime * self$stats[[node_index, "r"]]
  },

  #' @description
  #'
  #' Update the residual of a *good* node in the neighborhood of
  #' the current node, adding it to the tracker if necessary
  #'
  #' @param graph The graph object.
  #' @param u Character name of the node we are currently visiting.
  #' @param v Names of neighbors of `u` as a character vector. Can
  #'   contain multiple elements. Can also contain zero elements.
  #'
  update_r_neighbor = function(graph, u, v) {

    stopifnot(length(u) == 1)

    if (length(v) < 1)
      return(invisible())

    new_nodes <- v[!self$in_tracker(v)]

    if (length(new_nodes) > 0)
      self$add_nodes(graph, new_nodes)

    u_index <- which(self$stats$name == u)
    v_index <- match(v, self$stats$name)

    self$stats[v_index, "r"] <- self$stats[v_index, "r"] +
      (1 - self$alpha_prime) * self$stats[[u_index, "r"]] /
      (2 * self$stats[[u_index, "out_degree"]])

  },

  #' @description
  #'
  #' Update the residual of current node
  #'
  #' @param node Character name of the node we are currently visiting.
  #'
  update_r_self = function(node) {
    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "r"]] <- (1 - self$alpha_prime) *
      self$stats[[node_index, "r"]] / 2
  },

  #' @description
  #'
  #' Compute the degree-adjusted and regularized variants of personalized
  #' PageRank as in Algorithm 4.
  #'
  #' @param node Character name of the node we are currently visiting.
  #'
  regularize = function() {

    if (is.null(self$tau)) {
      tau <- mean(self$stats$in_degree)
    }

    # might divide by 0 here
    self$stats$degree_adjusted <- self$stats$p / self$stats$in_degree
    self$stats$regularized <- self$stats$p / (self$stats$in_degree + tau)
  }
))
