# Print a cooccurrence edge list

Print a cooccurrence edge list

## Usage

``` r
# S3 method for class 'cooccurrence'
print(x, n = 10L, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- n:

  Integer. Number of rows to show. Default 10.

- ...:

  Ignored.

## Value

Invisibly returns `x`.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
print(res)
#> # cooccurrence: 3 nodes, 3 edges (3 transactions)
#>  from to weight count
#>     A  C      2     2
#>     B  C      2     2
#>     A  B      1     1
```
