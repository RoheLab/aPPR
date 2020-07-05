
#' @rdname appr
#' @export
appr.igraph <- function(graph, seeds, ...) {

  if (!requireNamespace("igraph", quietly = TRUE))
    stop("`igraph` package must be installed to use igraphs.", call. = FALSE)

  if (is.null(igraph::V(graph)$names))
    igraph::V(graph)$names <- as.character(1:igraph::gorder(graph))

  appr.abstract_graph(graph = graph, seeds = seeds, ...)
}

check.igraph <- function(graph, nodes) {

  node_names <- names(igraph::V(graph))
  nodes_in_graph <- nodes[nodes %in% node_names]

  nodes_in_graph[igraph::degree(graph, v = nodes_in_graph, mode = "out") > 0]
}

node_degrees.igraph <- function(graph, nodes) {
  list(
    in_degree = igraph::degree(graph, v = nodes, mode = "in"),
    out_degree = igraph::degree(graph, v = nodes, mode = "out")
  )
}

# character list of neighboring nodes
# treat directed vs undirected differently?
neighborhood.igraph <- function(graph, node) {
  int_node_list <- igraph::ego(
    graph, nodes = node, mode = "out", mindist = 1
  )

  nodes <- int_node_list[[1]]
  igraph::V(graph)$names[nodes]
}

