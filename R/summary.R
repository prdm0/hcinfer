numeric_summary <- function(x) {
  qs <- stats::quantile(x, probs = c(0.25, 0.5, 0.75), names = FALSE)
  tibble::tibble(
    minimum = min(x),
    q1 = qs[[1]],
    median = qs[[2]],
    mean = mean(x),
    q3 = qs[[3]],
    maximum = max(x)
  )
}

max_diagnostic <- function(x, observation) {
  index <- which.max(x)
  tibble::tibble(
    index = index,
    observation = observation[[index]],
    value = unname(x[[index]])
  )
}

#' Summarize heteroskedasticity-consistent inference
#'
#' @description
#' Builds a detailed summary for an [hcinfer()] result. The summary includes
#' model metadata, HC method information, leverage diagnostics, robust weight
#' diagnostics, and coefficient-by-coefficient normal Wald tests with p-values
#' and confidence intervals. The print method adds formal test decisions to
#' improve interpretation while preserving the numeric components of the object.
#'
#' @param object An object returned by [hcinfer()].
#' @param ... Unused.
#'
#' @return An object of class `summary_hcinfer`.
#'
#' @export
summary.hcinfer <- function(object, ...) {
  check_dots_empty(list(...))

  structure(
    list(
      call = object$call,
      model_call = object$model_call,
      model_formula = object$model_formula,
      method = object$label,
      type = object$type,
      alpha = object$alpha,
      confidence_level = object$confidence_level,
      critical_value = object$critical_value,
      n = object$n,
      p = object$p,
      residual_df = object$residual_df,
      method_params = object$method_params,
      leverage_summary = numeric_summary(object$leverage),
      max_leverage = max_diagnostic(object$leverage, object$observation),
      weights_summary = numeric_summary(object$weights),
      max_weight = max_diagnostic(object$weights, object$observation),
      tests = object$table
    ),
    class = "summary_hcinfer"
  )
}

#' Summarize heteroskedasticity-consistent covariance objects
#'
#' @description
#' Builds a detailed summary for an object returned by [vcov_hc()].
#'
#' @param object An object returned by [vcov_hc()].
#' @param ... Unused.
#'
#' @return An object of class `summary_hcinfer_vcov`.
#'
#' @export
summary.hcinfer_vcov <- function(object, ...) {
  check_dots_empty(list(...))

  structure(
    list(
      call = object$call,
      model_call = object$model_call,
      model_formula = object$model_formula,
      method = object$label,
      type = object$type,
      n = object$n,
      p = object$p,
      residual_df = object$residual_df,
      method_params = object$method_params,
      leverage_summary = numeric_summary(object$leverage),
      max_leverage = max_diagnostic(object$leverage, object$observation),
      weights_summary = numeric_summary(object$weights),
      max_weight = max_diagnostic(object$weights, object$observation)
    ),
    class = "summary_hcinfer_vcov"
  )
}

print_method_params <- function(params, type) {
  if (length(params) == 0) {
    cli::cli_text("No additional method parameters.")
    return(invisible(NULL))
  }

  params_table <- method_params_display_table(params, type)
  cli_print_table(params_table, n = Inf, width = Inf)
}

cli_print_table <- function(x, ...) {
  lines <- utils::capture.output(print(x, ...))
  cli::cli_verbatim(lines)
  invisible(x)
}

print_leverage_diagnostics <- function(x) {
  cli_print_table(summary_display_table(x$leverage_summary), n = Inf, width = Inf)

  max_leverage_observation <- x$max_leverage$observation[[1]]
  max_leverage_index <- x$max_leverage$index[[1]]
  max_leverage_value <- x$max_leverage$value[[1]]
  average_leverage <- x$p / x$n
  concentration <- max_leverage_value / average_leverage

  cli::cli_text("Maximum leverage: observation {max_leverage_observation} (index {max_leverage_index}), value {formatC(max_leverage_value, digits = 4, format = 'f')}")
  cli::cli_text("Average leverage: {formatC(average_leverage, digits = 4, format = 'f')}")
  cli::cli_text("Concentration: {format_multiplier(concentration)} average leverage")
}

print_weight_diagnostics <- function(x) {
  cli_print_table(summary_display_table(x$weights_summary), n = Inf, width = Inf)

  max_weight_observation <- x$max_weight$observation[[1]]
  max_weight_index <- x$max_weight$index[[1]]
  max_weight_value <- x$max_weight$value[[1]]
  median_weight <- x$weights_summary$median[[1]]
  concentration <- max_weight_value / median_weight

  cli::cli_text("Maximum weight: observation {max_weight_observation} (index {max_weight_index}), value {formatC(max_weight_value, digits = 4, format = 'f')}")
  cli::cli_text("Median weight: {formatC(median_weight, digits = 4, format = 'f')}")
  cli::cli_text("Concentration: {format_multiplier(concentration)} median weight")
}

#' @export
print.summary_hcinfer <- function(x, ...) {
  check_dots_empty(list(...))

  title <- output_label("tests", paste(x$method, "robust inference summary"))
  cli::cli_h1(title)

  cli::cli_h2(output_label("model", "Model"))
  cli::cli_text("Formula: {.code {format_formula(x$model_formula)}}")
  cli::cli_text("Observations: {x$n} | Parameters: {x$p} | Residual df: {x$residual_df}")

  cli::cli_h2(output_label("covariance", "Robust covariance"))
  cli::cli_text("Estimator: {x$method}")
  cli::cli_text("Confidence level: {format_percent(x$confidence_level)} | Normal critical value: {formatC(x$critical_value, digits = 4, format = 'f')}")
  cli::cli_text("Tests are two-sided normal Wald tests, one coefficient at a time.")
  cli::cli_text("Test results use alpha = {formatC(x$alpha, digits = 3, format = 'f')}.")

  cli::cli_h2(output_label("leverage", "Leverage diagnostics"))
  print_leverage_diagnostics(x)

  cli::cli_h2(output_label("weights", "Robust weights"))
  print_weight_diagnostics(x)

  cli::cli_h2(output_label("parameters", "Method parameters"))
  print_method_params(x$method_params, x$type)
  cli::cli_text("")

  cli::cli_h2(output_label("tests", "Coefficient tests"))
  cli_print_table(coefficient_display_table(x$tests, x$alpha), n = Inf, width = Inf)
  cli::cli_text("")

  cli::cli_h2(output_label("intervals", "Confidence intervals"))
  intervals <- tibble::tibble(
    term = x$tests$term,
    null_value = format_number(x$tests$null_value),
    interval = format_interval(x$tests$conf_low, x$tests$conf_high),
    interpretation = format_interval_check(
      x$tests$conf_low,
      x$tests$conf_high,
      x$tests$null_value
    )
  )
  cli_print_table(intervals, n = Inf, width = Inf)

  cli::cli_text(output_label("interpretation", "test_result is based on p_value < alpha. Do not reject H0 does not mean that H0 is true."))

  invisible(x)
}

#' @export
print.summary_hcinfer_vcov <- function(x, ...) {
  check_dots_empty(list(...))

  title <- output_label("covariance", paste(x$method, "robust covariance summary"))
  cli::cli_h1(title)

  cli::cli_h2(output_label("model", "Model"))
  cli::cli_text("Formula: {.code {format_formula(x$model_formula)}}")
  cli::cli_text("Observations: {x$n} | Parameters: {x$p} | Residual df: {x$residual_df}")

  cli::cli_h2(output_label("leverage", "Leverage diagnostics"))
  print_leverage_diagnostics(x)

  cli::cli_h2(output_label("weights", "Robust weights"))
  print_weight_diagnostics(x)

  cli::cli_h2(output_label("parameters", "Method parameters"))
  print_method_params(x$method_params, x$type)

  invisible(x)
}
