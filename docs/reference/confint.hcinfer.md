# Confidence intervals for hcinfer objects

Extracts normal Wald confidence intervals from an
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
result. If the requested level differs from the level used to create the
object, only the normal critical value and interval endpoints are
recomputed.

## Usage

``` r
# S3 method for class 'hcinfer'
confint(object, parm, level = object$confidence_level, ...)
```

## Arguments

- object:

  An object returned by
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md).

- parm:

  Optional coefficient names or positions.

- level:

  Confidence level.

- ...:

  Unused.

## Value

A tibble with columns `term`, `conf_low`, `conf_high`, and `level`.
