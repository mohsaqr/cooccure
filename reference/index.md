# Package index

## Overview

- [`cooccure`](https://pak.dynasite.org/cooccure/reference/cooccure-package.md)
  [`cooccure-package`](https://pak.dynasite.org/cooccure/reference/cooccure-package.md)
  : cooccure: co-occurrence networks from many kinds of data

## Building networks

Co-occurrence networks from delimited columns, long tables, one-hot
tables, sequences and event logs, with similarity, counting, scaling,
filtering and groups.

- [`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
  [`co()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
  : Build a co-occurrence network

## Results

Printing, summarizing and plotting a network, and its edge, node and
group tables.

- [`print(`*`<cooccurrence>`*`)`](https://pak.dynasite.org/cooccure/reference/print.cooccurrence.md)
  : Print a co-occurrence network
- [`summary(`*`<cooccurrence>`*`)`](https://pak.dynasite.org/cooccure/reference/summary.cooccurrence.md)
  : Summarize a co-occurrence network
- [`print(`*`<summary.cooccurrence>`*`)`](https://pak.dynasite.org/cooccure/reference/print.summary.cooccurrence.md)
  : Print a co-occurrence network summary
- [`as.data.frame(`*`<cooccurrence>`*`)`](https://pak.dynasite.org/cooccure/reference/as.data.frame.cooccurrence.md)
  : Extract the tables of a co-occurrence network
- [`as.data.frame(`*`<summary.cooccurrence>`*`)`](https://pak.dynasite.org/cooccure/reference/as.data.frame.summary.cooccurrence.md)
  : Extract the tables of a co-occurrence network summary
- [`plot(`*`<cooccurrence>`*`)`](https://pak.dynasite.org/cooccure/reference/plot.cooccurrence.md)
  : Plot a co-occurrence network

## Conversion

The weight matrix and the network classes of igraph, tidygraph, cograph
and Nestimate.

- [`as_matrix()`](https://pak.dynasite.org/cooccure/reference/as_matrix.md)
  : Extract the weight matrix of a co-occurrence network
- [`as_igraph()`](https://pak.dynasite.org/cooccure/reference/as_igraph.md)
  : Convert a co-occurrence network to an igraph graph
- [`as_tidygraph()`](https://pak.dynasite.org/cooccure/reference/as_tidygraph.md)
  : Convert a co-occurrence network to a tidygraph
- [`as_cograph()`](https://pak.dynasite.org/cooccure/reference/as_cograph.md)
  : Convert a co-occurrence network to a cograph network
- [`as_netobject()`](https://pak.dynasite.org/cooccure/reference/as_netobject.md)
  : Convert a co-occurrence network to a Nestimate netobject

## Data

Films, casts and genres from the IMDb non-commercial datasets, and a
small cast table.

- [`movies`](https://pak.dynasite.org/cooccure/reference/movies.md) :
  Highly rated films with their genres (IMDb, 1970-2024)
- [`actors`](https://pak.dynasite.org/cooccure/reference/actors.md) :
  Actors and the films they appeared in (IMDb, 1970-2024)
- [`actor_genres`](https://pak.dynasite.org/cooccure/reference/actor_genres.md)
  : Actors and the genres of their films (IMDb, 1970-2024)
- [`demo`](https://pak.dynasite.org/cooccure/reference/demo.md) : A
  small cast table of ten films

## Explorer

An interactive application for building networks.

- [`launch_app()`](https://pak.dynasite.org/cooccure/reference/launch_app.md)
  : Open the interactive co-occurrence explorer
