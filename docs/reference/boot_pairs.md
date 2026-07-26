# Pairs bootstrap standard errors and confidence intervals

Computes pairs (case) bootstrap standard errors and confidence intervals
for the coefficients of an ordinary least squares model fitted with
[`stats::lm()`](https://rdrr.io/r/stats/lm.html). The pairs bootstrap
resamples the observations \\(y_t, x_t)\\ with replacement, refits OLS
on each resample, and summarizes the resulting sampling distribution of
\\\hat\beta\\. It makes no assumption about the form of the error
variance, so it is a useful empirical reference for the analytic
heteroskedasticity-consistent standard errors produced by
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) and
[`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md).

## Usage

``` r
boot_pairs(
  object,
  R = 1000L,
  level = 0.95,
  ci_type = c("percentile", "basic", "normal"),
  parallel = FALSE,
  cores = NULL,
  seed = NULL
)

# S3 method for class 'hcinfer_boot'
print(x, ...)
```

## Arguments

- object:

  An ordinary least squares model fitted by
  [`stats::lm()`](https://rdrr.io/r/stats/lm.html). Weighted fits are
  not supported.

- R:

  Number of bootstrap replicates. A positive integer; defaults to
  `1000`.

- level:

  Confidence level for the intervals, strictly between 0 and 1. Defaults
  to `0.95`.

- ci_type:

  Interval type: `"percentile"` (default), `"basic"`, or `"normal"`. See
  Details.

- parallel:

  Logical; if `TRUE`, run the replicate fits in parallel with
  [`purrr::in_parallel()`](https://purrr.tidyverse.org/reference/in_parallel.html)
  and mirai. Defaults to `FALSE`.

- cores:

  Number of parallel worker processes to use when `parallel = TRUE`. A
  positive integer, or `NULL` (the default) to use one fewer than the
  number of detected cores. Ignored when `parallel = FALSE`.

- seed:

  Optional single number used to seed the resampling for
  reproducibility. When supplied, the result is deterministic and
  independent of `parallel` and `cores`. Defaults to `NULL`.

- x:

  An object returned by `boot_pairs()`.

- ...:

  Unused.

## Value

An object of class `hcinfer_boot`: a list with the original OLS
`coefficients`, bootstrap `std_error`, `bias`, interval endpoints
`conf_low` and `conf_high`, the settings (`level`, `ci_type`, `R`,
`R_effective`, `n_failed`, `parallel`, `cores`, `seed`), the full
`replicates` matrix (`R` rows by `p` columns), and a tidy `table` tibble
with columns `term`, `estimate`, `bias`, `std_error`, `conf_low`, and
`conf_high`. Use [`coef()`](https://rdrr.io/r/stats/coef.html),
[`vcov()`](https://rdrr.io/r/stats/vcov.html), and
[`confint()`](https://rdrr.io/r/stats/confint.html) to extract
components.

## Details

For each of `R` bootstrap replicates, a sample of `n` row indices is
drawn with replacement from `1, ..., n`, and OLS is refitted on the
resampled rows \\(y\_{i}, x\_{i})\\. Writing \\\hat\beta^{\*}\_{(r)}\\
for the estimate on replicate `r`, the bootstrap standard error of
coefficient `j` is the sample standard deviation of
\\\hat\beta^{\*}\_{1,j}, \ldots, \hat\beta^{\*}\_{R,j}\\, and the bias
estimate is the mean of the replicates minus the original OLS estimate.

Three interval types are available through `ci_type`. Let \\q\_\alpha\\
denote the empirical \\\alpha\\ quantile of the bootstrap replicates for
a coefficient, \\\hat\beta_j\\ the original estimate, \\s^{\*}\_j\\ the
bootstrap standard error, and \\\alpha = 1 - \texttt{level}\\. The
`"percentile"` interval is \\\[q\_{\alpha/2}, q\_{1-\alpha/2}\]\\. The
`"basic"` (reverse percentile) interval is \\\[2\hat\beta_j -
q\_{1-\alpha/2}, \\ 2\hat\beta_j - q\_{\alpha/2}\]\\. The `"normal"`
interval is \\\hat\beta_j \pm z\_{1-\alpha/2}\\ s^{\*}\_j\\, with \\z\\
the standard normal quantile.

**Reproducibility.** When `seed` is supplied, all resampling indices are
drawn once, sequentially, in the main process under that seed, and the
per-replicate fit is deterministic. The results are therefore identical
whether the run is sequential or parallel and regardless of the number
of cores. The caller's random number generator state is saved and
restored, so calling `boot_pairs()` does not disturb a surrounding
random stream. When `seed` is `NULL`, the current RNG state is used and
results are not reproducible.

**Parallelism.** With `parallel = TRUE`, the deterministic per-replicate
fits are distributed with
[`purrr::in_parallel()`](https://purrr.tidyverse.org/reference/in_parallel.html),
which uses the mirai package as its backend. `boot_pairs()` starts
`cores` daemons for the duration of the call and shuts them down on
exit; do not call it while relying on externally configured `mirai`
daemons. Parallelism only speeds up the computation: it never changes
the numeric result. It is worthwhile mainly for large `R` or large `n`;
for small problems the setup overhead can dominate.

**Rank-deficient resamples.** A resample can be rank deficient (for
example when a resample omits the observations that identify a
coefficient). Such replicates are dropped, a warning reports how many
were dropped, and the summaries use the remaining replicates. The call
errors if fewer than two valid replicates remain.

## References

Davison, A. C. and Hinkley, D. V. (1997). *Bootstrap Methods and their
Application*. Cambridge University Press.
[doi:10.1017/CBO9780511802843](https://doi.org/10.1017/CBO9780511802843)

Efron, B. and Tibshirani, R. J. (1993). *An Introduction to the
Bootstrap*. Chapman and Hall.
[doi:10.1201/9780429246593](https://doi.org/10.1201/9780429246593)

## See also

[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md),
[`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)

## Examples

``` r
schools <- PublicSchools |>
  dplyr::mutate(
    income_scaled = income / 10000,
    income_scaled_sq = income_scaled^2
  )
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)

# 1. Basic reproducible pairs bootstrap with percentile intervals.
boot <- boot_pairs(fit, R = 1000, seed = 123)
boot
#> 
#> ── 🔎 Pairs bootstrap inference ────────────────────────────────────────────────
#> 📐 Model: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3
#> Replicates: 1000 of 1000 valid | Interval: percentile at 95.0%
#> Execution: sequential | Seed: 123
#> # A tibble: 3 × 5
#>   term             estimate bias   boot_se ci            
#>   <chr>            <chr>    <chr>  <chr>   <chr>         
#> 1 (Intercept)      832.9    -221.1 626.6   [-631.1, 1498]
#> 2 income_scaled    -1834    601.2  1697    [-3545, 2116] 
#> 3 income_scaled_sq 1587     -401.8 1135    [-1027, 2634] 
confint(boot)
#> # A tibble: 3 × 4
#>   term             conf_low conf_high level
#>   <chr>               <dbl>     <dbl> <dbl>
#> 1 (Intercept)         -631.     1498.  0.95
#> 2 income_scaled      -3545.     2116.  0.95
#> 3 income_scaled_sq   -1027.     2634.  0.95

# 2. Reproducibility and use as an empirical reference for HC standard errors.
boot_a <- boot_pairs(fit, R = 1000, seed = 2024)
boot_b <- boot_pairs(fit, R = 1000, seed = 2024)
identical(boot_a$replicates, boot_b$replicates)
#> [1] TRUE
data.frame(
  term = boot_a$table$term,
  bootstrap = boot_a$table$std_error,
  hcbeta = sqrt(diag(vcov(hcinfer(fit, type = "hcbeta"))))
)
#>                              term bootstrap    hcbeta
#> (Intercept)           (Intercept)  631.2285  850.6572
#> income_scaled       income_scaled 1706.9685 2308.6541
#> income_scaled_sq income_scaled_sq 1140.5313 1547.4583

# 3. Parallel run with more replicates and basic (reverse-percentile)
#    intervals. Requires the mirai package; the numeric result matches a
#    sequential run with the same seed.
# \donttest{
if (requireNamespace("mirai", quietly = TRUE) &&
    requireNamespace("carrier", quietly = TRUE)) {
  boot_par <- boot_pairs(
    fit,
    R = 4000,
    ci_type = "basic",
    parallel = TRUE,
    cores = 2,
    seed = 42
  )
  summary_par <- boot_par$table
  print(summary_par)
}
#> # A tibble: 3 × 6
#>   term             estimate  bias std_error conf_low conf_high
#>   <chr>               <dbl> <dbl>     <dbl>    <dbl>     <dbl>
#> 1 (Intercept)          833. -213.      625.     182.     2294.
#> 2 income_scaled      -1834.  581.     1688.   -5771.     -160.
#> 3 income_scaled_sq    1587. -389.     1127.     514.     4212.
# }
```
