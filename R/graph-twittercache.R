
#' @export
twittercache_graph <- function() {
  new_abstract_graph("tc_graph")
}

#' @export
print.tc_graph <- function() {
  cat("twittercache graph connection\n")
}

in_degree.tc_graph <- function(node) {
  # pass
}

out_degree.tc_graph <- function(node) {
  # pass
}

neighborhood.tc_graph <- function(node) {
  # pass
}
