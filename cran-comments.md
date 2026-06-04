## Resubmission

This is a resubmission of hcinfer 0.1.0 after the CRAN incoming pretest.

In this version I have:

* changed the pkgdown URL in DESCRIPTION to its canonical form with a trailing slash;
* added `inst/WORDLIST` for technical terms reported by the spell checker;
* kept version 0.1.0 because the previous upload was rejected before CRAN publication.

## R CMD check results

0 errors | 0 warnings | 2 notes

* This is a new submission.
* On the local macOS check, HTML validation was skipped because the local HTML
  Tidy binary is not recent enough, and math rendering was skipped because the
  optional V8 package is unavailable. These are local check-tool limitations.

## Test environments

* Local macOS Tahoe 26.5, R 4.5.3
