# Extract the tables of a co-occurrence network summary

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns
the node table or the group table of a
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
object as a plain data frame, so the metrics can be sorted, filtered,
joined or plotted with ordinary data-frame tools.

## Usage

``` r
# S3 method for class 'summary.cooccurrence'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  what = c("nodes", "groups"),
  ...
)
```

## Arguments

- x:

  A `summary.cooccurrence` object.

- row.names, optional:

  Unused; present for compatibility with the
  [`base::as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  generic.

- what:

  `"nodes"` (default) for the node table, or `"groups"` for the group
  table of a `split_by` result.

- ...:

  Ignored.

## Value

A base `data.frame`. For `what = "nodes"`, one row per node (per node
and group for a `split_by` result, with a leading `group` column),
sorted by degree and strength (both decreasing) and then name, with
columns `node`, `degree` (number of incident edges), `strength` (sum of
incident edge weights), `count_strength` (sum of incident raw counts)
and `frequency` (number of transactions containing the node; `NA` when
not stored, as for `aggregate_by` and weighted results). For
`what = "groups"`, one row per group with columns `group`, `n_nodes`,
`n_edges`, `possible_edges`, `density`, `weight_mean` and `count_sum`;
zero rows when the network was not split.

## See also

[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md);
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md),
which returns the same tables directly from the network.

## Examples

``` r
by_decade <- cooccurrence(movies, field = "genres", sep = ",",
                          split_by = "decade", similarity = "jaccard")
as.data.frame(summary(by_decade), what = "groups")
#>   group n_nodes n_edges possible_edges   density weight_mean count_sum
#> 1 1970s      20      53            190 0.2789474  0.11842267       158
#> 2 1980s      20      61            190 0.3210526  0.09031828       185
#> 3 1990s      20      54            190 0.2842105  0.10294475       204
#> 4 2000s      22      84            231 0.3636364  0.07101046       358
#> 5 2010s      20      94            190 0.4947368  0.06183414       592
#> 6 2020s      19      60            171 0.3508772  0.08369359       210
```
