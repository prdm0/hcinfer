#' Heteroskedasticity-consistent covariance estimator
#'
#' @description
#' Computes a heteroskedasticity-consistent covariance matrix estimator for an
#' ordinary least squares model fitted with [stats::lm()]. The function returns
#' a rich S3 object that stores the covariance matrix, HC weights, leverage
#' values, method parameters, and model metadata.
#'
#' @details
#' For a linear model with design matrix \eqn{X}, OLS residuals \eqn{\hat e_t},
#' and HC weights \eqn{g_t}, the estimator is
#'
#' \deqn{\widehat{\Psi}_{HC} =
#' (X'X)^{-1} X' \widehat{\Omega} X (X'X)^{-1},}
#'
#' where \eqn{\widehat{\Omega} = diag(\hat e_t^2 g_t)}. The supported
#' estimators are `"hc0"`, `"hc1"`, `"hc2"`, `"hc3"`, `"hc4"`, `"hc4m"`,
#' `"hc5"`, `"hc5m"`, and `"hcbeta"`.
#'
#' Additional arguments in `...` are method-specific. The defaults are:
#'
#' * `"hc0"`, `"hc1"`, `"hc2"`, `"hc3"`, `"hc4"`, and `"hc4m"`: no
#'   method-specific arguments.
#' * `"hc5"`: `k = 0.7`.
#' * `"hc5m"`: `k = 0.7`, `k1 = 1`, `k2 = 0`, `k3 = 1`, `gamma1 = 1`, and
#'   `gamma2 = 1.5`.
#' * `"hcbeta"`: `c1 = 7`, `c2 = 0.75`, `lower = 0.01`, `upper = 0.99`,
#'   `a_max = 10000`, and `b_max = 10000`.
#'
#' For `"hc5"` and `"hc5m"`, `k`, `k1`, `k2`, and `k3` must be nonnegative,
#' while `gamma1` and `gamma2` must be positive. For `"hcbeta"`, `c1` must be
#' nonnegative, `c2` must be positive, and `lower` and `upper` must lie in
#' `(0, 1)` with `lower < upper`. The HCbeta leverage-complement truncation is
#' \eqn{w_t = max(lower, min(1 - h_t, upper))}.
#'
#' After shrinkage with \eqn{\zeta = n / (n + 50)}, the Beta shape parameters
#' are clamped as
#' \deqn{\tilde a =
#' \min\{\max\{(1 - \zeta) + \zeta\hat a, \epsilon\}, A_{\max}\},}
#' \deqn{\tilde b =
#' \min\{\max\{(1 - \zeta) + \zeta\hat b, \epsilon\}, B_{\max}\}.}
#' The value \eqn{\epsilon = 0.01} is fixed, applied after shrinkage and before
#' the caps, and is not a method argument. It is distinct from `lower`, which
#' truncates \eqn{w_t}; changing `lower` does not change \eqn{\epsilon}.
#'
#' Both `a_max` and `b_max` must be finite and lie in `[50, 25000]`; they
#' default to 10000 and can be set independently through `...` for sensitivity
#' analysis. When the variance of the truncated complements is numerically
#' degenerate, the adjusted shapes are set directly to their respective caps.
#' HCbeta remains defined when \eqn{h_t = 1} because it truncates
#' \eqn{1 - h_t} before evaluating the Beta CDF. In contrast, HC2 through HC5m
#' require a strictly positive leverage complement.
#'
#' @param object An ordinary least squares model fitted by [stats::lm()].
#' @param type A character string specifying the HC estimator. The default is
#'   `"hcbeta"`.
#' @param ... Method-specific constants. Unknown names are rejected. See Details
#'   for the accepted names, defaults, and parameter domains.
#'
#' @return
#' An object of class `hcinfer_vcov`. The covariance matrix is stored in
#' `object$vcov` and is returned directly by [vcov()].
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
#' cov <- vcov_hc(fit, type = "hcbeta")
#' cov
#' vcov(cov)
#' plot(cov)
#'
#' # Sensitivity analysis with nondefault HCbeta caps
#' vcov_hc(fit, type = "hcbeta", a_max = 20000, b_max = 20000)
#' vcov_hc(fit, type = "hc5", k = 0.7)
#' vcov_hc(fit, type = "hc5m", k = 0.7, k1 = 1, k2 = 0, k3 = 1)
#'
#' @export
vcov_hc <- function(object, type = "hcbeta", ...) {
  call <- match.call()
  type <- normalise_hc_type(type)
  info <- model_info_lm(object)
  dots <- list(...)

  weights <- compute_hc_weights(
    type = type,
    leverage = info$leverage,
    n = info$n,
    p = info$p,
    dots = dots
  )

  psi <- robust_vcov_from_weights(
    x = info$x,
    residuals = info$residuals,
    weights = weights$weights
  )

  structure(
    list(
      call = call,
      type = type,
      label = hc_label(type),
      vcov = psi,
      weights = weights$weights,
      leverage = info$leverage,
      residuals = info$residuals,
      coefficients = info$coefficients,
      terms = info$terms,
      observation = info$observation,
      n = info$n,
      p = info$p,
      residual_df = info$residual_df,
      method_params = weights$params,
      model_call = info$model_call,
      model_formula = info$model_formula
    ),
    class = c("hcinfer_vcov", "hcinfer_object")
  )
}
