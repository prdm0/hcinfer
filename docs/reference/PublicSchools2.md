# Public school expenditure, income, and region by U.S. jurisdiction

Public school expenditure and per capita income for the 50 U.S. states
and the District of Columbia. Income is measured for 2024, and
expenditure is measured for 2025. The regional indicator uses the U.S.
Census Bureau classification of the Southern United States.

## Usage

``` r
PublicSchools2
```

## Format

A tibble with 51 rows and 4 variables:

- state:

  Character. Name of one of the 50 U.S. states or the District of
  Columbia.

- income:

  Integer. Annual per capita personal income for 2024, in nominal U.S.
  dollars. It is calculated as total personal income for the
  jurisdiction divided by its population.

- expenditure:

  Integer. Annual expenditure per student enrolled in K-12 public
  schools for 2025, in U.S. dollars. It includes instructional salaries
  and expenses, school support, and administrative services.

- south:

  Integer. Indicator equal to 1 for Alabama, Arkansas, Delaware, the
  District of Columbia, Florida, Georgia, Kentucky, Louisiana, Maryland,
  Mississippi, North Carolina, Oklahoma, South Carolina, Tennessee,
  Texas, Virginia, and West Virginia, and 0 otherwise.

## Source

World Population Review (2026), *Per Capita Income by State*,
<https://worldpopulationreview.com/state-rankings/per-capita-income-by-state>.
Accessed June 11, 2026. The supplied data dictionary also attributes the
income measure to the U.S. Bureau of Economic Analysis.

World Population Review (2026), *Per Pupil Spending by State*,
<https://worldpopulationreview.com/state-rankings/per-pupil-spending-by-state>.
Accessed June 11, 2026.

U.S. Census Bureau, *Terms and Definitions: Census Regions and
Divisions*,
<https://www.census.gov/programs-surveys/popest/guidance-geographies/terms-and-definitions.html>.

Wikipedia, *Southern United States*,
<https://en.wikipedia.org/wiki/Southern_United_States>. This was the
geographic source recorded in the supplied data dictionary. Accessed
June 11, 2026.

## Examples

``` r
data(PublicSchools2)
PublicSchools2[PublicSchools2$state == "District of Columbia", ]
#> # A tibble: 1 × 4
#>   state                income expenditure south
#>   <chr>                 <int>       <int> <int>
#> 1 District of Columbia  77348       31629     1
table(PublicSchools2$south)
#> 
#>  0  1 
#> 34 17 
```
