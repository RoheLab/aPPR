#' @export
new_abstract_graph <- function(subclass) {
  graph <- list()
  class(graph) <- c(subclass, "abstract_graph")
  graph
}

# TODO: do we need to export these??

#' @export
check <- function(graph, node) {
  UseMethod("check")
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
