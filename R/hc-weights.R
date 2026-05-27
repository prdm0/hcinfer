default_hc_args <- function(type, dots, call = rlang::caller_env()) {
  switch(
    type,
    hc0 =,
    hc1 =,
    hc2 =,
    hc3 =,
    hc4 =,
    hc4m = {
      check_dots_empty(dots, call = call)
      list()
    },
    hc5 = {
      allowed <- "k"
      check_allowed_dots(dots, allowed, call = call)
      args <- utils::modifyList(hc_default_arguments()$hc5, dots)
      args$k <- check_nonnegative_scalar(args$k, "k", call = call)
      args
    },
    hc5m = {
      allowed <- c("k", "k1", "k2", "k3", "gamma1", "gamma2")
      check_allowed_dots(dots, allowed, call = call)
      args <- utils::modifyList(hc_default_arguments()$hc5m, dots)
      args$k <- check_nonnegative_scalar(args$k, "k", call = call)
      args$k1 <- check_nonnegative_scalar(args$k1, "k1", call = call)
      args$k2 <- check_nonnegative_scalar(args$k2, "k2", call = call)
      args$k3 <- check_nonnegative_scalar(args$k3, "k3", call = call)
      args$gamma1 <- check_positive_scalar(args$gamma1, "gamma1", call = call)
      args$gamma2 <- check_positive_scalar(args$gamma2, "gamma2", call = call)
      args
    },
    hcbeta = {
      allowed <- c("c1", "c2", "lower", "upper")
      check_allowed_dots(dots, allowed, call = call)
      args <- utils::modifyList(hc_default_arguments()$hcbeta, dots)
      args$c1 <- check_nonnegative_scalar(args$c1, "c1", call = call)
      args$c2 <- check_positive_scalar(args$c2, "c2", call = call)
      args$lower <- check_scalar_number(args$lower, "lower", lower = 0, upper = 1,
        closed = FALSE, call = call
      )
      args$upper <- check_scalar_number(args$upper, "upper", lower = 0, upper = 1,
        closed = FALSE, call = call
      )
      if (args$lower >= args$upper) {
        cli::cli_abort(
          c(
            "{.arg lower} must be smaller than {.arg upper}.",
            "x" = "Got lower = {args$lower} and upper = {args$upper}."
          ),
          call = call
        )
      }
      args
    }
  )
}

hcbeta_components <- function(leverage, n, p, args, call = rlang::caller_env()) {
  u <- 1 - leverage
  w <- pmax(args$lower, pmin(u, args$upper))

  mu_hat <- mean(w)
  s2_w <- sum((w - mu_hat)^2) / (n - 1)

  if (!is.finite(s2_w) || s2_w <= .Machine$double.eps) {
    cli::cli_abort(
      c(
        "HCbeta cannot estimate beta parameters from these leverages.",
        "x" = "The sample variance of truncated leverage complements is zero or too small."
      ),
      call = call
    )
  }

  phi_hat <- mu_hat * (1 - mu_hat) / s2_w - 1
  a_hat <- mu_hat * phi_hat
  b_hat <- (1 - mu_hat) * phi_hat
  zeta <- n / (n + 50)
  a_tilde <- (1 - zeta) + zeta * a_hat
  b_tilde <- (1 - zeta) + zeta * b_hat

  if (a_tilde <= 0 || b_tilde <= 0 || !is.finite(a_tilde) || !is.finite(b_tilde)) {
    cli::cli_abort(
      c(
        "HCbeta produced invalid beta shape parameters.",
        "x" = "Both adjusted shape parameters must be positive and finite.",
        "i" = "Computed a_tilde = {a_tilde} and b_tilde = {b_tilde}."
      ),
      call = call
    )
  }

  beta_cdf <- stats::pbeta(w, a_tilde, b_tilde)
  if (any(!is.finite(beta_cdf)) || any(beta_cdf <= 0)) {
    cli::cli_abort(
      "HCbeta produced invalid beta distribution probabilities.",
      call = call
    )
  }

  weights <- (n / (n - p)) * (1 / beta_cdf)^(args$c1 / n^args$c2)

  list(
    weights = weights,
    params = c(
      args,
      list(
        mu_hat = mu_hat,
        s2_w = s2_w,
        phi_hat = phi_hat,
        a_hat = a_hat,
        b_hat = b_hat,
        zeta = zeta,
        a_tilde = a_tilde,
        b_tilde = b_tilde
      )
    )
  )
}

compute_hc_weights <- function(type, leverage, n, p, dots,
                               call = rlang::caller_env()) {
  args <- default_hc_args(type, dots, call = call)

  h_bar <- p / n
  h_max <- max(leverage)
  ratio <- leverage / h_bar
  u <- 1 - leverage

  out <- switch(
    type,
    hc0 = list(weights = rep(1, n), params = list()),
    hc1 = list(weights = rep(n / (n - p), n), params = list()),
    hc2 = list(weights = 1 / u, params = list()),
    hc3 = list(weights = 1 / u^2, params = list()),
    hc4 = {
      delta <- pmin(4, ratio)
      list(weights = u^(-delta), params = list())
    },
    hc4m = {
      delta <- pmin(1, ratio) + pmin(1.5, ratio)
      list(weights = u^(-delta), params = list())
    },
    hc5 = {
      delta <- pmin(ratio, max(4, args$k * h_max / h_bar))
      list(weights = u^(-delta), params = args)
    },
    hc5m = {
      delta <- args$k1 * pmin(args$gamma1, ratio) +
        args$k2 * pmin(args$gamma2, ratio) +
        args$k3 * pmin(ratio, max(4, args$k * h_max / h_bar))
      list(weights = u^(-delta), params = args)
    },
    hcbeta = hcbeta_components(leverage, n, p, args, call = call)
  )

  if (any(!is.finite(out$weights)) || any(out$weights <= 0)) {
    cli::cli_abort(
      "The HC weights must be positive and finite.",
      call = call
    )
  }

  names(out$weights) <- names(leverage)
  out
}
