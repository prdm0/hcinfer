# Clean R CMD check for hcinfer.
#
# The package sits inside a Dropbox-synced directory. When R CMD check installs
# the package into hcinfer.Rcheck under that directory, the staged-install lock
# 00LOCK-hcinfer survives the install, and the check then reports it under
# "checking for non-standard things in the check directory". Running the check
# outside the synced tree removes the cause: no sync client then holds or
# recreates the lock directory after R unlinks it. Disabling the lock instead
# (--install-args=--no-lock) is not an option, since it forces a non-staged
# installation, which --as-cran reports as a NOTE of its own.
#
# Run from the package root:
#   Rscript dev/check.R

# dirname(tempdir()) is the per-user temporary directory, which lives outside the
# synced tree and, unlike the per-session tempdir(), survives this script so that
# the check log and the built vignettes can be inspected afterwards.
check_dir <- Sys.getenv(
  "HCINFER_CHECK_DIR",
  unset = file.path(dirname(tempdir()), "hcinfer-check")
)
unlink(check_dir, recursive = TRUE, force = TRUE)
dir.create(check_dir, recursive = TRUE, showWarnings = FALSE)

message("Check directory: ", check_dir)

devtools::check(
  document = TRUE,
  args = "--timings",
  check_dir = check_dir,
  error_on = "warning"
)

installed <- file.path(check_dir, "hcinfer.Rcheck", "hcinfer")
if (dir.exists(installed)) {
  sizes <- vapply(
    c(total = installed, doc = file.path(installed, "doc")),
    function(path) sum(file.info(list.files(path, recursive = TRUE, full.names = TRUE))$size, na.rm = TRUE),
    numeric(1)
  )
  message(sprintf(
    "Installed size: %.1f MB (doc: %.1f MB)",
    sizes[["total"]] / 1024^2, sizes[["doc"]] / 1024^2
  ))
}

leftovers <- list.files(file.path(check_dir, "hcinfer.Rcheck"), pattern = "^00LOCK")
if (length(leftovers)) {
  stop("Lock directory left in the check directory: ", paste(leftovers, collapse = ", "))
}
