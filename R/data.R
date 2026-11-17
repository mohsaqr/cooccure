# ---- Package datasets ----

#' Highly rated films with their genres (IMDb, 1970-2024)
#'
#' @description
#' `movies` is a sample of 1,000 films with an IMDb rating of at least 7.0 and
#' at least 1,000 votes, released between 1970 and 2024. Each film lists its
#' genres in one comma-delimited column, so the data illustrate co-occurrence
#' from a delimited field: genres are linked when they are assigned to the same
#' film. The release decade and the rating allow one network per group.
#'
#' @format A data frame with 1,000 rows and 7 variables:
#' \describe{
#'   \item{tconst}{IMDB title identifier (e.g. \code{"tt0068646"}).}
#'   \item{primaryTitle}{Movie title.}
#'   \item{startYear}{Release year (integer).}
#'   \item{genres}{Comma-separated genre labels (e.g. \code{"Crime,Drama"}).}
#'   \item{decade}{Release decade as a character string (e.g. \code{"1970s"}).}
#'   \item{averageRating}{IMDB average user rating.}
#'   \item{numVotes}{Number of IMDB user votes.}
#' }
#' @source \url{https://data.imdb.com/non-commercial-datasets/}
#' @seealso [actors] for the casts of these films; [cooccurrence()].
#' @examples
#' head(movies)
#' cooccurrence(movies, field = "genres", sep = ",", similarity = "jaccard")
"movies"


#' Actors and the films they appeared in (IMDb, 1970-2024)
#'
#' @description
#' `actors` is a dataset of the 624 actors who appear in at least two of the
#' films in [movies], with one row per actor and film. The data illustrate
#' co-occurrence from a long (item, transaction) table: actors are linked when
#' they appear in the same film, which gives a collaboration network.
#'
#' @format A data frame with 1,267 rows and 7 variables:
#' \describe{
#'   \item{actor}{Actor name.}
#'   \item{tconst}{IMDB title identifier linking to \code{\link{movies}}.}
#'   \item{primaryTitle}{Movie title.}
#'   \item{startYear}{Release year (integer).}
#'   \item{decade}{Release decade as a character string.}
#'   \item{genres}{Comma-separated genre labels for the linked movie.}
#'   \item{averageRating}{IMDB average user rating for the linked movie.}
#' }
#' @source \url{https://data.imdb.com/non-commercial-datasets/}
#' @seealso [movies]; [actor_genres]; [cooccurrence()].
#' @examples
#' head(actors)
#' cooccurrence(actors, field = "actor", by = "tconst", similarity = "jaccard")
"actors"


#' Actors and the genres of their films (IMDb, 1970-2024)
#'
#' @description
#' `actor_genres` is a dataset of the genres the 624 actors of [actors] work in:
#' every genre of every film they appeared in, one row per actor and genre. Used
#' with `field = "actor"` and `by = "genre"`, it links actors who work in the
#' same genres; with the roles reversed, it links genres that share actors.
#'
#' @format A data frame with 2,502 rows and 2 variables:
#' \describe{
#'   \item{actor}{Actor name.}
#'   \item{genre}{Genre label (one row per actor-genre combination).}
#' }
#' @source \url{https://data.imdb.com/non-commercial-datasets/}
#' @seealso [actors]; [cooccurrence()].
#' @examples
#' head(actor_genres)
#' cooccurrence(actor_genres, field = "actor", by = "genre", similarity = "jaccard")
"actor_genres"


#' A small cast table of ten films
#'
#' @description
#' `demo` is a hand-built dataset of 30 actors in 10 well-known films, each film
#' carrying its full genre list, with one row per film, actor and genre. Every
#' pairing of two columns gives a network: actors linked by shared films, genres
#' linked by shared films, or actors linked by shared genres. It is small enough
#' to check a network by hand and is the default data of [launch_app()].
#'
#' @format A data frame with 89 rows and 3 variables:
#' \describe{
#'   \item{movie}{Movie title.}
#'   \item{actor}{Actor name.}
#'   \item{genre}{Genre label. Films carry every genre they belong to, so a
#'     movie contributes several rows per actor.}
#' }
#' @seealso [actors] for a larger cast table; [cooccurrence()].
#' @examples
#' head(demo)
#' # Actors linked by the films they share
#' cooccurrence(demo, field = "actor", by = "movie", similarity = "jaccard")
#'
#' # Genres linked by the films they share
#' cooccurrence(demo, field = "genre", by = "movie", similarity = "jaccard")
#'
#' # Actors linked by the genres they share
#' cooccurrence(demo, field = "actor", by = "genre")
"demo"
