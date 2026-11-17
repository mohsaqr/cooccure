# Convert a co-occurrence network to an igraph graph

`as_igraph()` converts a co-occurrence network to an `igraph` object.
igraph is the most widely used general-purpose network library in R,
with functions for centrality, community detection, paths and layouts;
the conversion makes all of them available without re-entering the
edges.

The result is a weighted graph with one vertex per item, isolates
included, and one edge per row of the edge list, carrying the edge
attributes `weight` and `count`. The graph is undirected, except for
`similarity = "relative"`, where each row is a directed edge and the
graph is directed.

A result built with `split_by` holds several networks; `group` names the
one to convert, since stacking them would create one parallel edge per
group. For a `tbl_graph`, use
[`as_tidygraph()`](https://pak.dynasite.org/cooccure/reference/as_tidygraph.md).

## Usage

``` r
as_igraph(x, ...)

# S3 method for class 'cooccurrence'
as_igraph(x, group = NULL, ...)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md),
  with default or `"gephi"` column names.

- ...:

  Passed to
  [`igraph::graph_from_data_frame()`](https://r.igraph.org/reference/graph_from_data_frame.html),
  apart from `directed` and `vertices`, which are set here.

- group:

  For a result built with `split_by`, the name of the group to convert.
  `NULL` (default) for an unsplit result.

## Value

An `igraph` object with one vertex per item (vertex attribute `name`)
and one edge per row of the edge list (edge attributes `weight` and
`count`). Directed for `similarity = "relative"`, undirected otherwise.

## Conditions

`cooccure_missing_package` when igraph is not installed;
`cooccure_grouped_input` when `x` was built with `split_by` and `group`
is `NULL`; `cooccure_bad_input` for an unknown `group`.

## See also

[`as_tidygraph()`](https://pak.dynasite.org/cooccure/reference/as_tidygraph.md)
for a `tbl_graph`;
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and
[`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md)
for the cograph and Nestimate classes;
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
for the weight matrix.

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
if (requireNamespace("igraph", quietly = TRUE)) {
  g <- as_igraph(net)
  igraph::strength(g)
}
#>      Action   Adventure   Animation   Biography      Comedy       Crime 
#>   0.9045285   0.7396102   0.5941691   0.6762096   0.7860438   0.7275008 
#> Documentary       Drama     History       Music     Romance    Thriller 
#>   0.5079317   0.9949722   0.4323294   0.3200247   0.4693573   0.4428561 
```
