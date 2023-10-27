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
#'   - Can get all nodes connected to `node` / the 1-hop neighborhood
#'
#' @param graph A graph object.
#' @param nodes The name(s) of node(s) in `graph` as a character vector.
#'
#' @return The subset of `nodes` that are acceptable for inclusion. This
#'   can be a character vector of length zero if necessary. It is critical
#'   that no entries of `nodes` are duplicated in this output, so we
#'   recommend calling `unique()` if there is any potential for repeats
#'   in your checking good.
#'
#' @export
check <- function(graph, nodes) {
  UseMethod("check")
}

#' Get the in-degree and out-degree of nodes in an abstract graph
#'
#' This function is only called nodes that have been [check()]'d. It is
#' safe to assume that `nodes` is non-empty.
#'
#' @param graph A graph object.
#' @param nodes The name(s) of node(s) in `graph` as a character vector.
#'   Methods may assume that there are no repeated values in `nodes`.
#'
#' @return A [data.frame()] with one row for every node in `nodes` and
#'   two columns: `in_degree` and `out_degree`.
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
#' @param node The name of a single node in `graph` as a character vector.
#'
#' @return A character vector of all nodes in `graph` connected such that
#'   there is an outgoing edge for `node` to those nodes. This should
#'   never be empty, as `neighborhood()` should not be called on nodes
#'   that fail `check()`, and `check()` enforces that nodes have out-degree
#'   of at least one. It is critical node names are duplicated in the
#'   output recommend calling `unique()` if there is any potential for
#'   for that to occur.
#'
#' @export
neighborhood <- function(graph, node) {

  if (length(node) != 1)
    stop("`node` must be a character vector of length 1L.", call. = FALSE)

  UseMethod("neighborhood")
}

# memoized versions, these are what actually get used
#' @importFrom memoise memoise
memo_neighborhood <- memoise::memoise(neighborhood)

#' @method print abstract_graph
#' @export
print.abstract_graph <- function(x, ...) {
  cat(glue("Abstract graph object (subclass: {class(x)[1]})\n"))
}
