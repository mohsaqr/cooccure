# Notes on the bundled data (2026-11-17)

- `movies`, `actors`, `actor_genres` are derived from the IMDb
  non-commercial datasets (title.basics, title.ratings, title.principals);
  the build script is not in data-raw/ (only `demo.R` is). IMDb licenses
  these files for personal and non-commercial use; see the owner-decision
  note in AGENT-NOTE-REVIEW-2026-11-17.md.
- `actors` keeps the 624 actors in at least two of the 1,000 films
  (401 films have at least one such actor).
- `demo` is built by data-raw/demo.R (hand-entered casts and genres).
