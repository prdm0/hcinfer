# hcinfer (development version)

* Added `boot_pairs()` for pairs (case) bootstrap standard errors and confidence intervals of ordinary least squares coefficients. It resamples the observations with replacement, refits the model on each replicate, and summarizes the sampling distribution of the coefficients, providing an assumption-free empirical reference for the analytic heteroskedasticity-consistent standard errors from `hcinfer()` and `vcov_hc()`. Percentile, basic, and normal intervals are available, the resampling is reproducible through the `seed` argument, and the replicate fits can optionally run in parallel via `purrr::in_parallel()` and `mirai` without changing the numeric result.
* Added `coef()`, `vcov()`, `confint()`, `print()`, and `plot()` methods for the `hcinfer_boot` objects returned by `boot_pairs()`. `vcov()` returns the bootstrap covariance matrix of the coefficients, `confint()` can recompute intervals at a different `level` or `type` directly from the stored replicates, and `plot()` draws the bootstrap confidence intervals, coloring each coefficient by whether its interval excludes or includes zero.
* `hcinfer()` and `vcov_hc()` now accept independent HCbeta shape caps from 50 through 25000 inclusive, with defaults of 10000. HC0, HC1, and HCbeta also remain defined for an exact leverage value of one, while HC2, HC3, HC4, HC4m, HC5, and HC5m retain the positive leverage-complement requirement.

# hcinfer 0.1.1

* Added the `PublicSchools2` dataset with 2024 per capita income, 2025 public school expenditure per student, a Southern-region indicator, and complete variable and source documentation.
* Standardized the federal district name in `PublicSchools` from `Washington DC` to `District of Columbia`.

# hcinfer 0.1.0

# hcinfer 0.0.0.9000

* Added the initial development version with HC covariance estimators, normal Wald inference, S3 output, and the PublicSchools dataset.
* `plot()` now supports `vcov_hc()` objects, producing leverage-versus-adjustment-factor graphics for inspecting the relationship between h_t and g_t.
* summary() now prints formal test results, confidence interval checks, and optional emoji markers to improve interpretation of robust inference output.
* summary() now keeps displayed test_result decisions consistent with numeric p-values when p-values are displayed as <0.001.
* Added `tests()` as a formal extractor for coefficient-level Wald test results. The function mirrors the API of `confint()`: an optional `parm` argument selects coefficients by name or position, and an optional `alpha` argument recomputes the `reject` column without affecting the stored p-values or test statistics.
