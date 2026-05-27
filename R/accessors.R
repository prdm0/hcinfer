#' Extract robust covariance matrices
#'
#' @description
#' Extracts the heteroskedasticity-consistent covariance matrix stored in an
#' hcinfer object. The matrix is returned directly and is not recomputed.
#'
#' @param object An object returned by [hcinfer()] or [vcov_hc()].
#' @param ... Unused.
#'
#' @return A numeric covariance matrix.
#'
#' @export
vcov.hcinfer <- function(object, ...) {
  check_dots_empty(list(...))
  object$vcov
}

#' @rdname vcov.hcinfer
#' @export
vcov.hcinfer_vcov <- function(object, ...) {
  check_dots_empty(list(...))
  object$vcov
}

#' Extract model coefficients from an hcinfer object
#'
#' @description
#' Extracts the OLS coefficients stored in an [hcinfer()] result.
#'
#' @param object An object returned by [hcinfer()].
#' @param ... Unused.
#'
#' @return A named numeric vector of OLS coefficients.
#'
#' @export
coef.hcinfer <- function(object, ...) {
  check_dots_empty(list(...))
  object$coefficients
}
