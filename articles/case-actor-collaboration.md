# Case study: actor collaboration networks

Collaboration networks are among the oldest objects of network science.
Linking two people when they have worked on the same project, whether a
scientific paper or a film, turns a record of projects into a social
structure in which one can ask who works with whom, who bridges
otherwise separate groups, and how tightly knit a field is. Film casts
were one of the first large collaboration networks studied in this way
(Watts & Strogatz, 1998), because every film credits its cast and every
credit is public.

A collaboration network is a co-occurrence network with people as items
and projects as transactions. Its construction raises the questions that
any co-occurrence network raises. A film with a large cast links every
pair of its members, so a single production can create hundreds of links
that say little about repeated collaboration; fractional counting gives
such a film the same total weight as a film with two actors
(Perianes-Rodriguez et al., 2016). And a single shared film is weak
evidence of a working relationship, while a pair who share several films
have chosen, or been chosen, to work together again. This case study
builds the collaboration network of the actors in a sample of IMDb films
and asks how connected it is, which actors hold it together, which pairs
work together repeatedly, how the choice of counting changes the
picture, and how actors’ genres are related.

``` r

library(cooccure)
```

## Data

`actors` is a long table with one row per actor and film, drawn from the
IMDb non-commercial datasets for the films in `movies`. It is limited to
the 624 actors who appear in at least two of those films. The roles of
its columns are:

- **Item:** `actor`, the actor’s name.
- **Transaction:** `tconst`, the film identifier, with `primaryTitle`
  its title.
- **Grouping variable:** `decade`, the film’s release decade.
- **Not used here:** `startYear`, `genres` and `averageRating`, which
  describe the film.

A second table, `actor_genres`, lists each of the 624 actors with every
genre of every film they appeared in, one row per actor and genre.

``` r

head(actors)
#>                actor    tconst   primaryTitle startYear decade                     genres
#> 24       Phil Harris tt0065421 The Aristocats      1970  1970s Adventure,Animation,Comedy
#> 25    Larry Clemmons tt0065421 The Aristocats      1970  1970s Adventure,Animation,Comedy
#> 26     Paul Winchell tt0065421 The Aristocats      1970  1970s Adventure,Animation,Comedy
#> 34 Sterling Holloway tt0065421 The Aristocats      1970  1970s Adventure,Animation,Comedy
#> 37  Scatman Crothers tt0065421 The Aristocats      1970  1970s Adventure,Animation,Comedy
#> 43       Vito Scotti tt0065421 The Aristocats      1970  1970s Adventure,Animation,Comedy
#>    averageRating
#> 24           7.1
#> 25           7.1
#> 26           7.1
#> 34           7.1
#> 37           7.1
#> 43           7.1
```

Because only actors with at least two films are kept, the casts in this
table are fragments of the full casts.

``` r

with(actors, table(cast_size = table(tconst)))
#> cast_size
#>   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  18  19  20  25  27  34 
#> 177  77  41  31  18  16  10   9   4   1   3   1   2   1   1   1   2   1   1   1   1   1 
#>  38 
#>   1
```

Of the 401 films, 177 keep a single actor from the sample and contribute
no link; a few keep many, up to 38 actors in one film.

## How connected is the collaboration network?

Actors are the items and films the transactions, so `field` names the
actor column and `by` the film column.

``` r

collaboration <- cooccurrence(actors, field = "actor", by = "tconst")
summary(collaboration)
#> cooccurrence network
#> ------------------------------
#> Nodes          : 624
#> Edges          : 4353
#> Possible edges : 194376
#> Density        : 0.0224
#> Mean degree    : 13.9519
#> Isolates       : 34
#> Transactions   : 401
#> Similarity     : none
#> Counting       : full
#> Weight range   : [1, 3]
#> Weight mean    : 1.078
#> Count range    : [1, 3]
#> Count mean     : 1.078
#> Top nodes      : Brad Rea(66, 70), Dawn Michelle King(66, 70), Kevin LaRosa II(66, 70), Michael Runyard(66, 70), Ricki Lander(66, 70)
```

The 624 actors share 4,353 links, a density of 0.0224: each actor is
linked to 13.9519 others on average, out of 623 possible. Every weight
lies between 1 and 3 films, with a mean of 1.078, so most pairs have
shared a single film. Thirty-four actors have no link: each of their
films kept no other actor from the sample.

Whether the links join the actors into one connected network is a
question for **igraph**.

``` r

collaboration_graph <- as_igraph(collaboration)
igraph::count_components(collaboration_graph)
#> [1] 57
igraph::vcount(igraph::largest_component(collaboration_graph))
#> [1] 495
```

The network falls into 57 components, of which 34 are the isolated
actors. A single large component holds 495 of the 624 actors; the
remaining components are small groups linked only to each other.

## Which actors hold the network together?

The node table ranks actors by degree, the number of actors they share a
film with.

``` r

head(as.data.frame(collaboration, what = "nodes"), 8)
#>                 node degree strength count_strength frequency
#> 1           Brad Rea     66       70             70         2
#> 2 Dawn Michelle King     66       70             70         2
#> 3    Kevin LaRosa II     66       70             70         2
#> 4    Michael Runyard     66       70             70         2
#> 5       Ricki Lander     66       70             70         2
#> 6        Hilary Klym     59       59             59         2
#> 7    Jessica Winther     57       57             57         2
#> 8         Adi Granov     56       61             61         2
```

The highest degrees belong to actors with only two films each
(`frequency`): Brad Rea, Dawn Michelle King, Kevin LaRosa II, Michael
Runyard and Ricki Lander are each linked to 66 actors. Their two films
have large casts within the sample, and every cast member is linked to
every other. Degree in a collaboration network therefore measures how
large an actor’s casts were as much as how widely the actor works.

Betweenness centrality measures something else: how often an actor lies
on the shortest path between two others, and so how far the network
depends on that actor to connect its parts. Edge weights are ignored
here, so a path is counted in films rather than in weights.

``` r

head(sort(igraph::betweenness(collaboration_graph, weights = NA),
          decreasing = TRUE), 6)
#>         Tony Martin Hayley Joanne Bacon      Bill Humphries    Tom Goodman-Hill 
#>               22654               20033               16940               16717 
#> Johnette Napolitano   Naveen Polishetty 
#>               16067               14154
```

None of the six actors with the highest betweenness is among the actors
with the highest degree. Tony Martin, Hayley Joanne Bacon and the others
connect casts that would otherwise be separate, which large casts alone
do not do.

## Which pairs work together repeatedly?

A weight of 2 or more means that two actors share at least two films.
`threshold` keeps those pairs.

``` r

repeated <- cooccurrence(actors, field = "actor", by = "tconst",
                         threshold = 2)
print(repeated, n = 6)
#> # cooccurrence: 624 nodes, 338 edges | density: 0.0017 | mean degree: 1.0833 | 401 transactions
#> # similarity: none | counting: full
#> # possible edges: 194376 | isolates: 388
#> # top nodes: Mukesh(deg=12,str=24), Akihiko Sugizaki(deg=9,str=18), Ben Hernandez Bray(deg=9,str=18), Chris Ingersoll(deg=9,str=18), Daisuke Ryû(deg=9,str=18)
#>                from                 to weight count
#>    Julia Bache-Wiig     Robin Ottersen      3     3
#>           Akash Dev       Anson Antony      2     2
#>           Akash Dev    Antony Varghese      2     2
#>        Anson Antony    Antony Varghese      2     2
#>  Catalina Harabagiu Cerasela Iosifescu      2     2
#>  Ben Hernandez Bray    Chris Ingersoll      2     2
#> # ... 332 more edges
```

Of the 4,353 links, 338 are repeated collaborations, and only one pair,
Julia Bache-Wiig and Robin Ottersen, shares three films. With the
filter, 388 actors have no repeated partner.

The Jaccard index asks a stricter question: of all the films either
actor appears in, what share do they appear in together? Actors with at
least three films in the sample are kept, so that a score rests on more
than two films.

``` r

regulars <- cooccurrence(actors, field = "actor", by = "tconst",
                         similarity = "jaccard", min_occur = 3)
regulars
#> # cooccurrence: 19 nodes, 7 edges | density: 0.0409 | mean degree: 0.7368 | 47 transactions
#> # similarity: jaccard | counting: full
#> # possible edges: 171 | isolates: 7
#> # top nodes: Dina Pathak(deg=2,str=0.4), Mukesh(deg=2,str=0.4), Julia Bache-Wiig(deg=1,str=1), Robin Ottersen(deg=1,str=1), Constantin Fleancu(deg=1,str=0.5)
#>                from             to weight count
#>    Julia Bache-Wiig Robin Ottersen    1.0     3
#>  Constantin Fleancu Liliana Mocanu    0.5     2
#>         Dina Pathak   Harish Magon    0.2     1
#>         Dina Pathak         Mukesh    0.2     1
#>           Akash Dev         Rajesh    0.2     1
#>         Joseph Izzo    Shiyoon Kim    0.2     1
#>              Mukesh          Vinod    0.2     1
```

Only 19 actors have three films in the sample, and they form 7 links.
Julia Bache-Wiig and Robin Ottersen score 1: each appears in the sample
only in the three films they share. Seven of the 19 actors have no link
to another actor with three films.

## Does fractional counting change the network?

Under full counting, a film adds 1 to every pair in its cast. Under
fractional counting, each pair in a film of *n* actors adds 1/(*n* - 1),
so every actor receives a total weight of 1 from each film whatever the
size of the cast.

``` r

fractional <- cooccurrence(actors, field = "actor", by = "tconst",
                           counting = "fractional")
print(fractional, n = 5)
#> # cooccurrence: 624 nodes, 4353 edges | density: 0.0224 | mean degree: 13.9519 | 401 transactions
#> # similarity: none | counting: fractional
#> # possible edges: 194376 | isolates: 34
#> # top nodes: Michael Runyard(deg=66,str=2), Kevin LaRosa II(deg=66,str=2), Brad Rea(deg=66,str=2), Dawn Michelle King(deg=66,str=2), Ricki Lander(deg=66,str=2)
#>            from               to weight count
#>    Hasan Zahedi    Mehran Mahram      2     2
#>    Luan Kryeziu   Molike Maxhuni      2     2
#>  Andreas Dresen   Steffi Kühnert      2     2
#>      Jang Gwang          Won Woo      2     2
#>          Tom Fu Zhuangzhuang Cai      2     2
#> # ... 4348 more edges
```

The edges are the same 4,353, but their weights now reflect the size of
the casts. The heaviest pairs, with a weight of 2, are pairs who form
the whole sampled cast of two films each. The actors with the highest
degree have a strength of 2, the same as any actor whose two films each
include another sampled actor, so fractional counting removes the
advantage that large casts gave them under full counting.

For the network of actors with three films, fractional counting changes
nothing.

``` r

regulars_fractional <- cooccurrence(actors, field = "actor", by = "tconst",
                                    similarity = "jaccard", min_occur = 3,
                                    counting = "fractional")
all.equal(as_matrix(regulars), as_matrix(regulars_fractional))
#> [1] TRUE
```

The two matrices are equal because, once `min_occur = 3` has removed the
other actors, no film keeps more than two of the 19, and for a film of
two actors 1/(*n* - 1) = 1. Fractional counting changes a network only
when the transactions differ in how many items they keep.

## Has collaboration changed across decades?

`split_by` builds one network per decade. Repeated collaborations within
a decade are kept with `threshold = 2`.

``` r

decade_pairs <- cooccurrence(actors, field = "actor", by = "tconst",
                             split_by = "decade", threshold = 2)
as.data.frame(decade_pairs, what = "groups")
#>   group n_nodes n_edges possible_edges  density weight_mean count_sum
#> 1 1970s      43      17            903 0.018826           2        34
#> 2 1980s      87      47           3741 0.012563           2        94
#> 3 1990s     106       6           5565 0.001078           2        12
#> 4 2000s     246      90          30135 0.002987           2       180
#> 5 2010s     353      85          62128 0.001368           2       170
#> 6 2020s     118       6           6903 0.000869           2        12
```

The number of sampled actors grows from 43 in the 1970s to 353 in the
2010s, as the sample itself grows from decade to decade. Repeated pairs
are most common relative to the number of actors in the 1970s and 1980s
(17 among 43 actors, 47 among 87) and rare in the 1990s and 2020s (6
each). Together the decades hold 251 repeated pairs (17 + 47 + 6 + 90 +
85 + 6), fewer than the 338 of the pooled network: 87 pairs repeated
their collaboration in a different decade, and splitting by decade hides
them.

## Which genres share actors?

`actor_genres` links actors to genres. Read with genres as items and
actors as transactions, it gives a genre network in which two genres are
linked by the actors who have worked in both.

``` r

career_genres <- cooccurrence(actor_genres, field = "genre", by = "actor",
                              similarity = "jaccard")
print(career_genres, n = 6)
#> # cooccurrence: 20 nodes, 155 edges | density: 0.8158 | mean degree: 15.5000 | 624 transactions
#> # similarity: jaccard | counting: full
#> # possible edges: 190 | isolates: 0
#> # top nodes: Drama(deg=19,str=2.759), Action(deg=19,str=2.735), Comedy(deg=19,str=2.14), Crime(deg=19,str=1.979), Adventure(deg=18,str=2.408)
#>       from        to weight count
#>     Action Adventure  0.518   221
#>     Action     Drama  0.382   229
#>  Adventure    Sci-Fi  0.363   107
#>      Crime  Thriller  0.342    95
#>     Comedy     Drama  0.338   187
#>     Action     Crime  0.329   143
#> # ... 149 more edges
```

The strongest link is between Action and Adventure (0.518, 221 actors),
followed by Action and Drama and by Adventure and Sci-Fi. In the
film-level genre network of the [genre case
study](https://pak.dynasite.org/cooccure/articles/case-imdb-genres.md)
the strongest pair is Adventure and Animation; at the level of careers,
the action adventure dominates. The two networks answer different
questions, which genres are combined in one film and which genres one
actor moves between.

## Summary

The actor network is sparse and fragmented into 57 components, with one
large component holding 495 of the 624 actors. High degree in it
reflects large casts, which fractional counting neutralizes, while
betweenness picks out a different set of actors who connect separate
casts. Most links rest on a single film; 338 pairs share two or more,
and splitting by decade hides the 87 pairs whose films fall in different
decades. For the counting methods, see the [guide to
counting](https://pak.dynasite.org/cooccure/articles/counting.md); for
per-group networks, the [guide to comparing
groups](https://pak.dynasite.org/cooccure/articles/comparing-groups.md);
and for igraph and other formats, the [guide to
exporting](https://pak.dynasite.org/cooccure/articles/exporting.md).

## References

Perianes-Rodriguez, A., Waltman, L., & van Eck, N. J. (2016).
Constructing bibliometric networks: A comparison between full and
fractional counting. *Journal of Informetrics*, 10(4), 1178–1195.
<https://doi.org/10.1016/j.joi.2016.10.006>

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of
‘small-world’ networks. *Nature*, 393(6684), 440–442.
<https://doi.org/10.1038/30918>
