# cooccure 0.1.2

* `cooccurrence()` gains a `window =` parameter for sliding-window
  co-occurrence on ordered sequence input (lists of vectors and wide
  TraMineR-style data frames via `field = "all"`). Each window of
  `w` consecutive positions becomes one transaction; states inside
  the same window co-occur. `window = sequence_length` reduces to
  the existing bag-of-states behaviour. TraMineR void markers (`NA`,
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
  vectorised: `trimws()`, NA/empty filtering, and per-row deduplication
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
