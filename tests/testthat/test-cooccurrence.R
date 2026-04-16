# ---- cooccurrence() tests ----

.test_list <- list(c("A", "B", "C"), c("B", "C"), c("A", "C"))

# ========================================
# 1. Returns tidy data.frame
# ========================================

test_that("cooccurrence returns a tidy data.frame", {
  res <- cooccurrence(.test_list)
  expect_s3_class(res, "cooccurrence")
  expect_s3_class(res, "data.frame")
  expect_true(all(c("from", "to", "weight", "count") %in% names(res)))
  expect_true(nrow(res) > 0)
})

test_that("co() alias works", {
  res <- co(.test_list)
  expect_s3_class(res, "cooccurrence")
})

test_that("edges are sorted by weight descending", {
  res <- cooccurrence(.test_list)
  expect_true(all(diff(res$weight) <= 0))
})

# ========================================
# 2. Input formats
# ========================================

test_that("delimited input works", {
  df <- data.frame(items = c("A;B;C", "B;C", "A;C"), stringsAsFactors = FALSE)
  res <- cooccurrence(df, field = "items", sep = ";")
  expect_equal(nrow(res), 3L)  # 3 pairs: A-B, A-C, B-C
})

test_that("multi-column delimited works", {
  df <- data.frame(c1 = c("A;B", "B", "A"), c2 = c("C", "C", "C"),
                   stringsAsFactors = FALSE)
  res <- cooccurrence(df, field = c("c1", "c2"), sep = ";")
  expect_equal(nrow(res), 3L)
})

test_that("long/bipartite works", {
  df <- data.frame(doc = c(1,1,1,2,2,3,3),
                   item = c("A","B","C","B","C","A","C"),
                   stringsAsFactors = FALSE)
  res <- cooccurrence(df, field = "item", by = "doc")
  expect_equal(nrow(res), 3L)
})

test_that("binary matrix works", {
  bin <- matrix(c(1,1,1, 0,1,1, 1,0,1), nrow = 3, byrow = TRUE,
                dimnames = list(NULL, c("A","B","C")))
  res <- cooccurrence(bin)
  expect_equal(nrow(res), 3L)
})

test_that("wide sequence works", {
  df <- data.frame(V1 = c("A","B","A"), V2 = c("B","C","C"),
                   V3 = c("C", NA, NA), stringsAsFactors = FALSE)
  res <- cooccurrence(df)
  expect_equal(nrow(res), 3L)
})

test_that("list input works", {
  res <- cooccurrence(.test_list)
  expect_equal(nrow(res), 3L)
})

test_that("all formats give same counts", {
  res_list <- cooccurrence(.test_list)

  df_del <- data.frame(items = c("A;B;C", "B;C", "A;C"),
                        stringsAsFactors = FALSE)
  res_del <- cooccurrence(df_del, field = "items", sep = ";")

  # Sort both by from+to for comparison
  key <- function(r) paste(pmin(r$from, r$to), pmax(r$from, r$to))
  r1 <- res_list[order(key(res_list)), ]
  r2 <- res_del[order(key(res_del)), ]

  expect_equal(r1$count, r2$count)
  expect_equal(r1$weight, r2$weight)
})

# ========================================
# 3. Similarity measures
# ========================================

test_that("similarity = 'none' gives raw counts", {
  res <- cooccurrence(.test_list, similarity = "none")
  # A-C co-occur 2 times, so weight = 2
  ac <- res[res$from == "A" & res$to == "C", ]
  expect_equal(ac$weight, 2)
  expect_equal(ac$count, 2L)
})

test_that("similarity = 'jaccard' is correct", {
  res <- cooccurrence(.test_list, similarity = "jaccard")
  ab <- res[res$from == "A" & res$to == "B", ]
  # Jaccard(A,B) = 1 / (2+2-1) = 1/3
  expect_equal(ab$weight, 1 / 3)
})

test_that("similarity = 'cosine' is correct", {
  res <- cooccurrence(.test_list, similarity = "cosine")
  ab <- res[res$from == "A" & res$to == "B", ]
  expect_equal(ab$weight, 0.5)
})

test_that("similarity = 'association' is correct", {
  res <- cooccurrence(.test_list, similarity = "association")
  ab <- res[res$from == "A" & res$to == "B", ]
  expect_equal(ab$weight, 0.25)
})

test_that("similarity = 'equivalence' is correct", {
  res <- cooccurrence(.test_list, similarity = "equivalence")
  ab <- res[res$from == "A" & res$to == "B", ]
  expect_equal(ab$weight, 0.25)
})

test_that("similarity = 'dice' is correct", {
  res <- cooccurrence(.test_list, similarity = "dice")
  ab <- res[res$from == "A" & res$to == "B", ]
  expect_equal(ab$weight, 0.5)
})

test_that("similarity = 'inclusion' is correct", {
  res <- cooccurrence(.test_list, similarity = "inclusion")
  ac <- res[res$from == "A" & res$to == "C", ]
  expect_equal(ac$weight, 1)
})

test_that("similarity = 'relative' row-normalizes", {
  res <- cooccurrence(.test_list, similarity = "relative")
  mat <- as_matrix(res)
  expect_true(all(abs(rowSums(mat) - 1) < 1e-10 | rowSums(mat) == 0))
})

# ========================================
# 4. Scaling
# ========================================

test_that("scale = 'minmax' scales to [0,1]", {
  res <- cooccurrence(.test_list, scale = "minmax")
  expect_true(max(res$weight) <= 1)
  expect_true(min(res$weight) >= 0)
})

test_that("scale = 'log' applies log(1+w)", {
  res_raw <- cooccurrence(.test_list)
  res_log <- cooccurrence(.test_list, scale = "log")
  expect_equal(res_log$weight, log(1 + res_raw$weight))
})

test_that("scale = 'binary' gives 0/1 weights", {
  res <- cooccurrence(.test_list, scale = "binary")
  expect_true(all(res$weight %in% c(0, 1)))
})

test_that("scale = 'sqrt' applies square root", {
  res_raw <- cooccurrence(.test_list)
  res_sqrt <- cooccurrence(.test_list, scale = "sqrt")
  expect_equal(res_sqrt$weight, sqrt(res_raw$weight))
})

test_that("scale = 'zscore' standardizes", {
  res <- cooccurrence(.test_list, scale = "zscore")
  vals <- res$weight[res$weight != 0]
  if (length(vals) > 1) {
    expect_equal(mean(vals), 0, tolerance = 1e-10)
  }
})

test_that("scale = 'proportion' normalizes by total weight", {
  res <- cooccurrence(.test_list, scale = "proportion")
  # The full symmetric matrix sums to 1 (upper + lower triangle)
  mat <- as_matrix(res)
  expect_equal(sum(mat), 1, tolerance = 1e-10)
})

# ========================================
# 5. Parameters
# ========================================

test_that("threshold filters edges", {
  res <- cooccurrence(.test_list, threshold = 2)
  expect_true(all(res$weight >= 2))
  expect_equal(nrow(res), 2L)  # Only A-C and B-C have count >= 2
})

test_that("min_occur drops rare entities", {
  trans <- list(c("A","B"), c("A","B"), c("A","D"))
  res <- cooccurrence(trans, min_occur = 2L)
  expect_false("D" %in% c(res$from, res$to))
})

test_that("top_n limits edges", {
  res <- cooccurrence(.test_list, top_n = 1L)
  expect_equal(nrow(res), 1L)
})

# ========================================
# 6. Attributes
# ========================================

test_that("attributes are stored", {
  res <- cooccurrence(.test_list, similarity = "jaccard", scale = "log")
  expect_equal(attr(res, "similarity"), "jaccard")
  expect_equal(attr(res, "scale"), "log")
  expect_equal(attr(res, "n_transactions"), 3L)
  expect_equal(attr(res, "n_items"), 3L)
  expect_true(!is.null(attr(res, "matrix")))
  expect_true(!is.null(attr(res, "items")))
  expect_true(!is.null(attr(res, "frequencies")))
})

# ========================================
# 7. Converters
# ========================================

test_that("as_matrix returns correct matrix", {
  res <- cooccurrence(.test_list)
  mat <- as_matrix(res)
  expect_true(is.matrix(mat))
  expect_equal(nrow(mat), 3L)
  expect_equal(ncol(mat), 3L)
  expect_true(isSymmetric(mat))
})

test_that("as_matrix type='raw' gives counts", {
  res <- cooccurrence(.test_list, similarity = "jaccard")
  raw <- as_matrix(res, type = "raw")
  expect_equal(raw["A", "B"], 1)
  expect_equal(raw["A", "C"], 2)
})

test_that("as_igraph works", {
  skip_if_not_installed("igraph")
  res <- cooccurrence(.test_list)
  g <- as_igraph(res)
  expect_true(igraph::is_igraph(g))
  expect_equal(igraph::vcount(g), 3L)
  expect_false(igraph::is_directed(g))
})

test_that("as_cograph works", {
  skip_if_not_installed("cograph")
  res <- cooccurrence(.test_list)
  net <- as_cograph(res)
  expect_true(inherits(net, "cograph_network"))
  expect_equal(net$n_nodes, 3L)
})

test_that("as_netobject works", {
  skip_if_not_installed("Nestimate")
  res <- cooccurrence(.test_list)
  net <- as_netobject(res)
  expect_true(inherits(net, "netobject"))
  expect_true(inherits(net, "cograph_network"))
  expect_false(net$directed)
})

test_that("as_tidygraph works", {
  skip_if_not_installed("tidygraph")
  skip_if_not_installed("igraph")
  res <- cooccurrence(.test_list)
  tg <- as_tidygraph(res)
  expect_true(inherits(tg, "tbl_graph"))
})

# ========================================
# 8. Edge cases
# ========================================

test_that("error on empty input", {
  expect_error(cooccurrence(list()), "No non-empty transactions")
})

test_that("single-item transactions give no edges", {
  res <- cooccurrence(list(c("A"), c("B"), c("C")))
  expect_equal(nrow(res), 0L)
})

test_that("count is always the raw co-occurrence", {
  res <- cooccurrence(.test_list, similarity = "jaccard", scale = "log")
  ab <- res[res$from == "A" & res$to == "B", ]
  expect_equal(ab$count, 1L)
})

# ========================================
# 9. split_by
# ========================================

test_that("split_by produces a group column", {
  df <- data.frame(
    year = c(2020, 2020, 2020, 2021, 2021, 2021),
    kw = c("A; B; C", "B; C", "A; C", "B; C; D", "C; D", "B; D"),
    stringsAsFactors = FALSE
  )
  res <- cooccurrence(df, field = "kw", sep = ";", split_by = "year")
  expect_s3_class(res, "cooccurrence")
  expect_true("group" %in% names(res))
  expect_equal(sort(unique(res$group)), c("2020", "2021"))
})

test_that("split_by computes separate networks per group", {
  df <- data.frame(
    grp = c("X", "X", "Y", "Y"),
    kw = c("A; B", "A; B", "C; D", "C; D"),
    stringsAsFactors = FALSE
  )
  res <- cooccurrence(df, field = "kw", sep = ";", split_by = "grp")
  # Group X has only A-B; group Y has only C-D
  res_x <- res[res$group == "X", ]
  res_y <- res[res$group == "Y", ]
  expect_equal(nrow(res_x), 1L)
  expect_equal(nrow(res_y), 1L)
  expect_true(all(c(res_x$from, res_x$to) %in% c("A", "B")))
  expect_true(all(c(res_y$from, res_y$to) %in% c("C", "D")))
})

test_that("split_by + similarity works", {
  df <- data.frame(
    grp = c("X", "X", "X", "Y", "Y", "Y"),
    kw = c("A; B; C", "B; C", "A; C", "A; B; C", "B; C", "A; C"),
    stringsAsFactors = FALSE
  )
  res <- cooccurrence(df, field = "kw", sep = ";",
                      split_by = "grp", similarity = "jaccard")
  # Both groups have the same data → same weights
  res_x <- res[res$group == "X", ]
  res_y <- res[res$group == "Y", ]
  expect_equal(sort(res_x$weight), sort(res_y$weight))
})

test_that("split_by + top_n applies per group", {
  df <- data.frame(
    grp = c("X", "X", "X", "Y", "Y", "Y"),
    kw = c("A; B; C", "B; C", "A; C", "D; E; F", "E; F", "D; F"),
    stringsAsFactors = FALSE
  )
  res <- cooccurrence(df, field = "kw", sep = ";",
                      split_by = "grp", top_n = 1L)
  # 1 edge per group → 2 total
  expect_equal(nrow(res), 2L)
  expect_equal(length(unique(res$group)), 2L)
})

test_that("split_by skips groups with no edges", {
  df <- data.frame(
    grp = c("X", "X", "Y"),
    kw = c("A; B", "A; B", "C"),
    stringsAsFactors = FALSE
  )
  res <- cooccurrence(df, field = "kw", sep = ";", split_by = "grp")
  # Y has only one item → no edges → should be absent
  expect_equal(unique(res$group), "X")
})

test_that("split_by stores attributes", {
  df <- data.frame(
    year = c(2020, 2021),
    kw = c("A; B", "A; B"),
    stringsAsFactors = FALSE
  )
  res <- cooccurrence(df, field = "kw", sep = ";", split_by = "year")
  expect_equal(attr(res, "split_by"), "year")
  expect_equal(sort(attr(res, "groups")), c("2020", "2021"))
})
