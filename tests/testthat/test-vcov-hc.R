test_that("vcov_hc() returns a rich object with a stored covariance matrix", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- vcov_hc(fit, type = "hcbeta")

  expect_s3_class(result, "hcinfer_vcov")
  expect_equal(rownames(result$vcov), c("(Intercept)", "income"))
  expect_equal(colnames(result$vcov), c("(Intercept)", "income"))
  expect_equal(dim(result$vcov), c(2, 2))
  expect_equal(result$vcov, t(result$vcov))
  expect_identical(vcov(result), result$vcov)
})

test_that("vcov_hc() matches a direct sandwich calculation", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- vcov_hc(fit, type = "hc3")

  x <- stats::model.matrix(fit)
  residuals <- stats::residuals(fit)
  omega <- residuals^2 * result$weights
  bread <- solve(crossprod(x))
  expected <- bread %*% crossprod(x, x * omega) %*% bread

  expect_equal(result$vcov, expected, tolerance = 1e-10)
})
