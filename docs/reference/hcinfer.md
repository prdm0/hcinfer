# Heteroskedasticity-consistent Wald inference

Computes normal Wald tests and confidence intervals for an ordinary
least squares model using a heteroskedasticity-consistent covariance
estimator.

## Usage

``` r
hcinfer(object, type = "hcbeta", alpha = 0.05, null = 0, ...)
```

## Arguments

- object:

  An ordinary least squares model fitted by
  [`stats::lm()`](https://rdrr.io/r/stats/lm.html).

- type:

  A character string specifying the HC estimator. The default is
  `"hcbeta"`.

- alpha:

  Significance level. The confidence level is `1 - alpha`.

- null:

  Null values for the coefficient tests. Use a scalar to test all
  coefficients against the same value, or a numeric vector with one
  value per coefficient.

- ...:

  Method-specific constants passed to
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md).
  Defaults are documented in
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  and can be inspected with
  [`hc_methods()`](https://prdm0.github.io/hcinfer/reference/hc_methods.md).

## Value

An object of class `hcinfer` containing the fitted HC covariance
estimator, coefficient tests, p-values, confidence intervals,
diagnostics, and method parameters.

## Details

For each coefficient, hcinfer tests

\$\$H_0: \beta_j = \beta_j^{(0)}\$\$

against a two-sided alternative using the statistic

\$\$z_j = \frac{\hat\beta_j - \beta_j^{(0)}}
{\sqrt{\[\widehat{\Psi}\_{HC}\]\_{jj}}}.\$\$

The reference distribution is the standard normal distribution.
Confidence intervals are Wald intervals obtained by direct inversion of
the test,

\$\$\hat\beta_j \pm z\_{1 - \alpha / 2}
\sqrt{\[\widehat{\Psi}\_{HC}\]\_{jj}}.\$\$

Bootstrap intervals and Student t quantiles are not used.

## References

White, H. (1980). A heteroskedasticity-consistent covariance matrix
estimator and a direct test for heteroskedasticity. *Econometrica*,
48(4), 817-838.

Cribari-Neto, F. (2004). Asymptotic inference under heteroskedasticity
of unknown form. *Computational Statistics and Data Analysis*, 45(2),
215-233.

## Examples

``` r
schools <- PublicSchools |>
  dplyr::mutate(
    income_scaled = income / 10000,
    income_scaled_sq = income_scaled^2
  )
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
result <- hcinfer(fit, type = "hcbeta")
result
#> 
#> ── 🔎 HCbeta robust inference ──────────────────────────────────────────────────
#> 📐 Model: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3
#> 🥪 Robust covariance: HCbeta
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
summary(result)
#> 
#> ── 🔎 HCbeta robust inference summary ──────────────────────────────────────────
#> 
#> ── 📐 Model ──
#> 
#> Formula: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3 | Residual df: 47
#> 
#> ── 🥪 Robust covariance ──
#> 
#> Estimator: HCbeta
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> Tests are two-sided normal Wald tests, one coefficient at a time.
#> Test results use alpha = 0.050.
#> 
#> ── 🎯 Leverage diagnostics ──
#> 
#> # A tibble: 6 × 2
#>   statistic value  
#>   <chr>     <chr>  
#> 1 minimum   0.02669
#> 2 q1        0.03106
#> 3 median    0.03912
#> 4 mean      0.06   
#> 5 q3        0.04962
#> 6 maximum   0.6508 
#> Maximum leverage: observation 2 (index 2), value 0.6508
#> Average leverage: 0.0600
#> Concentration: 10.85 x average leverage
#> 
#> ── ⚖️ Robust weights ──
#> 
#> # A tibble: 6 × 2
#>   statistic value
#>   <chr>     <chr>
#> 1 minimum   1.156
#> 2 q1        1.167
#> 3 median    1.187
#> 4 mean      1.276
#> 5 q3        1.212
#> 6 maximum   4.581
#> Maximum weight: observation 2 (index 2), value 4.5807
#> Median weight: 1.1869
#> Concentration: 3.86 x median weight
#> 
#> ── ⚙️ Method parameters ──
#> 
#> # A tibble: 12 × 3
#>    parameter value    role              
#>    <chr>     <chr>    <chr>             
#>  1 c1        7        method constant   
#>  2 c2        0.75     method constant   
#>  3 lower     0.01     method constant   
#>  4 upper     0.99     method constant   
#>  5 mu_hat    0.94     estimated quantity
#>  6 s2_w      0.008504 estimated quantity
#>  7 phi_hat   5.632    estimated quantity
#>  8 a_hat     5.294    estimated quantity
#>  9 b_hat     0.3379   estimated quantity
#> 10 zeta      0.5      estimated quantity
#> 11 a_tilde   3.147    estimated quantity
#> 12 b_tilde   0.669    estimated quantity
#> 
#> 
#> ── 🔎 Coefficient tests ──
#> 
#> # A tibble: 3 × 9
#>   term             estimate robust_se z       p_value alpha test_result        
#>   <chr>            <chr>    <chr>     <chr>   <chr>   <chr> <chr>              
#> 1 (Intercept)      832.9    850.7     0.9791  0.328   0.050 ✅ do not reject H0
#> 2 income_scaled    -1834    2309      -0.7945 0.427   0.050 ✅ do not reject H0
#> 3 income_scaled_sq 1587     1547      1.026   0.305   0.050 ✅ do not reject H0
#>   ci             ci_relation  
#>   <chr>          <chr>        
#> 1 [-834.3, 2500] includes null
#> 2 [-6359, 2691]  includes null
#> 3 [-1446, 4620]  includes null
#> 
#> 
#> ── 📏 Confidence intervals ──
#> 
#> # A tibble: 3 × 4
#>   term             null_value interval       interpretation
#>   <chr>            <chr>      <chr>          <chr>         
#> 1 (Intercept)      0          [-834.3, 2500] includes null 
#> 2 income_scaled    0          [-6359, 2691]  includes null 
#> 3 income_scaled_sq 0          [-1446, 4620]  includes null 
#> 💡 test_result is based on p_value < alpha. Do not reject H0 does not mean that
#> H0 is true.
confint(result)
#> # A tibble: 3 × 4
#>   term             conf_low conf_high level
#>   <chr>               <dbl>     <dbl> <dbl>
#> 1 (Intercept)         -834.     2500.  0.95
#> 2 income_scaled      -6359.     2691.  0.95
#> 3 income_scaled_sq   -1446.     4620.  0.95

hcinfer(fit, type = "hcbeta", c1 = 7, c2 = 0.75, lower = 0.01, upper = 0.99)
#> 
#> ── 🔎 HCbeta robust inference ──────────────────────────────────────────────────
#> 📐 Model: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3
#> 🥪 Robust covariance: HCbeta
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
hcinfer(fit, type = "hc5", k = 0.7)
#> 
#> ── 🔎 HC5 robust inference ─────────────────────────────────────────────────────
#> 📐 Model: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3
#> 🥪 Robust covariance: HC5
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
hcinfer(fit, type = "hc5m", k = 0.7, k1 = 1, k2 = 0, k3 = 1)
#> 
#> ── 🔎 HC5m robust inference ────────────────────────────────────────────────────
#> 📐 Model: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3
#> 🥪 Robust covariance: HC5m
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
```
