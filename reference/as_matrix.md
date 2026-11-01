# Extract the co-occurrence matrix

Returns the full square co-occurrence matrix: the edge weights after
similarity normalization, scaling, and filtering, or with `type = "raw"`
the raw co-occurrence counts. Use it when a method downstream
(clustering, a heatmap, another network package) expects a matrix rather
than an edge list.

## Usage

``` r
as_matrix(x, ...)

# S3 method for class 'cooccurrence'
as_matrix(x, type = c("normalized", "raw"), ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- ...:

  Ignored.

- type:

  Character. `"normalized"` (default) for the weights, or `"raw"` for
  the number of transactions in which each pair co-occurs.

## Value

A dense base numeric matrix, one row and one column per item, with item
names as row and column names and a zero diagonal. It is symmetric for
every similarity except `"relative"`, where row `i` holds the weights
from item `i` and each row sums to 1. Results built with `split_by`
store no single matrix, so the matrix is rebuilt from the edge list.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
as_matrix(res)
#>   A B C
#> A 0 1 2
#> B 1 0 2
#> C 2 2 0
as_matrix(res, type = "raw")
#>   A B C
#> A 0 1 2
#> B 1 0 2
#> C 2 2 0
```
