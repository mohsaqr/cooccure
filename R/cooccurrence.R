# ---- Co-occurrence Network Construction ----

# TraMineR/tna void markers
.void_markers <- c("%", "*", "", "NA", "NaN")

#' Build a co-occurrence network
#'
#' @description
#' `cooccurrence()` builds a co-occurrence network; `co()` is a short alias.
#' In a co-occurrence network two items are linked when they appear in the
#' same transaction: keywords assigned to the same article, genres of the
#' same film, actors in the same cast, states visited in the same session or
#' the same window of a sequence. The edge weight starts as the number of
#' transactions shared by the two items. Because frequent items co-occur
#' with almost everything, the counts are usually normalized by a similarity
#' measure that compares the observed co-occurrence with the items' own
#' frequencies (van Eck & Waltman, 2009), and transactions with many items
#' can be down-weighted by fractional counting (Perianes-Rodriguez et al.,
#' 2016).
#'
#' The transactions are read from a delimited column, a long (item,
#' transaction) table, a binary or one-hot table, wide sequences, a list of
#' vectors, or a raw event log. Eight similarity measures, three counting
#' methods, eight scalings, sliding windows over ordered sequences, and
#' per-group networks (`split_by`) or pooled ones (`aggregate_by`) are
#' available. Every measure except `"relative"` gives an undirected network;
#' `"relative"` divides each row by its sum, so its edges have a direction.
#'
#' The network is returned as a tidy edge list with the weight (after
#' similarity, scaling and filtering) and the raw count of each pair: it
#' shows which items go together, how strongly, and, with `split_by`, how
#' this differs across groups.
#'
#' The edge list converts to a matrix with [as_matrix()] and to graph objects
#' with [as_igraph()], [as_tidygraph()], [as_cograph()] and [as_netobject()];
#' [summary.cooccurrence()] and [as.data.frame.cooccurrence()] give network,
#' node and group metrics.
#'
#' @param data Input data, one of:
#'   * a data frame with a delimited column (`field` and `sep`);
#'   * a long data frame with one row per item and transaction (`field` and
#'     `by`), optionally weighted (`weight_by`);
#'   * a binary (0/1 or `TRUE`/`FALSE`) data frame or matrix, detected
#'     automatically;
#'   * a one-hot or count table, with `vars` naming the indicator columns;
#'   * a wide sequence data frame or matrix, one row per sequence
#'     (`field = "all"`);
#'   * a list of character vectors, one per transaction;
#'   * a raw event log (`action`, with `actor`, `time`, `session`);
#'   * a `nestimate_data` object from `Nestimate::prepare()`.
#' @param field The item column. For delimited input, the column split by
#'   `sep` (several columns are pooled per row); for long input, the item
#'   column; `"all"` for wide sequence data, where every column is a time
#'   point.
#' @param by For long input, the column identifying the transaction.
#' @param sep Separator for delimited input.
#' @param weight_by For long input, a numeric column giving each item's
#'   weight in its transaction, so that \eqn{C_{ij} = \sum_d w_{id} w_{jd}}
#'   (for instance topic probabilities per document). Requires
#'   `counting = "full"`.
#' @param split_by A column of `data`. One network is built per group and the
#'   edge lists are stacked with a `group` column.
#' @param similarity Normalization of the counts \eqn{C_{ij}} by the item
#'   frequencies \eqn{f_i}:
#'   * `"none"` (default): the counts;
#'   * `"jaccard"`: \eqn{C_{ij} / (f_i + f_j - C_{ij})};
#'   * `"cosine"` (Salton): \eqn{C_{ij} / \sqrt{f_i f_j}};
#'   * `"inclusion"` (Simpson): \eqn{C_{ij} / \min(f_i, f_j)};
#'   * `"association"` (association strength): \eqn{C_{ij} / (f_i f_j)};
#'   * `"dice"`: \eqn{2 C_{ij} / (f_i + f_j)};
#'   * `"equivalence"`: \eqn{C_{ij}^2 / (f_i f_j)};
#'   * `"relative"`: \eqn{C_{ij} / \sum_k C_{ik}}, each row summing to 1.
#'     The only asymmetric measure: the network is directed and the edge
#'     list holds one row per direction.
#' @param counting How each transaction contributes to a pair:
#'   * `"full"` (default): 1 per transaction containing both items;
#'   * `"fractional"`: \eqn{1 / (n - 1)} for a transaction of \eqn{n}
#'     items, so large transactions weigh less per pair;
#'   * `"attention"`: \eqn{\exp(-|p_i - p_j| / \lambda)}, decaying with the
#'     distance between the two items' positions in an ordered transaction.
#'     A repeated item keeps the position of its first occurrence.
#' @param scale Rescaling of the weights after similarity: `NULL` or
#'   `"none"` (default), `"minmax"` (to \eqn{[0, 1]}), `"log"`
#'   (\eqn{\log(1 + w)}), `"log10"`, `"binary"` (1 for every edge),
#'   `"zscore"`, `"sqrt"`, or `"proportion"` (divided by the sum).
#' @param threshold Minimum edge weight to keep, applied after similarity
#'   and scaling, to each direction separately for `"relative"`. The default
#'   `0` keeps every edge. A negative value keeps weights at or above it,
#'   which is useful with `scale = "zscore"`.
#' @param min_occur Items in fewer than `min_occur` transactions are dropped
#'   before counting (default 1).
#' @param top_n Keep the `top_n` heaviest edges (default `NULL`, all). Ties
#'   at the cut are truncated. Applied per group with `split_by`.
#' @param output `"default"` for the edge list; `"gephi"` for the same edges
#'   with Gephi column names; `"igraph"`, `"cograph"` or `"matrix"` for the
#'   result of [as_igraph()], [as_cograph()] or [as_matrix()]. The last three
#'   need an unsplit network.
#' @param vars The indicator columns of a one-hot or count table, given like
#'   `select` in [base::subset()]: names, a range (`A:D`), positions, a
#'   negative selection (`-c(id, note)`) or a logical mask. Other columns are
#'   ignored. Any non-zero, non-missing value counts as presence.
#' @param actor,action,time,session,order Columns of a raw event log: who
#'   acted, the event, its timestamp, an explicit session, and a tie-breaking
#'   order. With `action`, the log is cut into sessions by
#'   `Nestimate::prepare()` and each session becomes an ordered transaction.
#' @param time_threshold Gap in seconds that starts a new session (default
#'   900). `Inf` keeps one sequence per actor.
#' @param group Alias for `split_by`.
#' @param aggregate_by A column of `data`. One network is built per group
#'   and the edge weights are combined by `aggregate` into one network.
#'   `threshold` and `top_n` apply after combining. Cannot be combined with
#'   `split_by`.
#' @param aggregate `"sum"` (default), `"mean"`, `"min"` or `"max"`: how
#'   `aggregate_by` combines weights. Counts are always summed.
#' @param window Sliding-window size (an integer of at least 2) for ordered
#'   input (wide sequences, a list of vectors, an event log): each window of
#'   `window` consecutive positions is a transaction. `NULL` (default) uses
#'   the whole sequence.
#' @param lambda Decay rate for `counting = "attention"` (default 1); larger
#'   values decay more slowly.
#' @param ... Must be empty: an unknown or misspelled argument raises an
#'   error.
#'
#' @return With `output = "default"`, a data frame of class
#'   `c("cooccurrence", "data.frame")` with one row per edge, sorted by
#'   weight (largest first), and columns `from` and `to` (item names),
#'   `weight` (after similarity, scaling and filtering) and `count`
#'   (transactions containing both items; summed over groups for
#'   `aggregate_by`). An undirected network has one row per pair; the
#'   directed `"relative"` network has one row per direction. With
#'   `split_by`, one row per edge per group and a `group` column. Read the
#'   tables with [as.data.frame.cooccurrence()] and the matrix with
#'   [as_matrix()].
#'
#'   `output = "gephi"` gives the same edges with columns `Source`,
#'   `Target`, `Weight`, `Type` (`"Undirected"` or `"Directed"`) and
#'   `Count`. `"igraph"`, `"cograph"` and `"matrix"` return the converter's
#'   result.
#' @section Conditions:
#'   Errors inherit from `cooccure_error`:
#'   * `cooccure_bad_input` for an invalid argument value, a missing column,
#'     or an input whose format cannot be detected;
#'   * `cooccure_incompatible_args` for arguments that cannot be combined:
#'     `split_by` with `aggregate_by`, `weight_by` with `window` or with
#'     `counting` other than `"full"`, `vars` with `field`, `by` or `sep`,
#'     `window` with unordered input, event-log columns without `action`;
#'   * `cooccure_grouped_input` for `output = "igraph"`, `"cograph"` or
#'     `"matrix"` with `split_by`;
#'   * `cooccure_empty_input` when no transaction or item remains, or when
#'     no group produces an edge;
#'   * `cooccure_missing_package` for event-log input without
#'     \pkg{Nestimate}.
#'
#'   With `split_by` or `aggregate_by`, a group left with no transaction is
#'   dropped; any other error in a group is raised with the group named.
#' @references
#' van Eck, N. J., & Waltman, L. (2009). How to normalize cooccurrence
#' data? An analysis of some well-known similarity measures. *Journal of
#' the American Society for Information Science and Technology*, 60(8),
#' 1635--1651. \doi{10.1002/asi.21075}
#'
#' Perianes-Rodriguez, A., Waltman, L., & van Eck, N. J. (2016).
#' Constructing bibliometric networks: A comparison between full and
#' fractional counting. *Journal of Informetrics*, 10(4), 1178--1195.
#' \doi{10.1016/j.joi.2016.10.006}
#'
#' Saqr, M., Lopez-Pernas, S., Conde, M. A., & Hernandez-Garcia, A. (2024).
#' Social network analysis: A primer, a guide and a tutorial in R. In M. Saqr
#' & S. Lopez-Pernas (Eds.), *Learning Analytics Methods and Tutorials: A
#' Practical Guide Using R*. Springer. \doi{10.1007/978-3-031-54464-4_15}
#' @seealso [as.data.frame.cooccurrence()] and [summary.cooccurrence()] for
#'   tables and metrics; [as_matrix()], [as_igraph()], [as_cograph()] and
#'   [as_netobject()] for conversion; [plot.cooccurrence()]; [movies] and
#'   [actors] for example data.
#' @examples
#' # Genres linked by the films they share (delimited column)
#' cooccurrence(movies, field = "genres", sep = ",", similarity = "jaccard")
#'
#' # Actors linked by shared films (long table)
#' co(actors, field = "actor", by = "tconst", min_occur = 3)
#'
#' # One network per decade
#' cooccurrence(movies, field = "genres", sep = ",", split_by = "decade",
#'              similarity = "jaccard", top_n = 3)
#'
#' # A directed network: the share of each genre's links going to each other
#' cooccurrence(movies, field = "genres", sep = ",", similarity = "relative",
#'              min_occur = 100)
#'
#' # Adjacent states of ordered sequences
#' seqs <- list(c("plan", "read", "write", "read", "review"),
#'              c("read", "write", "write", "review"))
#' cooccurrence(seqs, window = 2)
#'
#' # Weighted long table (topic probabilities per document)
#' theta <- data.frame(
#'   doc   = c("d1", "d1", "d1", "d2", "d2", "d3", "d3"),
#'   topic = c("T1", "T2", "T3", "T1", "T3", "T2", "T3"),
#'   prob  = c(0.6, 0.3, 0.1, 0.4, 0.6, 0.5, 0.5)
#' )
#' cooccurrence(theta, field = "topic", by = "doc", weight_by = "prob")
#'
#' # One-hot table with an id column
#' onehot <- data.frame(doc = c("d1", "d2", "d3"),
#'                      A = c(1, 0, 1), B = c(1, 1, 0), C = c(0, 1, 1))
#' cooccurrence(onehot, vars = A:C)
#'
#' # Raw event log, cut into sessions by Nestimate
#' \donttest{
#' if (requireNamespace("Nestimate", quietly = TRUE)) {
#'   events <- data.frame(
#'     student = rep(c("s1", "s2"), each = 3),
#'     code    = c("read", "write", "read", "test", "write", "read"),
#'     stamp   = as.POSIXct("2026-01-01 09:00:00", tz = "UTC") +
#'       c(0, 60, 120, 0, 30, 90)
#'   )
#'   cooccurrence(events, actor = "student", action = "code", time = "stamp")
#' }
#' }
#'
#' @export
## The first thirteen arguments reproduce the CRAN 0.1.1 signature exactly,
## so positional calls written against 0.1.1 keep their meaning. Every
## argument added since is keyword-only in practice, appended after them.
cooccurrence <- function(data, field = NULL, by = NULL, sep = NULL,
                         weight_by = NULL,
                         split_by = NULL,
                         similarity = c("none", "jaccard", "cosine",
                                        "inclusion", "association",
                                        "dice", "equivalence", "relative"),
                         counting = c("full", "fractional", "attention"),
                         scale = NULL,
                         threshold = 0, min_occur = 1L,
                         top_n = NULL,
                         output = c("default", "gephi", "igraph",
                                    "cograph", "matrix"),
                         vars = NULL,
                         actor = NULL, action = NULL, time = NULL,
                         session = NULL, order = NULL, time_threshold = 900,
                         group = NULL,
                         aggregate_by = NULL,
                         aggregate = c("sum", "mean", "min", "max"),
                         window = NULL,
                         lambda = 1.0, ...) {
  ## An unknown argument used to be swallowed silently by `...`, so a typo
  ## such as `simliarity = "jaccard"` returned raw counts with no warning.
  .co_check_dots(...)
  similarity <- match.arg(similarity)
  counting <- match.arg(counting)
  output <- match.arg(output)
  aggregate <- match.arg(aggregate)
  ## `threshold` may be negative: a centring scale such as z-score gives
  ## negative weights, and a negative cut keeps edges above it. Zero keeps
  ## its documented meaning of "no filtering".
  if (!(is.numeric(threshold) && length(threshold) == 1L &&
        is.finite(threshold)))
    .co_abort("`threshold` must be a single finite number.")
  if (!(is.numeric(min_occur) && length(min_occur) == 1L &&
        is.finite(min_occur) && min_occur >= 1))
    .co_abort("`min_occur` must be a single number of at least 1.")
  if (!is.null(top_n) && !(is.numeric(top_n) && length(top_n) == 1L &&
                           is.finite(top_n) && top_n >= 1))
    .co_abort("`top_n` must be NULL or a single number of at least 1.")
  if (!(is.numeric(lambda) && length(lambda) == 1L && is.finite(lambda) &&
        lambda > 0))
    .co_abort("`lambda` must be a single positive number.")
  threshold <- as.numeric(threshold)
  min_occur <- as.integer(min_occur)
  if (!is.null(group)) {
    if (!is.null(split_by) && !identical(split_by, group))
      .co_abort("`group` is an alias for `split_by`; supply only one value.",
                class = "cooccure_incompatible_args")
    split_by <- group
  }
  if (!is.null(window)) {
    if (!(is.numeric(window) && length(window) == 1L && is.finite(window) &&
          window >= 2))
      .co_abort("`window` must be NULL or a single integer of at least 2.")
    window <- as.integer(window)
  }
  if (!is.null(aggregate_by) && !is.null(split_by))
    .co_abort("`aggregate_by` and `split_by` cannot be combined.",
              class = "cooccure_incompatible_args")
  if (!is.null(weight_by) && !is.null(window))
    .co_abort("`window` is not compatible with `weight_by`.",
              class = "cooccure_incompatible_args")
  ## Fractional and attention counting reweight each transaction's pairs
  ## from its item count or item positions; a weighted long table already
  ## carries its own per-item weights, so the two cannot be combined. They
  ## used to be ignored silently, giving full-counting weights.
  if (!is.null(weight_by) && counting != "full")
    .co_abort("`counting = \"", counting, "\"` cannot be combined with ",
              "`weight_by`: the weights already define each item's ",
              "contribution. Use `counting = \"full\"` with `weight_by`.",
              class = "cooccure_incompatible_args")
  if (!is.null(split_by) && output %in% c("igraph", "cograph", "matrix"))
    .co_abort("`output = \"", output, "\"` builds one network, but ",
              "`split_by` returns one network per group. Build the edge list ",
              "first and convert one group with `as_", output,
              "(x, group = ...)`.",
              class = "cooccure_grouped_input")
  ## `vars` is resolved like base R's subset(select = ): bare ranges
  ## (a:c), positions (1:8), negatives (-id), and character vectors all work.
  vars <- .co_resolve_vars(substitute(vars), data, parent.frame())
  if (!is.null(vars)) {
    if (length(vars) < 2L)
      .co_abort("`vars` must name at least two indicator columns.")
    if (!is.null(field) || !is.null(by) || !is.null(sep))
      .co_abort("`vars` names indicator columns directly and cannot be ",
                "combined with `field`, `by`, or `sep`.",
                class = "cooccure_incompatible_args")
  }

  ## Raw event-log input: sessionize first, then continue down the ordinary
  ## wide-sequence path. Sessionization (timestamp parsing, gap splitting)
  ## is delegated to Nestimate::prepare() rather than reimplemented here.
  if (!is.null(action)) {
    data <- .co_prepare_events(data, actor = actor, action = action,
                               time = time, session = session, order = order,
                               time_threshold = time_threshold)
    field <- "all"
  } else if (!is.null(actor) || !is.null(time) || !is.null(session)) {
    .co_abort("`actor`, `time`, and `session` describe raw event data and ",
              "require `action` naming the event column.",
              class = "cooccure_incompatible_args")
  }
  .co_check_columns(data, field, by, weight_by)

  if (is.null(scale) || identical(scale, "none")) {
    scale_method <- "none"
  } else {
    scale_method <- match.arg(scale, c("none", "minmax", "log", "log10",
                                       "binary", "zscore", "sqrt",
                                       "proportion"))
  }
  directed <- identical(similarity, "relative")

  core_args <- list(field = field, by = by, sep = sep, vars = vars,
                    weight_by = weight_by, similarity = similarity,
                    counting = counting, scale_method = scale_method,
                    min_occur = min_occur, window = window, lambda = lambda)

  # ---- split_by: compute per group, combine ----
  if (!is.null(split_by)) {
    .co_check_group_column(data, split_by, "split_by")
    groups <- split(data, data[[split_by]])
    parts <- lapply(names(groups), function(g) {
      sub <- groups[[g]]
      # Drop the split_by column so it doesn't interfere with format detection
      sub[[split_by]] <- NULL
      edges <- .co_core_group(sub, g, core_args, threshold = threshold,
                              top_n = top_n)
      if (is.null(edges) || nrow(edges) == 0L) return(NULL)
      edges$group <- g
      edges
    })
    kept <- !vapply(parts, is.null, logical(1))
    ## Per-group node support, captured before the parts are stacked. A node
    ## that is isolated within its group appears in no edge, so it cannot be
    ## recovered from the combined frame afterwards.
    group_items <- lapply(parts[kept], function(p) attr(p, "items"))
    group_freq <- lapply(parts[kept], function(p) attr(p, "frequencies"))
    names(group_items) <- names(group_freq) <- names(groups)[kept]
    group_tx <- vapply(parts[kept],
                       function(p) as.integer(attr(p, "n_transactions") %||% NA),
                       integer(1))
    names(group_tx) <- names(groups)[kept]

    parts <- parts[kept]
    if (length(parts) == 0L)
      .co_abort("No group produced any edges.",
                class = "cooccure_empty_input")
    edges <- do.call(rbind, parts)
    rownames(edges) <- NULL

    ## rbind() carries the FIRST part's attributes onto the stacked frame,
    ## so the combined object would otherwise advertise group 1's matrix,
    ## items, and frequencies as if they described the whole result.
    for (a in c("matrix", "raw_matrix", "items", "frequencies",
                "n_transactions", "n_items", "counting", "lambda"))
      attr(edges, a) <- NULL

    class(edges) <- c("cooccurrence", "data.frame")
    attr(edges, "similarity") <- similarity
    attr(edges, "scale") <- scale_method
    attr(edges, "threshold") <- threshold
    attr(edges, "min_occur") <- min_occur
    attr(edges, "counting") <- if (is.null(weight_by)) counting else "weighted"
    attr(edges, "lambda") <- lambda
    attr(edges, "directed") <- directed
    attr(edges, "split_by") <- split_by
    ## Only groups that actually contributed edges, not every input level.
    attr(edges, "groups") <- names(groups)[kept]
    attr(edges, "group_items") <- group_items
    attr(edges, "group_frequencies") <- group_freq
    attr(edges, "group_transactions") <- group_tx
    return(.co_format_output(edges, output))
  }

  # ---- aggregate_by: per-group compute, then combine into one network ----
  if (!is.null(aggregate_by)) {
    .co_check_group_column(data, aggregate_by, "aggregate_by")
    groups <- split(data, data[[aggregate_by]])
    parts <- lapply(names(groups), function(g) {
      sub <- groups[[g]]
      sub[[aggregate_by]] <- NULL
      ## Defer threshold/top_n to after aggregation; per-group filtering
      ## would distort the global combine.
      .co_core_group(sub, g, core_args, threshold = 0, top_n = NULL)
    })
    kept <- !vapply(parts, is.null, logical(1))
    parts <- parts[kept]
    if (length(parts) == 0L)
      .co_abort("No group produced any edges.",
                class = "cooccure_empty_input")

    edges <- .co_aggregate_parts(parts, aggregate, threshold, top_n)

    items <- sort(unique(unlist(lapply(parts, attr, "items"))))
    n_items <- length(items)
    M <- .co_edges_to_sparse(edges, items, directed = directed)
    ## The raw matrix holds the summed counts, not the aggregated weights.
    M_raw <- .co_count_sparse(edges, items)

    n_trans <- sum(vapply(parts, function(p) {
      v <- attr(p, "n_transactions")
      if (is.null(v) || is.na(v)) 0L else as.integer(v)
    }, integer(1)))

    class(edges) <- c("cooccurrence", "data.frame")
    attr(edges, "matrix")         <- M
    attr(edges, "raw_matrix")     <- M_raw
    attr(edges, "items")          <- items
    attr(edges, "frequencies")    <- NULL
    attr(edges, "similarity")     <- similarity
    attr(edges, "scale")          <- scale_method
    attr(edges, "threshold")      <- threshold
    attr(edges, "min_occur")      <- min_occur
    attr(edges, "counting")       <- if (is.null(weight_by)) counting else "weighted"
    attr(edges, "lambda")         <- lambda
    attr(edges, "directed")       <- directed
    attr(edges, "n_transactions") <- n_trans
    attr(edges, "n_items")        <- n_items
    attr(edges, "aggregate_by")   <- aggregate_by
    attr(edges, "aggregate")      <- aggregate
    attr(edges, "groups")         <- names(groups)[kept]
    return(.co_format_output(edges, output))
  }

  # ---- Single-group path ----
  result <- do.call(.co_core, c(list(data = data), core_args,
                                list(threshold = threshold, top_n = top_n)))

  .co_format_output(result, output)
}


#' @rdname cooccurrence
#' @export
co <- cooccurrence


#' Check a `split_by` / `aggregate_by` column.
#' @noRd
.co_check_group_column <- function(data, column, arg) {
  if (!is.data.frame(data))
    .co_abort("`", arg, "` requires a data frame input.")
  if (!(is.character(column) && length(column) == 1L &&
        column %in% names(data)))
    .co_abort("`", arg, "` must name one column of `data`.")
  invisible(NULL)
}

#' Run the core pipeline on one group of a split or aggregated input.
#'
#' A group with no transaction or no item left is a legitimate outcome of
#' splitting (a small decade, a rare journal) and returns NULL, so the group
#' is dropped. Any other failure is a real error: it is re-raised with the
#' group named, keeping its class, rather than turned into an empty network.
#' @noRd
.co_core_group <- function(sub, g, core_args, threshold, top_n) {
  tryCatch(
    do.call(.co_core, c(list(data = sub), core_args,
                        list(threshold = threshold, top_n = top_n))),
    cooccure_empty_input = function(e) NULL,
    error = function(e) {
      specific <- if (inherits(e, "cooccure_error")) class(e)[1L] else
        "cooccure_bad_input"
      .co_abort("Group '", g, "': ", conditionMessage(e), class = specific)
    }
  )
}


# ---- Core pipeline (used by both single and split_by paths) ----

#' @noRd
.co_core <- function(data, field, by, sep, vars = NULL, weight_by = NULL, similarity,
                     counting, scale_method, threshold, min_occur, top_n,
                     window = NULL, lambda = 1.0) {
  # Parse input
  fmt <- .co_detect_format(data, field, by, sep, vars)

  # Weighted path — long format only
  if (!is.null(weight_by)) {
    if (fmt != "long")
      .co_abort("`weight_by` is only supported for long format (field + by).",
           class = "cooccure_incompatible_args")
    return(.co_core_weighted(data, field, by, weight_by, similarity,
                             scale_method, threshold, min_occur, top_n))
  }

  transactions <- .co_parse_transactions(data, fmt, field, by, sep, window,
                                         vars)

  # Drop empty transactions
  keep_tx <- vapply(transactions, length, integer(1)) > 0L
  transactions <- transactions[keep_tx]
  if (length(transactions) == 0L)
    .co_abort("No non-empty transactions found in the input data.",
           class = "cooccure_empty_input")

  # min_occur filter
  if (min_occur > 1L) {
    freq_table <- table(unlist(transactions))
    keep <- names(freq_table[freq_table >= min_occur])
    transactions <- lapply(transactions, function(t) t[t %in% keep])
    keep_tx <- vapply(transactions, length, integer(1)) > 0L
    transactions <- transactions[keep_tx]
    if (length(transactions) == 0L)
      .co_abort("No transactions remain after min_occur filtering.",
           class = "cooccure_empty_input")
  }

  # Build sparse bipartite matrix (works x items) with counting weights baked in
  sp <- .co_build_sparse(transactions, counting, lambda = lambda)
  n_trans <- sp$n
  n_items <- sp$k
  items <- sp$items

  # Counting-weighted co-occurrence (sparse k x k). For "attention" the
  # pair contribution depends on the positional GAP, not on a per-item
  # weight, so we cannot factor it through B + crossprod — `.co_build_sparse`
  # builds C directly in that case.
  C <- if (counting == "attention") sp$C else Matrix::crossprod(sp$B)
  # Raw binary co-occurrence (sparse k x k) for the count column and frequencies
  C_raw <- Matrix::crossprod(sp$B_bin)
  freq <- as.numeric(Matrix::colSums(sp$B_bin))
  names(freq) <- items

  # Zero diagonals (self co-occurrence is not an edge)
  Matrix::diag(C) <- 0
  Matrix::diag(C_raw) <- 0
  C <- Matrix::drop0(C)
  C_raw <- Matrix::drop0(C_raw)

  result <- .co_finalize(C, C_raw, freq, n_trans, n_items, items,
                         similarity, scale_method, threshold, min_occur,
                         top_n)
  attr(result, "counting") <- counting
  attr(result, "lambda") <- lambda

  result
}


# ---- Shared finalization: normalize -> scale -> threshold -> edges -> stamp ----

#' Finalize edges from sparse co-occurrence matrices.
#'
#' Operates on triplets throughout — never materializes a dense k x k matrix.
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
    W_sparse <- .co_edges_to_sparse(edges, items,
                                    directed = similarity == "relative")
  } else {
    ## Raw counts at the same positions. Non-zero pattern of C and C_raw is
    ## identical (both are crossprods of binaries with the same support), so
    ## [cbind(i, j)] indexing returns counts aligned with c_vals.
    raw_vals <- as.integer(C_raw[cbind(i, j)])

    ## Similarity normalization on triplets.
    if (similarity == "none") {
      W_x <- c_vals
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
      }
    }

    ## Edge triplets. Every measure except 'relative' is symmetric, so one
    ## row per unordered pair describes the network. 'relative' is
    ## asymmetric (W[i, j] = C[i, j] / rowSums(C)[i]), so it keeps one row
    ## per DIRECTION: a pair contributes i -> j and j -> i with their own
    ## weights and the same raw count, and the network is directed.
    if (similarity == "relative") {
      e_i <- ii; e_j <- jj; e_w <- W_full_x; e_c <- c(raw_vals, raw_vals)
    } else {
      e_i <- i; e_j <- j; e_w <- W_x; e_c <- raw_vals
    }

    ## Threshold filter on edge weights, one direction at a time for
    ## 'relative'. `threshold = 0` is the default and means "no filtering",
    ## NOT "drop negative weights": scalings such as z-score centre weights
    ## on zero, and filtering at the default would silently discard half of
    ## that network. A negative threshold keeps weights at or above it.
    if (threshold != 0) {
      keep <- e_w >= threshold
      e_i <- e_i[keep]; e_j <- e_j[keep]; e_w <- e_w[keep]; e_c <- e_c[keep]
    }

    edges <- data.frame(
      from   = items[e_i],
      to     = items[e_j],
      weight = e_w,
      count  = e_c,
      stringsAsFactors = FALSE
    )
    edges <- edges[order(-edges$weight), ]

    if (!is.null(top_n)) {
      top_n <- as.integer(top_n)
      if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
    }

    ## Rebuild the stored matrix from the surviving edges so that
    ## as_matrix(), the heatmap, and the converters agree with the edge
    ## list. Previously W_sparse was built pre-filter, so `top_n = 1`
    ## printed one edge while as_matrix() still held all of them.
    W_sparse <- .co_edges_to_sparse(edges, items,
                                    directed = similarity == "relative")
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
  attr(edges, "directed")       <- identical(similarity, "relative")

  edges
}


# ---- Weighted core (long format with per-entity weights) ----

#' @noRd
.co_core_weighted <- function(data, field, by, weight_by, similarity,
                               scale_method, threshold, min_occur, top_n) {
  stopifnot(
    "`data` must be a data frame" = is.data.frame(data),
    "`field`, `by` and `weight_by` must each name one column of `data`" =
      all(vapply(list(field, by, weight_by),
                 function(v) length(v) == 1L && v %in% names(data),
                 logical(1)))
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

  ## Binary companion for raw counts, built over the FULL item set so its
  ## column indices stay valid; it is filtered alongside W below. Building
  ## it after filtering would leave `item_idx` pointing past the new dims.
  B_bin <- Matrix::sparseMatrix(
    i = doc_idx, j = item_idx, x = 1,
    dims = c(length(all_docs), length(all_items)),
    dimnames = list(NULL, all_items)
  )
  ## sparseMatrix sums duplicates — clip to {0, 1} for the binary matrix.
  B_bin <- Matrix::drop0(sign(B_bin))

  if (min_occur > 1L) {
    ## Support is the number of distinct documents an item appears in, not
    ## the number of rows mentioning it: duplicate (doc, item) rows must not
    ## inflate it. The clipped binary matrix gives exactly that.
    n_docs_per_item <- as.numeric(Matrix::colSums(B_bin))
    keep_items <- n_docs_per_item >= min_occur
    W <- W[, keep_items, drop = FALSE]
    B_bin <- B_bin[, keep_items, drop = FALSE]
    all_items <- all_items[keep_items]
  }

  if (ncol(W) == 0L)
    .co_abort("No items remain after min_occur filtering.",
           class = "cooccure_empty_input")

  n_trans <- nrow(W)
  n_items <- ncol(W)
  freq <- as.numeric(Matrix::colSums(W))
  names(freq) <- all_items

  C_raw <- Matrix::crossprod(B_bin)
  C     <- Matrix::crossprod(W)
  Matrix::diag(C) <- 0
  Matrix::diag(C_raw) <- 0
  C     <- Matrix::drop0(C)
  C_raw <- Matrix::drop0(C_raw)

  result <- .co_finalize(C, C_raw, freq, n_trans, n_items, all_items,
                         similarity, scale_method, threshold, min_occur,
                         top_n)
  attr(result, "counting") <- "weighted"
  result
}


# ---- Scaling (triplet-based) ----

#' Apply a post-normalization scaling to edge weights.
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
.co_detect_format <- function(data, field, by, sep, vars = NULL) {
  ## `vars` names the indicator columns explicitly, so no detection is needed
  ## and columns that are not indicators (ids, timestamps) are simply ignored.
  if (!is.null(vars)) {
    if (!is.data.frame(data) && !is.matrix(data))
      .co_abort("`vars` requires a data frame or matrix input.")
    missing_vars <- setdiff(vars, colnames(data))
    if (length(missing_vars))
      .co_abort("`vars` column(s) not found in the data: ",
           paste(missing_vars, collapse = ", "), ".")
    return("indicator")
  }

  ## A `nestimate_data` object from Nestimate::prepare() is a list, so it
  ## would otherwise fall into the "list of transactions" branch below and
  ## silently produce nonsense items from its internal components.
  if (inherits(data, "nestimate_data"))
    return("nestimate")

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
    ## Logical columns are indicators too, but as.matrix() keeps them
    ## logical and is.numeric() is FALSE for a logical matrix.
    if (is.data.frame(data) && all(vapply(data, is.logical, logical(1))))
      return("binary")
    mat <- if (is.data.frame(data)) as.matrix(data) else data
    if (is.logical(mat)) return("binary")
    if (is.numeric(mat) && all(mat[!is.na(mat)] %in% c(0, 1)))
      return("binary")
    .co_abort("Cannot detect input format. Use `field = \"all\"` for wide ",
         "sequence data, or `vars = c(...)` to name the indicator columns ",
         "of a one-hot / count table (needed when the table also holds id ",
         "or metadata columns, or when cell values are counts rather than ",
         "0/1).")
  }

  .co_abort("Cannot detect input format. Provide field/by/sep arguments or a ",
       "recognized data structure (data.frame, matrix, list).")
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

#' Parse transactions for the detected input format.
#' @noRd
.co_parse_transactions <- function(data, fmt, field, by, sep, window = NULL,
                                   vars = NULL) {
  ## Nestimate::prepare() already produced sessionized wide sequences, so
  ## unwrap to its $sequence_data and continue down the ordinary wide path
  ## rather than duplicating its sessionization here.
  if (fmt == "nestimate") {
    seqs <- data$sequence_data
    if (is.null(seqs))
      .co_abort("This looks like a `nestimate_data` object but it has no ",
           "`sequence_data` component.")
    return(.co_parse_transactions(seqs, "wide", field, by, sep, window, NULL))
  }

  if (!is.null(window)) {
    if (fmt == "indicator")
      .co_abort("`window` needs ordered sequence input; an indicator table has ",
           "no within-row order.",
           class = "cooccure_incompatible_args")
    if (!fmt %in% c("wide", "list"))
      .co_abort("`window` only applies to ordered sequence formats: a list of ",
           "vectors, or a wide data frame with field = \"all\".",
           class = "cooccure_incompatible_args")
    return(if (fmt == "wide") {
      .co_parse_wide_windowed(data, window)
    } else {
      .co_parse_list_windowed(data, window)
    })
  }

  if (fmt == "field_only")
    .co_warn_missing_sep(data, field)

  switch(fmt,
    delimited       = .co_parse_delimited(data, field, sep),
    multi_delimited = .co_parse_multi_delimited(data, field, sep),
    field_only      = .co_parse_field_only(data, field),
    long            = .co_parse_long(data, field, by),
    binary          = .co_parse_binary(data),
    indicator       = .co_parse_indicator(data, vars),
    wide            = .co_parse_wide(data),
    list            = .co_parse_list(data)
  )
}


#' Transactions from explicitly named indicator columns.
#'
#' `vars` names the one-hot / count columns; every other column (ids,
#' timestamps, metadata) is ignored. Values are read as presence: any
#' non-zero, non-NA value marks the item present, so count tables such as
#' document-term matrices work as well as 0/1 and TRUE/FALSE. `NA` is
#' treated as absent, consistent with the void handling in the sequence
#' parsers.
#' @noRd
.co_parse_indicator <- function(data, vars) {
  sub <- if (is.data.frame(data)) data[, vars, drop = FALSE] else
    data[, vars, drop = FALSE]
  bad <- vars[!vapply(as.data.frame(sub), function(v)
    is.numeric(v) || is.logical(v), logical(1))]
  if (length(bad))
    .co_abort("`vars` column(s) are not numeric or logical: ",
         paste(bad, collapse = ", "),
         ". Indicator columns must hold 0/1, counts, or TRUE/FALSE.")
  mat <- as.matrix(as.data.frame(sub))
  if (any(!is.na(mat) & mat < 0))
    .co_abort("`vars` columns contain negative values; indicator columns must ",
         "be non-negative.")
  present <- !is.na(mat) & mat != 0
  lapply(seq_len(nrow(present)), function(i) vars[present[i, ]])
}

#' Rebuild a list of per-row character vectors from a flat token vector.
#'
#' Splits `flat` (already trimmed and NA-cleaned) back into a list of length
#' `n`, honouring the original row lengths via the accompanying `row_idx`.
#' Rows whose tokens were all dropped appear as `character(0)`. Per-row
#' deduplication is done globally via `duplicated()` on a two-column frame,
#' which is faster than calling `unique()` once per row.
#'
#' @noRd
.co_relist_unique <- function(flat, row_idx, n) {
  if (length(flat) == 0L) return(rep(list(character(0)), n))

  ## Global dedup: at most one (row, item) pair.
  dup <- duplicated(data.frame(row_idx, flat, stringsAsFactors = FALSE))
  flat <- flat[!dup]
  row_idx <- row_idx[!dup]

  ## split() by a factor with the full level range preserves empty rows.
  out <- split(flat, factor(row_idx, levels = seq_len(n)))
  names(out) <- NULL
  out
}

#' @noRd
.co_parse_delimited <- function(data, field, sep) {
  stopifnot(
    "`data` must be a data frame" = is.data.frame(data),
    "`field` must name one column of `data`" =
      length(field) == 1L && field %in% names(data)
  )
  vals <- as.character(data[[field]])
  n <- length(vals)

  ## strsplit returns a list; flatten once so `trimws` and filtering run as
  ## vectorized C loops over the full token population rather than 166k
  ## per-row R calls (that per-row path was ~48% of total runtime).
  splits <- strsplit(vals, sep, fixed = TRUE)
  lens <- lengths(splits)
  if (sum(lens) == 0L) return(rep(list(character(0)), n))

  flat <- trimws(unlist(splits, use.names = FALSE))
  row_idx <- rep.int(seq_len(n), lens)
  keep <- !is.na(flat) & nzchar(flat)
  flat <- flat[keep]; row_idx <- row_idx[keep]

  .co_relist_unique(flat, row_idx, n)
}

#' @noRd
.co_parse_multi_delimited <- function(data, field, sep) {
  stopifnot(
    "`data` must be a data frame" = is.data.frame(data),
    "every `field` must be a column of `data`" = all(field %in% names(data))
  )
  n <- nrow(data)

  ## Split each column independently, concatenate with aligned row indices,
  ## then run the same flat trim + dedup as `.co_parse_delimited`.
  parts <- lapply(field, function(f) {
    splits <- strsplit(as.character(data[[f]]), sep, fixed = TRUE)
    lens <- lengths(splits)
    list(
      row_idx = rep.int(seq_len(n), lens),
      flat    = unlist(splits, use.names = FALSE)
    )
  })
  row_idx <- unlist(lapply(parts, `[[`, "row_idx"), use.names = FALSE)
  flat    <- unlist(lapply(parts, `[[`, "flat"),    use.names = FALSE)
  if (length(flat) == 0L) return(rep(list(character(0)), n))

  flat <- trimws(flat)
  keep <- !is.na(flat) & nzchar(flat)
  flat <- flat[keep]; row_idx <- row_idx[keep]

  .co_relist_unique(flat, row_idx, n)
}

#' @noRd
.co_parse_field_only <- function(data, field) {
  stopifnot(
    "`data` must be a data frame" = is.data.frame(data),
    "every `field` must be a column of `data`" = all(field %in% names(data))
  )
  lapply(seq_len(nrow(data)), function(i) {
    vals <- as.character(unlist(data[i, field, drop = TRUE]))
    vals <- trimws(vals)
    vals <- vals[!is.na(vals) & nzchar(vals)]
    unique(vals)
  })
}

#' @noRd
.co_parse_long <- function(data, field, by) {
  stopifnot(
    "`data` must be a data frame" = is.data.frame(data),
    "`field` must name one column of `data`" =
      length(field) == 1L && field %in% names(data),
    "`by` must name one column of `data`" =
      length(by) == 1L && by %in% names(data)
  )
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
  ## `mat[i, ] == 1` yields NA for missing cells, which used to reach
  ## Matrix::sparseMatrix() as an NA index and fail with an internal error.
  ## NA means "not present", matching the void handling in the sequence
  ## parsers.
  present <- !is.na(mat) & mat == 1
  lapply(seq_len(nrow(present)), function(i) cn[present[i, ]])
}


#' Resolve a `vars` column specification to column names.
#'
#' Uses the same mechanism as base R's `subset(select = )`: the expression is
#' evaluated in a frame that maps each column name to its position, so bare
#' ranges (`a:c`), positions (`1:8`), negative selection (`-id`), `c(a, b)`,
#' and plain character vectors all resolve. Falls back to the caller's
#' environment, so a pre-built character vector variable works too.
#' @noRd
.co_resolve_vars <- function(vars_expr, data, env) {
  if (is.null(vars_expr)) return(NULL)
  ## Checked here rather than in .co_detect_format() because resolution
  ## needs column names, so it must fail first and with the right message.
  if (!is.data.frame(data) && !is.matrix(data))
    .co_abort("`vars` requires a data frame or matrix input.")
  nm <- colnames(data)
  if (is.null(nm))
    .co_abort("`vars` requires input with column names.")
  ## Evaluate with column names bound to positions; unbound symbols fall
  ## through to the caller, so `vars = my_states` still works.
  pos <- as.list(seq_along(nm))
  names(pos) <- nm
  idx <- tryCatch(eval(vars_expr, pos, env),
                  error = function(e)
                    .co_abort("`vars` could not be resolved to columns: ",
                         conditionMessage(e)))
  if (is.null(idx)) return(NULL)
  if (is.logical(idx)) {
    if (length(idx) != length(nm))
      .co_abort("A logical `vars` must have one entry per column (", length(nm),
           ").")
    return(nm[idx])
  }
  if (is.numeric(idx)) {
    if (any(idx < 0) && any(idx > 0))
      .co_abort("`vars` cannot mix positive and negative positions.")
    out <- nm[idx]
    if (anyNA(out)) {
      bad <- idx[is.na(out)]
      .co_abort("`vars` position(s) out of range (data has ", length(nm),
           " columns): ", paste(utils::head(bad, 5L), collapse = ", "),
           if (length(bad) > 5L) paste0(", ... (", length(bad), " total)"),
           ".")
    }
    return(unique(out))
  }
  if (is.character(idx)) {
    missing_vars <- setdiff(idx, nm)
    if (length(missing_vars))
      .co_abort("`vars` column(s) not found in the data: ",
           paste(missing_vars, collapse = ", "), ".")
    ## A repeated column would be counted twice by the sparse builder,
    ## inflating both weight and count for every pair involving it.
    return(unique(idx))
  }
  .co_abort("`vars` must resolve to column names, positions, or a logical mask.")
}


#' Sessionize a raw event log into wide sequence data.
#'
#' Delegates to `Nestimate::prepare()`, which owns timestamp parsing (ISO8601,
#' Unix, 40+ formats), tie-breaking, and gap-based session splitting. Returns
#' the wide `sequence_data` frame, which the ordinary `field = "all"` path
#' then consumes.
#' @noRd
.co_prepare_events <- function(data, actor, action, time, session, order,
                               time_threshold) {
  if (!requireNamespace("Nestimate", quietly = TRUE))
    .co_abort("Package 'Nestimate' is required for raw event-log input ",
         "(`action = `). Install it, or sessionize the data yourself and ",
         "pass wide sequences with `field = \"all\"`.",
           class = "cooccure_missing_package")
  if (!is.data.frame(data))
    .co_abort("`action` requires a data frame of event records.")
  if (!is.character(action) || length(action) != 1L || !action %in% names(data))
    .co_abort("`action` must name a single column of `data`.")
  for (arg in list(c("actor", actor), c("time", time), c("session", session),
                   c("order", order))) {
    val <- arg[-1]
    if (length(val) && !all(val %in% names(data)))
      .co_abort("`", arg[1], "` column(s) not found in the data: ",
           paste(setdiff(val, names(data)), collapse = ", "), ".")
  }

  args <- list(data = data, action = action, time = time, session = session,
               order = order, time_threshold = time_threshold)
  ## prepare() treats a missing `actor` as "all rows are one actor".
  if (!is.null(actor)) args$actor <- actor
  prepared <- do.call(Nestimate::prepare, args)
  prepared$sequence_data
}


#' Reject unknown arguments passed through `...`.
#'
#' `cooccurrence()` keeps `...` for signature stability, but silently
#' swallowing unknown names turned a typo such as `simliarity = "jaccard"`
#' into a raw-count network with no warning.
#' @noRd
.co_check_dots <- function(...) {
  extra <- names(list(...))
  if (length(list(...)) == 0L) return(invisible(NULL))
  if (is.null(extra) || any(!nzchar(extra)))
    .co_abort("Unnamed arguments passed to `cooccurrence()`. All optional ",
         "arguments must be named.")
  .co_abort("Unknown argument(s) passed to `cooccurrence()`: ",
       paste(extra, collapse = ", "),
       ". Check for a misspelled argument name.")
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


# ---- Windowed parsers (ordered sequences) ----

#' Sliding-window transactions for one ordered sequence.
#'
#' Drops void markers (NA, "", "%", "*", "NaN") before windowing — voids
#' are not real states. Returns one transaction per window of length
#' \code{window}, deduped within each window. Empty list when the
#' cleaned sequence is shorter than \code{window}.
#' @noRd
.co_window_one <- function(seq, window) {
  seq <- as.character(seq)
  seq <- seq[!is.na(seq) & nzchar(seq) & !(seq %in% .void_markers)]
  if (length(seq) < window) return(list())
  ## embed() returns each window most-recent-first, i.e. REVERSED. That is
  ## harmless for set-based counting but not for `counting = "attention"`,
  ## which reads positional gaps off the transaction, so the row is flipped
  ## back into reading order before dedup.
  W <- stats::embed(seq, window)
  lapply(seq_len(nrow(W)), function(r) unique(rev(W[r, ])))
}

#' @noRd
.co_parse_wide_windowed <- function(data, window) {
  mat <- if (is.data.frame(data)) as.matrix(data) else data
  per_row <- lapply(seq_len(nrow(mat)),
                    function(i) .co_window_one(mat[i, ], window))
  do.call(c, per_row)
}

#' @noRd
.co_parse_list_windowed <- function(data, window) {
  per_seq <- lapply(data, .co_window_one, window = window)
  do.call(c, per_seq)
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
.co_build_sparse <- function(transactions, counting, lambda = 1.0) {
  all_items <- sort(unique(unlist(transactions, use.names = FALSE)))
  n <- length(transactions)
  k <- length(all_items)
  lens <- vapply(transactions, length, integer(1))
  row_idx <- rep.int(seq_len(n), lens)
  col_idx <- match(unlist(transactions, use.names = FALSE), all_items)

  ## Binary bipartite matrix — needed for raw counts and item frequencies
  ## in every counting mode.
  B_bin <- Matrix::sparseMatrix(
    i = row_idx, j = col_idx, x = rep(1.0, length(row_idx)),
    dims = c(n, k),
    dimnames = list(NULL, all_items)
  )

  ## "attention" can't be expressed as a per-row weighted bipartite + crossprod:
  ## the pair contribution is exp(-|pos_i - pos_j| / lambda), a function of
  ## positional GAP, not a product of per-item weights. So we build the
  ## symmetric pair matrix C directly and skip B.
  if (counting == "attention") {
    C <- .co_attention_pairs(transactions, all_items, lambda = lambda)
    return(list(B = NULL, B_bin = B_bin, C = C,
                items = all_items, n = n, k = k))
  }

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

  list(B = B, B_bin = B_bin, items = all_items, n = n, k = k)
}


# ---- Attention pair-decay matrix ----

#' Build the symmetric pair matrix for `counting = "attention"`.
#'
#' For every transaction with n >= 2 items, generate all pair triplets
#' (item_i, item_j, weight) where weight = exp(-|pos_i - pos_j| / lambda).
#' Triplets are concatenated across transactions and fed to
#' `Matrix::sparseMatrix(symmetric = TRUE)`, which sums duplicate (i, j)
#' entries to give the aggregated pair weights.
#'
#' Closer positions → larger weight; distant positions → exponential
#' decay. Matches the `tna::build_model(type = "attention")` semantics
#' but is undirected (we always sum the contribution into the
#' upper-triangle entry; cooccure networks are symmetric by
#' construction).
#'
#' @noRd
.co_attention_pairs <- function(transactions, items, lambda = 1.0) {
  n_items <- length(items)

  ## Per transaction, generate triplets via vectorized triangle-index
  ## construction (avoids utils::combn(), which is recursive R and
  ## materializes a 2 x C(n,2) matrix per call).
  triplets_list <- lapply(transactions, function(t) {
    n <- length(t)
    if (n < 2L) return(NULL)
    pos_i <- rep.int(seq_len(n - 1L), (n - 1L):1L)
    pos_j <- sequence((n - 1L):1L, 2:n)
    weights <- exp(-(pos_j - pos_i) / lambda)
    list(i = match(t[pos_i], items),
         j = match(t[pos_j], items),
         w = weights)
  })
  triplets_list <- triplets_list[!vapply(triplets_list, is.null, logical(1))]

  if (length(triplets_list) == 0L)
    return(.co_sym_sparse(integer(0), integer(0), numeric(0), items))

  ii <- unlist(lapply(triplets_list, `[[`, "i"), use.names = FALSE)
  jj <- unlist(lapply(triplets_list, `[[`, "j"), use.names = FALSE)
  ww <- unlist(lapply(triplets_list, `[[`, "w"), use.names = FALSE)
  .co_sym_sparse(ii, jj, ww, items)
}


# ---- Shared sparse-matrix builder ----

#' Build a symmetric sparse matrix from triplets, normalizing i <= j.
#'
#' `Matrix::sparseMatrix(symmetric = TRUE)` requires entries in one
#' triangle. Callers that arrive with mixed i,j must swap; this helper
#' centralizes the swap and the empty-triplets shortcut so the
#' three places that build symmetric pair matrices
#' (`.co_attention_pairs`, `.co_edges_to_sparse`, plus the empty
#' fallbacks) read as one line.
#' @noRd
.co_sym_sparse <- function(i, j, x, items) {
  n_items <- length(items)
  if (length(i) == 0L) {
    return(Matrix::sparseMatrix(
      i = integer(0), j = integer(0), x = numeric(0),
      dims = c(n_items, n_items), symmetric = TRUE,
      dimnames = list(items, items)
    ))
  }
  swap <- i > j
  if (any(swap)) {
    tmp <- i[swap]; i[swap] <- j[swap]; j[swap] <- tmp
  }
  Matrix::sparseMatrix(
    i = as.integer(i), j = as.integer(j), x = as.numeric(x),
    dims = c(n_items, n_items), symmetric = TRUE,
    dimnames = list(items, items)
  )
}



# ---- aggregate_by helpers ----

#' Combine per-group edge tables into one aggregated table.
#'
#' Stacks the (from, to, weight, count) rows from each group's
#' `cooccurrence` data frame, groups by unordered pair, and reduces
#' the weight column with the chosen aggregator. The count column is
#' always summed (it is a count, not a weight). Threshold and top_n
#' are applied AFTER aggregation so per-group filtering doesn't
#' distort the global combine.
#' @noRd
.co_aggregate_parts <- function(parts, aggregate, threshold, top_n) {
  all_edges <- do.call(rbind, lapply(parts, function(p) {
    p[, c("from", "to", "weight", "count"), drop = FALSE]
  }))
  rownames(all_edges) <- NULL

  if (nrow(all_edges) == 0L) {
    return(data.frame(from = character(0), to = character(0),
                      weight = numeric(0), count = integer(0),
                      stringsAsFactors = FALSE))
  }

  agg_fn <- switch(aggregate,
    sum  = sum, mean = mean, min  = min, max  = max
  )

  ## Group by ordered pair: within each part `from` < `to` for undirected
  ## networks, and each direction is its own key for directed ones.
  key <- paste(all_edges$from, all_edges$to, sep = "\037")
  weight_by_pair <- vapply(split(all_edges$weight, key),
                           agg_fn, numeric(1))
  count_by_pair  <- vapply(split(all_edges$count, key),
                           function(v) as.integer(sum(v)), integer(1))

  uk <- names(weight_by_pair)
  fr_to <- do.call(rbind, strsplit(uk, "\037", fixed = TRUE))
  edges <- data.frame(
    from   = fr_to[, 1],
    to     = fr_to[, 2],
    weight = unname(weight_by_pair),
    count  = unname(count_by_pair),
    stringsAsFactors = FALSE
  )

  if (threshold != 0) edges <- edges[edges$weight >= threshold, ]
  edges <- edges[order(-edges$weight), ]
  if (!is.null(top_n)) {
    top_n <- as.integer(top_n)
    if (nrow(edges) > top_n) edges <- edges[seq_len(top_n), ]
  }
  rownames(edges) <- NULL
  edges
}

#' Build the weight matrix from an edge data frame.
#'
#' Symmetric (one stored triangle) for undirected networks; a general sparse
#' matrix with one cell per directed edge for `similarity = "relative"`.
#' @noRd
.co_edges_to_sparse <- function(edges, items, directed = FALSE) {
  if (!directed) {
    if (nrow(edges) == 0L)
      return(.co_sym_sparse(integer(0), integer(0), numeric(0), items))
    return(.co_sym_sparse(match(edges$from, items),
                          match(edges$to,   items),
                          edges$weight, items))
  }
  Matrix::sparseMatrix(
    i = match(edges$from, items), j = match(edges$to, items),
    x = as.numeric(edges$weight),
    dims = c(length(items), length(items)),
    dimnames = list(items, items)
  )
}

#' Build the symmetric raw-count matrix from an edge data frame.
#'
#' Counts are symmetric even when weights are not, so a directed edge list
#' (both directions of a pair) is reduced to one entry per unordered pair.
#' @noRd
.co_count_sparse <- function(edges, items) {
  if (nrow(edges) == 0L)
    return(.co_sym_sparse(integer(0), integer(0), numeric(0), items))
  fi <- match(edges$from, items)
  ti <- match(edges$to, items)
  lo <- pmin(fi, ti)
  hi <- pmax(fi, ti)
  first <- !duplicated(data.frame(lo, hi))
  .co_sym_sparse(lo[first], hi[first], edges$count[first], items)
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
    out$Type <- if (.co_is_directed(result)) "Directed" else "Undirected"
    # Reorder: Source, Target, Weight, Type, Count, [group]
    cols <- c("Source", "Target", "Weight", "Type", "Count")
    if (has_group) cols <- c(cols, "group")
    out <- out[, cols]
    class(out) <- c("cooccurrence", "data.frame")
    # Copy attributes
    for (a in c("matrix", "raw_matrix", "items", "frequencies",
                "similarity", "scale", "threshold", "min_occur",
                "n_transactions", "n_items", "split_by", "groups",
                "group_items", "group_frequencies", "group_transactions",
                "aggregate_by", "aggregate", "counting", "lambda",
                "directed")) {
      attr(out, a) <- attr(result, a)
    }
    return(out)
  }

  if (output == "igraph") return(as_igraph(result))
  if (output == "cograph") return(as_cograph(result))
  if (output == "matrix") return(as_matrix(result))

  result
}
