# Extract coefficient test results

Extracts the normal Wald test results from an
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
object. If the requested significance level differs from the one used to
create the object, only the `reject` column is recomputed. The test
statistics and p-values are not affected by `alpha` and are never
recomputed.

## Usage

``` r
tests(object, ...)

# S3 method for class 'hcinfer'
tests(object, parm, alpha = object$alpha, ...)
```

## Arguments

- object:

  An object returned by
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md).

- ...:

  Unused. Passing named arguments raises an error.

- parm:

  Optional coefficient names or integer positions to select a subset of
  coefficients. When omitted, all coefficients are returned.

- alpha:

  Significance level used to compute the `reject` column. Must be
  strictly between 0 and 1. Defaults to the level stored in `object`.
  Changing `alpha` updates only the `reject` column; all other columns
  remain identical to the stored values.

## Value

A tibble with one row per selected coefficient and the following
columns:

- `term`:

  Coefficient name.

- `estimate`:

  OLS estimate \\\hat\beta_j\\.

- `null_value`:

  Null hypothesis value \\\beta_j^{(0)}\\.

- `std_error`:

  Robust standard error \\\sqrt{\[\widehat{\Psi}\_{HC}\]\_{jj}}\\.

- `z_value`:

  Normal Wald statistic \\z_j\\.

- `p_value`:

  Two-sided p-value \\2\\\Phi(-\|z_j\|)\\.

- `alpha`:

  Significance level used for the `reject` column.

- `reject`:

  Logical. `TRUE` when `p_value < alpha`.

## Details

For each coefficient, the stored test is

\$\$H_0: \beta_j = \beta_j^{(0)}\$\$

against a two-sided alternative. The test statistic is

\$\$z_j = \frac{\hat\beta_j - \beta_j^{(0)}}
{\sqrt{\[\widehat{\Psi}\_{HC}\]\_{jj}}},\$\$

and the p-value is \\2\\\Phi(-\|z_j\|)\\, where \\\Phi\\ is the standard
normal distribution function. The null value \\\beta_j^{(0)}\\ is the
one stored in the object, set when
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) was
called.

To test against a different null value, rerun
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) with
the desired `null` argument.

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

## See also

[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md),
[`confint.hcinfer()`](https://prdm0.github.io/hcinfer/reference/confint.hcinfer.md)

## Examples

``` r
schools <- PublicSchools |>
  dplyr::mutate(
    income_scaled = income / 10000,
    income_scaled_sq = income_scaled^2
  )
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
result <- hcinfer(fit)

tests(result)
#> # A tibble: 3 × 8
#>   term             estimate null_value std_error z_value p_value alpha reject
#>   <chr>               <dbl>      <dbl>     <dbl>   <dbl>   <dbl> <dbl> <lgl> 
#> 1 (Intercept)          833.          0      851.   0.979   0.328  0.05 FALSE 
#> 2 income_scaled      -1834.          0     2309.  -0.794   0.427  0.05 FALSE 
#> 3 income_scaled_sq    1587.          0     1547.   1.03    0.305  0.05 FALSE 
tests(result, parm = "income_scaled_sq")
#> # A tibble: 1 × 8
#>   term             estimate null_value std_error z_value p_value alpha reject
#>   <chr>               <dbl>      <dbl>     <dbl>   <dbl>   <dbl> <dbl> <lgl> 
#> 1 income_scaled_sq    1587.          0     1547.    1.03   0.305  0.05 FALSE 
tests(result, alpha = 0.10)
#> # A tibble: 3 × 8
#>   term             estimate null_value std_error z_value p_value alpha reject
#>   <chr>               <dbl>      <dbl>     <dbl>   <dbl>   <dbl> <dbl> <lgl> 
#> 1 (Intercept)          833.          0      851.   0.979   0.328   0.1 FALSE 
#> 2 income_scaled      -1834.          0     2309.  -0.794   0.427   0.1 FALSE 
#> 3 income_scaled_sq    1587.          0     1547.   1.03    0.305   0.1 FALSE 
```
