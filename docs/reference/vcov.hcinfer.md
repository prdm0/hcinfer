# Extract robust covariance matrices

Extracts the heteroskedasticity-consistent covariance matrix stored in
an hcinfer object. The matrix is returned directly and is not
recomputed.

## Usage

``` r
# S3 method for class 'hcinfer'
vcov(object, ...)

# S3 method for class 'hcinfer_vcov'
vcov(object, ...)
```

## Arguments

- object:

  An object returned by
  [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) or
  [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md).

- ...:

  Unused.

## Value

A numeric covariance matrix.
