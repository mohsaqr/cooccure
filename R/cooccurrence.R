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
#'   of column names pooled per row. Use \code{field = "all"} for wide
#'   sequence data (e.g. TraMineR / tna format) where every column is a
#'   time point and cell values are the items.
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

  # Build sparse bipartite matrix (works x items) with counting weights baked in
  sp <- .co_build_sparse(transactions, counting)
  n_trans <- sp$n
  n_items <- sp$k
  items <- sp$items

  # Counting-weighted co-occurrence (sparse k x k)
  C <- Matrix::crossprod(sp$B)
  # Raw binary co-occurrence (sparse k x k) for the count column and frequencies
  C_raw <- Matrix::crossprod(sp$B_bin)
  freq <- as.numeric(Matrix::colSums(sp$B_bin))
  names(freq) <- items

  # Zero diagonals (self co-occurrence is not an edge)
  Matrix::diag(C) <- 0
  Matrix::diag(C_raw) <- 0
  C <- Matrix::drop0(C)
  C_raw <- Matrix::drop0(C_raw)

  .co_finalize(C, C_raw, freq, n_trans, n_items, items,
               similarity, scale_method, threshold, min_occur, top_n)
}


# ---- Shared finalization: normalize -> scale -> threshold -> edges -> stamp ----

#' Finalize edges from sparse co-occurrence matrices.
#'
#' Operates on triplets throughout — never materialises a dense k x k matrix.
#' For symmetric similarities, the attribute `matrix` is stored as a symmetric
#' sparse `dsCMatrix`; for `similarity = "relative"` it is a general
#' `dgCMatrix` holding both triangles.
#'
#' @param C Sparse counting-weighted co-occurrence matrix (k x k, diag = 0).
#' @param C_raw Sparse raw (binary) co-occurrence matrix (k x k, diag = 0).
#' @param freq Named numeric vector of item frequencies.
#' @param items Character vector of item names (k).
#' @noRd
.co_finalize <- function(C, C_raw, freq, n_trans, n_items, items,
                         similarity, scale_method, threshold, min_occur, top_n) {
  ## Upper-triangle triplets of C (counting-weighted) — these carry x values.
  C_upper_T <- methods::as(Matrix::triu(C, k = 1L), "TsparseMatrix")
  i <- C_upper_T@i + 1L
  j <- C_upper_T@j + 1L
  c_vals <- C_upper_T@x

  if (length(i) == 0L) {
    edges <- data.frame(from = character(0), to = character(0),
                        weight = numeric(0), count = integer(0),
                        stringsAsFactors = FALSE)
    W_sparse <- Matrix::sparseMatrix(
      i = integer(0), j = integer(0), x = numeric(0),
      dims = c(n_items, n_items), symmetric = TRUE,
      dimnames = list(items, items)
    )
  } else {
    ## Raw counts at the same positions. Non-zero pattern of C and C_raw is
    ## identical (both are crossprods of binaries with the same support), so
    ## [cbind(i, j)] indexing returns counts aligned with c_vals.
    raw_vals <- as.integer(C_raw[cbind(i, j)])

    ## Similarity normalisation on triplets.
    if (similarity == "none") {
      W_x <- c_vals
      W_sparse <- Matrix::sparseMatrix(
        i = i, j = j, x = W_x,
        dims = c(n_items, n_items), symmetric = TRUE,
        dimnames = list(items, items)
      )
    } else if (similarity == "relative") {
      ## Asymmetric: W[i,j] = C[i,j] / rowSums(C)[i]. Needs both triangles.
      ## C is a symmetric dsCMatrix whose TsparseMatrix form stores only the
      ## upper triangle, so we mirror (i, j, c_vals) to build the full matrix
      ## explicitly rather than relying on the symmetric packing.
      rs <- as.numeric(Matrix::rowSums(C))
      rs[rs == 0] <- 1
      W_x <- c_vals / rs[i]

      ii <- c(i, j)
      jj <- c(j, i)
      xx <- c(c_vals, c_vals)
      W_full_x <- xx / rs[ii]
    } else {
      denom <- switch(similarity,
        jaccard     = freq[i] + freq[j] - c_vals,
        cosine      = sqrt(freq[i] * freq[j]),
        inclusion   = pmin(freq[i], freq[j]),
        association = freq[i] * freq[j],
        dice        = freq[i] + freq[j],
        equivalence = freq[i] * freq[j]
      )
      denom[denom == 0] <- 1
      numer <- switch(similarity,
        dice        = 2 * c_vals,
        equivalence = c_vals^2,
        c_vals
      )
      W_x <- as.numeric(numer / denom)
      W_sparse <- Matrix::sparseMatrix(
        i = i, j = j, x = W_x,
        dims = c(n_items, n_items), symmetric = TRUE,
        dimnames = list(items, items)
      )
    }

    ## Scaling operates on the full non-zero population of the stored matrix.
    ## For symmetric W, that population is c(W_x, W_x); for relative W, it is
    ## the asymmetric entries in both triangles.
    if (scale_method != "none") {
      if (similarity == "relative") {
        population <- W_full_x
        W_full_x <- .co_scale_values(W_full_x, population, scale_method)
        W_x <- .co_scale_values(W_x, population, scale_method)
      } else {
        population <- c(W_x, W_x)
        W_x <- .co_scale_values(W_x, population, scale_method)
        W_sparse <- Matrix::sparseMatrix(
          i = i, j = j, x = W_x,
          dims = c(n_items, n_items), symmetric = TRUE,
          dimnames = list(items, items)
        )
      }
    }

    ## Build the asymmetric W_sparse for 'relative' (post-scaling).
    if (similarity == "relative") {
      W_sparse <- Matrix::sparseMatrix(
        i = ii, j = jj, x = W_full_x,
        dims = c(n_items, n_items),
        dimnames = list(items, items)
      )
    }

    ## Threshold filter on edge weights (before name lookup is cheap).
    if (threshold > 0) {
      keep <- W_x >= threshold
      W_x <- W_x[keep]; i <- i[keep]; j <- j[keep]; raw_vals <- raw_vals[keep]
    }

    edges <- data.frame(
      from   = items[i],
      to     = items[j],
      weight = W_x,
      count  = raw_vals,
      stringsAsFactors = FALSE
    )
    edges <- edges[order(-edges$weight), ]

    if (!is.null(top_n)) {
      stopifnot(is.numeric(top_n), top_n > 0)
      top_n <- as.integer(top_n)
      if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
    }
  }

  rownames(edges) <- NULL
  class(edges) <- c("cooccurrence", "data.frame")
  attr(edges, "matrix")         <- W_sparse
  attr(edges, "raw_matrix")     <- C_raw
  attr(edges, "items")          <- items
  attr(edges, "frequencies")    <- freq
  attr(edges, "similarity")     <- similarity
  attr(edges, "scale")          <- scale_method
  attr(edges, "threshold")      <- threshold
  attr(edges, "min_occur")      <- min_occur
  attr(edges, "n_transactions") <- n_trans
  attr(edges, "n_items")        <- n_items

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

  docs      <- as.character(data[[by]])
  items_col <- as.character(data[[field]])
  weights   <- as.numeric(data[[weight_by]])

  ## Drop NA / zero-weight rows up front.
  keep <- !is.na(docs) & !is.na(items_col) & !is.na(weights) & weights != 0
  docs <- docs[keep]
  items_col <- items_col[keep]
  weights <- weights[keep]

  all_docs  <- unique(docs)
  all_items <- sort(unique(items_col))
  doc_idx   <- match(docs, all_docs)
  item_idx  <- match(items_col, all_items)

  ## Sparse weighted matrix: docs x items. Duplicate (doc, item) rows sum.
  W <- Matrix::sparseMatrix(
    i = doc_idx, j = item_idx, x = weights,
    dims = c(length(all_docs), length(all_items)),
    dimnames = list(NULL, all_items)
  )

  if (min_occur > 1L) {
    ## Count distinct docs per item via sparse triplets.
    n_docs_per_item <- tabulate(item_idx, nbins = length(all_items))
    keep_items <- n_docs_per_item >= min_occur
    W <- W[, keep_items, drop = FALSE]
    all_items <- all_items[keep_items]
  }

  if (ncol(W) == 0L)
    stop("No items remain after min_occur filtering.", call. = FALSE)

  n_trans <- nrow(W)
  n_items <- ncol(W)
  freq <- as.numeric(Matrix::colSums(W))
  names(freq) <- all_items

  ## Binary companion for raw counts.
  B_bin <- Matrix::sparseMatrix(
    i = doc_idx, j = item_idx, x = 1,
    dims = c(length(all_docs), length(all_items)),
    dimnames = list(NULL, colnames(W))
  )
  ## If min_occur filtered columns, realign B_bin to W.
  if (ncol(B_bin) != ncol(W)) {
    B_bin <- B_bin[, colnames(W), drop = FALSE]
  }
  ## sparseMatrix sums duplicates — clip to {0, 1} for the binary matrix.
  B_bin <- Matrix::drop0(sign(B_bin))

  C_raw <- Matrix::crossprod(B_bin)
  C     <- Matrix::crossprod(W)
  Matrix::diag(C) <- 0
  Matrix::diag(C_raw) <- 0
  C     <- Matrix::drop0(C)
  C_raw <- Matrix::drop0(C_raw)

  .co_finalize(C, C_raw, freq, n_trans, n_items, all_items,
               similarity, scale_method, threshold, min_occur, top_n)
}


# ---- Scaling (triplet-based) ----

#' Apply a post-normalisation scaling to edge weights.
#'
#' @param vals Numeric vector to scale (the edge weights returned to the user).
#' @param population Numeric vector of all non-zero values that would appear in
#'   the conceptual full k x k matrix. Used to compute statistics (min/max,
#'   mean/sd, sum) so results match the original dense implementation.
#' @param method Scaling method.
#' @noRd
.co_scale_values <- function(vals, population, method) {
  nz <- population[population != 0]
  if (length(nz) == 0L) return(vals)

  nonzero <- vals != 0

  switch(method,
    minmax = {
      mn <- min(nz); mx <- max(nz)
      out <- vals
      out[nonzero] <- if (mx > mn) (vals[nonzero] - mn) / (mx - mn) else 1
      out
    },
    log = {
      out <- vals
      out[nonzero] <- log(1 + vals[nonzero])
      out
    },
    log10 = {
      out <- vals
      out[nonzero] <- log10(1 + vals[nonzero])
      out
    },
    binary = {
      out <- vals
      out[nonzero] <- 1
      out
    },
    zscore = {
      mu <- mean(nz); s <- stats::sd(nz)
      out <- vals
      if (s > 0) out[nonzero] <- (vals[nonzero] - mu) / s
      out
    },
    sqrt = {
      out <- vals
      out[nonzero] <- sqrt(vals[nonzero])
      out
    },
    proportion = {
      s <- sum(nz)
      out <- vals
      if (s > 0) out[nonzero] <- vals[nonzero] / s
      out
    }
  )
}


# ---- Format detection ----

#' @noRd
.co_detect_format <- function(data, field, by, sep) {
  if (is.list(data) && !is.data.frame(data) && !is.matrix(data))
    return("list")

  if (!is.null(field) && length(field) == 1L && identical(field, "all"))
    return("wide")

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
    stop("Cannot detect input format. For wide sequence data use field = \"all\".",
         call. = FALSE)
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


# ---- Sparse bipartite matrix builder ----

#' Build sparse works-by-items incidence matrices from a list of transactions.
#'
#' Returns both the counting-weighted matrix `B` (used for the weighted
#' crossprod) and the binary matrix `B_bin` (used for item frequencies and
#' raw counts). Staying in sparse representation is what lets the pipeline
#' scale to hundreds of thousands of items.
#'
#' Counting method `"fractional"` (Perianes-Rodriguez et al., 2016) bakes
#' `sqrt(1/(n_r - 1))` into each row's non-zero entries, so that
#' `crossprod(B)[i, j] = sum over rows with both i and j of 1/(n_r - 1)`.
#'
#' @noRd
.co_build_sparse <- function(transactions, counting) {
  all_items <- sort(unique(unlist(transactions, use.names = FALSE)))
  n <- length(transactions)
  k <- length(all_items)
  lens <- vapply(transactions, length, integer(1))
  row_idx <- rep.int(seq_len(n), lens)
  col_idx <- match(unlist(transactions, use.names = FALSE), all_items)

  if (counting == "fractional") {
    row_weight <- ifelse(lens > 1L, 1 / (lens - 1L), 1)
    x <- sqrt(row_weight[row_idx])
  } else {
    x <- rep(1.0, length(row_idx))
  }

  B <- Matrix::sparseMatrix(
    i = row_idx, j = col_idx, x = x,
    dims = c(n, k),
    dimnames = list(NULL, all_items)
  )
  B_bin <- Matrix::sparseMatrix(
    i = row_idx, j = col_idx, x = rep(1.0, length(row_idx)),
    dims = c(n, k),
    dimnames = list(NULL, all_items)
  )

  list(B = B, B_bin = B_bin, items = all_items, n = n, k = k)
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
