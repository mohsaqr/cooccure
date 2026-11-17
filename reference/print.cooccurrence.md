# Print a co-occurrence network

[`print()`](https://rdrr.io/r/base/print.html) shows a co-occurrence
network as a short diagnostic header followed by the strongest edges.
The header reports what is first looked at in any network before its
edges are read: how many items and edges it has, how dense it is, which
similarity, counting and scaling produced the weights, how many items
are isolated, and which items are the hubs.

For a network built with `split_by`, the pooled density and degree are
omitted, since they are undefined when several networks are stacked; use
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
for one row of metrics per group. A directed network
(`similarity = "relative"`) is marked as such and its density is
computed over ordered pairs.

## Usage

``` r
# S3 method for class 'cooccurrence'
print(x, n = 10L, ...)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- n:

  Number of edges to show (default 10).

- ...:

  Ignored.

## Value

`x`, invisibly and unchanged. Called for the printed output.

## See also

[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
for network, node and group metrics;
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
for the edge and node tables.

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard")
print(net, n = 5)
#> # cooccurrence: 22 nodes, 129 edges | density: 0.5584 | mean degree: 11.7273 | 1000 transactions
#> # similarity: jaccard | counting: full
#> # possible edges: 231 | isolates: 0
#> # top nodes: Drama(deg=20,str=1.178), Comedy(deg=19,str=0.9227), Action(deg=17,str=1.07), Romance(deg=17,str=0.5551), Adventure(deg=15,str=0.9235)
#>       from          to    weight count
#>  Adventure   Animation 0.2846715    39
#>     Action       Crime 0.2369478    59
#>     Comedy       Drama 0.2111554   159
#>     Action   Adventure 0.2075472    44
#>  Biography Documentary 0.2037037    44
#> # ... 124 more edges
```
