#' Plot robust confidence intervals
#'
#' @description
#' Plots normal Wald confidence intervals for an [hcinfer()] result. Each
#' interval is color-coded by the test decision at the stored significance
#' level: coefficients for which the null hypothesis is rejected are shown in
#' red, and those for which it is not rejected are shown in blue. Formatted
#' p-values are printed to the right of each interval for quick reading.
#'
#' @param x An object returned by [hcinfer()].
#' @param parm Optional coefficient names or integer positions. When supplied,
#'   only the selected coefficients are plotted. The selection follows the same
#'   rules as [confint.hcinfer()] and [tests.hcinfer()].
#' @param ... Unused. Passing named arguments raises an error.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [hcinfer()], [confint.hcinfer()], [tests.hcinfer()]
#'
#' @examples
#' schools <- PublicSchools |>
#'   dplyr::mutate(
#'     income_scaled = income / 10000,
#'     income_scaled_sq = income_scaled^2
#'   )
#' fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
#' result <- hcinfer(fit)
#' plot(result)
#' plot(result, parm = "income_scaled_sq")
#'
#' @export
plot.hcinfer <- function(x, parm, ...) {
  check_dots_empty(list(...))

  plot_data <- x$table

  if (!missing(parm)) {
    if (is.numeric(parm)) {
      plot_data <- plot_data[parm, , drop = FALSE]
    } else if (is.character(parm)) {
      missing_terms <- setdiff(parm, plot_data$term)
      if (length(missing_terms) > 0) {
        cli::cli_abort(
          c(
            "Unknown coefficient name in {.arg parm}.",
            "x" = "Unknown term: {.val {missing_terms}}."
          )
        )
      }
      plot_data <- plot_data[match(parm, plot_data$term), , drop = FALSE]
    } else {
      abort_bad_argument("parm", "It must contain coefficient names or positions.")
    }
  }

  plot_data$term <- factor(plot_data$term, levels = rev(plot_data$term))
  plot_data$decision <- ifelse(
    plot_data$p_value < x$alpha,
    "reject H0",
    "do not reject H0"
  )
  plot_data$p_label <- format_p_label(plot_data$p_value)

  pal <- c(
    "reject H0"        = "#c0392b",
    "do not reject H0" = "#2c5f8a"
  )

  null_vals   <- unique(x$null[names(x$null) %in% as.character(plot_data$term)])
  single_null <- length(null_vals) == 1

  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(y = .data$term, color = .data$decision)
  ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x    = .data$conf_low,
        xend = .data$conf_high,
        yend = .data$term
      ),
      linewidth = 1
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data$estimate),
      size  = 3.2,
      shape = 19
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$conf_high, label = .data$p_label),
      hjust       = -0.12,
      size        = 3.1,
      fontface    = "italic",
      show.legend = FALSE
    ) +
    ggplot2::scale_color_manual(
      name   = NULL,
      values = pal,
      breaks = c("do not reject H0", "reject H0"),
      labels = c(
        expression("do not reject" ~ H[0]),
        expression("reject" ~ H[0])
      ),
      guide  = ggplot2::guide_legend(
        override.aes = list(shape = 19, linewidth = 2),
        reverse      = FALSE
      )
    ) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.05, 0.28))
    ) +
    ggplot2::labs(
      title    = paste0(x$label, " robust confidence intervals"),
      subtitle = paste0(format_percent(x$confidence_level), " normal Wald intervals"),
      caption  = build_plot_caption(x),
      x        = "Coefficient estimate",
      y        = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title              = ggplot2::element_text(
        face = "bold", size = 13
      ),
      plot.subtitle           = ggplot2::element_text(
        color  = "grey40",
        margin = ggplot2::margin(b = 4)
      ),
      plot.caption            = ggplot2::element_text(
        color = "grey50", size = 8, hjust = 0
      ),
      plot.title.position     = "plot",
      plot.caption.position   = "plot",
      axis.text.y             = ggplot2::element_text(face = "bold", size = 10.5),
      axis.text.x             = ggplot2::element_text(color = "grey40", size = 9),
      panel.grid.major.y      = ggplot2::element_blank(),
      panel.grid.minor        = ggplot2::element_blank(),
      panel.grid.major.x      = ggplot2::element_line(
        color     = "grey90",
        linewidth = 0.4
      ),
      legend.position         = "bottom",
      legend.text             = ggplot2::element_text(size = 9),
      legend.key.width        = ggplot2::unit(2, "cm"),
      legend.margin           = ggplot2::margin(t = 2)
    )

  if (single_null) {
    p <- p +
      ggplot2::geom_vline(
        xintercept = null_vals,
        linewidth  = 0.3,
        linetype   = "dashed",
        color      = "#2c5f8a"
      ) +
      ggplot2::annotate(
        "text",
        x     = null_vals,
        y     = Inf,
        label = paste0(
          'paste(H[0], ": ", beta[j], " = ", beta[j]^"(0)", " = ", "',
          format_number(null_vals),
          '")'
        ),
        parse = TRUE,
        hjust = -0.12,
        vjust = 1.6,
        size  = 2.9,
        color = "grey50"
      )
  } else {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(x = .data$null_value),
        shape  = 4,
        size   = 2.5,
        color  = "grey55",
        stroke = 0.9
      )
  }

  p
}

#' Plot HC adjustment factors against leverages
#'
#' @description
#' Plots the HC adjustment factors \eqn{g_t} against the leverage values
#' \eqn{h_t} stored in a [vcov_hc()] object. Points with
#' \eqn{h_t > 3p/n} are highlighted because this threshold is commonly used to
#' flag high-leverage observations in the empirical examples from the HCbeta
#' paper.
#'
#' @param x An object returned by [vcov_hc()].
#' @param label_top A nonnegative whole number. The observations with the
#'   largest adjustment factors are labeled. Use `0` to suppress labels.
#' @param ... Unused. Passing named arguments raises an error.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @seealso [vcov_hc()], [hcinfer()], [plot.hcinfer()]
#'
#' @examples
#' schools <- PublicSchools |>
#'   dplyr::mutate(
#'     income_scaled = income / 10000,
#'     income_scaled_sq = income_scaled^2
#'   )
#' fit <- lm(expenditure ~ income_scaled + income_scaled_sq, data = schools)
#'
#' cov <- vcov_hc(fit, type = "hcbeta")
#' plot(cov)
#' plot(vcov_hc(fit, type = "hc4"), label_top = 2)
#'
#' @export
plot.hcinfer_vcov <- function(x, label_top = 3, ...) {
  check_dots_empty(list(...))
  check_label_top(label_top)

  threshold <- 3 * x$p / x$n
  plot_data <- tibble::tibble(
    observation = x$observation,
    leverage = unname(x$leverage),
    weight = unname(x$weights),
    high_leverage = unname(x$leverage) > threshold
  )

  label_data <- top_weight_rows(plot_data, label_top)
  pal <- c(`FALSE` = "#2c5f8a", `TRUE` = "#c0392b")

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = .data$leverage, y = .data$weight)
  ) +
    ggplot2::geom_vline(
      xintercept = threshold,
      linewidth = 0.35,
      linetype = "dashed",
      color = "#c0392b"
    ) +
    ggplot2::geom_point(
      ggplot2::aes(color = .data$high_leverage),
      size = 2.6,
      alpha = 0.9
    ) +
    ggplot2::geom_text(
      data = label_data,
      ggplot2::aes(label = .data$observation),
      hjust = -0.15,
      vjust = -0.35,
      size = 3,
      color = "grey25",
      check_overlap = TRUE,
      show.legend = FALSE
    ) +
    ggplot2::scale_color_manual(
      name = NULL,
      values = pal,
      breaks = c(FALSE, TRUE),
      labels = c("regular leverage", "high leverage")
    ) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.04, 0.12))
    ) +
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = c(0.04, 0.12))
    ) +
    ggplot2::labs(
      title = paste0(x$label, " adjustment factors"),
      subtitle = "HC weights versus leverage values",
      caption = build_weight_plot_caption(x, threshold),
      x = expression(h[t]),
      y = expression(g[t])
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 13),
      plot.subtitle = ggplot2::element_text(color = "grey40"),
      plot.caption = ggplot2::element_text(color = "grey50", size = 8, hjust = 0),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      axis.title = ggplot2::element_text(face = "bold"),
      axis.text = ggplot2::element_text(color = "grey40"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(color = "grey90", linewidth = 0.4),
      legend.position = "bottom",
      legend.text = ggplot2::element_text(size = 9)
    )
}

check_label_top <- function(label_top, call = rlang::caller_env()) {
  if (!is.numeric(label_top) || length(label_top) != 1 || !is.finite(label_top)) {
    abort_bad_argument("label_top", "It must be one nonnegative whole number.", call = call)
  }
  if (label_top < 0 || label_top != floor(label_top)) {
    abort_bad_argument("label_top", "It must be one nonnegative whole number.", call = call)
  }

  invisible(label_top)
}

top_weight_rows <- function(plot_data, label_top) {
  if (label_top == 0 || nrow(plot_data) == 0) {
    return(plot_data[0, , drop = FALSE])
  }

  n_labels <- min(label_top, nrow(plot_data))
  plot_data[order(plot_data$weight, decreasing = TRUE)[seq_len(n_labels)], , drop = FALSE]
}

format_p_label <- function(p_value, digits = 3) {
  cutoff <- 10^-digits
  below  <- p_value < cutoff
  label  <- formatC(p_value, digits = digits, format = "f")
  bound  <- paste0("<", formatC(cutoff, digits = digits, format = "f"))
  paste0("p-value ", ifelse(below, bound, paste0("= ", label)))
}

build_plot_caption <- function(x) {
  null_vals    <- unique(x$null)
  null_val_str <- format_number(null_vals[[1]])

  if (length(null_vals) == 1) {
    bquote(
      paste(
        "n = ", .(x$n), "  \u00b7  ",
        alpha, " = ", .(x$alpha), "  \u00b7  ",
        beta[j]^"(0)", " = ", .(null_val_str)
      )
    )
  } else {
    bquote(
      paste(
        "n = ", .(x$n), "  \u00b7  ",
        alpha, " = ", .(x$alpha), "  \u00b7  ",
        beta[j]^"(0)", ": per coefficient"
      )
    )
  }
}

build_weight_plot_caption <- function(x, threshold) {
  threshold_str <- format_number(threshold)

  bquote(
    paste(
      "n = ", .(x$n), "  \u00b7  ",
      "p = ", .(x$p), "  \u00b7  ",
      "high leverage: ", h[t], " > 3p/n = ", .(threshold_str)
    )
  )
}
