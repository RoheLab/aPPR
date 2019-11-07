igraph_connection <- function(igraph_object) {

  if (!inherits(igraph_object, "igraph"))
    stop("`igraph_object` must be an object of class `igraph`.", call. = FALSE)

  if (!requireNamespace("igraph", quietly = TRUE))
    stop("`igraph` package must be installed to use igraphs.", call. = FALSE)

  if (is.null(V(igraph_object)$names))
    V(igraph_object)$names <- as.character(1:gorder(igraph_object))

  agraph <- new_abstract_graph("igraph_connection")
  agraph$igraph <- igraph_object
  agraph
}

#' @export
print.igraph_connection <- function(x, ...) {
  cat("igraph graph connection\n")
}

# user_ids rather than screennames

in_degree.igraph_connection <- function(graph, node) {
  igraph::degree(graph$igraph, v = node, mode = "in")
}

out_degree.igraph_connection <- function(graph, node) {
  igraph::degree(graph$igraph, v = node, mode = "out")
}

# character list of neighboring nodes
# treat directed vs undirected differently?
neighborhood.igraph_connection <- function(graph, node) {
  int_node_list <- igraph::ego(
    graph$igraph, nodes = node, mode = "out", mindist = 1
  )

  nodes <- int_node_list[[1]]

  V(graph$igraph)$names[nodes]
}

