# ---- S3 methods for cooccurrence ----

#' Print a co-occurrence network
#'
#' @description
#' `print()` shows a co-occurrence network as a short diagnostic header
#' followed by the strongest edges. The header reports what is first looked
#' at in any network before its edges are read: how many items and edges
#' it has, how dense it is, which similarity, counting and scaling produced
#' the weights, how many items are isolated, and which items are the hubs.
#'
#' For a network built with `split_by`, the pooled density and degree are
#' omitted, since they are undefined when several networks are stacked; use
#' [summary.cooccurrence()] for one row of metrics per group. A directed
#' network (`similarity = "relative"`) is marked as such and its density is
#' computed over ordered pairs.
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param n Number of edges to show (default 10).
#' @param ... Ignored.
#' @return `x`, invisibly and unchanged. Called for the printed output.
#' @seealso [summary.cooccurrence()] for network, node and group metrics;
#'   [as.data.frame.cooccurrence()] for the edge and node tables.
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard")
#' print(net, n = 5)
#' @export
print.cooccurrence <- function(x, n = 10L, ...) {
  s <- .co_summary_data(x)

  cat(sprintf("# cooccurrence: %d nodes, %d %sedges", s$n_nodes, s$n_edges,
              if (s$directed) "directed " else ""))
  if (!s$is_split) {
    cat(sprintf(" | density: %.4f | mean degree: %.4f",
                s$density, s$mean_degree))
  }
  if (!is.null(s$n_transactions)) {
    cat(sprintf(" | %d transactions", s$n_transactions))
  }
  cat("\n")
  if (!is.null(s$split_by)) {
    cat(sprintf("# split_by: %s (%d groups)\n", s$split_by, length(s$groups)))
  }
  if (!is.null(s$aggregate_by)) {
    cat(sprintf("# aggregate_by: %s (%d groups, %s)\n",
                s$aggregate_by, length(s$groups), s$aggregate))
  }
  cat(sprintf("# similarity: %s | counting: %s",
              s$similarity %||% "none", s$counting %||% "full"))
  if (!is.null(s$scale) && s$scale != "none") {
    cat(sprintf(" | scale: %s", s$scale))
  }
  cat("\n")
  if (s$is_split) {
    cat(sprintf("# isolates: %d | per-group metrics: summary()\n", s$isolates))
  } else {
    cat(sprintf("# possible edges: %.0f | isolates: %d\n",
                s$possible_edges, s$isolates))
    if (s$n_edges > 0L) {
      top <- utils::head(s$nodes[s$nodes$degree > 0L, ], 5L)
      cat(sprintf("# top nodes: %s\n",
                  paste(sprintf("%s(deg=%d,str=%.4g)", top$node, top$degree,
                                top$strength),
                        collapse = ", ")))
    }
  }

  show <- min(n, s$n_edges)
  if (show > 0L) {
    print(utils::head(as.data.frame(x), show), row.names = FALSE)
    if (s$n_edges > show)
      cat(sprintf("# ... %d more edges\n", s$n_edges - show))
  } else {
    cat("# (no edges)\n")
  }
  invisible(x)
}


#' Network, node and group metrics of one cooccurrence object.
#'
#' A `split_by` result stacks one network per group, so the same node pair
#' can appear once per group. Pooled simple-graph metrics are undefined
#' there (density would exceed 1, degree would exceed n - 1): they are NA,
#' the node table is computed within each group, and the group table
#' carries one row of metrics per group.
#' @noRd
.co_summary_data <- function(object) {
  cols <- .co_edge_columns(object)
  is_split <- .co_is_split(object)
  directed <- .co_is_directed(object)
  items <- sort(unique(c(attr(object, "items"), cols$from, cols$to)))
  n_nodes <- length(items)
  n_edges <- nrow(object)

  ## Ordered pairs for a directed network, unordered otherwise.
  possible_edges <- if (is_split) {
    NA_real_
  } else if (directed) {
    n_nodes * (n_nodes - 1)
  } else {
    n_nodes * (n_nodes - 1) / 2
  }
  density <- if (is_split || !(possible_edges > 0)) NA_real_ else
    n_edges / possible_edges

  node_stats <- if (is_split) {
    .co_split_node_table(object)
  } else {
    .co_node_table(cols, items, attr(object, "frequencies"))
  }
  isolates <- if (is_split) {
    length(setdiff(items, c(cols$from, cols$to)))
  } else {
    sum(node_stats$degree == 0L)
  }

  out <- list(
    n_nodes = n_nodes,
    n_edges = n_edges,
    possible_edges = possible_edges,
    density = density,
    mean_degree = if (is_split || n_nodes == 0L) {
      NA_real_
    } else {
      2 * n_edges / n_nodes
    },
    isolates = isolates,
    is_split = is_split,
    directed = directed,
    n_transactions = attr(object, "n_transactions"),
    similarity = attr(object, "similarity"),
    counting = attr(object, "counting"),
    scale = attr(object, "scale"),
    threshold = attr(object, "threshold"),
    min_occur = attr(object, "min_occur"),
    split_by = attr(object, "split_by"),
    aggregate_by = attr(object, "aggregate_by"),
    aggregate = attr(object, "aggregate"),
    groups = attr(object, "groups"),
    weight = .co_five_numbers(cols$weight),
    count = .co_five_numbers(cols$count),
    nodes = node_stats,
    groups_summary = if (is_split) .co_group_table(object) else NULL
  )
  class(out) <- "summary.cooccurrence"
  out
}

#' Node table of one network: degree, strength, count strength, frequency.
#'
#' Degree counts incident edges; in a directed network an item's in- and
#' out-edges both count, so degree is the total degree.
#' @noRd
.co_node_table <- function(cols, items, frequencies = NULL) {
  n_nodes <- length(items)
  degree <- stats::setNames(integer(n_nodes), items)
  strength <- stats::setNames(numeric(n_nodes), items)
  count_strength <- stats::setNames(numeric(n_nodes), items)
  if (length(cols$from) > 0L) {
    edge_nodes <- c(cols$from, cols$to)
    deg_tab <- table(edge_nodes)
    degree[names(deg_tab)] <- as.integer(deg_tab)
    strength_tab <- rowsum(rep(cols$weight, 2L), edge_nodes, reorder = FALSE)
    count_tab <- rowsum(rep(cols$count, 2L), edge_nodes, reorder = FALSE)
    strength[rownames(strength_tab)] <- as.numeric(strength_tab[, 1])
    count_strength[rownames(count_tab)] <- as.numeric(count_tab[, 1])
  }
  frequency <- stats::setNames(rep(NA_real_, n_nodes), items)
  if (!is.null(frequencies)) {
    known <- intersect(names(frequencies), items)
    frequency[known] <- as.numeric(frequencies[known])
  }
  node_stats <- data.frame(
    node = items,
    degree = as.integer(degree),
    strength = as.numeric(strength),
    count_strength = as.numeric(count_strength),
    frequency = as.numeric(frequency),
    stringsAsFactors = FALSE
  )
  node_stats <- node_stats[order(-node_stats$degree, -node_stats$strength,
                                 node_stats$node), ]
  rownames(node_stats) <- NULL
  node_stats
}

#' Node table of a split result: one row per node per group.
#' @noRd
.co_split_node_table <- function(object) {
  groups <- unique(as.character(object$group))
  tables <- lapply(groups, function(g) {
    rows <- as.character(object$group) == g
    sub_cols <- lapply(.co_edge_columns(object), function(v) v[rows])
    items <- sort(unique(c(attr(object, "group_items")[[g]],
                           sub_cols$from, sub_cols$to)))
    tab <- .co_node_table(sub_cols, items,
                          attr(object, "group_frequencies")[[g]])
    cbind(group = rep(g, nrow(tab)), tab, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, tables)
  rownames(out) <- NULL
  out
}

#' Group table of a split result: one row of network metrics per group.
#' @noRd
.co_group_table <- function(object) {
  group_items <- attr(object, "group_items")
  directed <- .co_is_directed(object)
  groups <- unique(as.character(object$group))
  rows <- lapply(groups, function(g) {
    in_group <- as.character(object$group) == g
    group_cols <- lapply(.co_edge_columns(object), function(v) v[in_group])
    ## Per-group support recorded at split time; a node isolated inside its
    ## group appears in no edge and cannot be recovered from the rows alone.
    nodes <- sort(unique(c(group_items[[g]], group_cols$from, group_cols$to)))
    n_group_nodes <- length(nodes)
    n_group_edges <- sum(in_group)
    group_possible <- n_group_nodes * (n_group_nodes - 1) /
      (if (directed) 1 else 2)
    data.frame(
      group = g,
      n_nodes = n_group_nodes,
      n_edges = n_group_edges,
      possible_edges = group_possible,
      density = if (group_possible > 0) n_group_edges / group_possible else
        NA_real_,
      weight_mean = if (n_group_edges > 0L) mean(group_cols$weight) else
        NA_real_,
      count_sum = if (n_group_edges > 0L) sum(group_cols$count) else 0,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Minimum, quartiles, mean and maximum (NA for an empty vector).
#' @noRd
.co_five_numbers <- function(v) {
  if (length(v) == 0L) {
    return(c(min = NA_real_, q1 = NA_real_, median = NA_real_,
             mean = NA_real_, q3 = NA_real_, max = NA_real_))
  }
  c(min = min(v),
    q1 = stats::quantile(v, 0.25, names = FALSE),
    median = stats::median(v),
    mean = mean(v),
    q3 = stats::quantile(v, 0.75, names = FALSE),
    max = max(v))
}


.co_edge_columns <- function(x) {
  if (all(c("from", "to", "weight", "count") %in% names(x))) {
    return(list(from = as.character(x$from), to = as.character(x$to),
                weight = as.numeric(x$weight), count = as.numeric(x$count)))
  }
  if (all(c("Source", "Target", "Weight", "Count") %in% names(x))) {
    return(list(from = as.character(x$Source), to = as.character(x$Target),
                weight = as.numeric(x$Weight), count = as.numeric(x$Count)))
  }
  .co_abort("Cannot identify edge columns in this cooccurrence object: ",
            "expected from/to/weight/count or Source/Target/Weight/Count.",
            class = "cooccure_bad_input")
}


`%||%` <- function(x, y) if (is.null(x)) y else x


#' Summarize a co-occurrence network
#'
#' @description
#' `summary()` computes the metrics of a co-occurrence network at three
#' levels: the network as a whole (size, density, mean degree, isolates and
#' the distribution of edge weights and counts), each item in it (degree,
#' strength and frequency), and, for a network built with `split_by`, each
#' group. Together these show whether the network is sparse or saturated,
#' which items are hubs, and how groups differ in size and density.
#'
#' The metrics are returned as an object; printing it shows the
#' network-level block. The node and group tables are returned
#' as tidy data frames by [as.data.frame.summary.cooccurrence()], or directly
#' from the network with [as.data.frame.cooccurrence()].
#'
#' For a network built with `split_by`, the frame stacks one network per
#' group, so a pair can occur once per group. Pooled simple-graph metrics
#' (`density`, `mean_degree`, `possible_edges`) are undefined and reported
#' as `NA`; the node table has one row per node per group and the group
#' table carries the per-group values. For the directed
#' `similarity = "relative"` network, density is computed over ordered pairs
#' and degree counts in- and out-edges.
#'
#' @param object A `cooccurrence` edge list from [cooccurrence()].
#' @param ... Ignored.
#' @return An object of class `summary.cooccurrence`: a list of network
#'   metrics (`n_nodes`, `n_edges`, `possible_edges`, `density`,
#'   `mean_degree`, `isolates`), the parameters used, five-number summaries
#'   of the weights and counts, a node table and, for `split_by` results, a
#'   group table. Read the tables with [as.data.frame.summary.cooccurrence()].
#' @seealso [print.summary.cooccurrence()]; [as.data.frame.cooccurrence()];
#'   [plot.cooccurrence()] for the degree distribution.
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard")
#' summary(net)
#'
#' # The node table as a data frame
#' as.data.frame(summary(net), what = "nodes")
#' @export
summary.cooccurrence <- function(object, ...) {
  .co_summary_data(object)
}


#' Print a co-occurrence network summary
#'
#' @description
#' `print()` shows the network-level block of a [summary.cooccurrence()]
#' object: the numbers of nodes, edges and possible edges, density, mean
#' degree, isolates, transactions, the parameters used, the range and mean of
#' the weights and counts, the top nodes by degree, and the largest groups by
#' number of edges. For a `split_by` result the pooled metrics and the
#' top-node line are omitted, since they are undefined for stacked networks.
#'
#' @param x A `summary.cooccurrence` object.
#' @param n Number of top nodes and groups to show (default 5).
#' @param ... Ignored.
#' @return `x`, invisibly and unchanged. Called for the printed output.
#' @seealso [summary.cooccurrence()]; [as.data.frame.summary.cooccurrence()].
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",")
#' print(summary(net), n = 3)
#' @export
print.summary.cooccurrence <- function(x, n = 5L, ...) {
  cat(sprintf("cooccurrence network%s\n",
              if (isTRUE(x$directed)) " (directed)" else ""))
  cat(rep("-", 30), "\n", sep = "")
  cat(sprintf("Nodes          : %d\n", x$n_nodes))
  cat(sprintf("Edges          : %d%s\n", x$n_edges,
              if (x$is_split) " (pooled across groups)" else ""))
  ## Pooled simple-graph metrics are undefined for a split_by result; the
  ## per-group block below reports them correctly instead.
  if (!x$is_split) {
    cat(sprintf("Possible edges : %.0f\n", x$possible_edges))
    cat(sprintf("Density        : %.4f\n", x$density))
    cat(sprintf("Mean degree    : %.4f\n", x$mean_degree))
  }
  cat(sprintf("Isolates       : %d\n", x$isolates))
  if (!is.null(x$n_transactions)) {
    cat(sprintf("Transactions   : %d\n", as.integer(x$n_transactions)))
  }
  if (!is.null(x$split_by)) {
    cat(sprintf("Split by       : %s (%d groups)\n",
                x$split_by, length(x$groups)))
  }
  if (!is.null(x$aggregate_by)) {
    cat(sprintf("Aggregate by   : %s (%d groups, %s)\n",
                x$aggregate_by, length(x$groups), x$aggregate))
  }
  if (!is.null(x$similarity)) {
    cat(sprintf("Similarity     : %s\n", x$similarity))
  }
  if (!is.null(x$counting)) {
    cat(sprintf("Counting       : %s\n", x$counting))
  }
  if (!is.null(x$scale) && x$scale != "none") {
    cat(sprintf("Scale          : %s\n", x$scale))
  }

  if (x$n_edges > 0L) {
    cat(sprintf("Weight range   : [%.4g, %.4g]\n",
                x$weight[["min"]], x$weight[["max"]]))
    cat(sprintf("Weight mean    : %.4g\n", x$weight[["mean"]]))
    cat(sprintf("Count range    : [%.4g, %.4g]\n",
                x$count[["min"]], x$count[["max"]]))
    cat(sprintf("Count mean     : %.4g\n", x$count[["mean"]]))

    ## Node degree is per group when split_by is used, so a pooled top-node
    ## line would mix groups; the group block below is shown instead.
    if (!x$is_split) {
      top <- utils::head(x$nodes[x$nodes$degree > 0L, ], as.integer(n))
      if (nrow(top) > 0L) {
        cat(sprintf("Top nodes      : %s\n",
                    paste(sprintf("%s(%d, %.4g)", top$node, top$degree,
                                  top$strength),
                          collapse = ", ")))
      }
    }
  }

  if (!is.null(x$groups_summary) && nrow(x$groups_summary) > 0L) {
    show <- utils::head(x$groups_summary[order(-x$groups_summary$n_edges,
                                               x$groups_summary$group), ],
                        as.integer(n))
    cat("Groups         : ")
    cat(paste(sprintf("%s(%d nodes, %d edges, %.4f density)",
                      show$group, show$n_nodes, show$n_edges, show$density),
              collapse = ", "))
    cat("\n")
  }

  invisible(x)
}


#' Extract the tables of a co-occurrence network summary
#'
#' @description
#' `as.data.frame()` returns the node table or the group table of a
#' [summary.cooccurrence()] object as a plain data frame, so the metrics can
#' be sorted, filtered, joined or plotted with ordinary data-frame tools.
#'
#' @param x A `summary.cooccurrence` object.
#' @param row.names,optional Unused; present for compatibility with the
#'   [base::as.data.frame()] generic.
#' @param what `"nodes"` (default) for the node table, or `"groups"` for the
#'   group table of a `split_by` result.
#' @param ... Ignored.
#' @return A base `data.frame`.
#'   For `what = "nodes"`, one row per node (per node and group for a
#'   `split_by` result, with a leading `group` column), sorted by degree and
#'   strength (both decreasing) and then name, with columns `node`, `degree`
#'   (number of incident edges), `strength` (sum of incident edge weights),
#'   `count_strength` (sum of incident raw counts) and `frequency` (number of
#'   transactions containing the node; `NA` when not stored, as for
#'   `aggregate_by` and weighted results).
#'   For `what = "groups"`, one row per group with columns `group`,
#'   `n_nodes`, `n_edges`, `possible_edges`, `density`, `weight_mean` and
#'   `count_sum`; zero rows when the network was not split.
#' @seealso [summary.cooccurrence()]; [as.data.frame.cooccurrence()], which
#'   returns the same tables directly from the network.
#' @examples
#' by_decade <- cooccurrence(movies, field = "genres", sep = ",",
#'                           split_by = "decade", similarity = "jaccard")
#' as.data.frame(summary(by_decade), what = "groups")
#' @export
as.data.frame.summary.cooccurrence <- function(x, row.names = NULL,
                                               optional = FALSE,
                                               what = c("nodes", "groups"),
                                               ...) {
  what <- match.arg(what)
  if (what == "nodes") return(x$nodes)
  if (is.null(x$groups_summary)) {
    return(data.frame(group = character(0), n_nodes = integer(0),
                      n_edges = integer(0), possible_edges = numeric(0),
                      density = numeric(0), weight_mean = numeric(0),
                      count_sum = numeric(0), stringsAsFactors = FALSE))
  }
  x$groups_summary
}


#' Extract the tables of a co-occurrence network
#'
#' @description
#' `as.data.frame()` returns a table of a co-occurrence network as a plain
#' data frame without the network's attributes, ready for sorting, joining,
#' plotting or writing to a file. A co-occurrence network is described by
#' two tables: its edges, one row per pair of items with a weight and a raw
#' count, and its nodes, one row per item with degree, strength and
#' frequency. A network built with `split_by` adds a third, one row of
#' metrics per group.
#'
#' `what` selects the table. The edge table is the printed network; the node
#' and group tables are those of [summary.cooccurrence()].
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param row.names,optional Unused; present for compatibility with the
#'   [base::as.data.frame()] generic.
#' @param what `"edges"` (default), `"nodes"` or `"groups"`.
#' @param ... Ignored.
#' @return A base `data.frame`.
#'   For `what = "edges"`, one row per edge with columns `from`, `to`,
#'   `weight` and `count` (and `group` for a `split_by` result), in the order
#'   printed. An undirected network has one row per pair; the directed
#'   `similarity = "relative"` network has one row per direction.
#'   For `what = "nodes"` and `what = "groups"`, the tables described in
#'   [as.data.frame.summary.cooccurrence()].
#' @seealso [summary.cooccurrence()]; [as_matrix()] for the weight matrix.
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' as.data.frame(net)
#' as.data.frame(net, what = "nodes")
#' @export
as.data.frame.cooccurrence <- function(x, row.names = NULL, optional = FALSE,
                                       what = c("edges", "nodes", "groups"),
                                       ...) {
  what <- match.arg(what)
  if (what != "edges")
    return(as.data.frame(.co_summary_data(x), what = what))
  out <- data.frame(unclass(x)[names(x)], stringsAsFactors = FALSE,
                    check.names = FALSE)
  rownames(out) <- NULL
  out
}


#' Plot a co-occurrence network
#'
#' @description
#' `plot()` draws one of three displays of a co-occurrence network: a heatmap
#' of the weight matrix (default), a network drawing through \pkg{igraph}, or
#' the degree distribution as a bar chart. The heatmap shows which item pairs
#' carry the heaviest weights and which never co-occur. The network drawing
#' places linked items near one another. The degree distribution shows
#' whether connectivity is concentrated on a few hub items or spread evenly.
#'
#' The heatmap uses
#' a white-to-blue scale for non-negative weights and a red-white-blue scale
#' centered on zero when weights can be negative (`scale = "zscore"`); rows
#' are the source items, which matters for the directed
#' `similarity = "relative"` network.
#'
#' For a result built with `split_by`, `group` names the network to draw.
#' For publication-quality network drawings, convert with [as_cograph()] and
#' use `cograph::splot()`.
#'
#' @param x A `cooccurrence` edge list from [cooccurrence()].
#' @param type `"heatmap"` (default), `"network"` (requires \pkg{igraph}), or
#'   `"degree"`.
#' @param group For a result built with `split_by`, the name of the group to
#'   draw. `NULL` (default) for an unsplit result.
#' @param ... Passed to `graphics::image()` for the heatmap, `plot()` on the
#'   `igraph` object for the network, and `graphics::barplot()` for the
#'   degree distribution, where they override the defaults (for instance
#'   `col` or `main`).
#' @return `x`, invisibly and unchanged. Called for the plot drawn on the
#'   current graphics device.
#' @section Conditions:
#'   `cooccure_grouped_input` when `x` was built with `split_by` and `group`
#'   is `NULL`; `cooccure_missing_package` for `type = "network"` without
#'   \pkg{igraph}.
#' @seealso [as_cograph()] for publication network drawings;
#'   [summary.cooccurrence()] for the numbers behind the degree plot.
#' @examples
#' net <- cooccurrence(movies, field = "genres", sep = ",",
#'                     similarity = "jaccard", min_occur = 50)
#' plot(net)
#' plot(net, type = "degree")
#' @export
plot.cooccurrence <- function(x, type = c("heatmap", "network", "degree"),
                              group = NULL, ...) {
  type <- match.arg(type)
  net <- .co_select_group(x, group)

  if (type == "network") {
    .co_need("igraph", "for network plots")
    plot(as_igraph(net), ...)
  } else if (type == "degree") {
    s <- .co_summary_data(net)
    degree_counts <- table(factor(s$nodes$degree,
                                  levels = seq.int(0L, max(c(0L, s$nodes$degree)))))
    args <- list(
      height = as.numeric(degree_counts),
      names.arg = names(degree_counts),
      xlab = "Degree",
      ylab = "Number of nodes",
      main = "Degree distribution",
      col = "#56B4E9",
      border = "#000000"
    )
    dots <- list(...)
    args[names(dots)] <- dots
    do.call(graphics::barplot, args)
  } else {
    ## Go through as_matrix() so sparse attributes get densified consistently.
    mat <- as_matrix(net)
    n <- nrow(mat)
    args <- list(
      x = seq_len(n), y = seq_len(n), z = t(mat[rev(seq_len(n)), , drop = FALSE]),
      xlab = "", ylab = "", axes = FALSE
    )
    args <- c(args, .co_heatmap_scale(mat))
    dots <- list(...)
    args[names(dots)] <- dots
    do.call(graphics::image, args)
    graphics::axis(1, at = seq_len(n), labels = colnames(mat),
                   las = 2, cex.axis = 0.7)
    graphics::axis(2, at = seq_len(n), labels = rev(rownames(mat)),
                   las = 2, cex.axis = 0.7)
  }

  invisible(x)
}

#' Colors and limits for the heatmap.
#'
#' Non-negative weights run from white (absent) to blue; weights that can be
#' negative get the house diverging scale, red (#D33F6A) through white to
#' blue (#4A6FE3), with limits symmetric about zero so white means zero.
#' @noRd
.co_heatmap_scale <- function(mat) {
  rng <- range(c(0, mat), finite = TRUE)
  if (rng[1] < 0) {
    lim <- max(abs(rng))
    list(col = grDevices::colorRampPalette(c("#D33F6A", "#FFFFFF",
                                             "#4A6FE3"))(101),
         zlim = c(-lim, lim))
  } else {
    list(col = grDevices::colorRampPalette(c("#FFFFFF", "#4A6FE3"))(100),
         zlim = c(0, if (rng[2] > 0) rng[2] else 1))
  }
}
