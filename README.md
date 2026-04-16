# cooccur

Build co-occurrence networks from any data format. One function, six input formats, eight similarity measures, eight scaling methods, and seamless conversion to igraph, tidygraph, cograph, and Nestimate.

Returns a tidy edge data frame --- not a matrix, not a custom object. Just `from`, `to`, `weight`, `count`. Use it directly, pipe it, filter it, join it.

## Installation

```r
# From GitHub
remotes::install_github("mohsaqr/cooccur")
```

## Quick start

```r
library(cooccur)

# Keywords separated by semicolons
papers <- data.frame(
  id = 1:5,
  keywords = c("machine learning; deep learning; nlp",
               "deep learning; computer vision",
               "nlp; transformers; machine learning",
               "computer vision; object detection",
               "machine learning; transformers; deep learning")
)

cooccurrence(papers, field = "keywords", sep = ";")
#> # cooccurrence: 5 nodes, 8 edges (5 transactions)
#>                 from                to weight count
#>      deep learning   machine learning      3     3
#>      deep learning               nlp      2     2
#>      deep learning   computer vision      2     2
#>   machine learning      transformers      2     2
#>                ...               ...    ...   ...
```

The short alias `co()` does the same thing:

```r
co(papers, field = "keywords", sep = ";", similarity = "jaccard")
```

## Input formats

cooccur auto-detects the input format from the arguments you provide. Six formats are supported, covering the most common shapes data comes in.

### 1. Delimited field

The most common case in bibliometrics and text analysis. A single column contains multiple items separated by a delimiter. Each row is a document.

```r
df <- data.frame(
  id = 1:3,
  keywords = c("network; graph; matrix",
               "graph; algebra",
               "network; algebra; graph")
)
cooccurrence(df, field = "keywords", sep = ";")
```

Whitespace around the separator is automatically trimmed (`" network "` becomes `"network"`). Empty strings and NAs are dropped. Duplicate items within a row are de-duplicated.

### 2. Multi-column delimited

When items live in multiple columns --- for example, author keywords and index keywords in a Scopus export, or authors and affiliations. Values from all specified columns are pooled per row.

```r
df <- data.frame(
  author_kw = c("machine learning; nlp", "deep learning", "nlp"),
  index_kw  = c("classification", "image recognition", "text mining")
)
cooccurrence(df, field = c("author_kw", "index_kw"), sep = ";")
```

### 3. Long / bipartite

One row per item-document pair. Common in relational databases, survey data, and tidy data pipelines. The `by` argument specifies which column groups items into transactions.

```r
citations <- data.frame(
  paper_id = c(1, 1, 1, 2, 2, 3, 3, 3),
  reference = c("Smith2020", "Jones2019", "Lee2021",
                "Jones2019", "Lee2021",
                "Smith2020", "Lee2021", "Park2022")
)
cooccurrence(citations, field = "reference", by = "paper_id")
```

### 4. Binary matrix

A document-term matrix where columns are items and values are 0/1. Auto-detected when all values in the data are 0 or 1 and no `field`/`by`/`sep` arguments are provided.

```r
dtm <- matrix(c(1,1,0,1,
                0,1,1,0,
                1,0,1,1), nrow = 3, byrow = TRUE,
              dimnames = list(NULL, c("network", "graph", "algebra", "matrix")))
cooccurrence(dtm)
```

Works with both `matrix` and `data.frame` inputs. Columns without names get auto-named `V1`, `V2`, etc.

### 5. Wide sequence

Non-binary data frames or matrices where each row is a sequence or record. The unique values in each row form a transaction. This is the native format for sequence analysis tools like TraMineR and tna.

```r
sequences <- data.frame(
  t1 = c("A", "B", "A"),
  t2 = c("B", "C", "C"),
  t3 = c("C", NA,  NA)
)
cooccurrence(sequences)
```

NAs, empty strings, and TraMineR void markers (`%`, `*`) are automatically removed.

### 6. List of character vectors

The most direct format. Each list element is a transaction.

```r
baskets <- list(
  c("bread", "milk", "eggs"),
  c("bread", "butter"),
  c("milk", "eggs", "butter"),
  c("bread", "milk", "eggs", "butter")
)
cooccurrence(baskets)
```

## Similarity measures

The `similarity` argument controls how raw co-occurrence counts are normalized into a similarity or association measure. All formulas operate on the co-occurrence count $C_{ij}$ and item frequencies $f_i$, $f_j$ (number of transactions containing each item).

| Method | Formula | Best for |
|--------|---------|----------|
| `"none"` | $C_{ij}$ | Raw counts, exploratory analysis |
| `"jaccard"` | $\frac{C_{ij}}{f_i + f_j - C_{ij}}$ | General purpose, penalizes unbalanced pairs |
| `"cosine"` | $\frac{C_{ij}}{\sqrt{f_i \cdot f_j}}$ | Scale-invariant comparison (Salton's cosine) |
| `"inclusion"` | $\frac{C_{ij}}{\min(f_i, f_j)}$ | Detecting subset relationships (Simpson coefficient) |
| `"association"` | $\frac{C_{ij}}{f_i \cdot f_j}$ | Probabilistic affinity, recommended by van Eck & Waltman (2009) |
| `"dice"` | $\frac{2 C_{ij}}{f_i + f_j}$ | Balanced overlap, similar to F1-score |
| `"equivalence"` | $\frac{C_{ij}^2}{f_i \cdot f_j}$ | Cosine squared, stronger penalty for low overlap |
| `"relative"` | Row-normalized (each row sums to 1) | Directed-like asymmetric weights |

```r
# Jaccard similarity
cooccurrence(baskets, similarity = "jaccard")

# Association strength (recommended for bibliometric networks)
cooccurrence(papers, field = "keywords", sep = ";", similarity = "association")
```

### Which similarity to use?

- **Exploratory work**: Start with `"none"` to see raw counts, then try `"jaccard"` or `"cosine"`.
- **Bibliometric networks**: `"association"` is recommended by van Eck & Waltman (2009) as it correctly accounts for the expected number of co-occurrences under independence.
- **Detecting hierarchical/subset structure**: `"inclusion"` reveals when one item almost always appears with another.
- **Binary networks**: `"jaccard"` or `"dice"` when you only care whether items co-occur, not how often.

## Scaling

The `scale` argument applies a transformation to the weights after similarity normalization. Useful for visualization, thresholding, or feeding into downstream models.

| Method | Transformation | Use case |
|--------|---------------|----------|
| `"minmax"` | Scale to $[0, 1]$ | Visualization, comparable weights |
| `"log"` | $\log(1 + w)$ | Compress heavy-tailed distributions |
| `"log10"` | $\log_{10}(1 + w)$ | Same, base 10 |
| `"sqrt"` | $\sqrt{w}$ | Mild compression |
| `"binary"` | 1 if $w > 0$, else 0 | Presence/absence networks |
| `"zscore"` | $(w - \mu) / \sigma$ | Standardized for statistical comparison |
| `"proportion"` | $w / \sum w$ | Relative importance |

```r
# Log-scaled Jaccard similarity
cooccurrence(baskets, similarity = "jaccard", scale = "log")

# Min-max scaled for visualization
cooccurrence(baskets, similarity = "cosine", scale = "minmax")
```

## Filtering

Three filtering mechanisms control which edges appear in the result:

```r
# Drop entities appearing in fewer than 3 transactions
cooccurrence(baskets, min_occur = 3)

# Keep only edges with weight >= 0.5 (applied after similarity + scaling)
cooccurrence(baskets, similarity = "jaccard", threshold = 0.5)

# Keep only the 10 strongest edges
cooccurrence(baskets, top_n = 10)
```

All three can be combined:

```r
cooccurrence(papers, field = "keywords", sep = ";",
             similarity = "association", min_occur = 2,
             threshold = 0.01, top_n = 50)
```

## Splitting by groups

The `split_by` argument computes a separate co-occurrence network for each level of a grouping variable and returns them in a single data frame with a `group` column.

```r
papers <- data.frame(
  year = c(2020, 2020, 2020, 2021, 2021, 2021),
  keywords = c("network; graph; matrix", "graph; algebra",
               "network; algebra; graph",
               "deep learning; nlp", "nlp; transformers",
               "deep learning; transformers; nlp")
)

co(papers, field = "keywords", sep = ";", split_by = "year",
   similarity = "jaccard")
#> # cooccurrence: 7 nodes, 8 edges | split_by: year (2 groups) | similarity: jaccard
#>           from           to    weight count group
#>        algebra        graph 0.6666667     2  2020
#>          graph      network 0.6666667     2  2020
#>  deep learning          nlp 0.6666667     2  2021
#>            nlp transformers 0.6666667     2  2021
#>            ...
```

This is useful for comparing co-occurrence patterns across time periods, disciplines, journals, or any categorical variable. Each group gets its own similarity computation, so item frequencies are group-specific.

All other parameters (`similarity`, `scale`, `threshold`, `min_occur`, `top_n`) apply per group.

## Output

`cooccurrence()` returns a data frame with class `cooccurrence`. It prints nicely, summarizes, and plots:

```r
result <- cooccurrence(baskets, similarity = "jaccard")

# Tidy data.frame — pipe it, filter it, join it
result
#> # cooccurrence: 4 nodes, 6 edges (4 transactions) | similarity: jaccard
#>     from     to    weight count
#>     eggs   milk 0.6666667     3
#>    bread   milk 0.5000000     2
#>    ...

# Summary statistics
summary(result)

# Heatmap
plot(result)

# Network plot (requires igraph)
plot(result, type = "network")
```

The raw co-occurrence count is always preserved in the `count` column, regardless of similarity or scaling. This means you can always trace back to the original data.

### Attributes

The full matrix, item frequencies, and all parameters are stored as attributes on the data frame:

```r
attr(result, "matrix")          # Normalized weight matrix
attr(result, "raw_matrix")      # Raw count matrix (diagonal zeroed)
attr(result, "items")           # Character vector of all items
attr(result, "frequencies")     # Named vector of item frequencies
attr(result, "similarity")      # Which similarity was used
attr(result, "scale")           # Which scaling was used
attr(result, "n_transactions")  # Number of transactions
attr(result, "n_items")         # Number of unique items
```

## Converters

Convert a `cooccurrence` result to other network formats. All converter packages are optional --- install only what you need.

### Matrix

```r
# Normalized similarity matrix
as_matrix(result)

# Raw co-occurrence count matrix
as_matrix(result, type = "raw")
```

### igraph

```r
# install.packages("igraph")
g <- as_igraph(result)
plot(g, edge.width = igraph::E(g)$weight * 3)
igraph::degree(g)
igraph::betweenness(g)
```

### tidygraph

```r
# install.packages("tidygraph")
tg <- as_tidygraph(result)
# Use with ggraph
```

### cograph

```r
# remotes::install_github("mohsaqr/cograph")
net <- as_cograph(result)
cograph::splot(net)
cograph::communities(net)
```

### Nestimate

```r
# remotes::install_github("mohsaqr/Nestimate")
net <- as_netobject(result)
Nestimate::centrality(net)
Nestimate::bootstrap_network(net)
```

## Full parameter reference

| Argument | Type | Description | Default |
|----------|------|-------------|---------|
| `data` | various | Input data (data.frame, matrix, or list) | required |
| `field` | character | Column(s) containing entities (nodes) | `NULL` |
| `by` | character | Column grouping entities into transactions | `NULL` |
| `sep` | character | Delimiter for splitting delimited fields | `NULL` |
| `split_by` | character | Column to split data by (separate network per group) | `NULL` |
| `similarity` | character | Normalization measure | `"none"` |
| `scale` | character | Weight scaling method | `NULL` |
| `threshold` | numeric | Minimum edge weight (after normalization + scaling) | `0` |
| `min_occur` | integer | Minimum entity frequency (transactions) | `1` |
| `top_n` | integer | Keep only the top N edges by weight (per group if split) | `NULL` |

## How it works

Regardless of input format, the internal pipeline is:

1. **Parse** input into a list of character vectors (transactions)
2. **Filter** entities below `min_occur` frequency
3. **Build** a binary transaction matrix $B$ (rows = transactions, columns = items)
4. **Compute** raw co-occurrence: $C = B^\top B$ via `crossprod()`
5. **Normalize** using the chosen `similarity` measure
6. **Scale** weights if `scale` is specified
7. **Filter** edges below `threshold` and keep `top_n`
8. **Return** upper triangle as a tidy sorted edge data frame

The computation is vectorized throughout --- no loops in the hot path. `crossprod()` delegates to optimized BLAS routines for the matrix multiplication.

## References

van Eck, N. J., & Waltman, L. (2009). How to normalize co-occurrence data? An analysis of some well-known similarity measures. *Journal of the American Society for Information Science and Technology*, 60(8), 1635--1651.

## License

MIT
