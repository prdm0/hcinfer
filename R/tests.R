#' Extract coefficient test results
#'
#' @description
#' Extracts the normal Wald test results from an [hcinfer()] object. If the
#' requested significance level differs from the one used to create the object,
#' only the `reject` column is recomputed. The test statistics and p-values are
#' not affected by `alpha` and are never recomputed.
#'
#' @details
#' For each coefficient, the stored test is
#'
#' \deqn{H_0: \beta_j = \beta_j^{(0)}}
#'
#' against a two-sided alternative. The test statistic is
#'
#' \deqn{z_j =
#' \frac{\hat\beta_j - \beta_j^{(0)}}
#' {\sqrt{[\widehat{\Psi}_{HC}]_{jj}}},}
#'
#' and the p-value is \eqn{2\,\Phi(-|z_j|)}, where \eqn{\Phi} is the standard
#' normal distribution function. The null value \eqn{\beta_j^{(0)}} is the one
#' stored in the object, set when [hcinfer()] was called.
#'
#' To test against a different null value, rerun [hcinfer()] with the desired
#' `null` argument.
#'
#' @param object An object returned by [hcinfer()].
#' @param parm Optional coefficient names or integer positions to select a
#'   subset of coefficients. When omitted, all coefficients are returned.
#' @param alpha Significance level used to compute the `reject` column. Must
#'   be strictly between 0 and 1. Defaults to the level stored in `object`.
#'   Changing `alpha` updates only the `reject` column; all other columns
#'   remain identical to the stored values.
#' @param ... Unused. Passing named arguments raises an error.
#'
#' @return
#' A tibble with one row per selected coefficient and the following columns:
#'
#' \describe{
#'   \item{`term`}{Coefficient name.}
#'   \item{`estimate`}{OLS estimate \eqn{\hat\beta_j}.}
#'   \item{`null_value`}{Null hypothesis value \eqn{\beta_j^{(0)}}.}
#'   \item{`std_error`}{Robust standard error
#'     \eqn{\sqrt{[\widehat{\Psi}_{HC}]_{jj}}}.}
#'   \item{`z_value`}{Normal Wald statistic \eqn{z_j}.}
#'   \item{`p_value`}{Two-sided p-value \eqn{2\,\Phi(-|z_j|)}.}
#'   \item{`alpha`}{Significance level used for the `reject` column.}
#'   \item{`reject`}{Logical. `TRUE` when `p_value < alpha`.}
#' }
#'
#' @seealso [hcinfer()], [confint.hcinfer()]
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
#' result <- hcinfer(fit)
#'
#' tests(result)
#' tests(result, parm = "income_scaled_sq")
#' tests(result, alpha = 0.10)
#'
#' @export
tests <- function(object, ...) {
  UseMethod("tests")
}

#' @rdname tests
#' @export
tests.hcinfer <- function(object, parm, alpha = object$alpha, ...) {
  check_dots_empty(list(...))
  check_alpha(alpha)

  table <- object$table

  if (!missing(parm)) {
    if (is.numeric(parm)) {
      table <- table[parm, , drop = FALSE]
    } else if (is.character(parm)) {
      missing_terms <- setdiff(parm, table$term)
      if (length(missing_terms) > 0) {
        cli::cli_abort(
          c(
            "Unknown coefficient name in {.arg parm}.",
            "x" = "Unknown term: {.val {missing_terms}}."
          )
        )
      }
      table <- table[match(parm, table$term), , drop = FALSE]
    } else {
      abort_bad_argument("parm", "It must contain coefficient names or positions.")
    }
  }

  tibble::tibble(
    term      = table$term,
    estimate  = table$estimate,
    null_value = table$null_value,
    std_error = table$std_error,
    z_value   = table$z_value,
    p_value   = table$p_value,
    alpha     = alpha,
    reject    = table$p_value < alpha
  )
}
