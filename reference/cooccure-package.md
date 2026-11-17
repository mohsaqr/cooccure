# cooccure: co-occurrence networks from many kinds of data

`cooccure` builds co-occurrence networks, in which two items are linked
when they appear in the same transaction: the keywords of one article,
the genres of one film, the actors of one cast, or the states of one
learning session. The network shows which items tend to go together and
how a field, a corpus or a set of sessions is organized around them. The
weight of a link starts as the number of shared transactions; because
frequent items co-occur often by chance alone, it can be normalized for
item frequency by one of eight similarity measures (van Eck & Waltman,
2009), and each transaction's contribution can be counted fractionally
(Perianes-Rodriguez et al., 2016) or with a position decay. One network
can be built per group (`split_by`) or one network pooled over groups
(`aggregate_by`).

All of this is done by one function,
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md).
It reads delimited columns, long (item, transaction) tables, binary and
one-hot tables, wide sequences, lists of vectors and raw event logs,
with sliding windows over ordered sequences and eight scalings of the
weights, and returns the network as a tidy edge list.

## Results

The edge list prints with a diagnostic header.
[`summary.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
computes network, node and group metrics;
[`as.data.frame.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
returns the edge, node and group tables;
[`plot.cooccurrence()`](https://pak.dynasite.org/cooccure/reference/plot.cooccurrence.md)
draws a heatmap, a network or the degree distribution.

## Conversion

[`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
returns the weight or count matrix;
[`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md),
[`as_tidygraph()`](https://pak.dynasite.org/cooccure/reference/as_tidygraph.md),
[`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
and
[`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md)
convert to the graph classes of igraph, tidygraph, cograph and
Nestimate. The network is undirected except for
`similarity = "relative"`, which is directed.

## Data

[movies](https://pak.dynasite.org/cooccure/reference/movies.md),
[actors](https://pak.dynasite.org/cooccure/reference/actors.md) and
[actor_genres](https://pak.dynasite.org/cooccure/reference/actor_genres.md)
are drawn from the IMDb non-commercial datasets;
[demo](https://pak.dynasite.org/cooccure/reference/demo.md) is a small
hand-built cast table.
[`launch_app()`](https://pak.dynasite.org/cooccure/reference/launch_app.md)
opens an interactive explorer.

## References

van Eck, N. J., & Waltman, L. (2009). How to normalize cooccurrence
data? An analysis of some well-known similarity measures. *Journal of
the American Society for Information Science and Technology*, 60(8),
1635–1651. [doi:10.1002/asi.21075](https://doi.org/10.1002/asi.21075)

Perianes-Rodriguez, A., Waltman, L., & van Eck, N. J. (2016).
Constructing bibliometric networks: A comparison between full and
fractional counting. *Journal of Informetrics*, 10(4), 1178–1195.
[doi:10.1016/j.joi.2016.10.006](https://doi.org/10.1016/j.joi.2016.10.006)

## See also

Useful links:

- <https://github.com/mohsaqr/cooccure>

- <https://pak.dynasite.org/cooccure/>

- Report bugs at <https://github.com/mohsaqr/cooccure/issues>

## Author

**Maintainer**: Mohammed Saqr <saqr@saqr.me>
([ORCID](https://orcid.org/0000-0001-5881-3109)) \[copyright holder\]

Authors:

- Mohammed Saqr <saqr@saqr.me>
  ([ORCID](https://orcid.org/0000-0001-5881-3109)) \[copyright holder\]

- Sonsoles López-Pernas <sonsoles.lopez@uef.fi>
  ([ORCID](https://orcid.org/0000-0002-9621-1392)) \[copyright holder\]

- Kamila Misiejuk \[copyright holder\]
