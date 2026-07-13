# Changelog

## hcinfer 0.1.1

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
