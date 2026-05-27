# Public school expenditure and income by US state

Public school expenditure and income data for US states and Washington
DC in 1979. The expenditure value for Wisconsin is missing in the source
data, so the standard regression example uses 50 complete observations.
The data are useful for illustrating heteroskedasticity-consistent
inference because Alaska is a high-leverage observation in the quadratic
public-schools model studied in the HCbeta paper.

## Usage

``` r
PublicSchools
```

## Format

A tibble with 51 rows and 3 variables:

- state:

  US state or Washington DC.

- expenditure:

  Per capita expenditure on public schools in 1979. This variable has
  one missing value.

- income:

  Per capita income in 1979.

## Source

Greene, W. H. (1993). *Econometric Analysis*, 2nd ed. Macmillan
Publishing Company, New York. Table 14.1, p. 385. The data were
originally sourced from the U.S. Department of Commerce, *Statistical
Abstract of the United States* (1979). The dataset is also available in
the `sandwich` R package.

## Examples

``` r
data(PublicSchools)
PublicSchools[PublicSchools$state == "Alaska", ]
#> # A tibble: 1 × 3
#>   state  expenditure income
#>   <chr>        <dbl>  <dbl>
#> 1 Alaska         821  10851

schools <- PublicSchools |>
  dplyr::mutate(
    income_scaled = income / 10000,
    income_scaled_sq = income_scaled^2
  )
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
hcinfer(fit, type = "hcbeta")
#> 
#> ── 🔎 HCbeta robust inference ──────────────────────────────────────────────────
#> 📐 Model: `expenditure ~ income_scaled + income_scaled_sq`
#> Observations: 50 | Parameters: 3
#> 🥪 Robust covariance: HCbeta
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
```
