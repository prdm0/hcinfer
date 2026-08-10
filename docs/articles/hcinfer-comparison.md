# Comparing HC Estimators

This vignette assumes the introduction
([`vignette("introduction", package = "hcinfer")`](https://prdm0.github.io/hcinfer/articles/introduction.md))
and compares several HC estimators on a single fitted model, using
coefficient tables, confidence intervals, covariance matrices, robust
weights, and leverage diagnostics.

## Fit one model

Comparisons should start from one fitted model. Here we use the Boston
house-price model from the HCbeta paper (price regressed on lot size,
number of bedrooms, and a bedrooms-by-size interaction) and focus on the
lot-size coefficient.

``` r

library(hcinfer)

fit <- lm(price ~ lotsize + bdrms + bdrms:sqrft, data = Hprice)
```

## Run several methods

The `type` argument selects the HC estimator. Store each result in a
named list so that later extraction is straightforward.

``` r

methods <- c("hc0", "hc3", "hc4", "hc4m", "hcbeta")

results <- purrr::map(methods, \(method) {
  hcinfer(fit, type = method)
})
names(results) <- methods
```

## Compare one coefficient

Most applied comparisons focus on one or a few coefficients. The helper
below uses
[`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md) and
[`confint()`](https://rdrr.io/r/stats/confint.html) to extract one
coefficient and adds the method name.

``` r

extract_term <- function(result, method, term = "lotsize") {
  row <- tests(result, parm = term)
  ci <- confint(result, parm = term)

  tibble::tibble(
    method = method,
    estimate = row$estimate,
    std_error = row$std_error,
    p_value = row$p_value,
    conf_low = ci$conf_low,
    conf_high = ci$conf_high,
    reject = row$reject
  )
}

comparison <- purrr::imap(results, extract_term)
comparison <- dplyr::bind_rows(comparison)
comparison
#> # A tibble: 5 × 7
#>   method estimate std_error p_value  conf_low conf_high reject
#>   <chr>     <dbl>     <dbl>   <dbl>     <dbl>     <dbl> <lgl> 
#> 1 hc0     0.00199   0.00109  0.0673 -0.000142   0.00412 FALSE 
#> 2 hc3     0.00199   0.00670  0.767  -0.0111     0.0151  FALSE 
#> 3 hc4     0.00199   0.0451   0.965  -0.0863     0.0903  FALSE 
#> 4 hc4m    0.00199   0.0108   0.854  -0.0191     0.0231  FALSE 
#> 5 hcbeta  0.00199   0.00214  0.354  -0.00222    0.00619 FALSE
```

Add interval widths when the goal is to compare how conservative the
estimators are for this coefficient.

``` r

comparison <- comparison |>
  dplyr::mutate(interval_width = conf_high - conf_low)

comparison
#> # A tibble: 5 × 8
#>   method estimate std_error p_value  conf_low conf_high reject interval_width
#>   <chr>     <dbl>     <dbl>   <dbl>     <dbl>     <dbl> <lgl>           <dbl>
#> 1 hc0     0.00199   0.00109  0.0673 -0.000142   0.00412 FALSE         0.00426
#> 2 hc3     0.00199   0.00670  0.767  -0.0111     0.0151  FALSE         0.0263 
#> 3 hc4     0.00199   0.0451   0.965  -0.0863     0.0903  FALSE         0.177  
#> 4 hc4m    0.00199   0.0108   0.854  -0.0191     0.0231  FALSE         0.0423 
#> 5 hcbeta  0.00199   0.00214  0.354  -0.00222    0.00619 FALSE         0.00841
```

## Plot the robust standard errors

A simple plot can help show how the estimators differ for the selected
coefficient.

``` r

ggplot2::ggplot(comparison, ggplot2::aes(x = method, y = std_error)) +
  ggplot2::geom_col(fill = "#305c8a") +
  ggplot2::labs(
    x = "Estimator",
    y = "Robust standard error for the lot-size coefficient"
  ) +
  ggplot2::theme_minimal(base_size = 12)
```

![Bar chart comparing robust standard errors for the lot-size
coefficient across HC
estimators.](hcinfer-comparison_files/figure-html/comparison-se-plot-1.png)

## Compare confidence intervals directly

[`confint()`](https://rdrr.io/r/stats/confint.html) returns a tibble for
one result. Use the stored comparison table when you want intervals from
several methods side by side.

``` r

comparison |>
  dplyr::select(method, conf_low, conf_high, interval_width)
#> # A tibble: 5 × 4
#>   method  conf_low conf_high interval_width
#>   <chr>      <dbl>     <dbl>          <dbl>
#> 1 hc0    -0.000142   0.00412        0.00426
#> 2 hc3    -0.0111     0.0151         0.0263 
#> 3 hc4    -0.0863     0.0903         0.177  
#> 4 hc4m   -0.0191     0.0231         0.0423 
#> 5 hcbeta -0.00222    0.00619        0.00841
```

## Compare covariance objects

Use [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
when you only need the covariance matrix and diagnostics, not
coefficient tests.

``` r

cov_hc3 <- vcov_hc(fit, type = "hc3")
cov_hc3
#> 
#> ── HC3 robust covariance ───────────────────────────────────────────────────────
#> Model: `price ~ lotsize + bdrms + bdrms:sqrft`
#> Dimension: 4 x 4
#> Observations: 88
#> Parameters: 4
#> Maximum leverage: 0.8517
#> Maximum robust weight: 45.4824
#> Use `vcov()` to extract the stored covariance matrix.
vcov(cov_hc3)
#>               (Intercept)       lotsize         bdrms   bdrms:sqrft
#> (Intercept)  8746.3251016 -5.211208e-01 -2919.1484384  7.562435e-01
#> lotsize        -0.5211208  4.491379e-05     0.1647236 -5.637653e-05
#> bdrms       -2919.1484384  1.647236e-01  1099.5622412 -3.040083e-01
#> bdrms:sqrft     0.7562435 -5.637653e-05    -0.3040083  1.045768e-04
```

Plot the adjustment factors against leverage values for a covariance
object.

``` r

plot(cov_hc3)
```

![Scatterplot of HC3 adjustment factors against leverage values for the
Hprice
model.](hcinfer-comparison_files/figure-html/comparison-hc3-plot-1.png)

The covariance object also has a summary method.

``` r

summary(cov_hc3)
#> 
#> ── HC3 robust covariance summary ───────────────────────────────────────────────
#> 
#> ── Model ──
#> 
#> Formula: `price ~ lotsize + bdrms + bdrms:sqrft`
#> Observations: 88 | Parameters: 4 | Residual df: 84
#> 
#> ── Leverage diagnostics ──
#> 
#> # A tibble: 6 × 2
#>   statistic value  
#>   <chr>     <chr>  
#> 1 minimum   0.01498
#> 2 q1        0.01772
#> 3 median    0.02034
#> 4 mean      0.04545
#> 5 q3        0.02978
#> 6 maximum   0.8517
#> Maximum leverage: observation 77 (index 77), value 0.8517
#> Average leverage: 0.0455
#> Concentration: 18.74 x average leverage
#> 
#> ── Robust weights ──
#> 
#> # A tibble: 6 × 2
#>   statistic value
#>   <chr>     <chr>
#> 1 minimum   1.031
#> 2 q1        1.036
#> 3 median    1.042
#> 4 mean      1.591
#> 5 q3        1.062
#> 6 maximum   45.48
#> Maximum weight: observation 77 (index 77), value 45.4824
#> Median weight: 1.0420
#> Concentration: 43.65 x median weight
#> 
#> ── Method parameters ──
#> 
#> No additional method parameters.
```

## Compare diagnostics across methods

All covariance and inference objects store robust weights and leverage
values. The leverage values depend only on the fitted model, while the
weights depend on the HC estimator.

``` r

covariances <- purrr::map(methods, \(method) {
  vcov_hc(fit, type = method)
})
names(covariances) <- methods

diagnostic_comparison <- purrr::imap(covariances, \(cov, method) {
  tibble::tibble(
    method = method,
    max_leverage = max(cov$leverage),
    max_weight = max(cov$weights),
    median_weight = stats::median(cov$weights)
  )
})
diagnostic_comparison <- dplyr::bind_rows(diagnostic_comparison)
diagnostic_comparison
#> # A tibble: 5 × 4
#>   method max_leverage max_weight median_weight
#>   <chr>         <dbl>      <dbl>         <dbl>
#> 1 hc0           0.852       1             1   
#> 2 hc3           0.852      45.5           1.04
#> 3 hc4           0.852    2069.            1.01
#> 4 hc4m          0.852     118.            1.02
#> 5 hcbeta        0.852       4.42          1.13
```

The next figure mirrors the empirical display in the HCbeta paper:
adjustment factors are plotted against leverages for HC3, HC4, HC4m, and
HCbeta.

``` r

figure_methods <- c("hc3", "hc4", "hc4m", "hcbeta")
figure_covariances <- purrr::map(figure_methods, \(method) {
  vcov_hc(fit, type = method)
})
names(figure_covariances) <- figure_methods

weight_comparison <- purrr::imap(figure_covariances, \(cov, method) {
  tibble::tibble(
    method = cov$label,
    leverage = cov$leverage,
    weight = cov$weights,
    high_leverage = cov$leverage > 3 * cov$p / cov$n
  )
}) |>
  dplyr::bind_rows() |>
  dplyr::mutate(
    method = factor(method, levels = c("HC3", "HC4", "HC4m", "HCbeta"))
  )

ggplot2::ggplot(weight_comparison, ggplot2::aes(x = leverage, y = weight)) +
  ggplot2::geom_point(
    ggplot2::aes(color = high_leverage),
    size = 1.8,
    alpha = 0.85
  ) +
  ggplot2::facet_wrap(~method, scales = "free_y", ncol = 2) +
  ggplot2::scale_color_manual(
    values = c(`FALSE` = "#2c5f8a", `TRUE` = "#c0392b"),
    guide = "none"
  ) +
  ggplot2::labs(
    x = expression(h[t]),
    y = expression(g[t])
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    strip.text = ggplot2::element_text(face = "bold"),
    panel.grid.minor = ggplot2::element_blank()
  )
```

![Faceted scatterplot of HC adjustment factors against leverage values
for HC3, HC4, HC4m, and HCbeta in the Hprice
model.](hcinfer-comparison_files/figure-html/comparison-weight-facets-1.png)

## What to report

A compact reporting table usually needs the estimator, estimate, robust
standard error, p-value, and interval endpoints.

``` r

comparison |>
  dplyr::select(method, estimate, std_error, p_value, conf_low, conf_high)
#> # A tibble: 5 × 6
#>   method estimate std_error p_value  conf_low conf_high
#>   <chr>     <dbl>     <dbl>   <dbl>     <dbl>     <dbl>
#> 1 hc0     0.00199   0.00109  0.0673 -0.000142   0.00412
#> 2 hc3     0.00199   0.00670  0.767  -0.0111     0.0151 
#> 3 hc4     0.00199   0.0451   0.965  -0.0863     0.0903 
#> 4 hc4m    0.00199   0.0108   0.854  -0.0191     0.0231 
#> 5 hcbeta  0.00199   0.00214  0.354  -0.00222    0.00619
```

Use this comparison to document how sensitive your conclusion is to the
choice of HC estimator. Use
[`vignette("hcinfer-hcbeta")`](https://prdm0.github.io/hcinfer/articles/hcinfer-hcbeta.md)
for a closer look at the default HCbeta estimator.
