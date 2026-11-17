# Build a co-occurrence network

`cooccurrence()` builds a co-occurrence network; `co()` is a short
alias. In a co-occurrence network two items are linked when they appear
in the same transaction: keywords assigned to the same article, genres
of the same film, actors in the same cast, states visited in the same
session or the same window of a sequence. The edge weight starts as the
number of transactions shared by the two items. Because frequent items
co-occur with almost everything, the counts are usually normalized by a
similarity measure that compares the observed co-occurrence with the
items' own frequencies (van Eck & Waltman, 2009), and transactions with
many items can be down-weighted by fractional counting
(Perianes-Rodriguez et al., 2016).

The transactions are read from a delimited column, a long (item,
transaction) table, a binary or one-hot table, wide sequences, a list of
vectors, or a raw event log. Eight similarity measures, three counting
methods, eight scalings, sliding windows over ordered sequences, and
per-group networks (`split_by`) or pooled ones (`aggregate_by`) are
available. Every measure except `"relative"` gives an undirected
network; `"relative"` divides each row by its sum, so its edges have a
direction.

The network is returned as a tidy edge list with the weight (after
similarity, scaling and filtering) and the raw count of each pair: it
shows which items go together, how strongly, and, with `split_by`, how
this differs across groups.

The edge list converts to a matrix with
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
and to graph objects with
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md),
[`as_tidygraph()`](https://pak.dynasite.org/cooccure/reference/as_tidygraph.md),
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and
[`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md);
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
and
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
give network, node and group metrics.

## Usage

``` r
cooccurrence(
  data,
  field = NULL,
  by = NULL,
  sep = NULL,
  weight_by = NULL,
  split_by = NULL,
  similarity = c("none", "jaccard", "cosine", "inclusion", "association", "dice",
    "equivalence", "relative"),
  counting = c("full", "fractional", "attention"),
  scale = NULL,
  threshold = 0,
  min_occur = 1L,
  top_n = NULL,
  output = c("default", "gephi", "igraph", "cograph", "matrix"),
  vars = NULL,
  actor = NULL,
  action = NULL,
  time = NULL,
  session = NULL,
  order = NULL,
  time_threshold = 900,
  group = NULL,
  aggregate_by = NULL,
  aggregate = c("sum", "mean", "min", "max"),
  window = NULL,
  lambda = 1,
  ...
)

co(
  data,
  field = NULL,
  by = NULL,
  sep = NULL,
  weight_by = NULL,
  split_by = NULL,
  similarity = c("none", "jaccard", "cosine", "inclusion", "association", "dice",
    "equivalence", "relative"),
  counting = c("full", "fractional", "attention"),
  scale = NULL,
  threshold = 0,
  min_occur = 1L,
  top_n = NULL,
  output = c("default", "gephi", "igraph", "cograph", "matrix"),
  vars = NULL,
  actor = NULL,
  action = NULL,
  time = NULL,
  session = NULL,
  order = NULL,
  time_threshold = 900,
  group = NULL,
  aggregate_by = NULL,
  aggregate = c("sum", "mean", "min", "max"),
  window = NULL,
  lambda = 1,
  ...
)
```

## Arguments

- data:

  Input data, one of:

  - a data frame with a delimited column (`field` and `sep`);

  - a long data frame with one row per item and transaction (`field` and
    `by`), optionally weighted (`weight_by`);

  - a binary (0/1 or `TRUE`/`FALSE`) data frame or matrix, detected
    automatically;

  - a one-hot or count table, with `vars` naming the indicator columns;

  - a wide sequence data frame or matrix, one row per sequence
    (`field = "all"`);

  - a list of character vectors, one per transaction;

  - a raw event log (`action`, with `actor`, `time`, `session`);

  - a `nestimate_data` object from
    [`Nestimate::prepare()`](https://pak.dynasite.org/Nestimate/reference/prepare.html).

- field:

  The item column. For delimited input, the column split by `sep`
  (several columns are pooled per row); for long input, the item column;
  `"all"` for wide sequence data, where every column is a time point.

- by:

  For long input, the column identifying the transaction.

- sep:

  Separator for delimited input.

- weight_by:

  For long input, a numeric column giving each item's weight in its
  transaction, so that \\C\_{ij} = \sum_d w\_{id} w\_{jd}\\ (for
  instance topic probabilities per document). Requires
  `counting = "full"`.

- split_by:

  A column of `data`. One network is built per group and the edge lists
  are stacked with a `group` column.

- similarity:

  Normalization of the counts \\C\_{ij}\\ by the item frequencies
  \\f_i\\:

  - `"none"` (default): the counts;

  - `"jaccard"`: \\C\_{ij} / (f_i + f_j - C\_{ij})\\;

  - `"cosine"` (Salton): \\C\_{ij} / \sqrt{f_i f_j}\\;

  - `"inclusion"` (Simpson): \\C\_{ij} / \min(f_i, f_j)\\;

  - `"association"` (association strength): \\C\_{ij} / (f_i f_j)\\;

  - `"dice"`: \\2 C\_{ij} / (f_i + f_j)\\;

  - `"equivalence"`: \\C\_{ij}^2 / (f_i f_j)\\;

  - `"relative"`: \\C\_{ij} / \sum_k C\_{ik}\\, each row summing to 1.
    The only asymmetric measure: the network is directed and the edge
    list holds one row per direction.

- counting:

  How each transaction contributes to a pair:

  - `"full"` (default): 1 per transaction containing both items;

  - `"fractional"`: \\1 / (n - 1)\\ for a transaction of \\n\\ items, so
    large transactions weigh less per pair;

  - `"attention"`: \\\exp(-\|p_i - p_j\| / \lambda)\\, decaying with the
    distance between the two items' positions in an ordered transaction.
    A repeated item keeps the position of its first occurrence.

- scale:

  Rescaling of the weights after similarity: `NULL` or `"none"`
  (default), `"minmax"` (to \\\[0, 1\]\\), `"log"` (\\\log(1 + w)\\),
  `"log10"`, `"binary"` (1 for every edge), `"zscore"`, `"sqrt"`, or
  `"proportion"` (divided by the sum).

- threshold:

  Minimum edge weight to keep, applied after similarity and scaling, to
  each direction separately for `"relative"`. The default `0` keeps
  every edge. A negative value keeps weights at or above it, which is
  useful with `scale = "zscore"`.

- min_occur:

  Items in fewer than `min_occur` transactions are dropped before
  counting (default 1).

- top_n:

  Keep the `top_n` heaviest edges (default `NULL`, all). Ties at the cut
  are truncated. Applied per group with `split_by`.

- output:

  `"default"` for the edge list; `"gephi"` for the same edges with Gephi
  column names; `"igraph"`, `"cograph"` or `"matrix"` for the result of
  [`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md),
  [`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
  or
  [`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md).
  The last three need an unsplit network.

- vars:

  The indicator columns of a one-hot or count table, given like `select`
  in [`base::subset()`](https://rdrr.io/r/base/subset.html): names, a
  range (`A:D`), positions, a negative selection (`-c(id, note)`) or a
  logical mask. Other columns are ignored. Any non-zero, non-missing
  value counts as presence.

- actor, action, time, session, order:

  Columns of a raw event log: who acted, the event, its timestamp, an
  explicit session, and a tie-breaking order. With `action`, the log is
  cut into sessions by
  [`Nestimate::prepare()`](https://pak.dynasite.org/Nestimate/reference/prepare.html)
  and each session becomes an ordered transaction.

- time_threshold:

  Gap in seconds that starts a new session (default 900). `Inf` keeps
  one sequence per actor.

- group:

  Alias for `split_by`.

- aggregate_by:

  A column of `data`. One network is built per group and the edge
  weights are combined by `aggregate` into one network. `threshold` and
  `top_n` apply after combining. Cannot be combined with `split_by`.

- aggregate:

  `"sum"` (default), `"mean"`, `"min"` or `"max"`: how `aggregate_by`
  combines weights. Counts are always summed.

- window:

  Sliding-window size (an integer of at least 2) for ordered input (wide
  sequences, a list of vectors, an event log): each window of `window`
  consecutive positions is a transaction. `NULL` (default) uses the
  whole sequence.

- lambda:

  Decay rate for `counting = "attention"` (default 1); larger values
  decay more slowly.

- ...:

  Must be empty: an unknown or misspelled argument raises an error.

## Value

With `output = "default"`, a data frame of class
`c("cooccurrence", "data.frame")` with one row per edge, sorted by
weight (largest first), and columns `from` and `to` (item names),
`weight` (after similarity, scaling and filtering) and `count`
(transactions containing both items; summed over groups for
`aggregate_by`). An undirected network has one row per pair; the
directed `"relative"` network has one row per direction. With
`split_by`, one row per edge per group and a `group` column. Read the
tables with
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
and the matrix with
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md).

`output = "gephi"` gives the same edges with columns `Source`, `Target`,
`Weight`, `Type` (`"Undirected"` or `"Directed"`) and `Count`.
`"igraph"`, `"cograph"` and `"matrix"` return the converter's result.

## Conditions

Errors inherit from `cooccure_error`:

- `cooccure_bad_input` for an invalid argument value, a missing column,
  or an input whose format cannot be detected;

- `cooccure_incompatible_args` for arguments that cannot be combined:
  `split_by` with `aggregate_by`, `weight_by` with `window` or with
  `counting` other than `"full"`, `vars` with `field`, `by` or `sep`,
  `window` with unordered input, event-log columns without `action`;

- `cooccure_grouped_input` for `output = "igraph"`, `"cograph"` or
  `"matrix"` with `split_by`;

- `cooccure_empty_input` when no transaction or item remains, or when no
  group produces an edge;

- `cooccure_missing_package` for event-log input without Nestimate.

With `split_by` or `aggregate_by`, a group left with no transaction is
dropped; any other error in a group is raised with the group named.

## References

van Eck, N. J., & Waltman, L. (2009). How to normalize cooccurrence
data? An analysis of some well-known similarity measures. *Journal of
the American Society for Information Science and Technology*, 60(8),
1635–1651. [doi:10.1002/asi.21075](https://doi.org/10.1002/asi.21075)

Perianes-Rodriguez, A., Waltman, L., & van Eck, N. J. (2016).
Constructing bibliometric networks: A comparison between full and
fractional counting. *Journal of Informetrics*, 10(4), 1178–1195.
[doi:10.1016/j.joi.2016.10.006](https://doi.org/10.1016/j.joi.2016.10.006)

Saqr, M., Lopez-Pernas, S., Conde, M. A., & Hernandez-Garcia, A. (2024).
Social network analysis: A primer, a guide and a tutorial in R. In M.
Saqr & S. Lopez-Pernas (Eds.), *Learning Analytics Methods and
Tutorials: A Practical Guide Using R*. Springer.
[doi:10.1007/978-3-031-54464-4_15](https://doi.org/10.1007/978-3-031-54464-4_15)

## See also

[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
and
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
for tables and metrics;
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md),
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md),
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and
[`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md)
for conversion;
[`plot.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/plot.cooccurrence.md);
[movies](https://pak.dynasite.org/cooccure/reference/movies.md) and
[actors](https://pak.dynasite.org/cooccure/reference/actors.md) for
example data.

## Examples

``` r
# Genres linked by the films they share (delimited column)
cooccurrence(movies, field = "genres", sep = ",", similarity = "jaccard")
#> # cooccurrence: 22 nodes, 129 edges | density: 0.5584 | mean degree: 11.7273 | 1000 transactions
#> # similarity: jaccard | counting: full
#> # possible edges: 231 | isolates: 0
#> # top nodes: Drama(deg=20,str=1.178), Comedy(deg=19,str=0.9227), Action(deg=17,str=1.07), Romance(deg=17,str=0.5551), Adventure(deg=15,str=0.9235)
#>         from          to    weight count
#>    Adventure   Animation 0.2846715    39
#>       Action       Crime 0.2369478    59
#>       Comedy       Drama 0.2111554   159
#>       Action   Adventure 0.2075472    44
#>    Biography Documentary 0.2037037    44
#>        Drama     Romance 0.1975867   131
#>        Crime    Thriller 0.1745283    37
#>       Comedy     Romance 0.1680000    63
#>  Documentary       Music 0.1590909    28
#>    Biography     History 0.1564626    23
#> # ... 119 more edges

# Actors linked by shared films (long table)
co(actors, field = "actor", by = "tconst", min_occur = 3)
#> # cooccurrence: 19 nodes, 7 edges | density: 0.0409 | mean degree: 0.7368 | 47 transactions
#> # similarity: none | counting: full
#> # possible edges: 171 | isolates: 7
#> # top nodes: Dina Pathak(deg=2,str=2), Mukesh(deg=2,str=2), Julia Bache-Wiig(deg=1,str=3), Robin Ottersen(deg=1,str=3), Constantin Fleancu(deg=1,str=2)
#>                from             to weight count
#>    Julia Bache-Wiig Robin Ottersen      3     3
#>  Constantin Fleancu Liliana Mocanu      2     2
#>         Dina Pathak   Harish Magon      1     1
#>         Dina Pathak         Mukesh      1     1
#>           Akash Dev         Rajesh      1     1
#>         Joseph Izzo    Shiyoon Kim      1     1
#>              Mukesh          Vinod      1     1

# One network per decade
cooccurrence(movies, field = "genres", sep = ",", split_by = "decade",
             similarity = "jaccard", top_n = 3)
#> # cooccurrence: 12 nodes, 18 edges
#> # split_by: decade (6 groups)
#> # similarity: jaccard | counting: full
#> # isolates: 0 | per-group metrics: summary()
#>         from        to    weight count group
#>    Adventure Animation 0.5000000     7 1970s
#>        Crime  Thriller 0.4285714     6 1970s
#>    Biography   History 0.3333333     4 1970s
#>  Documentary     Music 0.4444444     4 1980s
#>       Action     Crime 0.2333333     7 1980s
#>    Biography   History 0.2142857     3 1980s
#>    Adventure Animation 0.3333333     5 1990s
#>      History       War 0.3333333     3 1990s
#>       Comedy     Drama 0.2980769    31 1990s
#>       Action Adventure 0.2608696    12 2000s
#> # ... 8 more edges

# A directed network: the share of each genre's links going to each other
cooccurrence(movies, field = "genres", sep = ",", similarity = "relative",
             min_occur = 100)
#> # cooccurrence: 8 nodes, 52 directed edges | density: 0.9286 | mean degree: 13.0000 | 983 transactions
#> # similarity: relative | counting: full
#> # possible edges: 56 | isolates: 0
#> # top nodes: Drama(deg=14,str=3.693), Comedy(deg=14,str=2.29), Biography(deg=14,str=1.978), Crime(deg=14,str=1.75), Adventure(deg=14,str=1.482)
#>         from          to    weight count
#>  Documentary   Biography 0.6875000    44
#>      Romance       Drama 0.6267943   131
#>       Comedy       Drama 0.4847561   159
#>        Crime       Drama 0.4396135    91
#>    Biography       Drama 0.4244604    59
#>    Adventure      Action 0.3492063    44
#>       Action       Drama 0.3380952    71
#>    Biography Documentary 0.3165468    44
#>      Romance      Comedy 0.3014354    63
#>        Drama      Comedy 0.2875226   159
#> # ... 42 more edges

# Adjacent states of ordered sequences
seqs <- list(c("plan", "read", "write", "read", "review"),
             c("read", "write", "write", "review"))
cooccurrence(seqs, window = 2)
#> # cooccurrence: 4 nodes, 4 edges | density: 0.6667 | mean degree: 2.0000 | 7 transactions
#> # similarity: none | counting: full
#> # possible edges: 6 | isolates: 0
#> # top nodes: read(deg=3,str=5), write(deg=2,str=4), review(deg=2,str=2), plan(deg=1,str=1)
#>    from     to weight count
#>    read  write      3     3
#>    plan   read      1     1
#>    read review      1     1
#>  review  write      1     1

# Weighted long table (topic probabilities per document)
theta <- data.frame(
  doc   = c("d1", "d1", "d1", "d2", "d2", "d3", "d3"),
  topic = c("T1", "T2", "T3", "T1", "T3", "T2", "T3"),
  prob  = c(0.6, 0.3, 0.1, 0.4, 0.6, 0.5, 0.5)
)
cooccurrence(theta, field = "topic", by = "doc", weight_by = "prob")
#> # cooccurrence: 3 nodes, 3 edges | density: 1.0000 | mean degree: 2.0000 | 3 transactions
#> # similarity: none | counting: weighted
#> # possible edges: 3 | isolates: 0
#> # top nodes: T3(deg=2,str=0.58), T1(deg=2,str=0.48), T2(deg=2,str=0.46)
#>  from to weight count
#>    T1 T3   0.30     2
#>    T2 T3   0.28     2
#>    T1 T2   0.18     1

# One-hot table with an id column
onehot <- data.frame(doc = c("d1", "d2", "d3"),
                     A = c(1, 0, 1), B = c(1, 1, 0), C = c(0, 1, 1))
cooccurrence(onehot, vars = A:C)
#> # cooccurrence: 3 nodes, 3 edges | density: 1.0000 | mean degree: 2.0000 | 3 transactions
#> # similarity: none | counting: full
#> # possible edges: 3 | isolates: 0
#> # top nodes: A(deg=2,str=2), B(deg=2,str=2), C(deg=2,str=2)
#>  from to weight count
#>     A  B      1     1
#>     A  C      1     1
#>     B  C      1     1

# Raw event log, cut into sessions by Nestimate
# \donttest{
if (requireNamespace("Nestimate", quietly = TRUE)) {
  events <- data.frame(
    student = rep(c("s1", "s2"), each = 3),
    code    = c("read", "write", "read", "test", "write", "read"),
    stamp   = as.POSIXct("2026-01-01 09:00:00", tz = "UTC") +
      c(0, 60, 120, 0, 30, 90)
  )
  cooccurrence(events, actor = "student", action = "code", time = "stamp")
}
#> # cooccurrence: 3 nodes, 3 edges | density: 1.0000 | mean degree: 2.0000 | 2 transactions
#> # similarity: none | counting: full
#> # possible edges: 3 | isolates: 0
#> # top nodes: read(deg=2,str=3), write(deg=2,str=3), test(deg=2,str=2)
#>  from    to weight count
#>  read write      2     2
#>  read  test      1     1
#>  test write      1     1
# }
```
