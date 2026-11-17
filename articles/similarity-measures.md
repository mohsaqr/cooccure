# Choosing a similarity measure

A raw co-occurrence count mixes two things: how strongly two items are
associated, and how frequent each of them is. An item that appears in
most transactions co-occurs with nearly everything, so the heaviest
edges of a count network tend to join the most frequent items whatever
their association. Similarity measures separate the two by comparing the
observed count with the frequencies of the items involved. van Eck and
Waltman (2009) distinguish set-theoretic measures, which relate the
count to the sizes of the two item sets (Jaccard, cosine, inclusion,
Dice), from probabilistic measures, which relate it to the count
expected if the items occurred independently (association strength).
They argue that only the probabilistic measure removes the effect of
item frequency, and recommend it for normalizing co-occurrence data.

The measures differ in which pairs they bring to the top, and the choice
changes the substantive reading of a network. This guide compares the
eight measures offered by
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
on one data set, works through one pair by hand, treats the directed
`relative` measure separately, and closes with rescaling and guidance on
choosing.

``` r

library(cooccure)
```

## Data

`movies` holds 1,000 films with an IMDb rating of at least 7.0, released
between 1970 and 2024. In the analyses below:

- **Transaction:** a film (one row, identified by `tconst`).
- **Items:** its genres, listed in the comma-delimited `genres` column.
- **Grouping variables (not used here):** `decade` and `averageRating`.

``` r

head(movies, 3)
#>       tconst        primaryTitle startYear                    genres decade averageRating
#> 1  tt0118117     The War at Home      1996                     Drama  1990s           7.0
#> 2 tt10534996               Josep      2020 Animation,Biography,Drama  2020s           7.4
#> 3  tt4686844 The Death of Stalin      2017      Comedy,Drama,History  2010s           7.3
#>   numVotes
#> 1     2733
#> 2     2340
#> 3   126237
```

## How are the measures defined?

Write $`C_{ij}`$ for the number of films that carry both genre $`i`$ and
genre $`j`$, and $`f_i`$ for the number of films that carry genre $`i`$.
The measures are:

| `similarity`    | Weight of the edge between $`i`$ and $`j`$ |
|-----------------|--------------------------------------------|
| `"none"`        | $`C_{ij}`$                                 |
| `"jaccard"`     | $`C_{ij} / (f_i + f_j - C_{ij})`$          |
| `"cosine"`      | $`C_{ij} / \sqrt{f_i f_j}`$                |
| `"inclusion"`   | $`C_{ij} / \min(f_i, f_j)`$                |
| `"association"` | $`C_{ij} / (f_i f_j)`$                     |
| `"dice"`        | $`2 C_{ij} / (f_i + f_j)`$                 |
| `"equivalence"` | $`C_{ij}^2 / (f_i f_j)`$                   |
| `"relative"`    | $`C_{ij} / \sum_k C_{ik}`$                 |

The first seven are symmetric and give an undirected network.
`"relative"` divides each row by its own sum, so the weight from $`i`$
to $`j`$ differs from the weight from $`j`$ to $`i`$ and the network is
directed.

The frequencies $`f_i`$ are the `frequency` column of the node table,
which [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
returns with `what = "nodes"`.

``` r

genre_counts <- cooccurrence(movies, field = "genres", sep = ",")
genre_nodes <- as.data.frame(genre_counts, what = "nodes")
subset(genre_nodes, node %in% c("Adventure", "Animation", "Drama"))
#>        node degree strength count_strength frequency
#> 1     Drama     20      812            812       634
#> 5 Adventure     15      195            195       101
#> 6 Animation     15      149            149        75
```

*Drama* is on 634 of the 1,000 films, *Adventure* on 101 and *Animation*
on 75. *Adventure* and *Animation* share 39 films. That one pair is
followed through the measures below: its Jaccard weight is
$`39 / (101 + 75 - 39) = 39 / 137 = 0.285`$, its cosine weight
$`39 / \sqrt{101 \times 75} = 0.448`$, its Dice weight
$`78 / 176 = 0.443`$, and its equivalence weight $`0.448^2 = 0.201`$.

## Which pairs rank highest under each measure?

The raw counts rank pairs by volume. With `top_n = 3` only the three
heaviest edges are kept.

``` r

co(movies, field = "genres", sep = ",", similarity = "none", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: none | counting: full
#> # possible edges: 231 | isolates: 18
#> # top nodes: Drama(deg=3,str=381), Comedy(deg=1,str=159), Romance(deg=1,str=131), Crime(deg=1,str=91)
#>    from      to weight count
#>  Comedy   Drama    159   159
#>   Drama Romance    131   131
#>   Crime   Drama     91    91
```

All three edges involve *Drama*, the most frequent genre:
*Comedy*–*Drama* (159 films), *Drama*–*Romance* (131) and
*Crime*–*Drama* (91). The ranking says more about how common *Drama* is
than about which genres belong together.

Jaccard divides the count by the number of films carrying either genre.

``` r

co(movies, field = "genres", sep = ",", similarity = "jaccard", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: jaccard | counting: full
#> # possible edges: 231 | isolates: 16
#> # top nodes: Adventure(deg=1,str=0.2847), Animation(deg=1,str=0.2847), Action(deg=1,str=0.2369), Crime(deg=1,str=0.2369), Comedy(deg=1,str=0.2112)
#>       from        to weight count
#>  Adventure Animation  0.285    39
#>     Action     Crime  0.237    59
#>     Comedy     Drama  0.211   159
```

*Adventure*–*Animation* moves to the top with 0.285, the value computed
by hand above, followed by *Action*–*Crime* (0.237). *Comedy*–*Drama*
keeps third place (0.211) despite having the largest count, because both
genres are common and appear apart as often as together.

Cosine divides by the geometric mean of the two frequencies, which
penalizes a pair of unequal frequencies less than Jaccard does.

``` r

co(movies, field = "genres", sep = ",", similarity = "cosine", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: cosine | counting: full
#> # possible edges: 231 | isolates: 16
#> # top nodes: Adventure(deg=1,str=0.4481), Animation(deg=1,str=0.4481), Drama(deg=1,str=0.4113), Romance(deg=1,str=0.4113), Action(deg=1,str=0.3831)
#>       from        to weight count
#>  Adventure Animation  0.448    39
#>      Drama   Romance  0.411   131
#>     Action     Crime  0.383    59
```

*Adventure*–*Animation* leads again (0.448), and *Drama*–*Romance*
(0.411) replaces *Comedy*–*Drama* in the top three, reflecting cosine’s
more lenient treatment of a frequent genre paired with a less frequent
one.

Inclusion (the Simpson coefficient) divides by the frequency of the
rarer genre, so it measures how far the rarer genre is contained in the
more common one.

``` r

co(movies, field = "genres", sep = ",", similarity = "inclusion", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: inclusion | counting: full
#> # possible edges: 231 | isolates: 17
#> # top nodes: News(deg=2,str=2), Documentary(deg=1,str=1), Drama(deg=1,str=1), History(deg=1,str=1), Western(deg=1,str=1)
#>         from      to weight count
#>  Documentary    News      1     1
#>      History    News      1     1
#>        Drama Western      1     1
```

*Documentary*–*News*, *History*–*News* and *Drama*–*Western* all score 1
with a count of 1. *News* and *Western* each appear on a single film, so
any genre sharing that film includes them completely. Inclusion rewards
rare items and needs a `min_occur` filter before a score of 1 can be
read as a subset relation.

Association strength divides by the product of the frequencies, which is
proportional to the count expected under independence.

``` r

co(movies, field = "genres", sep = ",", similarity = "association", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: association | counting: full
#> # possible edges: 231 | isolates: 17
#> # top nodes: News(deg=2,str=0.02271), History(deg=1,str=0.01613), Horror(deg=1,str=0.01136), Sci-Fi(deg=1,str=0.01136), Documentary(deg=1,str=0.006579)
#>         from     to  weight count
#>      History   News 0.01613     1
#>       Horror Sci-Fi 0.01136     2
#>  Documentary   News 0.00658     1
```

*History*–*News*, *Horror*–*Sci-Fi* and *Documentary*–*News* top the
list, each resting on one or two films. The measure compares observed
with expected co-occurrence, and for rare genres the expected count is
so small that one shared film is far above it. The next section returns
to this.

Dice divides twice the count by the sum of the two frequencies.

``` r

co(movies, field = "genres", sep = ",", similarity = "dice", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: dice | counting: full
#> # possible edges: 231 | isolates: 16
#> # top nodes: Adventure(deg=1,str=0.4432), Animation(deg=1,str=0.4432), Action(deg=1,str=0.3831), Crime(deg=1,str=0.3831), Comedy(deg=1,str=0.3487)
#>       from        to weight count
#>  Adventure Animation  0.443    39
#>     Action     Crime  0.383    59
#>     Comedy     Drama  0.349   159
```

The ranking matches Jaccard (*Adventure*–*Animation*, *Action*–*Crime*,
*Comedy*–*Drama*), with higher weights (0.443 for the first pair). Dice
is a monotone function of Jaccard, $`D = 2J / (1 + J)`$, so the two
measures always rank pairs in the same order.

Equivalence is the square of cosine.

``` r

co(movies, field = "genres", sep = ",", similarity = "equivalence", top_n = 3)
#> # cooccurrence: 22 nodes, 3 edges | density: 0.0130 | mean degree: 0.2727 | 1000 transactions
#> # similarity: equivalence | counting: full
#> # possible edges: 231 | isolates: 16
#> # top nodes: Adventure(deg=1,str=0.2008), Animation(deg=1,str=0.2008), Drama(deg=1,str=0.1692), Romance(deg=1,str=0.1692), Action(deg=1,str=0.1468)
#>       from        to weight count
#>  Adventure Animation  0.201    39
#>      Drama   Romance  0.169   131
#>     Action     Crime  0.147    59
```

The order is the cosine order, and only the spread changes. The top pair
is 1.17 times the third under cosine (0.448 against 0.383) and 1.37
times under equivalence (0.201 against 0.147), so equivalence lets weak
pairs fade from a weighted drawing.

## How do rare items distort the probabilistic measure?

Association strength and inclusion both reach their highest values for
pairs of rare items. Dropping genres that appear on fewer than 20 films
with `min_occur` removes pairs resting on one or two films.

``` r

co(movies, field = "genres", sep = ",", similarity = "association",
   min_occur = 20, top_n = 5)
#> # cooccurrence: 17 nodes, 5 edges | density: 0.0368 | mean degree: 0.5882 | 998 transactions
#> # similarity: association | counting: full
#> # possible edges: 136 | isolates: 8
#> # top nodes: Animation(deg=2,str=0.008678), Adventure(deg=1,str=0.005149), History(deg=1,str=0.004536), War(deg=1,str=0.004536), Mystery(deg=1,str=0.003811)
#>         from        to  weight count
#>    Adventure Animation 0.00515    39
#>      History       War 0.00454     9
#>      Mystery  Thriller 0.00381    15
#>  Documentary     Music 0.00354    28
#>    Animation   Fantasy 0.00353     9
```

Five genres fall below 20 films and two films carried only those genres,
so the network has 17 genres and 998 films. The top pairs are now
*Adventure*–*Animation* (0.00515, or $`39 / (101 \times 75)`$),
*History*–*War*, *Mystery*–*Thriller*, *Documentary*–*Music* and
*Animation*–*Fantasy*. None involves *Drama*: once frequency is
discounted, the strongest associations are between genres that rarely
appear apart. Association weights are small numbers because they are
ratios to a product of frequencies; their order, not their size, is what
they convey.

## What does the directed relative measure show?

`similarity = "relative"` divides each row of the count matrix by its
sum. The weight from genre $`i`$ to genre $`j`$ is the share of all of
$`i`$’s co-occurrences that are with $`j`$, so the rows sum to 1 and the
two directions of a pair differ. The edge list therefore has one row per
direction. To keep the example small, genres on fewer than 100 films are
dropped.

``` r

genre_shares <- cooccurrence(movies, field = "genres", sep = ",",
                             similarity = "relative", min_occur = 100)
print(genre_shares, n = 8)
#> # cooccurrence: 8 nodes, 52 directed edges | density: 0.9286 | mean degree: 13.0000 | 983 transactions
#> # similarity: relative | counting: full
#> # possible edges: 56 | isolates: 0
#> # top nodes: Drama(deg=14,str=3.693), Comedy(deg=14,str=2.29), Biography(deg=14,str=1.978), Crime(deg=14,str=1.75), Adventure(deg=14,str=1.482)
#>         from          to weight count
#>  Documentary   Biography  0.688    44
#>      Romance       Drama  0.627   131
#>       Comedy       Drama  0.485   159
#>        Crime       Drama  0.440    91
#>    Biography       Drama  0.424    59
#>    Adventure      Action  0.349    44
#>       Action       Drama  0.338    71
#>    Biography Documentary  0.317    44
#> # ... 44 more edges
```

The header reports 8 genres and 52 directed edges out of 56 possible
ordered pairs. The heaviest edge runs from *Documentary* to *Biography*
(0.688): about two thirds of *Documentary*’s co-occurrences in this set
are with *Biography*. The reverse edge, *Biography* to *Documentary*,
weighs 0.317, because *Biography* is also often paired with *Drama*.
Both directions carry the same count, 44 films.

The row sums behind these shares are the count strengths of the
unnormalized network on the same genres.

``` r

as.data.frame(cooccurrence(movies, field = "genres", sep = ",",
                           min_occur = 100),
              what = "nodes")
#>          node degree strength count_strength frequency
#> 1       Drama      7      553            553       634
#> 2      Comedy      7      328            328       278
#> 3       Crime      7      207            207       153
#> 4   Biography      7      139            139       108
#> 5   Adventure      7      126            126       101
#> 6      Action      6      210            210       155
#> 7     Romance      6      209            209       160
#> 8 Documentary      5       64             64       152
```

*Documentary* has a count strength of 64 and *Biography* 139, so the two
weights are $`44 / 64 = 0.688`$ and $`44 / 139 = 0.317`$.

Because the network is directed, the converters keep the direction.

``` r

igraph::is_directed(as_igraph(genre_shares))
#> [1] TRUE
```

[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md)
returns a directed graph; [Exporting
networks](https://pak.dynasite.org/cooccure/articles/exporting.md) shows
the other formats.

## When should weights be rescaled?

Scaling is applied after the similarity measure and changes the spread
of the weights, not which pairs are linked. `scale = "minmax"` maps the
weights to the range 0 to 1.

``` r

co(movies, field = "genres", sep = ",", similarity = "jaccard",
   scale = "minmax", top_n = 5)
#> # cooccurrence: 22 nodes, 5 edges | density: 0.0216 | mean degree: 0.4545 | 1000 transactions
#> # similarity: jaccard | counting: full | scale: minmax
#> # possible edges: 231 | isolates: 14
#> # top nodes: Adventure(deg=2,str=1.728), Action(deg=2,str=1.559), Animation(deg=1,str=1), Crime(deg=1,str=0.8314), Comedy(deg=1,str=0.7403)
#>       from          to weight count
#>  Adventure   Animation  1.000    39
#>     Action       Crime  0.831    59
#>     Comedy       Drama  0.740   159
#>     Action   Adventure  0.728    44
#>  Biography Documentary  0.714    44
```

*Adventure*–*Animation*, the strongest Jaccard pair, scores 1 and the
other weights are fractions of it: *Action*–*Crime* is at 0.831 of the
top pair. The order is the Jaccard order.

`scale = "zscore"` expresses each weight in standard deviations from the
mean weight, so weights below the mean are negative. A `threshold` of 1
keeps the edges at least one standard deviation above the mean.

``` r

co(movies, field = "genres", sep = ",", similarity = "jaccard",
   scale = "zscore", threshold = 1)
#> # cooccurrence: 22 nodes, 15 edges | density: 0.0649 | mean degree: 1.3636 | 1000 transactions
#> # similarity: jaccard | counting: full | scale: zscore
#> # possible edges: 231 | isolates: 8
#> # top nodes: Action(deg=4,str=9.225), Crime(deg=3,str=7.393), Drama(deg=3,str=7.343), Thriller(deg=3,str=4.957), Adventure(deg=2,str=7.303)
#>         from          to weight count
#>    Adventure   Animation   4.35    39
#>       Action       Crime   3.48    59
#>       Comedy       Drama   3.02   159
#>       Action   Adventure   2.95    44
#>    Biography Documentary   2.88    44
#>        Drama     Romance   2.77   131
#>        Crime    Thriller   2.35    37
#>       Comedy     Romance   2.23    63
#>  Documentary       Music   2.07    28
#>    Biography     History   2.02    23
#> # ... 5 more edges
```

Fifteen genre pairs are at least one standard deviation above the mean
Jaccard weight, the strongest being *Adventure*–*Animation* at 4.35. A
negative threshold keeps edges above a point below the mean; the default
`threshold = 0` keeps every edge. The other scalings (`"log"`,
`"log10"`, `"sqrt"`, `"binary"`, `"proportion"`) are described in
[`?cooccurrence`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

## Which measure to use?

- **Describing the data:** `"none"` shows the counts as they are, and
  its heaviest edges show where most co-occurrence lies.
- **Bibliometric and scientometric maps:** `"association"`, as
  recommended by van Eck and Waltman (2009), because it removes the
  effect of item frequency. Pair it with `min_occur` so that pairs of
  rare items do not dominate.
- **Overlap of two items’ transactions:** `"jaccard"` or `"dice"`, which
  rank pairs identically; Jaccard gives lower weights.
- **Pairs of unequal frequency:** `"cosine"` penalizes a frequent item
  paired with a rare one less than Jaccard does; `"equivalence"` keeps
  the cosine order and widens the gaps.
- **Containment:** `"inclusion"` shows when a rare item appears mostly
  with a common one, again with `min_occur`.
- **Composition of each item’s ties:** `"relative"` gives, for each
  item, the share of its co-occurrences going to each other item, as a
  directed network.

Counting choices are covered in [Counting
methods](https://pak.dynasite.org/cooccure/articles/counting.md), and
group comparisons in [Comparing
groups](https://pak.dynasite.org/cooccure/articles/comparing-groups.md).

## Reference

van Eck, N. J., & Waltman, L. (2009). How to normalize cooccurrence
data? An analysis of some well-known similarity measures. *Journal of
the American Society for Information Science and Technology, 60*(8),
1635–1651. <https://doi.org/10.1002/asi.21075>
