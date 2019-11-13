
#' @rdname appr
#' @export
#'
#' @examples
#'
#' library(igraph)
#'
#' set.seed(27)
#'
#' graph <- sample_pa(100)
#'
#' appr(graph, seeds = "5")
#'
appr.igraph <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                        tau = NULL, ...) {

  if (!requireNamespace("igraph", quietly = TRUE))
    stop("`igraph` package must be installed to use igraphs.", call. = FALSE)

  if (is.null(V(graph)$names))
    V(graph)$names <- as.character(1:gorder(graph))

  if (!all(seeds %in% V(graph)$names))
    stop("All `seeds` must be nodes in `graph`.", call. = FALSE)

  appr.abstract_graph(graph = graph, seeds = seeds, ...)
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

