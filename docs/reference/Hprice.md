# Boston-area home prices, 1990

Sale prices, assessed values, and physical characteristics of 88 homes
sold in the Boston, Massachusetts area in 1990. The data are widely used
to illustrate regression and heteroskedasticity-consistent inference.

## Usage

``` r
Hprice
```

## Format

A tibble with 88 rows and 10 variables:

- price:

  House price, in thousands of U.S. dollars.

- assess:

  Assessed value, in thousands of U.S. dollars.

- bdrms:

  Number of bedrooms.

- lotsize:

  Size of the lot, in square feet.

- sqrft:

  Size of the house, in square feet.

- colonial:

  Indicator equal to 1 if the home is of colonial style.

- lprice:

  Natural logarithm of `price`.

- lassess:

  Natural logarithm of `assess`.

- llotsize:

  Natural logarithm of `lotsize`.

- lsqrft:

  Natural logarithm of `sqrft`.

## Source

Wooldridge, J. M. (2020). *Introductory Econometrics: A Modern
Approach*, 7th ed. Cengage Learning, Boston, MA. The `hprice1` data are
distributed with the `wooldridge` R package and were originally
collected from the real estate pages of the *Boston Globe*.

## Examples

``` r
data(Hprice)
head(Hprice)
#> # A tibble: 6 × 10
#>   price assess bdrms lotsize sqrft colonial lprice lassess llotsize lsqrft
#>   <dbl>  <dbl> <int>   <dbl> <int>    <int>  <dbl>   <dbl>    <dbl>  <dbl>
#> 1  300    349.     4    6126  2438        1   5.70    5.86     8.72   7.80
#> 2  370    352.     3    9903  2076        1   5.91    5.86     9.20   7.64
#> 3  191    218.     3    5200  1374        0   5.25    5.38     8.56   7.23
#> 4  195    232.     3    4600  1448        1   5.27    5.45     8.43   7.28
#> 5  373    319.     4    6095  2514        1   5.92    5.77     8.72   7.83
#> 6  466.   414.     5    8566  2754        1   6.14    6.03     9.06   7.92

fit <- lm(price ~ lotsize + sqrft + bdrms, data = Hprice)
hcinfer(fit, type = "hcbeta")
#> 
#> ── 🔎 HCbeta robust inference ──────────────────────────────────────────────────
#> 📐 Model: `price ~ lotsize + sqrft + bdrms`
#> Observations: 88 | Parameters: 4
#> 🥪 Robust covariance: HCbeta
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
```
