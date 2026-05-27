# Build PublicSchools package data.

source_file <- file.path("..", "PublicSchools.RData")

if (!file.exists(source_file)) {
  stop("Cannot find PublicSchools.RData in the project root.")
}

env <- new.env(parent = emptyenv())
load(source_file, envir = env)

PublicSchools <- tibble::tibble(
  state = rownames(env$PublicSchools),
  expenditure = as.numeric(env$PublicSchools$Expenditure),
  income = as.numeric(env$PublicSchools$Income)
)

save(PublicSchools, file = file.path("data", "PublicSchools.rda"), compress = "xz")
