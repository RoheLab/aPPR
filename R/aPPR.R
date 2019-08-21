#' @export
appr <- function(graph) {
  UseMethod("appr")
}

appr.default <- function(graph) {
  stop(
    paste("No `appr` method exists for objects of class ", class(graph)[1]),
    call. = FALSE
  )
}

# how to set tau?
#' @export
appr.abstract_graph <- function(graph, seed, alpha, epsilon, adjust = TRUE,
                                tau = 0) {

  alpha_prime <- alpha / (2 - alpha)

  tracker <- Tracker$new()

  for (seed in seeds) {
    tracker$add_node(graph, seed, preference = 1 / length(seeds))
  }

  remaining <- tracker$remaining(epsilon)

  while (length(remaining) > 0) {

    # TODO: test edge case when remaining is a single integer node
    u <- sample(remaining, size = 1)

    tracker$update_p(u, alpha_prime)  # u is a node name

    for (v in neighorhood(graph, u)) {
      tracker$update_r_neighbor(graph, u, v)
    }

    tracker$update_r_self(u)

    remaining <- tracker$remaining(epsilon)
  }

  if (!adjust)
    return(tracker$stats$p)

  # TODO: maybe there is a smarter way to guestimate tau
  # based on the observed nodes

  tracker$stats$p / (tracker$stats$in_degree + tau)
}

Tracker <- R6Class("Tracker", list(
  stats = NULL,

  initialize = function() {
    self$stats <- tibble(
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
    s[s$r > epsilon * s$out_degree, "name"]
  },

  in_tracker = function(node) {
    node %in% self$stats$name
  }

  # assumes that node is not in the tracker yet
  add_node = function(graph, node, preference = 0) {

    self$stats <- add_row(
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

  update_r_neighbor = function(graph, u, v) {

    if (!in_tracker(v))
      self$add_node(graph, v)

    u_index <- which(self$stats$name == u)
    v_index <- which(self$stats$name == v)

    self$stats[[v_index, "r"]] <- self$stats[[v_index, "r"]] +
      (1 - alpha_prime) * self$stats[[u_index, "r"]] /
      (2 * self$stats[[u_index, "degree_out"]])

  },

  update_r_self = function(node) {
    node_index <- which(self$stats$name == node)
    self$stats[[node_index, "r"]] <- (1 - alpha_prime) *
      self$stats[[node_index, "r"]] / 2
  }
))
