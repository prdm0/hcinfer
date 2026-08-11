# information criteria reject a two-step fit

    Code
      logLik(result)
    Condition
      Error in `logLik()`:
      ! Information criteria require the maximum likelihood fit.
      i Refit with `gls_mult(..., method = "ml")` to use `logLik()`, `AIC()`, and `BIC()`.

---

    Code
      AIC(result)
    Condition
      Error in `ll()`:
      ! Information criteria require the maximum likelihood fit.
      i Refit with `gls_mult(..., method = "ml")` to use `logLik()`, `AIC()`, and `BIC()`.

# dispersion formulas preserve the mean estimation sample

    Code
      gls_mult(unavailable_fit, variance = ~z, method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! The original data for the mean model could not be recovered.
      i Refit `stats::lm()` with the data available in the formula environment.
      Caused by error:
      ! object 'unavailable_data' not found

---

    Code
      gls_mult(misaligned_fit, variance = ~z, method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! The dispersion data do not contain the complete estimation sample.
      x Missing rows: "old1", "old2", "old3", "old4", "old5", "old6", "old7", "old8", "old9", "old10", "old11", and "old12".
      i Refit the mean model and dispersion model from the same data source.

# gls_mult reports unsupported and unidentified fits

    Code
      gls_mult(1)
    Condition
      Error in `gls_mult()`:
      ! `object` must be a linear model fitted by `stats::lm()`.
      x You supplied an object with class <numeric>.

---

    Code
      gls_mult(multivariate_fit)
    Condition
      Error in `gls_mult()`:
      ! Multivariate <mlm> responses are not supported.
      i Fit one univariate mean model at a time.

---

    Code
      gls_mult(weighted_fit)
    Condition
      Error in `gls_mult()`:
      ! Weighted <lm> objects are not supported.
      i The implemented covariance estimators follow the ordinary least squares model.

---

    Code
      gls_mult(offset_fit)
    Condition
      Error in `gls_mult()`:
      ! Offset mean models are not supported.
      i Fit the mean model without an offset before using `gls_mult()`.

---

    Code
      gls_mult(rank_fit)
    Condition
      Error in `gls_mult()`:
      ! The mean model matrix must have full column rank.
      x Its rank is 2, but it has 3 columns.

---

    Code
      gls_mult(dispersion_rank_fit, variance = ~ z + I(2 * z), method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! The dispersion model matrix must have full column rank.
      x Its rank is 2, but it has 3 columns.

---

    Code
      gls_mult(missing_fit, variance = ~z, method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! The dispersion model matrix must contain only finite values.
      i Missing and nonfinite dispersion regressors are not supported.

---

    Code
      gls_mult(no_intercept_fit, method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! The dispersion model needs exactly one all-ones intercept column.
      i Include one intercept so the Harvey bias correction is well defined.

---

    Code
      gls_mult(zero_residual_fit, method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! OLS residuals must be finite and nonzero.
      i The auxiliary response `log(residual^2)` is undefined otherwise.

---

    Code
      gls_mult(missing_residual_fit, method = "two_step")
    Condition
      Error in `gls_mult()`:
      ! OLS residuals must be finite and nonzero.
      i The auxiliary response `log(residual^2)` is undefined otherwise.

---

    Code
      gls_mult(public_fit, method = "ml", control = list(maxit = 1))
    Condition
      Error in `gls_mult()`:
      ! Maximum likelihood optimization did not converge.
      x stats::optim() returned convergence code 1.

# maximum likelihood requires positive finite objective scaling

    Code
      gls_mult(fit, method = "ml", control = list(fnscale = -1))
    Condition
      Error in `gls_mult()`:
      ! `control$fnscale` must be one finite positive number.
      i `gls_mult()` already minimizes the negative profile log-likelihood.

