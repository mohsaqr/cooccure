# Extract the weight matrix of a co-occurrence network

`as_matrix()` returns the weight matrix of a co-occurrence network built
by
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).
The weight matrix is the network written as a square matrix with one row
and one column per item, where a cell holds the weight of the edge
between two items and the diagonal is zero. This form is what
clustering, heatmaps, matrix algebra and many network packages expect,
and it shows at once which item pairs never co-occur.

The cells hold the edge weights after similarity, scaling and filtering,
or, with `type = "raw"`, the number of transactions in which each pair
co-occurs. The matrix agrees with the printed edge list, including any
`threshold` or `top_n` filter. It is symmetric for every similarity
except `"relative"`, whose network is directed.

A result built with `split_by` stacks one network per group and has no
single matrix, so `group` names the network to extract. For a graph
object rather than a matrix, use
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md),
[`as_tidygraph()`](https://pak.dynasite.org/cooccure/reference/as_tidygraph.md),
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
or
[`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md).

## Usage

``` r
as_matrix(x, ...)

# S3 method for class 'cooccurrence'
as_matrix(x, type = c("normalized", "raw"), group = NULL, ...)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- ...:

  Ignored.

- type:

  `"normalized"` (default) for the edge weights, or `"raw"` for the
  co-occurrence counts.

- group:

  For a result built with `split_by`, the name of the group to extract.
  `NULL` (default) for an unsplit result.

## Value

A dense base numeric matrix with one row and one column per item, item
names as row and column names, and a zero diagonal. Items that co-occur
with nothing (isolates) keep a row of zeros. For
`similarity = "relative"` the weight matrix is asymmetric: row `i` holds
the weights of the edges from item `i`, and each non-empty row sums to 1
before filtering. The raw matrix is always symmetric.

## Conditions

`cooccure_grouped_input` when `x` was built with `split_by` and `group`
is `NULL`; `cooccure_bad_input` when `group` names no group of `x`, or
is given for an unsplit result.

## See also

[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
to build the network;
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md)
for a graph object;
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
for the edge and node tables.

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
as_matrix(net)
#>                 Action   Adventure   Animation   Biography      Comedy
#> Action      0.00000000 0.207547170 0.133004926 0.019379845 0.066502463
#> Adventure   0.20754717 0.000000000 0.284671533 0.039800995 0.089080460
#> Animation   0.13300493 0.284671533 0.000000000 0.011049724 0.082822086
#> Biography   0.01937984 0.039800995 0.011049724 0.000000000 0.021164021
#> Comedy      0.06650246 0.089080460 0.082822086 0.021164021 0.000000000
#> Crime       0.23694779 0.007936508 0.013333333 0.048192771 0.082914573
#> Documentary 0.00000000 0.007968127 0.004424779 0.203703704 0.016548463
#> Drama       0.09888579 0.051502146 0.033527697 0.086383602 0.211155378
#> History     0.01877934 0.018750000 0.014814815 0.156462585 0.014925373
#> Music       0.00000000 0.000000000 0.007936508 0.073825503 0.024844720
#> Romance     0.01286174 0.011627907 0.008583691 0.011320755 0.168000000
#> Thriller    0.11061947 0.020725389 0.000000000 0.004926108 0.008086253
#>                   Crime Documentary       Drama    History       Music
#> Action      0.236947791 0.000000000 0.098885794 0.01877934 0.000000000
#> Adventure   0.007936508 0.007968127 0.051502146 0.01875000 0.000000000
#> Animation   0.013333333 0.004424779 0.033527697 0.01481481 0.007936508
#> Biography   0.048192771 0.203703704 0.086383602 0.15646259 0.073825503
#> Comedy      0.082914573 0.016548463 0.211155378 0.01492537 0.024844720
#> Crime       0.000000000 0.016666667 0.130747126 0.00000000 0.000000000
#> Documentary 0.016666667 0.000000000 0.007692308 0.09183673 0.159090909
#> Drama       0.130747126 0.007692308 0.000000000 0.06584992 0.026946108
#> History     0.000000000 0.091836735 0.065849923 0.00000000 0.017857143
#> Music       0.000000000 0.159090909 0.026946108 0.01785714 0.000000000
#> Romance     0.016233766 0.000000000 0.197586727 0.01369863 0.009523810
#> Thriller    0.174528302 0.000000000 0.084695394 0.01935484 0.000000000
#>                 Romance    Thriller
#> Action      0.012861736 0.110619469
#> Adventure   0.011627907 0.020725389
#> Animation   0.008583691 0.000000000
#> Biography   0.011320755 0.004926108
#> Comedy      0.168000000 0.008086253
#> Crime       0.016233766 0.174528302
#> Documentary 0.000000000 0.000000000
#> Drama       0.197586727 0.084695394
#> History     0.013698630 0.019354839
#> Music       0.009523810 0.000000000
#> Romance     0.000000000 0.019920319
#> Thriller    0.019920319 0.000000000
as_matrix(net, type = "raw")
#>             Action Adventure Animation Biography Comedy Crime Documentary Drama
#> Action           0        44        27         5     27    59           0    71
#> Adventure       44         0        39         8     31     2           2    36
#> Animation       27        39         0         2     27     3           1    23
#> Biography        5         8         2         0      8    12          44    59
#> Comedy          27        31        27         8      0    33           7   159
#> Crime           59         2         3        12     33     0           5    91
#> Documentary      0         2         1        44      7     5           0     6
#> Drama           71        36        23        59    159    91           6     0
#> History          4         3         2        23      5     0          18    43
#> Music            0         0         1        11      8     0          28    18
#> Romance          4         3         2         3     63     5           0   131
#> Thriller        25         4         0         1      3    37           0    57
#>             History Music Romance Thriller
#> Action            4     0       4       25
#> Adventure         3     0       3        4
#> Animation         2     1       2        0
#> Biography        23    11       3        1
#> Comedy            5     8      63        3
#> Crime             0     0       5       37
#> Documentary      18    28       0        0
#> Drama            43    18     131       57
#> History           0     2       3        3
#> Music             2     0       2        0
#> Romance           3     2       0        5
#> Thriller          3     0       5        0

# One network of a split result
by_decade <- cooccurrence(movies, field = "genres", sep = ",",
                          split_by = "decade", min_occur = 50)
as_matrix(by_decade, group = "2010s")
#>             Action Biography Comedy Crime Documentary Drama
#> Action           0         2     10    26           0    24
#> Biography        2         0      6     6          27    25
#> Comedy          10         6      0     9           3    43
#> Crime           26         6      9     0           2    29
#> Documentary      0        27      3     2           0     5
#> Drama           24        25     43    29           5     0
```
