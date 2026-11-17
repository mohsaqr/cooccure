# Implementation notes removed from the converter help pages (2026-11-17)

- `as_matrix()` returns the stored sparse attribute densified; when the
  attribute is absent (one group of a split result, or an object whose
  attributes were dropped) the matrix is rebuilt from the edge list. Gephi
  column names (`Source`/`Target`/`Weight`/`Count`) are recognised.
- `as_igraph()` passes `vertices` built from the `items` attribute plus any
  edge endpoints, so isolates survive; `...` goes to
  `igraph::graph_from_data_frame()`.
- `as_cograph()` and `as_netobject()` hand-build the foreign classes
  (`cograph_network`; `c("netobject", "cograph_network")`) from
  `as_matrix()`: upper triangle for undirected networks, every non-zero
  off-diagonal cell for `relative`. `as_netobject()` sets `data = NULL`,
  `method = "cooccurrence"`, and `meta$tna$method = "cooccurrence"`.
- cograph >= 2.7 exports its own `as_cograph()`; attaching cograph after
  cooccure masks this generic (see the owner-decision note in
  AGENT-NOTE-REVIEW-2026-11-17.md).
