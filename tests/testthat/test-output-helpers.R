test_that("display helpers format p-values", {
  old <- options(hcinfer.use_emoji = FALSE)
  on.exit(options(old), add = TRUE)

  expect_equal(
    hcinfer:::format_p_value(c(0.2, 0.01234, 0.0003)),
    c("0.200", "0.012", "<0.001")
  )
})

test_that("display helpers format test results and intervals", {
  old <- options(hcinfer.use_emoji = FALSE)
  on.exit(options(old), add = TRUE)

  expect_equal(
    hcinfer:::format_test_result(c(0.04, 0.06), alpha = 0.05),
    c("reject H0", "do not reject H0")
  )
  expect_equal(
    hcinfer:::format_interval(c(-1, 0.1), c(1, 0.5)),
    c("[-1, 1]", "[0.1, 0.5]")
  )
  expect_equal(
    hcinfer:::format_interval_check(c(-1, 0.1), c(1, 0.5), c(0, 0)),
    c("includes null", "excludes null")
  )
})

capture_printed_output <- function(expr) {
  output <- NULL
  messages <- capture.output(
    output <- capture.output(force(expr), type = "output"),
    type = "message"
  )

  paste(c(messages, output), collapse = "\n")
}

test_that("summary output includes formal test results without emoji", {
  old <- options(hcinfer.use_emoji = FALSE, cli.num_colors = 1)
  on.exit(options(old), add = TRUE)

  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")
  output <- capture_printed_output(print(summary(result)))

  expect_match(output, "Robust covariance", fixed = TRUE)
  expect_match(output, "Coefficient tests", fixed = TRUE)
  expect_match(output, "test_result", fixed = TRUE)
  expect_match(output, "reject H0", fixed = TRUE)
  expect_match(output, "excludes null", fixed = TRUE)
  expect_no_match(output, "\U0001F96A", fixed = TRUE)
})

test_that("summary output can include the selected emoji palette", {
  skip_if_not(l10n_info()[["UTF-8"]])

  old <- options(hcinfer.use_emoji = TRUE, cli.num_colors = 1)
  on.exit(options(old), add = TRUE)

  fit <- lm(expenditure ~ income, data = PublicSchools)
  result <- hcinfer(fit, type = "hcbeta")
  output <- capture_printed_output(print(summary(result)))

  expect_match(output, "\U0001F96A", fixed = TRUE)
  expect_match(output, "\u274C", fixed = TRUE)
  expect_match(output, "\u2705", fixed = TRUE)
})
