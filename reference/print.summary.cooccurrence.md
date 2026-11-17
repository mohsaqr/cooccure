# Print a co-occurrence network summary

[`print()`](https://rdrr.io/r/base/print.html) shows the network-level
block of a
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
object: the numbers of nodes, edges and possible edges, density, mean
degree, isolates, transactions, the parameters used, the range and mean
of the weights and counts, the top nodes by degree, and the largest
groups by number of edges. For a `split_by` result the pooled metrics
and the top-node line are omitted, since they are undefined for stacked
networks.

## Usage

``` r
# S3 method for class 'summary.cooccurrence'
print(x, n = 5L, ...)
```

## Arguments

- x:

  A `summary.cooccurrence` object.

- n:

  Number of top nodes and groups to show (default 5).

- ...:

  Ignored.

## Value

`x`, invisibly and unchanged. Called for the printed output.

## See also

[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md);
[`as.data.frame.summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.summary.cooccurrence.md).

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",")
print(summary(net), n = 3)
#> cooccurrence network
#> ------------------------------
#> Nodes          : 22
#> Edges          : 129
#> Possible edges : 231
#> Density        : 0.5584
#> Mean degree    : 11.7273
#> Isolates       : 0
#> Transactions   : 1000
#> Similarity     : none
#> Counting       : full
#> Weight range   : [1, 159]
#> Weight mean    : 13.23
#> Count range    : [1, 159]
#> Count mean     : 13.23
#> Top nodes      : Drama(20, 812), Comedy(19, 412), Action(17, 295)
```
