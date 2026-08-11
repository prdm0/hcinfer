# Feasible GLS under multiplicative heteroskedasticity

Fits a linear mean model by feasible generalized least squares when the
conditional variance is modelled as an exponential function of observed
dispersion regressors. Both Harvey's two-step estimator and full
Gaussian maximum likelihood are available. The method complements HC
covariance inference by making an explicit, testable variance-model
assumption.

## Usage

``` r
gls_mult(
  object,
  variance = NULL,
  method = c("ml", "two_step"),
  alpha = 0.05,
  null = 0,
  control = list(),
  ...
)
```

## Arguments

- object:

  An unweighted, univariate ordinary least squares model fitted by
  [`stats::lm()`](https://rdrr.io/r/stats/lm.html) without an offset.

- variance:

  `NULL` to use the mean model matrix for the dispersion model, or a
  one-sided formula specifying the dispersion regressors. The formula
  must generate exactly one all-ones intercept column.

- method:

  Fitting method. `"ml"` locally optimizes the Gaussian profile
  likelihood and is the default. `"two_step"` applies Harvey's corrected
  auxiliary regression once.

- alpha:

  Significance level for normal Wald tests. The confidence level is
  `1 - alpha`.

- null:

  Null values for mean-coefficient tests. Use one value for all
  coefficients or one finite value per mean coefficient.

- control:

  A list passed to
  [`stats::optim()`](https://rdrr.io/r/stats/optim.html) for maximum
  likelihood fitting. It is accepted but not used by the two-step
  estimator. For maximum likelihood, `control$maxit` must be a positive
  integer and a supplied `control$fnscale` must be one finite positive
  number. Negative scaling is invalid because `gls_mult()` already
  minimizes the negative profile log-likelihood. The accepted locally
  optimized stationary fit must satisfy the scale-invariant score check
  described in Details.

- ...:

  Unused. Passing arguments raises an error.

## Value

An object of class `gls_mult` and `hcinfer_object`. Important components
are:

- `coefficients`, `vcov`:

  Mean coefficients and their model-based covariance matrix.

- `variance_coefficients`, `variance_vcov`:

  Dispersion coefficients and their method-specific covariance matrix.

- `variance_coefficients_raw`, `variance_coefficients_corrected`:

  Raw and intercept-corrected two-step auxiliary estimates. For maximum
  likelihood, the corrected estimate is the optimizer starting value.

- `fitted`, `residuals`:

  GLS fitted values and residuals.

- `fitted_variances`, `weights`, `eta`:

  Fitted conditional variances in squared response units,
  inverse-variance weights, and fitted log-variances \\\eta_t =
  z_t^\top\gamma\\.

- `table`, `variance_table`:

  Normal Wald summaries for the mean and dispersion parameter blocks.

- `loglik`, `convergence`:

  The log-likelihood at the accepted local solution and optimizer
  diagnostics, present only for maximum likelihood fits.

- `df`, `nobs`:

  Likelihood parameter count \\p + q\\ and sample size.

## Details

### Model

Let the mean model be

\$\$y = X\beta + e,\$\$

where \\X\\ is an \\n \times p\\ full-rank matrix with \\p \< n\\. The
multiplicative variance model is

\$\$e_t = \sigma_t\varepsilon_t,\qquad \varepsilon_t
\stackrel{\mathrm{iid}}{\sim} N(0,1),\qquad \sigma_t^2 =
\exp(\eta_t),\qquad \eta_t = z_t^\top\gamma,\$\$

where \\Z\\ is an \\n \times q\\ full-rank matrix with \\q \< n\\,
\\\gamma\\ is the dispersion coefficient vector, and \\\eta_t\\ is the
fitted log-variance. Thus \\\exp(\eta_t)\\ has squared response units,
whereas \\\exp(\eta_t/2)\\ is the conditional standard deviation in
response units. The mean and dispersion coefficients remain distinct
parameter blocks even when `variance = NULL` makes \\Z = X\\.

The dispersion model must contain exactly one all-ones intercept column.
This requirement makes the two-step intercept correction unambiguous. A
custom one-sided `variance` formula may use variables outside the mean
formula. Such variables are recovered from the original `lm` data and
aligned by the exact rows used to estimate the mean model.

### Two-step estimator

With `method = "two_step"`, the function first regresses \\\log(\hat
e_t^2)\\ on \\Z\\, where \\\hat e_t\\ are the OLS residuals. If
\\\widetilde\gamma\\ denotes this raw auxiliary estimate, the intercept
is corrected as

\$\$\widehat\gamma = \widetilde\gamma + c\\\iota,\qquad c =
-\operatorname{digamma}(1/2) - \log(2),\$\$

where \\\iota\\ is the unit vector that selects the dispersion
intercept. The constant is approximately 1.270362845 because
\\E\\\log(\varepsilon_t^2)\\ = \operatorname{digamma}(1/2) + \log(2) =
-c\\ for a standard normal error. The resulting weights are \\\widehat
w_t = \exp(-z_t^\top\widehat\gamma)\\, collected in the diagonal weight
matrix \\\widehat W =
\operatorname{diag}\\\exp(-\eta_1),\ldots,\exp(-\eta_n)\\\\, and the
feasible GLS estimate is obtained from the weighted normal equations.
Multiplying every inverse-variance weight by the same positive constant
leaves the GLS coefficient estimate unchanged. The raw and corrected
auxiliary estimates are stored in `variance_coefficients_raw` and
`variance_coefficients_corrected`.

The asymptotic normal-theory covariance approximation for the auxiliary
\\\log(\chi_1^2)\\ regression is

\$\$\frac{\pi^2}{2}(Z^\top Z)^{-1},\$\$

because \\\pi^2/2 = \operatorname{trigamma}(1/2) =
\operatorname{Var}\\\log(\varepsilon_t^2)\\\\ under normality. The
intercept correction centers this auxiliary error, but it does not
remove finite-sample effects from using OLS residuals in place of the
errors.

The reported mean covariance is the model-based plug-in
\\(X^\top\widehat W X)^{-1}\\, which treats the estimated weights as
known and does not propagate the sampling variability of
\\\widehat\gamma\\, the same convention adopted by Cribari-Neto and
Pereira (2019). The Gaussian log-likelihood at a two-step estimate is
not maximized, so two-step objects do not support
[`logLik()`](https://rdrr.io/r/stats/logLik.html),
[`AIC()`](https://rdrr.io/r/stats/AIC.html), or
[`BIC()`](https://rdrr.io/r/stats/AIC.html).

### Maximum likelihood

With the default `method = "ml"`, the corrected two-step estimate
initializes BFGS optimization of the Gaussian log-likelihood. The joint
log-likelihood of the mean and dispersion blocks is

\$\$\ell(\beta,\gamma) = -\frac{n}{2}\log(2\pi) -\frac{1}{2}\sum_t
z_t^\top\gamma -\frac{1}{2}\sum_t
\exp(-z_t^\top\gamma)(y_t-x_t^\top\beta)^2.\$\$

For every trial value of \\\gamma\\, \\\beta\\ is profiled out by
weighted least squares, yielding \\\widehat\beta(\gamma)\\, and BFGS
optimizes the resulting profile log-likelihood \\\ell_p(\gamma) =
\ell(\widehat\beta(\gamma),\gamma)\\ with its analytic gradient through
[`stats::optim()`](https://rdrr.io/r/stats/optim.html). The asymptotic
expected information has zero cross-information between \\\beta\\ and
\\\gamma\\, with blocks

\$\$\mathcal I\_{\beta\beta}=X^\top W X,\qquad \mathcal
I\_{\gamma\gamma}=\frac{1}{2}Z^\top Z.\$\$

Its inverse gives the reported asymptotic dispersion covariance
\\2(Z^\top Z)^{-1}\\ and the model-based mean plug-in covariance
\\(X^\top\widehat W X)^{-1}\\, which treats the estimated weights as
known.

For an accepted maximum likelihood fit,
[`logLik()`](https://rdrr.io/r/stats/logLik.html) returns the Gaussian
log-likelihood evaluated at the accepted local solution, so the default
[`AIC()`](https://rdrr.io/r/stats/AIC.html) and
[`BIC()`](https://rdrr.io/r/stats/AIC.html) methods work without
package-specific information-criterion methods. Their likelihood degrees
of freedom equal \\p + q\\, and comparisons require competing fits to
have reached comparable likelihood solutions. With an intercept-only
dispersion model, `variance = ~ 1`, the fit reduces to the homoskedastic
Gaussian linear model and reproduces the `lm` coefficients,
log-likelihood, AIC, and BIC.

### Inference and numerical safeguards

Mean and dispersion tables use standard-normal Wald reference values.
The reported mean covariance is model-based and relies on correct
specification of the multiplicative variance model. It is not an HC
sandwich covariance, and no robust GLS covariance is computed.

For `method = "ml"`, a fit is accepted as a locally optimized stationary
solution only when
[`stats::optim()`](https://rdrr.io/r/stats/optim.html) returns
convergence code zero and the scale-invariant profile-score norm
\\\sqrt{s(\widehat\gamma)^\top (Z^\top Z)^{-1} s(\widehat\gamma)}\\,
where \\s(\gamma)\\ is the profile score, falls below a fixed tolerance.
This guard rejects a false convergence report at a nonstationary point,
such as one caused by an excessively loose `reltol`, but it does not
prove that the accepted solution is a global maximum.

Computation uses row-scaled matrices, Cholesky solves, and centered
log-variances; it never constructs an \\n \times n\\ diagonal weight
matrix or explicitly inverts a cross-product. The function fails
explicitly for rank-deficient designs, missing or nonfinite aligned
inputs, zero or nonfinite OLS residuals, an absent dispersion intercept,
unrecoverable dispersion rows, nonrepresentable fitted variances or
weights, a singular weighted design, or maximum likelihood
non-convergence. Weighted, offset, and multivariate `lm` fits are not
silently reinterpreted and are rejected.

## References

Harvey, A. C. (1976). Estimating regression models with multiplicative
heteroscedasticity. *Econometrica*, 44(3), 461-465.
[doi:10.2307/1913974](https://doi.org/10.2307/1913974)

Cribari-Neto, F. and Pereira, I. F. S. (2019). Testing inference in
heteroskedastic linear regressions: a comparison of two alternative
approaches. *Journal of Statistical Computation and Simulation*, 89(8),
1437-1465.
[doi:10.1080/00949655.2019.1586902](https://doi.org/10.1080/00949655.2019.1586902)

## See also

[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) for
OLS inference with HC covariance estimators and
[`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md) for
the implemented HC covariance matrices.
[`vignette("hcinfer-gls", package = "hcinfer")`](https://prdm0.github.io/hcinfer/articles/hcinfer-gls.md)
is a didactic guide to feasible GLS under multiplicative
heteroskedasticity.

## Examples

``` r
schools <- PublicSchools |>
  dplyr::mutate(income_scaled = income / 10000)
fit <- lm(expenditure ~ income_scaled, data = schools)

result <- gls_mult(fit)
result
#> 
#> ── 🔎 Multiplicative heteroskedasticity FGLS summary ───────────────────────────
#> 
#> ── 📐 Mean model ──
#> 
#> Formula: `expenditure ~ income_scaled`
#> Observations: 50 | Mean parameters: 2 | Dispersion parameters: 2
#> 
#> ── ⚙️ Dispersion model ──
#> 
#> Specification: `Z = X (the mean model matrix)`
#> Fitting method: Maximum likelihood
#> Variance function: exp(z' gamma)
#> 
#> ── 🥪 Model-based inference ──
#> 
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> Coefficient covariance: model-based, conditional on a correctly specified
#> variance model.
#> 
#> ── 🔎 Mean-coefficient Wald tests ──
#> 
#> # A tibble: 2 × 7
#>   term          estimate model_se z     p_value test_result        
#>   <chr>         <chr>    <chr>    <chr> <chr>   <chr>              
#> 1 (Intercept)   -58.12   57.53    -1.01 0.312   ✅ do not reject H0
#> 2 income_scaled 563.3    80.2     7.023 <0.001  ❌ reject H0       
#>   confidence_interval
#>   <chr>              
#> 1 [-170.9, 54.64]    
#> 2 [406.1, 720.5]     
#> 
#> ── ⚙️ Dispersion coefficients ──
#> 
#> # A tibble: 2 × 5
#>   term          estimate std_error z     p_value
#>   <chr>         <chr>    <chr>     <chr> <chr>  
#> 1 (Intercept)   3.83     1.477     2.594 0.009  
#> 2 income_scaled 5.386    1.923     2.801 0.005  
#> 
#> ── ⚖️ Fitted conditional variance and standard deviation ──
#> 
#> Variance is expressed in squared response units; standard deviation is
#> expressed in response units.
#> # A tibble: 6 × 3
#>   statistic variance  standard_deviation
#>   <chr>     <chr>     <chr>             
#> 1 minimum   1012      31.81             
#> 2 q1        1660      40.75             
#> 3 median    2726      52.21             
#> 4 mean      3315      54.92             
#> 5 q3        4019      63.39             
#> 6 maximum   1.591e+04 126.1             
#> 
#> ── ⚙️ Maximum likelihood ──
#> 
#> logLik: -269.2 | AIC: 546.3 | BIC: 554
#> Convergence code: 0 | function = 18 | gradient = 11
#> Score norm (scale-invariant): 4.839e-05 | Gradient norm: 0.0002001
summary(result)
#> 
#> ── 🔎 Multiplicative heteroskedasticity FGLS summary ───────────────────────────
#> 
#> ── 📐 Mean model ──
#> 
#> Formula: `expenditure ~ income_scaled`
#> Observations: 50 | Mean parameters: 2 | Dispersion parameters: 2
#> 
#> ── ⚙️ Dispersion model ──
#> 
#> Specification: `Z = X (the mean model matrix)`
#> Fitting method: Maximum likelihood
#> Variance function: exp(z' gamma)
#> 
#> ── 🥪 Model-based inference ──
#> 
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> Coefficient covariance: model-based, conditional on a correctly specified
#> variance model.
#> 
#> ── 🔎 Mean-coefficient Wald tests ──
#> 
#> # A tibble: 2 × 7
#>   term          estimate model_se z     p_value test_result        
#>   <chr>         <chr>    <chr>    <chr> <chr>   <chr>              
#> 1 (Intercept)   -58.12   57.53    -1.01 0.312   ✅ do not reject H0
#> 2 income_scaled 563.3    80.2     7.023 <0.001  ❌ reject H0       
#>   confidence_interval
#>   <chr>              
#> 1 [-170.9, 54.64]    
#> 2 [406.1, 720.5]     
#> 
#> ── ⚙️ Dispersion coefficients ──
#> 
#> # A tibble: 2 × 5
#>   term          estimate std_error z     p_value
#>   <chr>         <chr>    <chr>     <chr> <chr>  
#> 1 (Intercept)   3.83     1.477     2.594 0.009  
#> 2 income_scaled 5.386    1.923     2.801 0.005  
#> 
#> ── ⚖️ Fitted conditional variance and standard deviation ──
#> 
#> Variance is expressed in squared response units; standard deviation is
#> expressed in response units.
#> # A tibble: 6 × 3
#>   statistic variance  standard_deviation
#>   <chr>     <chr>     <chr>             
#> 1 minimum   1012      31.81             
#> 2 q1        1660      40.75             
#> 3 median    2726      52.21             
#> 4 mean      3315      54.92             
#> 5 q3        4019      63.39             
#> 6 maximum   1.591e+04 126.1             
#> 
#> ── ⚙️ Maximum likelihood ──
#> 
#> logLik: -269.2 | AIC: 546.3 | BIC: 554
#> Convergence code: 0 | function = 18 | gradient = 11
#> Score norm (scale-invariant): 4.839e-05 | Gradient norm: 0.0002001
coef(result)
#>   (Intercept) income_scaled 
#>     -58.11517     563.27991 
coef(result, model = "dispersion")
#>   (Intercept) income_scaled 
#>      3.830193      5.386184 
vcov(result)
#>               (Intercept) income_scaled
#> (Intercept)      3309.724     -4580.333
#> income_scaled   -4580.333      6432.553
tests(result)
#> # A tibble: 2 × 8
#>   term          estimate null_value std_error z_value  p_value alpha reject
#>   <chr>            <dbl>      <dbl>     <dbl>   <dbl>    <dbl> <dbl> <lgl> 
#> 1 (Intercept)      -58.1          0      57.5   -1.01 3.12e- 1  0.05 FALSE 
#> 2 income_scaled    563.           0      80.2    7.02 2.17e-12  0.05 TRUE  
confint(result)
#> # A tibble: 2 × 4
#>   term          conf_low conf_high level
#>   <chr>            <dbl>     <dbl> <dbl>
#> 1 (Intercept)      -171.      54.6  0.95
#> 2 income_scaled     406.     720.   0.95
logLik(result)
#> 'log Lik.' -269.1543 (df=4)
AIC(result)
#> [1] 546.3087
BIC(result)
#> [1] 553.9568

two_step <- gls_mult(fit, method = "two_step")
coef(two_step)
#>   (Intercept) income_scaled 
#>     -31.72321     525.59326 
```
