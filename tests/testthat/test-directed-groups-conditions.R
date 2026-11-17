# Regression and calibration tests for the 0.4.4 fixes: directed
# `relative` networks, per-group conversion of split results, classed
# conditions instead of silent failures, the summary object, and the
# heatmap scale.

.tx4 <- list(c("A", "B", "C"), c("A", "B"), c("B", "C"), c("A", "D"))

.split_df <- function() {
  data.frame(grp = c("X", "X", "Y", "Y"),
             kw = c("A;B", "A;B", "A;B;C", "B;C"),
             stringsAsFactors = FALSE)
}

.edge_weight <- function(x, from, to) {
  e <- as.data.frame(x)
  e$weight[e$from == from & e$to == to]
}

# ---- 1. similarity = "relative" is directed ------------------------------

test_that("relative keeps both directions with hand-computed weights", {
  r <- cooccurrence(.tx4, similarity = "relative")
  ## C: A-B 2, A-C 1, A-D 1, B-C 2; row sums A 4, B 4, C 3, D 1.
  expect_equal(nrow(r), 8L)
  expect_equal(.edge_weight(r, "D", "A"), 1)
  expect_equal(.edge_weight(r, "A", "D"), 1 / 4)
  expect_equal(.edge_weight(r, "C", "B"), 2 / 3)
  expect_equal(.edge_weight(r, "B", "C"), 2 / 4)
  expect_equal(.edge_weight(r, "C", "A"), 1 / 3)
  ## Raw counts are the same in both directions.
  e <- as.data.frame(r)
  expect_equal(e$count[e$from == "A" & e$to == "B"],
               e$count[e$from == "B" & e$to == "A"])
})

test_that("relative edge list agrees with the stored matrix cell by cell", {
  r <- cooccurrence(.tx4, similarity = "relative")
  m <- as_matrix(r)
  e <- as.data.frame(r)
  expect_equal(e$weight, m[cbind(e$from, e$to)])
  ## Every non-zero cell of the matrix is an edge row.
  expect_equal(sum(m != 0), nrow(e))
})

test_that("relative out-weights of every node sum to one", {
  e <- as.data.frame(cooccurrence(.tx4, similarity = "relative"))
  out_sums <- as.numeric(tapply(e$weight, e$from, sum))
  expect_equal(out_sums, rep(1, length(out_sums)))
})

test_that("relative is thresholded and truncated per direction", {
  r <- cooccurrence(.tx4, similarity = "relative", threshold = 0.5)
  e <- as.data.frame(r)
  expect_true(all(e$weight >= 0.5))
  expect_equal(nrow(e), 5L)
  expect_length(.edge_weight(r, "A", "D"), 0L)
  expect_equal(.edge_weight(r, "D", "A"), 1)

  top <- as.data.frame(cooccurrence(.tx4, similarity = "relative",
                                    top_n = 1))
  expect_equal(nrow(top), 1L)
  expect_equal(c(top$from, top$to), c("D", "A"))
})

test_that("symmetric measures keep one row per unordered pair", {
  for (s in c("none", "jaccard", "cosine", "association")) {
    e <- as.data.frame(cooccurrence(.tx4, similarity = s))
    expect_equal(nrow(e), 4L)
    expect_false(any(duplicated(paste(pmin(e$from, e$to),
                                      pmax(e$from, e$to)))))
  }
})

test_that("relative converts to directed igraph, cograph and netobject", {
  r <- cooccurrence(.tx4, similarity = "relative")
  skip_if_not_installed("igraph")
  g <- as_igraph(r)
  expect_true(igraph::is_directed(g))
  expect_equal(igraph::ecount(g), 8L)
  ge <- igraph::as_data_frame(g, what = "edges")
  expect_equal(ge$weight[ge$from == "D" & ge$to == "A"], 1)
  expect_false(igraph::is_directed(as_igraph(cooccurrence(.tx4))))
})

test_that("relative converts to directed cograph and netobject", {
  r <- cooccurrence(.tx4, similarity = "relative")
  skip_if_not_installed("cograph")
  net <- cooccure::as_cograph(r)
  expect_true(net$directed)
  expect_equal(net$n_edges, 8L)
  expect_equal(net$weights, as_matrix(r))
  skip_if_not_installed("Nestimate")
  nob <- as_netobject(r)
  expect_true(nob$directed)
  expect_equal(nob$n_edges, 8L)
})

test_that("relative gephi output is typed Directed", {
  g <- cooccurrence(.tx4, similarity = "relative", output = "gephi")
  expect_true(all(as.data.frame(g)$Type == "Directed"))
  u <- cooccurrence(.tx4, output = "gephi")
  expect_true(all(as.data.frame(u)$Type == "Undirected"))
})

test_that("relative with aggregate_by keeps directions and summed counts", {
  d <- data.frame(g = c(1, 1, 2, 2), kw = c("A;B", "A;C", "A;B", "B;C"),
                  stringsAsFactors = FALSE)
  a <- cooccurrence(d, field = "kw", sep = ";", aggregate_by = "g",
                    similarity = "relative")
  ## Group 1: A-B, A-C -> A->B .5, A->C .5, B->A 1, C->A 1.
  ## Group 2: A-B, B-C -> A->B 1, B->A .5, B->C .5, C->B 1.
  expect_equal(.edge_weight(a, "A", "B"), 1.5)
  expect_equal(.edge_weight(a, "B", "A"), 1.5)
  expect_equal(.edge_weight(a, "C", "B"), 1)
  expect_equal(.edge_weight(a, "B", "C"), 0.5)
  raw <- as_matrix(a, type = "raw")
  expect_true(isSymmetric(raw))
  expect_equal(raw["A", "B"], 2)
})

# ---- 2. split_by results are converted one group at a time ---------------

test_that("converters refuse a split result without a group", {
  s <- cooccurrence(.split_df(), field = "kw", sep = ";", split_by = "grp")
  expect_error(as_matrix(s), class = "cooccure_grouped_input")
  pdf(NULL); on.exit(dev.off(), add = TRUE)
  expect_error(plot(s), class = "cooccure_grouped_input")
  skip_if_not_installed("igraph")
  expect_error(as_igraph(s), class = "cooccure_grouped_input")
})

test_that("one group converts to exactly that group's own network", {
  d <- .split_df()
  s <- cooccurrence(d, field = "kw", sep = ";", split_by = "grp")
  for (g in c("X", "Y")) {
    alone <- cooccurrence(subset(d, grp == g, select = kw),
                          field = "kw", sep = ";")
    expect_equal(as_matrix(s, group = g), as_matrix(alone))
    expect_equal(as_matrix(s, group = g, type = "raw"),
                 as_matrix(alone, type = "raw"))
  }
  ## The old last-group-wins merge gave A-B = 1 for both groups.
  expect_equal(as_matrix(s, group = "X")["A", "B"], 2)
  expect_equal(as_matrix(s, group = "Y")["A", "B"], 1)
})

test_that("group conversion keeps the group's isolated items", {
  d <- data.frame(grp = c("X", "X", "X"), kw = c("A;B", "A;B", "Q"),
                  stringsAsFactors = FALSE)
  d <- rbind(d, data.frame(grp = "Y", kw = "C;D"))
  s <- cooccurrence(d, field = "kw", sep = ";", split_by = "grp")
  expect_equal(rownames(as_matrix(s, group = "X")), c("A", "B", "Q"))
  skip_if_not_installed("igraph")
  g <- as_igraph(s, group = "X")
  expect_equal(igraph::vcount(g), 3L)
  expect_equal(igraph::ecount(g), 1L)
})

test_that("group argument is validated", {
  s <- cooccurrence(.split_df(), field = "kw", sep = ";", split_by = "grp")
  expect_error(as_matrix(s, group = "Z"), class = "cooccure_bad_input")
  expect_error(as_matrix(s, group = c("X", "Y")), class = "cooccure_bad_input")
  expect_error(as_matrix(cooccurrence(.tx4), group = "X"),
               class = "cooccure_bad_input")
})

test_that("graph outputs are refused for split_by up front", {
  for (o in c("igraph", "cograph", "matrix")) {
    expect_error(cooccurrence(.split_df(), field = "kw", sep = ";",
                              split_by = "grp", output = o),
                 class = "cooccure_grouped_input")
  }
})

test_that("split groups convert to cograph and netobject", {
  s <- cooccurrence(.split_df(), field = "kw", sep = ";", split_by = "grp")
  skip_if_not_installed("cograph")
  net <- cooccure::as_cograph(s, group = "Y")
  expect_equal(net$weights, as_matrix(s, group = "Y"))
  expect_equal(net$n_edges, 3L)
  skip_if_not_installed("Nestimate")
  expect_equal(as_netobject(s, group = "Y")$weights,
               as_matrix(s, group = "Y"))
})

# ---- 3. no silent failures -----------------------------------------------

test_that("a misspelled column fails with its own message", {
  d <- .split_df()
  expect_error(cooccurrence(d, field = "nope", sep = ";", aggregate_by = "grp"),
               class = "cooccure_bad_input")
  expect_error(cooccurrence(d, field = "nope", sep = ";", aggregate_by = "grp"),
               "nope")
  expect_error(cooccurrence(d, field = "nope", sep = ";", split_by = "grp"),
               class = "cooccure_bad_input")
  expect_error(cooccurrence(d, field = "kw", sep = ";", aggregate_by = "zz"),
               class = "cooccure_bad_input")
})

test_that("a failing group is re-raised with the group named", {
  d <- data.frame(g = c("x", "x", "y", "y"), A = c(1, 0, -1, 1),
                  B = c(1, 1, 1, 1))
  expect_error(cooccurrence(d, vars = c("A", "B"), split_by = "g"),
               class = "cooccure_bad_input")
  expect_error(cooccurrence(d, vars = c("A", "B"), split_by = "g"),
               "Group 'y'")
  expect_error(cooccurrence(d, vars = c("A", "B"), aggregate_by = "g"),
               "Group 'y'")
})

test_that("an empty group is dropped from aggregate_by quietly", {
  d <- data.frame(g = c("a", "a", "b"), kw = c("A;B", "B;C", "Q"),
                  stringsAsFactors = FALSE)
  a <- cooccurrence(d, field = "kw", sep = ";", aggregate_by = "g")
  only_a <- cooccurrence(subset(d, g == "a", select = kw),
                         field = "kw", sep = ";")
  expect_equal(as.data.frame(a)$weight, as.data.frame(only_a)$weight)
})

test_that("aggregate_by stores summed counts as the raw matrix", {
  d <- data.frame(g = c(1, 1, 2, 2), kw = c("A;B", "A;B;C", "A;B", "B;C"),
                  stringsAsFactors = FALSE)
  a <- cooccurrence(d, field = "kw", sep = ";", aggregate_by = "g",
                    similarity = "jaccard")
  raw <- as_matrix(a, type = "raw")
  ## A-B appears in two transactions of group 1 and one of group 2.
  expect_equal(raw["A", "B"], 3)
  expect_false(isTRUE(all.equal(raw, as_matrix(a))))
})

test_that("weight_by refuses fractional and attention counting", {
  theta <- data.frame(doc = c("d1", "d1", "d2", "d2"),
                      topic = c("T1", "T2", "T1", "T2"),
                      prob = c(0.6, 0.4, 0.3, 0.7))
  for (cnt in c("fractional", "attention")) {
    expect_error(cooccurrence(theta, field = "topic", by = "doc",
                              weight_by = "prob", counting = cnt),
                 class = "cooccure_incompatible_args")
  }
  expect_no_error(cooccurrence(theta, field = "topic", by = "doc",
                               weight_by = "prob"))
})

# ---- 4. argument validation and conditions -------------------------------

test_that("invalid arguments raise classed errors", {
  expect_error(cooccurrence(.tx4, threshold = "a"),
               class = "cooccure_bad_input")
  expect_error(cooccurrence(.tx4, min_occur = 0), class = "cooccure_bad_input")
  expect_error(cooccurrence(.tx4, top_n = 0), class = "cooccure_bad_input")
  expect_error(cooccurrence(.tx4, window = 1), class = "cooccure_bad_input")
  expect_error(cooccurrence(.tx4, counting = "attention", lambda = -1),
               class = "cooccure_bad_input")
  expect_error(cooccurrence(.tx4, simliarity = "jaccard"),
               class = "cooccure_bad_input")
  expect_error(cooccurrence(list()), class = "cooccure_empty_input")
  expect_error(cooccurrence(.split_df(), field = "kw", sep = ";",
                            split_by = "grp", aggregate_by = "grp"),
               class = "cooccure_incompatible_args")
  expect_error(cooccurrence(data.frame(a = c("x", "y"))),
               class = "cooccure_bad_input")
})

test_that("a negative threshold filters z-scored weights", {
  all_w <- as.data.frame(cooccurrence(.tx4, scale = "zscore"))
  cut <- as.data.frame(cooccurrence(.tx4, scale = "zscore",
                                    threshold = -0.5))
  expect_true(any(all_w$weight < -0.5))
  expect_equal(cut$weight, all_w$weight[all_w$weight >= -0.5])
  ## Zero keeps its meaning of no filtering.
  expect_equal(nrow(as.data.frame(cooccurrence(.tx4, scale = "zscore",
                                               threshold = 0))),
               nrow(all_w))
})

# ---- 5. summary object and node accessor ---------------------------------

test_that("summary() returns an object and prints only when printed", {
  r <- cooccurrence(.tx4)
  expect_silent(s <- summary(r))
  expect_s3_class(s, "summary.cooccurrence")
  out <- capture.output(print(s))
  expect_true(any(grepl("Density", out)))
})

test_that("as.data.frame(x, what = 'nodes') gives hand-checked node metrics", {
  nodes <- as.data.frame(cooccurrence(.tx4), what = "nodes")
  expect_identical(class(nodes), "data.frame")
  a <- subset(nodes, node == "A")
  ## A links to B (2), C (1), D (1); A is in three transactions.
  expect_equal(a$degree, 3L)
  expect_equal(a$strength, 4)
  expect_equal(a$frequency, 3)
  expect_equal(nodes, as.data.frame(summary(cooccurrence(.tx4)),
                                    what = "nodes"))
})

test_that("as.data.frame(x) returns the bare edge table", {
  e <- as.data.frame(cooccurrence(.tx4, similarity = "jaccard"))
  expect_identical(class(e), "data.frame")
  expect_setequal(names(attributes(e)), c("names", "class", "row.names"))
  expect_equal(names(e), c("from", "to", "weight", "count"))
})

test_that("split node table is computed within each group", {
  s <- cooccurrence(.split_df(), field = "kw", sep = ";", split_by = "grp")
  nodes <- as.data.frame(s, what = "nodes")
  expect_equal(names(nodes)[1], "group")
  groups <- as.data.frame(s, what = "groups")
  n_by_group <- stats::setNames(groups$n_nodes, groups$group)
  expect_true(all(nodes$degree <= n_by_group[nodes$group] - 1L))
  expect_equal(subset(nodes, group == "X" & node == "A")$degree, 1L)
  expect_equal(subset(nodes, group == "Y" & node == "B")$degree, 2L)
})

test_that("directed summary counts ordered pairs", {
  s <- summary(cooccurrence(.tx4, similarity = "relative"))
  expect_true(s$directed)
  expect_equal(s$possible_edges, 12)
  expect_equal(s$density, 8 / 12)
})

# ---- 6. heatmap colour scale ---------------------------------------------

test_that("heatmap uses a white-to-blue scale for non-negative weights", {
  sc <- .co_heatmap_scale(as_matrix(cooccurrence(.tx4)))
  expect_equal(sc$col[1], "#FFFFFF")
  expect_equal(sc$col[length(sc$col)], "#4A6FE3")
  expect_equal(sc$zlim, c(0, 2))
})

test_that("heatmap uses a symmetric diverging scale for negative weights", {
  m <- as_matrix(cooccurrence(.tx4, scale = "zscore"))
  sc <- .co_heatmap_scale(m)
  expect_equal(sc$col[1], "#D33F6A")
  expect_equal(sc$col[51], "#FFFFFF")
  expect_equal(sc$col[101], "#4A6FE3")
  expect_equal(sc$zlim[1], -sc$zlim[2])
})

test_that("plot draws one group of a split result", {
  s <- cooccurrence(.split_df(), field = "kw", sep = ";", split_by = "grp")
  pdf(NULL); on.exit(dev.off(), add = TRUE)
  expect_invisible(plot(s, group = "Y"))
  expect_invisible(plot(s, type = "degree", group = "X"))
})
