# Launch the cooccur Shiny explorer

Opens an interactive Shiny application for building and exploring
co-occurrence networks. Requires the shiny, DT, and visNetwork packages.

## Usage

``` r
launch_app(...)
```

## Arguments

- ...:

  Passed to [`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html) (e.g.
  `port`, `launch.browser`).

## Value

Called for its side effect (launches the app).

## Examples

``` r
if (FALSE) { # \dontrun{
launch_app()
} # }
```
