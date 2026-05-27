model_info_lm <- function(object, call = rlang::caller_env()) {
  check_lm_object(object, call = call)

  x <- stats::model.matrix(object)
  residuals <- stats::residuals(object)
  coefficients <- stats::coef(object)
  leverage <- stats::hatvalues(object)

  n <- nrow(x)
  p <- ncol(x)
  rank <- object$rank

  if (is.null(rank) || rank < p) {
    cli::cli_abort(
      c(
        "The model matrix must have full column rank.",
        "x" = "The fitted model rank is {rank}, but the model has {p} columns."
      ),
      call = call
    )
  }

  if (p >= n) {
    cli::cli_abort(
      c(
        "The fitted model must satisfy {.code p < n}.",
        "x" = "The model has n = {n} observations and p = {p} parameters."
      ),
      call = call
    )
  }

  if (any(!is.finite(coefficients))) {
    cli::cli_abort(
      "All model coefficients must be finite.",
      call = call
    )
  }

  if (any(!is.finite(residuals))) {
    cli::cli_abort(
      "All model residuals must be finite.",
      call = call
    )
  }

  if (any(!is.finite(leverage))) {
    cli::cli_abort(
      "All leverage values must be finite.",
      call = call
    )
  }

  tolerance <- sqrt(.Machine$double.eps)
  if (any(leverage < -tolerance | leverage > 1 + tolerance)) {
    cli::cli_abort(
      c(
        "Leverage values are outside the admissible range.",
        "i" = "Expected values in the interval [0, 1]."
      ),
      call = call
    )
  }

  leverage <- pmin(pmax(leverage, 0), 1)

  if (any(1 - leverage <= .Machine$double.eps)) {
    cli::cli_abort(
      c(
        "At least one leverage value is too close to 1.",
        "i" = "HC leverage corrections require positive {.code 1 - h_t}."
      ),
      call = call
    )
  }

  terms <- names(coefficients)
  if (is.null(terms)) {
    terms <- colnames(x)
  }

  observation <- names(residuals)
  if (is.null(observation)) {
    observation <- as.character(seq_len(n))
  }

  list(
    x = x,
    residuals = residuals,
    coefficients = coefficients,
    leverage = leverage,
    n = n,
    p = p,
    residual_df = n - p,
    terms = terms,
    observation = observation,
    model_call = object$call,
    model_formula = stats::formula(object)
  )
}

chol_solve <- function(chol_factor, b) {
  backsolve(chol_factor, forwardsolve(t(chol_factor), b))
}

robust_vcov_from_weights <- function(x, residuals, weights,
                                     call = rlang::caller_env()) {
  omega <- residuals^2 * weights
  middle <- crossprod(x, x * omega)
  xtx <- crossprod(x)

  chol_factor <- tryCatch(
    chol(xtx),
    error = function(cnd) {
      cli::cli_abort(
        c(
          "The cross-product matrix is not numerically positive definite.",
          "i" = "Check whether the model matrix is ill-conditioned."
        ),
        parent = cnd,
        call = call
      )
    }
  )

  left <- chol_solve(chol_factor, middle)
  psi <- t(chol_solve(chol_factor, t(left)))
  psi <- (psi + t(psi)) / 2

  dimnames(psi) <- list(colnames(x), colnames(x))
  psi
}
