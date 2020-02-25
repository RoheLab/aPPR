#' Create an abstract graph object
#'
#' Could be an actual graph object, or a graph such as the Twitter
#' following network defined implicitly via API requests, etc.
#' The abstract graph is just a list with `abstract_graph` class
#' and your desired subclass.
#'
#' @param subclass Desired subclass (character).
#' @param ... Other arguments to pass to `list()`. See
#'   [rtweet_graph()] for an example.
#'
#' @export
abstract_graph <- function(subclass, ...) {
  graph <- list(...)
  class(graph) <- c(subclass, "abstract_graph")
  graph
}

#' Check if a node an abstract graph is acceptable for inclusion in PPR
#'
#' Inclusion criteria:
#'
#'   - At least one outgoing edge
#'   - Can get in degree and out degree of node
#'   - Can get all nodes connected to `node` / the 1-hop neighbhorhood
#'
#' @param graph A graph object.
#' @param nodes The name(s) of node(s) in `graph` as a character vector.
#'
#' @return The subset of `nodes` that are acceptable for inclusion. This
#'   can be a character vector of length zero if necessary.
#'
#' @export
check <- function(graph, nodes) {
  UseMethod("check")
}

#' Get the in-degree and out-degree of nodes in an abstract graph
#'
#' This function is only called nodes that have been [check()]'d. It is
#' safe to assume that `nodes` is non-empty. (TODO: check this!)
#'
#' @param graph A graph object.
#' @param nodes The name(s) of node(s) in `graph` as a character vector.
#'
#' @return A [data.frame()] with one row for every node in `nodes` and
#'   two columns: `in_degree` and `out_degree`.frame with one
#'
#' @export
node_degrees <- function(graph, nodes) {
  UseMethod("node_degrees")
}

#' Get the neighborhood of a node in a graph
#'
#' That is, find all nodes connected to `node` by an outgoing edge.
#' This function is memorized to avoid making repeated API queries.
#'
#' @param graph A graph object.
#' @param nodes The name of a single node in `graph` as a character vector.
#'
#' @return A character vector of all nodes in `graph` connected such that
#'   there is an outgoing edge for `node` to those nodes. This should
#'   never be empty, as `neighborhood()` should not be called on nodes
#'   that fail `check()`.
#'
#' @export
neighborhood <- function(graph, node) {

  if (length(node) != 1)
    stop("`node` must be a character vector of length 1L.", call. = FALSE)

  UseMethod("neighborhood")
}

# memoized versions, these are what actually get used
memo_neighborhood <- memoise::memoise(neighborhood)
