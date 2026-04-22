# Launch the cooccure Shiny explorer

Opens an interactive Shiny application for building and exploring
co-occurrence networks. Requires the shiny and DT packages.

## Usage

``` r
launch_app(...)
```

## Arguments

- ...:

  Passed to [`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html) (e.g.
  `port`, `launch.browser`).

## Value

Called for its side effect (launches the app). No return value.

## Examples

``` r
if (interactive()) {
  launch_app()
}
```
