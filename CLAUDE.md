# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

`cooccure` is an R package (v0.1.1) for building co-occurrence networks from arbitrary input formats. It returns tidy edge data frames with eight similarity measures, optional weight scaling, and converters to igraph, cograph, Nestimate, and tidygraph. (The package was developed on GitHub as `cooccur` and renamed to `cooccure` for CRAN submission because an unrelated archived CRAN package already holds the `cooccur` name.)

## Common Commands

```bash
# Load package in-place
Rscript -e 'devtools::load_all(".")'

# Run all tests
Rscript -e 'devtools::test(".")'

# Run a single test file
Rscript -e 'testthat::test_file("tests/testthat/test-cooccurrence.R")'

# Build documentation
Rscript -e 'devtools::document(".")'

# Quick package check (skip slow extras)
Rscript -e 'devtools::check(".", args = c("--no-tests", "--no-examples", "--no-vignettes", "--no-manual"))'

# Render the vignette to HTML
Rscript -e 'rmarkdown::render("vignettes/imdb-tutorial.Rmd", output_dir = "tmp/")'
```

## Architecture

### Source files (`R/`)

| File | Role |
|------|------|
| `cooccurrence.R` | Public API: `cooccurrence()` / `co()` alias, `split_by` dispatch, all `.co_*` internal helpers |
| `converters.R` | S3 generics + methods: `as_matrix`, `as_igraph`, `as_tidygraph`, `as_cograph`, `as_netobject` |
| `methods.R` | S3 methods: `print.cooccurrence`, `summary.cooccurrence`, `plot.cooccurrence` |

### Core pipeline

`cooccurrence()` → (if `split_by`) split + lapply → `.co_core()` per group → combine

`.co_core()` calls in sequence:
1. `.co_detect_format()` — auto-detects one of six formats: `delimited`, `multi_delimited`, `long`, `binary`, `wide`, `list`
2. `.co_parse_*()` — format-specific parser returns a list of character vectors (transactions)
3. `.co_transactions_to_matrix()` — builds the binary B matrix
4. `.co_apply_counting()` — applies `full` or `fractional` weighting to B rows (fractional: each row scaled by `sqrt(1/(n-1))` so `crossprod` gives Perianes-Rodriguez weighted counts)
5. `.co_compute_matrix()` — `crossprod(B)` for both weighted C and raw C
6. `.co_normalize()` — computes one of eight similarity measures from C and item frequencies
7. `.co_scale()` — optional post-normalization scaling
8. `.co_matrix_to_edges()` — upper triangle → tidy edge data frame

### `cooccurrence` S3 class

The return value is a `data.frame` with class `c("cooccurrence", "data.frame")`. All metadata is stored as attributes: `matrix` (normalized), `raw_matrix` (counts), `items`, `frequencies`, `similarity`, `scale`, `threshold`, `min_occur`, `n_transactions`, `n_items`. When `split_by` is used, a `group` column is added and attributes `split_by` / `groups` are set (but per-group matrices are not stored).

### Output format dispatch

`output =` argument in `cooccurrence()` short-circuits via `.co_format_output()`:
- `"gephi"` — renames columns in-place, preserves `cooccurrence` class and attributes
- `"igraph"` / `"cograph"` / `"matrix"` — delegates to the corresponding `as_*` converter

### Converters

All converters are S3 generics in `converters.R`. `as_cograph` and `as_netobject` build from `as_matrix(type = "normalized")` and reconstruct an edge list from the upper triangle of the matrix (not from the edge data frame directly).

## Dependencies

All heavy dependencies (`igraph`, `cograph`, `Nestimate`, `tidygraph`) are in `Suggests`, not `Imports`. Every converter guards with `requireNamespace(..., quietly = TRUE)` and stops with an informative message. Do not add `Imports` without a strong reason.

## Test file

All tests are in `tests/testthat/test-cooccurrence.R`. Tests cover:
1. Return type and column names
2. All six input formats + cross-format equivalence
3. All eight similarity measures with exact expected values
4. All eight scaling methods
5. `threshold`, `min_occur`, `top_n` parameters
6. Attribute correctness
7. All five converters (each guarded with `skip_if_not_installed`)
8. Edge cases (empty input, single-item transactions)
9. `split_by` (group column, per-group networks, `top_n` per group, skipping empty groups)
10. All output format variants

## Sample data

`inst/extdata/imdb_movies.csv` — 1,000 IMDB movies (rating ≥ 7.0, 1970–2024) with a comma-delimited `genres` column.  
`inst/extdata/imdb_actor_movie.csv` — long-format actor–movie bipartite table.
