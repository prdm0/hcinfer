# Build PublicSchools2 package data.

source_file <- file.path("..", "PublicSchools2.RData")

if (!file.exists(source_file)) {
  stop("Cannot find PublicSchools2.RData in the project root.")
}

env <- new.env(parent = emptyenv())
loaded_objects <- load(source_file, envir = env)

if (!identical(loaded_objects, "PublicSchools2")) {
  stop("PublicSchools2.RData must contain only an object named PublicSchools2.")
}

expected_names <- c("state", "income", "expenditure", "south")

if (!identical(names(env$PublicSchools2), expected_names)) {
  stop(
    "PublicSchools2 must contain state, income, expenditure, and south, in that order."
  )
}

PublicSchools2 <- tibble::as_tibble(env$PublicSchools2)

save(
  PublicSchools2,
  file = file.path("data", "PublicSchools2.rda"),
  compress = "xz"
)
