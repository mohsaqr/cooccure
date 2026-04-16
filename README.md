# cooccur

Co-occurrence networks from any data format.

## Install

```r
remotes::install_github("mohsaqr/cooccur")
```

## Usage

```r
library(cooccur)

# Semicolon-delimited keywords
df <- data.frame(
  id = 1:4,
  keywords = c("network; graph", "graph; matrix; network",
               "matrix; algebra", "network; algebra; graph")
)
cooccurrence(df, field = "keywords", sep = ";")
#>     from      to weight count
#>    graph network      3     3
#>  algebra   graph      2     2
#>    graph  matrix      2     2
#>  algebra network      1     1
#>  algebra  matrix      1     1
#>   matrix network      1     1

# With similarity + scaling
co(df, field = "keywords", sep = ";", similarity = "jaccard", scale = "minmax")
```

## Six input formats

```r
# 1. Delimited field
cooccurrence(df, field = "keywords", sep = ";")

# 2. Multi-column delimited
cooccurrence(df, field = c("authors", "keywords"), sep = ";")

# 3. Long / bipartite
cooccurrence(long_df, field = "keyword", by = "paper_id")

# 4. Binary matrix (auto-detected)
cooccurrence(binary_matrix)

# 5. Wide sequence
cooccurrence(sequence_df)

# 6. List of character vectors
cooccurrence(list(c("A", "B"), c("B", "C"), c("A", "B", "C")))
```

## Eight similarity measures

`"none"` (raw counts), `"jaccard"`, `"cosine"` (Salton), `"inclusion"` (Simpson), `"association"` (van Eck & Waltman 2009), `"dice"`, `"equivalence"` (cosine squared), `"relative"` (row-normalized).

## Scaling

`"minmax"`, `"log"`, `"log10"`, `"binary"`, `"zscore"`, `"sqrt"`, `"proportion"`.

## Converters

```r
as_matrix(result)              # Square co-occurrence matrix
as_matrix(result, type="raw")  # Raw count matrix
as_igraph(result)              # igraph graph object
as_cograph(result)             # cograph_network for splot()
as_netobject(result)           # Nestimate netobject
as_tidygraph(result)           # tidygraph tbl_graph
```

## Parameters

| Argument | Description | Default |
|----------|-------------|---------|
| `field` | Column(s) containing entities | `NULL` |
| `by` | Grouping column (long format) | `NULL` |
| `sep` | Delimiter for splitting | `NULL` |
| `similarity` | Normalization measure | `"none"` |
| `scale` | Weight scaling method | `NULL` |
| `threshold` | Minimum edge weight | `0` |
| `min_occur` | Minimum entity frequency | `1` |
| `top_n` | Keep top N edges | `NULL` |

## License

MIT
