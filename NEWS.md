# cooccur 0.1.1

* Internal engine rewritten on top of `Matrix::sparseMatrix` /
  `Matrix::crossprod`. Previously `cooccurrence()` allocated dense `n x k`
  and `k x k` matrices, which hit R's vector memory limit on corpora with
  many documents and items (e.g. citation networks > ~100k unique
  references). The sparse rewrite stays in triplet form end-to-end and
  scales linearly with the number of non-zero co-occurrences.
* `attr(x, "matrix")` and `attr(x, "raw_matrix")` are now sparse Matrix
  objects. `as_matrix()` densifies them on demand so existing downstream
  code keeps working.
* Added `Matrix` to `Imports`.
* Delimited parsers (`.co_parse_delimited`, `.co_parse_multi_delimited`)
  vectorised: `trimws()`, NA/empty filtering, and per-row deduplication
  now run as single C-level calls over the flattened token vector rather
  than as 166k+ per-row R calls. Cuts overall runtime on a 166k-row x
  20-items-per-row citation corpus from ~6.2 s to ~3.4 s (1.8x faster).

# cooccur 0.1.0

* Initial release.
* `cooccurrence()` (alias `co()`) builds co-occurrence networks from six input
  formats: delimited fields, multi-column delimited, long/bipartite, binary
  matrices, wide sequences (`field = "all"`), and lists of character vectors.
* Eight similarity measures: `none`, `jaccard`, `cosine`, `inclusion`,
  `association`, `dice`, `equivalence`, `relative`.
* Eight scaling methods: `minmax`, `log`, `log10`, `binary`, `zscore`, `sqrt`,
  `proportion`, `none`.
* `counting = "fractional"` implements the Perianes-Rodriguez et al. (2016)
  weighted pair count.
* `weight_by` parameter supports weighted long-format input (e.g. LDA
  topic-document probabilities).
* `split_by` computes a separate network per group and returns a combined
  edge data frame.
* `output` argument returns edges in default, Gephi, `igraph`, `cograph`, or
  matrix form.
* S3 converters: `as_matrix()`, `as_igraph()`, `as_tidygraph()`,
  `as_cograph()`, `as_netobject()`.
* Shiny app accessible via `launch_app()`.
