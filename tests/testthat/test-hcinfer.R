test_that("hcinfer() computes normal Wald inference", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta", alpha = 0.05)

  expect_s3_class(result, "hcinfer")
  expect_equal(result$critical_value, stats::qnorm(0.975))
  expect_identical(vcov(result), result$vcov)
  expect_identical(coef(result), result$coefficients)

  expected_se <- sqrt(diag(result$vcov))
  expected_z <- stats::coef(fit) / expected_se
  expected_p <- 2 * stats::pnorm(abs(expected_z), lower.tail = FALSE)
  expected_low <- stats::coef(fit) - result$critical_value * expected_se
  expected_high <- stats::coef(fit) + result$critical_value * expected_se

  expect_equal(result$table$std_error, unname(expected_se))
  expect_equal(result$table$z_value, unname(expected_z))
  expect_equal(result$table$p_value, unname(expected_p))
  expect_equal(result$table$conf_low, unname(expected_low))
  expect_equal(result$table$conf_high, unname(expected_high))
})

test_that("named null values are matched to model terms", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  null <- c(income = 0.05, `(Intercept)` = -100)
  result <- hcinfer(fit, type = "hc3", null = null)

  expect_equal(result$null, null[names(result$null)])
  expect_equal(result$table$null_value, c(-100, 0.05))
})
