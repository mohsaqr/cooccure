#' Launch the cooccur Shiny explorer
#'
#' Opens an interactive Shiny application for building and exploring
#' co-occurrence networks. Requires the \pkg{shiny}, \pkg{DT}, and
#' \pkg{visNetwork} packages.
#'
#' @param ... Passed to \code{\link[shiny]{runApp}} (e.g. \code{port},
#'   \code{launch.browser}).
#' @return Called for its side effect (launches the app).
#' @export
#' @examples
#' \dontrun{
#' launch_app()
#' }
launch_app <- function(...) {
  for (pkg in c("shiny", "DT", "visNetwork")) {
    if (!requireNamespace(pkg, quietly = TRUE))
      stop(sprintf("Package '%s' is required. Install it with: install.packages('%s')",
                   pkg, pkg), call. = FALSE)
  }
  app_dir <- system.file("shiny", "cooccur_app", package = "cooccur")
  if (!nzchar(app_dir))
    stop("Could not find the Shiny app directory. Re-install the cooccur package.",
         call. = FALSE)
  shiny::runApp(app_dir, ...)
}
