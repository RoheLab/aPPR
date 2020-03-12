
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

  # might be a bit weird with how twittercache and socialsampler interact
  abstract_graph("tc_graph", direction = direction)
}

#' @export
print.tc_graph <- function(x, ...) {
  cat("twittercache graph connection\n")
}

#' @rdname appr
#' @export
#' @importFrom twittercache cache_lookup_users
appr.tc_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("twittercache", quietly = TRUE)) {
    stop(
      "`twittercache` package must be installed to use `twittercache_graph()`",
      call. = FALSE
    )
  }

  seed_data <- cache_lookup_users(seeds)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  NextMethod()
}

# return character vector of all good nodes in the batch
#' @importFrom twittercache cache_lookup_users
#' @importFrom glue glue
check.tc_graph <- function(graph, nodes) {

  log_debug(glue("Checking nodes"))

  if (length(nodes) < 1)
    return(character(0))

  node_data <- cache_lookup_users(nodes)

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !node_data$protected & node_data$friends_count > 0

  log_debug(glue("Done checking nodes"))

  node_data$user_id[good_nodes]
}

#' @importFrom twittercache cache_lookup_users
node_degrees.tc_graph <- function(graph, nodes) {

  logger::log_debug(glue("Getting node degrees"))

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  node_data <- cache_lookup_users(nodes)

  logger::log_debug(glue("Done getting node degrees"))

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}

#' @importFrom twittercache cache_get_friends
neighborhood.tc_graph <- function(graph, node) {

  logger::log_debug(glue("Getting neighborhood: {node}"))

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- cache_get_friends(node)

  logger::log_debug(glue("Done getting neighborhood"))

  if (nrow(friends) < 1) character(0) else friends$to
}

