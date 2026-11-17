# Open the interactive co-occurrence explorer

`launch_app()` opens an interactive co-occurrence explorer: a shiny
application in which a data set (the bundled
[demo](https://pak.dynasite.org/cooccure/reference/demo.md) table or an
uploaded file) is turned into a network with
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
and shown as a table and a plot. The explorer is a quick way to see how
the choice of items, transactions, similarity measure and filters
changes a co-occurrence network before writing the analysis as code.

It requires the shiny and DT packages and an interactive session.

## Usage

``` r
launch_app(...)
```

## Arguments

- ...:

  Passed to [`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html) (e.g.
  `port`, `launch.browser`).

## Value

No return value; called to run the application, which blocks the session
until it is closed.

## Conditions

`cooccure_missing_package` when shiny or DT is not installed.

## See also

[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md);
[demo](https://pak.dynasite.org/cooccure/reference/demo.md).

## Examples

``` r
if (interactive()) {
  launch_app()
}
```
