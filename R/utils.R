# ---- Internal helpers: conditions, direction, groups ----

#' Raise a classed cooccure error.
#'
#' Every user-facing error inherits from `cooccure_error` plus one specific
#' class, so callers and tests can catch it by class rather than by message:
#' `cooccure_bad_input` (an argument or column is invalid),
#' `cooccure_incompatible_args` (two arguments cannot be combined),
#' `cooccure_empty_input` (no transaction or item survives),
#' `cooccure_grouped_input` (a split result needs a `group` to convert),
#' `cooccure_missing_package` (a suggested package is not installed).
#' @noRd
.co_abort <- function(..., class = "cooccure_bad_input") {
  stop(errorCondition(paste0(...), class = c(class, "cooccure_error"),
                      call = NULL))
}

#' Raise a classed cooccure warning.
#' @noRd
.co_warn <- function(..., class = "cooccure_warning") {
  warning(warningCondition(paste0(...), class = c(class, "cooccure_warning"),
                           call = NULL))
}

#' Require a suggested package or raise `cooccure_missing_package`.
#' @noRd
.co_need <- function(pkg, purpose = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    .co_abort(sprintf("Package '%s' is required%s. Install it with ",
                      pkg, if (is.null(purpose)) "" else paste0(" ", purpose)),
              sprintf("install.packages(\"%s\").", pkg),
              class = "cooccure_missing_package")
  }
  invisible(TRUE)
}

#' Is a cooccurrence result a directed network?
#'
#' Only `similarity = "relative"` is asymmetric (each row of the weight
#' matrix sums to 1), so its edges carry a direction. Results built before
#' the `directed` attribute existed fall back to the similarity name.
#' @noRd
.co_is_directed <- function(x) {
  d <- attr(x, "directed")
  if (!is.null(d)) return(isTRUE(d))
  identical(attr(x, "similarity"), "relative")
}

#' Is a cooccurrence result a stack of per-group networks (split_by)?
#' @noRd
.co_is_split <- function(x) "group" %in% names(x)

#' Reduce a cooccurrence result to one network before conversion.
#'
#' A `split_by` result stacks one network per group, so the same pair can
#' occur once per group with different weights. Converting the stack as a
#' single network either lets one group overwrite another (matrix) or builds
#' multi-edges (igraph). Converters therefore ask for one `group` and get a
#' proper single-network object back, with that group's items (isolates
#' included) and transaction count.
#' @noRd
.co_select_group <- function(x, group = NULL) {
  if (!.co_is_split(x)) {
    if (!is.null(group))
      .co_abort("`group` applies only to a result built with `split_by`; ",
                "this network was not split.", class = "cooccure_bad_input")
    return(x)
  }
  available <- attr(x, "groups") %||% unique(as.character(x$group))
  if (is.null(group)) {
    .co_abort("This result stacks ", length(available), " networks built ",
              "with `split_by`, so it cannot be converted as one network. ",
              "Pass `group =` naming one of: ",
              paste(utils::head(available, 10L), collapse = ", "),
              if (length(available) > 10L) ", ..." else "", ".",
              class = "cooccure_grouped_input")
  }
  if (!is.character(group) && !is.numeric(group) || length(group) != 1L)
    .co_abort("`group` must be a single group name.",
              class = "cooccure_bad_input")
  group <- as.character(group)
  if (!group %in% available)
    .co_abort("Group '", group, "' is not in this result. Available: ",
              paste(utils::head(available, 10L), collapse = ", "),
              if (length(available) > 10L) ", ..." else "", ".",
              class = "cooccure_bad_input")

  rows <- as.character(x$group) == group
  keep_cols <- setdiff(names(x), "group")
  out <- as.data.frame(x)[rows, keep_cols, drop = FALSE]
  rownames(out) <- NULL
  class(out) <- c("cooccurrence", "data.frame")
  for (a in c("similarity", "scale", "threshold", "min_occur", "counting",
              "lambda", "directed"))
    attr(out, a) <- attr(x, a)
  attr(out, "items") <- attr(x, "group_items")[[group]]
  attr(out, "frequencies") <- attr(x, "group_frequencies")[[group]]
  tx <- attr(x, "group_transactions")
  attr(out, "n_transactions") <- if (!is.null(tx)) unname(tx[[group]]) else NULL
  attr(out, "n_items") <- length(attr(out, "items"))
  attr(out, "group") <- group
  out
}

#' Check that named columns exist before any per-group work starts.
#'
#' Validating once on the whole frame means a misspelled `field` fails with
#' its own message instead of surfacing, group by group, as an empty network.
#' @noRd
.co_check_columns <- function(data, field, by, weight_by) {
  if (!is.data.frame(data)) return(invisible(NULL))
  cols <- c(if (!identical(field, "all")) field, by, weight_by)
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols))
    .co_abort("Column(s) not found in `data`: ",
              paste(missing_cols, collapse = ", "), ".",
              class = "cooccure_bad_input")
  invisible(NULL)
}
