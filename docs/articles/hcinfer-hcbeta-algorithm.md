# The HCbeta algorithm and its consistency

This vignette presents the HCbeta adjustment factor as an explicit
algorithm and records the argument that it yields a consistent
covariance estimator. It complements
[`vignette("hcinfer-methodology", package = "hcinfer")`](https://prdm0.github.io/hcinfer/articles/hcinfer-methodology.md),
which places HCbeta within the broader family of HC estimators, and
[`vignette("hcinfer-hcbeta", package = "hcinfer")`](https://prdm0.github.io/hcinfer/articles/hcinfer-hcbeta.md),
which is usage oriented.

## Motivation

The classical leverage corrections write the adjustment factor as a
power of the leverage complement u_t = 1 - h_t. Because u_t \in \[0,
1\], it can be read as the value at 1 - h_t of the cumulative
distribution function of a Uniform(0, 1) random variable. HCbeta keeps
this reading but replaces the uniform cdf with a Beta cdf F_B(w_t;
\tilde a, \tilde b) evaluated at a truncated complement w_t. The two
shape parameters give the correction curve an extra degree of
flexibility, so the adjustment can adapt to the observed leverage
configuration instead of following a fixed exponent.

This flexibility is what tempers the overshooting that HC3, HC4, and
HC4m can display under strong leverage, where small values of 1 - h_t
raised to a fixed negative exponent produce very large factors. HCbeta
calibrates the Beta shape parameters to the first two sample moments of
w_t, so the resulting factor reflects the actual spread of the leverages
rather than a worst case exponent.

It is important to state what HCbeta does not assume. The Beta cdf is a
calibration device, not a claim that the leverage complements follow a
Beta distribution. The shape parameters are matched to the sample mean
and variance of the truncated complements, and the construction would be
unchanged if the leverages arose from another mechanism. The Beta family
is used because its support is \[0, 1\] and its two parameters are
enough to bend the uniform baseline in either direction.

## The algorithm

Let X be the n \times p design matrix of an OLS fit with residuals \hat
e_t and leverages h_t = x_t'(X'X)^{-1}x_t. HCbeta computes the
adjustment factor g_t in four steps.

1.  **Truncated leverage complements.** Form u_t = 1 - h_t and truncate
    it to w_t = \max\\\text{lower}, \min(u_t, \text{upper})\\, with
    defaults \text{lower} = 0.01 and \text{upper} = 0.99. The lower
    bound prevents the adjustment from exploding when h_t approaches
    one, and the upper bound keeps the values away from the boundary
    when leverages are small.

2.  **Method of moments.** Estimate the mean and variance of the
    truncated complements, \hat\mu = n^{-1}\sum\_{t=1}^{n} w_t and s_w^2
    = (n - 1)^{-1}\sum\_{t=1}^{n}(w_t - \hat\mu)^2, and map them to Beta
    shape parameters through the mean precision parameterization,
    \hat\phi = \hat\mu(1 - \hat\mu)/s_w^2 - 1, \hat a = \hat\mu\hat\phi,
    and \hat b = (1 - \hat\mu)\hat\phi.

3.  **Shrinkage with caps.** Shrink the estimates toward the uniform
    case a = b = 1 and bound them from above, \zeta = n/(n + 50), \tilde
    a = \min\\(1 - \zeta) + \zeta\hat a,\\ A\_{\max}\\, and \tilde b =
    \min\\(1 - \zeta) + \zeta\hat b,\\ B\_{\max}\\, with defaults
    A\_{\max} = B\_{\max} = 10000 set through the arguments `a_max` and
    `b_max`, each of which accepts finite values in the inclusive range
    `[50, 25000]`. Shrinkage stabilizes the small sample estimates, and
    the caps keep the shape parameters in a bounded range.

4.  **Adjustment factor and sandwich.** Combine the Beta cdf with a
    decaying exponent, g_t = \frac{n}{n - p}\left\\1/F_B(w_t; \tilde a,
    \tilde b)\right\\^{c_1/n^{c_2}}, with defaults c_1 = 7 and c_2 =
    0.75. The covariance estimator is the sandwich
    \widehat\Psi\_{HC\beta} = (X'X)^{-1} X'\widehat\Omega\_\beta X
    (X'X)^{-1} with \widehat\Omega\_\beta = \operatorname{diag}(\hat
    e_t^2 g_t).

The degrees of freedom factor n/(n - p) enters g_t in the same way as in
HC1. When \tilde a = \tilde b = 1 the Beta cdf returns w_t, and with c_1
= 0 the factor reduces to n/(n - p), so HCbeta coincides with HC1. This
identity is a convenient implementation check and is exercised in the
package tests.

## Consistency

The consistency of HCbeta follows from the standard argument for HC0
given by White (1980) for fixed regressors, extended to stochastic
regressors in the usual way. The role of the HCbeta construction is only
to show that its adjustment factor does not disturb that argument
asymptotically. The reasoning below is presented at an accessible level
and does not introduce a new theorem.

Two features keep the adjustment under control. First, the truncation to
\[0.01, 0.99\] and the bounds on the shape parameters place \tilde a and
\tilde b in a compact interval \[\varepsilon, \max(A\_{\max},
B\_{\max})\] with \varepsilon \> 0. On that compact set the Beta cdf
evaluated at w_t is bounded away from zero, so that \inf_t F_B(w_t;
\tilde a, \tilde b) \geq \delta for some \delta \> 0, and therefore
\sup_t \|\log F_B(w_t; \tilde a, \tilde b)\| \leq -\log\delta \< \infty.
The caps are what make the parameter space compact, which is what keeps
the log adjustments uniformly bounded.

The caps are essential when the leverage variance vanishes. Under the
standard fixed-design condition \max_t h_t \to 0, the complements
eventually reach the common upper truncation, so s_w^2 = 0 and the
uncapped method-of-moments shape estimates diverge. HCbeta then uses
A\_{\max} and B\_{\max} as the limiting shape parameters instead of
aborting. This keeps the Beta cdf and g_t well-defined throughout the
sequence; with the default caps, the common cdf is numerically one and
g_t equals the HC1 scale n/(n - p).

Second, a first-order Taylor expansion of g_t around one gives \sup_t
\|g_t - 1\| = O(n^{-c_2}) = o(1), because the exponent c_1/n^{c_2} tends
to zero while it multiplies the bounded log cdf. It follows that
\widehat\Omega\_\beta and the HC0 residual matrix
\operatorname{diag}(\hat e_t^2) are asymptotically equivalent, so
\widehat\Psi\_{HC\beta} and \widehat\Psi\_{HC0} share the same limit.
HCbeta therefore inherits the consistency of HC0, while the finite
sample factor g_t supplies the leverage correction that motivates the
method without the overshooting that fixed exponent methods can produce
under strong leverage.

## Numerical implementation

Three safeguards keep the computation of g_t numerically stable. First,
the Beta cdf is evaluated on the log scale with
`pbeta(w, a_tilde, b_tilde, log.p = TRUE)`, which returns \log F_B
directly and avoids the \log(0) = -\infty that a naive `log(pbeta(...))`
would produce when the cdf underflows for extreme shape parameters.
Second, the exponent -(c_1/n^{c_2})\log F_B(w_t; \tilde a, \tilde b) is
capped at 700 before exponentiation, so that
[`exp()`](https://rdrr.io/r/base/Log.html) cannot overflow to infinity.
Third, the degrees of freedom factor n/(n - p) is computed once and
reused.

The published applications are unaffected by the caps because the
default A\_{\max} = B\_{\max} = 10000 is far from binding on those
designs. The quadratic public schools model illustrates this.

``` r

library(hcinfer)

schools <- transform(
  PublicSchools,
  income_scaled = income / 10000,
  income_scaled_sq = (income / 10000)^2
)
fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
cov <- vcov_hc(fit, type = "hcbeta")

cov$method_params[c("a_tilde", "b_tilde", "a_max", "b_max")]
#> $a_tilde
#> [1] 3.147193
#> 
#> $b_tilde
#> [1] 0.6689698
#> 
#> $a_max
#> [1] 10000
#> 
#> $b_max
#> [1] 10000
max(cov$weights)
#> [1] 4.580723
```

The adjusted shape parameters are well below the caps, and the largest
adjustment factor matches the value reported for this model. By
construction each factor is at least the HC1 scale n/(n - p), because
the capped exponent is nonnegative and the leading factor is exactly
n/(n - p).

``` r

n <- cov$n
p <- cov$p

all(cov$weights >= n / (n - p))
#> [1] TRUE
```
