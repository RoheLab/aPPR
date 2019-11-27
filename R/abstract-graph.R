#' Create an abstract graph object
#'
#' Could be an actual graph object, or a graph such as the Twitter
#' following network defined implicitly via API requests, etc.
#'
#' @param subclass TODO
#' @param ... TODO
#'
#' @return Returns `TRUE` if information on `node` is available, and
#'   `node` has at least one outgoing edge.
#'
#' @export
abstract_graph <- function(subclass, ...) {
  graph <- list(...)
  class(graph) <- c(subclass, "abstract_graph")
  graph
}

#' Check if a node an abstract graph is acceptable for inclusion in PPR
#'
#' @param graph A graph object.
#' @param node The name of a node as a character vector.
#'
#' @return Returns `TRUE` if information on `node` is available, and
#'   `node` has at least one outgoing edge.
#'
#' @export
check <- function(graph, node) {
  UseMethod("check")
}

#' @export
check_batch <- function(graph, node) {
  UseMethod("check_batch")
}

#' @export
in_degree <- function(graph, node) {
  UseMethod("in_degree")
}

#' @export
out_degree <- function(graph, node) {
  UseMethod("out_degree")
}

#' @export
neighborhood <- function(graph, node) {
  UseMethod("neighborhood")
}
