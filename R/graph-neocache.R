#' Create an abstract representation of the Twitter friendship graph
#'
#' Signifies that `aPPR` should query the Twitter friendship graph via
#' `neocache`.
#'
#' @param attempts The number of times to attempt an API request before
#'   moving on or erroring.
#'
#' @export
neocache_graph <- function(attempts = 5) {
  # TODO: Make sure the Neo4j Docker container is running. If it is not
  #       then warn the user.

  agraph <- abstract_graph("neocache_graph", attempts = attempts)
  agraph
}

#' @rdname appr
#' @export
#' @importFrom neocache lookup_users
appr.neocache_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("rtweet", quietly = TRUE)) {
    stop(
      "`rtweet` package must be installed to use `neocache_graph()`",
      call. = FALSE
    )
  }

  seed_data <- lookup_users(seeds)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  NextMethod()
}

# return character vector of all good nodes in the batch
#' @importFrom neocache lookup_users
#' @importFrom glue glue
check.neocache_graph <- function(graph, nodes) {

  logger::log_debug(glue("Checking nodes"))

  if (length(nodes) < 1)
    return(character(0))

  node_data <- lookup_users(nodes)

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !node_data$protected & node_data$friends_count > 0

  logger::log_debug(glue("Done checking nodes"))

  node_data$user_id[good_nodes]
}

#' @importFrom neocache lookup_users
node_degrees.neocache_graph <- function(graph, nodes) {

  logger::log_debug(glue("Getting node degrees"))

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  node_data <- lookup_users(nodes)

  logger::log_debug(glue("Done getting node degrees"))

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}

#' @importFrom neocache get_friends
neighborhood.neocache_graph <- function(graph, node) {

  logger::log_debug(glue("Getting neighborhood: {node}"))

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- get_friends(node)

  logger::log_debug(glue("Done getting neighborhood"))

  if (nrow(friends) < 1) character(0) else friends$to
}
