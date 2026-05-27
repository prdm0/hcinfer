# Summarize heteroskedasticity-consistent inference

Builds a detailed summary for an
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
result. The summary includes model metadata, HC method information,
leverage diagnostics, robust weight diagnostics, and
coefficient-by-coefficient normal Wald tests with p-values and
confidence intervals. The print method adds formal test decisions to
improve interpretation while preserving the numeric components of the
object.

## Usage

``` r
# S3 method for class 'hcinfer'
summary(object, ...)
```

## Arguments

- object:

  An object returned by
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md).

- ...:

  Unused.

## Value

An object of class `summary_hcinfer`.
