test_that("summary() contains Wald tests and diagnostics", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")
  summary_result <- summary(result)

  expect_s3_class(summary_result, "summary_hcinfer")
  expect_named(summary_result$tests, c(
    "term", "estimate", "null_value", "std_error",
    "z_value", "p_value", "conf_low", "conf_high"
  ))
  expect_named(summary_result$leverage_summary, c("minimum", "q1", "median", "mean", "q3", "maximum"))
  expect_named(summary_result$weights_summary, c("minimum", "q1", "median", "mean", "q3", "maximum"))
  expect_equal(summary_result$tests$p_value, result$table$p_value)
})

test_that("summary() works for covariance objects", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  cov <- vcov_hc(fit, type = "hc4m")
  summary_result <- summary(cov)

  expect_s3_class(summary_result, "summary_hcinfer_vcov")
  expect_equal(summary_result$method, "HC4m")
  expect_named(summary_result$weights_summary, c("minimum", "q1", "median", "mean", "q3", "maximum"))
})
