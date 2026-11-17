# Sequences, windows and event logs

Much of the data collected about learning and behavior is sequential:
the actions a student takes in a learning management system, the
self-regulated learning phases coded from a think-aloud protocol, the
moves of a collaborative discussion. Transition networks model such data
through the order of consecutive states. Co-occurrence networks ask a
different question: which states appear together, regardless of which
came first. Applied to whole sequences, the answer is coarse, because in
a long session almost every state eventually shares the session with
every other. Restricting co-occurrence to a sliding window of
consecutive positions links only states that occur close together in
time, which yields a network of local association between states.

This guide shows how
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
handles ordered data. It contrasts whole-sequence co-occurrence with
windowed co-occurrence, discusses the choice of window size, and shows
how a raw event log with timestamps is cut into sessions before the
network is built. Weighting pairs by their distance within a sequence is
covered in [Full, fractional and attention
counting](https://pak.dynasite.org/cooccure/articles/counting.md).

``` r

library(cooccure)
```

## Data

The bundled IMDb data are not ordered, so two small tables written for
this guide illustrate sequential input. The first holds six learning
sessions in the wide format used by **TraMineR** and **tna**:

- **Sequence:** one row per session.
- **Time points:** columns `t1` to `t6`, in order.
- **States:** the cell values `plan`, `read`, `write`, `review` and
  `discuss`; `NA` marks the end of a shorter session.

``` r

sessions <- data.frame(
  t1 = c("plan",    "plan",   "read",   "plan",    "read",    "plan"),
  t2 = c("read",    "read",   "write",  "read",    "read",    "write"),
  t3 = c("write",   "read",   "review", "discuss", "write",   "review"),
  t4 = c("review",  "write",  "write",  "write",   "discuss", "write"),
  t5 = c("write",   "review", NA,       "review",  "write",   "review"),
  t6 = c("discuss", NA,       NA,       "plan",    "review",  NA)
)
sessions
#>     t1    t2      t3      t4     t5      t6
#> 1 plan  read   write  review  write discuss
#> 2 plan  read    read   write review    <NA>
#> 3 read write  review   write   <NA>    <NA>
#> 4 plan  read discuss   write review    plan
#> 5 read  read   write discuss  write  review
#> 6 plan write  review   write review    <NA>
```

The second is a raw event log of three students, one row per event:

- **Actor:** `student`.
- **Event:** `action`, the state recorded.
- **Time:** `time`, a timestamp, from which sessions are derived.

``` r

events <- data.frame(
  student = rep(c("s1", "s2", "s3"), c(7, 5, 6)),
  action  = c("plan", "read", "write", "review", "read", "write", "review",
              "plan", "read", "read", "write", "review",
              "read", "write", "discuss", "write", "review", "write"),
  time    = as.POSIXct("2026-03-02 09:00:00", tz = "UTC") +
    60 * c(0, 2, 5, 9, 40, 43, 47,
           0, 3, 4, 8, 12,
           0, 1, 30, 33, 35, 36)
)
head(events)
#>   student action                time
#> 1      s1   plan 2026-03-02 09:00:00
#> 2      s1   read 2026-03-02 09:02:00
#> 3      s1  write 2026-03-02 09:05:00
#> 4      s1 review 2026-03-02 09:09:00
#> 5      s1   read 2026-03-02 09:40:00
#> 6      s1  write 2026-03-02 09:43:00
```

## Which states share a session?

With `field = "all"`, each row is one transaction, and its distinct
states are linked to each other whatever their positions.

``` r

cooccurrence(sessions, field = "all")
#> # cooccurrence: 5 nodes, 10 edges | density: 1.0000 | mean degree: 4.0000 | 6 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: review(deg=4,str=18), write(deg=4,str=18), read(deg=4,str=16), plan(deg=4,str=13), discuss(deg=4,str=11)
#>     from     to weight count
#>   review  write      6     6
#>     read review      5     5
#>     read  write      5     5
#>     plan review      4     4
#>     plan  write      4     4
#>  discuss   read      3     3
#>     plan   read      3     3
#>  discuss review      3     3
#>  discuss  write      3     3
#>  discuss   plan      2     2
```

All five states are linked to all others (density 1). *Review* and
*write* share all six sessions, and *read* shares five sessions with
each of them. The network says which states are part of the same
sessions but nothing about whether they occur near each other: a state
at the start of a session and a state at its end count as much as two
adjacent states.

## Which states occur next to each other?

`window = 2` turns every pair of consecutive positions into a
transaction, so two states are linked only when one directly precedes
the other.

``` r

cooccurrence(sessions, field = "all", window = 2)
#> # cooccurrence: 5 nodes, 7 edges | density: 0.7000 | mean degree: 2.8000 | 26 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: write(deg=4,str=19), read(deg=3,str=8), plan(deg=3,str=5), review(deg=2,str=11), discuss(deg=2,str=5)
#>     from     to weight count
#>   review  write     10    10
#>  discuss  write      4     4
#>     read  write      4     4
#>     plan   read      3     3
#>  discuss   read      1     1
#>     plan review      1     1
#>     plan  write      1     1
```

The six sessions yield 26 windows: each session gives one window fewer
than it has states. The network keeps 7 of the 10 possible pairs.
*Review* and *write* are adjacent 10 times, which makes them the core of
the sessions. *Read* and *review*, which shared five sessions,
disappear: in these data a review is never directly preceded or followed
by reading. *Read* and *read* in consecutive positions form a window
with one distinct state, which adds no pair. Under a window the `count`
column counts windows, not sessions.

## How wide should the window be?

The window sets the time scale of the association. A window of three
positions also links states separated by one other state.

``` r

cooccurrence(sessions, field = "all", window = 3)
#> # cooccurrence: 5 nodes, 10 edges | density: 1.0000 | mean degree: 4.0000 | 20 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: write(deg=4,str=29), review(deg=4,str=20), read(deg=4,str=17), discuss(deg=4,str=13), plan(deg=4,str=9)
#>     from     to weight count
#>   review  write     12    12
#>     read  write      8     8
#>  discuss  write      6     6
#>  discuss   read      3     3
#>     plan   read      3     3
#>  discuss review      3     3
#>     read review      3     3
#>     plan  write      3     3
#>     plan review      2     2
#>  discuss   plan      1     1
```

With 20 windows the network again links all 10 pairs, but the weights
still follow proximity: *review* and *write* lead with 12, while *read*
and *review* are linked by 3 windows only. Between the adjacent pairs of
`window = 2` and the whole session lies a range of networks, and the
choice should follow the process studied: adjacent states for immediate
succession, wider windows for association within a phase of work.

A sequence shorter than the window contributes no transaction at all,
which matters when sessions differ in length.

``` r

cooccurrence(sessions, field = "all", window = 6)
#> # cooccurrence: 5 nodes, 10 edges | density: 1.0000 | mean degree: 4.0000 | 3 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: discuss(deg=4,str=11), read(deg=4,str=11), review(deg=4,str=11), write(deg=4,str=11), plan(deg=4,str=8)
#>     from     to weight count
#>  discuss   read      3     3
#>  discuss review      3     3
#>     read review      3     3
#>  discuss  write      3     3
#>     read  write      3     3
#>   review  write      3     3
#>  discuss   plan      2     2
#>     plan   read      2     2
#>     plan review      2     2
#>     plan  write      2     2
```

Only three of the six sessions have six states, so the network rests on
3 transactions and differs from the whole-sequence network. A window
equal to the longest sequence reproduces the whole-sequence network only
when every sequence has that length.

## Building the network from a raw event log

An event log has no sessions yet: they must be derived from the gaps
between consecutive events of the same actor. With `action` naming the
event column,
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
passes the log to
[`Nestimate::prepare()`](https://pak.dynasite.org/Nestimate/reference/prepare.html),
which orders the events of each actor by time and starts a new session
after a gap longer than `time_threshold` seconds (default 900, fifteen
minutes). Each session is then one ordered transaction. This input needs
the **Nestimate** package.

``` r

cooccurrence(events, actor = "student", action = "action", time = "time")
#> # cooccurrence: 5 nodes, 8 edges | density: 0.8000 | mean degree: 3.2000 | 5 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: write(deg=4,str=11), review(deg=4,str=10), read(deg=3,str=9), plan(deg=3,str=6), discuss(deg=2,str=2)
#>     from     to weight count
#>     read  write      4     4
#>   review  write      4     4
#>     read review      3     3
#>     plan   read      2     2
#>     plan review      2     2
#>     plan  write      2     2
#>  discuss review      1     1
#>  discuss  write      1     1
```

The 18 events form 5 sessions: student `s1` pauses for 31 minutes after
the fourth event and `s3` for 29 minutes after the second, so each of
them contributes two sessions, and `s2` contributes one. The gap rule is
an analytic choice; `time_threshold = Inf` keeps one sequence per
student.

``` r

cooccurrence(events, actor = "student", action = "action", time = "time",
             time_threshold = Inf)
#> # cooccurrence: 5 nodes, 9 edges | density: 0.9000 | mean degree: 3.6000 | 3 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: read(deg=4,str=9), review(deg=4,str=9), write(deg=4,str=9), plan(deg=3,str=6), discuss(deg=3,str=3)
#>     from     to weight count
#>     read review      3     3
#>     read  write      3     3
#>   review  write      3     3
#>     plan   read      2     2
#>     plan review      2     2
#>     plan  write      2     2
#>  discuss   read      1     1
#>  discuss review      1     1
#>  discuss  write      1     1
```

With 3 transactions instead of 5, *discuss* is now linked to *read*, a
pair that never shares a session under the fifteen-minute rule. A
sensitivity check on `time_threshold` shows which links depend on how
sessions are defined.

Windows apply to event logs in the same way as to wide sequences.

``` r

cooccurrence(events, actor = "student", action = "action", time = "time",
             window = 2)
#> # cooccurrence: 5 nodes, 4 edges | density: 0.4000 | mean degree: 1.6000 | 13 transactions
#> # similarity: none | counting: full
#> # possible edges: 10 | isolates: 0
#> # top nodes: write(deg=3,str=10), read(deg=2,str=6), review(deg=1,str=5), plan(deg=1,str=2), discuss(deg=1,str=1)
#>     from    to weight count
#>   review write      5     5
#>     read write      4     4
#>     plan  read      2     2
#>  discuss write      1     1
```

The five sessions yield 13 windows of adjacent events, and *review* and
*write* are the most frequent neighbors (5 windows).

## Sessionizing once, networking many times

When several networks are built from one log, for instance with
different windows, the log can be cut into sessions once with
[`Nestimate::prepare()`](https://pak.dynasite.org/Nestimate/reference/prepare.html)
and the prepared object passed to
[`cooccurrence()`](https://pak.dynasite.org/cooccure/reference/cooccurrence.md)
directly.

``` r

prepared <- Nestimate::prepare(events, actor = "student", action = "action",
                               time = "time")
from_prepared <- cooccurrence(prepared, window = 2)
from_log <- cooccurrence(events, actor = "student", action = "action",
                         time = "time", window = 2)
all.equal(as_matrix(from_prepared), as_matrix(from_log))
#> [1] TRUE
```

The two routes give the same network. The prepared object also feeds the
transition networks of **Nestimate** and **tna**, so a co-occurrence
network and a transition network can be built from identical sessions
and compared.
