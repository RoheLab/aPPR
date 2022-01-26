#' Update a Tracker object
#'
#' Typically because results are insufficiently precise.
#'
#' At the moment, only supports changing `epsilon`. If there is interest,
#' we can consider allowing updates to `tau`, `alpha` and `seeds` in the
#' future.
#'
#' @param object The `Tracker` object to update.
#'
#' @inheritParams appr
#'
#' @return A new `Tracker` object with a new value of `epsilon`.
#' @export
#'
update.Tracker <- function(object, ..., epsilon, verbose = TRUE) {

  object$epsilon <- epsilon
  object$calculate_ppr(verbose)
  object$regularize()
  object
}
