# Extract the co-occurrence matrix

Returns the full square co-occurrence matrix (normalized + scaled). Use
`type = "raw"` for the raw count matrix.

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

  Character. `"normalized"` (default) or `"raw"`.

## Value

A numeric matrix.

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
