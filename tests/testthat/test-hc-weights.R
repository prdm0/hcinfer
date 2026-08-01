local_public_schools_fit <- function() {
  lm(expenditure ~ income, data = PublicSchools)
}

test_that("classical HC weights match the canonical formulas", {
  fit <- local_public_schools_fit()
  leverage <- stats::hatvalues(fit)
  n <- length(leverage)
  p <- length(stats::coef(fit))
  h_bar <- p / n
  ratio <- leverage / h_bar
  u <- 1 - leverage

  expect_equal(vcov_hc(fit, "hc0")$weights, rep(1, n), ignore_attr = TRUE)
  expect_equal(vcov_hc(fit, "hc1")$weights, rep(n / (n - p), n), ignore_attr = TRUE)
  expect_equal(vcov_hc(fit, "hc2")$weights, 1 / u, ignore_attr = TRUE)
  expect_equal(vcov_hc(fit, "hc3")$weights, 1 / u^2, ignore_attr = TRUE)
  expect_equal(vcov_hc(fit, "hc4")$weights, u^(-pmin(4, ratio)), ignore_attr = TRUE)
  expect_equal(
    vcov_hc(fit, "hc4m")$weights,
    u^(-(pmin(1, ratio) + pmin(1.5, ratio))),
    ignore_attr = TRUE
  )
})

test_that("HC5 and HC5m weights match their formulas", {
  fit <- local_public_schools_fit()
  leverage <- stats::hatvalues(fit)
  n <- length(leverage)
  p <- length(stats::coef(fit))
  h_bar <- p / n
  h_max <- max(leverage)
  ratio <- leverage / h_bar
  u <- 1 - leverage
  k <- 0.7

  hc5_delta <- pmin(ratio, max(4, k * h_max / h_bar))
  expect_equal(vcov_hc(fit, "hc5")$weights, u^(-hc5_delta), ignore_attr = TRUE)

  hc5m_delta <- pmin(1, ratio) + pmin(ratio, max(4, k * h_max / h_bar))
  expect_equal(vcov_hc(fit, "hc5m")$weights, u^(-hc5m_delta), ignore_attr = TRUE)
})

test_that("HC5m preserves documented special cases", {
  fit <- local_public_schools_fit()

  expect_equal(
    vcov_hc(fit, "hc5m", k1 = 1, k2 = 1, k3 = 0)$weights,
    vcov_hc(fit, "hc4m")$weights,
    ignore_attr = TRUE
  )

  expect_equal(
    vcov_hc(fit, "hc5m", k1 = 0, k2 = 0, k3 = 1)$weights,
    vcov_hc(fit, "hc5")$weights,
    ignore_attr = TRUE
  )

  expect_equal(
    vcov_hc(fit, "hc5")$weights,
    vcov_hc(fit, "hc4")$weights,
    ignore_attr = TRUE
  )
})

test_that("HCbeta weights match the method of moments formula", {
  fit <- local_public_schools_fit()
  leverage <- stats::hatvalues(fit)
  n <- length(leverage)
  p <- length(stats::coef(fit))

  lower <- 0.01
  upper <- 0.99
  c1 <- 7
  c2 <- 0.75

  w <- pmax(lower, pmin(1 - leverage, upper))
  mu_hat <- mean(w)
  s2_w <- sum((w - mu_hat)^2) / (n - 1)
  phi_hat <- mu_hat * (1 - mu_hat) / s2_w - 1
  a_hat <- mu_hat * phi_hat
  b_hat <- (1 - mu_hat) * phi_hat
  zeta <- n / (n + 50)
  a_tilde <- min(max((1 - zeta) + zeta * a_hat, 0.01), 10000)
  b_tilde <- min(max((1 - zeta) + zeta * b_hat, 0.01), 10000)
  expected <- (n / (n - p)) *
    (1 / stats::pbeta(w, a_tilde, b_tilde))^(c1 / n^c2)

  result <- vcov_hc(fit, "hcbeta")

  expect_equal(result$weights, expected, ignore_attr = TRUE)
  expect_equal(result$method_params$a_tilde, a_tilde)
  expect_equal(result$method_params$b_tilde, b_tilde)
})

test_that("HCbeta enforces the fixed shape floor", {
  n <- 6000L
  lower <- 1e-10
  upper <- 1 - 1e-10
  c1 <- 7
  c2 <- 0.75
  fit <- lm(
    y ~ 0 + x,
    data = data.frame(
      x = c(1, rep(0, n - 1L)),
      y = sin(seq_len(n))
    )
  )
  result <- vcov_hc(
    fit,
    type = "hcbeta",
    lower = lower,
    upper = upper
  )

  params <- result$method_params
  a_pre_floor <- (1 - params$zeta) + params$zeta * params$a_hat
  b_pre_floor <- (1 - params$zeta) + params$zeta * params$b_hat
  leverage <- stats::hatvalues(fit)
  w <- pmax(lower, pmin(1 - leverage, upper))
  log_beta_cdf <- stats::pbeta(w, 0.01, 0.01, log.p = TRUE)
  exponent <- pmin(-(c1 / n^c2) * log_beta_cdf, 700)
  expected <- (n / (n - length(stats::coef(fit)))) * exp(exponent)

  expect_lt(params$phi_hat, 0)
  expect_lt(a_pre_floor, 0.01)
  expect_lt(b_pre_floor, 0.01)
  expect_identical(params$a_tilde, 0.01)
  expect_identical(params$b_tilde, 0.01)
  expect_equal(result$weights, expected, ignore_attr = TRUE)
})

test_that("HCbeta controls propagate through public APIs", {
  fit <- local_public_schools_fit()
  controls <- list(
    c1 = 5,
    c2 = 0.8,
    lower = 0.02,
    upper = 0.98,
    a_max = 50,
    b_max = 75
  )

  cov <- do.call(
    vcov_hc,
    c(list(object = fit, type = "hcbeta"), controls)
  )
  inference <- do.call(
    hcinfer,
    c(list(object = fit, type = "hcbeta"), controls)
  )

  expect_identical(cov$method_params[names(controls)], controls)
  expect_identical(inference$method_params[names(controls)], controls)
  expect_equal(cov$weights, inference$weights)
})

test_that("HCbeta rejects epsilon as a method argument", {
  fit <- local_public_schools_fit()

  expect_snapshot(
    error = TRUE,
    vcov_hc(fit, "hcbeta", epsilon = 0.02)
  )
})

test_that("HCbeta with c1 equal to zero reduces to HC1 weights", {
  fit <- local_public_schools_fit()

  expect_equal(
    vcov_hc(fit, "hcbeta", c1 = 0)$weights,
    vcov_hc(fit, "hc1")$weights,
    ignore_attr = TRUE
  )
})

test_that("HCbeta clamps Beta shape parameters at a_max and b_max", {
  fit <- lm(y ~ x, data = data.frame(x = 1:60, y = sin(1:60)))

  uncapped <- vcov_hc(fit, "hcbeta")            # default a_max = 10000
  capped <- vcov_hc(fit, "hcbeta", a_max = 50)

  expect_gt(uncapped$method_params$a_tilde, 50) # uncapped ~ 75.17
  expect_equal(capped$method_params$a_tilde, 50)
  expect_equal(                                 # b_tilde ~ 3.03, cap does not bind
    capped$method_params$b_tilde,
    uncapped$method_params$b_tilde
  )
})

test_that("HCbeta cap bounds are inclusive", {
  fit <- local_public_schools_fit()

  lower <- vcov_hc(fit, "hcbeta", a_max = 50, b_max = 50)
  upper <- hcinfer(fit, type = "hcbeta", a_max = 25000, b_max = 25000)

  expect_identical(
    unname(unlist(lower$method_params[c("a_max", "b_max")])),
    c(50, 50)
  )
  expect_identical(
    unname(unlist(upper$method_params[c("a_max", "b_max")])),
    c(25000, 25000)
  )

  expect_snapshot(error = TRUE, vcov_hc(fit, "hcbeta", a_max = 49))
  expect_snapshot(error = TRUE, vcov_hc(fit, "hcbeta", a_max = 25001))
  expect_snapshot(error = TRUE, vcov_hc(fit, "hcbeta", b_max = 49))
  expect_snapshot(error = TRUE, vcov_hc(fit, "hcbeta", b_max = 25001))
})

test_that("HCbeta evaluates the log-CDF stably and clips the exponent", {
  n <- 100
  p <- 99
  leverage <- rep(0.99, n)
  base_args <- list(
    c1 = 7,
    c2 = 0.75,
    lower = 0.01,
    upper = 0.99,
    a_max = 25000,
    b_max = 25000
  )

  expect_equal(sum(leverage), p)

  log_beta_cdf <- stats::pbeta(
    base_args$lower,
    base_args$a_max,
    base_args$b_max,
    log.p = TRUE
  )
  raw_clipped <- -(base_args$c1 / n^base_args$c2) * log_beta_cdf
  clipped <- hcinfer:::hcbeta_components(leverage, n, p, base_args)

  expect_gt(raw_clipped, 700)
  expect_true(all(is.finite(clipped$weights)))
  expect_equal(
    clipped$weights,
    rep((n / (n - p)) * exp(700), n)
  )

  log_args <- utils::modifyList(base_args, list(c1 = 0.1))
  raw_unclipped <- -(log_args$c1 / n^log_args$c2) * log_beta_cdf
  stable <- hcinfer:::hcbeta_components(leverage, n, p, log_args)

  expect_identical(
    stats::pbeta(base_args$lower, base_args$a_max, base_args$b_max),
    0
  )
  expect_true(is.finite(log_beta_cdf))
  expect_gt(raw_unclipped, 0)
  expect_lt(raw_unclipped, 700)
  expect_true(all(is.finite(stable$weights)))
  expect_equal(
    stable$weights,
    rep((n / (n - p)) * exp(raw_unclipped), n)
  )
})

test_that("HC leverage-one guards are method-specific", {
  fit <- lm(
    y ~ x,
    data = data.frame(x = c(0, 0, 0, 1), y = c(1, 2, 4, 8))
  )

  allowed_types <- c("hc0", "hc1", "hcbeta")
  allowed <- lapply(allowed_types, \(type) vcov_hc(fit, type))

  expect_equal(
    vapply(allowed, \(result) all(is.finite(result$weights)), logical(1)),
    rep(TRUE, length(allowed_types))
  )
  expect_equal(
    vapply(allowed, \(result) all(is.finite(result$vcov)), logical(1)),
    rep(TRUE, length(allowed_types))
  )
  expect_equal(max(allowed[[3]]$leverage), 1)

  guarded_types <- c("hc2", "hc3", "hc4", "hc4m", "hc5", "hc5m")
  errors <- lapply(
    guarded_types,
    \(type) tryCatch(vcov_hc(fit, type), error = identity)
  )

  expect_equal(
    vapply(errors, inherits, logical(1), "error"),
    rep(TRUE, length(guarded_types))
  )
  expect_equal(
    vapply(
      errors,
      \(error) grepl(
        "HC leverage corrections require positive `1 - h_t`",
        conditionMessage(error),
        fixed = TRUE
      ),
      logical(1)
    ),
    rep(TRUE, length(guarded_types))
  )

  expect_snapshot(error = TRUE, vcov_hc(fit, "hc3"))
})

test_that("HCbeta weights never fall below the HC1 scale", {
  fit <- local_public_schools_fit()
  res <- vcov_hc(fit, "hcbeta")
  hc1 <- res$n / (res$n - res$p)

  expect_true(all(res$weights >= hc1 - 1e-8))
})

test_that("HCbeta caps degenerate moment estimates on balanced designs", {
  n <- 500
  fit <- lm(y ~ x, data = data.frame(
    x = seq_len(n),
    y = sin(seq_len(n))
  ))
  res <- vcov_hc(fit, "hcbeta")
  hc1 <- n / (n - res$p)

  expect_lt(max(res$leverage), 0.01)
  expect_lte(res$method_params$s2_w, .Machine$double.eps)
  expect_equal(res$method_params$a_tilde, 10000)
  expect_equal(res$method_params$b_tilde, 10000)
  expect_equal(res$weights, rep(hc1, n), ignore_attr = TRUE)
})
