#' Create an abstract representation of the Twitter friendship graph
#'
#' Signifies that `aPPR` should query the Twitter friendship graph via
#' `neocache`.
#'
#' @param attempts The number of times to attempt an API request before
#'   moving on or erroring.
#'
#' @export
#' @examples
#'
#' \dontrun{
#'
#'
#' test_ids <- c("780429268866052096", "1191642560")
#'
#' graph <- neocache_graph()
#'
#' check(graph, test_ids)
#' node_degrees(graph, test_ids)
#' neighborhood(graph, test_ids[1])
#'
#'
#' }
#'
neocache_graph <- function(cache_name = "aPPR", attempts = 5) {

  if (!requireNamespace("neocache", quietly = TRUE)) {
    stop(
      "`neocache` package must be installed to use `neocache_graph()`",
      call. = FALSE
    )
  }

  if (!neocache::nc_cache_exists(cache_name)) {
    neocache::nc_create_cache(cache_name = cache_name, http_port = 28491, bolt_port = 28492)
  }

  neocache::nc_activate_cache(cache_name)

  agraph <- abstract_graph(
    "neocache_graph",
    cache_name = cache_name,
    attempts = attempts
  )

  agraph
}

#' @rdname appr
#' @export
appr.neocache_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("neocache", quietly = TRUE)) {
    stop(
      "`neocache` package must be installed to use `neocache_graph()`",
      call. = FALSE
    )
  }

  seed_data <- rtweet::lookup_users(seeds, retryonratelimit = TRUE)

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  # have to double call the API to get information safely into the cache
  neocache::nc_lookup_users(seeds, cache_name = graph$cache_name, retryonratelimit = TRUE)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }



  NextMethod()
}

# return character vector of all good nodes in the batch
#' @importFrom glue glue
#' @export
check.neocache_graph <- function(graph, nodes) {

  logger::log_debug(glue("Checking nodes"))

  if (length(nodes) < 1)
    return(character(0))

  node_data <- neocache::nc_lookup_users(nodes, cache_name = graph$cache_name)

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !is.na(node_data$protected) & !node_data$protected & node_data$friends_count > 0

  log_debug(glue("Done checking nodes"))

  node_data$user_id[good_nodes]
}

#' @export
node_degrees.neocache_graph <- function(graph, nodes) {

  log_debug(glue("Getting node degrees"))

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  log_trace(glue("Getting node degree(s): {nodes}"))

  node_data <- neocache::nc_lookup_users(nodes, cache_name = graph$cache_name)

  logger::log_debug(glue("Done getting node degrees"))

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}

#' @export
neighborhood.neocache_graph <- function(graph, node) {

  logger::log_debug(glue("Getting neighborhood: {node}"))

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- neocache::nc_get_friends(node, cache_name = graph$cache_name)

  logger::log_debug(glue("Done getting neighborhood"))

  if (nrow(friends) < 1) character(0) else friends$to
}
