# Full, fractional and attention counting

Before any similarity measure is applied, a co-occurrence network rests
on a count: how much each transaction adds to the weight of each pair of
its items. The default, full counting, adds one for every pair in every
transaction. A transaction with $`n`$ items therefore creates
$`n(n - 1)/2`$ pairs, so a film with five genres contributes ten links
and a film with two genres one link, and transactions with many items
dominate the network. In bibliometrics this problem led to fractional
counting, in which each pair of a transaction with $`n`$ items adds
$`1/(n - 1)`$, so that the links of every item within one transaction
sum to one (Perianes-Rodriguez et al., 2016). For ordered transactions,
such as sessions of learning actions, a third option weights each pair
by the distance between the two items, so that items close together in a
sequence are linked more strongly than items far apart.

This guide compares the three methods available through the `counting`
argument of
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).
It shows what each method adds per transaction, checks the weights by
hand, and asks when the choice changes the conclusions drawn from a
network. Normalization of the counts by item frequencies is a separate
step, covered in [Choosing a similarity
measure](https://pak.dynasite.org/cooccure/articles/similarity-measures.md).

``` r

library(cooccure)
```

## Data

`movies` holds 1,000 highly rated IMDb films, one row per film:

- **Transaction:** the film (`tconst`).
- **Items:** `genres`, a comma-delimited string of one to three genres.

`actors` is a long table with one row per actor and film:

- **Items:** `actor`.
- **Transaction:** `tconst`, the film.

The number of items per transaction is what separates full from
fractional counting, so both distributions are shown first.

``` r

with(movies, table(n_genres = lengths(strsplit(genres, ","))))
#> n_genres
#>   1   2   3 
#> 231 300 469
with(actors, table(cast_size = table(tconst)))
#> cast_size
#>   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  18  19  20  25  27  34 
#> 177  77  41  31  18  16  10   9   4   1   3   1   2   1   1   1   2   1   1   1   1   1 
#>  38 
#>   1
```

Films carry one, two or three genres; 231 films have a single genre and
add nothing to the genre network under any counting method. Cast sizes
in the `actors` table vary far more, from 1 to 38 actors per film,
because the table keeps only actors who appear in at least two of the
films.

## Full counting

Under full counting, each film adds one to each pair of its genres.

``` r

cooccurrence(movies, field = "genres", sep = ",", top_n = 5)
#> # cooccurrence: 22 nodes, 5 edges | density: 0.0216 | mean degree: 0.4545 | 1000 transactions
#> # similarity: none | counting: full
#> # possible edges: 231 | isolates: 17
#> # top nodes: Drama(deg=4,str=452), Comedy(deg=2,str=222), Romance(deg=2,str=194), Crime(deg=1,str=91), Action(deg=1,str=71)
#>    from      to weight count
#>  Comedy   Drama    159   159
#>   Drama Romance    131   131
#>   Crime   Drama     91    91
#>  Action   Drama     71    71
#>  Comedy Romance     63    63
```

*Comedy* and *Drama* share 159 films, so their weight is 159, equal to
the `count` column. Under full counting the weight and the count are
always the same.

## Fractional counting

Under fractional counting, a film with $`n`$ genres adds $`1/(n - 1)`$
to each of its pairs: 1 for a two-genre film, 0.5 for a three-genre
film.

``` r

cooccurrence(movies, field = "genres", sep = ",", counting = "fractional",
             top_n = 5)
#> # cooccurrence: 22 nodes, 5 edges | density: 0.0216 | mean degree: 0.4545 | 1000 transactions
#> # similarity: none | counting: fractional
#> # possible edges: 231 | isolates: 17
#> # top nodes: Drama(deg=4,str=293), Comedy(deg=2,str=146), Romance(deg=2,str=133), Crime(deg=1,str=52.5), Action(deg=1,str=38.5)
#>    from      to weight count
#>  Comedy   Drama  107.5   159
#>   Drama Romance   94.5   131
#>   Crime   Drama   52.5    91
#>  Action   Drama   38.5    71
#>  Comedy Romance   38.5    63
```

The weight of *Comedy* and *Drama* falls from 159 to 107.5 while the
count stays at 159. The value can be checked from the composition of
those 159 films.

``` r

with(movies, table(
  comedy_and_drama = grepl("Comedy", genres) & grepl("Drama", genres),
  n_genres = lengths(strsplit(genres, ","))
))
#>                 n_genres
#> comedy_and_drama   1   2   3
#>            FALSE 231 244 366
#>            TRUE    0  56 103
```

Of the 159 films, 56 carry two genres and add 1 each, and 103 carry
three genres and add 0.5 each: $`56 + 103 \times 0.5 = 107.5`$.

Fractional counting has a second property that serves as a check: the
links of a genre within one film sum to one, so a genre’s strength (the
sum of its edge weights) equals the number of its films that carry at
least one other genre.

``` r

genre_fractional <- cooccurrence(movies, field = "genres", sep = ",",
                                 counting = "fractional")
head(as.data.frame(genre_fractional, what = "nodes"), 4)
#>      node degree strength count_strength frequency
#> 1   Drama     20      504            812       634
#> 2  Comedy     19      252            412       278
#> 3 Romance     17      155            237       160
#> 4  Action     17      154            295       155
with(movies, table(drama = grepl("Drama", genres),
                   several_genres = grepl(",", genres)))
#>        several_genres
#> drama   FALSE TRUE
#>   FALSE   101  265
#>   TRUE    130  504
```

*Drama* has a frequency of 634 films and a fractional strength of 504,
the number of *Drama* films with at least one other genre; the remaining
130 are tagged *Drama* alone. Under full counting the same strength is
812, because three-genre films count twice for each of their genres.

## Does the counting method change the conclusions?

Because the films carry at most three genres, the two methods differ by
at most a factor of two per film, and the strongest raw pairs keep their
order. The difference grows once counts are normalized, because a
measure such as association strength divides by the item frequencies,
which do not change with the counting method.

``` r

cooccurrence(movies, field = "genres", sep = ",",
             similarity = "association", top_n = 6)
#> # cooccurrence: 22 nodes, 6 edges | density: 0.0260 | mean degree: 0.5455 | 1000 transactions
#> # similarity: association | counting: full
#> # possible edges: 231 | isolates: 12
#> # top nodes: News(deg=2,str=0.02271), Horror(deg=2,str=0.01671), History(deg=1,str=0.01613), Sci-Fi(deg=1,str=0.01136), Documentary(deg=1,str=0.006579)
#>         from        to  weight count
#>      History      News 0.01613     1
#>       Horror    Sci-Fi 0.01136     2
#>  Documentary      News 0.00658     1
#>      Fantasy    Horror 0.00535     2
#>    Adventure Animation 0.00515    39
#>       Family   Musical 0.00463     2
cooccurrence(movies, field = "genres", sep = ",",
             similarity = "association", counting = "fractional", top_n = 6)
#> # cooccurrence: 22 nodes, 6 edges | density: 0.0260 | mean degree: 0.5455 | 1000 transactions
#> # similarity: association | counting: fractional
#> # possible edges: 231 | isolates: 13
#> # top nodes: News(deg=2,str=0.01135), Horror(deg=2,str=0.0112), Documentary(deg=2,str=0.006199), Sci-Fi(deg=1,str=0.008523), History(deg=1,str=0.008065)
#>         from        to  weight count
#>       Horror    Sci-Fi 0.00852     2
#>      History      News 0.00806     1
#>  Documentary      News 0.00329     1
#>  Documentary     Music 0.00291    28
#>      Fantasy    Horror 0.00267     2
#>    Adventure Animation 0.00257    39
```

*History* and *News* lead under full counting (0.01613) but drop to
second under fractional counting (0.00806). The ratio of 0.5 shows that
their one shared film carries three genres. *Horror* and *Sci-Fi* keep
three quarters of their weight (0.01136 to 0.00852), since one of their
two shared films has two genres and the other three, and they move to
the top. *Documentary* and *Music* enter the six strongest pairs under
fractional counting. The ranking of pairs that rest on one or two films
is fragile under both methods, which is a reason to combine association
strength with `min_occur`.

## Casts of different sizes

The case for fractional counting is stronger when transaction sizes vary
widely, as the casts in `actors` do. Under full counting, an actor in a
38-member cast gains 37 links from that one film.

``` r

actors_full <- cooccurrence(actors, field = "actor", by = "tconst")
actors_fractional <- cooccurrence(actors, field = "actor", by = "tconst",
                                  counting = "fractional")
subset(as.data.frame(actors_full, what = "nodes"),
       node %in% c("Brad Rea", "Julia Bache-Wiig"))
#>                 node degree strength count_strength frequency
#> 1           Brad Rea     66       70             70         2
#> 395 Julia Bache-Wiig      5        7              7         3
subset(as.data.frame(actors_fractional, what = "nodes"),
       node %in% c("Brad Rea", "Julia Bache-Wiig"))
#>                 node degree strength count_strength frequency
#> 3           Brad Rea     66        2             70         2
#> 395 Julia Bache-Wiig      5        3              7         3
```

Brad Rea appears in two films with large casts in the table and reaches
a degree of 66 and a full-counting strength of 70. Julia Bache-Wiig
appears in three films with small casts and has a strength of 7. Under
fractional counting their strengths become 2 and 3: one per film with at
least one co-star in the table. Fractional counting thus ranks actors by
the number of collaborative films rather than by the size of their
casts. Degree, a count of distinct co-stars, does not change with the
counting method.

``` r

subset(as.data.frame(actors_fractional), from == "Julia Bache-Wiig")
#>                 from             to weight count
#> 11  Julia Bache-Wiig Robin Ottersen   1.33     3
#> 172 Julia Bache-Wiig Viktoria Winge   0.50     1
```

The pair Julia Bache-Wiig and Robin Ottersen shares three films (count
3) but keeps a fractional weight of 1.33, because the casts of some of
those films include further actors of the table.

## Attention counting for ordered transactions

When the items of a transaction are ordered, such as the states of a
learning session, full and fractional counting ignore the order.
Attention counting adds $`\exp(-|p_i - p_j| / \lambda)`$ for each pair,
where $`p_i`$ and $`p_j`$ are the positions of the two items, so the
contribution decays with their distance. A single sequence of three
states shows the weights.

``` r

cooccurrence(list(c("A", "B", "C")), counting = "attention")
#> # cooccurrence: 3 nodes, 3 edges | density: 1.0000 | mean degree: 2.0000 | 1 transactions
#> # similarity: none | counting: attention
#> # possible edges: 3 | isolates: 0
#> # top nodes: B(deg=2,str=0.7358), A(deg=2,str=0.5032), C(deg=2,str=0.5032)
#>  from to weight count
#>     A  B  0.368     1
#>     B  C  0.368     1
#>     A  C  0.135     1
```

Adjacent states add $`e^{-1} = 0.368`$ and states two positions apart
add $`e^{-2} = 0.135`$, while the `count` column still records one
shared transaction. Repeated states are removed before positions are
assigned, so each state keeps the position of its first occurrence.

The bundled data are not ordered, so the six learning sessions of the
[sequences
guide](https://pak.dynasite.org/cooccure/articles/sequences.md)
illustrate the method.

``` r

sessions <- data.frame(
  t1 = c("plan",    "plan",   "read",   "plan",    "read",    "plan"),
  t2 = c("read",    "read",   "write",  "read",    "read",    "write"),
  t3 = c("write",   "read",   "review", "discuss", "write",   "review"),
  t4 = c("review",  "write",  "write",  "write",   "discuss", "write"),
  t5 = c("write",   "review", NA,       "review",  "write",   "review"),
  t6 = c("discuss", NA,       NA,       "plan",    "review",  NA)
)
cooccurrence(sessions, field = "all", counting = "attention")
#> # cooccurrence: 5 nodes, 10 edges | density: 1.0000 | mean degree: 4.0000 | 6 transactions
#> # similarity: none | counting: attention
#> # possible edges: 10 | isolates: 0
#> # top nodes: write(deg=4,str=5.141), read(deg=4,str=3.769), review(deg=4,str=3.605), discuss(deg=4,str=2.449), plan(deg=4,str=2.199)
#>     from     to weight count
#>   review  write  1.975     6
#>     read  write  1.607     5
#>     plan   read  1.104     3
#>  discuss review  0.871     3
#>  discuss  write  0.871     3
#>     plan  write  0.688     4
#>  discuss   read  0.553     3
#>     read review  0.506     5
#>     plan review  0.253     4
#>  discuss   plan  0.154     2
```

Under full counting, *read* and *review* share five sessions, the second
highest count (see the [sequences
guide](https://pak.dynasite.org/cooccure/articles/sequences.md)). Under
attention counting they fall to a weight of 0.506, below *plan* and
*read* (1.104), which share only three sessions but always as neighbors.
The decay rate `lambda` sets how fast distance is penalized.

``` r

cooccurrence(sessions, field = "all", counting = "attention", lambda = 3)
#> # cooccurrence: 5 nodes, 10 edges | density: 1.0000 | mean degree: 4.0000 | 6 transactions
#> # similarity: none | counting: attention
#> # possible edges: 10 | isolates: 0
#> # top nodes: write(deg=4,str=11.53), review(deg=4,str=9.831), read(deg=4,str=9.403), plan(deg=4,str=6.551), discuss(deg=4,str=6.268)
#>     from     to weight count
#>   review  write  4.096     6
#>     read  write  3.380     5
#>     read review  2.276     5
#>     plan   read  2.150     3
#>     plan  write  2.111     4
#>  discuss review  1.946     3
#>  discuss  write  1.946     3
#>  discuss   read  1.598     3
#>     plan review  1.513     4
#>  discuss   plan  0.777     2
```

With `lambda = 3`, distant pairs keep more of their weight and *read*
and *review* return to third place (2.276). As `lambda` grows, attention
counting approaches full counting; as it shrinks, only adjacent states
contribute. Attention counting can also be combined with `window`, so
that pairs beyond the window contribute nothing and pairs within it are
weighted by distance.

## Counting with weighted input

A long table with a weight column (`weight_by`) already defines how much
each item contributes to its transaction, as described in [Input
formats](https://pak.dynasite.org/cooccure/articles/input-formats.md).
Fractional and attention counting derive that contribution from the
number or the positions of the items, so the two cannot be combined:
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
raises an error of class `cooccure_incompatible_args` when `weight_by`
is given with a counting method other than `"full"`.

## References

Perianes-Rodriguez, A., Waltman, L., & van Eck, N. J. (2016).
Constructing bibliometric networks: A comparison between full and
fractional counting. *Journal of Informetrics*, *10*(4), 1178–1195.
<https://doi.org/10.1016/j.joi.2016.10.006>
