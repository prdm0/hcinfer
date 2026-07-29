# Package index

## Inference

- [`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) :
  Heteroskedasticity-consistent Wald inference
- [`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md) :
  Extract coefficient test results
- [`confint(`*`<hcinfer>`*`)`](https://prdm0.github.io/hcinfer/reference/confint.hcinfer.md)
  : Confidence intervals for hcinfer objects
- [`plot(`*`<hcinfer>`*`)`](https://prdm0.github.io/hcinfer/reference/plot.hcinfer.md)
  : Plot robust confidence intervals
- [`summary(`*`<hcinfer>`*`)`](https://prdm0.github.io/hcinfer/reference/summary.hcinfer.md)
  : Summarize heteroskedasticity-consistent inference

## Bootstrap

- [`boot_pairs()`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md)
  [`print(`*`<hcinfer_boot>`*`)`](https://prdm0.github.io/hcinfer/reference/boot_pairs.md)
  : Pairs bootstrap standard errors and confidence intervals
- [`coef(`*`<hcinfer_boot>`*`)`](https://prdm0.github.io/hcinfer/reference/hcinfer_boot-methods.md)
  [`vcov(`*`<hcinfer_boot>`*`)`](https://prdm0.github.io/hcinfer/reference/hcinfer_boot-methods.md)
  [`confint(`*`<hcinfer_boot>`*`)`](https://prdm0.github.io/hcinfer/reference/hcinfer_boot-methods.md)
  : Extract components from a pairs bootstrap object
- [`plot(`*`<hcinfer_boot>`*`)`](https://prdm0.github.io/hcinfer/reference/plot.hcinfer_boot.md)
  : Plot pairs bootstrap confidence intervals

## Covariance estimators

- [`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md) :
  Heteroskedasticity-consistent covariance estimator
- [`plot(`*`<hcinfer_vcov>`*`)`](https://prdm0.github.io/hcinfer/reference/plot.hcinfer_vcov.md)
  : Plot HC adjustment factors against leverages
- [`hc_methods()`](https://prdm0.github.io/hcinfer/reference/hc_methods.md)
  : Available heteroskedasticity-consistent estimators

## Data

- [`PublicSchools`](https://prdm0.github.io/hcinfer/reference/PublicSchools.md)
  : Public school expenditure and income by U.S. jurisdiction
- [`PublicSchools2`](https://prdm0.github.io/hcinfer/reference/PublicSchools2.md)
  : Public school expenditure, income, and region by U.S. jurisdiction
- [`Crime2009`](https://prdm0.github.io/hcinfer/reference/Crime2009.md)
  : State crime rates and socioeconomic indicators, 2009
- [`Hprice`](https://prdm0.github.io/hcinfer/reference/Hprice.md) :
  Boston-area home prices, 1990

## S3 methods

- [`coef(`*`<hcinfer>`*`)`](https://prdm0.github.io/hcinfer/reference/coef.hcinfer.md)
  : Extract model coefficients from an hcinfer object
- [`print(`*`<hcinfer>`*`)`](https://prdm0.github.io/hcinfer/reference/print.hcinfer.md)
  : Print hcinfer objects
- [`print(`*`<hcinfer_vcov>`*`)`](https://prdm0.github.io/hcinfer/reference/print.hcinfer_vcov.md)
  : Print hcinfer covariance objects
- [`summary(`*`<hcinfer_vcov>`*`)`](https://prdm0.github.io/hcinfer/reference/summary.hcinfer_vcov.md)
  : Summarize heteroskedasticity-consistent covariance objects
- [`vcov(`*`<hcinfer>`*`)`](https://prdm0.github.io/hcinfer/reference/vcov.hcinfer.md)
  [`vcov(`*`<hcinfer_vcov>`*`)`](https://prdm0.github.io/hcinfer/reference/vcov.hcinfer.md)
  : Extract robust covariance matrices
