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
  a_tilde <- (1 - zeta) + zeta * a_hat
  b_tilde <- (1 - zeta) + zeta * b_hat
  expected <- (n / (n - p)) *
    (1 / stats::pbeta(w, a_tilde, b_tilde))^(c1 / n^c2)

  result <- vcov_hc(fit, "hcbeta")

  expect_equal(result$weights, expected, ignore_attr = TRUE)
  expect_equal(result$method_params$a_tilde, a_tilde)
  expect_equal(result$method_params$b_tilde, b_tilde)
})

test_that("HCbeta with c1 equal to zero reduces to HC1 weights", {
  fit <- local_public_schools_fit()

  expect_equal(
    vcov_hc(fit, "hcbeta", c1 = 0)$weights,
    vcov_hc(fit, "hc1")$weights,
    ignore_attr = TRUE
  )
})
