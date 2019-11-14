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

#' @rdname appr
#' @export
appr.rtweet_graph <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                              tau = NULL, ...) {

  if (!requireNamespace("rtweet", quietly = TRUE)) {
    stop(
      "`rtweet` package must be installed to use `rtweet_graph()`",
      call. = FALSE
    )
  }

  seed_data <- safe_lookup_users(seeds)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  NextMethod()
}

check.rtweet_graph <- function(graph, node) {

  node_data <- safe_lookup_users(node, attempts = graph$attempts)

  !is.null(node_data) &&
    nrow(node_data) > 0 &&
    !node_data$protected &&
    node_data$friends_count > 0
}

in_degree.rtweet_graph <- function(graph, node) {
  safe_lookup_users(node, attempts = graph$attempts)$followers_count
}

out_degree.rtweet_graph <- function(graph, node) {
  safe_lookup_users(node, attempts = graph$attempts)$friends_count
}

neighborhood.rtweet_graph <- function(graph, node) {

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- safe_get_friends(node, attempts = graph$attempts)
  if (nrow(friends) < 1) character(0) else friends$user_id
}

