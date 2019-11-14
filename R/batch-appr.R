batch_appr <- function(graph, seeds, alpha = 0.15, epsilon = 1e-6,
                       tau = NULL, verbose = FALSE, ...) {

  if (verbose)
    message("Initializing the tracker.")

  alpha_prime <- alpha / (2 - alpha)

  tracker <- Tracker$new()

  for (seed in seeds) {

    if (!check(graph, seed))
      stop(
        paste("Seed", seed, "must be available and have positive out degree."),
        call. = FALSE
      )

    tracker$add_seed(graph, seed, preference = 1 / length(seeds))

    if (verbose)
      message(paste("Adding seed", seed, "to tracker."))
  }

  remaining <- seeds

  if (verbose)
    message(paste("There are", length(remaining), "remaining nodes."))

  while (length(remaining) > 0) {

    u <- if (length(remaining) == 1) remaining else sample(remaining, size = 1)

    if (verbose)
      message(paste("Updating p for node", u))

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

    if (verbose)
      message(paste("Sampling the neighborhood for node", u))

    neighbors <- neighborhood(graph, u)

    # first deal with the good neighbors we've already seen all
    # at once

    known_good <- neighbors[tracker$in_tracker(neighbors)]
    known_bad <- neighbors[tracker$in_failed(neighbors)]

    unknown <- setdiff(neighbors, c(known_good, known_bad))

    new_good <- check_batch(graph, unknown)
    new_bad <- setdiff(unknown, new_good)

    tracker$update_r_neighbor(graph, u, known_good, alpha_prime)
    tracker$update_r_neighbor(graph, u, new_good, alpha_prime)
    tracker$add_failed(new_bad)

    if (verbose)
      print(dplyr::arrange(tracker$stats, desc(r)))

    if (verbose)
      message(paste("Successfully dealt with neighborhood of", u))

    tracker$update_r_self(u, alpha_prime)

    if (verbose)
      message(paste("Successfully updated r for", u))

    remaining <- tracker$remaining(epsilon)

    if (verbose)
      message(paste("There are", length(remaining), "remaining nodes."))
  }

  ppr <- tracker$stats

  if (is.null(tau)) {
    tau <- mean(ppr$in_degree)  # TODO: in_degree or out_degree here?
  }

  ppr$degree_adjusted <- ppr$p / ppr$in_degree      # might divide by 0 here
  ppr$regularized <- ppr$p / (ppr$in_degree + tau)
  ppr
}

