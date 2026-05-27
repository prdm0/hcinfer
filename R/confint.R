#' Confidence intervals for hcinfer objects
#'
#' @description
#' Extracts normal Wald confidence intervals from an [hcinfer()] result. If the
#' requested level differs from the level used to create the object, only the
#' normal critical value and interval endpoints are recomputed.
#'
#' @param object An object returned by [hcinfer()].
#' @param parm Optional coefficient names or positions.
#' @param level Confidence level.
#' @param ... Unused.
#'
#' @return
#' A tibble with columns `term`, `conf_low`, `conf_high`, and `level`.
#'
#' @export
confint.hcinfer <- function(object, parm, level = object$confidence_level, ...) {
  check_dots_empty(list(...))
  check_alpha(1 - level)

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

  if (!isTRUE(all.equal(level, object$confidence_level))) {
    critical_value <- stats::qnorm(1 - (1 - level) / 2)
    table$conf_low <- table$estimate - critical_value * table$std_error
    table$conf_high <- table$estimate + critical_value * table$std_error
  }

  tibble::tibble(
    term = table$term,
    conf_low = table$conf_low,
    conf_high = table$conf_high,
    level = level
  )
}
