# Summarize a cooccurrence network

Computes network-level metrics (nodes, edges, possible edges, density,
mean degree, isolates, weight and count distribution), node-level
metrics (degree, strength, count strength, frequency), and, for a
`split_by` result, one row of metrics per group. The summary is printed
when computed. Node- and group-level metrics are available as tidy data
frames via
[`as.data.frame`](https://pak.dynasite.org/cooccure/reference/as.data.frame.summary.cooccurrence.md).

## Usage

``` r
# S3 method for class 'cooccurrence'
summary(object, ...)
```

## Arguments

- object:

  A `cooccurrence` data frame.

- ...:

  Ignored.

## Value

Invisibly, a list of class `summary.cooccurrence` holding the scalar
network metrics, the parameters used, a node table, and (for `split_by`
results) a group table. The summary is also printed via
[`print.summary.cooccurrence`](https://pak.dynasite.org/cooccure/reference/print.summary.cooccurrence.md)
as a side effect. Get the tables with `as.data.frame(summary(x))` (one
row per node) and `as.data.frame(summary(x), what = "groups")` (one row
per group).

## Details

For a network built with `split_by`, the returned frame stacks one
network per group, so a node pair can occur once per group. Pooled
simple-graph metrics (`density`, `mean_degree`, `possible_edges`) are
undefined in that case and reported as `NA`; the per-group table carries
the correct values.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
summary(res)
#> cooccurrence network
#> ------------------------------
#> Nodes          : 3
#> Edges          : 3
#> Possible edges : 3
#> Density        : 1.0000
#> Mean degree    : 2.0000
#> Isolates       : 0
#> Transactions   : 3
#> Similarity     : none
#> Counting       : full
#> Weight range   : [1, 2]
#> Weight mean    : 1.667
#> Count range    : [1, 2]
#> Count mean     : 1.667
#> Top nodes      : C(2, 4), A(2, 3), B(2, 3)

# Node-level metrics as a tidy data frame
as.data.frame(summary(res))
#> cooccurrence network
#> ------------------------------
#> Nodes          : 3
#> Edges          : 3
#> Possible edges : 3
#> Density        : 1.0000
#> Mean degree    : 2.0000
#> Isolates       : 0
#> Transactions   : 3
#> Similarity     : none
#> Counting       : full
#> Weight range   : [1, 2]
#> Weight mean    : 1.667
#> Count range    : [1, 2]
#> Count mean     : 1.667
#> Top nodes      : C(2, 4), A(2, 3), B(2, 3)
#>   node degree strength count_strength frequency
#> 1    C      2        4              4         3
#> 2    A      2        3              3         2
#> 3    B      2        3              3         2
```
