test_that("hc_methods() reports all estimators", {
  methods <- hc_methods()

  expect_s3_class(methods, "tbl_df")
  expect_named(methods, c("type", "label", "description", "default_arguments"))
  expect_equal(
    methods$type,
    c("hc0", "hc1", "hc2", "hc3", "hc4", "hc4m", "hc5", "hc5m", "hcbeta")
  )
  expect_equal(methods$label[[9]], "HCbeta")
})

test_that("hc_methods() reports method-specific defaults", {
  methods <- hc_methods()

  expect_equal(methods$default_arguments[methods$type == "hc0"], "none")
  expect_equal(methods$default_arguments[methods$type == "hc4m"], "none")
  expect_equal(methods$default_arguments[methods$type == "hc5"], "k = 0.7")
  expect_equal(
    methods$default_arguments[methods$type == "hc5m"],
    "k = 0.7, k1 = 1, k2 = 0, k3 = 1, gamma1 = 1, gamma2 = 1.5"
  )
  expect_equal(
    methods$default_arguments[methods$type == "hcbeta"],
    "c1 = 7, c2 = 0.75, lower = 0.01, upper = 0.99"
  )
})

test_that("reported defaults are consistent with internal defaults", {
  defaults <- hcinfer:::hc_default_arguments()
  methods <- hc_methods()
  reported <- stats::setNames(methods$default_arguments, methods$type)
  expected <- purrr::map_chr(defaults, hcinfer:::format_default_arguments)

  expect_equal(reported[names(expected)], expected)
})
