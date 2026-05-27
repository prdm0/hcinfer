# Plot HC adjustment factors against leverages

Plots the HC adjustment factors \\g_t\\ against the leverage values
\\h_t\\ stored in a
[`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
object. Points with \\h_t \> 3p/n\\ are highlighted because this
threshold is commonly used to flag high-leverage observations in the
empirical examples from the HCbeta paper.

## Usage

``` r
# S3 method for class 'hcinfer_vcov'
plot(x, label_top = 3, ...)
```

## Arguments

- x:

  An object returned by
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md).

- label_top:

  A nonnegative whole number. The observations with the largest
  adjustment factors are labeled. Use `0` to suppress labels.

- ...:

  Unused. Passing named arguments raises an error.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md),
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md),
[`plot.hcinfer()`](https://prdm0.github.io/hcinfer/reference/plot.hcinfer.md)

## Examples

``` r
schools <- PublicSchools |>
  dplyr::mutate(
    income_scaled = income / 10000,
    income_scaled_sq = income_scaled^2
  )
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)

cov <- vcov_hc(fit, type = "hcbeta")
plot(cov)

plot(vcov_hc(fit, type = "hc4"), label_top = 2)

```
