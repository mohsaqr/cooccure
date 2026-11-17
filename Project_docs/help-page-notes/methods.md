# Implementation notes removed from the print/summary/plot help pages (2026-11-17)

- `.co_summary_data()` computes everything; `summary()` returns it,
  `print()` formats it. A split result is detected by the presence of a
  `group` column, so `aggregate_by` results (one network) keep pooled
  metrics.
- Degree in a directed (`relative`) network is in-degree plus out-degree;
  possible edges are `n (n - 1)`.
- Heatmap: rows drawn top to bottom in matrix order (`t(mat[n:1, ])` for
  `image()`); colours from `grDevices::colorRampPalette()`: white to
  `#4A6FE3` (100 steps, `zlim = c(0, max)`) or `#D33F6A`-white-`#4A6FE3`
  (101 steps, symmetric `zlim`) when any weight is negative.
- Degree plot fill `#56B4E9` (Okabe-Ito sky blue), border black.
