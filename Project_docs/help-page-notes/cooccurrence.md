# Implementation notes removed from `?cooccurrence` (2026-11-17)

Kept for maintainers; the help page now describes the method, arguments,
return structure and conditions only.

- Argument names follow the citenets convention (`field`, `by`, `sep`).
- The first thirteen arguments reproduce the CRAN 0.1.1 signature, so
  positional calls written against 0.1.1 keep their meaning. Arguments added
  later (`vars`, event-log arguments, `group`, `aggregate_by`, `aggregate`,
  `window`, `lambda`) follow them.
- Engine: transactions -> sparse incidence matrix `B` (`Matrix::sparseMatrix`)
  -> `C = crossprod(B)`, diagonal zeroed. Fractional counting bakes
  `sqrt(1/(n_r - 1))` into each row of `B`, so `crossprod(B)` gives the
  Perianes-Rodriguez weighted counts. Attention counting cannot be factored
  through `B`; `.co_attention_pairs()` builds `C` from per-pair triplets.
- `matrix` and `raw_matrix` attributes are sparse `Matrix` objects
  (symmetric `dsCMatrix` for undirected, general `dgCMatrix` for
  `relative`); `as_matrix()` densifies on demand. Both are rebuilt from the
  surviving edges after `threshold`/`top_n`, so they agree with the edge list.
- Delimited parsing: whitespace around items is trimmed, empty strings and
  `NA` are dropped, duplicates within a row are removed (one global
  `duplicated()` pass rather than per-row `unique()`).
- Wide sequences and windows drop TraMineR void markers (`NA`, `""`, `"%"`,
  `"*"`, `"NaN"`) before windowing. `stats::embed()` returns windows
  most-recent-first; they are reversed before deduplication so that
  attention counting reads gaps in reading order.
- `vars` is resolved like `subset(select = )`: the expression is evaluated
  in a list mapping column names to positions, falling back to the caller's
  environment. Repeated columns are deduplicated; `NA` counts as absent.
- `nestimate_data` input uses its `sequence_data` (wide) component.
- Scaling statistics (min/max, mean/sd, sum) are taken over the full
  non-zero population of the stored matrix: both triangles for symmetric
  measures, every directed cell for `relative`.
- `relative`: `W[i, j] = C[i, j] / rowSums(C)[i]`; the edge list holds both
  directions with the same raw `count`. `top_n` ranks directed rows; this
  matches `Nestimate::cooccurrence()` from Nestimate 1.0.11 on, which also
  treats `relative` as directed.
- `top_n` truncates ties strictly at N (`Nestimate` keeps every tied edge).
- `split_by` attributes: `groups` (groups that produced edges),
  `group_items`, `group_frequencies`, `group_transactions`; per-group
  `matrix`/`items` are not stored. `.co_select_group()` rebuilds a single
  network object from them for the converters.
- `aggregate_by`: count is summed; `mean`/`min` are taken over the groups in
  which a pair occurs (absence is not counted as zero).
