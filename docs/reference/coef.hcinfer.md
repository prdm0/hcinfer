# Extract model coefficients from an hcinfer object

Extracts the OLS coefficients stored in an
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)
result.

## Usage

``` r
# S3 method for class 'hcinfer'
coef(object, ...)
```

## Arguments

- object:

  An object returned by
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md).

- ...:

  Unused.

## Value

A named numeric vector of OLS coefficients.
