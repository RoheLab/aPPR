
#' @export
twittercache_graph <- function() {

  # TODO: allow user to specify number of sampling attempts to account for
  # API downtime and issues
  abstract_graph("tc_graph")
}

#' @export
print.tc_graph <- function(x, ...) {
  cat("twittercache graph connection\n")
}

# user_ids rather than screennames

in_degree.tc_graph <- function(graph, node) {

  if (!twittercache:::in_cache(node))
    sample_node(node)

  path <- twittercache:::get_node_path(node)
  node_data <- readRDS(path)
  node_data$followers_count
}

out_degree.tc_graph <- function(graph, node) {
  if (!twittercache:::in_cache(node))
    sample_node(node)

  path <- twittercache:::get_node_path(node)
  node_data <- readRDS(path)
  node_data$friends_count
}

# character list of neighboring nodes
neighborhood.tc_graph <- function(graph, node, directed = TRUE) {

  if (!twittercache:::in_cache(node))
    sample_node(graph, node)

  path <- twittercache:::get_edge_path(node)
  edge_data <- readRDS(path)

  # issue: there will be edges to protected nodes that we can't sample

  as.character(edge_data[edge_data$from == node, ]$to)
}

sample_node <- function(graph, node) {
  stop("Trying to sample node not in Twittercache")
}
