# Available heteroskedasticity-consistent estimators

Returns the HC covariance estimators implemented by hcinfer.

## Usage

``` r
hc_methods()
```

## Value

A tibble with columns `type`, `label`, `description`, and
`default_arguments`.

## Examples

``` r
hc_methods()
#> # A tibble: 9 × 4
#>   type   label  description                                    default_arguments
#>   <chr>  <chr>  <chr>                                          <chr>            
#> 1 hc0    HC0    White heteroskedasticity-consistent estimator. none             
#> 2 hc1    HC1    HC0 with degrees-of-freedom scaling.           none             
#> 3 hc2    HC2    Leverage-adjusted estimator with exponent 1.   none             
#> 4 hc3    HC3    Leverage-adjusted estimator with exponent 2.   none             
#> 5 hc4    HC4    Adaptive leverage correction by Cribari-Neto.  none             
#> 6 hc4m   HC4m   Modified HC4 correction by Cribari-Neto and d… none             
#> 7 hc5    HC5    High-leverage correction by Cribari-Neto, Sou… k = 0.7          
#> 8 hc5m   HC5m   Modified HC5 correction by Li, Zhang, Zhang, … k = 0.7, k1 = 1,…
#> 9 hcbeta HCbeta Beta-distribution leverage correction.         c1 = 7, c2 = 0.7…
```
