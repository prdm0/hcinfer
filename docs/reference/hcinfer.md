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
  For HCbeta, `a_max` and `b_max` default to 10000, may be set
  independently, and must each be finite and lie in `[50, 25000]`. See
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
  for all other method-specific defaults and parameter domains.

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
48(4), 817-838. [doi:10.2307/1912934](https://doi.org/10.2307/1912934)

Hinkley, D. V. (1977). Jackknifing in unbalanced situations.
*Technometrics*, 19(3), 285-292.
[doi:10.1080/00401706.1977.10489550](https://doi.org/10.1080/00401706.1977.10489550)

MacKinnon, J. G. and White, H. (1985). Some
heteroskedasticity-consistent covariance matrix estimators with improved
finite sample properties. *Journal of Econometrics*, 29(3), 305-325.
[doi:10.1016/0304-4076(85)90158-7](https://doi.org/10.1016/0304-4076%2885%2990158-7)

Davidson, R. and MacKinnon, J. G. (1993). *Estimation and Inference in
Econometrics*. Oxford University Press.

Cribari-Neto, F. (2004). Asymptotic inference under heteroskedasticity
of unknown form. *Computational Statistics and Data Analysis*, 45(2),
215-233.
[doi:10.1016/S0167-9473(02)00366-3](https://doi.org/10.1016/S0167-9473%2802%2900366-3)

Cribari-Neto, F. and da Silva, W. B. (2011). A new heteroskedasticity
consistent covariance matrix estimator for the linear regression model.
*AStA Advances in Statistical Analysis*, 95(2), 129-146.
[doi:10.1007/s10182-010-0141-2](https://doi.org/10.1007/s10182-010-0141-2)

Cribari-Neto, F., Souza, T. C., and Vasconcellos, K. L. P. (2007).
Inference under heteroskedasticity and leveraged data. *Communications
in Statistics - Theory and Methods*, 36(10), 1877-1888.
[doi:10.1080/03610920601126589](https://doi.org/10.1080/03610920601126589)

Li, S., Zhang, N., Zhang, X., and Wang, G. (2016). A new
heteroskedasticity-consistent covariance matrix estimator and inference
under heteroskedasticity. *Journal of Statistical Computation and
Simulation*, 87(1), 198-210.
[doi:10.1080/00949655.2016.1198906](https://doi.org/10.1080/00949655.2016.1198906)

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
#> # A tibble: 14 × 3
#>    parameter value    role              
#>    <chr>     <chr>    <chr>             
#>  1 c1        7        method constant   
#>  2 c2        0.75     method constant   
#>  3 lower     0.01     method constant   
#>  4 upper     0.99     method constant   
#>  5 a_max     1e+04    method constant   
#>  6 b_max     1e+04    method constant   
#>  7 mu_hat    0.94     estimated quantity
#>  8 s2_w      0.008504 estimated quantity
#>  9 phi_hat   5.632    estimated quantity
#> 10 a_hat     5.294    estimated quantity
#> 11 b_hat     0.3379   estimated quantity
#> 12 zeta      0.5      estimated quantity
#> 13 a_tilde   3.147    estimated quantity
#> 14 b_tilde   0.669    estimated quantity
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

# Sensitivity analysis with nondefault HCbeta caps
hcinfer(fit, type = "hcbeta", a_max = 20000, b_max = 20000)
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
