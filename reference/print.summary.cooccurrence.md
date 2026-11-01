# Print a cooccurrence summary

Prints the network-level metrics, the parameters used, the weight and
count ranges, the top nodes by degree, and the largest groups by edge
count. For a `split_by` result the pooled possible edges, density, mean
degree, and top-node line are omitted, since they are undefined for
stacked networks.

## Usage

``` r
# S3 method for class 'summary.cooccurrence'
print(x, n = 5L, ...)
```

## Arguments

- x:

  A `summary.cooccurrence` object.

- n:

  Integer. Number of top nodes and groups to show. Default 5.

- ...:

  Ignored.

## Value

Invisibly returns `x`, unchanged. Called for the side effect of
printing.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
s <- summary(res)
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
print(s, n = 2)
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
#> Top nodes      : C(2, 4), A(2, 3)
```
