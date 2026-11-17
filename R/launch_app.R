#' Open the interactive co-occurrence explorer
#'
#' @description
#' `launch_app()` opens an interactive co-occurrence explorer: a \pkg{shiny}
#' application in which a data set (the bundled [demo] table or an uploaded
#' file) is turned into a network with [cooccurrence()] and shown as a table
#' and a plot. The explorer is a quick way to see how the choice of items,
#' transactions, similarity measure and filters changes a co-occurrence
#' network before writing the analysis as code.
#'
#' It requires the \pkg{shiny} and \pkg{DT} packages and an interactive
#' session.
#'
#' @param ... Passed to \code{\link[shiny]{runApp}} (e.g. \code{port},
#'   \code{launch.browser}).
#' @return No return value; called to run the application, which blocks
#'   the session until it is closed.
#' @section Conditions:
#'   `cooccure_missing_package` when \pkg{shiny} or \pkg{DT} is not
#'   installed.
#' @seealso [cooccurrence()]; [demo].
#' @export
#' @examples
#' if (interactive()) {
#'   launch_app()
#' }
launch_app <- function(...) {
  # nocov start — interactive Shiny entrypoint, not reachable under batch test runs
  invisible(lapply(c("shiny", "DT"), .co_need, purpose = "for the explorer"))
  app_dir <- system.file("shiny", "cooccure_app", package = "cooccure")
  if (!nzchar(app_dir))
    .co_abort("Could not find the Shiny app directory. Re-install the ",
              "cooccure package.", class = "cooccure_bad_input")
  shiny::runApp(app_dir, ...)
  # nocov end
}
