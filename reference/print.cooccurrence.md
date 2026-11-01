# Print a cooccurrence edge list

Prints a compact network diagnostic header followed by an edge preview.
The header gives the number of nodes, edges, and transactions, the
density and mean degree, the similarity, counting, and scaling used, the
number of isolates, and the five highest-degree nodes, so the size and
sparsity of a network can be judged before any edge is read. For a
`split_by` result the pooled density and degree are omitted, since they
are undefined when several networks are stacked; use
[`summary`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
for per-group metrics.

## Usage

``` r
# S3 method for class 'cooccurrence'
print(x, n = 10L, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- n:

  Integer. Number of edge rows to show. Default 10.

- ...:

  Ignored.

## Value

Invisibly returns `x`, unchanged. Called for the side effect of
printing.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
print(res)
#> # cooccurrence: 3 nodes, 3 edges | density: 1.0000 | mean degree: 2.0000 | 3 transactions
#> # similarity: none | counting: full
#> # possible edges: 3 | isolates: 0
#> # top nodes: C(deg=2,str=4), A(deg=2,str=3), B(deg=2,str=3)
#>  from to weight count
#>     A  C      2     2
#>     B  C      2     2
#>     A  B      1     1
```
