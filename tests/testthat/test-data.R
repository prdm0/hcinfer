test_that("PublicSchools has the expected structure", {
  expect_s3_class(PublicSchools, "tbl_df")
  expect_named(PublicSchools, c("state", "expenditure", "income"))
  expect_equal(nrow(PublicSchools), 51)
  expect_equal(ncol(PublicSchools), 3)

  alaska <- PublicSchools[PublicSchools$state == "Alaska", ]
  expect_equal(alaska$expenditure, 821)
  expect_equal(alaska$income, 10851)

  expect_equal(sum(is.na(PublicSchools$expenditure)), 1)
})
