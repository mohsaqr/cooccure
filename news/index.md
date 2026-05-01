# Changelog

## cooccure 0.1.1

CRAN release: 2026-04-24

- First CRAN release. Package renamed from `cooccur` (GitHub-only
  development name) to `cooccure` to avoid collision with an unrelated
  archived CRAN package of the same name.
- Internal engine rewritten on top of
  [`Matrix::sparseMatrix`](https://rdrr.io/pkg/Matrix/man/sparseMatrix.html)
  /
  [`Matrix::crossprod`](https://rdrr.io/pkg/Matrix/man/matmult-methods.html).
  The previous implementation allocated dense `n x k` and `k x k`
  matrices, which hit R’s vector memory limit on corpora with many
  documents and items (e.g. citation networks \> ~100k unique
  references). The sparse rewrite stays in triplet form end-to-end and
  scales linearly with the number of non-zero co-occurrences.
- `attr(x, "matrix")` and `attr(x, "raw_matrix")` are now sparse Matrix
  objects.
  [`as_matrix()`](https://saqr.me/cooccure/reference/as_matrix.md)
  densifies them on demand so existing downstream code keeps working.
- Added `Matrix` to `Imports`.
- Delimited parsers (`.co_parse_delimited`, `.co_parse_multi_delimited`)
  vectorised: [`trimws()`](https://rdrr.io/r/base/trimws.html), NA/empty
  filtering, and per-row deduplication now run as single C-level calls
  over the flattened token vector rather than as per-row R calls. Cuts
  overall runtime on a 166k-row x 20-items-per-row citation corpus from
  ~6.2 s to ~3.4 s (~1.8x faster).

## cooccure 0.1.0

- Initial development release (distributed as `cooccur` on GitHub).
- [`cooccurrence()`](https://saqr.me/cooccure/reference/cooccurrence.md)
  (alias [`co()`](https://saqr.me/cooccure/reference/cooccurrence.md))
  builds co-occurrence networks from six input formats: delimited
  fields, multi-column delimited, long/bipartite, binary matrices, wide
  sequences (`field = "all"`), and lists of character vectors.
- Eight similarity measures: `none`, `jaccard`, `cosine`, `inclusion`,
  `association`, `dice`, `equivalence`, `relative`.
- Eight scaling methods: `minmax`, `log`, `log10`, `binary`, `zscore`,
  `sqrt`, `proportion`, `none`.
- `counting = "fractional"` implements the Perianes-Rodriguez et al.
  2016. weighted pair count.
- `weight_by` parameter supports weighted long-format input (e.g. LDA
  topic-document probabilities).
- `split_by` computes a separate network per group and returns a
  combined edge data frame.
- `output` argument returns edges in default, Gephi, `igraph`,
  `cograph`, or matrix form.
- S3 converters:
  [`as_matrix()`](https://saqr.me/cooccure/reference/as_matrix.md),
  [`as_igraph()`](https://saqr.me/cooccure/reference/as_igraph.md),
  [`as_tidygraph()`](https://saqr.me/cooccure/reference/as_tidygraph.md),
  [`as_cograph()`](https://saqr.me/cooccure/reference/as_cograph.md),
  [`as_netobject()`](https://saqr.me/cooccure/reference/as_netobject.md).
- Shiny app accessible via
  [`launch_app()`](https://saqr.me/cooccure/reference/launch_app.md).
