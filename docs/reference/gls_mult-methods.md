# Methods for multiplicative heteroskedasticity GLS fits

Extracts, summarizes, and prints components of an object returned by
[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md).
Mean-model methods use normal Wald inference. The `model` argument
selects the mean or dispersion parameter block for
[`coef()`](https://rdrr.io/r/stats/coef.html) and
[`vcov()`](https://rdrr.io/r/stats/vcov.html).

## Usage

``` r
# S3 method for class 'gls_mult'
coef(object, model = c("mean", "dispersion"), ...)

# S3 method for class 'gls_mult'
vcov(object, model = c("mean", "dispersion"), ...)

# S3 method for class 'gls_mult'
confint(object, parm, level = object$confidence_level, ...)

# S3 method for class 'gls_mult'
tests(object, parm, alpha = object$alpha, ...)

# S3 method for class 'gls_mult'
nobs(object, ...)

# S3 method for class 'gls_mult'
fitted(object, ...)

# S3 method for class 'gls_mult'
residuals(object, ...)

# S3 method for class 'gls_mult'
logLik(object, ...)

# S3 method for class 'gls_mult'
print(x, ...)

# S3 method for class 'gls_mult'
summary(object, ...)

# S3 method for class 'summary_gls_mult'
print(x, ...)
```

## Arguments

- object, x:

  An object returned by
  [`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md),
  or its summary.

- model:

  Parameter block to extract: `"mean"` or `"dispersion"`.

- ...:

  Unused. Passing arguments raises an error.

- parm:

  Optional mean-coefficient names or integer positions.

- level:

  Confidence level for mean-coefficient intervals.

- alpha:

  Significance level for mean-coefficient tests.

## Value

[`coef()`](https://rdrr.io/r/stats/coef.html) returns a named numeric
vector; [`vcov()`](https://rdrr.io/r/stats/vcov.html) returns a
covariance matrix; [`confint()`](https://rdrr.io/r/stats/confint.html)
and [`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md)
return tibbles; [`fitted()`](https://rdrr.io/r/stats/fitted.values.html)
and [`residuals()`](https://rdrr.io/r/stats/residuals.html) return named
numeric vectors; [`nobs()`](https://rdrr.io/r/stats/nobs.html) returns
the sample size; and [`logLik()`](https://rdrr.io/r/stats/logLik.html)
returns a `logLik` object for maximum likelihood fits.
[`summary()`](https://rdrr.io/r/base/summary.html) returns an object of
class `summary_gls_mult`, including fitted conditional-variance and
standard-deviation summaries in squared response and response units.
Print methods return their input invisibly.
