hc_type_labels <- function() {
  c(
    hc0 = "HC0",
    hc1 = "HC1",
    hc2 = "HC2",
    hc3 = "HC3",
    hc4 = "HC4",
    hc4m = "HC4m",
    hc5 = "HC5",
    hc5m = "HC5m",
    hcbeta = "HCbeta"
  )
}

hc_type_descriptions <- function() {
  c(
    hc0 = "White heteroskedasticity-consistent estimator.",
    hc1 = "HC0 with degrees-of-freedom scaling.",
    hc2 = "Leverage-adjusted estimator with exponent 1.",
    hc3 = "Leverage-adjusted estimator with exponent 2.",
    hc4 = "Adaptive leverage correction by Cribari-Neto.",
    hc4m = "Modified HC4 correction by Cribari-Neto and da Silva.",
    hc5 = "High-leverage correction by Cribari-Neto, Souza, and Vasconcellos.",
    hc5m = "Modified HC5 correction by Li, Zhang, Zhang, and Wang.",
    hcbeta = "Beta-distribution leverage correction."
  )
}

hc_default_arguments <- function() {
  list(
    hc0 = list(),
    hc1 = list(),
    hc2 = list(),
    hc3 = list(),
    hc4 = list(),
    hc4m = list(),
    hc5 = list(k = 0.7),
    hc5m = list(k = 0.7, k1 = 1, k2 = 0, k3 = 1, gamma1 = 1, gamma2 = 1.5),
    hcbeta = list(c1 = 7, c2 = 0.75, lower = 0.01, upper = 0.99)
  )
}

format_default_arguments <- function(args) {
  if (length(args) == 0) {
    return("none")
  }

  values <- purrr::imap_chr(args, \(value, name) paste0(name, " = ", value))
  paste(values, collapse = ", ")
}

#' Available heteroskedasticity-consistent estimators
#'
#' @description
#' Returns the HC covariance estimators implemented by hcinfer.
#'
#' @return
#' A tibble with columns `type`, `label`, `description`, and
#' `default_arguments`.
#'
#' @examples
#' hc_methods()
#'
#' @export
hc_methods <- function() {
  labels <- hc_type_labels()
  descriptions <- hc_type_descriptions()
  defaults <- hc_default_arguments()
  type <- purrr::map_chr(names(labels), identity)

  tibble::tibble(
    type = type,
    label = unname(labels),
    description = unname(descriptions[type]),
    default_arguments = unname(purrr::map_chr(defaults[type], format_default_arguments))
  )
}
