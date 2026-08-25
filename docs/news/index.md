# Changelog

## hcinfer 0.3.0

- Added
  [`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
  for feasible generalized least squares estimation under multiplicative
  heteroskedasticity. The `estimator` argument chooses the fit, either
  `"ml"` (default, Gaussian maximum likelihood) or `"two_step"`
  (Harvey’s corrected auxiliary regression), and for maximum likelihood
  the `method` argument selects the
  [`stats::optim()`](https://rdrr.io/r/stats/optim.html) algorithm:
  `"BFGS"` (default), `"Nelder-Mead"`, `"CG"`, or `"L-BFGS-B"`. New
  [`coef()`](https://rdrr.io/r/stats/coef.html) and
  [`vcov()`](https://rdrr.io/r/stats/vcov.html) methods access the mean
  and dispersion coefficients via `model =`, and
  [`confint()`](https://rdrr.io/r/stats/confint.html),
  [`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`print()`](https://rdrr.io/r/base/print.html),
  [`fitted()`](https://rdrr.io/r/stats/fitted.values.html), and
  [`residuals()`](https://rdrr.io/r/stats/residuals.html) methods
  support applied inference, while
  [`logLik()`](https://rdrr.io/r/stats/logLik.html) and
  [`nobs()`](https://rdrr.io/r/stats/nobs.html) enable
  [`AIC()`](https://rdrr.io/r/stats/AIC.html) and
  [`BIC()`](https://rdrr.io/r/stats/AIC.html) for maximum likelihood
  fits. The package `Description` now also covers feasible generalized
  least squares following Harvey (1976) and Cribari-Neto and Pereira
  (2019).
- Corrected the HC5 adjustment factor, which now follows the erratum to
  Cribari-Neto, Souza and Vasconcellos (2007).
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  and
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
  compute `g_t = (1 - h_t)^(-delta_t / 2)` instead of the expression
  `g_t = (1 - h_t)^(-delta_t)` printed in Section 3 of the original
  article, keeping
  `delta_t = min(h_t / h_bar, max(4, k * h_max / h_bar))` and the
  default `k = 0.7` unchanged. HC5 adjustment factors are therefore
  smaller, and HC5 standard errors, Wald statistics, p-values, and
  confidence intervals differ from those returned by earlier versions.
  HC5m is unaffected because it follows Li, Zhang, Zhang and Wang (2016)
  and applies its own exponent without the factor 1/2, so
  `type = "hc5m"` with `k1 = 0`, `k2 = 0`, and `k3 = 1` no longer
  reproduces `type = "hc5"` and instead squares its adjustment factor.
- Documented the corrected HC5 expression in the
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  help page and in the methodology vignette, and added the 2008 erratum
  to the references of
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md),
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md),
  [`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md), the
  methodology vignette, and the package `Description`.

## hcinfer 0.2.0

CRAN release: 2026-08-04

- Added
  [`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md)
  for pairs (case) bootstrap standard errors and confidence intervals of
  ordinary least squares coefficients. It resamples the observations
  with replacement, refits the model on each replicate, and summarizes
  the sampling distribution of the coefficients, providing an
  assumption-free empirical reference for the analytic
  heteroskedasticity-consistent standard errors from
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
  and
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md).
  Percentile, basic, and normal intervals are available, the resampling
  is reproducible through the `seed` argument, and the replicate fits
  can optionally run in parallel via
  [`purrr::in_parallel()`](https://purrr.tidyverse.org/reference/in_parallel.html)
  and `mirai` without changing the numeric result.
- Added [`coef()`](https://rdrr.io/r/stats/coef.html),
  [`vcov()`](https://rdrr.io/r/stats/vcov.html),
  [`confint()`](https://rdrr.io/r/stats/confint.html),
  [`print()`](https://rdrr.io/r/base/print.html), and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods for
  the `hcinfer_boot` objects returned by
  [`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md).
  [`vcov()`](https://rdrr.io/r/stats/vcov.html) returns the bootstrap
  covariance matrix of the coefficients,
  [`confint()`](https://rdrr.io/r/stats/confint.html) can recompute
  intervals at a different `level` or `type` directly from the stored
  replicates, and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws the
  bootstrap confidence intervals, coloring each coefficient by whether
  its interval excludes or includes zero.
- [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
  and
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  now accept independent HCbeta shape caps from 50 through 25000
  inclusive, with defaults of 10000. HC0, HC1, and HCbeta also remain
  defined for an exact leverage value of one, while HC2, HC3, HC4, HC4m,
  HC5, and HC5m retain the positive leverage-complement requirement.
- [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
  and
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  now enforce the fixed HCbeta shape floor of 0.01 after shrinkage and
  before the upper caps, including for nondefault leverage-complement
  truncation limits. The shape floor remains fixed when `lower` changes
  and is not a method argument.

## hcinfer 0.1.1

CRAN release: 2026-07-13

- Added the `PublicSchools2` dataset with 2024 per capita income, 2025
  public school expenditure per student, a Southern-region indicator,
  and complete variable and source documentation.
- Standardized the federal district name in `PublicSchools` from
  `Washington DC` to `District of Columbia`.

## hcinfer 0.1.0

CRAN release: 2026-06-10

## hcinfer 0.0.0.9000

- Added the initial development version with HC covariance estimators,
  normal Wald inference, S3 output, and the PublicSchools dataset.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) now supports
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  objects, producing leverage-versus-adjustment-factor graphics for
  inspecting the relationship between h_t and g_t.
- summary() now prints formal test results, confidence interval checks,
  and optional emoji markers to improve interpretation of robust
  inference output.
- summary() now keeps displayed test_result decisions consistent with
  numeric p-values when p-values are displayed as \<0.001.
- Added [`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md)
  as a formal extractor for coefficient-level Wald test results. The
  function mirrors the API of
  [`confint()`](https://rdrr.io/r/stats/confint.html): an optional
  `parm` argument selects coefficients by name or position, and an
  optional `alpha` argument recomputes the `reject` column without
  affecting the stored p-values or test statistics.
