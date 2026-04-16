# Summarise a cooccurrence network

Summarise a cooccurrence network

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

Invisibly returns `object`.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
summary(res)
#> cooccurrence network
#> ------------------------------
#> Nodes          : 3
#> Edges          : 3
#> Density        : 1.0000
#> Transactions   : 3
#> Similarity     : none
#> Weight range   : [1, 2]
#> Count range    : [1, 2]
#> Top nodes      : A(2), B(2), C(2)
```
