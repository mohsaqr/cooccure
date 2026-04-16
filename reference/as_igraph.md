# Convert to igraph

Creates an undirected, weighted `igraph` graph from a `cooccurrence`
edge list.

## Usage

``` r
as_igraph(x, ...)

# S3 method for class 'cooccurrence'
as_igraph(x, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- ...:

  Passed to
  [`igraph::graph_from_data_frame`](https://r.igraph.org/reference/graph_from_data_frame.html).

## Value

An `igraph` object.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
if (requireNamespace("igraph", quietly = TRUE)) {
  g <- as_igraph(res)
  igraph::vcount(g)
}
#> [1] 3
```
