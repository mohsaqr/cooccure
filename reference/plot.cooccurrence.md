# Plot a cooccurrence network

Plots the co-occurrence matrix as a heatmap, an igraph network, or a
base-R degree distribution. The heatmap shows which item pairs carry the
heaviest weights; the degree distribution shows whether connectivity is
concentrated on a few hub items or spread evenly. For
publication-quality network drawings, convert with
[`as_cograph`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and use
[`cograph::splot()`](https://sonsoles.me/cograph/reference/splot.html).

## Usage

``` r
# S3 method for class 'cooccurrence'
plot(x, type = c("heatmap", "network", "degree"), ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- type:

  Character. `"heatmap"` (default), `"network"` (requires igraph), or
  `"degree"` for a base-R degree distribution bar plot.

- ...:

  Passed to the plotting function:
  [`graphics::image()`](https://rdrr.io/r/graphics/image.html) for the
  heatmap, [`plot()`](https://rdrr.io/r/graphics/plot.default.html) on
  the `igraph` object for the network, and
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html) for
  the degree distribution (where they override the default labels and
  colors).

## Value

Invisibly returns `x`, unchanged. Called for the side effect of drawing
on the current graphics device.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C"), c("C","D")))
plot(res)

plot(res, type = "degree")
```
