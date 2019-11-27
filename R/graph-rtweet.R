#' Create an abstract representation of the Twitter friendship graph
#'
#' Signifies that we should query the Twitter friendship graph via
#' `rtweet`.
#'
#' @param attempts The number of times to attempt an API before
#'   moving on or erroring.
#'
#' @export
rtweet_graph <- function(attempts = 5) {
  agraph <- abstract_graph("rtweet_graph")
  agraph$attempts <- attempts
  agraph
}

appr_rtweet <- function(seeds, ...) {
  batch_appr(rtweet_graph(), seeds, ...)
}

#' @rdname appr
#' @export
appr.rtweet_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("rtweet", quietly = TRUE)) {
    stop(
      "`rtweet` package must be installed to use `rtweet_graph()`",
      call. = FALSE
    )
  }

  seed_data <- safe_lookup_users(seeds, attempts = graph$attempts)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  NextMethod()
  # appr(graph, seeds, ...)
}

#' @rdname appr
#' @export
batch_appr.rtweet_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("rtweet", quietly = TRUE)) {
    stop(
      "`rtweet` package must be installed to use `rtweet_graph()`",
      call. = FALSE
    )
  }

  seed_data <- safe_lookup_users(seeds, attempts = graph$attempts)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  NextMethod()
  # appr(graph, seeds, ...)
}

check.rtweet_graph <- function(graph, node) {

  node_data <- safe_lookup_users(node, attempts = graph$attempts)

  !is.null(node_data) &&
    nrow(node_data) > 0 &&
    !node_data$protected &&
    node_data$friends_count > 0
}

# return character vector of all good nodes in the batch
check_batch.rtweet_graph <- function(graph, nodes) {

  node_data <- safe_lookup_users(nodes, attempts = graph$attempts)

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !node_data$protected & node_data$friends_count > 0

  node_data$user_id[good_nodes]
}

node_degrees.rtweet_graph <- function(graph, nodes) {

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  node_data <- safe_lookup_users(nodes, attempts = graph$attempts)

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}

neighborhood.rtweet_graph <- function(graph, node) {

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- safe_get_friends(node, attempts = graph$attempts)
  if (nrow(friends) < 1) character(0) else friends$user_id
}

