#' Print hcinfer objects
#'
#' @description
#' Prints a compact overview of a heteroskedasticity-consistent inference
#' object. Emoji markers are used when the current locale supports UTF-8 and
#' `getOption("hcinfer.use_emoji", TRUE)` is true.
#'
#' @param x An object returned by [hcinfer()].
#' @param ... Unused.
#'
#' @return The input object, invisibly.
#'
#' @export
print.hcinfer <- function(x, ...) {
  check_dots_empty(list(...))

  title <- output_label("tests", paste(x$label, "robust inference"))
  cli::cli_h1(title)

  model <- output_label("model", "Model")
  cli::cli_text("{model}: {.code {format_formula(x$model_formula)}}")
  cli::cli_text("Observations: {x$n} | Parameters: {x$p}")

  covariance <- output_label("covariance", "Robust covariance")
  cli::cli_text("{covariance}: {x$label}")
  cli::cli_text("Confidence level: {format_percent(x$confidence_level)} | Normal critical value: {formatC(x$critical_value, digits = 4, format = 'f')}")

  interpretation <- output_label("interpretation", "Use {.fn summary} for p-values, test results, confidence intervals, and diagnostics.")
  cli::cli_text(interpretation)

  invisible(x)
}

#' Print hcinfer covariance objects
#'
#' @description
#' Prints a compact overview of a heteroskedasticity-consistent covariance
#' object. Emoji markers are used when the current locale supports UTF-8 and
#' `getOption("hcinfer.use_emoji", TRUE)` is true.
#'
#' @param x An object returned by [vcov_hc()].
#' @param ... Unused.
#'
#' @return The input object, invisibly.
#'
#' @export
print.hcinfer_vcov <- function(x, ...) {
  check_dots_empty(list(...))

  title <- output_label("covariance", paste(x$label, "robust covariance"))
  cli::cli_h1(title)

  model <- output_label("model", "Model")
  cli::cli_text("{model}: {.code {format_formula(x$model_formula)}}")
  cli::cli_text("Dimension: {nrow(x$vcov)} x {ncol(x$vcov)}")
  cli::cli_text("Observations: {x$n}")
  cli::cli_text("Parameters: {x$p}")

  leverage <- output_label("leverage", "Maximum leverage")
  cli::cli_text("{leverage}: {formatC(max(x$leverage), digits = 4, format = 'f')}")

  weights <- output_label("weights", "Maximum robust weight")
  cli::cli_text("{weights}: {formatC(max(x$weights), digits = 4, format = 'f')}")
  cli::cli_text("Use {.fn vcov} to extract the stored covariance matrix.")

  invisible(x)
}
