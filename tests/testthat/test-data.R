test_that("PublicSchools has the expected structure", {
  expect_s3_class(PublicSchools, "tbl_df")
  expect_named(PublicSchools, c("state", "expenditure", "income"))
  expect_equal(nrow(PublicSchools), 51)
  expect_equal(ncol(PublicSchools), 3)

  alaska <- PublicSchools[PublicSchools$state == "Alaska", ]
  expect_equal(alaska$expenditure, 821)
  expect_equal(alaska$income, 10851)

  expect_equal(sum(is.na(PublicSchools$expenditure)), 1)
  expect_identical(
    PublicSchools$state[grepl("District", PublicSchools$state)],
    "District of Columbia"
  )
  expect_length(grep("Washington DC", PublicSchools$state), 0)
})

test_that("PublicSchools2 has the expected structure and values", {
  expect_s3_class(PublicSchools2, "tbl_df")
  expect_named(
    PublicSchools2,
    c("state", "income", "expenditure", "south")
  )
  expect_equal(nrow(PublicSchools2), 51)
  expect_equal(ncol(PublicSchools2), 4)
  expect_type(PublicSchools2$state, "character")
  expect_type(PublicSchools2$income, "integer")
  expect_type(PublicSchools2$expenditure, "integer")
  expect_type(PublicSchools2$south, "integer")
  expect_equal(sum(is.na(PublicSchools2)), 0)
  expect_setequal(PublicSchools2$south, c(0L, 1L))

  federal_district <- PublicSchools2[
    PublicSchools2$state == "District of Columbia",
  ]
  expect_equal(nrow(federal_district), 1)
  expect_equal(federal_district$income, 77348L)
  expect_equal(federal_district$expenditure, 31629L)
  expect_equal(federal_district$south, 1L)

  southern_jurisdictions <- c(
    "Alabama",
    "Arkansas",
    "Delaware",
    "District of Columbia",
    "Florida",
    "Georgia",
    "Kentucky",
    "Louisiana",
    "Maryland",
    "Mississippi",
    "North Carolina",
    "Oklahoma",
    "South Carolina",
    "Tennessee",
    "Texas",
    "Virginia",
    "West Virginia"
  )
  expect_setequal(
    PublicSchools2$state[PublicSchools2$south == 1L],
    southern_jurisdictions
  )
})
