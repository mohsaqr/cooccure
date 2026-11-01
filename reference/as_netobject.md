# Convert to Nestimate netobject

Creates a `netobject` from a `cooccurrence` edge list, so the network
can be passed to Nestimate functions that work on an estimated weight
matrix, such as
[`Nestimate::net_centrality()`](https://pak.dynasite.org/Nestimate/reference/net_centrality.html).
Requires the Nestimate package.

## Usage

``` r
as_netobject(x, ...)

# S3 method for class 'cooccurrence'
as_netobject(x, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- ...:

  Ignored.

## Value

A list of class `c("netobject", "cograph_network")`, always undirected,
with method `"cooccurrence"`. It holds the weight matrix from
`as_matrix(x)`, a node table (one row per item), an edge table (one row
per edge of the upper triangle), and the similarity, scale, threshold,
and number of transactions used. Raises an error when Nestimate is not
installed.

## Details

The netobject carries no raw data (its `data` element is `NULL`), so
Nestimate functions that resample the original observations, such as
[`Nestimate::bootstrap_network()`](https://pak.dynasite.org/Nestimate/reference/bootstrap_network.html),
cannot run on it and stop with an error asking for a network built with
[`Nestimate::build_network()`](https://pak.dynasite.org/Nestimate/reference/build_network.html).

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
if (requireNamespace("Nestimate", quietly = TRUE)) {
  net <- as_netobject(res)
  Nestimate::net_centrality(net)
}
#> centralities computed excluding loops (diagonal). Pass `loops = TRUE` to include self-transitions.
#>   state InStrength Betweenness Diffusion
#> A     A          3         0.0         0
#> B     B          3         0.0         0
#> C     C          4         0.5         1
```
