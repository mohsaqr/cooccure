# Extract the tables of a co-occurrence network

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) returns a
table of a co-occurrence network as a plain data frame without the
network's attributes, ready for sorting, joining, plotting or writing to
a file. A co-occurrence network is described by two tables: its edges,
one row per pair of items with a weight and a raw count, and its nodes,
one row per item with degree, strength and frequency. A network built
with `split_by` adds a third, one row of metrics per group.

`what` selects the table. The edge table is the printed network; the
node and group tables are those of
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md).

## Usage

``` r
# S3 method for class 'cooccurrence'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  what = c("edges", "nodes", "groups"),
  ...
)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- row.names, optional:

  Unused; present for compatibility with the
  [`base::as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  generic.

- what:

  `"edges"` (default), `"nodes"` or `"groups"`.

- ...:

  Ignored.

## Value

A base `data.frame`. For `what = "edges"`, one row per edge with columns
`from`, `to`, `weight` and `count` (and `group` for a `split_by`
result), in the order printed. An undirected network has one row per
pair; the directed `similarity = "relative"` network has one row per
direction. For `what = "nodes"` and `what = "groups"`, the tables
described in
[`as.data.frame.summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.summary.cooccurrence.md).

## See also

[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md);
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
for the weight matrix.

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
as.data.frame(net)
#>           from          to      weight count
#> 1    Adventure   Animation 0.284671533    39
#> 2       Action       Crime 0.236947791    59
#> 3       Comedy       Drama 0.211155378   159
#> 4       Action   Adventure 0.207547170    44
#> 5    Biography Documentary 0.203703704    44
#> 6        Drama     Romance 0.197586727   131
#> 7        Crime    Thriller 0.174528302    37
#> 8       Comedy     Romance 0.168000000    63
#> 9  Documentary       Music 0.159090909    28
#> 10   Biography     History 0.156462585    23
#> 11      Action   Animation 0.133004926    27
#> 12       Crime       Drama 0.130747126    91
#> 13      Action    Thriller 0.110619469    25
#> 14      Action       Drama 0.098885794    71
#> 15 Documentary     History 0.091836735    18
#> 16   Adventure      Comedy 0.089080460    31
#> 17   Biography       Drama 0.086383602    59
#> 18       Drama    Thriller 0.084695394    57
#> 19      Comedy       Crime 0.082914573    33
#> 20   Animation      Comedy 0.082822086    27
#> 21   Biography       Music 0.073825503    11
#> 22      Action      Comedy 0.066502463    27
#> 23       Drama     History 0.065849923    43
#> 24   Adventure       Drama 0.051502146    36
#> 25   Biography       Crime 0.048192771    12
#> 26   Adventure   Biography 0.039800995     8
#> 27   Animation       Drama 0.033527697    23
#> 28       Drama       Music 0.026946108    18
#> 29      Comedy       Music 0.024844720     8
#> 30   Biography      Comedy 0.021164021     8
#> 31   Adventure    Thriller 0.020725389     4
#> 32     Romance    Thriller 0.019920319     5
#> 33      Action   Biography 0.019379845     5
#> 34     History    Thriller 0.019354839     3
#> 35      Action     History 0.018779343     4
#> 36   Adventure     History 0.018750000     3
#> 37     History       Music 0.017857143     2
#> 38       Crime Documentary 0.016666667     5
#> 39      Comedy Documentary 0.016548463     7
#> 40       Crime     Romance 0.016233766     5
#> 41      Comedy     History 0.014925373     5
#> 42   Animation     History 0.014814815     2
#> 43     History     Romance 0.013698630     3
#> 44   Animation       Crime 0.013333333     3
#> 45      Action     Romance 0.012861736     4
#> 46   Adventure     Romance 0.011627907     3
#> 47   Biography     Romance 0.011320755     3
#> 48   Animation   Biography 0.011049724     2
#> 49       Music     Romance 0.009523810     2
#> 50   Animation     Romance 0.008583691     2
#> 51      Comedy    Thriller 0.008086253     3
#> 52   Adventure Documentary 0.007968127     2
#> 53   Adventure       Crime 0.007936508     2
#> 54   Animation       Music 0.007936508     1
#> 55 Documentary       Drama 0.007692308     6
#> 56   Biography    Thriller 0.004926108     1
#> 57   Animation Documentary 0.004424779     1
as.data.frame(net, what = "nodes")
#>           node degree  strength count_strength frequency
#> 1        Drama     11 0.9949722            694       634
#> 2       Comedy     11 0.7860438            371       278
#> 3    Biography     11 0.6762096            176       108
#> 4    Adventure     10 0.7396102            172       101
#> 5    Animation     10 0.5941691            127        75
#> 6      Romance     10 0.4693573            221       160
#> 7      History     10 0.4323294            106        62
#> 8       Action      9 0.9045285            266       155
#> 9        Crime      9 0.7275008            247       153
#> 10 Documentary      8 0.5079317            111       152
#> 11    Thriller      8 0.4428561            135        96
#> 12       Music      7 0.3200247             70        52
```
