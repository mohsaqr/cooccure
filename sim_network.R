# sim_network.R
#
# Standalone similarity-network builder. Build a weighted, undirected
# network from a precomputed pairwise item × item similarity matrix
# (or distance, with conversion). Returns an S3 object that carries
# the edge list and the pruned sparse similarity matrix, with print /
# summary / as_matrix / as_igraph methods.
#
# Self-contained: depends only on base R and the Matrix package. Lives
# outside any package while the API stabilises. Source into a session:
#
#   source("sim_network.R")
#
# Conceptually distinct from co-occurrence: similarity asks "what is
# alike by some external measure?" — the user supplies the matrix.
# Co-occurrence asks "what appeared together?" — counts come from data.
# These two ideas should not share a package; this file is the
# prototype for splitting them out.

# ---- Generics (define conditionally so source() is safe whether or
#      not cooccure is also loaded) ---------------------------------

if (!exists("as_matrix", mode = "function")) {
  as_matrix <- function(x, ...) UseMethod("as_matrix")
}
if (!exists("as_igraph", mode = "function")) {
  as_igraph <- function(x, ...) UseMethod("as_igraph")
}


# ---- Main constructor ---------------------------------------------

#' Build a similarity network from a pairwise matrix
#'
#' @param x Square numeric matrix (or `Matrix` / `data.frame`) of
#'   pairwise item similarities (default) or distances. Symmetric or
#'   not — asymmetric inputs are averaged with their transpose.
#' @param input "similarity" (default) or "distance".
#' @param distance_to_similarity Conversion applied when
#'   `input = "distance"`. Choices: `"inverse"` (1/(1+d), default),
#'   `"exp_neg"` (exp(-d)), `"max_minus"` (max(d) - d).
#' @param threshold Drop edges below this weight. Default 0.
#' @param top_n Integer. Keep the top N edges globally. Default NULL.
#' @param top_k_per_node Integer. For each node keep its K strongest
#'   neighbours; symmetrise via union (an edge survives if either
#'   endpoint has the other in its top-K). Default NULL.
#' @param diag_zero Zero the diagonal before edge extraction. Default TRUE.
#' @return An S3 object `c("similarity_network", "data.frame")` with
#'   columns from / to / weight, plus attributes `matrix` (the pruned
#'   sparse symmetric matrix), `items`, `n_items`, and `config`.
similarity_network <- function(x,
                               input = c("similarity", "distance"),
                               distance_to_similarity =
                                 c("inverse", "exp_neg", "max_minus"),
                               threshold = 0,
                               top_n = NULL,
                               top_k_per_node = NULL,
                               diag_zero = TRUE) {
  input <- match.arg(input)
  distance_to_similarity <- match.arg(distance_to_similarity)
  threshold <- as.numeric(threshold)
  stopifnot(threshold >= 0)

  ## Coerce to a base numeric matrix.
  if (inherits(x, "Matrix")) x <- as.matrix(x)
  if (is.data.frame(x))      x <- as.matrix(x)
  stopifnot(
    is.matrix(x),
    is.numeric(x) || is.logical(x),
    nrow(x) == ncol(x),
    nrow(x) >= 2L
  )
  storage.mode(x) <- "double"

  ## Distance -> similarity.
  if (input == "distance") {
    if (any(x < 0, na.rm = TRUE))
      stop("Negative values in distance matrix.", call. = FALSE)
    x <- .sn_dist_to_sim(x, distance_to_similarity)
  }

  ## NA -> 0 (treated as no edge).
  x[is.na(x)] <- 0

  ## Names.
  if (is.null(rownames(x)) && is.null(colnames(x))) {
    nm <- paste0("V", seq_len(nrow(x)))
    rownames(x) <- nm; colnames(x) <- nm
  } else if (is.null(rownames(x))) {
    rownames(x) <- colnames(x)
  } else if (is.null(colnames(x))) {
    colnames(x) <- rownames(x)
  }
  if (!identical(rownames(x), colnames(x)))
    stop("rownames(x) and colnames(x) must match.", call. = FALSE)
  items <- rownames(x)
  n_items <- length(items)

  ## Symmetrise (similarity networks are undirected by construction).
  if (!isSymmetric(unname(x))) x <- (x + t(x)) / 2

  if (diag_zero) diag(x) <- 0

  ## Per-node kNN with union symmetrisation.
  if (!is.null(top_k_per_node)) {
    K <- as.integer(top_k_per_node)
    stopifnot(K >= 1L, K < n_items)
    mask <- .sn_knn_mask(x, K)
    x[!mask] <- 0
  }

  ## Build edges from the upper triangle.
  upper_idx <- which(upper.tri(x) & x != 0, arr.ind = TRUE)
  if (nrow(upper_idx) > 0L) {
    i <- upper_idx[, 1]; j <- upper_idx[, 2]; w <- x[upper_idx]
  } else {
    i <- integer(0); j <- integer(0); w <- numeric(0)
  }

  if (threshold > 0) {
    keep <- w >= threshold
    i <- i[keep]; j <- j[keep]; w <- w[keep]
  }

  edges <- data.frame(
    from   = items[i],
    to     = items[j],
    weight = w,
    stringsAsFactors = FALSE
  )
  if (nrow(edges) > 0L) {
    edges <- edges[order(-edges$weight), ]
    if (!is.null(top_n)) {
      stopifnot(is.numeric(top_n), top_n > 0)
      top_n <- as.integer(top_n)
      if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
    }
  }
  rownames(edges) <- NULL

  ## Pruned sparse symmetric matrix from the surviving edges.
  if (nrow(edges) > 0L) {
    ii <- match(edges$from, items)
    jj <- match(edges$to,   items)
    swap <- ii > jj
    if (any(swap)) {
      tmp <- ii[swap]; ii[swap] <- jj[swap]; jj[swap] <- tmp
    }
    M <- Matrix::sparseMatrix(
      i = ii, j = jj, x = edges$weight,
      dims = c(n_items, n_items),
      symmetric = TRUE,
      dimnames = list(items, items)
    )
  } else {
    M <- Matrix::sparseMatrix(
      i = integer(0), j = integer(0), x = numeric(0),
      dims = c(n_items, n_items),
      symmetric = TRUE,
      dimnames = list(items, items)
    )
  }

  class(edges) <- c("similarity_network", "data.frame")
  attr(edges, "matrix")  <- M
  attr(edges, "items")   <- items
  attr(edges, "n_items") <- n_items
  attr(edges, "config")  <- list(
    input = input,
    distance_to_similarity =
      if (input == "distance") distance_to_similarity else NA_character_,
    threshold      = threshold,
    top_n          = top_n,
    top_k_per_node = top_k_per_node
  )
  edges
}


# ---- Internal helpers ---------------------------------------------

.sn_dist_to_sim <- function(d, method) {
  switch(method,
    inverse   = 1 / (1 + d),
    exp_neg   = exp(-d),
    max_minus = max(d, na.rm = TRUE) - d
  )
}

.sn_knn_mask <- function(W, K) {
  n <- nrow(W)
  ## Mask the diagonal with -Inf so it never ranks in the top K. (Plain
  ## diag = 0 would surface as the largest entry in rows whose
  ## off-diagonal values are all negative, then get dropped at the
  ## upper-tri filter, leaving the node with degree < K.)
  W2 <- W
  diag(W2) <- -Inf
  knn_idx <- t(apply(W2, 1, function(r)
    order(r, decreasing = TRUE)[seq_len(K)]))
  mask <- matrix(FALSE, n, n)
  mask[cbind(rep(seq_len(n), each = K),
             as.vector(t(knn_idx)))] <- TRUE
  mask | t(mask)
}


# ---- Methods ------------------------------------------------------

#' @export
print.similarity_network <- function(x, n = 10L, ...) {
  n_nodes <- attr(x, "n_items")
  n_edges <- nrow(x)
  cfg <- attr(x, "config")

  cat(sprintf("# similarity_network: %d items, %d edges", n_nodes, n_edges))
  if (!is.null(cfg)) {
    if (cfg$input == "distance")
      cat(sprintf(" | dist→sim: %s", cfg$distance_to_similarity))
    if (!is.null(cfg$top_k_per_node))
      cat(sprintf(" | top_k_per_node: %d", cfg$top_k_per_node))
    if (!is.null(cfg$top_n))
      cat(sprintf(" | top_n: %d", cfg$top_n))
    if (cfg$threshold > 0)
      cat(sprintf(" | threshold: %g", cfg$threshold))
  }
  cat("\n")

  show <- min(n, n_edges)
  if (show > 0L) {
    print(as.data.frame(x)[seq_len(show), ], row.names = FALSE)
    if (n_edges > show)
      cat(sprintf("# ... %d more edges\n", n_edges - show))
  } else {
    cat("# (no edges)\n")
  }
  invisible(x)
}

#' @export
summary.similarity_network <- function(object, ...) {
  n_nodes <- attr(object, "n_items")
  n_edges <- nrow(object)
  max_possible <- n_nodes * (n_nodes - 1L) / 2L
  density <- if (max_possible > 0) n_edges / max_possible else NA_real_

  cat("similarity network\n")
  cat(strrep("-", 30), "\n", sep = "")
  cat(sprintf("Items          : %d\n", n_nodes))
  cat(sprintf("Edges          : %d\n", n_edges))
  cat(sprintf("Density        : %.4f\n", density))
  if (n_edges > 0L) {
    cat(sprintf("Weight range   : [%.4g, %.4g]\n",
                min(object$weight), max(object$weight)))
    deg <- sort(table(c(object$from, object$to)), decreasing = TRUE)
    top <- utils::head(deg, 5L)
    cat(sprintf("Top items      : %s\n",
                paste(sprintf("%s(%d)", names(top), as.integer(top)),
                      collapse = ", ")))
  }
  invisible(object)
}

#' @export
as_matrix.similarity_network <- function(x, ...) {
  M <- attr(x, "matrix")
  if (inherits(M, "Matrix")) as.matrix(M) else M
}

#' @export
as_igraph.similarity_network <- function(x, ...) {
  if (!requireNamespace("igraph", quietly = TRUE))
    stop("Package 'igraph' is required.", call. = FALSE)
  vertices <- data.frame(name = attr(x, "items"), stringsAsFactors = FALSE)
  igraph::graph_from_data_frame(
    x[, c("from", "to", "weight")],
    directed = FALSE,
    vertices = vertices,
    ...
  )
}


# ---- Quick verification block (interactive only) ------------------
# Wrapped in `if (FALSE)` so source()ing the file never executes it.

if (FALSE) {
  # 1. Correlation network from a small feature matrix
  set.seed(1)
  M <- matrix(rnorm(60), nrow = 6,
              dimnames = list(letters[1:6], paste0("f", 1:10)))
  S <- cor(t(M))
  net <- similarity_network(S, threshold = 0.2)
  print(net); summary(net)

  # 2. From a distance matrix, with kNN pruning
  D <- as.matrix(dist(M))
  net2 <- similarity_network(D, input = "distance",
                             distance_to_similarity = "inverse",
                             top_k_per_node = 2)
  print(net2)

  # 3. Hand off to igraph (requires the package)
  if (requireNamespace("igraph", quietly = TRUE)) {
    g <- as_igraph(net)
    print(g)
  }
}
