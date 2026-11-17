# Keep BLAS/OpenMP threads within CRAN's two-core limit.
Sys.setenv(OMP_THREAD_LIMIT = 2)

library(testthat)
library(cooccure)

test_check("cooccure")
