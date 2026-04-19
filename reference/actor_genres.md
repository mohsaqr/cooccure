# IMDB actor-genre long table (1970-2024)

Long-format table mapping each of the 624 actors in
[`actors`](http://saqr.me/cooccur/reference/actors.md) to every genre of
every movie they appeared in. Use this to build an actor co-occurrence
network grouped by genre: which actors share the same genres? Pass
`field = "actor"` and `by = "genre"` to
[`cooccurrence`](http://saqr.me/cooccur/reference/cooccurrence.md).

## Usage

``` r
actor_genres
```

## Format

A data frame with 2,502 rows and 2 variables:

- actor:

  Actor name.

- genre:

  Genre label (one row per actor-genre combination).

## Source

<https://developer.imdb.com/non-commercial-datasets/>

## Examples

``` r
head(actor_genres)
#> [1] actor genre
#> <0 rows> (or 0-length row.names)
cooccurrence(actor_genres, field = "actor", by = "genre", similarity = "jaccard")
#> Error: No non-empty transactions found in the input data.
```
