# Pairs bootstrap inference with hcinfer

The pairs (case) bootstrap is a resampling method for the coefficients
of an ordinary least squares model. It resamples whole observations,
refits the model many times, and summarizes the resulting spread of the
estimates. Because it makes no assumption about the form of the error
variance, it provides an empirical cross-check on the analytic
heteroskedasticity-consistent (HC) standard errors that `hcinfer`
computes, and this vignette shows how to run it, read its output, and
compare it with the HC estimators.

## The method

For each replicate the bootstrap draws `n` rows with replacement from
the original data and refits OLS on that resample. Writing the estimate
on replicate `r` as the vector of refitted coefficients, the bootstrap
standard error of a coefficient is the standard deviation of its
replicate values.
[`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md)
offers three interval types: `"percentile"` uses the empirical quantiles
of the replicates, `"basic"` (reverse percentile) reflects those
quantiles about the original estimate, and `"normal"` uses the estimate
plus or minus a normal quantile times the bootstrap standard error.

## Data and model

The model below uses the `PublicSchools2` data, which has complete
observations for all 51 states, and includes a `south` indicator that
the original `PublicSchools` data lack.

``` r

library(hcinfer)

schools <- PublicSchools2
schools$income_scaled <- schools$income / 10000

fit <- lm(expenditure ~ income_scaled + south, data = schools)
fit
#> 
#> Call:
#> lm(formula = expenditure ~ income_scaled + south, data = schools)
#> 
#> Coefficients:
#>   (Intercept)  income_scaled          south  
#>         -3111           4763          -1112
```

## Running the bootstrap

A single call fits the resamples and stores the estimates, standard
errors, bias, and intervals. Supplying `seed` makes the run
reproducible.

``` r

boot <- boot_pairs(fit, B = 2000, seed = 123)
boot
#> 
#> ── Pairs bootstrap inference ───────────────────────────────────────────────────
#> Model: `expenditure ~ income_scaled + south`
#> Observations: 51 | Parameters: 3
#> Replicates: 2000 of 2000 valid | Interval: percentile at 95.0%
#> Execution: sequential | Seed: 123
#> # A tibble: 3 × 5
#>   term          estimate bias   boot_se ci                 
#>   <chr>         <chr>    <chr>  <chr>   <chr>              
#> 1 (Intercept)   -3111    -461.9 2801    [-1.041e+04, 979.8]
#> 2 income_scaled 4763     103    627.5   [3865, 6415]       
#> 3 south         -1112    52.32  902.2   [-2851, 764.1]
```

## Extractors

The [`coef()`](https://rdrr.io/r/stats/coef.html),
[`vcov()`](https://rdrr.io/r/stats/vcov.html), and
[`confint()`](https://rdrr.io/r/stats/confint.html) methods pull out the
pieces you need. [`coef()`](https://rdrr.io/r/stats/coef.html) returns
the original OLS estimates,
[`vcov()`](https://rdrr.io/r/stats/vcov.html) the bootstrap covariance
matrix, and [`confint()`](https://rdrr.io/r/stats/confint.html) the
interval table. Note the argument-name asymmetry:
[`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md)
sets the default interval type via `ci_type`, while
[`confint()`](https://rdrr.io/r/stats/confint.html) overrides it via
`type`.

``` r

coef(boot)
#>   (Intercept) income_scaled         south 
#>     -3110.908      4762.569     -1112.153
vcov(boot)
#>               (Intercept) income_scaled      south
#> (Intercept)       7845298    -1711565.8 -1140786.7
#> income_scaled    -1711566      393699.5   168161.0
#> south            -1140787      168161.0   813921.3
confint(boot)
#> # A tibble: 3 × 4
#>   term          conf_low conf_high level
#>   <chr>            <dbl>     <dbl> <dbl>
#> 1 (Intercept)    -10413.      980.  0.95
#> 2 income_scaled    3865.     6415.  0.95
#> 3 south           -2851.      764.  0.95
```

[`confint()`](https://rdrr.io/r/stats/confint.html) can recompute
intervals at a different level or type directly from the stored
replicates, without rerunning the bootstrap.

``` r

confint(boot, level = 0.99, type = "basic")
#> # A tibble: 3 × 4
#>   term          conf_low conf_high level
#>   <chr>            <dbl>     <dbl> <dbl>
#> 1 (Intercept)     -9108.     8298.  0.99
#> 2 income_scaled    2206.     6102.  0.99
#> 3 south           -3858.      984.  0.99
confint(boot, parm = "south", level = 0.90)
#> # A tibble: 1 × 4
#>   term  conf_low conf_high level
#>   <chr>    <dbl>     <dbl> <dbl>
#> 1 south   -2525.      446.   0.9
```

## Visualizing the intervals

[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws each
coefficient as its estimate with its bootstrap interval, colored by
whether the interval excludes zero.

``` r

plot(boot)
```

![Pairs bootstrap confidence intervals for the public-schools regression
coefficients.](hcinfer-bootstrap_files/figure-html/bootstrap-ci-plot-1.png)

## An empirical reference for HC standard errors

Because the pairs bootstrap assumes nothing about the error variance,
its standard errors are a useful cross-check on the analytic HC
estimators. The following table places the OLS, bootstrap, HCbeta, and
HC3 standard errors side by side.

``` r

data.frame(
  term = boot$table$term,
  ols = sqrt(diag(vcov(fit))),
  bootstrap = boot$table$std_error,
  hcbeta = sqrt(diag(vcov(hcinfer(fit, type = "hcbeta")))),
  hc3 = sqrt(diag(vcov(hcinfer(fit, type = "hc3"))))
)
#>                        term       ols bootstrap    hcbeta       hc3
#> (Intercept)     (Intercept) 2932.8749 2800.9458 2431.8340 2230.6434
#> income_scaled income_scaled  636.0126  627.4548  543.1465  498.2300
#> south                 south 1030.4299  902.1759  943.9061  887.2695
```

The bootstrap and HC standard errors should broadly agree; large
disagreements are worth investigating, often at high-leverage points.

## Reproducibility

With a fixed `seed`, two runs are identical, and the call restores the
caller’s random-number stream so it does not disturb a surrounding
analysis.

``` r

a <- boot_pairs(fit, B = 1000, seed = 7)
b <- boot_pairs(fit, B = 1000, seed = 7)
identical(a$replicates, b$replicates)
#> [1] TRUE
```

## Running in parallel

For large `B` or large `n`, set `cores` to `2` or more to distribute the
replicate fits across worker processes (requires the mirai and carrier
packages). The numeric result is identical to a sequential run with the
same seed; parallelism only changes the speed. The default `cores = 1`
runs sequentially.

``` r

boot_pairs(fit, B = 10000, cores = 4, seed = 1)
```

## Practical guidance

Use a few thousand replicates for stable standard errors and more for
stable tail quantiles of the percentile and basic intervals. Choose
`ci_type` to match your needs: percentile and basic intervals adapt to
skewness in the replicate distribution, while normal intervals are
symmetric. If a resample is rank deficient it is dropped with a warning,
and the summaries use the remaining replicates.
