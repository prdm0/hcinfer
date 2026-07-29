# Build Hprice package data.
source_file <- file.path("..", "outros_dados", "Hprice.RData")
if (!file.exists(source_file)) {
  stop("Cannot find Hprice.RData in outros_dados/.")
}
env <- new.env(parent = emptyenv())
load(source_file, envir = env) # loads `hprice1`, an 88x10 data.frame

Hprice <- tibble::as_tibble(env$hprice1)

save(Hprice, file = file.path("data", "Hprice.rda"), compress = "xz")
