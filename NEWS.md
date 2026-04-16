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
