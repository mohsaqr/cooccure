# Plot a co-occurrence network

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws one of
three displays of a co-occurrence network: a heatmap of the weight
matrix (default), a network drawing through igraph, or the degree
distribution as a bar chart. The heatmap shows which item pairs carry
the heaviest weights and which never co-occur. The network drawing
places linked items near one another. The degree distribution shows
whether connectivity is concentrated on a few hub items or spread
evenly.

The heatmap uses a white-to-blue scale for non-negative weights and a
red-white-blue scale centered on zero when weights can be negative
(`scale = "zscore"`); rows are the source items, which matters for the
directed `similarity = "relative"` network.

For a result built with `split_by`, `group` names the network to draw.
For publication-quality network drawings, convert with
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and use
[`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html).

## Usage

``` r
# S3 method for class 'cooccurrence'
plot(x, type = c("heatmap", "network", "degree"), group = NULL, ...)
```

## Arguments

- x:

  A `cooccurrence` edge list from
  [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

- type:

  `"heatmap"` (default), `"network"` (requires igraph), or `"degree"`.

- group:

  For a result built with `split_by`, the name of the group to draw.
  `NULL` (default) for an unsplit result.

- ...:

  Passed to [`graphics::image()`](https://rdrr.io/r/graphics/image.html)
  for the heatmap,
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on the
  `igraph` object for the network, and
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html) for
  the degree distribution, where they override the defaults (for
  instance `col` or `main`).

## Value

`x`, invisibly and unchanged. Called for the plot drawn on the current
graphics device.

## Conditions

`cooccure_grouped_input` when `x` was built with `split_by` and `group`
is `NULL`; `cooccure_missing_package` for `type = "network"` without
igraph.

## See also

[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
for publication network drawings;
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
for the numbers behind the degree plot.

## Examples

``` r
net <- cooccurrence(movies, field = "genres", sep = ",",
                    similarity = "jaccard", min_occur = 50)
plot(net)

plot(net, type = "degree")
```
