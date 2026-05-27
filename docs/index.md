# hcinfer

`hcinfer` computes heteroskedasticity-consistent covariance estimators
and normal Wald inference for ordinary least squares models. It
implements HC0, HC1, HC2, HC3, HC4, HC4m, HC5, HC5m, and HCbeta.

## Installation

``` r

# install.packages("hcinfer")

# Development version
remotes::install_github("prdm0/hcinfer")
```

## Basic Use

``` r

library(hcinfer)

schools <- PublicSchools
schools$income_scaled <- schools$income / 10000
schools$income_scaled_sq <- schools$income_scaled^2

fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)

result <- hcinfer(fit)
```

The default estimator is HCbeta. Use
[`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md) and
[`confint()`](https://rdrr.io/r/stats/confint.html) to extract the main
inferential quantities as tibbles.

``` r

tests(result)
#> # A tibble: 3 × 8
#>   term             estimate null_value std_error z_value p_value alpha reject
#>   <chr>               <dbl>      <dbl>     <dbl>   <dbl>   <dbl> <dbl> <lgl> 
#> 1 (Intercept)          833.          0      851.   0.979   0.328  0.05 FALSE 
#> 2 income_scaled      -1834.          0     2309.  -0.794   0.427  0.05 FALSE 
#> 3 income_scaled_sq    1587.          0     1547.   1.03    0.305  0.05 FALSE
confint(result)
#> # A tibble: 3 × 4
#>   term             conf_low conf_high level
#>   <chr>               <dbl>     <dbl> <dbl>
#> 1 (Intercept)         -834.     2500.  0.95
#> 2 income_scaled      -6359.     2691.  0.95
#> 3 income_scaled_sq   -1446.     4620.  0.95
```

## Confidence Intervals

The [`plot()`](https://rdrr.io/r/graphics/plot.default.html) method
displays the robust confidence intervals and marks the null value used
in the tests.

``` r

plot(result)
```

![Robust confidence intervals for the public-schools regression
coefficients.](reference/figures/README-unnamed-chunk-5-1.png)

## Diagnostics

Use [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
when you only need the robust covariance matrix and its diagnostics. The
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) method for this
object shows leverage values and HC adjustment factors.

``` r

cov_hcbeta <- vcov_hc(fit)
plot(cov_hcbeta)
```

![HCbeta adjustment factors plotted against leverage values for the
public-schools
regression.](reference/figures/README-unnamed-chunk-6-1.png)

## Main Functions

``` r

hc_methods()
coef(result)
vcov(result)
```

The most common workflow is:

``` r

fit <- lm(y ~ x1 + x2, data = data)
result <- hcinfer(fit, type = "hcbeta")

summary(result)
tests(result)
confint(result)
plot(result)
```

## Learn More

Start with
[`vignette("introduction", package = "hcinfer")`](https://prdm0.github.io/hcinfer/articles/introduction.md)
for a compact overview of the package API.

## References

- White, H. (1980). A heteroskedasticity-consistent covariance matrix
  estimator and a direct test for heteroskedasticity. *Econometrica*,
  48(4), 817-838.
- Cribari-Neto, F. (2004). Asymptotic inference under heteroskedasticity
  of unknown form. *Computational Statistics and Data Analysis*, 45(2),
  215-233.
- Marinho, P. R. D., Cribari-Neto, F., and Cunha, M. O. (2025). HCbeta:
  A beta-distribution-based heteroskedasticity-consistent covariance
  estimator. Working paper.
