
#' @export
twittercache_graph <- function() {
  new_abstract_graph("tc_graph")
}

#' @export
print.tc_graph <- function() {
  cat("twittercache graph connection\n")
}

# user_ids rather than screennames

in_degree.tc_graph <- function(graph, node) {

  if (!twittercache:::in_cache(node))
    sample_node(node)

  path <- twittercache:::get_node_path(node)
  node_data <- readr::read_rds(path)
  node_data$followers_count
}

out_degree.tc_graph <- function(graph, node) {
  if (!twittercache:::in_cache(node))
    sample_node(node)

  path <- twittercache:::get_node_path(node)
  node_data <- readr::read_rds(path)
  node_data$friends_count
}

# character list of neighboring nodes
neighborhood.tc_graph <- function(graph, node, directed = TRUE) {

  if (!twittercache:::in_cache(node))
    sample_node(node)

  path <- twittercache:::get_edge_path(node)
  edge_data <- readr::read_rds(path)

  # issue: there will be edges to protected nodes that we can't sample


  _data$friends_count

  # check if node is in the cache

  # if it isn't, sample it and save it to the cache

  # return a character vector of users followed by node
}
