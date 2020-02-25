
#' @export
twittercache_graph <- function(
  direction = c(
    "following",
    "followed-by",
    "both"
  )) {

  direction <- rlang::arg_match(direction)

  if (!requireNamespace("twittercache", quietly = TRUE))
    stop(
      "Must install the development package `alexpghayes/twittercache` ",
      "from Github for this functionality.",
      call. = FALSE
    )

  # TODO: allow user to specify number of sampling attempts to account for
  # API downtime and issues
  abstract_graph("tc_graph", direction = direction)
}

#' @export
print.tc_graph <- function(x, ...) {
  cat("twittercache graph connection\n")
}

# user_ids rather than screennames
# return character vector of all good nodes in the batch
check.tc_graph <- function(graph, nodes) {

  node_data <- twittercache::cache_lookup_users(nodes)

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !node_data$protected & node_data$friends_count > 0

  node_data$user_id[good_nodes]
}

node_degrees.tc_graph <- function(graph, nodes) {

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  node_data <- twittercache::cache_lookup_users(nodes)

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}

neighborhood.tc_graph <- function(graph, node) {

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- safe_get_friends(node, attempts = graph$attempts)
  if (nrow(friends) < 1) character(0) else friends$user_id
}

in_degree.tc_graph <- function(graph, node) {
  twittercache::cache_lookup_users(node)$followers_count
}

out_degree.tc_graph <- function(graph, node) {
  twittercache::cache_lookup_users(node)$followers_count
}

# character list of neighboring nodes
neighborhood.tc_graph <- function(graph, node) {

  direction <- graph$direction

  if (direction == "following") {
  } else if (direction == "followed-by") {
    twittercache::cache_get_followers(node)$from
  } else if (direction == "both") {
    c(
      twittercache::cache_get_friends(node)$to,
      twittercache::cache_get_followers(node)$from
    )
  } else{
    stop("This shouldn't happen.", call. = FALSE)
  }
}
