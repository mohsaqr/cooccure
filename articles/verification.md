# Verification against Nestimate

A network statistic is only as trustworthy as its implementation. The
similarity measures used to normalize co-occurrence counts have short
formulas (van Eck & Waltman, 2009), but an implementation has to make
many small decisions around them: how a transaction that lists an item
twice is counted, whether the diagonal of the matrix holds item
frequencies or zeros, which items survive a frequency filter, and in
which order a threshold and a normalization are applied. Two
implementations that agree on the formulas can still disagree on the
numbers.

**Nestimate** contains an independent implementation of the same eight
similarity measures in its own
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
function, written for its network-estimation framework. This guide
compares the two on the data bundled with **cooccure** and shows that,
once two documented conventions are aligned, they return the same weight
matrix for every measure. The same comparison is kept in the package
repository (`tests/equivalence/test-nestimate-equivalence.R`) and runs
in continuous integration, on hand-built inputs in all five input
formats both packages read, with frequency and weight filters, and on 40
randomly generated networks, so that the two cannot drift apart
unnoticed. It is not part of the tests shipped to CRAN, so that a change
in one package cannot fail the other’s check.

``` r

library(cooccure)
```

Both packages export a function called
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md),
and they return different classes. **Nestimate** is therefore not
attached here; every call to it is written as
[`Nestimate::cooccurrence()`](https://pak.dynasite.org/Nestimate/reference/cooccurrence.html).

``` r

packageVersion("Nestimate")
#> [1] '0.9.24'
```

The comparison below was rendered against this version of **Nestimate**.

## Data

Two bundled tables, in two input formats, supply the networks:

- **`movies`**, a delimited format: one row per film, with the column
  `genres` holding the film’s genres separated by commas. Genres are the
  items and films the transactions; 1,000 films, 22 genres.
- **`actors`**, a long format: one row per actor and film, with `actor`
  as the item and the film identifier `tconst` as the transaction; 624
  actors in 401 films.

## Two helpers that return comparable matrices

The two packages store their networks differently: **cooccure** returns
an edge list whose matrix is read with
[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md),
and **Nestimate** returns a `netobject` that holds the matrix. The first
helper returns the **cooccure** matrix; the second returns the
**Nestimate** matrix with the diagonal set to zero, since **cooccure**
never stores self co-occurrence.

``` r

cooccure_matrix <- function(...) {
  as_matrix(cooccure::cooccurrence(...))
}

nestimate_matrix <- function(..., diagonal = FALSE) {
  m <- as.matrix(Nestimate::cooccurrence(..., diagonal = diagonal)$weights)
  diag(m) <- 0
  m
}
```

A third helper aligns the two matrices on their item names and returns
the largest absolute difference between any two cells, and a fourth
applies it to every similarity measure, returning one row per measure.

``` r

max_difference <- function(a, b) {
  items <- sort(rownames(a))
  stopifnot("the two networks hold different items" =
              setequal(rownames(a), rownames(b)))
  max(abs(a[items, items] - b[items, items]))
}

compare_measures <- function(...) {
  measures <- c("none", "jaccard", "cosine", "inclusion", "association",
                "dice", "equivalence", "relative")
  rows <- lapply(measures, function(s) {
    a <- cooccure_matrix(..., similarity = s)
    b <- nestimate_matrix(..., similarity = s)
    data.frame(similarity = s, items = nrow(a),
               max_abs_difference = max_difference(a, b))
  })
  do.call(rbind, rows)
}
```

## Do the two packages agree on every similarity measure?

The genre network of the `movies` table is built with each of the eight
measures by both packages, and the matrices are compared cell by cell.

``` r

compare_measures(movies, field = "genres", sep = ",")
#>    similarity items max_abs_difference
#> 1        none    22           0.00e+00
#> 2     jaccard    22           0.00e+00
#> 3      cosine    22           5.55e-17
#> 4   inclusion    22           0.00e+00
#> 5 association    22           0.00e+00
#> 6        dice    22           0.00e+00
#> 7 equivalence    22           0.00e+00
#> 8    relative    22           0.00e+00
```

Both packages find the same 22 genres for every measure. Seven of the
eight measures agree exactly; for `cosine` the largest difference is of
the order of 10⁻¹⁷, which is floating-point rounding from computing a
square root in a different order, far below any meaningful difference in
a similarity between 0 and 1.

The actor network is larger, 624 items and more than 4,000 edges, and
comes from a long table rather than a delimited column.

``` r

compare_measures(actors, field = "actor", by = "tconst")
#>    similarity items max_abs_difference
#> 1        none   624           0.00e+00
#> 2     jaccard   624           0.00e+00
#> 3      cosine   624           2.22e-16
#> 4   inclusion   624           0.00e+00
#> 5 association   624           0.00e+00
#> 6        dice   624           0.00e+00
#> 7 equivalence   624           0.00e+00
#> 8    relative   624           0.00e+00
```

The result is the same: every measure agrees to within 10⁻¹⁵, and
`cosine` is again the only one with a non-zero difference.

## Do filters give the same network?

Frequency and weight filters are where implementations most often part
ways, because a filter can be applied before or after normalization.
Here only genres in at least 20 films are kept, and Jaccard weights
below 0.1 are dropped.

``` r

max_difference(
  cooccure_matrix(movies, field = "genres", sep = ",",
                  similarity = "jaccard", min_occur = 20, threshold = 0.1),
  nestimate_matrix(movies, field = "genres", sep = ",",
                   similarity = "jaccard", min_occur = 20, threshold = 0.1)
)
#> [1] 0
```

The filtered networks are identical: both packages remove rare items
before counting and apply the weight threshold after the similarity
measure.

## Where the conventions differ

Two documented conventions differ between the packages, and both must be
aligned before the numbers can match.

### The diagonal

By default **Nestimate** stores each item’s frequency on the diagonal of
the matrix (`diagonal = TRUE`), while **cooccure** always sets it to
zero. For seven measures this changes only the diagonal, which the
helper above zeroes. For `relative` it changes every cell: `relative`
divides each row by its sum, and with the diagonal kept, the item’s own
frequency is part of that sum.

``` r

max_difference(
  cooccure_matrix(movies, field = "genres", sep = ",",
                  similarity = "relative"),
  nestimate_matrix(movies, field = "genres", sep = ",",
                   similarity = "relative", diagonal = TRUE)
)
#> [1] 0.5
```

With the diagonal kept, the off-diagonal `relative` weights differ by up
to 0.5. With `diagonal = FALSE`, as in the comparisons above, they agree
exactly. The two packages therefore implement the same measure; the
difference is in which co-occurrences count toward an item’s total.

### Ties at the `top_n` cut

`top_n` keeps the heaviest edges. When several edges tie at the cut,
**cooccure** truncates to exactly `top_n` edges and **Nestimate** keeps
every edge tied with the last one. In the genre network, three pairs
have an inclusion weight of 1, so the two packages return a different
number of edges for `top_n = 1`.

``` r

cooccurrence(movies, field = "genres", sep = ",",
             similarity = "inclusion", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: inclusion | counting: full
#> # possible edges: 231 | isolates: 17
#> # top nodes: News(deg=2,str=2), Documentary(deg=1,str=1), Drama(deg=1,str=1), History(deg=1,str=1), Western(deg=1,str=1)
#>         from      to weight count
#>  Documentary    News      1     1
#>      History    News      1     1
#>        Drama Western      1     1
```

These are the three tied pairs. With `top_n = 1`, **cooccure** keeps the
first of them and **Nestimate** keeps all three; the edges **cooccure**
keeps are always a subset of those **Nestimate** keeps, with the same
weights.

### Direction of `relative`

`relative` is the only asymmetric measure: the weight from genre A to
genre B is the share of A’s co-occurrences that involve B, which is not
the share of B’s co-occurrences that involve A. Both packages store the
asymmetric matrix compared above. **cooccure** returns one edge per
direction and marks the network as directed, and so does **Nestimate**
from version 1.0.11 onward.

``` r

genre_shares <- cooccurrence(movies, field = "genres", sep = ",",
                             similarity = "relative")
print(genre_shares, n = 4)
#> # cooccurrence: 22 nodes, 258 directed edges | density: 0.5584 | mean degree: 23.4545 | 1000 transactions
#> # similarity: relative | counting: full
#> # possible edges: 462 | isolates: 0
#> # top nodes: Drama(deg=40,str=7.551), Comedy(deg=38,str=3.216), Action(deg=34,str=2.686), Romance(deg=34,str=1.847), Adventure(deg=30,str=2.104)
#>     from          to weight count
#>  Western       Drama  1.000     1
#>  Romance       Drama  0.553   131
#>      War       Drama  0.509    27
#>     News Documentary  0.500     1
#> # ... 254 more edges
```

The header reports directed edges: the 129 genre pairs give 258 directed
edges. The strongest runs from Western to Drama with a weight of 1,
because the single Western film is also tagged Drama and nothing else.
The two directions of one pair can differ widely, as the Drama and
Romance pair shows.

``` r

subset(as.data.frame(genre_shares),
       from %in% c("Drama", "Romance") & to %in% c("Drama", "Romance"))
#>       from      to weight count
#> 2  Romance   Drama  0.553   131
#> 44   Drama Romance  0.161   131
```

More than half (0.553) of Romance’s co-occurrences are with Drama, but
only 0.161 of Drama’s co-occurrences are with Romance, because Drama
co-occurs with almost every other genre. The raw count, 131 films, is
the same in both directions.

## What the comparison covers

The comparison establishes that, given the same transactions, the two
packages compute the same weights. It does not test input parsing that
only one package offers, such as the sliding windows, attention
counting, event logs and `aggregate_by` of **cooccure**; those are
checked in `tests/testthat/test-cooccurrence.R` against values computed
by hand. For the choice between the measures themselves, see the [guide
to similarity
measures](https://pak.dynasite.org/cooccure/articles/similarity-measures.md).

## References

van Eck, N. J., & Waltman, L. (2009). How to normalize cooccurrence
data? An analysis of some well-known similarity measures. *Journal of
the American Society for Information Science and Technology*, 60(8),
1635–1651. <https://doi.org/10.1002/asi.21075>
