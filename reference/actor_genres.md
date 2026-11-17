# Actors and the genres of their films (IMDb, 1970-2024)

`actor_genres` is a dataset of the genres the 624 actors of
[actors](https://pak.dynasite.org/cooccure/reference/actors.md) work in:
every genre of every film they appeared in, one row per actor and genre.
Used with `field = "actor"` and `by = "genre"`, it links actors who work
in the same genres; with the roles reversed, it links genres that share
actors.

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

<https://data.imdb.com/non-commercial-datasets/>

## See also

[actors](https://pak.dynasite.org/cooccure/reference/actors.md);
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).

## Examples

``` r
head(actor_genres)
#>            actor     genre
#> 1    Phil Harris Adventure
#> 2    Phil Harris Animation
#> 3    Phil Harris    Comedy
#> 4 Larry Clemmons Adventure
#> 5 Larry Clemmons Animation
#> 6 Larry Clemmons    Comedy
cooccurrence(actor_genres, field = "actor", by = "genre", similarity = "jaccard")
#> # cooccurrence: 624 nodes, 172390 edges | density: 0.8869 | mean degree: 552.5321 | 20 transactions
#> # similarity: jaccard | counting: full
#> # possible edges: 194376 | isolates: 0
#> # top nodes: Babu Pathak(deg=623,str=240.1), Sheila Allen(deg=623,str=240.1), Stacey Pickren(deg=623,str=240.1), Armando Pizzuti(deg=623,str=236.2), Shameer Muhammed(deg=623,str=236.2)
#>            from               to weight count
#>      Adam Brown      Adnan Ghani      1     4
#>      Adam Brown   Akimasa Ohmori      1     4
#>     Adnan Ghani   Akimasa Ohmori      1     4
#>     Adam Strick         Aleks Le      1     3
#>       Akash Dev Anil K. Shivaram      1     5
#>        Abhilash     Anson Antony      1     4
#>        Abhilash  Antony Varghese      1     4
#>    Anson Antony  Antony Varghese      1     4
#>  Ashwani Chopra     Asif Ali Beg      1     5
#>          Aamani         Banerjee      1     3
#> # ... 172380 more edges
```
