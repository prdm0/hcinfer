bias_correction <- -digamma(0.5) - log(2)
log_chisq1_variance <- pi^2 / 2

# Scale-invariant profile-score tolerance for accepting a stationary ML fit.
# Calibrated on real fits: observed stationary fits settle between about 1e-8
# and ~1.5e-3 under optim's default BFGS reltol. The largest observed value is
# for PublicSchools2 with a dispersion model on income alone (score 1.45e-3);
# its logLik matches a tight-reltol local fit to 5e-6. Nonstationary optim
# code-0 points sit near 1.6 to 1.8. The tolerance 1e-2 is about 7 times above
# the largest accepted stationary fit and about 160 times below the failure
# regime, so it accepts flat, poorly scaled stationary fits while rejecting a
# crippled optimizer such as control = list(reltol = 10).
gls_mult_score_tolerance <- 1e-2

gls_mult_validate_core <- function(
  y,
  X,
  Z,
  estimator,
  ols_residuals,
  control,
  call = rlang::caller_env()
) {
  if (!is.numeric(y) || !is.null(dim(y)) || length(y) == 0L) {
    cli::cli_abort(
      "{.arg y} must be a nonempty numeric response vector.",
      call = call
    )
  }
  if (!is.matrix(X) || !is.numeric(X) || ncol(X) == 0L) {
    cli::cli_abort(
      "{.arg X} must be a nonempty numeric model matrix.",
      call = call
    )
  }
  if (!is.matrix(Z) || !is.numeric(Z) || ncol(Z) == 0L) {
    cli::cli_abort(
      "{.arg Z} must be a nonempty numeric dispersion model matrix.",
      call = call
    )
  }
  if (any(!is.finite(y)) || any(!is.finite(X)) || any(!is.finite(Z))) {
    cli::cli_abort(
      "The response and both model matrices must contain only finite values.",
      call = call
    )
  }

  n <- length(y)
  p <- ncol(X)
  q <- ncol(Z)
  if (nrow(X) != n || nrow(Z) != n) {
    cli::cli_abort(
      c(
        "The response and model matrices must describe the same observations.",
        "x" = "Lengths are n(y) = {n}, nrow(X) = {nrow(X)}, and nrow(Z) = {nrow(Z)}."
      ),
      call = call
    )
  }

  x_qr <- qr(X)
  if (x_qr$rank != p) {
    cli::cli_abort(
      c(
        "The mean model matrix must have full column rank.",
        "x" = "Its rank is {x_qr$rank}, but it has {p} columns."
      ),
      call = call
    )
  }
  if (p >= n) {
    cli::cli_abort(
      c(
        "The mean model must satisfy {.code p < n}.",
        "x" = "The model has n = {n} observations and p = {p} parameters."
      ),
      call = call
    )
  }

  z_qr <- qr(Z)
  if (z_qr$rank != q) {
    cli::cli_abort(
      c(
        "The dispersion model matrix must have full column rank.",
        "x" = "Its rank is {z_qr$rank}, but it has {q} columns."
      ),
      call = call
    )
  }
  if (q >= n) {
    cli::cli_abort(
      c(
        "The dispersion model must satisfy {.code q < n}.",
        "x" = "The model has n = {n} observations and q = {q} parameters."
      ),
      call = call
    )
  }

  intercept_column <- which(vapply(
    seq_len(q),
    function(j) all(Z[, j] == 1),
    logical(1)
  ))
  if (length(intercept_column) != 1L) {
    cli::cli_abort(
      c(
        "The dispersion model needs exactly one all-ones intercept column.",
        "i" = "Include one intercept so the Harvey bias correction is well defined."
      ),
      call = call
    )
  }

  if (
    !is.numeric(ols_residuals) ||
      length(ols_residuals) != n ||
      any(!is.finite(ols_residuals)) ||
      any(ols_residuals == 0)
  ) {
    cli::cli_abort(
      c(
        "OLS residuals must be finite and nonzero.",
        "i" = "The auxiliary response {.code log(residual^2)} is undefined otherwise."
      ),
      call = call
    )
  }
  if (
    !is.character(estimator) ||
      length(estimator) != 1L ||
      !estimator %in% c("ml", "two_step")
  ) {
    cli::cli_abort(
      c(
        "Unknown estimator {.val {estimator}}.",
        "i" = "Use {.val ml} or {.val two_step}."
      ),
      call = call
    )
  }
  if (!is.list(control)) {
    abort_bad_argument(
      "control",
      "It must be a list of arguments for stats::optim().",
      call = call
    )
  }

  z_chol <- tryCatch(chol(crossprod(Z)), error = identity)
  if (inherits(z_chol, "error")) {
    cli::cli_abort(
      c(
        "The dispersion cross-product is not numerically positive definite.",
        "i" = "Check whether the dispersion model matrix is ill-conditioned."
      ),
      parent = z_chol,
      call = call
    )
  }

  list(
    n = n,
    p = p,
    q = q,
    intercept_column = intercept_column,
    z_qr = z_qr,
    z_chol = z_chol
  )
}

gls_mult_weighted_solve <- function(
  y,
  X,
  Z,
  variance_coefficients,
  strict = TRUE,
  call = rlang::caller_env()
) {
  eta <- drop(Z %*% variance_coefficients)
  if (length(eta) != length(y) || any(!is.finite(eta))) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      "The fitted log-variances must be finite.",
      call = call
    )
  }

  center <- mean(eta)
  scaled_weights <- exp(center - eta)
  if (
    !is.finite(center) ||
      any(!is.finite(scaled_weights)) ||
      any(scaled_weights <= 0)
  ) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      c(
        "The centered GLS weights must be positive and finite.",
        "i" = "The fitted log-variances are outside the representable numeric range."
      ),
      call = call
    )
  }

  weighted_X <- scaled_weights * X
  weighted_crossprod <- crossprod(X, weighted_X)
  weighted_rhs <- drop(crossprod(X, scaled_weights * y))
  if (any(!is.finite(weighted_crossprod)) || any(!is.finite(weighted_rhs))) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      "The weighted normal equations must contain only finite values.",
      call = call
    )
  }

  chol_factor <- tryCatch(chol(weighted_crossprod), error = identity)
  if (inherits(chol_factor, "error")) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      c(
        "The weighted cross-product is not numerically positive definite.",
        "i" = "Check the mean design and the fitted dispersion weights."
      ),
      parent = chol_factor,
      call = call
    )
  }

  beta <- drop(chol_solve(chol_factor, weighted_rhs))
  covariance_scale <- exp(center)
  beta_cov <- covariance_scale * chol2inv(chol_factor)
  if (
    any(!is.finite(beta)) ||
      !is.finite(covariance_scale) ||
      covariance_scale <= 0 ||
      any(!is.finite(beta_cov))
  ) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      c(
        "The GLS coefficients and covariance must be finite.",
        "i" = "The fitted variances may be outside the representable numeric range."
      ),
      call = call
    )
  }

  list(beta = beta, eta = eta, beta_cov = beta_cov)
}

gls_mult_weighted_residual_squares <- function(
  residuals,
  eta,
  strict = TRUE,
  call = rlang::caller_env()
) {
  if (
    length(residuals) != length(eta) ||
      any(!is.finite(residuals)) ||
      any(!is.finite(eta))
  ) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      "Likelihood residuals and fitted log-variances must be finite and aligned.",
      call = call
    )
  }

  weighted_residual_squares <- numeric(length(residuals))
  nonzero <- residuals != 0
  if (any(nonzero)) {
    log_terms <- 2 * log(abs(residuals[nonzero])) - eta[nonzero]
    log_max <- log(.Machine$double.xmax)
    log_min <- log(.Machine$double.xmin) + log(.Machine$double.eps)
    if (
      any(!is.finite(log_terms)) ||
        any(log_terms > log_max) ||
        any(log_terms < log_min)
    ) {
      if (!strict) {
        return(NULL)
      }
      cli::cli_abort(
        c(
          "Weighted squared residuals are outside the representable numeric range.",
          "i" = "Rescale the response or dispersion regressors."
        ),
        call = call
      )
    }
    weighted_residual_squares[nonzero] <- exp(log_terms)
  }

  if (
    any(!is.finite(weighted_residual_squares)) ||
      any(weighted_residual_squares < 0)
  ) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      "Weighted squared residuals must be finite and nonnegative.",
      call = call
    )
  }

  weighted_residual_squares
}

gls_mult_profile <- function(
  variance_coefficients,
  y,
  X,
  Z,
  strict = TRUE,
  call = rlang::caller_env()
) {
  wls <- gls_mult_weighted_solve(
    y = y,
    X = X,
    Z = Z,
    variance_coefficients = variance_coefficients,
    strict = strict,
    call = call
  )
  if (is.null(wls)) {
    return(NULL)
  }

  residuals <- y - drop(X %*% wls$beta)
  weighted_residual_squares <- gls_mult_weighted_residual_squares(
    residuals = residuals,
    eta = wls$eta,
    strict = strict,
    call = call
  )
  if (is.null(weighted_residual_squares)) {
    return(NULL)
  }

  eta_sum <- sum(wls$eta)
  weighted_sum <- sum(weighted_residual_squares)
  loglik <- -length(y) / 2 * log(2 * pi) - 0.5 * eta_sum - 0.5 * weighted_sum
  gradient <- 0.5 * drop(crossprod(Z, weighted_residual_squares - 1))
  if (
    !is.finite(eta_sum) ||
      !is.finite(weighted_sum) ||
      !is.finite(loglik) ||
      any(!is.finite(gradient))
  ) {
    if (!strict) {
      return(NULL)
    }
    cli::cli_abort(
      "The profile log-likelihood and gradient must be finite.",
      call = call
    )
  }

  list(loglik = loglik, gradient = gradient, wls = wls)
}

gls_mult_fit <- function(y, X, Z, estimator, method, ols_residuals, control) {
  call <- rlang::caller_env()
  core <- gls_mult_validate_core(
    y = y,
    X = X,
    Z = Z,
    estimator = estimator,
    ols_residuals = ols_residuals,
    control = control,
    call = call
  )

  log_resid_sq <- 2 * log(abs(ols_residuals))
  variance_coefficients_raw <- drop(qr.coef(core$z_qr, log_resid_sq))
  if (any(!is.finite(variance_coefficients_raw))) {
    cli::cli_abort(
      "The auxiliary dispersion coefficients must be finite.",
      call = call
    )
  }
  variance_coefficients_corrected <- variance_coefficients_raw
  variance_coefficients_corrected[core$intercept_column] <-
    variance_coefficients_corrected[core$intercept_column] + bias_correction

  variance_vcov_two_step <- log_chisq1_variance * chol2inv(core$z_chol)

  if (estimator == "two_step") {
    final_profile <- gls_mult_weighted_solve(
      y = y,
      X = X,
      Z = Z,
      variance_coefficients = variance_coefficients_corrected,
      call = call
    )
    variance_coefficients <- variance_coefficients_corrected
    variance_vcov <- variance_vcov_two_step
    loglik <- NULL
    convergence <- NULL
  } else {
    if (!is.null(control$fnscale)) {
      if (
        !is.numeric(control$fnscale) ||
          length(control$fnscale) != 1L ||
          !is.finite(control$fnscale) ||
          control$fnscale <= 0
      ) {
        cli::cli_abort(
          c(
            "`control$fnscale` must be one finite positive number.",
            "i" = "`gls_mult()` already minimizes the negative profile log-likelihood."
          ),
          call = call
        )
      }
    }

    neg_loglik <- function(a) {
      profile <- gls_mult_profile(a, y, X, Z, strict = FALSE, call = call)
      if (is.null(profile)) Inf else -profile$loglik
    }
    neg_gradient <- function(a) {
      profile <- gls_mult_profile(a, y, X, Z, strict = FALSE, call = call)
      if (is.null(profile)) numeric(length(a)) else -profile$gradient
    }

    if (!is.null(control$maxit)) {
      control$maxit <- check_count(control$maxit, "control$maxit", call = call)
    }

    optimization <- tryCatch(
      stats::optim(
        par = variance_coefficients_corrected,
        fn = neg_loglik,
        gr = neg_gradient,
        method = method,
        control = control
      ),
      error = identity
    )
    if (inherits(optimization, "error")) {
      cli::cli_abort(
        c(
          "Maximum likelihood optimization failed.",
          "i" = "Adjust {.arg control} only after checking the model scaling."
        ),
        parent = optimization,
        call = call
      )
    }
    if (optimization$convergence != 0L) {
      details <- c(
        "Maximum likelihood optimization did not converge.",
        "x" = "stats::optim() returned convergence code {optimization$convergence}."
      )
      if (!is.null(optimization$message) && nzchar(optimization$message)) {
        details <- c(details, "i" = "Optimizer message: {optimization$message}")
      }
      cli::cli_abort(details, call = call)
    }
    if (!is.finite(optimization$value) || any(!is.finite(optimization$par))) {
      cli::cli_abort(
        "The optimized negative profile log-likelihood must be finite.",
        call = call
      )
    }

    final_evaluation <- gls_mult_profile(
      variance_coefficients = optimization$par,
      y = y,
      X = X,
      Z = Z,
      strict = TRUE,
      call = call
    )
    gradient_norm <- sqrt(sum((-final_evaluation$gradient)^2))
    if (!is.finite(gradient_norm)) {
      cli::cli_abort(
        "The maximum likelihood gradient norm must be finite.",
        call = call
      )
    }

    score_norm <- sqrt(drop(crossprod(
      final_evaluation$gradient,
      chol_solve(core$z_chol, final_evaluation$gradient)
    )))
    if (!is.finite(score_norm) || score_norm > gls_mult_score_tolerance) {
      cli::cli_abort(
        c(
          "Maximum likelihood optimization did not reach a stationary point.",
          "x" = "The scale-invariant score norm is {.val {score_norm}}, above the tolerance {.val {gls_mult_score_tolerance}}.",
          "i" = "Increase {.code control$maxit} or tighten {.code control$reltol}, and check the model scaling."
        ),
        call = call
      )
    }

    final_profile <- final_evaluation$wls
    variance_coefficients <- optimization$par
    variance_vcov <- 2 * chol2inv(core$z_chol)
    loglik <- -optimization$value
    convergence <- list(
      code = optimization$convergence,
      iterations = optimization$counts,
      score_norm = score_norm,
      gradient_norm = gradient_norm
    )
  }

  beta <- final_profile$beta
  eta <- final_profile$eta
  beta_cov <- (final_profile$beta_cov + t(final_profile$beta_cov)) / 2
  variance_vcov <- (variance_vcov + t(variance_vcov)) / 2
  fitted <- drop(X %*% beta)
  residuals <- y - fitted
  fitted_variances <- exp(eta)
  weights <- exp(-eta)

  if (any(!is.finite(fitted)) || any(!is.finite(residuals))) {
    cli::cli_abort(
      "GLS fitted values and residuals must be finite.",
      call = call
    )
  }
  if (
    any(!is.finite(fitted_variances)) ||
      any(fitted_variances <= 0) ||
      any(!is.finite(weights)) ||
      any(weights <= 0)
  ) {
    cli::cli_abort(
      c(
        "Fitted variances and GLS weights must be positive and finite.",
        "i" = "The fitted log-variances are outside the representable numeric range."
      ),
      call = call
    )
  }
  if (any(!is.finite(diag(beta_cov))) || any(diag(beta_cov) <= 0)) {
    cli::cli_abort(
      "Model-based coefficient variances must be positive and finite.",
      call = call
    )
  }
  if (any(!is.finite(diag(variance_vcov))) || any(diag(variance_vcov) <= 0)) {
    cli::cli_abort(
      "Dispersion-coefficient variances must be positive and finite.",
      call = call
    )
  }

  result <- list(
    n = core$n,
    p = core$p,
    q = core$q,
    beta = beta,
    beta_cov = beta_cov,
    variance_coefficients = variance_coefficients,
    variance_coefficients_raw = variance_coefficients_raw,
    variance_coefficients_corrected = variance_coefficients_corrected,
    variance_vcov = variance_vcov,
    fitted = fitted,
    residuals = residuals,
    fitted_variances = fitted_variances,
    weights = weights,
    eta = eta
  )
  if (estimator == "ml") {
    result$loglik <- loglik
    result$convergence <- convergence
  }

  result
}

gls_mult_variance_matrix <- function(
  object,
  model_frame,
  variance,
  call = rlang::caller_env()
) {
  if (!inherits(variance, "formula") || length(variance) != 2L) {
    abort_bad_argument(
      "variance",
      "It must be NULL or a one-sided formula.",
      call = call
    )
  }

  estimation_rows <- row.names(model_frame)
  if (
    is.null(estimation_rows) ||
      anyNA(estimation_rows) ||
      anyDuplicated(estimation_rows)
  ) {
    cli::cli_abort(
      c(
        "The estimation sample needs unique row names.",
        "i" = "Unique row names are required to align the mean and dispersion models."
      ),
      call = call
    )
  }

  build_frame <- function(data) {
    stats::model.frame(
      formula = variance,
      data = data,
      na.action = stats::na.pass,
      drop.unused.levels = TRUE
    )
  }

  variance_variables <- all.vars(variance)
  uses_retained_data <- all(variance_variables %in% names(model_frame))
  if (uses_retained_data) {
    variance_frame <- tryCatch(build_frame(model_frame), error = identity)
    if (inherits(variance_frame, "error")) {
      cli::cli_abort(
        c(
          "The dispersion model frame could not be constructed.",
          "i" = "Check the variables and transformations in {.arg variance}."
        ),
        parent = variance_frame,
        call = call
      )
    }
  } else {
    model_call <- stats::getCall(object)
    data_expression <- model_call$data
    if (is.null(data_expression)) {
      missing_variables <- setdiff(variance_variables, names(model_frame))
      cli::cli_abort(
        c(
          "The dispersion regressors could not be recovered.",
          "x" = "Not retained in the mean model frame: {.val {missing_variables}}.",
          "i" = "Refit {.fn stats::lm} with an accessible {.arg data} argument."
        ),
        call = call
      )
    }

    formula_environment <- environment(stats::formula(object))
    source_data <- tryCatch(
      eval(data_expression, envir = formula_environment),
      error = identity
    )
    if (inherits(source_data, "error")) {
      cli::cli_abort(
        c(
          "The original data for the mean model could not be recovered.",
          "i" = "Refit {.fn stats::lm} with the data available in the formula environment."
        ),
        parent = source_data,
        call = call
      )
    }

    source_variable_names <- if (is.environment(source_data)) {
      ls(envir = source_data, all.names = TRUE)
    } else {
      names(source_data)
    }
    if (is.null(source_variable_names)) {
      source_variable_names <- colnames(source_data)
    }
    if (is.null(source_variable_names)) {
      source_variable_names <- character()
    }
    missing_source_variables <- setdiff(
      variance_variables,
      source_variable_names
    )
    if (length(missing_source_variables) > 0L) {
      cli::cli_abort(
        c(
          "The original mean-model data do not contain all dispersion regressors.",
          "x" = "Missing variable{?s}: {.val {missing_source_variables}}.",
          "i" = "Include every dispersion regressor in the data used by {.fn stats::lm}."
        ),
        call = call
      )
    }

    variance_frame <- tryCatch(build_frame(source_data), error = identity)
    if (inherits(variance_frame, "error")) {
      cli::cli_abort(
        c(
          "The dispersion model frame could not be constructed.",
          "i" = "Check the variables and transformations in {.arg variance}."
        ),
        parent = variance_frame,
        call = call
      )
    }

    source_rows <- row.names(variance_frame)
    if (
      is.null(source_rows) || anyNA(source_rows) || anyDuplicated(source_rows)
    ) {
      cli::cli_abort(
        c(
          "The dispersion data need unique row names.",
          "i" = "Unique row names are required to recover the estimation sample."
        ),
        call = call
      )
    }

    row_index <- match(estimation_rows, source_rows)
    if (anyNA(row_index)) {
      missing_rows <- estimation_rows[is.na(row_index)]
      cli::cli_abort(
        c(
          "The dispersion data do not contain the complete estimation sample.",
          "x" = "Missing row{?s}: {.val {missing_rows}}.",
          "i" = "Refit the mean model and dispersion model from the same data source."
        ),
        call = call
      )
    }
    variance_frame <- variance_frame[row_index, , drop = FALSE]
  }

  if (
    nrow(variance_frame) != nrow(model_frame) ||
      !identical(row.names(variance_frame), estimation_rows)
  ) {
    cli::cli_abort(
      c(
        "The mean and dispersion model frames are not row-aligned.",
        "i" = "The dispersion model must use exactly the mean-model estimation sample."
      ),
      call = call
    )
  }
  variance_frame <- base::droplevels(variance_frame)

  Z <- tryCatch(
    stats::model.matrix(variance, data = variance_frame),
    error = identity
  )
  if (inherits(Z, "error")) {
    cli::cli_abort(
      c(
        "The dispersion model matrix could not be constructed.",
        "i" = "Check the contrasts and terms in {.arg variance}."
      ),
      parent = Z,
      call = call
    )
  }
  if (
    nrow(Z) != nrow(model_frame) ||
      !identical(row.names(Z), estimation_rows)
  ) {
    cli::cli_abort(
      c(
        "The dispersion model matrix changed the estimation sample.",
        "i" = "Missing values and unresolved rows are not silently removed."
      ),
      call = call
    )
  }
  if (any(!is.finite(Z))) {
    cli::cli_abort(
      c(
        "The dispersion model matrix must contain only finite values.",
        "i" = "Missing and nonfinite dispersion regressors are not supported."
      ),
      call = call
    )
  }

  Z
}

#' Feasible GLS under multiplicative heteroskedasticity
#'
#' @description
#' Fits a linear mean model by feasible generalized least squares when the
#' conditional variance is modelled as an exponential function of observed
#' dispersion regressors. Both Harvey's two-step estimator and full Gaussian
#' maximum likelihood are available. The method complements HC covariance
#' inference by making an explicit, testable variance-model assumption.
#'
#' @details
#' ## Model
#'
#' Let the mean model be
#'
#' \deqn{y = X\beta + e,}
#'
#' where \eqn{X} is an \eqn{n \times p} full-rank matrix with \eqn{p < n}.
#' The multiplicative variance model is
#'
#' \deqn{e_t = \sigma_t\varepsilon_t,\qquad
#' \varepsilon_t \stackrel{\mathrm{iid}}{\sim} N(0,1),\qquad
#' \sigma_t^2 = \exp(\eta_t),\qquad \eta_t = z_t^\top\gamma,}
#'
#' where \eqn{Z} is an \eqn{n \times q} full-rank matrix with \eqn{q < n},
#' \eqn{\gamma} is the dispersion coefficient vector, and \eqn{\eta_t} is the
#' fitted log-variance. Thus \eqn{\exp(\eta_t)} has squared response units,
#' whereas \eqn{\exp(\eta_t/2)} is the conditional standard deviation in
#' response units. The mean and dispersion coefficients remain distinct
#' parameter blocks even when `variance = NULL` makes \eqn{Z = X}.
#'
#' The dispersion model must contain exactly one all-ones intercept column.
#' This requirement makes the two-step intercept correction unambiguous.
#' A custom one-sided `variance` formula may use variables outside the mean
#' formula. Such variables are recovered from the original `lm` data and
#' aligned by the exact rows used to estimate the mean model.
#'
#' ## Two-step estimator
#'
#' With `estimator = "two_step"`, the function first regresses
#' \eqn{\log(\hat e_t^2)} on \eqn{Z}, where \eqn{\hat e_t} are the OLS
#' residuals. If \eqn{\widetilde\gamma} denotes this raw auxiliary estimate,
#' the intercept is corrected as
#'
#' \deqn{\widehat\gamma = \widetilde\gamma + c\,\iota,\qquad
#' c = -\operatorname{digamma}(1/2) - \log(2),}
#'
#' where \eqn{\iota} is the unit vector that selects the dispersion intercept.
#' The constant is approximately 1.270362845 because
#' \eqn{E\{\log(\varepsilon_t^2)\} = \operatorname{digamma}(1/2) + \log(2)
#' = -c} for a standard normal error. The resulting weights are
#' \eqn{\widehat w_t = \exp(-z_t^\top\widehat\gamma)}, collected in the
#' diagonal weight matrix
#' \eqn{\widehat W = \operatorname{diag}\{\exp(-\eta_1),\ldots,\exp(-\eta_n)\}},
#' and the feasible GLS estimate is obtained from the weighted normal
#' equations. Multiplying every inverse-variance weight by the same positive
#' constant leaves the GLS coefficient estimate unchanged. The raw and
#' corrected auxiliary estimates are stored in `variance_coefficients_raw` and
#' `variance_coefficients_corrected`.
#'
#' The asymptotic normal-theory covariance approximation for the auxiliary
#' \eqn{\log(\chi_1^2)} regression is
#'
#' \deqn{\frac{\pi^2}{2}(Z^\top Z)^{-1},}
#'
#' because \eqn{\pi^2/2 = \operatorname{trigamma}(1/2) =
#' \operatorname{Var}\{\log(\varepsilon_t^2)\}} under normality. The intercept
#' correction centers this auxiliary error, but it does not remove
#' finite-sample effects from using OLS residuals in place of the errors.
#'
#' The reported mean covariance is the model-based plug-in
#' \eqn{(X^\top\widehat W X)^{-1}}, which treats the estimated weights as known
#' and does not propagate the sampling variability of \eqn{\widehat\gamma}, the
#' same convention adopted by Cribari-Neto and Pereira (2019). The Gaussian
#' log-likelihood at a two-step estimate is not maximized, so two-step objects
#' do not support [logLik()], [AIC()], or [BIC()].
#'
#' ## Maximum likelihood
#'
#' With the default `estimator = "ml"`, the corrected two-step estimate
#' initializes optimization of the Gaussian log-likelihood by the algorithm
#' chosen with `method` (BFGS by default). The joint log-likelihood
#' of the mean and dispersion blocks is
#'
#' \deqn{\ell(\beta,\gamma) =
#' -\frac{n}{2}\log(2\pi)
#' -\frac{1}{2}\sum_t z_t^\top\gamma
#' -\frac{1}{2}\sum_t
#' \exp(-z_t^\top\gamma)(y_t-x_t^\top\beta)^2.}
#'
#' For every trial value of \eqn{\gamma}, \eqn{\beta} is profiled out by
#' weighted least squares, yielding \eqn{\widehat\beta(\gamma)}, and the chosen
#' optimizer maximizes the resulting profile log-likelihood
#' \eqn{\ell_p(\gamma) = \ell(\widehat\beta(\gamma),\gamma)} through
#' [stats::optim()], using the analytic profile gradient when the algorithm is
#' gradient based. The asymptotic expected information has
#' zero cross-information between \eqn{\beta} and \eqn{\gamma}, with blocks
#'
#' \deqn{\mathcal I_{\beta\beta}=X^\top W X,\qquad
#' \mathcal I_{\gamma\gamma}=\frac{1}{2}Z^\top Z.}
#'
#' Its inverse gives the reported asymptotic dispersion covariance
#' \eqn{2(Z^\top Z)^{-1}} and the model-based mean plug-in covariance
#' \eqn{(X^\top\widehat W X)^{-1}}, which treats the estimated weights as known.
#'
#' For an accepted maximum likelihood fit, [logLik()] returns the Gaussian
#' log-likelihood evaluated at the accepted local solution, so the default
#' [AIC()] and [BIC()] methods work without package-specific
#' information-criterion methods. Their likelihood degrees of freedom equal
#' \eqn{p + q}, and comparisons require competing fits to have reached
#' comparable likelihood solutions. With an intercept-only dispersion model,
#' `variance = ~ 1`, the fit reduces to the homoskedastic Gaussian linear model
#' and reproduces the `lm` coefficients, log-likelihood, AIC, and BIC.
#'
#' ## Inference and numerical safeguards
#'
#' Mean and dispersion tables use standard-normal Wald reference values.
#' The reported mean covariance is model-based and relies on correct
#' specification of the multiplicative variance model. It is not an HC
#' sandwich covariance, and no robust GLS covariance is computed.
#'
#' For `estimator = "ml"`, a fit is accepted as a locally optimized stationary
#' solution only when [stats::optim()] returns convergence code zero and the
#' scale-invariant profile-score norm
#' \eqn{\sqrt{s(\widehat\gamma)^\top (Z^\top Z)^{-1} s(\widehat\gamma)}}, where
#' \eqn{s(\gamma)} is the profile score, falls below a fixed tolerance. This
#' guard rejects a false convergence report at a nonstationary point, such as
#' one caused by an excessively loose `reltol`, but it does not prove that the
#' accepted solution is a global maximum.
#'
#' Computation uses row-scaled matrices, Cholesky solves, and centered
#' log-variances; it never constructs an \eqn{n \times n} diagonal weight
#' matrix or explicitly inverts a cross-product. The function fails explicitly
#' for rank-deficient designs, missing or nonfinite aligned inputs, zero or
#' nonfinite OLS residuals, an absent dispersion intercept, unrecoverable
#' dispersion rows, nonrepresentable fitted variances or weights, a singular
#' weighted design, or maximum likelihood non-convergence. Weighted, offset,
#' and multivariate `lm` fits are not silently reinterpreted and are rejected.
#'
#' @param object An unweighted, univariate ordinary least squares model fitted
#'   by [stats::lm()] without an offset.
#' @param variance `NULL` to use the mean model matrix for the dispersion model,
#'   or a one-sided formula specifying the dispersion regressors. The formula
#'   must generate exactly one all-ones intercept column.
#' @param estimator Estimator. `"ml"` (default) locally optimizes the Gaussian
#'   profile likelihood; `"two_step"` applies Harvey's corrected auxiliary
#'   regression once.
#' @param method Optimization algorithm passed to [stats::optim()] for the
#'   `"ml"` estimator: one of `"BFGS"` (default), `"Nelder-Mead"`, `"CG"`, or
#'   `"L-BFGS-B"`. It is ignored by `"two_step"`. `"BFGS"` uses the analytic
#'   profile gradient and is recommended; whatever the algorithm, the accepted
#'   fit must pass the stationarity check described in Details.
#' @param alpha Significance level for normal Wald tests. The confidence level
#'   is `1 - alpha`.
#' @param null Null values for mean-coefficient tests. Use one value for all
#'   coefficients or one finite value per mean coefficient.
#' @param control A list passed to [stats::optim()] for maximum likelihood
#'   fitting. It is accepted but not used by the two-step estimator. For
#'   maximum likelihood, `control$maxit` must be a positive integer and a
#'   supplied `control$fnscale` must be one finite positive number. Negative
#'   scaling is invalid because `gls_mult()` already minimizes the negative
#'   profile log-likelihood. The accepted locally optimized stationary fit
#'   must satisfy the scale-invariant score check described in Details. The
#'   optimizer itself is chosen with `method`; `control$method` is rejected.
#' @param ... Unused. Passing arguments raises an error.
#'
#' @return
#' An object of class `gls_mult` and `hcinfer_object`. Important components are:
#' \describe{
#'   \item{`coefficients`, `vcov`}{Mean coefficients and their model-based
#'     covariance matrix.}
#'   \item{`variance_coefficients`, `variance_vcov`}{Dispersion coefficients
#'     and their method-specific covariance matrix.}
#'   \item{`variance_coefficients_raw`,
#'     `variance_coefficients_corrected`}{Raw and intercept-corrected
#'     two-step auxiliary estimates. For maximum likelihood, the corrected
#'     estimate is the optimizer starting value.}
#'   \item{`fitted`, `residuals`}{GLS fitted values and residuals.}
#'   \item{`fitted_variances`, `weights`, `eta`}{Fitted conditional variances
#'     in squared response units, inverse-variance weights, and fitted
#'     log-variances \eqn{\eta_t = z_t^\top\gamma}.}
#'   \item{`table`, `variance_table`}{Normal Wald summaries for the mean and
#'     dispersion parameter blocks.}
#'   \item{`loglik`, `convergence`}{The log-likelihood at the accepted local
#'     solution and optimizer diagnostics, present only for maximum likelihood
#'     fits.}
#'   \item{`df`, `nobs`}{Likelihood parameter count \eqn{p + q} and sample
#'     size.}
#' }
#'
#' @references
#' Harvey, A. C. (1976). Estimating regression models with multiplicative
#' heteroscedasticity. *Econometrica*, 44(3), 461-465.
#' \doi{10.2307/1913974}
#'
#' Cribari-Neto, F. and Pereira, I. F. S. (2019). Testing inference in
#' heteroskedastic linear regressions: a comparison of two alternative
#' approaches. *Journal of Statistical Computation and Simulation*, 89(8),
#' 1437-1465. \doi{10.1080/00949655.2019.1586902}
#'
#' @seealso [hcinfer()] for OLS inference with HC covariance estimators and
#' [vcov_hc()] for the implemented HC covariance matrices.
#' `vignette("hcinfer-gls", package = "hcinfer")` is a didactic guide to
#' feasible GLS under multiplicative heteroskedasticity.
#'
#' @examples
#' schools <- PublicSchools |>
#'   dplyr::mutate(income_scaled = income / 10000)
#' fit <- lm(expenditure ~ income_scaled, data = schools)
#'
#' result <- gls_mult(fit)
#' result
#' summary(result)
#' coef(result)
#' coef(result, model = "dispersion")
#' vcov(result)
#' tests(result)
#' confint(result)
#' logLik(result)
#' AIC(result)
#' BIC(result)
#'
#' two_step <- gls_mult(fit, estimator = "two_step")
#' coef(two_step)
#'
#' nelder_mead <- gls_mult(fit, method = "Nelder-Mead")
#' coef(nelder_mead)
#'
#' @export
gls_mult <- function(
  object,
  variance = NULL,
  estimator = c("ml", "two_step"),
  method = c("BFGS", "Nelder-Mead", "CG", "L-BFGS-B"),
  alpha = 0.05,
  null = 0,
  control = list(),
  ...
) {
  call <- match.call()
  check_lm_object(object)
  if (inherits(object, "mlm")) {
    cli::cli_abort(
      c(
        "Multivariate {.cls mlm} responses are not supported.",
        "i" = "Fit one univariate mean model at a time."
      )
    )
  }

  if (!missing(method) && length(method) == 1L && method %in% c("ml", "two_step")) {
    cli::cli_abort(
      c(
        "`method` now selects the optimizer, not the estimator.",
        "i" = "Use `estimator = \"{method}\"`; `method` must be one of \"BFGS\", \"Nelder-Mead\", \"CG\", or \"L-BFGS-B\"."
      )
    )
  }
  estimator <- match.arg(estimator)
  method <- match.arg(method)
  check_alpha(alpha)
  if (!is.list(control)) {
    abort_bad_argument(
      "control",
      "It must be a list of arguments for stats::optim()."
    )
  }
  if (!is.null(control$method)) {
    cli::cli_abort(
      c(
        "`control$method` is not a valid `stats::optim()` control element.",
        "i" = "Choose the optimizer with the `method` argument; `control` only tunes it (e.g. `maxit`, `reltol`)."
      )
    )
  }
  check_dots_empty(list(...))

  model_frame <- tryCatch(stats::model.frame(object), error = identity)
  if (inherits(model_frame, "error")) {
    cli::cli_abort(
      c(
        "The mean-model estimation frame could not be recovered.",
        "i" = "Refit {.fn stats::lm} with its model data available."
      ),
      parent = model_frame
    )
  }
  if (!is.null(stats::model.offset(model_frame))) {
    cli::cli_abort(
      c(
        "Offset mean models are not supported.",
        "i" = "Fit the mean model without an offset before using {.fn gls_mult}."
      )
    )
  }

  X <- stats::model.matrix(object)
  y <- stats::model.response(model_frame)
  ols_residuals <- object$residuals
  estimation_rows <- row.names(model_frame)
  if (is.null(colnames(X))) {
    cli::cli_abort("The mean model matrix must have named columns.")
  }

  if (is.null(variance)) {
    Z <- X
  } else {
    Z <- gls_mult_variance_matrix(
      object = object,
      model_frame = model_frame,
      variance = variance
    )
  }
  if (is.null(colnames(Z))) {
    cli::cli_abort("The dispersion model matrix must have named columns.")
  }

  fit <- gls_mult_fit(
    y = y,
    X = X,
    Z = Z,
    estimator = estimator,
    method = method,
    ols_residuals = ols_residuals,
    control = control
  )

  terms <- colnames(X)
  variance_terms <- colnames(Z)
  coefficients <- stats::setNames(unname(fit$beta), terms)
  variance_coefficients <- stats::setNames(
    unname(fit$variance_coefficients),
    variance_terms
  )
  variance_coefficients_raw <- stats::setNames(
    unname(fit$variance_coefficients_raw),
    variance_terms
  )
  variance_coefficients_corrected <- stats::setNames(
    unname(fit$variance_coefficients_corrected),
    variance_terms
  )
  coefficient_vcov <- fit$beta_cov
  dimnames(coefficient_vcov) <- list(terms, terms)
  variance_vcov <- fit$variance_vcov
  dimnames(variance_vcov) <- list(variance_terms, variance_terms)

  null <- check_null(null, terms)
  critical_value <- stats::qnorm(1 - alpha / 2)
  std_error <- sqrt(diag(coefficient_vcov))
  if (any(!is.finite(std_error)) || any(std_error <= 0)) {
    cli::cli_abort(
      "Model-based standard errors must be positive and finite."
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

  variance_std_error <- sqrt(diag(variance_vcov))
  if (
    any(!is.finite(variance_std_error)) ||
      any(variance_std_error <= 0)
  ) {
    cli::cli_abort(
      "Dispersion standard errors must be positive and finite."
    )
  }
  variance_z_value <- variance_coefficients / variance_std_error
  variance_p_value <- 2 *
    stats::pnorm(
      abs(variance_z_value),
      lower.tail = FALSE
    )
  variance_table <- tibble::tibble(
    term = variance_terms,
    estimate = unname(variance_coefficients),
    std_error = unname(variance_std_error),
    z_value = unname(variance_z_value),
    p_value = unname(variance_p_value)
  )

  fitted <- stats::setNames(unname(fit$fitted), estimation_rows)
  residuals <- stats::setNames(unname(fit$residuals), estimation_rows)
  fitted_variances <- stats::setNames(
    unname(fit$fitted_variances),
    estimation_rows
  )
  weights <- stats::setNames(unname(fit$weights), estimation_rows)
  eta <- stats::setNames(unname(fit$eta), estimation_rows)

  result <- list(
    call = call,
    model_call = stats::getCall(object),
    model_formula = stats::formula(object),
    variance_formula = variance,
    estimator = estimator,
    vcov_type = "model",
    alpha = alpha,
    confidence_level = 1 - alpha,
    null = null,
    critical_value = critical_value,
    n = fit$n,
    p = fit$p,
    q = fit$q,
    coefficients = coefficients,
    vcov = coefficient_vcov,
    variance_coefficients = variance_coefficients,
    variance_coefficients_raw = variance_coefficients_raw,
    variance_coefficients_corrected = variance_coefficients_corrected,
    variance_vcov = variance_vcov,
    terms = terms,
    variance_terms = variance_terms,
    fitted = fitted,
    residuals = residuals,
    fitted_variances = fitted_variances,
    weights = weights,
    eta = eta,
    df = fit$p + fit$q,
    nobs = fit$n,
    table = table,
    variance_table = variance_table
  )
  if (estimator == "ml") {
    result$loglik <- fit$loglik
    result$convergence <- fit$convergence
    result$method <- method
  }

  structure(result, class = c("gls_mult", "hcinfer_object"))
}

#' Methods for multiplicative heteroskedasticity GLS fits
#'
#' @description
#' Extracts, summarizes, and prints components of an object returned by
#' [gls_mult()]. Mean-model methods use normal Wald inference. The `model`
#' argument selects the mean or dispersion parameter block for [coef()] and
#' [vcov()].
#'
#' @param object,x An object returned by [gls_mult()], or its summary.
#' @param model Parameter block to extract: `"mean"` or `"dispersion"`.
#' @param parm Optional mean-coefficient names or integer positions.
#' @param level Confidence level for mean-coefficient intervals.
#' @param alpha Significance level for mean-coefficient tests.
#' @param ... Unused. Passing arguments raises an error.
#'
#' @return
#' [coef()] returns a named numeric vector; [vcov()] returns a covariance
#' matrix; [confint()] and [tests()] return tibbles; [fitted()] and
#' [residuals()] return named numeric vectors; [nobs()] returns the sample size;
#' and [logLik()] returns a `logLik` object for maximum likelihood fits.
#' [summary()] returns an object of class `summary_gls_mult`, including fitted
#' conditional-variance and standard-deviation summaries in squared response
#' and response units. Print methods return their input invisibly.
#'
#' @name gls_mult-methods
NULL

#' @rdname gls_mult-methods
#' @export
coef.gls_mult <- function(object, model = c("mean", "dispersion"), ...) {
  check_dots_empty(list(...))
  model <- match.arg(model)

  if (model == "mean") {
    object$coefficients
  } else {
    object$variance_coefficients
  }
}

#' @rdname gls_mult-methods
#' @export
vcov.gls_mult <- function(object, model = c("mean", "dispersion"), ...) {
  check_dots_empty(list(...))
  model <- match.arg(model)

  if (model == "mean") {
    object$vcov
  } else {
    object$variance_vcov
  }
}

gls_mult_select_table <- function(table, parm) {
  if (is.numeric(parm)) {
    return(table[parm, , drop = FALSE])
  }
  if (is.character(parm)) {
    missing_terms <- setdiff(parm, table$term)
    if (length(missing_terms) > 0L) {
      cli::cli_abort(
        c(
          "Unknown coefficient name in {.arg parm}.",
          "x" = "Unknown term: {.val {missing_terms}}."
        )
      )
    }
    return(table[match(parm, table$term), , drop = FALSE])
  }

  abort_bad_argument(
    "parm",
    "It must contain coefficient names or positions."
  )
}

#' @rdname gls_mult-methods
#' @export
confint.gls_mult <- function(
  object,
  parm,
  level = object$confidence_level,
  ...
) {
  check_dots_empty(list(...))
  check_alpha(1 - level)

  table <- object$table
  if (!missing(parm)) {
    table <- gls_mult_select_table(table, parm)
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

#' @rdname gls_mult-methods
#' @export
tests.gls_mult <- function(object, parm, alpha = object$alpha, ...) {
  check_dots_empty(list(...))
  check_alpha(alpha)

  table <- object$table
  if (!missing(parm)) {
    table <- gls_mult_select_table(table, parm)
  }

  tibble::tibble(
    term = table$term,
    estimate = table$estimate,
    null_value = table$null_value,
    std_error = table$std_error,
    z_value = table$z_value,
    p_value = table$p_value,
    alpha = alpha,
    reject = table$p_value < alpha
  )
}

#' @rdname gls_mult-methods
#' @exportS3Method stats::nobs
nobs.gls_mult <- function(object, ...) {
  check_dots_empty(list(...))
  object$nobs
}

#' @rdname gls_mult-methods
#' @exportS3Method stats::fitted
fitted.gls_mult <- function(object, ...) {
  check_dots_empty(list(...))
  object$fitted
}

#' @rdname gls_mult-methods
#' @exportS3Method stats::residuals
residuals.gls_mult <- function(object, ...) {
  check_dots_empty(list(...))
  object$residuals
}

#' @rdname gls_mult-methods
#' @exportS3Method stats::logLik
logLik.gls_mult <- function(object, ...) {
  check_dots_empty(list(...))
  if (object$estimator != "ml") {
    cli::cli_abort(
      c(
        "Information criteria require the maximum likelihood fit.",
        "i" = "Refit with {.code gls_mult(..., estimator = \"ml\")} to use {.fn logLik}, {.fn AIC}, and {.fn BIC}."
      )
    )
  }

  structure(
    as.numeric(object$loglik),
    df = object$df,
    nobs = object$nobs,
    class = "logLik"
  )
}

gls_mult_mean_display_table <- function(table, alpha) {
  tibble::tibble(
    term = table$term,
    estimate = format_number(table$estimate),
    model_se = format_number(table$std_error),
    z = format_number(table$z_value),
    p_value = format_p_value(table$p_value),
    test_result = format_test_result(table$p_value, alpha),
    confidence_interval = format_interval(table$conf_low, table$conf_high)
  )
}

gls_mult_variance_display_table <- function(table) {
  tibble::tibble(
    term = table$term,
    estimate = format_number(table$estimate),
    std_error = format_number(table$std_error),
    z = format_number(table$z_value),
    p_value = format_p_value(table$p_value)
  )
}

gls_mult_fitted_scale_display_table <- function(
  variance_summary,
  standard_deviation_summary
) {
  variance_values <- unlist(variance_summary, use.names = TRUE)
  standard_deviation_values <- unlist(
    standard_deviation_summary,
    use.names = TRUE
  )
  tibble::tibble(
    statistic = names(variance_values),
    variance = unname(format_number(variance_values)),
    standard_deviation = unname(format_number(standard_deviation_values))
  )
}

#' @rdname gls_mult-methods
#' @export
print.gls_mult <- function(x, ...) {
  check_dots_empty(list(...))
  print(summary(x))
  invisible(x)
}

#' @rdname gls_mult-methods
#' @export
summary.gls_mult <- function(object, ...) {
  check_dots_empty(list(...))

  result <- list(
    call = object$call,
    model_call = object$model_call,
    model_formula = object$model_formula,
    variance_formula = object$variance_formula,
    estimator = object$estimator,
    vcov_type = object$vcov_type,
    alpha = object$alpha,
    confidence_level = object$confidence_level,
    critical_value = object$critical_value,
    n = object$n,
    p = object$p,
    q = object$q,
    df = object$df,
    tests = object$table,
    variance_tests = object$variance_table,
    fitted_variance_summary = numeric_summary(object$fitted_variances),
    fitted_standard_deviation_summary = numeric_summary(
      sqrt(object$fitted_variances)
    )
  )
  if (object$estimator == "ml") {
    result$loglik <- as.numeric(stats::logLik(object))
    result$aic <- stats::AIC(object)
    result$bic <- stats::BIC(object)
    result$convergence <- object$convergence
    result$method <- object$method
  }

  structure(result, class = "summary_gls_mult")
}

#' @rdname gls_mult-methods
#' @export
print.summary_gls_mult <- function(x, ...) {
  check_dots_empty(list(...))

  method_label <- if (x$estimator == "ml") {
    paste0("Maximum likelihood (", x$method, ")")
  } else {
    "Harvey two-step"
  }
  variance_label <- if (is.null(x$variance_formula)) {
    "Z = X (the mean model matrix)"
  } else {
    format_formula(x$variance_formula)
  }

  cli::cli_h1(output_label(
    "tests",
    "Multiplicative heteroskedasticity FGLS summary"
  ))

  cli::cli_h2(output_label("model", "Mean model"))
  cli::cli_text("Formula: {.code {format_formula(x$model_formula)}}")
  cli::cli_text(
    "Observations: {x$n} | Mean parameters: {x$p} | Dispersion parameters: {x$q}"
  )

  cli::cli_h2(output_label("parameters", "Dispersion model"))
  cli::cli_text("Specification: {.code {variance_label}}")
  cli::cli_text("Fitting method: {method_label}")
  cli::cli_text("Variance function: exp(z' gamma)")

  cli::cli_h2(output_label("covariance", "Model-based inference"))
  cli::cli_text(
    "Confidence level: {format_percent(x$confidence_level)} | Normal critical value: {formatC(x$critical_value, digits = 4, format = 'f')}"
  )
  cli::cli_text(
    "Coefficient covariance: model-based, conditional on a correctly specified variance model."
  )

  cli::cli_h2(output_label("tests", "Mean-coefficient Wald tests"))
  cli_print_table(
    gls_mult_mean_display_table(x$tests, x$alpha),
    n = Inf,
    width = Inf
  )

  cli::cli_h2(output_label("parameters", "Dispersion coefficients"))
  cli_print_table(
    gls_mult_variance_display_table(x$variance_tests),
    n = Inf,
    width = Inf
  )

  cli::cli_h2(output_label(
    "weights",
    "Fitted conditional variance and standard deviation"
  ))
  cli::cli_text(
    "Variance is expressed in squared response units; standard deviation is expressed in response units."
  )
  cli_print_table(
    gls_mult_fitted_scale_display_table(
      x$fitted_variance_summary,
      x$fitted_standard_deviation_summary
    ),
    n = Inf,
    width = Inf
  )

  if (x$estimator == "ml") {
    evaluation_counts <- paste(
      paste0(
        names(x$convergence$iterations),
        " = ",
        unname(x$convergence$iterations)
      ),
      collapse = " | "
    )
    cli::cli_h2(output_label("parameters", "Maximum likelihood"))
    cli::cli_text(
      "logLik: {format_number(x$loglik)} | AIC: {format_number(x$aic)} | BIC: {format_number(x$bic)}"
    )
    cli::cli_text(
      "Convergence code: {x$convergence$code} | {evaluation_counts}"
    )
    cli::cli_text(
      "Score norm (scale-invariant): {format_number(x$convergence$score_norm)} | Gradient norm: {format_number(x$convergence$gradient_norm)}"
    )
  }

  invisible(x)
}
