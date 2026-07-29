# State crime rates and socioeconomic indicators, 2009

Violent-crime and murder rates together with socioeconomic indicators
for the 50 U.S. states and the District of Columbia in 2009. The data
are useful for illustrating heteroskedasticity-consistent inference in a
cross-sectional design with influential observations.

## Usage

``` r
Crime2009
```

## Format

A tibble with 51 rows and 8 variables:

- state:

  Name of one of the 50 U.S. states or the District of Columbia.

- violent:

  Violent-crime rate per 100,000 population.

- murder:

  Murder rate per 100,000 population.

- hs_grad:

  Percentage of the population that graduated from high school or
  higher.

- poverty:

  Percentage of the population living below the poverty line.

- single:

  Percentage of households headed by a single parent.

- white:

  Percentage of the population that is white.

- urban:

  Percentage of the population living in urban areas.

## Source

French, J. P. (2023). *api2lm: Functions and Data Sets for the Book 'A
Progressive Introduction to Linear Models'*. R package version 0.2.
[doi:10.32614/CRAN.package.api2lm](https://doi.org/10.32614/CRAN.package.api2lm)
. The same data are distributed as the `statecrime` dataset in the
Python `statsmodels` package (Seabold and Perktold, 2010,
<https://www.statsmodels.org/>); the underlying figures come from the
*Statistical Abstract of the United States* (2009) and are in the public
domain.

## Examples

``` r
data(Crime2009)
Crime2009[Crime2009$state == "Alabama", ]
#> # A tibble: 1 × 8
#>   state   violent murder hs_grad poverty single white urban
#>   <chr>     <dbl>  <dbl>   <dbl>   <dbl>  <dbl> <dbl> <dbl>
#> 1 Alabama    460.    7.1    82.1    17.5     29    70  48.6

fit <- lm(violent ~ poverty + single, data = Crime2009)
hcinfer(fit, type = "hcbeta")
#> 
#> ── 🔎 HCbeta robust inference ──────────────────────────────────────────────────
#> 📐 Model: `violent ~ poverty + single`
#> Observations: 51 | Parameters: 3
#> 🥪 Robust covariance: HCbeta
#> Confidence level: 95.0% | Normal critical value: 1.9600
#> 💡 Use `summary()` for p-values, test results, confidence intervals, and
#> diagnostics.
```
