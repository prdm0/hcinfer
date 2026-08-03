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

#' State crime rates and socioeconomic indicators, 2009
#'
#' @description
#' Violent-crime and murder rates together with socioeconomic indicators for the
#' 50 U.S. states and the District of Columbia in 2009. The data are useful for
#' illustrating heteroskedasticity-consistent inference in a cross-sectional
#' design with influential observations.
#'
#' @format A tibble with 51 rows and 8 variables:
#' \describe{
#'   \item{state}{Name of one of the 50 U.S. states or the District of Columbia.}
#'   \item{violent}{Violent-crime rate per 100,000 population.}
#'   \item{murder}{Murder rate per 100,000 population.}
#'   \item{hs_grad}{Percentage of the population that graduated from high school
#'   or higher.}
#'   \item{poverty}{Percentage of the population living below the poverty line.}
#'   \item{single}{Percentage of households headed by a single parent.}
#'   \item{white}{Percentage of the population that is white.}
#'   \item{urban}{Percentage of the population living in urban areas.}
#' }
#'
#' @source
#' French, J. P. (2023). *api2lm: Functions and Data Sets for the Book 'A
#' Progressive Introduction to Linear Models'*. R package version 0.2.
#' \doi{10.32614/CRAN.package.api2lm}. The same data are distributed as the
#' `statecrime` dataset in the Python `statsmodels` package (Seabold and
#' Perktold, 2010, <https://www.statsmodels.org/>); the underlying figures come
#' from the *Statistical Abstract of the United States* (2009) and are in the
#' public domain.
#'
#' @examples
#' data(Crime2009)
#' Crime2009[Crime2009$state == "Alabama", ]
#'
#' fit <- lm(murder ~ hs_grad + poverty + single, data = Crime2009)
#' hcinfer(fit, type = "hcbeta")
#'
"Crime2009"

#' Boston-area home prices, 1990
#'
#' @description
#' Sale prices, assessed values, and physical characteristics of 88 homes sold
#' in the Boston, Massachusetts area in 1990. The data are widely used to
#' illustrate regression and heteroskedasticity-consistent inference.
#'
#' @format A tibble with 88 rows and 10 variables:
#' \describe{
#'   \item{price}{House price, in thousands of U.S. dollars.}
#'   \item{assess}{Assessed value, in thousands of U.S. dollars.}
#'   \item{bdrms}{Number of bedrooms.}
#'   \item{lotsize}{Size of the lot, in square feet.}
#'   \item{sqrft}{Size of the house, in square feet.}
#'   \item{colonial}{Indicator equal to 1 if the home is of colonial style.}
#'   \item{lprice}{Natural logarithm of `price`.}
#'   \item{lassess}{Natural logarithm of `assess`.}
#'   \item{llotsize}{Natural logarithm of `lotsize`.}
#'   \item{lsqrft}{Natural logarithm of `sqrft`.}
#' }
#'
#' @source
#' Wooldridge, J. M. (2020). *Introductory Econometrics: A Modern Approach*,
#' 7th ed. Cengage Learning, Boston, MA. The `hprice1` data are distributed with
#' the `wooldridge` R package and were originally collected from the real estate
#' pages of the *Boston Globe*.
#'
#' @examples
#' data(Hprice)
#' head(Hprice)
#'
#' fit <- lm(price ~ lotsize + bdrms + bdrms:sqrft, data = Hprice)
#' hcinfer(fit, type = "hcbeta")
#'
"Hprice"
