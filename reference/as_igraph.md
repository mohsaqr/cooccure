# Convert to igraph

Creates an undirected, weighted `igraph` graph from a `cooccurrence`
edge list, so the result can be analyzed with any igraph function.
Requires the igraph package.

## Usage

``` r
as_igraph(x, ...)

# S3 method for class 'cooccurrence'
as_igraph(x, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame (default or `"gephi"` column names).

- ...:

  Passed to
  [`igraph::graph_from_data_frame()`](https://r.igraph.org/reference/graph_from_data_frame.html),
  apart from `directed` and `vertices`, which are set here.

## Value

An undirected `igraph` object with one vertex per item (vertex attribute
`name`, isolated items included) and one edge per row of `x` (edge
attributes `weight` and `count`). Raises an error when igraph is not
installed.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
if (requireNamespace("igraph", quietly = TRUE)) {
  g <- as_igraph(res)
  igraph::vcount(g)
}
#> [1] 3
```
