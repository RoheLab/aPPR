#' Create an abstract representation of the Twitter friendship graph
#'
#' Signifies that `aPPR` should query the Twitter friendship graph via
#' `rtweet`.
#'
#' @inheritParams rtweet::get_friends
#'
#' @export
rtweet_graph <- function(retryonratelimit = TRUE, verbose = FALSE, n = 5000) {

  agraph <- abstract_graph(
    "rtweet_graph",
    retryonratelimit = retryonratelimit,
    verbose = verbose,
    max_friends = n
  )

  agraph
}

#' @rdname appr
#' @export
appr.rtweet_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("neocache", quietly = TRUE)) {
    stop(
      "`rtweet` package must be installed to use `rtweet_graph()`",
      call. = FALSE
    )
  }

  seed_data <- rtweet::lookup_users(
    seeds,
    retryonratelimit = graph$retryonratelimit,
    verbose = graph$verbose
  )

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$id_str

  NextMethod()
}

# return character vector of all good nodes in the batch
#' @importFrom glue glue
check.rtweet_graph <- function(graph, nodes) {

  logger::log_debug(glue("Checking nodes"))

  if (length(nodes) < 1)
    return(character(0))

  node_data <- rtweet::lookup_users(
    nodes,
    retryonratelimit = graph$retryonratelimit,
    verbose = graph$verbose
  )

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !node_data$protected & node_data$friends_count > 0

  logger::log_debug(glue("Done checking nodes"))

  node_data$id_str[good_nodes]
}

node_degrees.rtweet_graph <- function(graph, nodes) {

  logger::log_debug(glue("Getting node degrees"))

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  node_data <- rtweet::lookup_users(
    nodes,
    retryonratelimit = graph$retryonratelimit,
    verbose = graph$verbose
  )

  logger::log_debug(glue("Done getting node degrees"))

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}
neighborhood.rtweet_graph <- function(graph, node) {

  logger::log_debug(glue("Getting neighborhood: {node}"))

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- rtweet::get_friends(
    users = node,
    n = graph$max_friends,
    retryonratelimit = graph$retryonratelimit,
    verbose = graph$verbose
  )

  logger::log_debug(glue("Done getting neighborhood"))

  if (nrow(friends) < 1) character(0) else friends$to_id
}

