# IMDB actor-movie long table (1970-2024)

Long-format bipartite table linking actors to the 1,000 movies in
[`movies`](http://saqr.me/cooccur/reference/movies.md). Each row is one
actor in one movie. Pass `field = "actor"` and `by = "tconst"` to
[`cooccurrence`](http://saqr.me/cooccur/reference/cooccurrence.md) to
build an actor co-appearance network.

## Usage

``` r
actors
```

## Format

A data frame with 25,636 rows and 7 variables:

- actor:

  Actor name.

- tconst:

  IMDB title identifier linking to
  [`movies`](http://saqr.me/cooccur/reference/movies.md).

- primaryTitle:

  Movie title.

- startYear:

  Release year (integer).

- decade:

  Release decade as a character string.

- genres:

  Comma-separated genre labels for the linked movie.

- averageRating:

  IMDB average user rating for the linked movie.

## Source

<https://developer.imdb.com/non-commercial-datasets/>

## Examples

``` r
head(actors)
#>               actor    tconst primaryTitle startYear decade genres
#> 1    Jean-Guy Lecat tt0062285      Oh, Sun      1970  1970s  Drama
#> 2  Sarah Hardenberg tt0062285      Oh, Sun      1970  1970s  Drama
#> 3      Juran Mladen tt0062285      Oh, Sun      1970  1970s  Drama
#> 4 Roland Guillemard tt0062285      Oh, Sun      1970  1970s  Drama
#> 5  Géraldine Baaron tt0062285      Oh, Sun      1970  1970s  Drama
#> 6    Ambroise M'Bia tt0062285      Oh, Sun      1970  1970s  Drama
#>   averageRating
#> 1           7.4
#> 2           7.4
#> 3           7.4
#> 4           7.4
#> 5           7.4
#> 6           7.4
cooccurrence(actors, field = "actor", by = "tconst",
             similarity = "cosine", min_occur = 3)
#> # cooccurrence: 12 nodes, 7 edges (47 transactions) | similarity: cosine
#>                from             to    weight count
#>    Julia Bache-Wiig Robin Ottersen 1.0000000     3
#>  Constantin Fleancu Liliana Mocanu 0.6666667     2
#>         Dina Pathak   Harish Magon 0.3333333     1
#>         Dina Pathak         Mukesh 0.3333333     1
#>           Akash Dev         Rajesh 0.3333333     1
#>         Joseph Izzo    Shiyoon Kim 0.3333333     1
#>              Mukesh          Vinod 0.3333333     1
```
