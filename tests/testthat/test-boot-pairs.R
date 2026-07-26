test_that("boot_pairs() returns a well-formed hcinfer_boot object", {
  fit <- public_schools_article_fit()
  boot <- boot_pairs(fit, R = 200, seed = 1)

  expect_s3_class(boot, "hcinfer_boot")
  expect_named(
    boot$table,
    c("term", "estimate", "bias", "std_error", "conf_low", "conf_high")
  )
  expect_equal(boot$table$term, names(stats::coef(fit)))
  expect_equal(boot$table$estimate, unname(stats::coef(fit)))
  expect_equal(dim(boot$replicates), c(200L, length(stats::coef(fit))))
  expect_true(all(is.finite(boot$std_error)))
  expect_true(all(boot$conf_low < boot$conf_high))
})

test_that("boot_pairs() std_error and vcov are internally consistent", {
  fit <- public_schools_article_fit()
  boot <- boot_pairs(fit, R = 300, seed = 5)

  expect_equal(
    unname(boot$std_error),
    unname(apply(boot$replicates, 2, stats::sd))
  )
  expect_equal(
    unname(sqrt(diag(vcov(boot)))),
    unname(boot$std_error)
  )
  expect_equal(unname(coef(boot)), unname(stats::coef(fit)))
})

test_that("boot_pairs() is reproducible with a fixed seed", {
  fit <- public_schools_article_fit()
  a <- boot_pairs(fit, R = 300, seed = 42)
  b <- boot_pairs(fit, R = 300, seed = 42)

  expect_identical(a$replicates, b$replicates)
  expect_identical(a$std_error, b$std_error)
  expect_identical(a$conf_low, b$conf_low)
  expect_identical(a$conf_high, b$conf_high)
})

test_that("boot_pairs() differs across different seeds", {
  fit <- public_schools_article_fit()
  a <- boot_pairs(fit, R = 300, seed = 1)
  b <- boot_pairs(fit, R = 300, seed = 2)

  expect_false(identical(a$replicates, b$replicates))
})

test_that("boot_pairs() does not disturb the caller RNG state", {
  fit <- public_schools_article_fit()
  set.seed(99)
  before <- runif(1)
  set.seed(99)
  invisible(boot_pairs(fit, R = 100, seed = 7))
  after <- runif(1)

  expect_equal(before, after)
})

test_that("percentile intervals match empirical quantiles of the replicates", {
  fit <- public_schools_article_fit()
  boot <- boot_pairs(fit, R = 400, level = 0.90, ci_type = "percentile",
    seed = 3)

  q <- apply(boot$replicates, 2, stats::quantile, probs = c(0.05, 0.95),
    names = FALSE)
  expect_equal(boot$conf_low, stats::setNames(q[1, ], boot$terms))
  expect_equal(boot$conf_high, stats::setNames(q[2, ], boot$terms))
})

test_that("ci_type variants produce the documented endpoints", {
  fit <- public_schools_article_fit()
  perc <- boot_pairs(fit, R = 400, ci_type = "percentile", seed = 8)
  basic <- boot_pairs(fit, R = 400, ci_type = "basic", seed = 8)
  normal <- boot_pairs(fit, R = 400, ci_type = "normal", seed = 8)

  # basic is the reverse-percentile reflection of percentile about the estimate
  expect_equal(
    unname(basic$conf_low),
    unname(2 * perc$coefficients - perc$conf_high)
  )
  expect_equal(
    unname(basic$conf_high),
    unname(2 * perc$coefficients - perc$conf_low)
  )
  z <- stats::qnorm(0.975)
  expect_equal(
    unname(normal$conf_low),
    unname(normal$table$estimate - z * normal$std_error)
  )
})

test_that("confint.hcinfer_boot recomputes level and type, and selects parm", {
  fit <- public_schools_article_fit()
  boot <- boot_pairs(fit, R = 400, level = 0.95, ci_type = "percentile",
    seed = 11)

  default_ci <- confint(boot)
  expect_equal(default_ci$conf_low, unname(boot$conf_low))
  expect_equal(default_ci$level, rep(0.95, nrow(default_ci)))

  wide <- confint(boot, level = 0.99)
  expect_true(all(wide$conf_low <= default_ci$conf_low + 1e-8))

  one <- confint(boot, parm = boot$terms[[2]])
  expect_equal(nrow(one), 1L)
  expect_equal(one$term, boot$terms[[2]])
})

test_that("boot_pairs() parallel run equals the sequential run", {
  skip_on_cran()
  skip_if_not_installed("mirai")
  skip_if_not_installed("carrier")
  fit <- public_schools_article_fit()

  seq_run <- boot_pairs(fit, R = 500, seed = 123, parallel = FALSE)
  par_run <- boot_pairs(fit, R = 500, seed = 123, parallel = TRUE, cores = 2)

  expect_identical(seq_run$replicates, par_run$replicates)
  expect_identical(seq_run$std_error, par_run$std_error)
  expect_identical(seq_run$conf_low, par_run$conf_low)
  expect_identical(seq_run$conf_high, par_run$conf_high)
})

test_that("boot_pairs() rejects invalid input", {
  fit <- public_schools_article_fit()
  expect_snapshot(error = TRUE, boot_pairs("not a model"))
  expect_snapshot(error = TRUE, boot_pairs(fit, R = 0))
  expect_snapshot(error = TRUE, boot_pairs(fit, R = 100, level = 1))
  expect_snapshot(error = TRUE, boot_pairs(fit, R = 100, parallel = "yes"))
  expect_snapshot(error = TRUE, boot_pairs(fit, R = 100, cores = -1))
})
