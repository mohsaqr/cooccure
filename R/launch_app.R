#' Launch the cooccure Shiny explorer
#'
#' Opens an interactive Shiny application for building and exploring
#' co-occurrence networks. Requires the \pkg{shiny} and \pkg{DT} packages.
#'
#' @param ... Passed to \code{\link[shiny]{runApp}} (e.g. \code{port},
#'   \code{launch.browser}).
#' @return Called for its side effect (launches the app). No return value.
#' @export
#' @examples
#' if (interactive()) {
#'   launch_app()
#' }
launch_app <- function(...) {
  # nocov start — interactive Shiny entrypoint, not reachable under batch test runs
  for (pkg in c("shiny", "DT")) {
    if (!requireNamespace(pkg, quietly = TRUE))
      stop(sprintf("Package '%s' is required. Install it with: install.packages('%s')",
                   pkg, pkg), call. = FALSE)
  }
  app_dir <- system.file("shiny", "cooccure_app", package = "cooccure")
  if (!nzchar(app_dir))
    stop("Could not find the Shiny app directory. Re-install the cooccure package.",
         call. = FALSE)
  shiny::runApp(app_dir, ...)
  # nocov end
}
