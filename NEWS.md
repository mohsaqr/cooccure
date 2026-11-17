# cooccure 0.5.0

This release collects the changes made since 0.4.0, the current CRAN
version.

## Directed networks for `similarity = "relative"`

* `similarity = "relative"` divides each row of the count matrix by its sum,
  so the weight from item A to item B differs from the weight from B to A.
  The edge list now holds one row per direction instead of one row per pair,
  and `as_igraph()`, `as_tidygraph()`, `as_cograph()` and `as_netobject()`
  return directed networks for it. `output = "gephi"` marks these edges
  `"Directed"`. `threshold` and `top_n` apply to each direction. Printing and
  `summary()` count ordered pairs for the density of a directed network.
  The other seven measures are unchanged.

## Converting networks built with `split_by`

* A `split_by` result stacks one network per group. `as_matrix()`,
  `as_igraph()`, `as_tidygraph()`, `as_cograph()`, `as_netobject()` and
  `plot()` gain a `group` argument that converts or draws one group's
  network, with that group's items and transaction count. Without `group`
  they raise a `cooccure_grouped_input` error, as does
  `cooccurrence(..., split_by = , output = "igraph" / "cograph" / "matrix")`.
  Previously these calls combined the groups into one network.
* For a `split_by` result, the node table (`as.data.frame(x, what = "nodes")`
  or `as.data.frame(summary(x))`) has one row per node and group, computed
  within each group, with a leading `group` column.

## Results and accessors

* `summary()` returns a `summary.cooccurrence` object and no longer prints
  while computing it; printing the object shows the same block as before.
* New `as.data.frame()` method for `cooccurrence` objects: `what = "edges"`
  (default) gives the bare edge table, `what = "nodes"` the node table and
  `what = "groups"` the group table.
* `as.data.frame()` on a `summary.cooccurrence` object returns the node
  table (`what = "nodes"`) or the group table (`what = "groups"`).
* `aggregate_by` results store the summed counts as the raw matrix, so
  `as_matrix(x, type = "raw")` returns counts; it previously returned the
  aggregated weights.

## Arguments and conditions

* User-facing errors are classed conditions inheriting from `cooccure_error`
  (`cooccure_bad_input`, `cooccure_incompatible_args`,
  `cooccure_grouped_input`, `cooccure_empty_input`,
  `cooccure_missing_package`), documented under "Conditions" on each help
  page.
* `threshold` accepts negative values, which keep weights at or above the
  value; this allows filtering networks scaled with `scale = "zscore"`.
  `threshold = 0` still keeps every edge.
* Columns named in `field`, `by`, `weight_by`, `split_by` and
  `aggregate_by` are checked before any group is computed, so a misspelled
  column is reported by name. With `split_by` and `aggregate_by`, a group
  left without transactions is dropped; any other error in a group is raised
  with the group named. `aggregate_by` previously dropped such groups
  without a message.
* `weight_by` combined with `counting = "fractional"` or
  `counting = "attention"` raises a `cooccure_incompatible_args` error;
  the counting method was previously ignored for weighted input.

## Plots

* The heatmap uses a white-to-blue scale for non-negative weights and a
  red-white-blue scale centered on zero when weights can be negative. The
  degree distribution uses a color-blind-safe fill.

## Documentation

* New vignette "Co-occurrence networks" and pkgdown guides on input formats,
  similarity measures, counting, sequences and event logs, comparing groups,
  exporting, and the verification against `Nestimate::cooccurrence()`, with
  two case studies on the IMDb data. The earlier IMDb tutorial is divided
  among them.

# cooccure 0.4.0

* `cooccurrence()` gains a `window =` parameter for sliding-window
  co-occurrence on ordered sequence input (lists of vectors and wide
  TraMineR-style data frames via `field = "all"`). Each window of
  `w` consecutive positions becomes one transaction; states inside
  the same window co-occur. `window = sequence_length` reduces to
  the existing bag-of-states behavior. TraMineR void markers (`NA`,
  `""`, `"%"`, `"*"`, `"NaN"`) are dropped before windowing. Pure
  base R via `embed()`.
* `cooccurrence()` gains `aggregate_by =` and `aggregate =`
  parameters. `aggregate_by` groups the data by a column (e.g.
  journal id), computes the per-group co-occurrence network with
  whatever `similarity` / `counting` / `scale` / `window` was
  chosen, then combines the per-group edge weights into ONE final
  network. `aggregate = c("sum", "mean", "min", "max")` controls
  the combiner; `count` is always summed. Differs from `split_by`,
  which keeps groups separate. Cannot be combined with `split_by`.
  `threshold` and `top_n` apply after aggregation.
* `counting = "attention"` adds positional gap-decay weighting:
  each pair within an ordered transaction contributes
  `exp(-|pos_i - pos_j| / lambda)` to the edge. Closer positions
  give a stronger edge, distant pairs decay. Matches the
  `tna::build_model(type = "attention")` semantics, undirected.
  The new `lambda =` parameter (default `1.0`) controls the decay
  rate.
* `group =` is now accepted as an alias for `split_by =`.
* `summary.cooccurrence()` now returns a structured summary object with
  network size, density, mean degree, isolates, node-level degree and
  strength, and optional group-level summaries.
* `print.cooccurrence()` now shows a compact diagnostic header before
  the edge preview, including density, mean degree, isolates, method
  metadata, and top nodes.
* `plot.cooccurrence(type = "degree")` adds a base R degree-distribution
  plot.
* `cooccurrence()` accepts a raw event log directly via `action =`
  (the event column), with optional `actor =`, `time =`, `session =`,
  `order =`, and `time_threshold =` (default 900 seconds). The log is
  sessionized into ordered sequences and each session becomes one
  transaction, so `window =` and `counting = "attention"` apply.
  Sessionization — timestamp parsing and gap splitting — is delegated
  to `Nestimate::prepare()` rather than reimplemented, so `Nestimate`
  is required for this input only.
* `cooccurrence()` gains `vars =`, naming the indicator (one-hot)
  columns directly. The specification is resolved like `select` in
  base `subset()`, so a bare range (`vars = A:D`), bare names
  (`vars = c(A, B, C)`), positions (`vars = 2:5`), negative selection
  (`vars = -c(id, note)`), a logical mask, and a plain character
  vector all work. Other columns — ids, timestamps, metadata — are
  ignored, so a one-hot table no longer has to be stripped down to a
  bare matrix first. Cell values are read as presence, so count tables
  such as document-term matrices work alongside `0`/`1` and
  `TRUE`/`FALSE`.
* Logical (`TRUE`/`FALSE`) indicator tables are now auto-detected;
  previously only numeric `0`/`1` was recognized.
* `NA` in an indicator table is treated as absent. It previously
  reached `Matrix::sparseMatrix()` as an `NA` index and failed with an
  internal error.
* `cooccurrence()` accepts a `nestimate_data` object from
  `Nestimate::prepare()` and uses its `sequence_data`, so event logs
  can be sessionized by `prepare()` (time gaps, timestamp parsing) and
  networked here without duplicating that logic. Passing one used to
  fall into the list-of-transactions branch and silently produce items
  built from the object's internal components.
* Bug fix: unknown arguments were silently swallowed by `...`, so a
  typo such as `simliarity = "jaccard"` returned raw counts with no
  warning. Unknown or unnamed arguments now raise an error.
* `as.data.frame()` on a `summary.cooccurrence` object returns tidy
  node-level metrics (`what = "nodes"`, the default) or group-level
  metrics (`what = "groups"`), so callers no longer reach into the
  summary object's internals.
* `similarity = "relative"` is asymmetric, so each direction is now
  thresholded on its own value. Filtering by the undirected pair could
  retain a direction whose weight was below `threshold`.
* Added a cross-implementation test suite pinning `cooccurrence()` to
  `Nestimate::cooccurrence()` across all eight similarity measures, all
  five shared input formats, `min_occur`, `threshold`, `top_n`, their
  combinations, degenerate inputs, and randomized networks. The two
  agree exactly once conventions are aligned: Nestimate stores item
  frequency on the matrix diagonal (`diagonal = TRUE`) where cooccure
  zeroes it, and Nestimate keeps every edge tied at the `top_n` cut
  where cooccure truncates strictly at N.
* Bug fix: `weight_by` combined with `min_occur > 1` errored with
  "'dims' must contain all (i,j) pairs". The binary companion matrix was
  built from unfiltered column indices against filtered dimensions.
* Bug fix: `min_occur` support for weighted input counted rows rather
  than distinct documents, so duplicate rows for one document could
  keep an item that appears in only that document.
* Bug fix: `threshold` and `top_n` filtered the edge list but not the
  stored matrix, so `as_matrix()`, the heatmap, and the cograph and
  netobject converters disagreed with the printed edges (`top_n = 1`
  returned one edge but a three-edge matrix). The matrix is now rebuilt
  from the surviving edges.
* Bug fix: with `counting = "attention"`, a window covering the whole
  sequence did not reproduce the unwindowed result. `embed()` emits each
  window most-recent-first, and attention reads positional gaps off the
  transaction, so the decay was mirrored. Windows are restored to
  reading order before deduplication; set-based counting is unaffected.
* `as_igraph()` and `as_matrix()` now accept `output = "gephi"` objects,
  whose columns are named `Source`/`Target`/`Weight`/`Count`. They
  previously failed with "undefined columns selected".
* A group that fails during `split_by` now warns and names the group.
  Genuinely edgeless groups are still dropped quietly.
* `threshold = 0` is documented as meaning no filtering rather than
  "drop negative weights", so centering scalings such as
  `scale = "zscore"` keep their negative half.
* Bug fix: the argument order now reproduces the CRAN 0.1.1 signature
  for its first thirteen arguments, so positional calls written against
  0.1.1 keep their meaning. Arguments added in 0.1.2 (`vars`, the
  event-log arguments, `group`, `aggregate_by`, `aggregate`, `window`,
  `lambda`) follow them.
* Bug fix: a column repeated in `vars` was counted twice by the sparse
  builder, inflating weight and count for every pair involving it.
  Selected columns are now deduplicated.
* Bug fix: a `split_by` result inherited the FIRST group's `matrix`,
  `items`, `frequencies`, and `n_transactions` attributes from
  `rbind()`, so `as_matrix()` and the other converters silently
  described only that group. Those attributes are now dropped from
  split results, and `as_matrix()` rebuilds from the full edge list.
  Per-group support is recorded in the new `group_items` and
  `group_transactions` attributes.
* Bug fix: the `groups` attribute of a `split_by` result listed every
  input level, including groups that produced no edges and were
  dropped from the data. It now lists only the groups present.
* Bug fix: per-group density in `summary()` counted only nodes that
  appear in an edge, so a group containing an isolated node reported a
  density above its true value (a group with edge `A-B` plus isolated
  `C` reported density 1 instead of 1/3).
* Bug fix: `summary()` and `print()` reported pooled simple-graph
  metrics for `split_by` results, where a node pair can occur once per
  group. Density could exceed 1 and node degree could exceed
  `n_nodes - 1`. `density`, `mean_degree`, and `possible_edges` are now
  `NA` for split results, and the per-group table reports the correct
  values.

# cooccure 0.1.1

* First CRAN release. Package renamed from `cooccur` (GitHub-only
  development name) to `cooccure` to avoid collision with an unrelated
  archived CRAN package of the same name.
* Internal engine rewritten on top of `Matrix::sparseMatrix` /
  `Matrix::crossprod`. The previous implementation allocated dense
  `n x k` and `k x k` matrices, which hit R's vector memory limit on
  corpora with many documents and items (e.g. citation networks
  > ~100k unique references). The sparse rewrite stays in triplet form
  end-to-end and scales linearly with the number of non-zero
  co-occurrences.
* `attr(x, "matrix")` and `attr(x, "raw_matrix")` are now sparse Matrix
  objects. `as_matrix()` densifies them on demand so existing downstream
  code keeps working.
* Added `Matrix` to `Imports`.
* Delimited parsers (`.co_parse_delimited`, `.co_parse_multi_delimited`)
  vectorized: `trimws()`, NA/empty filtering, and per-row deduplication
  now run as single C-level calls over the flattened token vector rather
  than as per-row R calls. Cuts overall runtime on a 166k-row x
  20-items-per-row citation corpus from ~6.2 s to ~3.4 s (~1.8x faster).

# cooccure 0.1.0

* Initial development release (distributed as `cooccur` on GitHub).
* `cooccurrence()` (alias `co()`) builds co-occurrence networks from six
  input formats: delimited fields, multi-column delimited, long/bipartite,
  binary matrices, wide sequences (`field = "all"`), and lists of
  character vectors.
* Eight similarity measures: `none`, `jaccard`, `cosine`, `inclusion`,
  `association`, `dice`, `equivalence`, `relative`.
* Eight scaling methods: `minmax`, `log`, `log10`, `binary`, `zscore`,
  `sqrt`, `proportion`, `none`.
* `counting = "fractional"` implements the Perianes-Rodriguez et al.
  (2016) weighted pair count.
* `weight_by` parameter supports weighted long-format input (e.g. LDA
  topic-document probabilities).
* `split_by` computes a separate network per group and returns a combined
  edge data frame.
* `output` argument returns edges in default, Gephi, `igraph`, `cograph`,
  or matrix form.
* S3 converters: `as_matrix()`, `as_igraph()`, `as_tidygraph()`,
  `as_cograph()`, `as_netobject()`.
* Shiny app accessible via `launch_app()`.
