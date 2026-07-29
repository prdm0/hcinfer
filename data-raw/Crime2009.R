# Build Crime2009 package data.
source_file <- file.path("..", "outros_dados", "Crime2009.RData")
if (!file.exists(source_file)) {
  stop("Cannot find Crime2009.RData in outros_dados/.")
}
env <- new.env(parent = emptyenv())
load(source_file, envir = env) # loads `crime2009`, a 51x7 data.frame with state row names

Crime2009 <- tibble::tibble(
  state = rownames(env$crime2009),
  violent = as.numeric(env$crime2009$violent),
  murder = as.numeric(env$crime2009$murder),
  hs_grad = as.numeric(env$crime2009$hs_grad),
  poverty = as.numeric(env$crime2009$poverty),
  single = as.numeric(env$crime2009$single),
  white = as.numeric(env$crime2009$white),
  urban = as.numeric(env$crime2009$urban)
)

save(Crime2009, file = file.path("data", "Crime2009.rda"), compress = "xz")
