#' @keywords internal
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
## usethis namespace: end
NULL

#' @import logger
#' @importFrom glue glue
NULL

#' @import pander
.onLoad <- function(libname, pkgname) {
  log_formatter(formatter_pander, namespace = pkgname)
}
