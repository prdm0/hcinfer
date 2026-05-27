test_that("tests() returns a tibble with the correct columns", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  out <- tests(result)
  expect_s3_class(out, "tbl_df")
  expect_named(out, c("term", "estimate", "null_value", "std_error", "z_value", "p_value", "alpha", "reject"))
})

test_that("tests() values match the stored table", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  out <- tests(result)
  expect_equal(out$term, result$table$term)
  expect_equal(out$estimate, result$table$estimate)
  expect_equal(out$null_value, result$table$null_value)
  expect_equal(out$std_error, result$table$std_error)
  expect_equal(out$z_value, result$table$z_value)
  expect_equal(out$p_value, result$table$p_value)
  expect_equal(out$alpha, rep(result$alpha, nrow(out)))
  expect_equal(out$reject, result$table$p_value < result$alpha)
})

test_that("tests() selects coefficients by name", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hc3")

  out <- tests(result, parm = "income")
  expect_equal(nrow(out), 1L)
  expect_equal(out$term, "income")
  expect_equal(out$p_value, result$table$p_value[result$table$term == "income"])
})

test_that("tests() selects coefficients by position", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hc3")

  out <- tests(result, parm = 2L)
  expect_equal(nrow(out), 1L)
  expect_equal(out$term, result$table$term[[2]])
})

test_that("tests() errors on unknown coefficient name", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  expect_snapshot(error = TRUE, tests(result, parm = "nonexistent"))
})

test_that("tests() errors on invalid parm type", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  expect_snapshot(error = TRUE, tests(result, parm = TRUE))
})

test_that("tests() with different alpha only changes reject column", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  out_05 <- tests(result, alpha = 0.05)
  out_50 <- tests(result, alpha = 0.50)

  expect_equal(out_05$p_value, out_50$p_value)
  expect_equal(out_05$z_value, out_50$z_value)
  expect_equal(out_05$std_error, out_50$std_error)

  expect_equal(out_05$alpha, rep(0.05, nrow(out_05)))
  expect_equal(out_50$alpha, rep(0.50, nrow(out_50)))

  expect_equal(out_05$reject, out_05$p_value < 0.05)
  expect_equal(out_50$reject, out_50$p_value < 0.50)
})

test_that("tests() errors on invalid alpha", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  expect_snapshot(error = TRUE, tests(result, alpha = 1.5))
  expect_snapshot(error = TRUE, tests(result, alpha = 0))
})

test_that("tests() is consistent with summary()$tests for shared columns", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hc4m")

  out <- tests(result)
  sum_tests <- summary(result)$tests

  expect_equal(out$term, sum_tests$term)
  expect_equal(out$estimate, sum_tests$estimate)
  expect_equal(out$p_value, sum_tests$p_value)
  expect_equal(out$z_value, sum_tests$z_value)
  expect_equal(out$std_error, sum_tests$std_error)
})

test_that("tests() reject is logical", {
  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")

  out <- tests(result)
  expect_type(out$reject, "logical")
})
