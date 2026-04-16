# ---- Co-occurrence Network Construction ----

# TraMineR/tna void markers
.void_markers <- c("%", "*", "", "NA", "NaN")

#' Build a co-occurrence network
#'
#' Constructs an undirected co-occurrence network from various input formats
#' and returns a tidy edge data frame. Argument names follow the citenets
#' convention.
#'
#' @param data Input data. Accepts:
#'   \itemize{
#'     \item A \code{data.frame} with a delimited column (\code{field} + \code{sep}).
#'     \item A \code{data.frame} in long/bipartite format (\code{field} + \code{by}).
#'     \item A binary (0/1) \code{data.frame} or \code{matrix} (auto-detected).
#'     \item A wide sequence \code{data.frame} or \code{matrix} (non-binary).
#'     \item A \code{list} of character vectors (each element is a transaction).
#'   }
#' @param field Character. The entity column --- determines what the nodes are.
#'   For delimited format, a single column split by \code{sep}. For
#'   long/bipartite, the item column. For multi-column delimited, a vector
#'   of column names pooled per row.
#' @param by Character or \code{NULL}. Grouping column for long/bipartite
#'   format. Each unique value defines one transaction.
#' @param sep Character or \code{NULL}. Separator for splitting delimited
#'   fields.
#' @param similarity Character. Similarity measure:
#'   \describe{
#'     \item{\code{"none"}}{Raw co-occurrence counts.}
#'     \item{\code{"jaccard"}}{\eqn{C_{ij} / (f_i + f_j - C_{ij})}.}
#'     \item{\code{"cosine"}}{Salton's cosine:
#'       \eqn{C_{ij} / \sqrt{f_i \cdot f_j}}.}
#'     \item{\code{"inclusion"}}{Simpson coefficient:
#'       \eqn{C_{ij} / \min(f_i, f_j)}.}
#'     \item{\code{"association"}}{Association strength:
#'       \eqn{C_{ij} / (f_i \cdot f_j)}
#'       (van Eck & Waltman, 2009).}
#'     \item{\code{"dice"}}{\eqn{2 C_{ij} / (f_i + f_j)}.}
#'     \item{\code{"equivalence"}}{Salton's cosine squared:
#'       \eqn{C_{ij}^2 / (f_i \cdot f_j)}.}
#'     \item{\code{"relative"}}{Row-normalized: each row sums to 1.}
#'   }
#' @param scale Character or \code{NULL}. Optional scaling applied to weights
#'   after similarity normalization:
#'   \describe{
#'     \item{\code{NULL} or \code{"none"}}{No scaling.}
#'     \item{\code{"minmax"}}{Min-max to \eqn{[0, 1]}.}
#'     \item{\code{"log"}}{Natural log: \eqn{\log(1 + w)}.}
#'     \item{\code{"log10"}}{Log base 10: \eqn{\log_{10}(1 + w)}.}
#'     \item{\code{"binary"}}{Binary: 1 if \eqn{w > 0}, else 0.}
#'     \item{\code{"zscore"}}{Z-score standardization.}
#'     \item{\code{"sqrt"}}{Square root.}
#'     \item{\code{"proportion"}}{Divide by sum of all weights.}
#'   }
#' @param threshold Numeric. Minimum edge weight to retain. Applied after
#'   similarity and scaling. Default 0.
#' @param min_occur Integer. Minimum entity frequency. Entities appearing in
#'   fewer than \code{min_occur} transactions are dropped. Default 1.
#' @param top_n Integer or \code{NULL}. Keep only the top \code{top_n} edges
#'   by weight. Default \code{NULL} (all edges).
#' @param ... Currently unused.
#'
#' @return A \code{cooccurrence} data frame (inherits from \code{data.frame})
#'   with columns:
#'   \describe{
#'     \item{\code{from}}{Character. First entity.}
#'     \item{\code{to}}{Character. Second entity.}
#'     \item{\code{weight}}{Numeric. Similarity-normalized (and optionally
#'       scaled) co-occurrence value.}
#'     \item{\code{count}}{Integer. Raw co-occurrence count.}
#'   }
#'   Sorted by \code{weight} descending. Attributes store the full matrix,
#'   item frequencies, similarity method, and scaling.
#'
#' @references
#' van Eck, N. J., & Waltman, L. (2009). How to normalize co-occurrence
#' data? An analysis of some well-known similarity measures. \emph{Journal of
#' the American Society for Information Science and Technology}, 60(8),
#' 1635--1651.
#'
#' @examples
#' # Delimited keywords
#' df <- data.frame(
#'   id = 1:4,
#'   keywords = c("network; graph", "graph; matrix; network",
#'                "matrix; algebra", "network; algebra; graph")
#' )
#' cooccurrence(df, field = "keywords", sep = ";")
#'
#' # List of transactions with Jaccard similarity
#' cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")),
#'              similarity = "jaccard")
#'
#' # Short alias
#' co(df, field = "keywords", sep = ";", similarity = "cosine")
#'
#' @export
cooccurrence <- function(data, field = NULL, by = NULL, sep = NULL,
                         similarity = c("none", "jaccard", "cosine",
                                        "inclusion", "association",
                                        "dice", "equivalence", "relative"),
                         scale = NULL,
                         threshold = 0, min_occur = 1L,
                         top_n = NULL, ...) {
  similarity <- match.arg(similarity)
  threshold <- as.numeric(threshold)
  min_occur <- as.integer(min_occur)
  stopifnot(threshold >= 0, min_occur >= 1L)

  if (is.null(scale) || identical(scale, "none")) {
    scale_method <- "none"
  } else {
    scale_method <- match.arg(scale, c("none", "minmax", "log", "log10",
                                       "binary", "zscore", "sqrt",
                                       "proportion"))
  }

  # Parse input → list of character vectors (transactions)
  fmt <- .co_detect_format(data, field, by, sep)
  transactions <- switch(fmt,
    delimited       = .co_parse_delimited(data, field, sep),
    multi_delimited = .co_parse_multi_delimited(data, field, sep),
    long            = .co_parse_long(data, field, by),
    binary          = .co_parse_binary(data),
    wide            = .co_parse_wide(data),
    list            = .co_parse_list(data)
  )

  # Drop empty transactions
  transactions <- transactions[vapply(transactions, length, integer(1)) > 0L]
  if (length(transactions) == 0L)
    stop("No non-empty transactions found in the input data.", call. = FALSE)

  # min_occur filter
  if (min_occur > 1L) {
    freq_table <- table(unlist(transactions))
    keep <- names(freq_table[freq_table >= min_occur])
    transactions <- lapply(transactions, function(t) t[t %in% keep])
    transactions <- transactions[vapply(transactions, length, integer(1)) > 0L]
    if (length(transactions) == 0L)
      stop("No transactions remain after min_occur filtering.", call. = FALSE)
  }

  # Build binary transaction matrix → co-occurrence
  B <- .co_transactions_to_matrix(transactions)
  C <- .co_compute_matrix(B)
  n_trans <- nrow(B)

  # Item frequencies
  freq <- diag(C)

  # Zero diagonal (edges are between distinct items)
  diag(C) <- 0

  # Normalize
  W <- .co_normalize(C, freq, similarity)

  # Scale
  if (scale_method != "none") {
    W <- .co_scale(W, scale_method)
  }

  # Threshold
  if (threshold > 0) W[W < threshold] <- 0

  # Extract upper triangle → tidy edge list
  edges <- .co_matrix_to_edges(W, C)

  # Sort by weight descending
  edges <- edges[order(-edges$weight), ]

  # top_n
  if (!is.null(top_n)) {
    stopifnot(is.numeric(top_n), top_n > 0)
    top_n <- as.integer(top_n)
    if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
  }

  rownames(edges) <- NULL

  # Stamp class + metadata as attributes
  class(edges) <- c("cooccurrence", "data.frame")
  attr(edges, "matrix") <- W
  attr(edges, "raw_matrix") <- C
  attr(edges, "items") <- colnames(W)
  attr(edges, "frequencies") <- freq
  attr(edges, "similarity") <- similarity
  attr(edges, "scale") <- scale_method
  attr(edges, "threshold") <- threshold
  attr(edges, "min_occur") <- min_occur
  attr(edges, "n_transactions") <- n_trans
  attr(edges, "n_items") <- ncol(B)

  edges
}


#' @rdname cooccurrence
#' @export
co <- cooccurrence


# ---- Extract edges from matrix ----

#' Convert upper triangle of a matrix to an edge data.frame
#' @param W Normalized weight matrix (diagonal = 0).
#' @param C Raw count matrix (diagonal = 0).
#' @return data.frame with from, to, weight, count.
#' @noRd
.co_matrix_to_edges <- function(W, C) {
  idx <- which(upper.tri(W) & W != 0, arr.ind = TRUE)
  if (nrow(idx) == 0L) {
    return(data.frame(from = character(0), to = character(0),
                      weight = numeric(0), count = integer(0),
                      stringsAsFactors = FALSE))
  }
  nms <- rownames(W)
  data.frame(
    from = nms[idx[, 1]],
    to = nms[idx[, 2]],
    weight = W[idx],
    count = as.integer(C[idx]),
    stringsAsFactors = FALSE
  )
}


# ---- Scaling ----

#' Scale edge weights
#' @noRd
.co_scale <- function(W, method) {
  vals <- W[W != 0]
  if (length(vals) == 0L) return(W)

  switch(method,
    minmax = {
      mn <- min(vals); mx <- max(vals)
      if (mx > mn) {
        W[W != 0] <- (W[W != 0] - mn) / (mx - mn)
      } else {
        W[W != 0] <- 1
      }
      W
    },
    log = {
      W[W != 0] <- log(1 + W[W != 0])
      W
    },
    log10 = {
      W[W != 0] <- log10(1 + W[W != 0])
      W
    },
    binary = {
      W[W != 0] <- 1
      W
    },
    zscore = {
      mu <- mean(vals); s <- stats::sd(vals)
      if (s > 0) W[W != 0] <- (W[W != 0] - mu) / s
      W
    },
    sqrt = {
      W[W != 0] <- sqrt(W[W != 0])
      W
    },
    proportion = {
      s <- sum(vals)
      if (s > 0) W[W != 0] <- W[W != 0] / s
      W
    }
  )
}


# ---- Format detection ----

#' @noRd
.co_detect_format <- function(data, field, by, sep) {
  if (is.list(data) && !is.data.frame(data) && !is.matrix(data))
    return("list")

  if (!is.null(sep) && !is.null(field) && length(field) > 1L)
    return("multi_delimited")

  if (!is.null(sep) && !is.null(field))
    return("delimited")

  if (!is.null(field) && !is.null(by))
    return("long")

  if (is.matrix(data) || is.data.frame(data)) {
    mat <- if (is.data.frame(data)) as.matrix(data) else data
    if (is.numeric(mat) && all(mat[!is.na(mat)] %in% c(0, 1)))
      return("binary")
    return("wide")
  }

  stop("Cannot detect input format. Provide field/by/sep arguments or a ",
       "recognized data structure (data.frame, matrix, list).", call. = FALSE)
}


# ---- Parsers ----

#' @noRd
.co_parse_delimited <- function(data, field, sep) {
  stopifnot(is.data.frame(data), length(field) == 1L, field %in% names(data))
  vals <- as.character(data[[field]])
  lapply(strsplit(vals, sep, fixed = TRUE), function(items) {
    items <- trimws(items)
    items <- items[nzchar(items) & !is.na(items)]
    unique(items)
  })
}

#' @noRd
.co_parse_multi_delimited <- function(data, field, sep) {
  stopifnot(is.data.frame(data), all(field %in% names(data)))
  n <- nrow(data)
  lapply(seq_len(n), function(i) {
    items <- unlist(lapply(field, function(f) {
      strsplit(as.character(data[[f]][i]), sep, fixed = TRUE)[[1L]]
    }))
    items <- trimws(items)
    items <- items[nzchar(items) & !is.na(items)]
    unique(items)
  })
}

#' @noRd
.co_parse_long <- function(data, field, by) {
  stopifnot(is.data.frame(data), field %in% names(data), by %in% names(data))
  groups <- split(as.character(data[[field]]), data[[by]])
  lapply(groups, function(items) {
    items <- items[nzchar(items) & !is.na(items)]
    unique(items)
  })
}

#' @noRd
.co_parse_binary <- function(data) {
  mat <- if (is.data.frame(data)) as.matrix(data) else data
  if (is.null(colnames(mat)))
    colnames(mat) <- paste0("V", seq_len(ncol(mat)))
  cn <- colnames(mat)
  lapply(seq_len(nrow(mat)), function(i) cn[mat[i, ] == 1])
}

#' @noRd
.co_parse_wide <- function(data) {
  mat <- if (is.data.frame(data)) as.matrix(data) else data
  lapply(seq_len(nrow(mat)), function(i) {
    vals <- as.character(mat[i, ])
    vals <- vals[!is.na(vals) & nzchar(vals) & !(vals %in% .void_markers)]
    unique(vals)
  })
}

#' @noRd
.co_parse_list <- function(data) {
  lapply(data, function(items) {
    items <- as.character(items)
    items <- items[!is.na(items) & nzchar(items)]
    unique(items)
  })
}


# ---- Core computation ----

#' @noRd
.co_transactions_to_matrix <- function(transactions) {
  all_items <- sort(unique(unlist(transactions)))
  n <- length(transactions)
  k <- length(all_items)
  B <- matrix(FALSE, nrow = n, ncol = k,
              dimnames = list(NULL, all_items))
  for (i in seq_len(n)) {
    B[i, transactions[[i]]] <- TRUE
  }
  B
}

#' @noRd
.co_compute_matrix <- function(B) {
  C <- as.matrix(crossprod(B * 1L))
  storage.mode(C) <- "double"
  C
}

#' @noRd
.co_normalize <- function(C, freq, method) {
  if (method == "none") return(C)

  W <- C

  if (method == "jaccard") {
    denom <- outer(freq, freq, "+") - C
    denom[denom == 0] <- 1
    W <- C / denom
  } else if (method == "cosine") {
    denom <- outer(sqrt(freq), sqrt(freq), "*")
    denom[denom == 0] <- 1
    W <- C / denom
  } else if (method == "inclusion") {
    denom <- outer(freq, freq, pmin)
    denom[denom == 0] <- 1
    W <- C / denom
  } else if (method == "association") {
    denom <- outer(freq, freq, "*")
    denom[denom == 0] <- 1
    W <- C / denom
  } else if (method == "dice") {
    denom <- outer(freq, freq, "+")
    denom[denom == 0] <- 1
    W <- 2 * C / denom
  } else if (method == "equivalence") {
    denom <- outer(freq, freq, "*")
    denom[denom == 0] <- 1
    W <- C^2 / denom
  } else if (method == "relative") {
    rs <- rowSums(C)
    rs[rs == 0] <- 1
    W <- C / rs
  }

  W
}
