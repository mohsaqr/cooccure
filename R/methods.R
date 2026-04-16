# ---- S3 methods for cooccurrence ----

#' Print a cooccurrence edge list
#'
#' @param x A \code{cooccurrence} data frame.
#' @param n Integer. Number of rows to show. Default 10.
#' @param ... Ignored.
#' @return Invisibly returns \code{x}.
#' @export
print.cooccurrence <- function(x, n = 10L, ...) {
  nodes <- length(unique(c(x$from, x$to)))
  edges <- nrow(x)
  sim <- attr(x, "similarity")
  sc <- attr(x, "scale")
  n_trans <- attr(x, "n_transactions")

  cat(sprintf("# cooccurrence: %d nodes, %d edges", nodes, edges))
  if (!is.null(n_trans)) cat(sprintf(" (%d transactions)", n_trans))
  if (!is.null(sim) && sim != "none") cat(sprintf(" | similarity: %s", sim))
  if (!is.null(sc) && sc != "none") cat(sprintf(" | scale: %s", sc))
  cat("\n")

  show <- min(n, edges)
  if (show > 0L) {
    print(as.data.frame(x)[seq_len(show), ], row.names = FALSE)
    if (edges > show)
      cat(sprintf("# ... %d more edges\n", edges - show))
  } else {
    cat("# (no edges)\n")
  }
  invisible(x)
}


#' Summarise a cooccurrence network
#'
#' @param object A \code{cooccurrence} data frame.
#' @param ... Ignored.
#' @return Invisibly returns \code{object}.
#' @export
summary.cooccurrence <- function(object, ...) {
  nodes <- unique(c(object$from, object$to))
  n_nodes <- length(nodes)
  n_edges <- nrow(object)
  max_possible <- n_nodes * (n_nodes - 1L) / 2L
  density <- if (max_possible > 0) n_edges / max_possible else NA_real_

  cat("cooccurrence network\n")
  cat(rep("-", 30), "\n", sep = "")
  cat(sprintf("Nodes          : %d\n", n_nodes))
  cat(sprintf("Edges          : %d\n", n_edges))
  cat(sprintf("Density        : %.4f\n", density))
  cat(sprintf("Transactions   : %d\n", attr(object, "n_transactions")))
  cat(sprintf("Similarity     : %s\n", attr(object, "similarity")))

  sc <- attr(object, "scale")
  if (!is.null(sc) && sc != "none")
    cat(sprintf("Scale          : %s\n", sc))

  if (n_edges > 0L) {
    cat(sprintf("Weight range   : [%.4g, %.4g]\n",
                min(object$weight), max(object$weight)))
    cat(sprintf("Count range    : [%d, %d]\n",
                min(object$count), max(object$count)))

    # Top 5 nodes by degree
    deg <- sort(table(c(object$from, object$to)), decreasing = TRUE)
    top <- utils::head(deg, 5L)
    cat(sprintf("Top nodes      : %s\n",
                paste(sprintf("%s(%d)", names(top), as.integer(top)),
                      collapse = ", ")))
  }

  invisible(object)
}


#' Plot a cooccurrence network
#'
#' Plots the co-occurrence matrix as a heatmap. If \pkg{igraph} is available,
#' plots a network graph instead.
#'
#' @param x A \code{cooccurrence} data frame.
#' @param type Character. \code{"heatmap"} (default) or \code{"network"}
#'   (requires \pkg{igraph}).
#' @param ... Passed to the plotting function.
#' @return Invisibly returns \code{x}.
#' @export
plot.cooccurrence <- function(x, type = c("heatmap", "network"), ...) {
  type <- match.arg(type)

  if (type == "network") {
    if (!requireNamespace("igraph", quietly = TRUE))
      stop("Package 'igraph' is required for network plots.", call. = FALSE)
    g <- as_igraph(x)
    plot(g, ...)
  } else {
    mat <- attr(x, "matrix")
    if (is.null(mat)) {
      mat <- as_matrix(x)
    }
    n <- nrow(mat)
    graphics::image(
      seq_len(n), seq_len(n), t(mat[n:1, ]),
      xlab = "", ylab = "", axes = FALSE, ...
    )
    graphics::axis(1, at = seq_len(n), labels = colnames(mat),
                   las = 2, cex.axis = 0.7)
    graphics::axis(2, at = seq_len(n), labels = rev(rownames(mat)),
                   las = 2, cex.axis = 0.7)
  }

  invisible(x)
}
