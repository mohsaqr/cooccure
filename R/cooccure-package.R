#' cooccure: co-occurrence networks from many kinds of data
#'
#' @description
#' `cooccure` builds co-occurrence networks, in which two items are linked
#' when they appear in the same transaction: the keywords of one article, the
#' genres of one film, the actors of one cast, or the states of one learning
#' session. The network shows which items tend to go together and how a
#' field, a corpus or a set of sessions is organized around them. The weight
#' of a link starts as the number of shared transactions; because frequent
#' items co-occur often by chance alone, it can be normalized for item
#' frequency by one of eight similarity measures (van Eck & Waltman, 2009),
#' and each transaction's contribution can be counted fractionally
#' (Perianes-Rodriguez et al., 2016) or with a position decay. One network can
#' be built per group (`split_by`) or one network pooled over groups
#' (`aggregate_by`).
#'
#' All of this is done by one function, [cooccurrence()]. It reads delimited
#' columns, long (item, transaction) tables, binary and one-hot tables, wide
#' sequences, lists of vectors and raw event logs, with sliding windows over
#' ordered sequences and eight scalings of the weights, and returns the
#' network as a tidy edge list.
#'
#' @section Results:
#' The edge list prints with a diagnostic header. [summary.cooccurrence()]
#' computes network, node and group metrics; [as.data.frame.cooccurrence()]
#' returns the edge, node and group tables; [plot.cooccurrence()] draws a
#' heatmap, a network or the degree distribution.
#'
#' @section Conversion:
#' [as_matrix()] returns the weight or count matrix; [as_igraph()],
#' [as_tidygraph()], [as_cograph()] and [as_netobject()] convert to the
#' graph classes of \pkg{igraph}, \pkg{tidygraph}, \pkg{cograph} and
#' \pkg{Nestimate}. The network is undirected except for
#' `similarity = "relative"`, which is directed.
#'
#' @section Data:
#' [movies], [actors] and [actor_genres] are drawn from the IMDb
#' non-commercial datasets; [demo] is a small hand-built cast table.
#' [launch_app()] opens an interactive explorer.
#'
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
#' @keywords internal
"_PACKAGE"
