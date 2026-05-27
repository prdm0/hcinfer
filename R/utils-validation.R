abort_bad_argument <- function(arg, message, ..., call = rlang::caller_env()) {
  cli::cli_abort(
    c(
      "Invalid argument {.arg {arg}}.",
      "x" = message
    ),
    ...,
    call = call
  )
}

check_lm_object <- function(object, call = rlang::caller_env()) {
  if (!inherits(object, "lm")) {
    cli::cli_abort(
      c(
        "{.arg object} must be a linear model fitted by {.fn stats::lm}.",
        "x" = "You supplied an object with class {.cls {class(object)}}."
      ),
      call = call
    )
  }

  weights <- stats::weights(object)
  if (!is.null(weights)) {
    cli::cli_abort(
      c(
        "Weighted {.cls lm} objects are not supported.",
        "i" = "The implemented covariance estimators follow the ordinary least squares model."
      ),
      call = call
    )
  }

  invisible(object)
}

check_alpha <- function(alpha, call = rlang::caller_env()) {
  if (!is.numeric(alpha) || length(alpha) != 1 || !is.finite(alpha)) {
    abort_bad_argument("alpha", "It must be one finite number.", call = call)
  }
  if (alpha <= 0 || alpha >= 1) {
    abort_bad_argument("alpha", "It must be strictly between 0 and 1.", call = call)
  }
  invisible(alpha)
}

normalise_hc_type <- function(type, call = rlang::caller_env()) {
  if (!is.character(type) || length(type) != 1 || is.na(type)) {
    abort_bad_argument("type", "It must be one estimator name.", call = call)
  }

  type <- tolower(type)
  valid <- names(hc_type_labels())

  if (!type %in% valid) {
    cli::cli_abort(
      c(
        "Unknown HC estimator {.val {type}}.",
        "i" = "Use one of {.val {valid}}."
      ),
      call = call
    )
  }

  type
}

hc_label <- function(type) {
  unname(hc_type_labels()[[type]])
}

check_scalar_number <- function(x, arg, lower = -Inf, upper = Inf,
                                closed = TRUE,
                                call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x)) {
    abort_bad_argument(arg, "It must be one finite number.", call = call)
  }

  lower_ok <- if (closed) x >= lower else x > lower
  upper_ok <- if (closed) x <= upper else x < upper

  if (!lower_ok || !upper_ok) {
    interval <- if (closed) {
      paste0("[", lower, ", ", upper, "]")
    } else {
      paste0("(", lower, ", ", upper, ")")
    }
    abort_bad_argument(arg, "It must be in the interval {.val {interval}}.", call = call)
  }

  x
}

check_nonnegative_scalar <- function(x, arg, call = rlang::caller_env()) {
  check_scalar_number(x, arg, lower = 0, call = call)
}

check_positive_scalar <- function(x, arg, call = rlang::caller_env()) {
  check_scalar_number(x, arg, lower = 0, closed = FALSE, call = call)
}

check_dots_empty <- function(dots, call = rlang::caller_env()) {
  if (length(dots) > 0) {
    cli::cli_abort(
      c(
        "Unused argument in {.arg ...}.",
        "x" = "Unexpected name: {.arg {names(dots)}}."
      ),
      call = call
    )
  }
}

check_allowed_dots <- function(dots, allowed, call = rlang::caller_env()) {
  bad <- setdiff(names(dots), allowed)
  if (length(bad) > 0 || any(names(dots) == "")) {
    if (any(names(dots) == "")) {
      bad <- c(bad, "<unnamed>")
    }
    cli::cli_abort(
      c(
        "Invalid argument in {.arg ...}.",
        "x" = "Unexpected name: {.arg {bad}}.",
        "i" = "Allowed names: {.arg {allowed}}."
      ),
      call = call
    )
  }
}

check_null <- function(null, terms, call = rlang::caller_env()) {
  p <- length(terms)

  if (!is.numeric(null) || length(null) == 0 || any(!is.finite(null))) {
    abort_bad_argument("null", "It must contain finite numeric values.", call = call)
  }

  if (length(null) == 1) {
    out <- rep(null, p)
    names(out) <- terms
    return(out)
  }

  if (length(null) != p) {
    cli::cli_abort(
      c(
        "{.arg null} must have length 1 or match the number of coefficients.",
        "x" = "{.arg null} has length {length(null)}.",
        "i" = "The model has {p} coefficients."
      ),
      call = call
    )
  }

  if (!is.null(names(null))) {
    missing_terms <- setdiff(terms, names(null))
    extra_terms <- setdiff(names(null), terms)
    if (length(missing_terms) > 0 || length(extra_terms) > 0) {
      cli::cli_abort(
        c(
          "Names in {.arg null} must match model terms.",
          "x" = "Missing term{?s}: {.val {missing_terms}}.",
          "x" = "Extra term{?s}: {.val {extra_terms}}."
        ),
        call = call
      )
    }
    null <- null[terms]
  } else {
    names(null) <- terms
  }

  null
}

format_formula <- function(formula) {
  paste(deparse(formula, width.cutoff = 500), collapse = " ")
}

format_percent <- function(x, digits = 1) {
  paste0(formatC(100 * x, format = "f", digits = digits), "%")
}
