hcinfer_use_emoji <- function() {
  default <- isTRUE(l10n_info()[["UTF-8"]])
  isTRUE(getOption("hcinfer.use_emoji", default))
}

hcinfer_symbols <- function() {
  list(
    model = c(emoji = "\U0001F4D0", ascii = ""),
    covariance = c(emoji = "\U0001F96A", ascii = ""),
    leverage = c(emoji = "\U0001F3AF", ascii = ""),
    weights = c(emoji = "\u2696\ufe0f", ascii = ""),
    tests = c(emoji = "\U0001F50E", ascii = ""),
    intervals = c(emoji = "\U0001F4CF", ascii = ""),
    parameters = c(emoji = "\u2699\ufe0f", ascii = ""),
    interpretation = c(emoji = "\U0001F4A1", ascii = ""),
    warning = c(emoji = "\u26A0\ufe0f", ascii = ""),
    reject = c(emoji = "\u274C", ascii = ""),
    keep = c(emoji = "\u2705", ascii = "")
  )
}

hcinfer_symbol <- function(name) {
  symbols <- hcinfer_symbols()
  if (!name %in% names(symbols)) {
    return("")
  }

  style <- if (hcinfer_use_emoji()) "emoji" else "ascii"
  unname(symbols[[name]][[style]])
}

output_label <- function(name, text) {
  symbol <- hcinfer_symbol(name)
  if (!nzchar(symbol)) {
    return(text)
  }

  paste(symbol, text)
}

format_number <- function(x, digits = 4) {
  trimws(formatC(x, digits = digits, format = "g"))
}

format_p_value <- function(p_value, digits = 3) {
  cutoff <- 10^-digits
  formatted <- formatC(p_value, digits = digits, format = "f")
  lower_bound <- paste0("<", formatC(cutoff, digits = digits, format = "f"))

  ifelse(p_value < cutoff, lower_bound, formatted)
}

paste_symbol_text <- function(symbol, text) {
  ifelse(nzchar(symbol), paste(symbol, text), text)
}

format_test_result <- function(p_value, alpha) {
  reject <- p_value < alpha
  symbol <- ifelse(reject, hcinfer_symbol("reject"), hcinfer_symbol("keep"))
  text <- ifelse(reject, "reject H0", "do not reject H0")

  paste_symbol_text(symbol, text)
}

format_interval <- function(conf_low, conf_high) {
  paste0("[", format_number(conf_low), ", ", format_number(conf_high), "]")
}

format_interval_check <- function(conf_low, conf_high, null_value) {
  contains_null <- conf_low <= null_value & conf_high >= null_value
  ifelse(contains_null, "includes null", "excludes null")
}

format_multiplier <- function(x) {
  paste0(formatC(x, digits = 2, format = "f"), " x")
}

summary_display_table <- function(x) {
  values <- unlist(x, use.names = TRUE)
  tibble::tibble(
    statistic = names(values),
    value = unname(purrr::map_chr(values, format_number))
  )
}

method_params_display_table <- function(params, type) {
  if (length(params) == 0) {
    return(tibble::tibble())
  }

  parameter <- names(params)
  estimated_hcbeta <- c(
    "mu_hat", "s2_w", "phi_hat", "a_hat", "b_hat", "zeta",
    "a_tilde", "b_tilde"
  )
  role <- ifelse(
    type == "hcbeta" & parameter %in% estimated_hcbeta,
    "estimated quantity",
    "method constant"
  )

  tibble::tibble(
    parameter = parameter,
    value = unname(purrr::map_chr(unlist(params, use.names = FALSE), format_number)),
    role = role
  )
}

coefficient_display_table <- function(table, alpha) {
  tibble::tibble(
    term = table$term,
    estimate = format_number(table$estimate),
    robust_se = format_number(table$std_error),
    z = format_number(table$z_value),
    p_value = format_p_value(table$p_value),
    alpha = formatC(alpha, digits = 3, format = "f"),
    test_result = format_test_result(table$p_value, alpha),
    ci = format_interval(table$conf_low, table$conf_high),
    ci_relation = format_interval_check(table$conf_low, table$conf_high, table$null_value)
  )
}
