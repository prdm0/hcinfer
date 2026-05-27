#' Public school expenditure and income by US state
#'
#' @description
#' Public school expenditure and income data for US states and Washington DC in
#' 1979. The expenditure value for Wisconsin is missing in the source data, so
#' the standard regression example uses 50 complete observations. The data are
#' useful for illustrating heteroskedasticity-consistent inference because
#' Alaska is a high-leverage observation in the quadratic public-schools model
#' studied in the HCbeta paper.
#'
#' @format A tibble with 51 rows and 3 variables:
#' \describe{
#'   \item{state}{US state or Washington DC.}
#'   \item{expenditure}{Per capita expenditure on public schools in 1979. This
#'   variable has one missing value.}
#'   \item{income}{Per capita income in 1979.}
#' }
#'
#' @source
#' Greene, W. H. (1993). *Econometric Analysis*, 2nd ed. Macmillan Publishing
#' Company, New York. Table 14.1, p. 385. The data were originally sourced from
#' the U.S. Department of Commerce, *Statistical Abstract of the United States*
#' (1979). The dataset is also available in the `sandwich` R package.
#'
#' @examples
#' data(PublicSchools)
#' PublicSchools[PublicSchools$state == "Alaska", ]
#'
#' schools <- PublicSchools |>
#'   dplyr::mutate(
#'     income_scaled = income / 10000,
#'     income_scaled_sq = income_scaled^2
#'   )
#' fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
#' hcinfer(fit, type = "hcbeta")
#'
"PublicSchools"
