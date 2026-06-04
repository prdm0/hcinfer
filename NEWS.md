# hcinfer (development version)

# hcinfer 0.1.0

# hcinfer 0.0.0.9000

* Added the initial development version with HC covariance estimators, normal Wald inference, S3 output, and the PublicSchools dataset.
* `plot()` now supports `vcov_hc()` objects, producing leverage-versus-adjustment-factor graphics for inspecting the relationship between h_t and g_t.
* summary() now prints formal test results, confidence interval checks, and optional emoji markers to improve interpretation of robust inference output.
* summary() now keeps displayed test_result decisions consistent with numeric p-values when p-values are displayed as <0.001.
* Added `tests()` as a formal extractor for coefficient-level Wald test results. The function mirrors the API of `confint()`: an optional `parm` argument selects coefficients by name or position, and an optional `alpha` argument recomputes the `reject` column without affecting the stored p-values or test statistics.
