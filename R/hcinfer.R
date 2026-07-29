#' Heteroskedasticity-consistent Wald inference
#'
#' @description
#' Computes normal Wald tests and confidence intervals for an ordinary least
#' squares model using a heteroskedasticity-consistent covariance estimator.
#'
#' @details
#' For each coefficient, hcinfer tests
#'
#' \deqn{H_0: \beta_j = \beta_j^{(0)}}
#'
#' against a two-sided alternative using the statistic
#'
#' \deqn{z_j =
#' \frac{\hat\beta_j - \beta_j^{(0)}}
#' {\sqrt{[\widehat{\Psi}_{HC}]_{jj}}}.}
#'
#' The reference distribution is the standard normal distribution. Confidence
#' intervals are Wald intervals obtained by direct inversion of the test,
#'
#' \deqn{\hat\beta_j \pm z_{1 - \alpha / 2}
#' \sqrt{[\widehat{\Psi}_{HC}]_{jj}}.}
#'
#' Bootstrap intervals and Student t quantiles are not used.
#'
#' @param object An ordinary least squares model fitted by [stats::lm()].
#' @param type A character string specifying the HC estimator. The default is
#'   `"hcbeta"`.
#' @param alpha Significance level. The confidence level is `1 - alpha`.
#' @param null Null values for the coefficient tests. Use a scalar to test all
#'   coefficients against the same value, or a numeric vector with one value per
#'   coefficient.
#' @param ... Method-specific constants passed to [vcov_hc()]. For HCbeta,
#'   `a_max` and `b_max` default to 10000, may be set independently, and must
#'   each be finite and lie in `[50, 25000]`. See [vcov_hc()] for all other
#'   method-specific defaults and parameter domains.
#'
#' @return
#' An object of class `hcinfer` containing the fitted HC covariance estimator,
#' coefficient tests, p-values, confidence intervals, diagnostics, and method
#' parameters.
#'
#' @references
#' White, H. (1980). A heteroskedasticity-consistent covariance matrix estimator
#' and a direct test for heteroskedasticity. *Econometrica*, 48(4), 817-838.
#' \doi{10.2307/1912934}
#'
#' Hinkley, D. V. (1977). Jackknifing in unbalanced situations.
#' *Technometrics*, 19(3), 285-292.
#' \doi{10.1080/00401706.1977.10489550}
#'
#' MacKinnon, J. G. and White, H. (1985). Some heteroskedasticity-consistent
#' covariance matrix estimators with improved finite sample properties.
#' *Journal of Econometrics*, 29(3), 305-325.
#' \doi{10.1016/0304-4076(85)90158-7}
#'
#' Davidson, R. and MacKinnon, J. G. (1993). *Estimation and Inference in
#' Econometrics*. Oxford University Press.
#'
#' Cribari-Neto, F. (2004). Asymptotic inference under heteroskedasticity of
#' unknown form. *Computational Statistics and Data Analysis*, 45(2), 215-233.
#' \doi{10.1016/S0167-9473(02)00366-3}
#'
#' Cribari-Neto, F. and da Silva, W. B. (2011). A new heteroskedasticity
#' consistent covariance matrix estimator for the linear regression model.
#' *AStA Advances in Statistical Analysis*, 95(2), 129-146.
#' \doi{10.1007/s10182-010-0141-2}
#'
#' Cribari-Neto, F., Souza, T. C., and Vasconcellos, K. L. P. (2007).
#' Inference under heteroskedasticity and leveraged data. *Communications in
#' Statistics - Theory and Methods*, 36(10), 1877-1888.
#' \doi{10.1080/03610920601126589}
#'
#' Li, S., Zhang, N., Zhang, X., and Wang, G. (2016). A new
#' heteroskedasticity-consistent covariance matrix estimator and inference
#' under heteroskedasticity. *Journal of Statistical Computation and
#' Simulation*, 87(1), 198-210.
#' \doi{10.1080/00949655.2016.1198906}
#'
#' @examples
#' schools <- PublicSchools |>
#'   dplyr::mutate(
#'     income_scaled = income / 10000,
#'     income_scaled_sq = income_scaled^2
#'   )
#' fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
#' result <- hcinfer(fit, type = "hcbeta")
#' result
#' summary(result)
#' confint(result)
#'
#' # Sensitivity analysis with nondefault HCbeta caps
#' hcinfer(fit, type = "hcbeta", a_max = 20000, b_max = 20000)
#' hcinfer(fit, type = "hc5", k = 0.7)
#' hcinfer(fit, type = "hc5m", k = 0.7, k1 = 1, k2 = 0, k3 = 1)
#'
#' @export
hcinfer <- function(object, type = "hcbeta", alpha = 0.05, null = 0, ...) {
  call <- match.call()
  check_alpha(alpha)

  cov <- vcov_hc(object, type = type, ...)
  coefficients <- cov$coefficients
  terms <- cov$terms
  null <- check_null(null, terms)
  critical_value <- stats::qnorm(1 - alpha / 2)

  std_error <- sqrt(diag(cov$vcov))
  if (any(!is.finite(std_error)) || any(std_error <= 0)) {
    cli::cli_abort(
      "Robust standard errors must be positive and finite."
    )
  }

  z_value <- (coefficients - null) / std_error
  p_value <- 2 * stats::pnorm(abs(z_value), lower.tail = FALSE)
  conf_low <- coefficients - critical_value * std_error
  conf_high <- coefficients + critical_value * std_error

  table <- tibble::tibble(
    term = terms,
    estimate = unname(coefficients),
    null_value = unname(null),
    std_error = unname(std_error),
    z_value = unname(z_value),
    p_value = unname(p_value),
    conf_low = unname(conf_low),
    conf_high = unname(conf_high)
  )

  structure(
    list(
      call = call,
      model_call = cov$model_call,
      model_formula = cov$model_formula,
      type = cov$type,
      label = cov$label,
      alpha = alpha,
      confidence_level = 1 - alpha,
      null = null,
      critical_value = critical_value,
      n = cov$n,
      p = cov$p,
      residual_df = cov$residual_df,
      coefficients = coefficients,
      vcov = cov$vcov,
      weights = cov$weights,
      leverage = cov$leverage,
      residuals = cov$residuals,
      terms = terms,
      observation = cov$observation,
      method_params = cov$method_params,
      table = table
    ),
    class = c("hcinfer", "hcinfer_object")
  )
}
