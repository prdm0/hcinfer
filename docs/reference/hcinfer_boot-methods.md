# Extract components from a pairs bootstrap object

Extractors for objects returned by
[`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md).
[`coef()`](https://rdrr.io/r/stats/coef.html) returns the original OLS
coefficients, [`vcov()`](https://rdrr.io/r/stats/vcov.html) returns the
bootstrap covariance matrix (the sample covariance of the bootstrap
replicates), and [`confint()`](https://rdrr.io/r/stats/confint.html)
returns bootstrap confidence intervals, optionally recomputed at a
different `level` or `type` from the stored replicates.

## Usage

``` r
# S3 method for class 'hcinfer_boot'
coef(object, ...)

# S3 method for class 'hcinfer_boot'
vcov(object, ...)

# S3 method for class 'hcinfer_boot'
confint(object, parm, level = object$level, type = object$ci_type, ...)
```

## Arguments

- object:

  An object returned by
  [`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md).

- ...:

  Unused.

- parm:

  Optional coefficient names or integer positions.

- level:

  Confidence level for
  [`confint()`](https://rdrr.io/r/stats/confint.html). Defaults to the
  level stored in `object`.

- type:

  Interval type for [`confint()`](https://rdrr.io/r/stats/confint.html):
  `"percentile"`, `"basic"`, or `"normal"`. Defaults to the type stored
  in `object`.

## Value

[`coef()`](https://rdrr.io/r/stats/coef.html) a named numeric vector;
[`vcov()`](https://rdrr.io/r/stats/vcov.html) a numeric covariance
matrix; [`confint()`](https://rdrr.io/r/stats/confint.html) a tibble
with columns `term`, `conf_low`, `conf_high`, and `level`.
