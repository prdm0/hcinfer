# Plot robust confidence intervals

Plots normal Wald confidence intervals for an
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
result. Each interval is color-coded by the test decision at the stored
significance level: coefficients for which the null hypothesis is
rejected are shown in red, and those for which it is not rejected are
shown in blue. Formatted p-values are printed to the right of each
interval for quick reading.

## Usage

``` r
# S3 method for class 'hcinfer'
plot(x, parm, ...)
```

## Arguments

- x:

  An object returned by
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md).

- parm:

  Optional coefficient names or integer positions. When supplied, only
  the selected coefficients are plotted. The selection follows the same
  rules as
  [`confint.hcinfer()`](https://prdm0.github.io/hcinfer/reference/confint.hcinfer.md)
  and
  [`tests.hcinfer()`](https://prdm0.github.io/hcinfer/reference/tests.md).

- ...:

  Unused. Passing named arguments raises an error.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md),
[`confint.hcinfer()`](https://prdm0.github.io/hcinfer/reference/confint.hcinfer.md),
[`tests.hcinfer()`](https://prdm0.github.io/hcinfer/reference/tests.md)

## Examples

``` r
schools <- PublicSchools |>
  dplyr::mutate(
    income_scaled = income / 10000,
    income_scaled_sq = income_scaled^2
  )
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
result <- hcinfer(fit)
plot(result)

plot(result, parm = "income_scaled_sq")

```
