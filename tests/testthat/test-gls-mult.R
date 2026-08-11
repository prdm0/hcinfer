test_that("Harvey correction constants use their exact identities", {
  correction <- getFromNamespace("bias_correction", "hcinfer")
  dispersion_variance <- getFromNamespace("log_chisq1_variance", "hcinfer")

  expect_equal(correction, -digamma(0.5) - log(2), tolerance = 1e-15)
  expect_equal(correction, 1.2703628454614777, tolerance = 1e-15)
  expect_equal(dispersion_variance, pi^2 / 2, tolerance = 1e-15)
  expect_equal(dispersion_variance, 4.934802200544679, tolerance = 1e-15)
})

test_that("two-step GLS matches a literal Harvey calculation", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- gls_mult(fit, estimator = "two_step")
  X <- stats::model.matrix(fit)
  y <- stats::model.response(stats::model.frame(fit))
  Z <- X
  log_resid_sq <- 2 * log(abs(stats::residuals(fit)))
  raw <- drop(solve(crossprod(Z), crossprod(Z, log_resid_sq)))
  corrected <- raw
  corrected[1] <- corrected[1] - digamma(0.5) - log(2)
  weights <- exp(-drop(Z %*% corrected))
  W <- diag(weights)
  weighted_crossprod <- t(X) %*% W %*% X
  expected_coefficients <- drop(
    solve(weighted_crossprod, t(X) %*% W %*% y)
  )
  expected_vcov <- solve(weighted_crossprod)

  expect_equal(
    unname(result$coefficients),
    unname(expected_coefficients),
    tolerance = 1e-10
  )
  expect_equal(
    unname(result$vcov),
    unname(expected_vcov),
    tolerance = 1e-10
  )
  expect_equal(
    unname(result$variance_coefficients),
    unname(corrected),
    tolerance = 1e-10
  )
  expect_equal(
    unname(result$variance_coefficients_raw),
    unname(raw),
    tolerance = 1e-10
  )
})

test_that("two-step PublicSchools results retain the prototype anchor", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- gls_mult(fit, estimator = "two_step")

  expect_equal(
    unname(result$coefficients),
    c(-31.7232, 0.0525593),
    tolerance = 1e-3
  )
  expect_equal(
    unname(sqrt(diag(result$vcov))),
    c(55.3349, 0.00801841),
    tolerance = 1e-3
  )
})

test_that("row scaling reproduces diagonal-matrix algebra", {
  X <- cbind(1, c(-2, -0.5, 1, 3))
  weights <- c(0.5, 2, 1.5, 0.75)
  M <- matrix(seq_len(12), nrow = 4)
  values <- c(2, 3, 5, 7)

  expect_equal(
    crossprod(X, weights * X),
    t(X) %*% diag(weights) %*% X,
    tolerance = 1e-15
  )
  expect_equal(values * M, diag(values) %*% M, tolerance = 1e-15)
})

test_that("multivariate profile likelihood and gradient match direct oracles", {
  x <- seq(-1.5, 1.5, length.out = 12)
  X <- cbind("(Intercept)" = 1, x = x)
  Z <- cbind("(Intercept)" = 1, quadratic = x^2)
  y <- 1 + 0.5 * x + sin(seq_along(x)) / 4
  variance_coefficients <- c(-0.2, 0.35)
  profile_likelihood <- getFromNamespace("gls_mult_profile", "hcinfer")

  direct_profile <- function(alpha) {
    eta <- drop(Z %*% alpha)
    weights <- exp(-eta)
    beta <- drop(
      solve(crossprod(X, weights * X), crossprod(X, weights * y))
    )
    residuals <- y - drop(X %*% beta)
    -length(y) /
      2 *
      log(2 * pi) -
      0.5 * sum(eta) -
      0.5 * sum(weights * residuals^2)
  }

  result <- profile_likelihood(variance_coefficients, y, X, Z)
  step <- 1e-6
  finite_difference <- vapply(
    seq_along(variance_coefficients),
    function(index) {
      direction <- numeric(length(variance_coefficients))
      direction[index] <- step
      (direct_profile(variance_coefficients + direction) -
        direct_profile(variance_coefficients - direction)) /
        (2 * step)
    },
    numeric(1)
  )

  expect_equal(
    result$loglik,
    direct_profile(variance_coefficients),
    tolerance = 1e-12
  )
  expect_equal(
    unname(result$gradient),
    unname(finite_difference),
    tolerance = 1e-7
  )
})

test_that("intercept-only ML reproduces the Gaussian lm likelihood", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- gls_mult(fit, variance = ~1, estimator = "ml")

  expect_equal(
    unname(coef(result)),
    unname(coef(fit)),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(logLik(result)),
    as.numeric(logLik(fit)),
    tolerance = 1e-6
  )
  expect_equal(AIC(result), AIC(fit), tolerance = 1e-6)
  expect_equal(BIC(result), BIC(fit), tolerance = 1e-6)
  expect_identical(
    attr(logLik(result), "df"),
    length(coef(fit)) + 1L
  )
})

test_that("ML likelihood exposes parameter count and sample size", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- gls_mult(fit)
  likelihood <- logLik(result)
  expected_p <- ncol(model.matrix(fit))
  expected_q <- ncol(model.matrix(fit))
  expected_n <- nrow(model.frame(fit))
  expected_parameter_count <- expected_p + expected_q

  expect_identical(result$p, expected_p)
  expect_identical(result$q, expected_q)
  expect_identical(attr(likelihood, "df"), expected_parameter_count)
  expect_identical(nobs(result), expected_n)
  expect_equal(
    AIC(result),
    -2 * as.numeric(likelihood) + 2 * expected_parameter_count,
    tolerance = 1e-10
  )
  expect_equal(
    BIC(result),
    -2 * as.numeric(likelihood) + log(expected_n) * expected_parameter_count,
    tolerance = 1e-10
  )
})

test_that("response rescaling preserves the variance-unit identities", {
  schools <- transform(
    PublicSchools2,
    income_scaled = income / 10000,
    expenditure_thousands = expenditure / 1000
  )
  control <- list(reltol = 1e-13, maxit = 10000)
  dollars <- gls_mult(
    lm(expenditure ~ income_scaled + south, data = schools),
    estimator = "ml",
    control = control
  )
  thousands <- gls_mult(
    lm(expenditure_thousands ~ income_scaled + south, data = schools),
    estimator = "ml",
    control = control
  )

  expect_equal(
    unname(coef(thousands)),
    unname(coef(dollars)) / 1000,
    tolerance = 1e-8
  )
  expect_equal(
    unname(vcov(thousands)),
    unname(vcov(dollars)) / 1e6,
    tolerance = 1e-8
  )
  expect_equal(
    unname(thousands$fitted_variances),
    unname(dollars$fitted_variances) / 1e6,
    tolerance = 1e-8
  )
  expect_equal(
    unname(thousands$variance_coefficients[1]),
    unname(dollars$variance_coefficients[1]) - 2 * log(1000),
    tolerance = 1e-8
  )
  expect_equal(
    unname(thousands$variance_coefficients[-1]),
    unname(dollars$variance_coefficients[-1]),
    tolerance = 1e-8
  )
  expect_equal(
    unname(thousands$weights),
    unname(dollars$weights) * 1e6,
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(logLik(thousands)),
    as.numeric(logLik(dollars)) + dollars$n * log(1000),
    tolerance = 1e-8
  )

  for (result in list(dollars, thousands)) {
    expect_equal(
      unname(result$fitted_variances),
      unname(exp(result$eta)),
      tolerance = 1e-12
    )
    expect_equal(
      unname(result$weights * result$fitted_variances),
      rep(1, result$n),
      tolerance = 1e-12
    )
    intercept_score_bound <- 2 *
      sqrt(result$n) *
      result$convergence$score_norm
    standardized_residual_sum <- sum(
      result$residuals^2 / result$fitted_variances
    )
    expect_lte(
      abs(standardized_residual_sum - result$n),
      intercept_score_bound + 1e-10
    )
  }
})

test_that("public GLS methods expose the stored fit and inference", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- gls_mult(fit)
  withr::local_options(
    list(hcinfer.use_emoji = FALSE, cli.num_colors = 1)
  )

  expect_identical(coef(result), result$coefficients)
  expect_identical(
    coef(result, model = "dispersion"),
    result$variance_coefficients
  )
  expect_identical(vcov(result), result$vcov)
  expect_identical(
    vcov(result, model = "dispersion"),
    result$variance_vcov
  )
  expect_identical(fitted(result), result$fitted)
  expect_identical(residuals(result), result$residuals)

  intervals <- confint(result)
  expect_identical(intervals$term, result$table$term)
  expect_equal(intervals$conf_low, result$table$conf_low)
  expect_equal(intervals$conf_high, result$table$conf_high)
  expect_identical(unique(intervals$level), result$confidence_level)

  test_results <- tests(result)
  expect_identical(test_results$term, result$table$term)
  expect_equal(test_results$z_value, result$table$z_value)
  expect_equal(test_results$p_value, result$table$p_value)
  expect_identical(
    test_results$reject,
    result$table$p_value < result$alpha
  )

  result_summary <- summary(result)
  expect_s3_class(result_summary, "summary_gls_mult")
  expect_identical(result_summary$tests, result$table)
  expect_identical(result_summary$variance_tests, result$variance_table)
  expect_identical(
    result_summary$fitted_standard_deviation_summary,
    getFromNamespace("numeric_summary", "hcinfer")(
      sqrt(result$fitted_variances)
    )
  )

  result_output <- capture.output(
    result_return <- print(result),
    type = "message"
  )
  summary_output <- capture.output(
    summary_return <- print(result_summary),
    type = "message"
  )
  expect_gt(length(result_output), 0L)
  expect_gt(length(summary_output), 0L)
  expect_identical(result_return, result)
  expect_identical(summary_return, result_summary)
  plain_summary <- paste(summary_output, collapse = "\n")
  normalized_summary <- gsub("[[:space:]]+", " ", plain_summary)
  expect_match(
    plain_summary,
    "Fitted conditional variance and standard deviation",
    fixed = TRUE
  )
  expect_match(
    normalized_summary,
    paste(
      "Variance is expressed in squared response units;",
      "standard deviation is expressed in response units."
    ),
    fixed = TRUE
  )
  expect_match(plain_summary, "variance", fixed = TRUE)
  expect_match(plain_summary, "standard_deviation", fixed = TRUE)
  expect_match(plain_summary, "exp(z' gamma)", fixed = TRUE)
  expect_no_match(plain_summary, "Fitted variance summary", fixed = TRUE)
  expect_no_match(plain_summary, "exp(z' alpha)", fixed = TRUE)
})

test_that("stored Wald results match independent normal oracles", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  X <- model.matrix(fit)
  y <- model.response(model.frame(fit))
  alpha <- 0.1
  null <- c(-25, 0.04)

  for (estimator in c("ml", "two_step")) {
    result <- gls_mult(fit, estimator = estimator, alpha = alpha, null = null)
    mean_standard_errors <- sqrt(diag(vcov(result)))
    mean_z <- (coef(result) - null) / mean_standard_errors
    mean_p <- 2 * pnorm(abs(mean_z), lower.tail = FALSE)
    critical_value <- qnorm(1 - alpha / 2)

    expect_equal(
      result$table$std_error,
      unname(mean_standard_errors),
      tolerance = 1e-12
    )
    expect_equal(
      result$table$z_value,
      unname(mean_z),
      tolerance = 1e-12
    )
    expect_equal(result$table$p_value, unname(mean_p), tolerance = 1e-12)
    expect_equal(
      result$table$conf_low,
      unname(coef(result) - critical_value * mean_standard_errors),
      tolerance = 1e-12
    )
    expect_equal(
      result$table$conf_high,
      unname(coef(result) + critical_value * mean_standard_errors),
      tolerance = 1e-12
    )

    dispersion_standard_errors <- sqrt(diag(result$variance_vcov))
    dispersion_z <- result$variance_coefficients /
      dispersion_standard_errors
    dispersion_p <- 2 * pnorm(abs(dispersion_z), lower.tail = FALSE)
    expect_equal(
      result$variance_table$std_error,
      unname(dispersion_standard_errors),
      tolerance = 1e-12
    )
    expect_equal(
      result$variance_table$z_value,
      unname(dispersion_z),
      tolerance = 1e-12
    )
    expect_equal(
      result$variance_table$p_value,
      unname(dispersion_p),
      tolerance = 1e-12
    )

    expect_equal(
      unname(fitted(result)),
      unname(drop(X %*% coef(result))),
      tolerance = 1e-12
    )
    expect_equal(
      unname(residuals(result)),
      unname(y - fitted(result)),
      tolerance = 1e-12
    )
  }
})

test_that("dispersion covariance follows the selected fitting method", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  two_step <- gls_mult(fit, estimator = "two_step")
  ml <- gls_mult(fit, estimator = "ml")
  Z <- stats::model.matrix(fit)
  inverse_crossprod <- solve(crossprod(Z))

  expect_equal(
    unname(two_step$variance_vcov),
    unname((pi^2 / 2) * inverse_crossprod),
    tolerance = 1e-10
  )
  expect_equal(
    unname(ml$variance_vcov),
    unname(2 * inverse_crossprod),
    tolerance = 1e-10
  )
  expect_equal(
    unname(two_step$variance_vcov),
    unname((pi^2 / 4) * ml$variance_vcov),
    tolerance = 1e-10
  )
})

test_that("method selects the optimizer while estimator selects the fit", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  withr::local_options(
    list(hcinfer.use_emoji = FALSE, cli.num_colors = 1)
  )

  expect_error(gls_mult(fit, method = "AAS"))
  expect_snapshot(error = TRUE, gls_mult(fit, method = "ml"))
  expect_snapshot(error = TRUE, gls_mult(fit, control = list(method = "AAS")))

  default_fit <- gls_mult(fit)
  expect_identical(default_fit$estimator, "ml")
  expect_identical(default_fit$method, "BFGS")

  control <- list(reltol = 1e-13, maxit = 10000)
  bfgs <- gls_mult(fit, control = control)
  nelder_mead <- gls_mult(fit, method = "Nelder-Mead", control = control)
  expect_identical(nelder_mead$estimator, "ml")
  expect_identical(nelder_mead$method, "Nelder-Mead")
  expect_equal(coef(nelder_mead), coef(bfgs), tolerance = 1e-4)

  two_step <- gls_mult(fit, estimator = "two_step")
  expect_identical(two_step$estimator, "two_step")
  expect_null(two_step$method)
})

test_that("information criteria reject a two-step fit", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- gls_mult(fit, estimator = "two_step")

  expect_snapshot(error = TRUE, logLik(result))
  expect_snapshot(error = TRUE, AIC(result))
})

test_that("dispersion formulas preserve the mean estimation sample", {
  schools <- transform(
    PublicSchools,
    dispersion_income = log(income)
  )
  fit <- lm(expenditure ~ income, data = schools)
  outside <- gls_mult(
    fit,
    variance = ~dispersion_income,
    estimator = "two_step"
  )
  estimation_rows <- row.names(model.frame(fit))
  expected_Z <- model.matrix(
    ~dispersion_income,
    data = schools[estimation_rows, , drop = FALSE]
  )

  expect_equal(
    unname(outside$eta),
    unname(drop(expected_Z %*% outside$variance_coefficients)),
    tolerance = 1e-12
  )

  aligned_data <- data.frame(
    y = sin(1:15) + (1:15) / 5,
    x = c(1:6, NA, 8:15),
    z = log(1:15),
    keep = rep(c(TRUE, TRUE, FALSE), 5),
    row.names = paste0("row", 1:15)
  )
  aligned_fit <- lm(
    y ~ x,
    data = aligned_data,
    subset = keep,
    na.action = na.omit
  )
  aligned <- gls_mult(
    aligned_fit,
    variance = ~z,
    estimator = "two_step"
  )
  estimation_rows <- row.names(model.frame(aligned_fit))
  aligned_Z <- model.matrix(
    ~z,
    data = aligned_data[estimation_rows, , drop = FALSE]
  )

  expect_identical(names(aligned$eta), estimation_rows)
  expect_equal(
    unname(aligned$eta),
    unname(drop(aligned_Z %*% aligned$variance_coefficients)),
    tolerance = 1e-12
  )

  excluded_fit <- lm(
    y ~ x,
    data = aligned_data,
    na.action = na.exclude
  )
  excluded <- gls_mult(
    excluded_fit,
    variance = ~z,
    estimator = "two_step"
  )
  excluded_rows <- row.names(model.frame(excluded_fit))
  expect_identical(excluded$n, nrow(model.frame(excluded_fit)))
  expect_identical(names(excluded$residuals), excluded_rows)

  factor_data <- data.frame(
    y = sin(1:18) + (1:18) / 10,
    x = 1:18,
    group = factor(rep(c("a", "b", "c"), each = 6)),
    keep = rep(c(TRUE, TRUE, FALSE), each = 6)
  )
  factor_fit <- lm(y ~ x, data = factor_data, subset = keep)
  factor_result <- gls_mult(
    factor_fit,
    variance = ~group,
    estimator = "two_step"
  )
  expect_identical(factor_result$variance_terms, c("(Intercept)", "groupb"))
  expect_identical(factor_result$q, 2L)

  environment_data <- data.frame(
    y = cos(1:14) + (1:14) / 7,
    x = 1:14,
    z = log(1:14)
  )
  environment_fit <- lm(y ~ x, data = environment_data)
  z <- rev(environment_data$z)
  environment_result <- gls_mult(
    environment_fit,
    variance = ~z,
    estimator = "two_step"
  )
  source_Z <- model.matrix(~z, data = environment_data)
  expect_equal(
    unname(environment_result$eta),
    unname(drop(source_Z %*% environment_result$variance_coefficients)),
    tolerance = 1e-12
  )

  environment_only_data <- environment_data[c("y", "x")]
  environment_only_fit <- lm(y ~ x, data = environment_only_data)
  expect_error(
    gls_mult(
      environment_only_fit,
      variance = ~z,
      estimator = "two_step"
    ),
    "do not contain all dispersion regressors"
  )

  unavailable_data <- data.frame(
    y = sin(1:10),
    x = 1:10,
    z = log(1:10)
  )
  unavailable_fit <- lm(y ~ x, data = unavailable_data)
  rm(unavailable_data)
  expect_snapshot(
    error = TRUE,
    gls_mult(unavailable_fit, variance = ~z, estimator = "two_step")
  )

  misaligned_data <- data.frame(
    y = cos(1:12),
    x = 1:12,
    z = log(1:12),
    row.names = paste0("old", 1:12)
  )
  misaligned_fit <- lm(y ~ x, data = misaligned_data)
  row.names(misaligned_data) <- paste0("new", 1:12)
  expect_snapshot(
    error = TRUE,
    gls_mult(misaligned_fit, variance = ~z, estimator = "two_step")
  )
})

test_that("gls_mult reports unsupported and unidentified fits", {
  expect_snapshot(error = TRUE, gls_mult(1))

  multivariate_data <- data.frame(
    y1 = sin(1:8),
    y2 = cos(1:8),
    x = 1:8
  )
  multivariate_fit <- lm(cbind(y1, y2) ~ x, data = multivariate_data)
  expect_snapshot(error = TRUE, gls_mult(multivariate_fit))

  weighted_data <- data.frame(y = sin(1:10), x = 1:10)
  weighted_fit <- lm(
    y ~ x,
    data = weighted_data,
    weights = rep(1, nrow(weighted_data))
  )
  expect_snapshot(error = TRUE, gls_mult(weighted_fit))

  offset_data <- data.frame(
    y = sin(1:10),
    x = 1:10,
    known = seq(0.1, 1, length.out = 10)
  )
  offset_fit <- lm(y ~ x + offset(known), data = offset_data)
  expect_snapshot(error = TRUE, gls_mult(offset_fit))

  rank_data <- data.frame(y = sin(1:12), x = 1:12)
  rank_fit <- lm(y ~ x + I(2 * x), data = rank_data)
  expect_snapshot(error = TRUE, gls_mult(rank_fit))

  rank_data$z <- log(rank_data$x)
  dispersion_rank_fit <- lm(y ~ x, data = rank_data)
  expect_snapshot(
    error = TRUE,
    gls_mult(
      dispersion_rank_fit,
      variance = ~ z + I(2 * z),
      estimator = "two_step"
    )
  )

  missing_data <- transform(rank_data, z = replace(z, 4, NA_real_))
  missing_fit <- lm(y ~ x, data = missing_data)
  expect_snapshot(
    error = TRUE,
    gls_mult(missing_fit, variance = ~z, estimator = "two_step")
  )

  no_intercept_fit <- lm(y ~ 0 + x, data = rank_data)
  expect_snapshot(
    error = TRUE,
    gls_mult(no_intercept_fit, estimator = "two_step")
  )

  zero_residual_fit <- lm(y ~ x, data = rank_data)
  zero_residual_fit$residuals[1] <- 0
  expect_snapshot(
    error = TRUE,
    gls_mult(zero_residual_fit, estimator = "two_step")
  )

  missing_residual_fit <- lm(y ~ x, data = rank_data)
  missing_residual_fit$residuals[1] <- NA_real_
  expect_snapshot(
    error = TRUE,
    gls_mult(missing_residual_fit, estimator = "two_step")
  )

  public_fit <- lm(expenditure ~ income, data = PublicSchools)
  expect_snapshot(
    error = TRUE,
    gls_mult(public_fit, estimator = "ml", control = list(maxit = 1))
  )
})

test_that("ML remains stable for large representable log-variances", {
  x <- seq(-1, 1, length.out = 24)
  base_y <- 2 + 0.5 * x + sin(seq_along(x))
  scale <- 1.3e154
  fit <- lm(I(scale * base_y) ~ x)
  result <- gls_mult(
    fit,
    variance = ~1,
    estimator = "ml",
    control = list(reltol = 1e-16)
  )
  X <- model.matrix(fit)
  y <- model.response(model.frame(fit))
  base_fit <- lm(base_y ~ x)
  expected_eta <- 2 * log(scale) + log(mean(residuals(base_fit)^2))
  expected_weight <- exp(-expected_eta)
  expected_coefficients <- drop(
    solve(
      crossprod(X, expected_weight * X),
      crossprod(X, expected_weight * y)
    )
  )
  expected_vcov <- solve(crossprod(X, expected_weight * X))
  expected_loglik <- -length(y) / 2 * (log(2 * pi) + expected_eta + 1)

  expect_gt(sum(is.infinite(residuals(fit)^2)), 0)
  expect_equal(
    unname(coef(result)),
    unname(expected_coefficients),
    tolerance = 1e-8
  )
  expect_equal(
    unname(vcov(result)),
    unname(expected_vcov),
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(logLik(result)),
    expected_loglik,
    tolerance = 1e-8
  )
  expect_equal(
    unname(result$eta),
    rep(expected_eta, length(y)),
    tolerance = 1e-10
  )
  expect_equal(
    unname(result$weights),
    rep(expected_weight, length(y)),
    tolerance = 1e-10
  )
  expect_equal(sum(!is.finite(result$fitted_variances)), 0)
  expect_equal(sum(result$fitted_variances <= 0), 0)
})

test_that("maximum likelihood rejects a nonpositive iteration budget", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  expect_error(
    gls_mult(fit, estimator = "ml", control = list(maxit = 0)),
    "positive integer"
  )
  expect_error(
    gls_mult(fit, estimator = "ml", control = list(maxit = -1)),
    "positive integer"
  )
  expect_error(
    gls_mult(fit, estimator = "ml", control = list(maxit = 2.5)),
    "positive integer"
  )
})

test_that("maximum likelihood requires positive finite objective scaling", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  invalid_values <- list(
    "maximize",
    c(1, 2),
    NA_real_,
    NaN,
    Inf,
    -Inf,
    0
  )
  for (fnscale in invalid_values) {
    expect_error(
      gls_mult(fit, estimator = "ml", control = list(fnscale = fnscale)),
      "`control$fnscale` must be one finite positive number.",
      fixed = TRUE
    )
  }
  expect_snapshot(
    error = TRUE,
    gls_mult(fit, estimator = "ml", control = list(fnscale = -1))
  )
  expect_no_error(
    gls_mult(fit, estimator = "two_step", control = list(fnscale = -1))
  )

  control <- list(reltol = 1e-13, maxit = 10000)
  default_scale <- gls_mult(fit, estimator = "ml", control = control)
  doubled_scale <- gls_mult(
    fit,
    estimator = "ml",
    control = c(control, list(fnscale = 2))
  )
  expect_equal(
    unname(coef(doubled_scale)),
    unname(coef(default_scale)),
    tolerance = 1e-5
  )
  expect_equal(
    as.numeric(logLik(doubled_scale)),
    as.numeric(logLik(default_scale)),
    tolerance = 1e-8
  )
})

test_that("maximum likelihood rejects a nonstationary point", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  # reltol = 10 makes BFGS stop immediately with convergence code 0 at a
  # nonstationary point (invariant score norm ~1.61 >> tolerance 1e-2).
  expect_error(
    gls_mult(fit, estimator = "ml", control = list(reltol = 10)),
    "did not reach a stationary point"
  )
})

test_that("dispersion-regressor rescaling does not change the ML fit", {
  d <- transform(PublicSchools, income10 = income / 10000)
  fit <- lm(expenditure ~ income, data = d)
  # Rescaling a dispersion regressor must not trip the stationarity guard
  # under the default optimizer settings.
  expect_no_error(gls_mult(fit, variance = ~income10, estimator = "ml"))
  # Tighten the optimizer so both parameterizations reach corresponding
  # stationary fits.
  control <- list(reltol = 1e-13)
  base_fit <- gls_mult(fit, variance = ~income, estimator = "ml", control = control)
  scaled_fit <- gls_mult(fit, variance = ~income10, estimator = "ml", control = control)
  expect_equal(
    unname(coef(base_fit)),
    unname(coef(scaled_fit)),
    tolerance = 1e-6
  )
  expect_equal(
    as.numeric(logLik(base_fit)),
    as.numeric(logLik(scaled_fit)),
    tolerance = 1e-6
  )
})

test_that("base AIC and BIC compare multiple ML fits", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  full <- gls_mult(fit, estimator = "ml")
  homosk <- gls_mult(fit, variance = ~1, estimator = "ml")
  aic_table <- AIC(full, homosk)
  bic_table <- BIC(full, homosk)
  expect_s3_class(aic_table, "data.frame")
  expect_identical(nrow(aic_table), 2L)
  expect_identical(aic_table$df, c(4, 3))
  expect_equal(aic_table["full", "AIC"], AIC(full))
  expect_equal(bic_table["homosk", "BIC"], BIC(homosk))
})

test_that("maximum likelihood matches an independent profile optimizer", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  ml <- gls_mult(fit, estimator = "ml")
  y <- model.response(model.frame(fit))
  x10 <- model.matrix(fit)[, "income"] / 10000
  Xs <- cbind("(Intercept)" = 1, income10 = x10)
  neg_profile <- function(a) {
    eta <- drop(Xs %*% a)
    w <- exp(-eta)
    b <- drop(solve(crossprod(Xs, w * Xs), crossprod(Xs, w * y)))
    r <- y - drop(Xs %*% b)
    length(y) / 2 * log(2 * pi) + 0.5 * sum(eta) + 0.5 * sum(w * r^2)
  }
  opt <- optim(
    c(8, 0),
    neg_profile,
    method = "BFGS",
    control = list(reltol = 1e-13, maxit = 10000)
  )
  eta <- drop(Xs %*% opt$par)
  w <- exp(-eta)
  b_scaled <- drop(solve(crossprod(Xs, w * Xs), crossprod(Xs, w * y)))
  tt <- diag(c(1, 1 / 10000))
  beta_ref <- drop(tt %*% b_scaled)
  vcov_ref <- tt %*% solve(crossprod(Xs, w * Xs)) %*% tt
  expect_equal(unname(coef(ml)), unname(beta_ref), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(ml)), -opt$value, tolerance = 1e-6)
  expect_equal(unname(vcov(ml)), unname(vcov_ref), tolerance = 1e-5)
})

test_that("maximum likelihood accepts a stable flat stationary fit", {
  schools <- transform(PublicSchools2, income_scaled = income / 10000)
  fit <- lm(expenditure ~ income_scaled + south, data = schools)
  # This dispersion model is poorly scaled: default BFGS stops at a score
  # norm ~1.4e-3. Agreement with the tight-reltol local fit is a stability
  # check; matching two local runs does not prove global optimality.
  expect_no_error(gls_mult(fit, variance = ~ income_scaled))
  loose <- gls_mult(fit, variance = ~ income_scaled)
  tight <- gls_mult(
    fit,
    variance = ~ income_scaled,
    control = list(reltol = 1e-13, maxit = 10000)
  )
  expect_equal(
    as.numeric(logLik(loose)),
    as.numeric(logLik(tight)),
    tolerance = 1e-4
  )
})
