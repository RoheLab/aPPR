#' @export
new_abstract_graph <- function(subclass) {
  graph <- list()
  class(graph) <- c(subclass, "abstract_graph")
  graph
}

in_degree <- function(graph, node) {
  UseMethod("in_degree")
}

out_degree <- function(graph, node) {
  UseMethod("out_degree")
}

neighborhood <- function(graph, node) {
  UseMethod("neighborhood")
}
