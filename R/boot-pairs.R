#' Pairs bootstrap standard errors and confidence intervals
#'
#' @description
#' Computes pairs (case) bootstrap standard errors and confidence intervals for
#' the coefficients of an ordinary least squares model fitted with
#' [stats::lm()]. The pairs bootstrap resamples the observations
#' \eqn{(y_t, x_t)} with replacement, refits OLS on each resample, and
#' summarizes the resulting sampling distribution of \eqn{\hat\beta}. It makes no
#' assumption about the form of the error variance, so it is a useful empirical
#' reference for the analytic heteroskedasticity-consistent standard errors
#' produced by [hcinfer()] and [vcov_hc()].
#'
#' @details
#' For each of `B` bootstrap replicates, a sample of `n` row indices is drawn
#' with replacement from `1, ..., n`, and OLS is refitted on the resampled rows
#' \eqn{(y_{i}, x_{i})}. Writing \eqn{\hat\beta^{*}_{(r)}} for the estimate on
#' replicate `r`, the bootstrap standard error of coefficient `j` is the sample
#' standard deviation of \eqn{\hat\beta^{*}_{1,j}, \ldots, \hat\beta^{*}_{B,j}}.
#'
#' Three interval types are available through `ci_type`. Let
#' \eqn{q_\alpha} denote the empirical \eqn{\alpha} quantile of the bootstrap
#' replicates for a coefficient, \eqn{\hat\beta_j} the original estimate,
#' \eqn{s^{*}_j} the bootstrap standard error, and
#' \eqn{\alpha = 1 - \texttt{level}}.
#' The `"percentile"` interval is
#' \eqn{[q_{\alpha/2}, q_{1-\alpha/2}]}. The `"basic"` (reverse percentile)
#' interval is
#' \eqn{[2\hat\beta_j - q_{1-\alpha/2}, \; 2\hat\beta_j - q_{\alpha/2}]}. The
#' `"normal"` interval is
#' \eqn{\hat\beta_j \pm z_{1-\alpha/2}\, s^{*}_j}, with \eqn{z} the standard
#' normal quantile.
#'
#' **Reproducibility.** When `seed` is supplied, all resampling indices are drawn
#' once, sequentially, in the main process under that seed, and the per-replicate
#' fit is deterministic. The results are therefore identical whether the run is
#' sequential or parallel and regardless of the number of cores. The caller's
#' random number generator state is saved and restored, so calling `boot_pairs()`
#' does not disturb a surrounding random stream. When `seed` is `NULL`, the
#' current RNG state is used and results are not reproducible.
#'
#' **Parallelism.** The default `cores = 1` fits the replicates sequentially.
#' When `cores` rounds to `2` or more, the deterministic per-replicate fits are
#' distributed with [purrr::in_parallel()], which uses the \pkg{mirai} package
#' as its backend. `boot_pairs()` starts `cores` daemons for the duration of the
#' call and shuts them down on exit; do not call it while relying on externally
#' configured `mirai` daemons. Parallelism only speeds up the computation: it
#' never changes the numeric result. It is worthwhile mainly for large `B` or
#' large `n`; for small problems the setup overhead can dominate.
#'
#' **Rank-deficient resamples.** A resample can be rank deficient (for example
#' when a resample omits the observations that identify a coefficient). Such
#' replicates are dropped, a warning reports how many were dropped, and the
#' summaries use the remaining replicates. The call errors if fewer than two
#' valid replicates remain.
#'
#' @param object An ordinary least squares model fitted by [stats::lm()].
#'   Weighted fits are not supported.
#' @param B Number of bootstrap replicates. A positive integer; defaults to
#'   `1000`.
#' @param level Confidence level for the intervals, strictly between 0 and 1.
#'   Defaults to `0.95`.
#' @param ci_type Interval type: `"percentile"` (default), `"basic"`, or
#'   `"normal"`. See Details.
#' @param cores Number of worker processes. A single number greater than or
#'   equal to 1; non-integer values are rounded to the nearest integer. The
#'   default `1` runs the replicate fits sequentially. Any value that rounds to
#'   `2` or more runs them in parallel with [purrr::in_parallel()] and the
#'   \pkg{mirai} backend, which requires the \pkg{mirai} and \pkg{carrier}
#'   packages. Parallelism only speeds up the computation and never changes the
#'   numeric result.
#' @param seed Optional single number used to seed the resampling for
#'   reproducibility. When supplied, the result is deterministic and independent
#'   of the number of `cores`. Defaults to `NULL`.
#'
#' @return
#' An object of class `hcinfer_boot`: a list with the original OLS
#' `coefficients`, bootstrap `std_error`, `bias`, interval endpoints `conf_low`
#' and `conf_high`, the settings (`level`, `ci_type`, `B`, `B_effective`,
#' `n_failed`, `cores`, `seed`), the full `replicates` matrix
#' (`B` rows by `p` columns), and a tidy `table` tibble with columns `term`,
#' `estimate`, `bias`, `std_error`, `conf_low`, and `conf_high`. Use
#' [coef()], [vcov()], and [confint()] to extract components.
#'
#' @seealso [hcinfer()], [vcov_hc()]
#'
#' @references
#' Davison, A. C. and Hinkley, D. V. (1997). *Bootstrap Methods and their
#' Application*. Cambridge University Press. \doi{10.1017/CBO9780511802843}
#'
#' Efron, B. and Tibshirani, R. J. (1993). *An Introduction to the Bootstrap*.
#' Chapman and Hall. \doi{10.1201/9780429246593}
#'
#' @examples
#' schools <- PublicSchools |>
#'   dplyr::mutate(
#'     income_scaled = income / 10000,
#'     income_scaled_sq = income_scaled^2
#'   )
#' fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
#'
#' # 1. Fit, inspect, and visualize a reproducible pairs bootstrap.
#' boot <- boot_pairs(fit, B = 1000, seed = 123)
#' boot
#' confint(boot)
#' plot(boot)
#'
#' # 2. Use the bootstrap as an empirical reference for the analytic HC standard
#' #    errors, side by side in one table.
#' data.frame(
#'   term = boot$table$term,
#'   ols = sqrt(diag(vcov(fit))),
#'   bootstrap = boot$table$std_error,
#'   hcbeta = sqrt(diag(vcov(hcinfer(fit, type = "hcbeta")))),
#'   hc3 = sqrt(diag(vcov(hcinfer(fit, type = "hc3"))))
#' )
#'
#' # 3. Recompute intervals at a new level and type from the same replicates,
#' #    without rerunning the bootstrap.
#' confint(boot, level = 0.99, type = "basic")
#' confint(boot, parm = "income_scaled_sq", level = 0.90)
#'
#' # 4. Larger, parallel run on two cores. Requires the mirai and carrier
#' #    packages; the numeric result matches a sequential run with the same seed.
#' \donttest{
#' if (requireNamespace("mirai", quietly = TRUE) &&
#'     requireNamespace("carrier", quietly = TRUE)) {
#'   boot_par <- boot_pairs(fit, B = 4000, ci_type = "basic", cores = 2, seed = 42)
#'   boot_par$table
#' }
#' }
#'
#' @export
boot_pairs <- function(object,
                       B = 1000L,
                       level = 0.95,
                       ci_type = c("percentile", "basic", "normal"),
                       cores = 1L,
                       seed = NULL) {
  call <- match.call()
  ci_type <- rlang::arg_match(ci_type)
  B <- check_count(B, "B")
  level <- check_scalar_number(level, "level", lower = 0, upper = 1,
    closed = FALSE)
  if (!is.null(seed)) {
    seed <- check_scalar_number(seed, "seed")
  }
  if (!is.numeric(cores) || length(cores) != 1 || !is.finite(cores) || cores < 1) {
    abort_bad_argument("cores", "It must be a single number greater than or equal to 1.")
  }
  cores <- as.integer(round(cores))

  info <- model_info_lm(object)
  x <- info$x
  y <- as.numeric(stats::model.response(stats::model.frame(object)))
  n <- info$n
  p <- info$p
  coefficients <- info$coefficients
  terms <- info$terms

  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
      on.exit(assign(".Random.seed", old_seed, envir = globalenv()), add = TRUE)
    }
    set.seed(seed)
  }
  idx_list <- purrr::map(seq_len(B), function(i) sample.int(n, n, replace = TRUE))

  if (cores >= 2L) {
    rlang::check_installed(c("mirai", "carrier"), reason = "for parallel pairs bootstrap.")
    mirai::daemons(cores)
    on.exit(mirai::daemons(0), add = TRUE)
    coef_list <- purrr::map(
      idx_list,
      purrr::in_parallel(
        function(idx) boot_pairs_fit(idx, x, y, p),
        boot_pairs_fit = boot_pairs_fit,
        x = x,
        y = y,
        p = p
      )
    )
  } else {
    coef_list <- purrr::map(idx_list, function(idx) boot_pairs_fit(idx, x, y, p))
  }

  replicates <- do.call(rbind, coef_list)
  colnames(replicates) <- terms

  failed <- !stats::complete.cases(replicates)
  n_failed <- sum(failed)
  replicates_ok <- replicates[!failed, , drop = FALSE]

  if (nrow(replicates_ok) < 2L) {
    cli::cli_abort(
      c(
        "The pairs bootstrap could not produce enough valid replicates.",
        "x" = "Only {nrow(replicates_ok)} of {B} resamples yielded a full-rank fit.",
        "i" = "Increase {.arg B} or check the design matrix for near-collinearity."
      )
    )
  }
  if (n_failed > 0L) {
    cli::cli_warn(
      c(
        "Some pairs bootstrap resamples were rank deficient and were dropped.",
        "i" = "{n_failed} of {B} resamples produced a rank-deficient fit."
      )
    )
  }

  std_error <- apply(replicates_ok, 2, stats::sd)
  bias <- colMeans(replicates_ok) - coefficients
  ci <- boot_pairs_ci(replicates_ok, coefficients, std_error, level, ci_type)

  table <- tibble::tibble(
    term = terms,
    estimate = unname(coefficients),
    bias = unname(bias),
    std_error = unname(std_error),
    conf_low = unname(ci$conf_low),
    conf_high = unname(ci$conf_high)
  )

  structure(
    list(
      call = call,
      model_call = info$model_call,
      model_formula = info$model_formula,
      coefficients = coefficients,
      std_error = stats::setNames(unname(std_error), terms),
      bias = stats::setNames(unname(bias), terms),
      conf_low = stats::setNames(unname(ci$conf_low), terms),
      conf_high = stats::setNames(unname(ci$conf_high), terms),
      level = level,
      ci_type = ci_type,
      B = B,
      B_effective = nrow(replicates_ok),
      n_failed = n_failed,
      cores = cores,
      seed = seed,
      n = n,
      p = p,
      terms = terms,
      replicates = replicates,
      table = table
    ),
    class = c("hcinfer_boot", "hcinfer_object")
  )
}

boot_pairs_fit <- function(idx, x, y, p) {
  fit <- stats::.lm.fit(x[idx, , drop = FALSE], y[idx])
  if (fit$rank < p) {
    return(rep(NA_real_, p))
  }
  fit$coefficients
}

boot_pairs_ci <- function(replicates, estimate, std_error, level, ci_type) {
  alpha <- 1 - level
  probs <- c(alpha / 2, 1 - alpha / 2)
  estimate <- unname(estimate)
  std_error <- unname(std_error)

  if (ci_type == "normal") {
    z <- stats::qnorm(1 - alpha / 2)
    return(list(
      conf_low = estimate - z * std_error,
      conf_high = estimate + z * std_error
    ))
  }

  q <- apply(replicates, 2, stats::quantile, probs = probs, names = FALSE)
  lower <- unname(q[1, ])
  upper <- unname(q[2, ])

  if (ci_type == "basic") {
    return(list(
      conf_low = 2 * estimate - upper,
      conf_high = 2 * estimate - lower
    ))
  }

  list(conf_low = lower, conf_high = upper)
}

boot_display_table <- function(table) {
  tibble::tibble(
    term = table$term,
    estimate = format_number(table$estimate),
    bias = format_number(table$bias),
    boot_se = format_number(table$std_error),
    ci = format_interval(table$conf_low, table$conf_high)
  )
}

boot_select_terms <- function(table, parm, call = rlang::caller_env()) {
  if (is.numeric(parm)) {
    return(table[parm, , drop = FALSE])
  }
  if (is.character(parm)) {
    missing_terms <- setdiff(parm, table$term)
    if (length(missing_terms) > 0) {
      cli::cli_abort(
        c(
          "Unknown coefficient name in {.arg parm}.",
          "x" = "Unknown term: {.val {missing_terms}}."
        ),
        call = call
      )
    }
    return(table[match(parm, table$term), , drop = FALSE])
  }
  abort_bad_argument("parm", "It must contain coefficient names or positions.",
    call = call)
}

#' @rdname boot_pairs
#' @param x An object returned by [boot_pairs()].
#' @param ... Unused.
#' @export
print.hcinfer_boot <- function(x, ...) {
  check_dots_empty(list(...))

  title <- output_label("tests", "Pairs bootstrap inference")
  cli::cli_h1(title)

  model <- output_label("model", "Model")
  cli::cli_text("{model}: {.code {format_formula(x$model_formula)}}")
  cli::cli_text("Observations: {x$n} | Parameters: {x$p}")
  cli::cli_text("Replicates: {x$B_effective} of {x$B} valid | Interval: {x$ci_type} at {format_percent(x$level)}")

  execution <- if (x$cores >= 2L) paste0("parallel (", x$cores, " cores)") else "sequential"
  seed_text <- if (is.null(x$seed)) "none" else as.character(x$seed)
  cli::cli_text("Execution: {execution} | Seed: {seed_text}")

  cli_print_table(boot_display_table(x$table), n = Inf, width = Inf)
  invisible(x)
}

#' Extract components from a pairs bootstrap object
#'
#' @description
#' Extractors for objects returned by [boot_pairs()]. `coef()` returns the
#' original OLS coefficients, `vcov()` returns the bootstrap covariance matrix
#' (the sample covariance of the bootstrap replicates), and `confint()` returns
#' bootstrap confidence intervals, optionally recomputed at a different `level`
#' or `type` from the stored replicates.
#'
#' @param object An object returned by [boot_pairs()].
#' @param parm Optional coefficient names or integer positions.
#' @param level Confidence level for `confint()`. Defaults to the level stored
#'   in `object`.
#' @param type Interval type for `confint()`: `"percentile"`, `"basic"`, or
#'   `"normal"`. Defaults to the type stored in `object`.
#' @param ... Unused.
#'
#' @return
#' `coef()` a named numeric vector; `vcov()` a numeric covariance matrix;
#' `confint()` a tibble with columns `term`, `conf_low`, `conf_high`, and
#' `level`.
#'
#' @name hcinfer_boot-methods
NULL

#' @rdname hcinfer_boot-methods
#' @export
coef.hcinfer_boot <- function(object, ...) {
  check_dots_empty(list(...))
  object$coefficients
}

#' @rdname hcinfer_boot-methods
#' @export
vcov.hcinfer_boot <- function(object, ...) {
  check_dots_empty(list(...))
  v <- stats::cov(object$replicates, use = "complete.obs")
  dimnames(v) <- list(object$terms, object$terms)
  v
}

#' @rdname hcinfer_boot-methods
#' @export
confint.hcinfer_boot <- function(object, parm, level = object$level,
                                 type = object$ci_type, ...) {
  check_dots_empty(list(...))
  level <- check_scalar_number(level, "level", lower = 0, upper = 1,
    closed = FALSE)
  type <- rlang::arg_match(type, c("percentile", "basic", "normal"))

  replicates_ok <- object$replicates[stats::complete.cases(object$replicates), ,
    drop = FALSE]
  std_error <- apply(replicates_ok, 2, stats::sd)
  ci <- boot_pairs_ci(replicates_ok, object$coefficients, std_error, level, type)

  table <- tibble::tibble(
    term = object$terms,
    conf_low = unname(ci$conf_low),
    conf_high = unname(ci$conf_high),
    level = level
  )

  if (!missing(parm)) {
    table <- boot_select_terms(table, parm)
  }
  table
}
