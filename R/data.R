#' Public school expenditure and income by U.S. jurisdiction
#'
#' @description
#' Public school expenditure and income data for the 50 U.S. states and the
#' District of Columbia in 1979. The expenditure value for Wisconsin is missing
#' in the source data, so the standard regression example uses 50 complete
#' observations. The data are useful for illustrating
#' heteroskedasticity-consistent inference because Alaska is a high-leverage
#' observation in the quadratic public-schools model studied in the HCbeta
#' paper.
#'
#' @format A tibble with 51 rows and 3 variables:
#' \describe{
#'   \item{state}{Name of one of the 50 U.S. states or the District of
#'   Columbia.}
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

#' Public school expenditure, income, and region by U.S. jurisdiction
#'
#' @description
#' Public school expenditure and per capita income for the 50 U.S. states and
#' the District of Columbia. Income is measured for 2024, and expenditure is
#' measured for 2025. The regional indicator uses the U.S. Census Bureau
#' classification of the Southern United States.
#'
#' @format A tibble with 51 rows and 4 variables:
#' \describe{
#'   \item{state}{Character. Name of one of the 50 U.S. states or the District
#'   of Columbia.}
#'   \item{income}{Integer. Annual per capita personal income for 2024, in
#'   nominal U.S. dollars. It is calculated as total personal income for the
#'   jurisdiction divided by its population.}
#'   \item{expenditure}{Integer. Annual expenditure per student enrolled in
#'   K-12 public schools for 2025, in U.S. dollars. It includes instructional
#'   salaries and expenses, school support, and administrative services.}
#'   \item{south}{Integer. Indicator equal to 1 for Alabama, Arkansas,
#'   Delaware, the District of Columbia, Florida, Georgia, Kentucky, Louisiana,
#'   Maryland, Mississippi, North Carolina, Oklahoma, South Carolina,
#'   Tennessee, Texas, Virginia, and West Virginia, and 0 otherwise.}
#' }
#'
#' @source
#' World Population Review (2026), *Per Capita Income by State*,
#' <https://worldpopulationreview.com/state-rankings/per-capita-income-by-state>.
#' Accessed June 11, 2026. The supplied data dictionary also attributes the
#' income measure to the U.S. Bureau of Economic Analysis.
#'
#' World Population Review (2026), *Per Pupil Spending by State*,
#' <https://worldpopulationreview.com/state-rankings/per-pupil-spending-by-state>.
#' Accessed June 11, 2026.
#'
#' U.S. Census Bureau, *Terms and Definitions: Census Regions and Divisions*,
#' <https://www.census.gov/programs-surveys/popest/guidance-geographies/terms-and-definitions.html>.
#'
#' Wikipedia, *Southern United States*,
#' <https://en.wikipedia.org/wiki/Southern_United_States>. This was the
#' geographic source recorded in the supplied data dictionary. Accessed June
#' 11, 2026.
#'
#' @examples
#' data(PublicSchools2)
#' PublicSchools2[PublicSchools2$state == "District of Columbia", ]
#' table(PublicSchools2$south)
#'
"PublicSchools2"
