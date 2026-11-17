# Convert a co-occurrence network to a cograph network

`as_cograph()` converts a co-occurrence network to a `cograph_network`.
cograph draws and analyzes networks from a weight matrix, with layouts
and styling designed for publication figures and functions for
centrality and community detection. Its `cograph_network` class is also
the base class of the networks estimated by Nestimate.

The `cograph_network` is built from the weight matrix returned by
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md):
a node table with one row per item and an edge table with one row per
non-zero cell, one triangle for an undirected network and every
off-diagonal cell for the directed `similarity = "relative"` network.
The result can be passed to
[`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html).

cograph exports its own `as_cograph()`. When cograph is attached after
cooccure, a bare `as_cograph()` call resolves to the cograph version,
which reads the edge data frame with its own defaults. Call
`cooccure::as_cograph()`, or build the network with
`cooccurrence(..., output = "cograph")`. For a result built with
`split_by`, `group` names the network to convert.

## Usage

``` r
as_cograph(x, ...)

# S3 method for class 'cooccurrence'
as_cograph(x, group = NULL, ...)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- ...:

  Ignored.

- group:

  For a result built with `split_by`, the name of the group to convert.
  `NULL` (default) for an unsplit result.

## Value

A list of class `cograph_network` holding the weight matrix (`weights`),
a node table (one row per item: `id`, `label`, `name`, `x`, `y`), an
edge table (one row per edge: integer `from` and `to` node ids and
`weight`), `directed` (`TRUE` only for `similarity = "relative"`), and
the node and edge counts.

## Conditions

`cooccure_missing_package` when cograph is not installed; the conditions
of
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
for `group`.

## See also

[`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md)
for the Nestimate class;
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md);
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md).

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
if (requireNamespace("cograph", quietly = TRUE)) {
  cooccure::as_cograph(net)
}
#> Cograph network: 12 nodes, 57 edges ( undirected )
#> Source: cooccure 
#>   Nodes (12): Action, Adventure, Animation, Biography, Comedy, Crime, ... +6 more
#>   Edges: 57 / 66 (density: 86.4%)
#>   Weights: [0.004, 0.285]  |  mean: 0.067
#>   Strongest edges:
#>     Adventure -- Animation  0.285
#>     Action -- Crime  0.237
#>     Comedy -- Drama  0.211
#>     Action -- Adventure  0.208
#>     Biography -- Documentary  0.204
#> Layout: none 
#>   Use as.data.frame() for the edge table, as.data.frame(what = "nodes") for the nodes.
```
