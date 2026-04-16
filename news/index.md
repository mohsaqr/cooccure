# Changelog

## cooccur 0.1.0

- Initial release.
- [`cooccurrence()`](http://saqr.me/cooccur/reference/cooccurrence.md)
  (alias [`co()`](http://saqr.me/cooccur/reference/cooccurrence.md))
  builds co-occurrence networks from six input formats: delimited
  fields, multi-column delimited, long/bipartite, binary matrices, wide
  sequences (`field = "all"`), and lists of character vectors.
- Eight similarity measures: `none`, `jaccard`, `cosine`, `inclusion`,
  `association`, `dice`, `equivalence`, `relative`.
- Eight scaling methods: `minmax`, `log`, `log10`, `binary`, `zscore`,
  `sqrt`, `proportion`, `none`.
- `counting = "fractional"` implements the Perianes-Rodriguez et
  al. (2016) weighted pair count.
- `weight_by` parameter supports weighted long-format input (e.g. LDA
  topic-document probabilities).
- `split_by` computes a separate network per group and returns a
  combined edge data frame.
- `output` argument returns edges in default, Gephi, `igraph`,
  `cograph`, or matrix form.
- S3 converters:
  [`as_matrix()`](http://saqr.me/cooccur/reference/as_matrix.md),
  [`as_igraph()`](http://saqr.me/cooccur/reference/as_igraph.md),
  [`as_tidygraph()`](http://saqr.me/cooccur/reference/as_tidygraph.md),
  [`as_cograph()`](http://saqr.me/cooccur/reference/as_cograph.md),
  [`as_netobject()`](http://saqr.me/cooccur/reference/as_netobject.md).
- Shiny app accessible via
  [`launch_app()`](http://saqr.me/cooccur/reference/launch_app.md).
