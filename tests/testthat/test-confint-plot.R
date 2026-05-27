test_that("confint() returns stored and recomputed normal intervals", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  intervals <- confint(result)
  expect_s3_class(intervals, "tbl_df")
  expect_equal(intervals$conf_low, result$table$conf_low)
  expect_equal(intervals$conf_high, result$table$conf_high)

  intervals_90 <- confint(result, level = 0.90)
  critical <- stats::qnorm(0.95)
  expect_equal(
    intervals_90$conf_low,
    result$table$estimate - critical * result$table$std_error
  )
})

test_that("plot() returns a ggplot object", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  expect_s3_class(plot(result), "ggplot")
})

test_that("plot() data contains the decision column", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  p <- plot(result)
  expect_true("decision" %in% names(p$data))
  expect_true(all(p$data$decision %in% c("reject H0", "do not reject H0")))
})

test_that("plot() selects coefficients by name via parm", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  p <- plot(result, parm = "income_scaled_sq")
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 1L)
  expect_equal(as.character(p$data$term[[1]]), "income_scaled_sq")
})

test_that("plot() selects coefficients by position via parm", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  p <- plot(result, parm = 1L)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 1L)
})

test_that("plot() errors on unknown parm name", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  expect_snapshot(error = TRUE, plot(result, parm = "nonexistent"))
})

test_that("plot() p_label column is correctly formatted", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")

  p <- plot(result)
  expect_true(all(grepl("^p-value", p$data$p_label)))
})

test_that("format_p_label() produces correct labels", {
  expect_equal(
    hcinfer:::format_p_label(c(0.5, 0.042, 0.0003)),
    c("p-value = 0.500", "p-value = 0.042", "p-value <0.001")
  )
})

test_that("plot() works for covariance objects", {
  fit <- public_schools_article_fit()
  cov <- vcov_hc(fit, type = "hcbeta")

  p <- plot(cov)
  expect_s3_class(p, "ggplot")
  expect_named(p$data, c("observation", "leverage", "weight", "high_leverage"))
  expect_equal(p$data$high_leverage, p$data$leverage > 3 * cov$p / cov$n)
})

test_that("plot() for covariance objects can suppress labels", {
  fit <- public_schools_article_fit()
  cov <- vcov_hc(fit, type = "hc4")

  p <- plot(cov, label_top = 0)
  expect_s3_class(p, "ggplot")
})

test_that("plot() for covariance objects validates label_top", {
  fit <- public_schools_article_fit()
  cov <- vcov_hc(fit, type = "hcbeta")

  expect_snapshot(error = TRUE, plot(cov, label_top = -1))
  expect_snapshot(error = TRUE, plot(cov, label_top = 1.5))
})

test_that("public-schools article model reproduces reference values", {
  fit <- public_schools_article_fit()
  result <- hcinfer(fit, type = "hcbeta")
  cov <- vcov_hc(fit, type = "hcbeta")

  expect_equal(unname(stats::coef(fit)), c(832.9144, -1834.2029, 1587.0423), tolerance = 1e-4)
  expect_equal(cov$method_params$a_tilde, 3.1472, tolerance = 1e-4)
  expect_equal(cov$method_params$b_tilde, 0.6690, tolerance = 1e-4)
  expect_equal(max(cov$weights), 4.5807, tolerance = 1e-4)
  expect_equal(result$table$std_error[[3]], 1547.4583, tolerance = 1e-4)
})
