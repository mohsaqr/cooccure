## Test environments

* local macOS (R release)
* GitHub Actions: ubuntu-latest, macos-latest, windows-latest
  (R release, devel, oldrel)
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 1 note

The single note flags:

* "New submission" — expected for a first submission.
* "Possibly misspelled words in DESCRIPTION": Conde, Jaccard, Pernas, Saqr.
  These are all proper nouns: Conde, Pernas, and Saqr are author surnames
  in the method reference cited in the Description, and Jaccard is Paul
  Jaccard, the 19th-century Swiss botanist whose name the Jaccard index
  bears.

## Submission

This is a first submission to CRAN.

## References

The DESCRIPTION references Saqr, López-Pernas, Conde, and Hernández-García
(2024) <doi:10.1007/978-3-031-54464-4_15>, which covers the network
construction and analysis methods implemented in the package.
