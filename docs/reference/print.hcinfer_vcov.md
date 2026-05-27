# Print hcinfer covariance objects

Prints a compact overview of a heteroskedasticity-consistent covariance
object. Emoji markers are used when the current locale supports UTF-8
and `getOption("hcinfer.use_emoji", TRUE)` is true.

## Usage

``` r
# S3 method for class 'hcinfer_vcov'
print(x, ...)
```

## Arguments

- x:

  An object returned by
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md).

- ...:

  Unused.

## Value

The input object, invisibly.
