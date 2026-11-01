# ---- Converters for cooccurrence objects ----

#' Extract the co-occurrence matrix
#'
#' Returns the full square co-occurrence matrix: the edge weights after
#' similarity normalization, scaling, and filtering, or with
#' \code{type = "raw"} the raw co-occurrence counts. Use it when a method
#' downstream (clustering, a heatmap, another network package) expects a
#' matrix rather than an edge list.
#'
#' @param x A \code{cooccurrence} data frame.
#' @param type Character. \code{"normalized"} (default) for the weights, or
#'   \code{"raw"} for the number of transactions in which each pair
#'   co-occurs.
#' @param ... Ignored.
#' @return A dense base numeric matrix, one row and one column per item,
#'   with item names as row and column names and a zero diagonal. It is
#'   symmetric for every similarity except \code{"relative"}, where row
#'   \code{i} holds the weights from item \code{i} and each row sums to 1.
#'   Results built with \code{split_by} store no single matrix, so the
#'   matrix is rebuilt from the edge list.
#' @examples
#' res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
#' as_matrix(res)
#' as_matrix(res, type = "raw")
#' @export
as_matrix <- function(x, ...) UseMethod("as_matrix")

#' @rdname as_matrix
#' @export
as_matrix.cooccurrence <- function(x, type = c("normalized", "raw"), ...) {
  type <- match.arg(type)
  mat <- if (type == "raw") attr(x, "raw_matrix") else attr(x, "matrix")
  if (!is.null(mat)) {
    ## Attributes are stored as sparse Matrix objects in the current engine.
    ## Densify on demand so downstream code gets a regular base matrix. For
    ## very large networks, the caller should avoid as_matrix() and work with
    ## the edge list directly.
    if (inherits(mat, "Matrix")) return(as.matrix(mat))
    return(mat)
  }

  ## Fallback: rebuild from the edge list. Used when the matrix attribute is
  ## absent, which includes split_by results (where a single matrix cannot
  ## describe several stacked networks). Columns are resolved so that
  ## Gephi-named output works too.
  cols <- .co_edge_columns(x)
  items <- attr(x, "items")
  if (is.null(items)) items <- sort(unique(c(cols$from, cols$to)))
  k <- length(items)
  vals <- if (type == "raw") cols$count else cols$weight
  if (nrow(x) == 0L) {
    return(matrix(0, k, k, dimnames = list(items, items)))
  }
  i <- match(cols$from, items)
  j <- match(cols$to, items)
  M <- matrix(0, k, k, dimnames = list(items, items))
  M[cbind(i, j)] <- vals
  M[cbind(j, i)] <- vals
  M
}


#' Convert to igraph
#'
#' Creates an undirected, weighted \code{igraph} graph from a
#' \code{cooccurrence} edge list, so the result can be analyzed with any
#' \pkg{igraph} function. Requires the \pkg{igraph} package.
#'
#' @param x A \code{cooccurrence} data frame (default or \code{"gephi"}
#'   column names).
#' @param ... Passed to \code{igraph::graph_from_data_frame()}, apart from
#'   \code{directed} and \code{vertices}, which are set here.
#' @return An undirected \code{igraph} object with one vertex per item
#'   (vertex attribute \code{name}, isolated items included) and one edge
#'   per row of \code{x} (edge attributes \code{weight} and \code{count}).
#'   Raises an error when \pkg{igraph} is not installed.
#' @examples
#' res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   g <- as_igraph(res)
#'   igraph::vcount(g)
#' }
#' @export
as_igraph <- function(x, ...) UseMethod("as_igraph")

#' @rdname as_igraph
#' @export
as_igraph.cooccurrence <- function(x, ...) {
  if (!requireNamespace("igraph", quietly = TRUE))
    stop("Package 'igraph' is required.", call. = FALSE)

  items <- attr(x, "items")
  vertices <- if (!is.null(items)) {
    data.frame(name = items, stringsAsFactors = FALSE)
  } else {
    NULL
  }

  ## Resolve edge columns rather than assuming the default names, so that
  ## output = "gephi" objects (Source/Target/Weight/Count) also convert.
  cols <- .co_edge_columns(x)
  edge_df <- data.frame(from = cols$from, to = cols$to,
                        weight = cols$weight, count = cols$count,
                        stringsAsFactors = FALSE)
  if (is.null(vertices)) {
    vertices <- data.frame(name = sort(unique(c(cols$from, cols$to))),
                           stringsAsFactors = FALSE)
  }

  igraph::graph_from_data_frame(
    edge_df,
    directed = FALSE,
    vertices = vertices,
    ...
  )
}


#' Convert to tidygraph
#'
#' Creates a \code{tbl_graph} from a \code{cooccurrence} edge list, for
#' use with \pkg{tidygraph} and \pkg{ggraph}. Requires the \pkg{tidygraph}
#' and \pkg{igraph} packages.
#'
#' @param x A \code{cooccurrence} data frame.
#' @param ... Passed to \code{\link{as_igraph}()}.
#' @return A \code{tbl_graph} (which also inherits from \code{igraph}) with
#'   the same vertices and edges as \code{\link{as_igraph}()}: node column
#'   \code{name}, edge columns \code{from}, \code{to}, \code{weight},
#'   \code{count}. Raises an error when \pkg{tidygraph} is not installed.
#' @examples
#' res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
#' if (requireNamespace("tidygraph", quietly = TRUE) &&
#'     requireNamespace("igraph",    quietly = TRUE)) {
#'   as_tidygraph(res)
#' }
#' @export
as_tidygraph <- function(x, ...) UseMethod("as_tidygraph")

#' @rdname as_tidygraph
#' @export
as_tidygraph.cooccurrence <- function(x, ...) {
  if (!requireNamespace("tidygraph", quietly = TRUE))
    stop("Package 'tidygraph' is required.", call. = FALSE)
  tidygraph::as_tbl_graph(as_igraph(x, ...))
}


#' Convert to cograph network
#'
#' Creates a \code{cograph_network} object from a \code{cooccurrence}
#' edge list, so the network can be plotted with \code{cograph::splot()}
#' and analyzed with \pkg{cograph} functions such as
#' \code{cograph::centrality()} and \code{cograph::communities()}.
#' Requires the \pkg{cograph} package.
#'
#' \pkg{cograph} exports its own \code{as_cograph()}. When \pkg{cograph} is
#' attached after \pkg{cooccure}, a bare \code{as_cograph()} call resolves
#' to the \pkg{cograph} version, which reads the edge data frame with its
#' own defaults. Call \code{cooccure::as_cograph()}, or build the network
#' with \code{cooccurrence(..., output = "cograph")}, to get this method.
#'
#' @param x A \code{cooccurrence} data frame.
#' @param ... Ignored.
#' @return A list of class \code{cograph_network}, always undirected, built
#'   from the upper triangle of \code{as_matrix(x)}. It holds the weight
#'   matrix, a node table (one row per item: \code{id}, \code{label},
#'   \code{name}, \code{x}, \code{y}), an edge table (one row per edge:
#'   integer \code{from} and \code{to} node ids, \code{weight}), and the
#'   node and edge counts. Raises an error when \pkg{cograph} is not
#'   installed.
#' @examples
#' res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
#' if (requireNamespace("cograph", quietly = TRUE)) {
#'   cooccure::as_cograph(res)
#' }
#' @export
as_cograph <- function(x, ...) UseMethod("as_cograph")

#' @rdname as_cograph
#' @export
as_cograph.cooccurrence <- function(x, ...) {
  if (!requireNamespace("cograph", quietly = TRUE))
    stop("Package 'cograph' is required.", call. = FALSE)

  mat <- as_matrix(x, type = "normalized")
  items <- colnames(mat)

  nodes_df <- data.frame(
    id = seq_along(items), label = items, name = items,
    x = NA_real_, y = NA_real_, stringsAsFactors = FALSE
  )

  # Edge list from upper triangle
  idx <- which(upper.tri(mat) & mat != 0, arr.ind = TRUE)
  if (nrow(idx) > 0L) {
    edges_df <- data.frame(
      from = as.integer(idx[, 1]),
      to = as.integer(idx[, 2]),
      weight = mat[idx],
      stringsAsFactors = FALSE
    )
  } else {
    edges_df <- data.frame(from = integer(0), to = integer(0),
                           weight = numeric(0), stringsAsFactors = FALSE)
  }

  structure(
    list(
      weights = mat,
      nodes = nodes_df,
      edges = edges_df,
      directed = FALSE,
      n_nodes = length(items),
      n_edges = nrow(edges_df),
      meta = list(source = "cooccure", layout = NULL)
    ),
    class = "cograph_network"
  )
}


#' Convert to Nestimate netobject
#'
#' Creates a \code{netobject} from a \code{cooccurrence} edge list, so the
#' network can be passed to \pkg{Nestimate} functions that work on an
#' estimated weight matrix, such as \code{Nestimate::net_centrality()}.
#' Requires the \pkg{Nestimate} package.
#'
#' The netobject carries no raw data (its \code{data} element is
#' \code{NULL}), so \pkg{Nestimate} functions that resample the original
#' observations, such as \code{Nestimate::bootstrap_network()}, cannot run
#' on it and stop with an error asking for a network built with
#' \code{Nestimate::build_network()}.
#'
#' @param x A \code{cooccurrence} data frame.
#' @param ... Ignored.
#' @return A list of class \code{c("netobject", "cograph_network")},
#'   always undirected, with method \code{"cooccurrence"}. It holds the
#'   weight matrix from \code{as_matrix(x)}, a node table (one row per
#'   item), an edge table (one row per edge of the upper triangle), and the
#'   similarity, scale, threshold, and number of transactions used. Raises
#'   an error when \pkg{Nestimate} is not installed.
#' @examples
#' res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
#' if (requireNamespace("Nestimate", quietly = TRUE)) {
#'   net <- as_netobject(res)
#'   Nestimate::net_centrality(net)
#' }
#' @export
as_netobject <- function(x, ...) UseMethod("as_netobject")

#' @rdname as_netobject
#' @export
as_netobject.cooccurrence <- function(x, ...) {
  if (!requireNamespace("Nestimate", quietly = TRUE))
    stop("Package 'Nestimate' is required.", call. = FALSE)

  mat <- as_matrix(x, type = "normalized")
  items <- colnames(mat)

  nodes_df <- data.frame(
    id = seq_along(items), label = items, name = items,
    x = NA_real_, y = NA_real_, stringsAsFactors = FALSE
  )

  idx <- which(upper.tri(mat) & mat != 0, arr.ind = TRUE)
  if (nrow(idx) > 0L) {
    edges_df <- data.frame(
      from = as.integer(idx[, 1]),
      to = as.integer(idx[, 2]),
      weight = mat[idx],
      stringsAsFactors = FALSE
    )
  } else {
    edges_df <- data.frame(from = integer(0), to = integer(0),
                           weight = numeric(0), stringsAsFactors = FALSE)
  }

  structure(
    list(
      data = NULL,
      weights = mat,
      nodes = nodes_df,
      edges = edges_df,
      directed = FALSE,
      method = "cooccurrence",
      params = list(
        similarity = attr(x, "similarity"),
        scale = attr(x, "scale"),
        threshold = attr(x, "threshold"),
        n_transactions = attr(x, "n_transactions")
      ),
      scaling = NULL,
      threshold = attr(x, "threshold"),
      n_nodes = length(items),
      n_edges = nrow(edges_df),
      level = NULL,
      meta = list(source = "cooccure", layout = NULL,
                  tna = list(method = "cooccurrence")),
      node_groups = NULL
    ),
    class = c("netobject", "cograph_network")
  )
}
