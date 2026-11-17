# ---- Converters for cooccurrence objects ----

#' Extract the weight matrix of a co-occurrence network
#'
#' @description
#' `as_matrix()` returns the weight matrix of a co-occurrence network built
#' by [cooccurrence()]. The weight matrix is the network written as a square
#' matrix with one row and one column per item, where a cell holds the
#' weight of the edge between two items and the diagonal is zero. This form
#' is what clustering, heatmaps, matrix algebra and many network packages
#' expect, and it shows at once which item pairs never co-occur.
#'
#' The cells hold the edge weights after similarity, scaling and filtering,
#' or, with `type = "raw"`, the number of transactions in which each pair
#' co-occurs. The matrix agrees with the printed edge list,
#' including any `threshold` or `top_n` filter. It is symmetric for every
#' similarity except `"relative"`, whose network is directed.
#'
#' A result built with `split_by` stacks one network per group and has no
#' single matrix, so `group` names the network to extract. For a graph object
#' rather than a matrix, use [as_igraph()], [as_tidygraph()],
#' [as_cograph()] or [as_netobject()].
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param type `"normalized"` (default) for the edge weights, or `"raw"` for
#'   the co-occurrence counts.
#' @param group For a result built with `split_by`, the name of the group to
#'   extract. `NULL` (default) for an unsplit result.
#' @param ... Ignored.
#' @return A dense base numeric matrix with one row and one column per item,
#'   item names as row and column names, and a zero diagonal. Items that
#'   co-occur with nothing (isolates) keep a row of zeros. For
#'   `similarity = "relative"` the weight matrix is asymmetric: row `i` holds
#'   the weights of the edges from item `i`, and each non-empty row sums to 1
#'   before filtering. The raw matrix is always symmetric.
#' @section Conditions:
#'   `cooccure_grouped_input` when `x` was built with `split_by` and `group`
#'   is `NULL`; `cooccure_bad_input` when `group` names no group of `x`, or
#'   is given for an unsplit result.
#' @seealso [cooccurrence()] to build the network; [as_igraph()] for a graph
#'   object; [as.data.frame.cooccurrence()] for the edge and node tables.
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' as_matrix(net)
#' as_matrix(net, type = "raw")
#'
#' # One network of a split result
#' by_decade <- cooccurrence(movies, field = "genres", sep = ",",
#'                           split_by = "decade", min_occur = 50)
#' as_matrix(by_decade, group = "2010s")
#' @export
as_matrix <- function(x, ...) UseMethod("as_matrix")

#' @rdname as_matrix
#' @export
as_matrix.cooccurrence <- function(x, type = c("normalized", "raw"),
                                   group = NULL, ...) {
  type <- match.arg(type)
  x <- .co_select_group(x, group)
  mat <- if (type == "raw") attr(x, "raw_matrix") else attr(x, "matrix")
  if (!is.null(mat)) {
    ## Attributes are stored as sparse Matrix objects. Densify on demand so
    ## downstream code gets a regular base matrix; for very large networks
    ## the edge list is the better representation.
    if (inherits(mat, "Matrix")) return(as.matrix(mat))
    return(mat)
  }

  ## Rebuild from the edge list. Used when the matrix attribute is absent,
  ## which includes one group extracted from a split_by result and objects
  ## whose attributes were dropped by subsetting. Columns are resolved so
  ## that Gephi-named output works too.
  cols <- .co_edge_columns(x)
  items <- sort(unique(c(attr(x, "items"), cols$from, cols$to)))
  k <- length(items)
  M <- matrix(0, k, k, dimnames = list(items, items))
  if (length(cols$from) == 0L) return(M)
  i <- match(cols$from, items)
  j <- match(cols$to, items)
  vals <- if (type == "raw") cols$count else cols$weight
  M[cbind(i, j)] <- vals
  ## Undirected networks store one row per pair, and counts are symmetric
  ## in every network; only directed weights keep their own direction.
  if (type == "raw" || !.co_is_directed(x)) M[cbind(j, i)] <- vals
  M
}


#' Convert a co-occurrence network to an igraph graph
#'
#' @description
#' `as_igraph()` converts a co-occurrence network to an `igraph` object.
#' \pkg{igraph} is the most widely used general-purpose network library in R,
#' with functions for centrality, community detection, paths and layouts;
#' the conversion makes all of them available without re-entering the edges.
#'
#' The result is a weighted graph with one vertex per item, isolates
#' included, and one edge per row of the edge list, carrying the edge
#' attributes `weight` and `count`. The graph is undirected, except for
#' `similarity = "relative"`, where each row is a directed edge and the
#' graph is directed.
#'
#' A result built with `split_by` holds several networks; `group` names the
#' one to convert, since stacking them would create one parallel edge per
#' group. For a `tbl_graph`, use [as_tidygraph()].
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()], with default or
#'   `"gephi"` column names.
#' @param group For a result built with `split_by`, the name of the group to
#'   convert. `NULL` (default) for an unsplit result.
#' @param ... Passed to `igraph::graph_from_data_frame()`, apart from
#'   `directed` and `vertices`, which are set here.
#' @return An `igraph` object with one vertex per item (vertex attribute
#'   `name`) and one edge per row of the edge list (edge attributes `weight`
#'   and `count`). Directed for `similarity = "relative"`, undirected
#'   otherwise.
#' @section Conditions:
#'   `cooccure_missing_package` when \pkg{igraph} is not installed;
#'   `cooccure_grouped_input` when `x` was built with `split_by` and `group`
#'   is `NULL`; `cooccure_bad_input` for an unknown `group`.
#' @seealso [as_tidygraph()] for a `tbl_graph`; [as_cograph()] and
#'   [as_netobject()] for the \pkg{cograph} and \pkg{Nestimate} classes;
#'   [as_matrix()] for the weight matrix.
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   g <- as_igraph(net)
#'   igraph::strength(g)
#' }
#' @export
as_igraph <- function(x, ...) UseMethod("as_igraph")

#' @rdname as_igraph
#' @export
as_igraph.cooccurrence <- function(x, group = NULL, ...) {
  .co_need("igraph")
  x <- .co_select_group(x, group)

  ## Resolve edge columns rather than assuming the default names, so that
  ## output = "gephi" objects (Source/Target/Weight/Count) also convert.
  cols <- .co_edge_columns(x)
  edge_df <- data.frame(from = cols$from, to = cols$to,
                        weight = cols$weight, count = cols$count,
                        stringsAsFactors = FALSE)
  vertices <- data.frame(
    name = sort(unique(c(attr(x, "items"), cols$from, cols$to))),
    stringsAsFactors = FALSE
  )

  igraph::graph_from_data_frame(
    edge_df,
    directed = .co_is_directed(x),
    vertices = vertices,
    ...
  )
}


#' Convert a co-occurrence network to a tidygraph
#'
#' @description
#' `as_tidygraph()` converts a co-occurrence network to a `tbl_graph`.
#' \pkg{tidygraph} represents a network as two linked tables, nodes and
#' edges, that can be manipulated with \pkg{dplyr} verbs and drawn with
#' \pkg{ggraph}. It suits analyses that add node or edge measures as columns
#' and then plot them.
#'
#' The conversion goes by way of [as_igraph()], so the vertices, edges,
#' attributes and direction are the same as there.
#'
#' For a result built with `split_by`, `group` names the network to convert.
#' For the plain \pkg{igraph} object, use [as_igraph()].
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param group For a result built with `split_by`, the name of the group to
#'   convert. `NULL` (default) for an unsplit result.
#' @param ... Passed to [as_igraph()].
#' @return A `tbl_graph` (which also inherits from `igraph`) with node column
#'   `name` and edge columns `from`, `to`, `weight` and `count`; directed for
#'   `similarity = "relative"`.
#' @section Conditions:
#'   `cooccure_missing_package` when \pkg{tidygraph} or \pkg{igraph} is not
#'   installed; the conditions of [as_igraph()] otherwise.
#' @seealso [as_igraph()]; [as_cograph()]; [as_matrix()].
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' if (requireNamespace("tidygraph", quietly = TRUE) &&
#'     requireNamespace("igraph", quietly = TRUE)) {
#'   as_tidygraph(net)
#' }
#' @export
as_tidygraph <- function(x, ...) UseMethod("as_tidygraph")

#' @rdname as_tidygraph
#' @export
as_tidygraph.cooccurrence <- function(x, group = NULL, ...) {
  .co_need("tidygraph")
  tidygraph::as_tbl_graph(as_igraph(x, group = group, ...))
}


#' Convert a co-occurrence network to a cograph network
#'
#' @description
#' `as_cograph()` converts a co-occurrence network to a `cograph_network`.
#' \pkg{cograph} draws and analyzes networks from a weight matrix, with
#' layouts and styling designed for publication figures and functions for
#' centrality and community detection. Its `cograph_network` class is also
#' the base class of the networks estimated by \pkg{Nestimate}.
#'
#' The `cograph_network` is built from the weight matrix returned by
#' [as_matrix()]: a node table with one row per item and an edge table
#' with one row per non-zero cell, one triangle for an undirected network
#' and every off-diagonal cell for the directed `similarity = "relative"`
#' network. The result can be passed to `cograph::splot()`.
#'
#' \pkg{cograph} exports its own `as_cograph()`. When \pkg{cograph} is
#' attached after \pkg{cooccure}, a bare `as_cograph()` call resolves to the
#' \pkg{cograph} version, which reads the edge data frame with its own
#' defaults. Call `cooccure::as_cograph()`, or build the network with
#' `cooccurrence(..., output = "cograph")`. For a result built with
#' `split_by`, `group` names the network to convert.
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param group For a result built with `split_by`, the name of the group to
#'   convert. `NULL` (default) for an unsplit result.
#' @param ... Ignored.
#' @return A list of class `cograph_network` holding the weight matrix
#'   (`weights`), a node table (one row per item: `id`, `label`, `name`, `x`,
#'   `y`), an edge table (one row per edge: integer `from` and `to` node ids
#'   and `weight`), `directed` (`TRUE` only for `similarity = "relative"`),
#'   and the node and edge counts.
#' @section Conditions:
#'   `cooccure_missing_package` when \pkg{cograph} is not installed; the
#'   conditions of [as_matrix()] for `group`.
#' @seealso [as_netobject()] for the \pkg{Nestimate} class; [as_igraph()];
#'   [as_matrix()].
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' if (requireNamespace("cograph", quietly = TRUE)) {
#'   cooccure::as_cograph(net)
#' }
#' @export
as_cograph <- function(x, ...) UseMethod("as_cograph")

#' @rdname as_cograph
#' @export
as_cograph.cooccurrence <- function(x, group = NULL, ...) {
  .co_need("cograph")
  x <- .co_select_group(x, group)
  parts <- .co_graph_parts(x)
  structure(
    list(
      weights = parts$weights,
      nodes = parts$nodes,
      edges = parts$edges,
      directed = parts$directed,
      n_nodes = nrow(parts$nodes),
      n_edges = nrow(parts$edges),
      meta = list(source = "cooccure", layout = NULL)
    ),
    class = "cograph_network"
  )
}


#' Convert a co-occurrence network to a Nestimate netobject
#'
#' @description
#' `as_netobject()` converts a co-occurrence network to a \pkg{Nestimate}
#' `netobject`. \pkg{Nestimate} estimates and compares networks of several
#' kinds (transition, partial correlation, co-occurrence) and stores them as
#' `netobject`s, which its centrality and comparison functions accept; the
#' conversion lets a co-occurrence network sit beside networks estimated
#' there.
#'
#' The `netobject` has method `"cooccurrence"` and is built from the weight
#' matrix returned by [as_matrix()], with the same node and edge
#' tables as [as_cograph()] and the similarity, scale, threshold and number
#' of transactions recorded as parameters. It is directed only for
#' `similarity = "relative"`.
#'
#' The netobject carries no raw data (its `data` element is `NULL`), so
#' \pkg{Nestimate} functions that resample the original observations, such
#' as `Nestimate::bootstrap_network()`, cannot run on it. Build the network
#' with `Nestimate::cooccurrence()` for those. For a result built with
#' `split_by`, `group` names the network to convert.
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param group For a result built with `split_by`, the name of the group to
#'   convert. `NULL` (default) for an unsplit result.
#' @param ... Ignored.
#' @return A list of class `c("netobject", "cograph_network")` with method
#'   `"cooccurrence"`, holding the weight matrix, a node table (one row per
#'   item), an edge table (one row per edge), `directed`, and the parameters
#'   used.
#' @section Conditions:
#'   `cooccure_missing_package` when \pkg{Nestimate} is not installed; the
#'   conditions of [as_matrix()] for `group`.
#' @seealso [as_cograph()]; [as_igraph()]; [as_matrix()].
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' if (requireNamespace("Nestimate", quietly = TRUE)) {
#'   Nestimate::net_centrality(as_netobject(net))
#' }
#' @export
as_netobject <- function(x, ...) UseMethod("as_netobject")

#' @rdname as_netobject
#' @export
as_netobject.cooccurrence <- function(x, group = NULL, ...) {
  .co_need("Nestimate")
  x <- .co_select_group(x, group)
  parts <- .co_graph_parts(x)
  structure(
    list(
      data = NULL,
      weights = parts$weights,
      nodes = parts$nodes,
      edges = parts$edges,
      directed = parts$directed,
      method = "cooccurrence",
      params = list(
        similarity = attr(x, "similarity"),
        scale = attr(x, "scale"),
        threshold = attr(x, "threshold"),
        n_transactions = attr(x, "n_transactions")
      ),
      scaling = NULL,
      threshold = attr(x, "threshold"),
      n_nodes = nrow(parts$nodes),
      n_edges = nrow(parts$edges),
      level = NULL,
      meta = list(source = "cooccure", layout = NULL,
                  tna = list(method = "cooccurrence")),
      node_groups = NULL
    ),
    class = c("netobject", "cograph_network")
  )
}


#' Weight matrix, node table and edge table shared by the cograph and
#' Nestimate converters.
#'
#' An undirected network lists each pair once (upper triangle); a directed
#' one lists every non-zero off-diagonal cell, so both directions of a
#' `relative` pair survive.
#' @noRd
.co_graph_parts <- function(x) {
  mat <- as_matrix(x, type = "normalized")
  items <- colnames(mat)
  directed <- .co_is_directed(x)
  nodes_df <- data.frame(
    id = seq_along(items), label = items, name = items,
    x = NA_real_, y = NA_real_, stringsAsFactors = FALSE
  )
  cells <- if (directed) row(mat) != col(mat) else upper.tri(mat)
  idx <- which(cells & mat != 0, arr.ind = TRUE)
  edges_df <- data.frame(
    from = as.integer(idx[, 1]),
    to = as.integer(idx[, 2]),
    weight = as.numeric(mat[idx]),
    stringsAsFactors = FALSE
  )
  list(weights = mat, nodes = nodes_df, edges = edges_df,
       directed = directed)
}
