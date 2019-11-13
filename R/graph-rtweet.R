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
  agraph <- new_abstract_graph("rtweet_graph")
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

  seed_data <- rtweet::lookup_users(seeds)

  if (any(seed_data$protected)) {
    stop("Seed nodes should not be protected Twitter accounts.", call. = FALSE)
  }

  # convert seeds, potentially passed as screen names, to user ids
  seeds <- seed_data$user_id

  NextMethod()
}

in_degree.rtweet_graph <- function(graph, node) {
  rtweet::lookup_users(node)$followers_count
}

out_degree.rtweet_graph <- function(graph, node) {
  rtweet::lookup_users(node)$friends_count
}

# TODO: rate limiting, token usage, blargh
neighborhood.rtweet_graph <- function(graph, node) {
  rtweet::get_friends(node)$user_id
}

