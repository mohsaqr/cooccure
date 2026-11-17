# Convert a co-occurrence network to a Nestimate netobject

`as_netobject()` converts a co-occurrence network to a Nestimate
`netobject`. Nestimate estimates and compares networks of several kinds
(transition, partial correlation, co-occurrence) and stores them as
`netobject`s, which its centrality and comparison functions accept; the
conversion lets a co-occurrence network sit beside networks estimated
there.

The `netobject` has method `"cooccurrence"` and is built from the weight
matrix returned by
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md),
with the same node and edge tables as
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and the similarity, scale, threshold and number of transactions recorded
as parameters. It is directed only for `similarity = "relative"`.

The netobject carries no raw data (its `data` element is `NULL`), so
Nestimate functions that resample the original observations, such as
[`Nestimate::bootstrap_network()`](https://pak.dynasite.org/Nestimate/reference/bootstrap_network.html),
cannot run on it. Build the network with
[`Nestimate::cooccurrence()`](https://pak.dynasite.org/Nestimate/reference/cooccurrence.html)
for those. For a result built with `split_by`, `group` names the network
to convert.

## Usage

``` r
as_netobject(x, ...)

# S3 method for class 'cooccurrence'
as_netobject(x, group = NULL, ...)
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

A list of class `c("netobject", "cograph_network")` with method
`"cooccurrence"`, holding the weight matrix, a node table (one row per
item), an edge table (one row per edge), `directed`, and the parameters
used.

## Conditions

`cooccure_missing_package` when Nestimate is not installed; the
conditions of
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
for `group`.

## See also

[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md);
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md);
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md).

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
if (requireNamespace("Nestimate", quietly = TRUE)) {
  Nestimate::net_centrality(as_netobject(net))
}
#> centralities computed excluding loops (diagonal). Pass `loops = TRUE` to include self-transitions.
#>                   state InStrength Betweenness Diffusion
#> Action           Action  0.9045285           6 0.9636505
#> Adventure     Adventure  0.7396102           0 0.7421493
#> Animation     Animation  0.5941691           0 0.5622045
#> Biography     Biography  0.6762096          16 0.4361873
#> Comedy           Comedy  0.7860438           7 0.7898051
#> Crime             Crime  0.7275008           0 0.7374551
#> Documentary Documentary  0.5079317          10 0.1816975
#> Drama             Drama  0.9949722          30 1.0000000
#> History         History  0.4323294           0 0.1866349
#> Music             Music  0.3200247           0 0.0000000
#> Romance         Romance  0.4693573           0 0.3832359
#> Thriller       Thriller  0.4428561           0 0.3346036
```
