# Feasible GLS under multiplicative heteroskedasticity

Feasible generalized least squares (FGLS) complements the
heteroskedasticity-consistent (HC) estimators in `hcinfer`. The HC
estimators keep the ordinary least squares (OLS) coefficients and only
robustify their covariance, assuming nothing about the form of the
variance function. Feasible GLS instead models the conditional variance
as an exponential function of observed regressors, re-weights the
regression accordingly, and can be more efficient than OLS when that
variance model is adequate. The
[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
function offers two estimators of this model, Harvey’s two-step
procedure and Gaussian maximum likelihood, and the maximum likelihood
fit supplies a proper [`logLik()`](https://rdrr.io/r/stats/logLik.html)
together with [`AIC()`](https://rdrr.io/r/stats/AIC.html) and
[`BIC()`](https://rdrr.io/r/stats/AIC.html). The method follows Harvey
(1976) and Cribari-Neto and Pereira (2019).

## HC inference versus feasible GLS

The two approaches answer different questions and suit different
situations. Calling
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md) or
[`vcov_hc()`](https://prdm0.github.io/hcinfer/reference/vcov_hc.md)
returns the OLS point estimates together with a
heteroskedasticity-consistent sandwich covariance that is valid under
heteroskedasticity of unknown form, so it makes no commitment to how the
variance depends on the regressors. Calling
[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
instead estimates an explicit variance model, returns re-weighted
coefficients that can be more efficient than OLS, and reports a
model-based covariance that is valid when the variance model is
correctly specified. As a practical rule, the HC estimators are the
natural choice when you do not wish to model the variance and want
inference that is agnostic about its form, whereas feasible GLS is
attractive when a multiplicative variance model is plausible and the
efficiency gain matters.

## The multiplicative variance model

Feasible GLS in `hcinfer` is built on a linear mean model paired with a
multiplicative model for the conditional variance. The mean model is

y = X \beta + e, \qquad E(e_t) = 0, \qquad \operatorname{Var}(e_t) =
\sigma_t^2,

where y is the n \times 1 response, X is the n \times p mean design
matrix, and \beta is the vector of mean coefficients. The variance is
modelled as an exponential function of a second set of regressors,

\sigma_t^2 = \exp(\eta_t), \qquad \eta_t = z_t^\top \gamma,

so that the log-variance \eta_t is linear in the dispersion regressors
z_t, the rows of a dispersion design matrix Z, with coefficients \gamma.
Because the response has response units, \exp(\eta_t) has squared
response units and \exp(\eta_t/2) is the conditional standard deviation
in response units. The exponential link keeps the fitted variances
positive for any value of \gamma. The `variance` argument selects Z: a
one-sided formula such as `~ income_scaled` builds Z from the named
terms, while the default `variance = NULL` sets Z = X and reuses the
mean design. This is a model for the variance, not an assumption that
the residuals or leverage complements follow any particular
distribution.

## Two estimators

Both estimators target the same mean and variance model but reach it by
different routes. The two-step estimator is a single pass through an
auxiliary regression, whereas maximum likelihood locally optimises the
Gaussian profile likelihood and is accepted only at a stationary
solution. Maximum likelihood is the default, and it is also the fit that
supports the information criteria.

### Harvey two-step

The two-step estimator of Harvey (1976) begins from the OLS residuals
\hat e_t and regresses \log(\hat e_t^2) on the dispersion regressors Z.
Because the expectation of \log \varepsilon^2 under normality is not
zero, the intercept of this auxiliary regression is bias-corrected by
adding c = -\operatorname{digamma}(1/2) - \log 2 \approx 1.2704, the
bias of \log \varepsilon^2 under normality. The fitted log-variances
yield the weights \hat w_t = \exp(-z_t^\top \hat\gamma), and a single
weighted least squares pass with these weights delivers the mean
coefficients, with reported dispersion covariance
\tfrac{\pi^2}{2}(Z^\top Z)^{-1}.

### Maximum likelihood

Maximum likelihood optimises the Gaussian log-likelihood of the same
model. The mean coefficients \beta are profiled out by weighted least
squares at each candidate \gamma, so a BFGS optimiser searches only over
the dispersion parameters \gamma, and the reported asymptotic dispersion
covariance is 2(Z^\top Z)^{-1}. Under the model and standard regularity
conditions, maximum likelihood is asymptotically efficient. For an
accepted locally optimised stationary fit,
[`logLik()`](https://rdrr.io/r/stats/logLik.html) returns the likelihood
evaluated at that solution, which enables
[`AIC()`](https://rdrr.io/r/stats/AIC.html) and
[`BIC()`](https://rdrr.io/r/stats/AIC.html) without claiming that the
stationarity check has certified a global maximum.

## Data and model

The examples use the `PublicSchools2` data, which have complete
observations for the 50 U.S. states and the District of Columbia and
include a `south` indicator that the original `PublicSchools` data lack.
The `expenditure` response is annual expenditure per student enrolled in
K-12 public schools for 2025, measured in U.S. dollars. Income is
divided by ten thousand so that the estimated coefficients are on a
readable scale. The mean model regresses expenditure on rescaled income
and the regional indicator, and printing the fitted `lm` object shows
the OLS starting point that
[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
will refine.

[`library`](https://rdrr.io/r/base/library.html)`(`[`hcinfer`](https://prdm0.github.io/hcinfer/)`)`` `` ``schools`` ``<-`` ``PublicSchools2`` ``schools``$``income_scaled`` ``<-`` ``schools``$``income`` ``/`` ``10000`` `` ``fit`` ``<-`` `[`lm`](https://rdrr.io/r/stats/lm.html)`(``expenditure`` ``~`` ``income_scaled`` ``+`` ``south``, data ``=`` ``schools``)`` ``fit`` ``#> `` ``#> Call:`` ``#> lm(formula = expenditure ~ income_scaled + south, data = schools)`` ``#> `` ``#> Coefficients:`` ``#> (Intercept) income_scaled south `` ``#> -3111 4763 -1112`

## Maximum likelihood fit

With no `method` argument,
[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
fits the model by maximum likelihood, its default estimator. The printed
object gives a compact view of the mean and dispersion coefficients
together with the convergence diagnostics.

`gls_fit`` ``<-`` `[`gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)`(``fit``)`` ``gls_fit`` ``#> `` ``#> ``──`` ``Multiplicative heteroskedasticity FGLS summary`` ``──────────────────────────────`` ``#> `` ``#> ── ``Mean model`` ──`` ``#> `` ``` #> Formula: `expenditure ~ income_scaled + south` ``` ``#> Observations: 51 | Mean parameters: 3 | Dispersion parameters: 3`` ``#> `` ``#> ── ``Dispersion model`` ──`` ``#> `` ``` #> Specification: `Z = X (the mean model matrix)` ``` ``#> Fitting method: Maximum likelihood`` ``#> Variance function: exp(z' gamma)`` ``#> `` ``#> ── ``Model-based inference`` ──`` ``#> `` ``#> Confidence level: 95.0% | Normal critical value: 1.9600`` ``#> Coefficient covariance: model-based, conditional on a correctly specified`` ``#> variance model.`` ``#> `` ``#> ── ``Mean-coefficient Wald tests`` ──`` ``#> `` ``#> ``# A tibble: 3 × 7`` ``#> term estimate model_se z p_value test_result `` ``#> ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` (Intercept) -1003 2884 -0.3478 0.728 do not reject H0`` ``#> ``2`` income_scaled 4251 638.3 6.66 <0.001 reject H0 `` ``#> ``3`` south -977.7 867.6 -1.127 0.260 do not reject H0`` ``#> confidence_interval`` ``#> ``<chr>`` `` ``#> ``1`` [-6657, 4650] `` ``#> ``2`` [3000, 5502] `` ``#> ``3`` [-2678, 722.8]`` ``#> `` ``#> ── ``Dispersion coefficients`` ──`` ``#> `` ``#> ``# A tibble: 3 × 5`` ``#> term estimate std_error z p_value`` ``#> ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` (Intercept) 14.59 1.22 11.95 <0.001 `` ``#> ``2`` income_scaled 0.4123 0.2646 1.558 0.119 `` ``#> ``3`` south -0.9939 0.4287 -2.318 0.020`` ``#> `` ``#> ── ``Fitted conditional variance and standard deviation`` ──`` ``#> `` ``#> Variance is expressed in squared response units; standard deviation is`` ``#> expressed in response units.`` ``#> ``# A tibble: 6 × 3`` ``#> statistic variance standard_deviation`` ``#> ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` minimum 2.935e+06 1713 `` ``#> ``2`` q1 4.911e+06 2215 `` ``#> ``3`` median 1.17e+07 3420 `` ``#> ``4`` mean 1.123e+07 3231 `` ``#> ``5`` q3 1.466e+07 3829 `` ``#> ``6`` maximum 2.35e+07 4848`` ``#> `` ``#> ── ``Maximum likelihood`` ──`` ``#> `` ``#> logLik: -482.2 | AIC: 976.5 | BIC: 988`` ``#> Convergence code: 0 | function = 18 | gradient = 8`` ``#> Score norm (scale-invariant): 5.256e-05 | Gradient norm: 0.0008014`

[`summary`](https://rdrr.io/r/base/summary.html)`(``gls_fit``)`` ``#> `` ``#> ``──`` ``Multiplicative heteroskedasticity FGLS summary`` ``──────────────────────────────`` ``#> `` ``#> ── ``Mean model`` ──`` ``#> `` ``` #> Formula: `expenditure ~ income_scaled + south` ``` ``#> Observations: 51 | Mean parameters: 3 | Dispersion parameters: 3`` ``#> `` ``#> ── ``Dispersion model`` ──`` ``#> `` ``` #> Specification: `Z = X (the mean model matrix)` ``` ``#> Fitting method: Maximum likelihood`` ``#> Variance function: exp(z' gamma)`` ``#> `` ``#> ── ``Model-based inference`` ──`` ``#> `` ``#> Confidence level: 95.0% | Normal critical value: 1.9600`` ``#> Coefficient covariance: model-based, conditional on a correctly specified`` ``#> variance model.`` ``#> `` ``#> ── ``Mean-coefficient Wald tests`` ──`` ``#> `` ``#> ``# A tibble: 3 × 7`` ``#> term estimate model_se z p_value test_result `` ``#> ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` (Intercept) -1003 2884 -0.3478 0.728 do not reject H0`` ``#> ``2`` income_scaled 4251 638.3 6.66 <0.001 reject H0 `` ``#> ``3`` south -977.7 867.6 -1.127 0.260 do not reject H0`` ``#> confidence_interval`` ``#> ``<chr>`` `` ``#> ``1`` [-6657, 4650] `` ``#> ``2`` [3000, 5502] `` ``#> ``3`` [-2678, 722.8]`` ``#> `` ``#> ── ``Dispersion coefficients`` ──`` ``#> `` ``#> ``# A tibble: 3 × 5`` ``#> term estimate std_error z p_value`` ``#> ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` (Intercept) 14.59 1.22 11.95 <0.001 `` ``#> ``2`` income_scaled 0.4123 0.2646 1.558 0.119 `` ``#> ``3`` south -0.9939 0.4287 -2.318 0.020`` ``#> `` ``#> ── ``Fitted conditional variance and standard deviation`` ──`` ``#> `` ``#> Variance is expressed in squared response units; standard deviation is`` ``#> expressed in response units.`` ``#> ``# A tibble: 6 × 3`` ``#> statistic variance standard_deviation`` ``#> ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` minimum 2.935e+06 1713 `` ``#> ``2`` q1 4.911e+06 2215 `` ``#> ``3`` median 1.17e+07 3420 `` ``#> ``4`` mean 1.123e+07 3231 `` ``#> ``5`` q3 1.466e+07 3829 `` ``#> ``6`` maximum 2.35e+07 4848`` ``#> `` ``#> ── ``Maximum likelihood`` ──`` ``#> `` ``#> logLik: -482.2 | AIC: 976.5 | BIC: 988`` ``#> Convergence code: 0 | function = 18 | gradient = 8`` ``#> Score norm (scale-invariant): 5.256e-05 | Gradient norm: 0.0008014`

The summary reports fitted conditional variances in squared U.S.
dollars, or USD squared, because `expenditure` is measured in USD and
\exp(\eta_t) is a variance. On the standard-deviation scale, the
corresponding values range from about USD 1,713 to USD 4,848 and are
comparable to the OLS residual standard deviation of about USD 3,399.
The million-scale variance entries are therefore expected for this
response scale and are not evidence of an exponentiation error. The same
report gives the mean and dispersion blocks, normal Wald tests, and the
likelihood evaluated at the accepted local solution together with AIC
and BIC.

## Extracting the fit

The usual extractor functions work on the fitted object and, where
relevant, take a `model` argument to choose between the mean and
dispersion blocks.

[`coef`](https://rdrr.io/r/stats/coef.html)`(``gls_fit``)`` ``# mean coefficients`` ``#> (Intercept) income_scaled south `` ``#> -1003.2755 4251.2950 -977.6808`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(``gls_fit``, model ``=`` ``"dispersion"``)`` ``# log-variance coefficients`` ``#> (Intercept) income_scaled south `` ``#> 14.5855558 0.4122848 -0.9939059`

[`vcov`](https://rdrr.io/r/stats/vcov.html)`(``gls_fit``)`` ``# mean covariance`` ``#> (Intercept) income_scaled south`` ``#> (Intercept) 8319793 -1796404.4 -1314297.9`` ``#> income_scaled -1796404 407464.4 207402.6`` ``#> south -1314298 207402.6 752764.0`` `[`vcov`](https://rdrr.io/r/stats/vcov.html)`(``gls_fit``, model ``=`` ``"dispersion"``)`` ``# dispersion covariance`` ``#> (Intercept) income_scaled south`` ``#> (Intercept) 1.4890730 -0.31647258 -0.1612694`` ``#> income_scaled -0.3164726 0.07002617 0.0226683`` ``#> south -0.1612694 0.02266830 0.1838086`

[`tests`](https://prdm0.github.io/hcinfer/reference/tests.md)`(``gls_fit``)`` ``#> ``# A tibble: 3 × 8`` ``#> term estimate null_value std_error z_value p_value alpha reject`` ``#> ``<chr>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<lgl>`` `` ``#> ``1`` (Intercept) -``1``003.`` 0 ``2``884. -``0.348`` 7.28``e``- 1`` 0.05 FALSE `` ``#> ``2`` income_scaled ``4``251. 0 638. 6.66 2.74``e``-11`` 0.05 TRUE `` ``#> ``3`` south -``978.`` 0 868. -``1.13`` 2.60``e``- 1`` 0.05 FALSE`` `[`confint`](https://rdrr.io/r/stats/confint.html)`(``gls_fit``)`` ``#> ``# A tibble: 3 × 4`` ``#> term conf_low conf_high level`` ``#> ``<chr>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``#> ``1`` (Intercept) -``6``657.`` ``4``650. 0.95`` ``#> ``2`` income_scaled ``3``000. ``5``502. 0.95`` ``#> ``3`` south -``2``678.`` 723. 0.95`

[`head`](https://rdrr.io/r/utils/head.html)`(`[`fitted`](https://rdrr.io/r/stats/fitted.values.html)`(``gls_fit``)``)`` ``#> 1 2 3 4 5 6 `` ``#> 13360.69 18796.28 17066.00 12569.10 20046.16 21373.84`` `[`head`](https://rdrr.io/r/utils/head.html)`(``gls_fit``$``fitted_variances``)`` ``# estimated conditional variances`` ``#> 1 2 3 4 5 6 `` ``#> 3539380 14734315 12458202 3277838 16633036 18918634`` `[`head`](https://rdrr.io/r/utils/head.html)`(``gls_fit``$``weights``)`` ``# GLS weights exp(-eta)`` ``#> 1 2 3 4 5 6 `` ``#> 2.825354e-07 6.786878e-08 8.026840e-08 3.050792e-07 6.012131e-08 5.285794e-08`

By default [`coef()`](https://rdrr.io/r/stats/coef.html) and
[`vcov()`](https://rdrr.io/r/stats/vcov.html) return the mean block,
while `model = "dispersion"` selects the log-variance coefficients and
their covariance. The
[`tests()`](https://prdm0.github.io/hcinfer/reference/tests.md) and
[`confint()`](https://rdrr.io/r/stats/confint.html) methods report
normal Wald inference on the mean coefficients, using the model-based
standard errors. The fitted object also stores the conditional variances
in `fitted_variances` and the GLS weights \exp(-\eta_t) in `weights`, so
the estimated variance structure is available for diagnostics or
plotting. These weights have inverse-squared-response units, and
multiplying all of them by one positive constant leaves the weighted
least squares coefficients unchanged, so only their relative scale
affects those coefficients.

## Harvey two-step

Setting `method = "two_step"` fits the same model with Harvey’s
non-iterative estimator.

`two_step`` ``<-`` `[`gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)`(``fit``, method ``=`` ``"two_step"``)`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(``two_step``)`` ``#> (Intercept) income_scaled south `` ``#> -1842.018 4485.252 -1231.665`

[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` term ``=`` `[`names`](https://rdrr.io/r/base/names.html)`(`[`coef`](https://rdrr.io/r/stats/coef.html)`(``gls_fit``)``)``,`` `` ml ``=`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(``gls_fit``)``,`` `` two_step ``=`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(``two_step``)`` ``)`` ``#> term ml two_step`` ``#> (Intercept) (Intercept) -1003.2755 -1842.018`` ``#> income_scaled income_scaled 4251.2950 4485.252`` ``#> south south -977.6808 -1231.665`

The two-step estimator uses one auxiliary regression, whereas maximum
likelihood locally optimises the profile likelihood and applies the
stationarity guard. In this example, the income slopes are similar, but
the intercept and `south` coefficients differ more noticeably, so the
table demonstrates estimator dependence rather than equivalence.
Information criteria are defined only for the accepted maximum
likelihood fit because the two-step point does not optimise the
likelihood and therefore carries no comparable
[`logLik()`](https://rdrr.io/r/stats/logLik.html).

## Custom variance models

The `variance` argument decouples the dispersion model from the mean
model, so the analyst can let the variance depend on a different, and
usually smaller, set of regressors.

`gls_income`` ``<-`` `[`gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)`(``fit``, variance ``=`` ``~`` ``income_scaled``)`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(``gls_income``, model ``=`` ``"dispersion"``)`` ``#> (Intercept) income_scaled `` ``#> 13.1818795 0.6728328`

Here the variance is modelled as a function of income alone, while the
mean model still includes both income and the regional indicator. The
default `variance = NULL` instead reuses the full mean design as Z,
which is convenient but not always the most parsimonious choice for the
variance.

## Model selection with AIC and BIC

Because each maximum likelihood fit carries a proper
[`logLik()`](https://rdrr.io/r/stats/logLik.html) with p + q degrees of
freedom, where p counts the mean coefficients and q the dispersion
coefficients, the base [`AIC()`](https://rdrr.io/r/stats/AIC.html) and
[`BIC()`](https://rdrr.io/r/stats/AIC.html) generics compare competing
variance specifications directly. The three fits below share the same
mean model but differ in their variance model: the full dispersion model
on income and region, a reduced model on income alone, and the special
case `variance = ~ 1`, which forces a constant variance and so reduces
the fit to the homoskedastic Gaussian model.

`full`` ``<-`` `[`gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)`(``fit``)`` ``# variance ~ income + south`` ``income_only`` ``<-`` `[`gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)`(``fit``, variance ``=`` ``~`` ``income_scaled``)`` ``homoskedastic`` ``<-`` `[`gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)`(``fit``, variance ``=`` ``~`` ``1``)`` `[`AIC`](https://rdrr.io/r/stats/AIC.html)`(``full``, ``income_only``, ``homoskedastic``)`` ``#> df AIC`` ``#> full 6 976.4563`` ``#> income_only 5 978.3837`` ``#> homoskedastic 4 979.0259`` `[`BIC`](https://rdrr.io/r/stats/AIC.html)`(``full``, ``income_only``, ``homoskedastic``)`` ``#> df BIC`` ``#> full 6 988.0473`` ``#> income_only 5 988.0428`` ``#> homoskedastic 4 986.7532`

The specification with the smallest criterion is preferred, so these
tables let the data adjudicate between richer and sparser variance
models on the same footing. Because they rest on the likelihood, the
criteria are defined only for maximum likelihood fits. Meaningful
comparisons also require the competing fits to have reached comparable
likelihood solutions.

## Comparison with HC standard errors

It is instructive to place the feasible GLS standard errors next to the
OLS and HC standard errors for the same model.

[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` term ``=`` `[`names`](https://rdrr.io/r/base/names.html)`(`[`coef`](https://rdrr.io/r/stats/coef.html)`(``fit``)``)``,`` `` ols ``=`` `[`sqrt`](https://rdrr.io/r/base/MathFun.html)`(`[`diag`](https://rdrr.io/r/base/diag.html)`(`[`vcov`](https://rdrr.io/r/stats/vcov.html)`(``fit``)``)``)``,`` `` fgls_ml ``=`` `[`sqrt`](https://rdrr.io/r/base/MathFun.html)`(`[`diag`](https://rdrr.io/r/base/diag.html)`(`[`vcov`](https://rdrr.io/r/stats/vcov.html)`(``gls_fit``)``)``)``,`` `` hcbeta ``=`` `[`sqrt`](https://rdrr.io/r/base/MathFun.html)`(`[`diag`](https://rdrr.io/r/base/diag.html)`(`[`vcov`](https://rdrr.io/r/stats/vcov.html)`(`[`hcinfer`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)`(``fit``, type ``=`` ``"hcbeta"``)``)``)``)``,`` `` hc3 ``=`` `[`sqrt`](https://rdrr.io/r/base/MathFun.html)`(`[`diag`](https://rdrr.io/r/base/diag.html)`(`[`vcov`](https://rdrr.io/r/stats/vcov.html)`(`[`hcinfer`](https://prdm0.github.io/hcinfer/reference/hcinfer.md)`(``fit``, type ``=`` ``"hc3"``)``)``)``)`` ``)`` ``#> term ols fgls_ml hcbeta hc3`` ``#> (Intercept) (Intercept) 2932.8749 2884.4052 2431.8340 2230.6434`` ``#> income_scaled income_scaled 636.0126 638.3294 543.1465 498.2300`` ``#> south south 1030.4299 867.6197 943.9061 887.2695`

The feasible GLS standard errors come from a re-weighted fit under an
explicit variance model, whereas the HC standard errors, here HC\beta
and HC3, keep the OLS coefficients and only robustify their covariance
without modelling the variance. Agreement between the reported standard
errors is descriptive and does not by itself establish that the variance
model is correctly specified. Systematic differences can motivate
inspection of the variance specification and influential high-leverage
observations, but they do not identify either explanation on their own.

## Practical guidance

Several practical points help in routine use. Maximum likelihood is the
recommended default because it is efficient under the model and provides
information criteria, while the two-step estimator is a useful
non-iterative alternative. The mean covariance that
[`gls_mult()`](https://prdm0.github.io/hcinfer/reference/gls_mult.md)
reports is a model-based plug-in, valid when the variance model is
correctly specified rather than an HC sandwich, so inference that should
be agnostic about the variance form still belongs to
[`hcinfer()`](https://prdm0.github.io/hcinfer/reference/hcinfer.md).
Scaling the dispersion regressors sensibly can improve numerical
behaviour, because extreme scaling may require optimiser tuning through
`control`, such as a tighter `reltol`. The convergence code and
scale-invariant score check establish only a locally optimised
stationary fit; they do not prove that the accepted solution is a global
maximum. For the underlying theory of the HC estimators see
[`vignette("hcinfer-methodology", package = "hcinfer")`](https://prdm0.github.io/hcinfer/articles/hcinfer-methodology.md),
and for the full argument list see
[`?gls_mult`](https://prdm0.github.io/hcinfer/reference/gls_mult.md).
