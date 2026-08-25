# Plot multiplicative heteroskedasticity FGLS confidence intervals

Plots the normal Wald confidence intervals for the mean coefficients of
a [`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
fit, color-coded by the test decision at the stored significance level,
matching
[`plot.hcinfer()`](https://prdm0.github.io/hcinfer/reference/plot.hcinfer.md).
Only the mean block is shown, consistent with
[`confint.gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult-methods.md)
and
[`tests.gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult-methods.md).

## Usage

``` r
# S3 method for class 'gls_mult'
plot(x, parm, ...)
```

## Arguments

- x:

  An object returned by
  [`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md).

- parm:

  Optional coefficient names or integer positions. Selection follows the
  same rules as
  [`confint.gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult-methods.md)
  and
  [`tests.gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult-methods.md).

- ...:

  Unused. Passing named arguments raises an error.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## See also

[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md),
[`confint.gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult-methods.md),
[`tests.gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult-methods.md)

## Examples

``` r
fit <- lm(expenditure ~ income, data = PublicSchools)
result <- gls_mult(fit)
plot(result)

plot(result, parm = "income")

```
