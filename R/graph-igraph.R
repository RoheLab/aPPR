
#' @rdname appr
#' @export
appr.igraph <- function(graph, seeds, ...) {

  if (!requireNamespace("igraph", quietly = TRUE))
    stop("`igraph` package must be installed to use igraphs.", call. = FALSE)

  if (is.null(V(graph)$names))
    V(graph)$names <- as.character(1:gorder(graph))

  appr.abstract_graph(graph = graph, seeds = seeds, ...)
}

check.igraph <- function(graph, node) {
  node %in% V(graph)$names
}

in_degree.igraph <- function(graph, node) {
  igraph::degree(graph, v = node, mode = "in")
}

out_degree.igraph <- function(graph, node) {
  igraph::degree(graph, v = node, mode = "out")
}

# character list of neighboring nodes
# treat directed vs undirected differently?
neighborhood.igraph <- function(graph, node) {
  int_node_list <- igraph::ego(
    graph, nodes = node, mode = "out", mindist = 1
  )

  nodes <- int_node_list[[1]]
  V(graph)$names[nodes]
}

