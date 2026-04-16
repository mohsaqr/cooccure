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
#' Long-format bipartite table linking actors to the 1,000 movies in
#' \code{\link{movies}}. Each row is one actor in one movie. Pass
#' \code{field = "actor"} and \code{by = "tconst"} to
#' \code{\link{cooccurrence}} to build an actor co-appearance network.
#'
#' @format A data frame with 25,636 rows and 7 variables:
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
#' cooccurrence(actors, field = "actor", by = "tconst",
#'              similarity = "cosine", min_occur = 3)
"actors"
