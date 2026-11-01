# Convert to tidygraph

Creates a `tbl_graph` from a `cooccurrence` edge list, for use with
tidygraph and ggraph. Requires the tidygraph and igraph packages.

## Usage

``` r
as_tidygraph(x, ...)

# S3 method for class 'cooccurrence'
as_tidygraph(x, ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- ...:

  Passed to
  [`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md).

## Value

A `tbl_graph` (which also inherits from `igraph`) with the same vertices
and edges as
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md):
node column `name`, edge columns `from`, `to`, `weight`, `count`. Raises
an error when tidygraph is not installed.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
if (requireNamespace("tidygraph", quietly = TRUE) &&
    requireNamespace("igraph",    quietly = TRUE)) {
  as_tidygraph(res)
}
#> # A tbl_graph: 3 nodes and 3 edges
#> #
#> # An undirected simple graph with 1 component
#> #
#> # Node Data: 3 × 1 (active)
#>   name 
#>   <chr>
#> 1 A    
#> 2 B    
#> 3 C    
#> #
#> # Edge Data: 3 × 4
#>    from    to weight count
#>   <int> <int>  <dbl> <dbl>
#> 1     1     3      2     2
#> 2     2     3      2     2
#> 3     1     2      1     1
```
