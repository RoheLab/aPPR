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

  #' @field graph An abstract graph object.
  graph = NULL,

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
  #' @param graph See [appr()].
  #' @param alpha See [appr()].
  #' @param epsilon See [appr()].
  #' @param tau See [appr()].
  #'
  #' @return A new `Tracker` object.
  #'
  initialize = function(graph, alpha, epsilon, tau) {

    self$graph <- graph
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
  #' if there is a node with zero out degree, you will never
  #' leave from that node. So it is important to make sure
  #' we never add nodes with zero out degree into the tracker.
  #'
  #' @return A character vector of node names with current residuals
  #'   greater than `epsilon`.
  #'
  remaining = function() {

    # when we initialize, we need to initialize to the seeds
    # here we check for initialization by consider the path
    # of nodes we've visited so far. it's very important that
    # we do not populate `path` when adding the seeds
    if (length(self$path) < 1)
      return(self$seeds)

    self$stats[self$stats$r > self$epsilon * self$stats$out_degree, ]$name
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
  #' @param seeds The name of the node in the graph as a length 1
  #'   character vector.
  #'
  #' @param preference TODO: recall what on earth this is.
  #'
  add_seed = function(seeds, preference) {
    self$seeds <- c(self$seeds, seeds)
    self$add_nodes(nodes = seeds, preference = preference)
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
  #' @param nodes The name(s) of node(s) in the graph as a character vector.
  #'
  #' @param preference TODO: recall what on earth this is.
  #'
  add_nodes = function(nodes, preference = 0) {

    degree <- node_degrees(self$graph, nodes)

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
  #' @param u Character name of the node we are currently visiting.
  #' @param v Names of neighbors of `u` as a character vector. Can
  #'   contain multiple elements. Can also contain zero elements.
  #'
  update_r_neighbor = function(u, v) {

    stopifnot(length(u) == 1)

    if (length(v) < 1)
      return(invisible())

    new_nodes <- v[!self$in_tracker(v)]

    if (length(new_nodes) > 0)
      self$add_nodes(new_nodes)

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
  #' PageRank as in Algorithm 4, based on the outputs of Algorithm 3.
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
  },

  #' @description
  #'
  #' Main driver function to perform the computations outlined in
  #' Algorithm 3.
  #'
  #' @param node Character name of the node we are currently visiting.
  #' @param verbose Logical indicating whether to report on the algorithms
  #'   progress. Defaults to `TRUE`.
  #'
  calculate_ppr = function(verbose = TRUE) {

    if (verbose)
      message(Sys.time(), " Starting PPR calculations.")

    remaining <- self$remaining()

    while (length(remaining) > 0) {

      u <- if (length(remaining) == 1) remaining else sample(remaining, size = 1)

      self$update_p(u)

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

      neighbors <- memo_neighborhood(self$graph, u)

      self$add_to_path(u)

      # first deal with the good neighbors we've already seen all
      # at once

      known_good <- neighbors[self$in_tracker(neighbors)]
      known_bad <- neighbors[self$in_failed(neighbors)]

      unknown <- setdiff(neighbors, c(known_good, known_bad))

      new_good <- check(self$graph, unknown)
      new_bad <- setdiff(unknown, new_good)

      self$add_failed(new_bad)
      self$update_r_neighbor(u, known_good)
      self$update_r_neighbor(u, new_good)

      self$update_r_self(u)

      remaining <- self$remaining()

      if (verbose) {
        message(
          Sys.time(),
          paste0(
            " Visits: ",
            length(self$path), " total / ",
            length(unique(self$path)), " unique / ",
            length(remaining), " remaining"
          )
        )
      }
    }

    if (verbose)
      message(Sys.time(), " PPR calculation finished.")
  }
))
