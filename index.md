# cooccure

The **cooccure** R package builds co-occurrence networks: two items are
linked when they appear in the same transaction (a document, a basket, a
session, a stretch of a sequence). It auto-detects six input formats,
also reads one-hot tables, raw event logs, and sliding windows over
ordered sequences, and supports eight similarity measures, eight scaling
methods, full, fractional, and position-decay counting, per-group or
pooled networks, and filtering. Results are returned as a tidy edge data
frame (`from`, `to`, `weight`, `count`) convertible to **igraph**,
**tidygraph**, **cograph**, and **Nestimate** objects.

The main function
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
is also available as the short alias
[`co()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

## Installation

``` r

# CRAN release
install.packages("cooccure")

# Development version
remotes::install_github("mohsaqr/cooccure")
```

## Input formats

**cooccure** auto-detects the input format from the arguments provided.
Six formats are auto-detected (delimited field, multi-column delimited,
long/bipartite, binary matrix, wide sequence, and list of character
vectors), covering the most common shapes data comes in. One-hot tables
with extra columns, ordered sequences read through a sliding window, and
raw event logs are selected with dedicated arguments (sections 7 and 8).

### 1. Delimited field

A *delimited field* is a single column where multiple items are stored
as one string, separated by a consistent character such as `;`, `,`,
`|`, or a `space`. This is the most common format in bibliometrics and
text analysis, where each row represents a document.

Use the `field` argument to specify the column with the relevant values,
and `sep` to specify the delimiter.

``` r

df <- data.frame(
  id = 1:3,
  keywords = c("network; graph; matrix",
               "graph; algebra",
               "network; algebra; graph")
)
cooccurrence(df, field = "keywords", sep = ";")
```

Whitespace around the separator is automatically trimmed (`" network "`
becomes `"network"`). Empty strings and NAs are dropped. Duplicate items
within a row are de-duplicated.

### 2. Multi-column delimited

A *multi-column delimited* format is used when items are spread across
multiple columns - for example, author keywords and index keywords in a
Scopus export, or authors and affiliations. Values from all specified
columns are pooled per row.

Use the `field` argument to specify the columns with the relevant
values, and `sep` to specify the delimiter.

``` r

df <- data.frame(
  author_kw = c("machine learning; nlp", "deep learning", "nlp"),
  index_kw  = c("classification", "image recognition", "text mining")
)
cooccurrence(df, field = c("author_kw", "index_kw"), sep = ";")
```

### 3. Long / bipartite

A *long* or *bipartite* format has one row per item-document pair,
common in relational databases, survey data, and tidy data pipelines.

Use the `field` argument to specify the column containing the items, and
the `by` argument to specify which column groups them into transactions.

``` r

citations <- data.frame(
  paper_id = c(1, 1, 1, 2, 2, 3, 3, 3),
  reference = c("Smith2020", "Jones2019", "Lee2021",
                "Jones2019", "Lee2021",
                "Smith2020", "Lee2021", "Park2022")
)
cooccurrence(citations, field = "reference", by = "paper_id")
```

Use the `weight_by` argument to pass a numeric weight column for
*weighted long* format — for example, LDA topic-document probabilities
where each document contributes a topic with a given probability:

``` r

theta <- data.frame(
  doc   = c("d1","d1","d1","d2","d2","d3","d3"),
  topic = c("T1","T2","T3","T1","T3","T2","T3"),
  prob  = c(0.6, 0.3, 0.1, 0.4, 0.6, 0.5, 0.5)
)
cooccurrence(theta, field = "topic", by = "doc", weight_by = "prob")
```

In *weighted long* format, the co-occurrence between items `i` and `j`
is computed as `sum_d w_id * w_jd` (the sum of the products of their
weights across all shared transactions) rather than a simple binary
count. The `count` column still reports the number of transactions where
both items appear together.

### 4. Binary matrix

A *binary matrix* is a document-term matrix where columns are items and
values are 0/1 (absence or presence). This format is auto-detected when
all values are 0 or 1 and no `field`, `by`, or `sep` arguments are
provided.

``` r

dtm <- matrix(c(1,1,0,1,
                0,1,1,0,
                1,0,1,1), nrow = 3, byrow = TRUE,
              dimnames = list(NULL, c("network", "graph", "algebra", "matrix")))
cooccurrence(dtm)
```

Works with both `matrix` and `data.frame` inputs. Columns without names
are auto-named `V1`, `V2`, etc.

### 5. Wide sequence

A *wide sequence* format is used for non-binary data frames or matrices
where each row is a sequence or record, and the unique values in each
row form a transaction. This is the native format for sequence analysis
tools like **TraMineR** and **tna**. Pass `field = "all"` to treat every
column as a time point.

``` r

sequences <- data.frame(
  t1 = c("A", "B", "A"),
  t2 = c("B", "C", "C"),
  t3 = c("C", NA,  NA)
)
cooccurrence(sequences, field = "all")
```

NAs, empty strings, and **TraMineR** void markers (`%`, `*`) are
automatically removed.

### 6. List of character vectors

A *list of character vectors* is the most direct format, where each list
element is a transaction containing a set of categorical items.

``` r

baskets <- list(
  c("bread", "milk", "eggs"),
  c("bread", "butter"),
  c("milk", "eggs", "butter"),
  c("bread", "milk", "eggs", "butter")
)
cooccurrence(baskets)
```

### 7. One-hot / indicator table

A *one-hot* table has one column per item and one row per transaction,
often alongside identifier or metadata columns. Name the indicator
columns with `vars`; every other column is ignored. Columns can be given
as a bare range, bare names, positions, a negative selection, or a
character vector, exactly as `select` in base
[`subset()`](https://rdrr.io/r/base/subset.html). Any non-zero, non-`NA`
value counts as present, so count tables such as document-term matrices
work too.

``` r

onehot <- data.frame(
  doc     = c("d1", "d2", "d3"),
  network = c(1, 0, 1),
  graph   = c(1, 1, 1),
  algebra = c(0, 1, 1)
)
cooccurrence(onehot, vars = network:algebra)
```

### 8. Ordered sequences and event logs

For a categorical time series, treating a whole sequence as one
transaction links every state to every other state it ever shares a
sequence with. `window = w` instead makes every run of `w` consecutive
positions a transaction, so only states that occur close together are
linked. It applies to lists of sequences, wide sequence data
(`field = "all"`), and event logs.

``` r

states <- list(
  c("plan", "monitor", "adapt", "monitor", "evaluate"),
  c("plan", "adapt", "adapt", "evaluate")
)
cooccurrence(states, window = 2)
```

A raw event log (one row per event) is passed with `action` naming the
event column, plus optional `actor`, `time`, `session`, and `order`
columns. The log is split into sessions on time gaps longer than
`time_threshold` seconds (default 900) and each session becomes one
transaction. Sessionization is done by
[`Nestimate::prepare()`](https://pak.dynasite.org/Nestimate/reference/prepare.html),
so this input requires the **Nestimate** package.

``` r

events <- data.frame(
  student = rep(c("s1", "s2"), each = 3),
  code    = c("read", "write", "read", "test", "write", "read"),
  stamp   = as.POSIXct("2026-01-01 09:00:00") + c(0, 60, 120, 0, 30, 90)
)
cooccurrence(events, actor = "student", action = "code", time = "stamp")
```

## Similarity measures

The `similarity` argument controls how raw co-occurrence counts are
normalized into a similarity or association measure. All similarity
measures are based on two inputs: the co-occurrence count between two
items ($`C_{ij}`$), and how frequently each item appears individually
across all transactions ($`f_i`$, $`f_j`$).

The examples from here on use a small keyword table:

``` r

papers <- data.frame(
  year = c(2020, 2020, 2020, 2021, 2021, 2021),
  keywords = c("network; graph; matrix", "graph; algebra",
               "network; algebra; graph",
               "deep learning; nlp", "nlp; transformers",
               "deep learning; transformers; nlp")
)

# Jaccard similarity
cooccurrence(baskets, similarity = "jaccard")

# Association strength
cooccurrence(papers, field = "keywords", sep = ";", similarity = "association")
```

### Which similarity to use?

- **Exploratory work**: Start with `"none"` to see raw counts and
  understand the data, then try `"jaccard"` or `"cosine"` for a balanced
  view.

- **General purpose**: `"jaccard"` is a good default choice. It
  normalizes co-occurrences by the union of transactions containing
  either item, applying a balanced penalty for non-overlap.

- **Bibliometric and scientometric networks**: `"association"` is
  recommended by van Eck & Waltman (2009) because it correctly accounts
  for the expected number of co-occurrences under independence. Two
  items that are both very frequent will naturally co-occur often;
  association strength discounts this, revealing which pairs co-occur
  *more than chance alone would predict*.

- **Detecting hierarchical/subset structure**: `"inclusion"` (Simpson
  coefficient) reveals when one item almost always appears with another,
  useful for finding items that are subsets of broader categories or
  dependency relationships.

- **Binary presence/absence networks**: `"dice"` when you only care
  *whether* items co-occur, not *how often*. Less strict than
  `"jaccard"`, it applies a less severe penalty for partial overlap.

- **Scale-invariant comparison**: `"cosine"` is invariant to absolute
  frequency, useful when comparing co-occurrence patterns across
  datasets of different sizes or when frequent items should not dominate
  the network.

- **Strict filtering**: `"equivalence"` (cosine squared) amplifies
  differences, pushing pairs with weak overlap closer to zero and
  retaining only the strongest associations.

- **Asymmetric tendencies**: `"relative"` normalizes each row so that
  edge weights sum to 1, capturing the relative tendency of one item to
  appear with another rather than absolute co-occurrence counts. It is
  the only asymmetric measure: the edge data frame carries one direction
  per pair, and
  [`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
  returns both.

### Similarity method overview

| Method | Formula | Description | Best for |
|----|----|----|----|
| `"none"` | $`C_{ij}`$ | Raw co-occurrence count | Exploratory analysis |
| `"jaccard"` | $`\frac{C_{ij}}{f_i + f_j - C_{ij}}`$ | Divides co-occurrences by the total number of transactions containing either item | General purpose |
| `"cosine"` | $`\frac{C_{ij}}{\sqrt{f_i \cdot f_j}}`$ | Divides co-occurrences by the geometric mean of item frequencies (Salton’s cosine) | Scale-invariant comparison |
| `"inclusion"` | $`\frac{C_{ij}}{\min(f_i, f_j)}`$ | Divides co-occurrences by the frequency of the rarer item (Simpson coefficient) | Subset and hierarchical relationships |
| `"association"` | $`\frac{C_{ij}}{f_i \cdot f_j}`$ | Divides co-occurrences by the product of item frequencies, discounting chance co-occurrences (van Eck & Waltman, 2009) | Bibliometric networks |
| `"dice"` | $`\frac{2 C_{ij}}{f_i + f_j}`$ | Divides co-occurrences by the arithmetic mean of item frequencies | Binary presence/absence networks |
| `"equivalence"` | $`\frac{C_{ij}^2}{f_i \cdot f_j}`$ | Squares the co-occurrence count before dividing by the product of frequencies (cosine squared) | Strict filtering |
| `"relative"` | Row-normalized (each row sums to 1) | Normalizes each row so that all edge weights from an item sum to 1 | Asymmetric tendencies |

## Counting

The `counting` argument controls how much each transaction contributes
to the co-occurrence count. Under full counting (default), each
co-occurring pair adds 1 regardless of how many items are in the
transaction. Under fractional counting, each pair adds $`1/(n-1)`$ where
$`n`$ is the number of items in the transaction, preventing large
transactions from dominating the network (Perianes-Rodriguez et al.,
2016). For example, a document with 10 keywords creates 45 pairs under
full counting but contributes only 1/9 per pair under fractional
counting. Under attention counting, for ordered transactions, each pair
adds $`\exp(-|pos_i - pos_j| / \lambda)`$, so items that occur close
together in a sequence are linked more strongly than items far apart;
`lambda` (default 1) sets how fast the weight decays.

``` r

# Full counting (default): each co-occurring pair adds 1
co(papers, field = "keywords", sep = ";")

# Fractional: each pair adds 1/(n-1) where n = items in the transaction
co(papers, field = "keywords", sep = ";", counting = "fractional")

# Attention: each pair adds exp(-gap / lambda) within an ordered sequence
co(states, counting = "attention", lambda = 1)
```

## Scaling

The `scale` argument applies a transformation to the weights after
similarity normalization, useful for visualization, thresholding, or
feeding into downstream models.

``` r

# Log-scaled Jaccard similarity
cooccurrence(baskets, similarity = "jaccard", scale = "log")

# Min-max scaled for visualization
cooccurrence(baskets, similarity = "cosine", scale = "minmax")
```

### Scaling method overview

| Method | Transformation | Description | Use case |
|----|----|----|----|
| `"minmax"` | Scale to $`[0, 1]`$ | Rescales all weights to the range $`[0, 1]`$ | Visualization and cross-network comparison |
| `"log"` | $`\log(1 + w)`$ | Applies a natural log transformation | Compressing heavy-tailed distributions |
| `"log10"` | $`\log_{10}(1 + w)`$ | Same as log but base 10 | When base 10 interpretation is preferred |
| `"sqrt"` | $`\sqrt{w}`$ | Square root transformation | Mild compression of skewed weights |
| `"binary"` | 1 if $`w > 0`$, else 0 | Converts all positive weights to 1 | Presence/absence networks |
| `"zscore"` | $`(w - \mu) / \sigma`$ | Standardizes weights to mean 0 and standard deviation 1 | Statistical comparison across networks |
| `"proportion"` | $`w / \sum w`$ | Divides each weight by the total sum of weights | Expressing edges as relative importance |

## Filtering

Three filtering arguments control which edges appear in the result:

- `min_occur`: drops any entity appearing in fewer than a specified
  number of transactions, removing rare items before co-occurrences are
  computed.
- `threshold`: keeps only edges with a weight at or above a specified
  value, applied after similarity normalization and scaling.
- `top_n`: keeps only the $`n`$ strongest edges by weight (ties at the
  cut are truncated, so exactly $`n`$ edges are kept).

``` r

# Drop entities appearing in fewer than 3 transactions
cooccurrence(baskets, min_occur = 3)

# Keep only edges with weight >= 0.5 (applied after similarity + scaling)
cooccurrence(baskets, similarity = "jaccard", threshold = 0.5)

# Keep only the 10 strongest edges
cooccurrence(baskets, top_n = 10)
```

All three can be combined for fine-grained control over the network size
and density:

``` r

cooccurrence(papers, field = "keywords", sep = ";",
             similarity = "association", min_occur = 2,
             threshold = 0.01, top_n = 50)
```

## Splitting by groups

The `split_by` argument (alias `group`) computes a separate
co-occurrence network for each level of a grouping variable and returns
them in a single data frame with a `group` column. This is useful for
comparing co-occurrence patterns across time periods, disciplines,
journals, or any categorical variable. Each group gets its own
similarity computation, meaning item frequencies are group-specific. All
other parameters (`similarity`, `scale`, `threshold`, `min_occur`,
`top_n`) apply per group.

``` r

co(papers, field = "keywords", sep = ";", split_by = "year",
   similarity = "jaccard")
#> # cooccurrence: 7 nodes, 8 edges
#> # split_by: year (2 groups)
#> # similarity: jaccard | counting: full
#> # isolates: 0 | per-group metrics: summary()
#>           from           to    weight count group
#>        algebra        graph 0.6666667     2  2020
#>          graph      network 0.6666667     2  2020
#>         matrix      network 0.5000000     1  2020
#>          graph       matrix 0.3333333     1  2020
#>        algebra      network 0.3333333     1  2020
#>  deep learning          nlp 0.6666667     2  2021
#>            nlp transformers 0.6666667     2  2021
#>  deep learning transformers 0.3333333     1  2021
```

Per-group density, size, and mean weight come from
[`summary()`](https://rdrr.io/r/base/summary.html) as a tidy data frame:

``` r

by_year <- co(papers, field = "keywords", sep = ";", split_by = "year",
              similarity = "jaccard")
as.data.frame(summary(by_year), what = "groups")
```

`aggregate_by` is the opposite choice: it computes one network per group
and then combines the edge weights into ONE network
(`aggregate = "sum"`, `"mean"`, `"min"`, or `"max"`; counts are always
summed). Use it when items should be normalized within their own context
(for example, keywords within a journal) before the contexts are pooled.

``` r

co(papers, field = "keywords", sep = ";", aggregate_by = "year",
   similarity = "jaccard", aggregate = "mean")
```

## Output

[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
returns a tidy data frame of class `cooccurrence` that can be piped,
filtered, and joined like any standard data frame. The raw co-occurrence
count is always preserved in the `count` column regardless of similarity
or scaling, meaning the original counts can always be traced back.

The full matrix, item frequencies, and parameters travel with the
result, and accessor functions return them in tidy form:

``` r

result <- co(papers, field = "keywords", sep = ";", similarity = "jaccard")

as_matrix(result)                    # Normalized weight matrix
as_matrix(result, type = "raw")      # Raw count matrix (diagonal zeroed)
as.data.frame(summary(result))       # One row per node: degree, strength, frequency
```

The `cooccurrence` object can be also printed, summarized, and plotted
directly as a co-occurrence network (Saqr et al., 2024):

``` r

# Summary statistics: size, density, degree, weight distribution
summary(result)

# Heatmap
plot(result)

# Network plot (requires igraph)
plot(result, type = "network")
```

### Output formats

The `output` argument controls the format returned directly:

- `"default"` — tidy data frame with `from`, `to`, `weight`, `count`
  columns
- `"gephi"` — Gephi-ready format with `Source`, `Target`, `Weight`,
  `Type`, `Count` columns, writable directly to CSV
- `"igraph"` — igraph object for network analysis and visualization
- `"cograph"` — cograph object for use with the cograph package
- `"matrix"` — square co-occurrence matrix

``` r

# Default: tidy data frame with from, to, weight, count
co(papers, field = "keywords", sep = ";")

# Gephi-ready: Source, Target, Weight, Type, Count columns
co(papers, field = "keywords", sep = ";", output = "gephi")
#>         Source       Target Weight       Type Count
#>        algebra        graph      2 Undirected     2
#>          graph      network      2 Undirected     2
#>  deep learning          nlp      2 Undirected     2
#>            nlp transformers      2 Undirected     2
#>  ...

# igraph object
g <- co(papers, field = "keywords", sep = ";", output = "igraph")

# cograph object
net <- co(papers, field = "keywords", sep = ";", output = "cograph")

# Square matrix
mat <- co(papers, field = "keywords", sep = ";", output = "matrix")
```

The Gephi output can be written directly to CSV for import:

``` r

write.csv(co(papers, field = "keywords", sep = ";", output = "gephi"),
          file.path(tempdir(), "network.csv"), row.names = FALSE)
```

## Converters

A `cooccurrence` result can be converted to other network formats using
the built-in converter functions. All converter packages are optional —
install only what you need.

### Matrix

``` r

# Normalized similarity matrix
as_matrix(result)

# Raw co-occurrence count matrix
as_matrix(result, type = "raw")
```

### igraph

``` r

# install.packages("igraph")
g <- as_igraph(result)
igraph::degree(g)
igraph::betweenness(g)
```

### tidygraph

``` r

# install.packages("tidygraph")
tg <- as_tidygraph(result)
# Use with ggraph
```

### cograph

``` r

# install.packages("cograph")
net <- as_cograph(result)
cograph::splot(net)
cograph::communities(net)
```

**cograph** exports its own
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md).
If you attach **cograph** with
[`library(cograph)`](https://sonsoles.me/cograph/) after **cooccure**,
call `cooccure::as_cograph(result)` or build the network with
`output = "cograph"`.

### Nestimate

``` r

# install.packages("Nestimate")
net <- as_netobject(result)
Nestimate::net_centrality(net)
```

The netobject carries the estimated weight matrix but not the raw
transactions, so Nestimate functions that resample the original data
(such as `bootstrap_network()`) do not run on it.

## How it works

Regardless of input format, the internal pipeline is:

1.  **Parse** input into a list of character vectors (transactions);
    with `window`, each window of consecutive positions is a transaction
2.  **Filter** entities below `min_occur` frequency
3.  **Build** a sparse transaction matrix $`B`$ (rows = transactions,
    columns = items), weighted by the `counting` method
4.  **Compute** co-occurrence: $`C = B^\top B`$ via sparse
    [`Matrix::crossprod()`](https://rdrr.io/pkg/Matrix/man/matmult-methods.html)
5.  **Normalize** using the chosen `similarity` measure
6.  **Scale** weights if `scale` is specified
7.  **Filter** edges below `threshold` and keep `top_n`
8.  **Return** upper triangle as a tidy sorted edge data frame

The computation is vectorized throughout - no loops in the hot path -
and stays in sparse form, so it scales to corpora with hundreds of
thousands of distinct items.

## Full parameter reference

| Argument | Type | Description | Default |
|----|----|----|----|
| `data` | various | Input data (data.frame, matrix, or list) | required |
| `field` | character | Column(s) containing entities (nodes) | `NULL` |
| `by` | character | Column grouping entities into transactions | `NULL` |
| `weight_by` | character | Column with numeric weights for long format (e.g. LDA topic probabilities) | `NULL` |
| `sep` | character | Delimiter for splitting delimited fields | `NULL` |
| `split_by` | character | Column to split data by (separate network per group) | `NULL` |
| `similarity` | character | Normalization measure | `"none"` |
| `counting` | character | `"full"`, `"fractional"`, or `"attention"` | `"full"` |
| `scale` | character | Weight scaling method | `NULL` |
| `threshold` | numeric | Minimum edge weight (after normalization + scaling); `0` keeps all edges | `0` |
| `min_occur` | integer | Minimum entity frequency (transactions) | `1` |
| `top_n` | integer | Keep only the top N edges by weight (per group if split) | `NULL` |
| `output` | character | Output format: `"default"`, `"gephi"`, `"igraph"`, `"cograph"`, `"matrix"` | `"default"` |
| `vars` | column spec | Indicator (one-hot) columns; other columns ignored | `NULL` |
| `actor` | character | Event log: column(s) identifying who acted | `NULL` |
| `action` | character | Event log: event/state column; turns on event-log input | `NULL` |
| `time` | character | Event log: timestamp column | `NULL` |
| `session` | character | Event log: explicit session column(s) | `NULL` |
| `order` | character | Event log: tie-breaking column for identical timestamps | `NULL` |
| `time_threshold` | numeric | Event log: gap in seconds that starts a new session | `900` |
| `group` | character | Alias for `split_by` | `NULL` |
| `aggregate_by` | character | Column to group by, then combine into one network | `NULL` |
| `aggregate` | character | Combiner for `aggregate_by`: `"sum"`, `"mean"`, `"min"`, `"max"` | `"sum"` |
| `window` | integer | Sliding-window size for ordered sequences | `NULL` |
| `lambda` | numeric | Decay rate for `counting = "attention"` | `1` |

## References

Perianes-Rodriguez, A., Waltman, L., & van Eck, N. J. (2016).
Constructing bibliometric networks: A comparison between full and
fractional counting. *Journal of Informetrics*, *10*(4), 1178-1195.
<https://doi.org/10.1016/j.joi.2016.10.006>

Saqr, M., López-Pernas, S., Conde, M. Á., & Hernández-García, Á. (2024).
Social Network Analysis: A Primer, a Guide and a Tutorial in R. In Saqr,
M. & López-Pernas, S. (Eds.), *Learning Analytics Methods and Tutorials:
A Practical Guide Using R*. Springer.
<https://doi.org/10.1007/978-3-031-54464-4_15>

van Eck, N. J., & Waltman, L. (2009). How to normalize cooccurrence
data? An analysis of some well-known similarity measures. *Journal of
the American Society for Information Science and Technology*, *60*(8),
1635-1651. <https://doi.org/10.1002/asi.21075>

## Authors

**Mohammed Saqr** — University of Eastern Finland ·
[saqr.me](https://saqr.me)

**Sonsoles López-Pernas** — University of Eastern Finland ·
[sonsoles.me](https://sonsoles.me)

**Kamila Misiejuk** — FernUniversität in Hagen ·
[kamilamisiejuk.com](https://kamilamisiejuk.com)

## License

MIT
