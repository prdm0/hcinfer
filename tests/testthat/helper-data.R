data("PublicSchools", package = "hcinfer")

public_schools_article_data <- function() {
  transform(
    PublicSchools,
    income_scaled = income / 10000,
    income_scaled_sq = (income / 10000)^2
  )
}

public_schools_article_fit <- function() {
  lm(
    expenditure ~ income_scaled + income_scaled_sq,
    data = public_schools_article_data()
  )
}
