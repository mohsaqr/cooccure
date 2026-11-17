# Summarize a co-occurrence network

[`summary()`](https://rdrr.io/r/base/summary.html) computes the metrics
of a co-occurrence network at three levels: the network as a whole
(size, density, mean degree, isolates and the distribution of edge
weights and counts), each item in it (degree, strength and frequency),
and, for a network built with `split_by`, each group. Together these
show whether the network is sparse or saturated, which items are hubs,
and how groups differ in size and density.

The metrics are returned as an object; printing it shows the
network-level block. The node and group tables are returned as tidy data
frames by
[`as.data.frame.summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.summary.cooccurrence.md),
or directly from the network with
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md).

For a network built with `split_by`, the frame stacks one network per
group, so a pair can occur once per group. Pooled simple-graph metrics
(`density`, `mean_degree`, `possible_edges`) are undefined and reported
as `NA`; the node table has one row per node per group and the group
table carries the per-group values. For the directed
`similarity = "relative"` network, density is computed over ordered
pairs and degree counts in- and out-edges.

## Usage

``` r
# S3 method for class 'cooccurrence'
summary(object, ...)
```

## Arguments

- object:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- ...:

  Ignored.

## Value

An object of class `summary.cooccurrence`: a list of network metrics
(`n_nodes`, `n_edges`, `possible_edges`, `density`, `mean_degree`,
`isolates`), the parameters used, five-number summaries of the weights
and counts, a node table and, for `split_by` results, a group table.
Read the tables with
[`as.data.frame.summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.summary.cooccurrence.md).

## See also

[`print.summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/print.summary.cooccurrence.md);
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md);
[`plot.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/plot.cooccurrence.md)
for the degree distribution.

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard")
summary(net)
#> cooccurrence network
#> ------------------------------
#> Nodes          : 22
#> Edges          : 129
#> Possible edges : 231
#> Density        : 0.5584
#> Mean degree    : 11.7273
#> Isolates       : 0
#> Transactions   : 1000
#> Similarity     : jaccard
#> Counting       : full
#> Weight range   : [0.001577, 0.2847]
#> Weight mean    : 0.04503
#> Count range    : [1, 159]
#> Count mean     : 13.23
#> Top nodes      : Drama(20, 1.178), Comedy(19, 0.9227), Action(17, 1.07), Romance(17, 0.5551), Adventure(15, 0.9235)

# The node table as a data frame
as.data.frame(summary(net), what = "nodes")
#>           node degree    strength count_strength frequency
#> 1        Drama     20 1.177622464            812       634
#> 2       Comedy     19 0.922671237            412       278
#> 3       Action     17 1.069718544            295       155
#> 4      Romance     17 0.555144865            237       160
#> 5    Adventure     15 0.923450746            195       101
#> 6    Animation     15 0.813375869            149        75
#> 7  Documentary     14 0.664612219            138       152
#> 8    Biography     13 0.744557686            185       108
#> 9     Thriller     13 0.637683585            158        96
#> 10     History     13 0.564867087            117        62
#> 11       Crime     12 0.853922379            269       153
#> 12     Fantasy     12 0.439408607             65        34
#> 13     Mystery     12 0.391973213             76        41
#> 14      Family     11 0.378315121             64        36
#> 15       Music     10 0.359710616             73        52
#> 16         War     10 0.267933813             53        32
#> 17      Sci-Fi      9 0.265024671             31        16
#> 18      Horror      9 0.243435685             19        11
#> 19       Sport      7 0.197994819             44        28
#> 20     Musical      7 0.121968041             19        12
#> 21        News      2 0.022707980              2         1
#> 22     Western      1 0.001577287              1         1
```
