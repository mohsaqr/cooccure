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
#' @param weight_by Character or \code{NULL}. Column name containing a numeric
#'   association strength for each entity-transaction pair. Only accepted for
#'   long format (\code{field} + \code{by}). When supplied, each entity
#'   contributes its weight rather than 1, so
#'   \eqn{C_{ij} = \sum_d w_{id} \cdot w_{jd}}.
#'   Typical use: topic-document probability matrices from LDA or similar
#'   models.
#' @param sep Character or \code{NULL}. Separator for splitting delimited
#'   fields.
#' @param split_by Character or \code{NULL}. Column name to split the data
#'   by before computing co-occurrence. A separate network is computed per
#'   group and the results are combined into a single data frame with an
#'   additional \code{group} column. Only works with data.frame inputs.
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
#' @param counting Character. Counting method:
#'   \describe{
#'     \item{\code{"full"}}{Each co-occurring pair adds 1 regardless of
#'       transaction size. Default.}
#'     \item{\code{"fractional"}}{Each pair adds \eqn{1 / (n_i - 1)}
#'       where \eqn{n_i} is the number of items in transaction \eqn{i}.
#'       Transactions with many items contribute less per pair
#'       (Perianes-Rodriguez et al., 2016).}
#'   }
#' @param threshold Numeric. Minimum edge weight to retain. Applied after
#'   similarity and scaling. Default 0.
#' @param min_occur Integer. Minimum entity frequency. Entities appearing in
#'   fewer than \code{min_occur} transactions are dropped. Default 1.
#' @param top_n Integer or \code{NULL}. Keep only the top \code{top_n} edges
#'   by weight. When \code{split_by} is used, applied per group.
#'   Default \code{NULL} (all edges).
#' @param output Character. Column naming convention for the output:
#'   \describe{
#'     \item{\code{"default"}}{\code{from}, \code{to}, \code{weight}, \code{count}.}
#'     \item{\code{"gephi"}}{\code{Source}, \code{Target}, \code{Weight},
#'       \code{Type} (= \code{"Undirected"}). Ready for Gephi import.}
#'     \item{\code{"igraph"}}{Returns an \code{igraph} graph object directly.}
#'     \item{\code{"cograph"}}{Returns a \code{cograph_network} object directly.}
#'     \item{\code{"matrix"}}{Returns the square co-occurrence matrix.}
#'   }
#' @param ... Currently unused.
#'
#' @return Depends on \code{output}:
#'   \itemize{
#'     \item \code{"default"}: A \code{cooccurrence} data frame with columns
#'       \code{from}, \code{to}, \code{weight}, \code{count} (and \code{group}
#'       when \code{split_by} is used).
#'     \item \code{"gephi"}: A data frame with columns \code{Source},
#'       \code{Target}, \code{Weight}, \code{Type}, \code{Count}. Ready for
#'       Gephi CSV import.
#'     \item \code{"igraph"}: An \code{igraph} graph object.
#'     \item \code{"cograph"}: A \code{cograph_network} object.
#'     \item \code{"matrix"}: A square numeric co-occurrence matrix.
#'   }
#'   For the data frame outputs, rows are sorted by weight descending and
#'   attributes store the full matrix, item frequencies, and parameters.
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
#' # Split by a grouping variable
#' df$year <- c(2020, 2020, 2021, 2021)
#' cooccurrence(df, field = "keywords", sep = ";", split_by = "year")
#'
#' # List of transactions with Jaccard similarity
#' cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")),
#'              similarity = "jaccard")
#'
#' # Short alias
#' co(df, field = "keywords", sep = ";", similarity = "cosine")
#'
#' # Weighted long format (e.g. LDA topic-document probabilities)
#' theta <- data.frame(
#'   doc   = c("d1","d1","d1","d2","d2","d3","d3"),
#'   topic = c("T1","T2","T3","T1","T3","T2","T3"),
#'   prob  = c(0.6, 0.3, 0.1, 0.4, 0.6, 0.5, 0.5)
#' )
#' cooccurrence(theta, field = "topic", by = "doc", weight_by = "prob")
#'
#' @export
cooccurrence <- function(data, field = NULL, by = NULL, sep = NULL,
                         weight_by = NULL,
                         split_by = NULL,
                         similarity = c("none", "jaccard", "cosine",
                                        "inclusion", "association",
                                        "dice", "equivalence", "relative"),
                         counting = c("full", "fractional"),
                         scale = NULL,
                         threshold = 0, min_occur = 1L,
                         top_n = NULL,
                         output = c("default", "gephi", "igraph",
                                    "cograph", "matrix"), ...) {
  similarity <- match.arg(similarity)
  counting <- match.arg(counting)
  output <- match.arg(output)
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

  # ---- split_by: compute per group, combine ----
  if (!is.null(split_by)) {
    stopifnot(is.data.frame(data), split_by %in% names(data))
    groups <- split(data, data[[split_by]])
    parts <- lapply(names(groups), function(g) {
      sub <- groups[[g]]
      # Drop the split_by column so it doesn't interfere with format detection
      sub[[split_by]] <- NULL
      edges <- tryCatch(
        .co_core(sub, field = field, by = by, sep = sep,
                 weight_by = weight_by,
                 similarity = similarity, counting = counting,
                 scale_method = scale_method,
                 threshold = threshold, min_occur = min_occur,
                 top_n = top_n),
        error = function(e) NULL
      )
      if (is.null(edges) || nrow(edges) == 0L) return(NULL)
      edges$group <- g
      edges
    })
    parts <- parts[!vapply(parts, is.null, logical(1))]
    if (length(parts) == 0L)
      stop("No groups produced any edges.", call. = FALSE)
    edges <- do.call(rbind, parts)
    rownames(edges) <- NULL

    class(edges) <- c("cooccurrence", "data.frame")
    attr(edges, "similarity") <- similarity
    attr(edges, "scale") <- scale_method
    attr(edges, "threshold") <- threshold
    attr(edges, "min_occur") <- min_occur
    attr(edges, "split_by") <- split_by
    attr(edges, "groups") <- names(groups)
    return(.co_format_output(edges, output))
  }

  # ---- Single-group path ----
  result <- .co_core(data, field = field, by = by, sep = sep,
                     weight_by = weight_by,
                     similarity = similarity, counting = counting,
                     scale_method = scale_method,
                     threshold = threshold, min_occur = min_occur,
                     top_n = top_n)

  .co_format_output(result, output)
}


#' @rdname cooccurrence
#' @export
co <- cooccurrence


# ---- Core pipeline (used by both single and split_by paths) ----

#' @noRd
.co_core <- function(data, field, by, sep, weight_by = NULL, similarity,
                     counting, scale_method, threshold, min_occur, top_n) {
  # Parse input
  fmt <- .co_detect_format(data, field, by, sep)

  # Weighted path — long format only
  if (!is.null(weight_by)) {
    if (fmt != "long")
      stop("`weight_by` is only supported for long format (field + by).",
           call. = FALSE)
    return(.co_core_weighted(data, field, by, weight_by, similarity,
                             scale_method, threshold, min_occur, top_n))
  }

  if (fmt == "field_only")
    .co_warn_missing_sep(data, field)

  transactions <- switch(fmt,
    delimited       = .co_parse_delimited(data, field, sep),
    multi_delimited = .co_parse_multi_delimited(data, field, sep),
    field_only      = .co_parse_field_only(data, field),
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

  # Build binary transaction matrix
  B <- .co_transactions_to_matrix(transactions)
  n_trans <- nrow(B)

  # Apply counting method (weights rows of B before crossprod)
  B_weighted <- .co_apply_counting(B, counting)

  # Co-occurrence matrices
  C <- .co_compute_matrix(B_weighted)        # counting-weighted
  C_raw <- .co_compute_matrix(B)             # always full (for count column)

  # Item frequencies (always from the binary matrix, not weighted)
  freq <- colSums(B)

  # Zero diagonals
  diag(C) <- 0
  diag(C_raw) <- 0

  # Normalize
  W <- .co_normalize(C, freq, similarity)

  # Scale
  if (scale_method != "none") W <- .co_scale(W, scale_method)

  # Threshold
  if (threshold > 0) W[W < threshold] <- 0

  # Extract upper triangle -> tidy edge list
  edges <- .co_matrix_to_edges(W, C_raw)

  # Sort by weight descending
  edges <- edges[order(-edges$weight), ]

  # top_n
  if (!is.null(top_n)) {
    stopifnot(is.numeric(top_n), top_n > 0)
    top_n <- as.integer(top_n)
    if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
  }

  rownames(edges) <- NULL

  # Stamp class + metadata
  class(edges) <- c("cooccurrence", "data.frame")
  attr(edges, "matrix") <- W
  attr(edges, "raw_matrix") <- C_raw
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


# ---- Weighted core (long format with per-entity weights) ----

#' @noRd
.co_core_weighted <- function(data, field, by, weight_by, similarity,
                               scale_method, threshold, min_occur, top_n) {
  stopifnot(
    is.data.frame(data),
    field %in% names(data), by %in% names(data), weight_by %in% names(data)
  )

  # Build weighted matrix W: rows = transactions, cols = items
  W <- tapply(as.numeric(data[[weight_by]]),
              list(as.character(data[[by]]), as.character(data[[field]])),
              FUN = sum)
  W[is.na(W)] <- 0
  storage.mode(W) <- "double"

  # min_occur: filter by number of transactions with non-zero weight
  if (min_occur > 1L) {
    n_docs <- colSums(W > 0)
    keep <- colnames(W)[n_docs >= min_occur]
    W <- W[, keep, drop = FALSE]
  }

  if (ncol(W) == 0L)
    stop("No items remain after min_occur filtering.", call. = FALSE)

  n_trans <- nrow(W)

  # Frequencies: total weight per item across all transactions
  freq <- colSums(W)

  # Raw counts: number of transactions containing both items (binary)
  B <- (W > 0) * 1L
  C_raw <- as.matrix(crossprod(B))
  storage.mode(C_raw) <- "double"
  diag(C_raw) <- 0

  # Weighted co-occurrence: sum of products of weights
  C <- as.matrix(crossprod(W))
  storage.mode(C) <- "double"
  diag(C) <- 0

  # Normalize, scale, threshold, edges — identical to standard path
  Wmat <- .co_normalize(C, freq, similarity)
  if (scale_method != "none") Wmat <- .co_scale(Wmat, scale_method)
  if (threshold > 0) Wmat[Wmat < threshold] <- 0

  edges <- .co_matrix_to_edges(Wmat, C_raw)
  edges <- edges[order(-edges$weight), ]

  if (!is.null(top_n)) {
    top_n <- as.integer(top_n)
    if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
  }

  rownames(edges) <- NULL
  class(edges) <- c("cooccurrence", "data.frame")
  attr(edges, "matrix")        <- Wmat
  attr(edges, "raw_matrix")    <- C_raw
  attr(edges, "items")         <- colnames(Wmat)
  attr(edges, "frequencies")   <- freq
  attr(edges, "similarity")    <- similarity
  attr(edges, "scale")         <- scale_method
  attr(edges, "threshold")     <- threshold
  attr(edges, "min_occur")     <- min_occur
  attr(edges, "n_transactions")<- n_trans
  attr(edges, "n_items")       <- ncol(W)

  edges
}


# ---- Extract edges from matrix ----

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

  if (!is.null(field) && is.null(sep) && is.null(by) && is.data.frame(data))
    return("field_only")

  if (is.matrix(data) || is.data.frame(data)) {
    mat <- if (is.data.frame(data)) as.matrix(data) else data
    if (is.numeric(mat) && all(mat[!is.na(mat)] %in% c(0, 1)))
      return("binary")
    return("wide")
  }

  stop("Cannot detect input format. Provide field/by/sep arguments or a ",
       "recognized data structure (data.frame, matrix, list).", call. = FALSE)
}


#' @noRd
.co_warn_missing_sep <- function(data, field) {
  candidates <- c(";", ",", "|", "/", "\t")
  vals <- unlist(lapply(field, function(f) as.character(data[[f]])))
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0L) return(invisible())

  counts <- vapply(candidates, function(s) sum(grepl(s, vals, fixed = TRUE)),
                   integer(1))
  best <- which.max(counts)

  if (counts[best] > 0L) {
    sep_label <- if (candidates[best] == "\t") "\\t" else candidates[best]
    pct <- round(100 * counts[best] / length(vals))
    warning(
      "`field` was provided without `sep`. Each value is treated as a single item. ",
      sprintf(
        "Found '%s' in %d%% of values. Did you mean: sep = \"%s\"?",
        sep_label, pct, sep_label
      ),
      call. = FALSE
    )
  } else {
    warning(
      "`field` was provided without `sep`. Each value is treated as a single item.",
      call. = FALSE
    )
  }
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
.co_parse_field_only <- function(data, field) {
  stopifnot(is.data.frame(data), all(field %in% names(data)))
  lapply(seq_len(nrow(data)), function(i) {
    vals <- as.character(unlist(data[i, field, drop = TRUE]))
    vals <- trimws(vals)
    vals <- vals[!is.na(vals) & nzchar(vals)]
    unique(vals)
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


# ---- Counting ----

#' Apply counting weights to the binary transaction matrix
#' @param B Logical matrix (rows = transactions, cols = items).
#' @param counting "full", "fractional", or "paper".
#' @return Numeric matrix with row weights applied.
#' @noRd
.co_apply_counting <- function(B, counting) {
  if (counting == "full") return(B)

  n_per_row <- rowSums(B)
  n_per_row[n_per_row == 0] <- 1

  # Perianes-Rodriguez: each pair contributes 1/(n-1) per transaction
  w <- ifelse(n_per_row > 1, 1 / (n_per_row - 1), 1)

  # Multiply each row by sqrt(w) so crossprod gives weighted counts
  B_num <- B * 1.0
  B_num * sqrt(w)
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


# ---- Output format conversion ----

#' @noRd
.co_format_output <- function(result, output) {
  if (output == "default") return(result)

  if (output == "gephi") {
    out <- result
    has_group <- "group" %in% names(out)
    names(out)[names(out) == "from"] <- "Source"
    names(out)[names(out) == "to"] <- "Target"
    names(out)[names(out) == "weight"] <- "Weight"
    names(out)[names(out) == "count"] <- "Count"
    out$Type <- "Undirected"
    # Reorder: Source, Target, Weight, Type, Count, [group]
    cols <- c("Source", "Target", "Weight", "Type", "Count")
    if (has_group) cols <- c(cols, "group")
    out <- out[, cols]
    class(out) <- c("cooccurrence", "data.frame")
    # Copy attributes
    for (a in c("matrix", "raw_matrix", "items", "frequencies",
                "similarity", "scale", "threshold", "min_occur",
                "n_transactions", "n_items", "split_by", "groups")) {
      attr(out, a) <- attr(result, a)
    }
    return(out)
  }

  if (output == "igraph") return(as_igraph(result))
  if (output == "cograph") return(as_cograph(result))
  if (output == "matrix") return(as_matrix(result))

  result
}
