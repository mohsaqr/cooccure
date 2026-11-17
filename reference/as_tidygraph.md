# Convert a co-occurrence network to a tidygraph

`as_tidygraph()` converts a co-occurrence network to a `tbl_graph`.
tidygraph represents a network as two linked tables, nodes and edges,
that can be manipulated with dplyr verbs and drawn with ggraph. It suits
analyses that add node or edge measures as columns and then plot them.

The conversion goes by way of
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md),
so the vertices, edges, attributes and direction are the same as there.

For a result built with `split_by`, `group` names the network to
convert. For the plain igraph object, use
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md).

## Usage

``` r
as_tidygraph(x, ...)

# S3 method for class 'cooccurrence'
as_tidygraph(x, group = NULL, ...)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- ...:

  Passed to
  [`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md).

- group:

  For a result built with `split_by`, the name of the group to convert.
  `NULL` (default) for an unsplit result.

## Value

A `tbl_graph` (which also inherits from `igraph`) with node column
`name` and edge columns `from`, `to`, `weight` and `count`; directed for
`similarity = "relative"`.

## Conditions

`cooccure_missing_package` when tidygraph or igraph is not installed;
the conditions of
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md)
otherwise.

## See also

[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md);
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md);
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md).

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
if (requireNamespace("tidygraph", quietly = TRUE) &&
    requireNamespace("igraph", quietly = TRUE)) {
  as_tidygraph(net)
}
#> # A tbl_graph: 12 nodes and 57 edges
#> #
#> # An undirected simple graph with 1 component
#> #
#> # Node Data: 12 × 1 (active)
#>    name       
#>    <chr>      
#>  1 Action     
#>  2 Adventure  
#>  3 Animation  
#>  4 Biography  
#>  5 Comedy     
#>  6 Crime      
#>  7 Documentary
#>  8 Drama      
#>  9 History    
#> 10 Music      
#> 11 Romance    
#> 12 Thriller   
#> #
#> # Edge Data: 57 × 4
#>    from    to weight count
#>   <int> <int>  <dbl> <dbl>
#> 1     2     3  0.285    39
#> 2     1     6  0.237    59
#> 3     5     8  0.211   159
#> # ℹ 54 more rows
```
