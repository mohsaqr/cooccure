# ---- Package datasets ----

#' IMDB movie metadata (1970-2024)
#'
#' A sample of 1,000 highly-rated IMDB movies (rating >= 7.0, >= 1,000 votes)
#' released between 1970 and 2024. The \code{genres} column is comma-delimited
#' and suitable for use as the \code{field} argument to \code{\link{cooccurrence}}.
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
#' @source \url{https://developer.imdb.com/non-commercial-datasets/}
#' @examples
#' head(movies)
#' cooccurrence(movies, field = "genres", sep = ",", similarity = "jaccard")
"movies"


#' IMDB actor-movie long table (1970-2024)
#'
#' Long-format bipartite table linking actors to movies in
#' \code{\link{movies}}. Pre-filtered to the 624 actors who appear in at
#' least two movies, so all similarity measures compute instantly.
#' Pass \code{field = "actor"} and \code{by = "tconst"} to
#' \code{\link{cooccurrence}} to build an actor co-appearance network.
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
#' @source \url{https://developer.imdb.com/non-commercial-datasets/}
#' @examples
#' head(actors)
#' cooccurrence(actors, field = "actor", by = "tconst", similarity = "jaccard")
"actors"


#' IMDB actor-genre long table (1970-2024)
#'
#' Long-format table mapping each of the 624 actors in \code{\link{actors}}
#' to every genre of every movie they appeared in. Use this to build an
#' actor co-occurrence network grouped by genre: which actors share the
#' same genres? Pass \code{field = "actor"} and \code{by = "genre"} to
#' \code{\link{cooccurrence}}.
#'
#' @format A data frame with 2,502 rows and 2 variables:
#' \describe{
#'   \item{actor}{Actor name.}
#'   \item{genre}{Genre label (one row per actor-genre combination).}
#' }
#' @source \url{https://developer.imdb.com/non-commercial-datasets/}
#' @examples
#' head(actor_genres)
#' cooccurrence(actor_genres, field = "actor", by = "genre", similarity = "jaccard")
"actor_genres"
