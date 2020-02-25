#' Create an abstract representation of the Twitter friendship graph
#'
#' Signifies that `aPPR` should query the Twitter friendship graph via
#' `rtweet`. In practice, uses `socialsampler`, so you
#' can use multiple tokens at once. See [socialsampler::register_token()]
#' for details.
#'
#' @param attempts The number of times to attempt an API request before
#'   moving on or erroring.
#'
#' @export
rtweet_graph <- function(attempts = 5) {
  agraph <- abstract_graph("rtweet_graph", attempts = attempts)
  agraph
}

#' Convenience function to run aPPR via rtweet
#'
#' @param seeds Screen names or user IDs of seed nodes
#'   in the Twitter graph, as a character vector.
#'
#' @inheritDotParams appr
#'
#' @export
#'
appr_rtweet <- function(seeds, ...) {
  appr(rtweet_graph(), seeds, ...)
}

#' @rdname appr
#' @export
#' @importFrom socialsampler safe_lookup_users
appr.rtweet_graph <- function(graph, seeds, ...) {

  if (!requireNamespace("socialsampler", quietly = TRUE)) {
    stop(
      "`socialsampler` package must be installed to use `rtweet_graph()`",
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
}

# return character vector of all good nodes in the batch
#' @importFrom socialsampler safe_lookup_users
#' @importFrom glue glue
check.rtweet_graph <- function(graph, nodes) {

  logger::log_debug(glue("Checking nodes"))

  if (length(nodes) < 1)
    return(character(0))

  node_data <- safe_lookup_users(nodes, attempts = graph$attempts)

  if (is.null(node_data) || nrow(node_data) < 1)
    return(character(0))

  good_nodes <- !node_data$protected & node_data$friends_count > 0

  logger::log_debug(glue("Done checking nodes"))

  node_data$user_id[good_nodes]
}

#' @importFrom socialsampler safe_lookup_users
node_degrees.rtweet_graph <- function(graph, nodes) {

  logger::log_debug(glue("Getting node degrees"))

  # assumes that you want any errors / empty rows when accessing this
  # data, i.e. that the nodes have already been checked

  node_data <- safe_lookup_users(nodes, attempts = graph$attempts)

  logger::log_debug(glue("Done getting node degrees"))

  list(
    in_degree = node_data$followers_count,
    out_degree = node_data$friends_count
  )
}

#' @importFrom socialsampler safe_get_friends
neighborhood.rtweet_graph <- function(graph, node) {

  logger::log_debug(glue("Getting neighborhood: {node}"))

  # if a user doesn't follow anyone, safe_get_friends returns an empty
  # tibble, but instead it should return an empty character vector?
  friends <- safe_get_friends(node, attempts = graph$attempts)

  logger::log_debug(glue("Done getting neighborhood"))

  if (nrow(friends) < 1) character(0) else friends$to
}

