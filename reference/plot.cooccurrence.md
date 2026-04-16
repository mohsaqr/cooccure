# Plot a cooccurrence network

Plots the co-occurrence matrix as a heatmap. If igraph is available,
plots a network graph instead.

## Usage

``` r
# S3 method for class 'cooccurrence'
plot(x, type = c("heatmap", "network"), ...)
```

## Arguments

- x:

  A `cooccurrence` data frame.

- type:

  Character. `"heatmap"` (default) or `"network"` (requires igraph).

- ...:

  Passed to the plotting function.

## Value

Invisibly returns `x`.

## Examples

``` r
res <- cooccurrence(list(c("A","B","C"), c("B","C"), c("A","C")))
plot(res)
```
