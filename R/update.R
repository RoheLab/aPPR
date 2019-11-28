
#' Update a Tracker object
#'
#' Typically because results are insufficiently precise.
#'
#' At the moment, only supports changing `epsilon`. If there is interest,
#' we can consider allowing updates to `tau`, `alpha` and `seeds` in the
#' future.
#'
#' @param object
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
update.Tracker <- function(object, ..., epsilon, verbose = FALSE) {

  tracker <- object

  if (verbose)
    message(Sys.time(), " Updating aPPR.")

  alpha_prime <- alpha / (2 - alpha)

  remaining <- tracker$remaining(epsilon)

  if (length(remaining) < 1) {
    warning("Tracker has already achieved the desired precision", call. = FALSE)
    return(tracker)
  }

  while (length(remaining) > 0) {

    u <- if (length(remaining) == 1) remaining else sample(remaining, size = 1)

    tracker$update_p(u, alpha_prime)

    # here we come into contact with reality and must depart from the
    # warm embrace of algorithm 3

    # this is where we learn about new nodes. there are two kinds of new
    # nodes: "good" nodes that we can visit, and "bad" nodes that we can't
    # visit, such as protected Twitter accounts or nodes that the API fails
    # to get for some reason. we want to:
    #
    #   - update the good nodes are we typically would
    #   - pretend the bad nodes don't exist
    #
    # also note that we only want to *check* each node once

    neighbors <- memo_neighborhood(graph, u)

    tracker$add_to_path(u)

    # first deal with the good neighbors we've already seen all
    # at once

    known_good <- neighbors[tracker$in_tracker(neighbors)]
    known_bad <- neighbors[tracker$in_failed(neighbors)]

    unknown <- setdiff(neighbors, c(known_good, known_bad))

    new_good <- check(graph, unknown)
    new_bad <- setdiff(unknown, new_good)

    tracker$add_failed(new_bad)
    tracker$update_r_neighbor(graph, u, known_good, alpha_prime)
    tracker$update_r_neighbor(graph, u, new_good, alpha_prime)

    tracker$update_r_self(u, alpha_prime)

    remaining <- tracker$remaining(epsilon)

    if (verbose) {
      message(
        paste0(
          "Visits: ",
          length(tracker$path), " total / ",
          length(unique(tracker$path)), " unique / ",
          length(remaining), " remaining"
        )
      )
    }
  }

  if (verbose)
    message(Sys.time(), " aPPR update finished.")

  ppr <- tracker$stats

  # TODO: save tau in the Tracker object to in case user
  # specified this. also, check if we should use in_degree
  # or out_degree here
  tau <- mean(ppr$in_degree)

  ppr$degree_adjusted <- ppr$p / ppr$in_degree # might divide by 0 here
  ppr$regularized <- ppr$p / (ppr$in_degree + tau)
  tracker$stats <- ppr
  tracker
}
