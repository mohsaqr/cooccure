# Convert to cograph network

Creates a `cograph_network` object from a `cooccurrence` edge list, so
the network can be plotted with
[`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html)
and analyzed with cograph functions such as
[`cograph::centrality()`](https://sonsoles.me/cograph/reference/centrality.html)
and
[`cograph::communities()`](https://sonsoles.me/cograph/reference/communities.html).
Requires the cograph package.

## Usage

``` r
as_cograph(x, ...)

# S3 method for class 'cooccurrence'
as_cograph(x, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- ...:

  Ignored.

## Value

A list of class `cograph_network`, always undirected, built from the
upper triangle of `as_matrix(x)`. It holds the weight matrix, a node
table (one row per item: `id`, `label`, `name`, `x`, `y`), an edge table
(one row per edge: integer `from` and `to` node ids, `weight`), and the
node and edge counts. Raises an error when cograph is not installed.

## Details

cograph exports its own `as_cograph()`. When cograph is attached after
cooccure, a bare `as_cograph()` call resolves to the cograph version,
which reads the edge data frame with its own defaults. Call
`cooccure::as_cograph()`, or build the network with
`cooccurrence(..., output = "cograph")`, to get this method.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
if (requireNamespace("cograph", quietly = TRUE)) {
  cooccure::as_cograph(res)
}
#> Cograph network: 3 nodes, 3 edges ( undirected )
#> Source: cooccure 
#>   Nodes (3): A, B, C
#>   Edges: 3 / 3 (density: 100.0%)
#>   Weights: [1.000, 2.000]  |  mean: 1.667
#>   Strongest edges:
#>     A -- C  2.000
#>     B -- C  2.000
#>     A -- B  1.000
#> Layout: none 
#>   Use as.data.frame() for the edge table, as.data.frame(what = "nodes") for the nodes.
```
