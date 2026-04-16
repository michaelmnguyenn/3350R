suppressPackageStartupMessages({
  library(readxl)
  library(forecast)
  library(rugarch)
})

script_file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])
if (is.na(script_file)) script_file <- "_extras/regenerate_report_artifacts.R"
root <- normalizePath(file.path(dirname(script_file), ".."), mustWork = FALSE)
if (!dir.exists(root) || !file.exists(file.path(root, "MacroData (1).xlsx"))) {
  root <- getwd()
}
setwd(root)

fig_width <- 1500
fig_height <- 600
fig_res <- 150
quarter_labels <- paste(rep(2024:2025, each = 4), paste0("Q", 1:4), sep = "")
eval_quarters <- quarter_labels[1:7]

load_macro_data <- function() {
  df_full <- read_excel("MacroData (1).xlsx", sheet = "data")
  names(df_full)[1:5] <- c("date", "p", "r", "y", "c")
  df_full <- as.data.frame(df_full[, 1:5])
  df_full$date <- as.Date(df_full$date)
  df <- df_full[1:260, ]
  df$pt <- log(df$p)
  df$yt <- log(df$y)
  df$ct <- log(df$c)
  df$dpt <- c(NA_real_, diff(df$pt))
  df$dyt <- c(NA_real_, diff(df$yt))
  df$dct <- c(NA_real_, diff(df$ct))
  df$trend <- seq_len(nrow(df))
  df$inflation_pct <- 100 * df$dpt
  df$rr <- df$r - df$inflation_pct
  df$cy <- df$c / df$y
  attr(df, "p_future") <- df_full$p[261:267]
  df
}

load_fx_data <- function() {
  ex <- read_excel("EXRATE (1).xlsx", sheet = "All")
  names(ex)[1:5] <- c("date", "CNY", "USD", "TWI", "SDR")
  ex <- as.data.frame(ex[, 1:5])
  ex$date <- as.Date(ex$date)
  returns <- lapply(ex[, c("CNY", "USD", "TWI", "SDR")], function(x) 100 * diff(log(x)))
  list(data = ex, dates = ex$date[-1], returns = returns)
}

lb_p_value <- function(x, lag, fitdf) {
  Box.test(x, lag = lag, type = "Ljung-Box", fitdf = fitdf)$p.value
}

search_arima <- function(series, d_values, p_max, q_max, lb_lag) {
  rows <- list()
  fits <- list()
  idx <- 0
  for (d in d_values) {
    for (p in 0:p_max) {
      for (q in 0:q_max) {
        fit <- tryCatch(
          Arima(series, order = c(p, d, q),
                include.mean = (d == 0),
                include.drift = (d > 0),
                method = "ML"),
          error = function(e) NULL
        )
        if (!is.null(fit)) {
          idx <- idx + 1
          fits[[idx]] <- fit
          rows[[idx]] <- data.frame(
            d = d, p = p, q = q,
            aic = AIC(fit),
            bic = BIC(fit),
            lb_p = lb_p_value(residuals(fit), lag = lb_lag, fitdf = p + q)
          )
        }
      }
    }
  }
  info <- do.call(rbind, rows)
  info$fit_id <- seq_len(nrow(info))
  info <- info[order(info$aic, info$bic), ]
  list(info = info, fits = fits)
}

fit_exact_arima <- function(series, order_vec) {
  Arima(series, order = order_vec,
        include.mean = (order_vec[2] == 0),
        include.drift = (order_vec[2] > 0),
        method = "ML")
}

engle_arch_lm <- function(x, lags = 10) {
  e2 <- x^2
  n <- length(e2) - lags
  y <- e2[(lags + 1):length(e2)]
  X <- sapply(seq_len(lags), function(j) e2[(lags + 1 - j):(length(e2) - j)])
  fit <- lm(y ~ X)
  lm_stat <- n * summary(fit)$r.squared
  c(statistic = lm_stat, p_value = 1 - pchisq(lm_stat, df = lags))
}

parse_mean_model <- function(model_label) {
  as.integer(regmatches(model_label, gregexpr("[0-9]+", model_label))[[1]])
}

fit_garch <- function(x, arma_order, garch_order, distribution = "norm", include_mean = TRUE) {
  spec <- ugarchspec(
    variance.model = list(model = "sGARCH", garchOrder = garch_order),
    mean.model = list(armaOrder = arma_order, include.mean = include_mean),
    distribution.model = distribution
  )
  ugarchfit(spec, data = x, solver = "hybrid")
}

garch_unconditional_variance <- function(fit) {
  cf <- coef(fit)
  persistence <- sum(cf[grep("alpha|beta", names(cf))], na.rm = TRUE)
  c(persistence = persistence, model_variance = unname(cf["omega"] / (1 - persistence)))
}

macro <- load_macro_data()
fx <- load_fx_data()

dpt_ts <- ts(na.omit(macro$dpt), start = c(1959, 2), frequency = 4)
rt_ts <- ts(macro$r, start = c(1959, 1), frequency = 4)
rr_ts <- ts(na.omit(macro$rr), start = c(1959, 2), frequency = 4)
cy_ts <- ts(macro$cy, start = c(1959, 1), frequency = 4)

q1_trends <- list(
  p = lm(pt ~ trend, data = macro),
  y = lm(yt ~ trend, data = macro),
  c = lm(ct ~ trend, data = macro)
)
q1_means <- c(
  dpt = mean(macro$dpt, na.rm = TRUE),
  dyt = mean(macro$dyt, na.rm = TRUE),
  dct = mean(macro$dct, na.rm = TRUE)
)

q2_dpt_search <- search_arima(dpt_ts, d_values = 0, p_max = 10, q_max = 10, lb_lag = 20)
q2_dpt_orders <- list(c(3, 0, 3), c(1, 0, 6), c(5, 0, 6))
q2_dpt_models <- setNames(
  lapply(q2_dpt_orders, function(ord) fit_exact_arima(dpt_ts, ord)),
  vapply(q2_dpt_orders, function(ord) sprintf("ARIMA(%d,%d,%d)", ord[1], ord[2], ord[3]), character(1))
)
q2_dpt_top3 <- do.call(rbind, lapply(seq_along(q2_dpt_models), function(i) {
  ord <- q2_dpt_orders[[i]]
  fit <- q2_dpt_models[[i]]
  data.frame(
    d = ord[2], p = ord[1], q = ord[3],
    aic = AIC(fit), bic = BIC(fit),
    lb_p = lb_p_value(residuals(fit), lag = 20, fitdf = ord[1] + ord[3])
  )
}))
q2_dpt_adequate <- q2_dpt_top3
q2_dpt_models <- setNames(
  q2_dpt_models,
  names(q2_dpt_models)
)
q2_dpt_forecasts <- lapply(q2_dpt_models, function(fit) forecast::forecast(fit, h = 8, level = c(68, 95)))
q2_model_names <- names(q2_dpt_forecasts)

q2_rt_search <- search_arima(rt_ts, d_values = c(0, 1), p_max = 10, q_max = 10, lb_lag = 20)
q2_rt_orders <- list(c(4, 0, 6), c(8, 0, 1), c(9, 0, 1))
q2_rt_models <- setNames(
  lapply(q2_rt_orders, function(ord) fit_exact_arima(rt_ts, ord)),
  vapply(q2_rt_orders, function(ord) sprintf("ARIMA(%d,%d,%d)", ord[1], ord[2], ord[3]), character(1))
)
q2_rt_adequate <- do.call(rbind, lapply(seq_along(q2_rt_models), function(i) {
  ord <- q2_rt_orders[[i]]
  fit <- q2_rt_models[[i]]
  data.frame(
    d = ord[2], p = ord[1], q = ord[3],
    aic = AIC(fit), bic = BIC(fit),
    lb_p = lb_p_value(residuals(fit), lag = 20, fitdf = ord[1] + ord[3])
  )
}))
q2_rt_fit <- q2_rt_models[[1]]

actual_p_future <- attr(macro, "p_future")
actual_dpt <- diff(log(c(macro$p[260], actual_p_future)))
q3_eval <- do.call(rbind, lapply(names(q2_dpt_forecasts), function(nm) {
  pred <- as.numeric(q2_dpt_forecasts[[nm]]$mean[1:7])
  data.frame(
    model = nm,
    msfe = mean((actual_dpt - pred)^2),
    rmsfe = sqrt(mean((actual_dpt - pred)^2)),
    mae = mean(abs(actual_dpt - pred))
  )
}))

q4_rr_search <- search_arima(rr_ts, d_values = c(0, 1), p_max = 10, q_max = 10, lb_lag = 20)
q4_rr_adequate <- q4_rr_search$info[q4_rr_search$info$lb_p > 0.05, ]
q4_rr_adequate <- q4_rr_adequate[order(q4_rr_adequate$aic, q4_rr_adequate$bic), ]
q4_rr_fit <- Arima(rr_ts, order = c(7, 1, 1), include.mean = FALSE, include.drift = FALSE, method = "ML")
q4_rr_selected <- data.frame(
  const = 0, trend = 0, p = 7, d = 1, q = 1,
  aic = AIC(q4_rr_fit), bic = BIC(q4_rr_fit),
  lb_p = lb_p_value(residuals(q4_rr_fit), lag = 8, fitdf = 0)
)
q4_cy_search <- search_arima(cy_ts, d_values = c(0, 1), p_max = 6, q_max = 6, lb_lag = 8)
q4_cy_trend <- seq_along(cy_ts)
q4_cy_fit <- Arima(cy_ts, order = c(3, 0, 2), xreg = q4_cy_trend, include.constant = TRUE)
q4_cy_selected <- data.frame(
  const = 1, trend = 1, p = 3, d = 0, q = 2,
  aic = AIC(q4_cy_fit), bic = BIC(q4_cy_fit),
  lb_p = lb_p_value(residuals(q4_cy_fit), lag = 8, fitdf = 0)
)

q5_sample_vars <- sapply(fx$returns, var)

q6_arma_specs <- data.frame(
  currency = c("CNY", "USD", "TWI", "SDR"),
  arma_model = c("ARMA(2,3)", "ARMA(1,0)", "ARMA(1,3)", "ARMA(0,1)"),
  stringsAsFactors = FALSE
)

q6_arma_fits <- lapply(seq_len(nrow(q6_arma_specs)), function(i) {
  row <- q6_arma_specs[i, ]
  arma_order <- parse_mean_model(row$arma_model)
  Arima(fx$returns[[row$currency]], order = c(arma_order[1], 0, arma_order[2]),
        include.mean = TRUE, method = "ML")
})
names(q6_arma_fits) <- q6_arma_specs$currency

q6_arma_table <- do.call(rbind, lapply(names(q6_arma_fits), function(name) {
  fit <- q6_arma_fits[[name]]
  ord <- parse_mean_model(q6_arma_specs[q6_arma_specs$currency == name, "arma_model"])
  data.frame(
    currency = name,
    arma_model = q6_arma_specs[q6_arma_specs$currency == name, "arma_model"],
    aic = AIC(fit),
    bic = BIC(fit),
    lb_p = lb_p_value(residuals(fit), lag = 10, fitdf = sum(ord))
  )
}))

q6_arch_tests <- do.call(rbind, lapply(names(fx$returns), function(name) {
  x <- as.numeric(residuals(q6_arma_fits[[name]]))
  arch <- engle_arch_lm(x, lags = 10)
  data.frame(
    currency = name,
    arch_lm = arch["statistic"],
    arch_p = arch["p_value"],
    lb_sq_p = lb_p_value(x^2, lag = 10, fitdf = 0)
  )
}))

q6_report_specs <- data.frame(
  currency = c("CNY", "USD", "TWI", "SDR"),
  mean_model = c("ARMA(2,2)", "ARMA(2,2)", "ARMA(2,2)", "ARMA(2,2)"),
  variance_model = c("sGARCH", "sGARCH", "sGARCH", "sGARCH"),
  garch_label = c("GARCH(2,2)", "GARCH(2,2)", "GARCH(2,2)", "GARCH(2,1)"),
  arch_order = c(2, 2, 2, 1),
  garch_order = c(2, 2, 2, 2),
  distribution = c("norm", "norm", "norm", "norm"),
  include_mean = c(FALSE, TRUE, TRUE, TRUE),
  stringsAsFactors = FALSE
)
q6_final_fits <- lapply(seq_len(nrow(q6_report_specs)), function(i) {
  row <- q6_report_specs[i, ]
  fit_garch(fx$returns[[row$currency]], parse_mean_model(row$mean_model),
            c(row$arch_order, row$garch_order), row$distribution, row$include_mean)
})
names(q6_final_fits) <- q6_report_specs$currency

q6_model_ic <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  ic <- infocriteria(q6_final_fits[[name]])
  data.frame(currency = name, aic = ic[1], bic = ic[2])
}))
q6_coefficients <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  cf <- coef(q6_final_fits[[name]])
  data.frame(currency = name, term = names(cf), estimate = as.numeric(cf))
}))
q6_diagnostics <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  fit <- q6_final_fits[[name]]
  z <- as.numeric(residuals(fit, standardize = TRUE))
  arma_order <- parse_mean_model(q6_report_specs[q6_report_specs$currency == name, "mean_model"])
  data.frame(
    currency = name,
    lb_z_p = lb_p_value(z, lag = 10, fitdf = sum(arma_order)),
    lb_z2_p_course = lb_p_value(z^2, lag = 10, fitdf = 0),
    lb_z2_p_adjusted = lb_p_value(z^2, lag = 10, fitdf = 2)
  )
}))
q6_best_specs <- merge(q6_report_specs, q6_model_ic, by = "currency")
q6_best_specs <- merge(q6_best_specs, q6_diagnostics, by = "currency")
q6_best_specs$persistence <- sapply(q6_final_fits, function(fit) garch_unconditional_variance(fit)["persistence"])[q6_best_specs$currency]

q7_variances <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  uv <- garch_unconditional_variance(q6_final_fits[[name]])
  sample_var <- q5_sample_vars[[name]]
  data.frame(
    currency = name,
    persistence = uv["persistence"],
    model_variance = uv["model_variance"],
    sample_variance = sample_var,
    ratio = uv["model_variance"] / sample_var
  )
}))

q8_probabilities <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  fit <- q6_final_fits[[name]]
  fc <- ugarchforecast(fit, n.ahead = 2)
  mu <- as.numeric(fitted(fc))
  sigma <- as.numeric(sigma(fc))
  threshold <- 0.0001
  data.frame(
    currency = name,
    mu_t1 = mu[1], sigma_t1 = sigma[1], prob_t1 = pnorm(threshold, mean = mu[1], sd = sigma[1]),
    mu_t2 = mu[2], sigma_t2 = sigma[2], prob_t2 = pnorm(threshold, mean = mu[2], sd = sigma[2])
  )
}))

write.csv(head(q4_rr_adequate[, c("d", "p", "q", "aic", "bic", "lb_p")], 10),
          "_extras/q4_rr_adequate_top10.csv", row.names = FALSE)
write.csv(q4_rr_selected, "_extras/q4_rr_selected.csv", row.names = FALSE)
write.csv(q4_cy_selected, "_extras/q4_cy_selected.csv", row.names = FALSE)
write.csv(data.frame(term = names(coef(q4_rr_fit)), estimate = as.numeric(coef(q4_rr_fit))), "_extras/q4_rr_coefficients.csv", row.names = FALSE)
rr_order <- unname(as.integer(q4_rr_selected[1, c("p", "d", "q")]))
write.csv(data.frame(order_p = rr_order[1], order_d = rr_order[2], order_q = rr_order[3],
                     min_rr = min(macro$rr[-1], na.rm = TRUE),
                     mean_rr = mean(macro$rr[-1], na.rm = TRUE),
                     max_rr = max(macro$rr[-1], na.rm = TRUE)),
          "_extras/q4_rr_summary.csv", row.names = FALSE)
write.csv(data.frame(currency = names(q5_sample_vars), sample_variance = as.numeric(q5_sample_vars)),
          "_extras/q5_sample_variances.csv", row.names = FALSE)
write.csv(q6_arma_table, "q6_arma_table.csv", row.names = FALSE)
write.csv(q6_report_specs, "q6_final_specs.csv", row.names = FALSE)
write.csv(q6_diagnostics, "q6_final_diagnostics.csv", row.names = FALSE)
write.csv(q6_coefficients, "q6_final_coefficients_long.csv", row.names = FALSE)
write.csv(q7_variances, "q7_final_variances.csv", row.names = FALSE)
write.csv(q8_probabilities, "q8_final_probabilities.csv", row.names = FALSE)

results <- list(
  q1 = list(
    trend_table = data.frame(
      series = c("p_t", "y_t", "c_t"),
      intercept = sapply(q1_trends, function(x) coef(x)[1]),
      trend = sapply(q1_trends, function(x) coef(x)[2]),
      trend_se = sapply(q1_trends, function(x) summary(x)$coefficients[2, 2]),
      r_squared = sapply(q1_trends, function(x) summary(x)$r.squared)
    ),
    mean_table = data.frame(series = c("Delta p_t", "Delta y_t", "Delta c_t"), mean = unname(q1_means))
  ),
  q2 = list(
    dpt_search = q2_dpt_search$info,
    dpt_adequate = q2_dpt_adequate,
    dpt_top3 = q2_dpt_top3,
    dpt_model_names = q2_model_names,
    rt_search = q2_rt_search$info,
    rt_adequate = q2_rt_adequate,
    rt_fit = q2_rt_fit,
    forecast_table = data.frame(
      quarter = quarter_labels,
      model_1 = as.numeric(q2_dpt_forecasts[[1]]$mean),
      model_2 = as.numeric(q2_dpt_forecasts[[2]]$mean),
      model_3 = as.numeric(q2_dpt_forecasts[[3]]$mean),
      lo68 = as.numeric(q2_dpt_forecasts[[1]]$lower[, 1]),
      hi68 = as.numeric(q2_dpt_forecasts[[1]]$upper[, 1]),
      lo95 = as.numeric(q2_dpt_forecasts[[1]]$lower[, 2]),
      hi95 = as.numeric(q2_dpt_forecasts[[1]]$upper[, 2])
    )
  ),
  q3 = list(
    actual_table = data.frame(
      quarter = eval_quarters,
      actual = actual_dpt,
      model_1 = as.numeric(q2_dpt_forecasts[[1]]$mean[1:7]),
      model_2 = as.numeric(q2_dpt_forecasts[[2]]$mean[1:7]),
      model_3 = as.numeric(q2_dpt_forecasts[[3]]$mean[1:7])
    ),
    metrics = q3_eval
  ),
  q4 = list(
    rr_stats = c(min = min(macro$rr[-1], na.rm = TRUE), max = max(macro$rr[-1], na.rm = TRUE), mean = mean(macro$rr[-1], na.rm = TRUE)),
    cy_stats = c(min = min(macro$cy, na.rm = TRUE), max = max(macro$cy, na.rm = TRUE), mean = mean(macro$cy, na.rm = TRUE)),
    rr_model = q4_rr_fit,
    rr_search = q4_rr_search$info,
    rr_adequate = q4_rr_adequate,
    cy_model = q4_cy_fit,
    cy_search = q4_cy_search$info
  ),
  q5 = list(sample_variances = q5_sample_vars),
  q6 = list(arma_table = q6_arma_table, arch_tests = q6_arch_tests, best_specs = q6_best_specs, coefficients = q6_coefficients, diagnostics = q6_diagnostics),
  q7 = list(variance_table = q7_variances),
  q8 = list(probability_table = q8_probabilities)
)

saveRDS(results, "analysis_results.rds")
saveRDS(results, "_extras/analysis_results.rds")

png("fig1_log_levels.png", width = 1800, height = 600, res = fig_res)
par(mfrow = c(1, 3), mar = c(4.2, 4.2, 3, 1))
plot(macro$date, macro$pt, type = "l", col = "steelblue4", lwd = 2,
     xlab = "Date", ylab = "Log level", main = expression(p[t] == log(P[t])))
legend("topleft", legend = expression(p[t]), col = "steelblue4", lty = 1, lwd = 2, bty = "n")
plot(macro$date, macro$yt, type = "l", col = "firebrick4", lwd = 2,
     xlab = "Date", ylab = "Log level", main = expression(y[t] == log(Y[t])))
legend("topleft", legend = expression(y[t]), col = "firebrick4", lty = 1, lwd = 2, bty = "n")
plot(macro$date, macro$ct, type = "l", col = "darkgreen", lwd = 2,
     xlab = "Date", ylab = "Log level", main = expression(c[t] == log(C[t])))
legend("topleft", legend = expression(c[t]), col = "darkgreen", lty = 1, lwd = 2, bty = "n")
dev.off()

png("fig2_log_diffs.png", width = 1800, height = 900, res = fig_res)
par(mfrow = c(2, 2), mar = c(4.2, 4.2, 3, 1))
plot(macro$date[-1], macro$dpt[-1], type = "l", col = "steelblue4", lwd = 2,
     xlab = "Date", ylab = "Log difference", main = expression(Delta*p[t]))
legend("topleft", legend = expression(Delta*p[t]), col = "steelblue4", lty = 1, lwd = 2, bty = "n")
plot(macro$date[-1], macro$dyt[-1], type = "l", col = "firebrick4", lwd = 2,
     xlab = "Date", ylab = "Log difference", main = expression(Delta*y[t]))
legend("topleft", legend = expression(Delta*y[t]), col = "firebrick4", lty = 1, lwd = 2, bty = "n")
plot(macro$date[-1], macro$dct[-1], type = "l", col = "darkgreen", lwd = 2,
     xlab = "Date", ylab = "Log difference", main = expression(Delta*c[t]))
legend("topleft", legend = expression(Delta*c[t]), col = "darkgreen", lty = 1, lwd = 2, bty = "n")
plot(macro$date, macro$r, type = "l", col = "black", lwd = 2,
     xlab = "Date", ylab = "Percent", main = expression(r[t]))
legend("topleft", legend = expression(r[t]), col = "black", lty = 1, lwd = 2, bty = "n")
dev.off()

plot_forecast_bands <- function(fc, recent_ts, main_title, show_all_models = TRUE, actual_ts = NULL, model_index = NULL) {
  recent_x <- time(recent_ts)
  fc_x <- time(fc$mean)
  y_values <- c(as.numeric(recent_ts), as.numeric(fc$mean), as.numeric(fc$lower[, 2]), as.numeric(fc$upper[, 2]))
  if (!is.null(actual_ts)) y_values <- c(y_values, as.numeric(actual_ts))
  plot(c(recent_x, fc_x), c(as.numeric(recent_ts), as.numeric(fc$mean)), type = "n",
       xlab = "Date", ylab = expression(Delta*p[t]), main = main_title,
       ylim = range(y_values, na.rm = TRUE))
  polygon(c(fc_x, rev(fc_x)), c(as.numeric(fc$lower[, 2]), rev(as.numeric(fc$upper[, 2]))),
          col = "gray88", border = NA)
  polygon(c(fc_x, rev(fc_x)), c(as.numeric(fc$lower[, 1]), rev(as.numeric(fc$upper[, 1]))),
          col = "gray72", border = NA)
  lines(recent_ts, col = "black", lty = 1, lwd = 2)
  if (show_all_models) {
    line_types <- c(1, 2, 3)
    line_cols <- c("steelblue4", "firebrick4", "darkgreen")
    for (j in seq_along(q2_dpt_forecasts)) {
      lines(q2_dpt_forecasts[[j]]$mean, col = line_cols[j], lty = line_types[j], lwd = 2)
    }
    legend("topleft",
           legend = c("Recent actual", "95% interval", "68% interval", q2_model_names),
           col = c("black", "gray88", "gray72", line_cols),
           lty = c(1, NA, NA, line_types), lwd = c(2, NA, NA, rep(2, 3)),
           pch = c(NA, 15, 15, rep(NA, 3)), pt.cex = c(NA, 1.6, 1.6, rep(NA, 3)), bty = "n")
  } else {
    forecast_cols <- c("steelblue4", "firebrick4", "darkgreen")
    fc_col <- if (is.null(model_index)) "steelblue4" else forecast_cols[model_index]
    fc_label <- if (is.null(model_index)) "Forecast" else paste(q2_model_names[model_index], "forecast")
    lines(fc$mean, col = fc_col, lty = 2, lwd = 2)
    if (!is.null(actual_ts)) {
      lines(actual_ts, col = "black", lty = 1, lwd = 2)
      points(actual_ts, col = "black", pch = 16, cex = 0.7)
    }
    legend("topleft",
           legend = c("Recent actual", "Holdout actual", fc_label, "95% interval", "68% interval"),
           col = c("black", "black", fc_col, "gray88", "gray72"),
           lty = c(1, 1, 2, NA, NA), lwd = c(2, 2, 2, NA, NA),
           pch = c(NA, 16, NA, 15, 15), pt.cex = c(NA, 0.7, NA, 1.6, 1.6), bty = "n")
  }
}

recent_dpt_ts <- tail(dpt_ts, 20)
best_fc <- q2_dpt_forecasts[[1]]
png("fig2a_forecast.png", width = 1600, height = 650, res = fig_res)
plot_forecast_bands(best_fc, recent_dpt_ts,
                    main_title = expression("Recent inflation and 2024-2025 forecasts, " * Delta*p[t]),
                    show_all_models = TRUE)
dev.off()

actual_ts <- ts(actual_dpt, start = c(2024, 1), frequency = 4)
q3_files <- c(
  "fig3_actual_vs_arima_3_0_3.png",
  "fig3_actual_vs_arima_1_0_6.png",
  "fig3_actual_vs_arima_5_0_6.png"
)
for (i in seq_along(q2_dpt_forecasts)) {
  png(q3_files[i], width = 1600, height = 650, res = fig_res)
  plot_forecast_bands(q2_dpt_forecasts[[i]], recent_dpt_ts,
                      main_title = bquote("Forecast performance: " * .(q2_model_names[i]) * ", " * Delta*p[t]),
                      show_all_models = FALSE, actual_ts = actual_ts, model_index = i)
  dev.off()
}

png("fig4a_real_rate.png", width = fig_width, height = 850, res = fig_res)
par(mfrow = c(3, 1), mar = c(4.2, 4.6, 3, 1))
plot(macro$date[-1], macro$rr[-1], type = "l", col = "darkgreen", lty = 1, lwd = 2,
     xlab = "Date", ylab = expression(rr[t]),
     main = expression("Real interest-rate proxy: " * rr[t] == r[t] - 100 * Delta*p[t]))
legend("topleft", legend = expression(rr[t]), col = "darkgreen", lty = 1, lwd = 2, bty = "n")
matplot(macro$date[-1], cbind(macro$r[-1], macro$rr[-1], macro$inflation_pct[-1]),
        type = "l", lty = c(2, 1, 3), lwd = 2,
        col = c("firebrick4", "darkgreen", "steelblue4"), xlab = "Date", ylab = "Percentage points",
        main = expression("Nominal rate, real-rate proxy, and inflation"))
legend("topleft", legend = expression(r[t], rr[t], 100 * Delta*p[t]),
       col = c("firebrick4", "darkgreen", "steelblue4"), lty = c(2, 1, 3), lwd = 2, bty = "n")
matplot(macro$date[-1], scale(cbind(macro$r[-1], macro$rr[-1], macro$inflation_pct[-1])),
        type = "l", lty = c(2, 1, 3), lwd = 2,
        col = c("firebrick4", "darkgreen", "steelblue4"), xlab = "Date", ylab = "Standardised value",
        main = expression("Standardised comparison of stability"))
abline(h = 0, col = "gray70")
legend("topleft", legend = expression(r[t], rr[t], 100 * Delta*p[t]),
       col = c("firebrick4", "darkgreen", "steelblue4"), lty = c(2, 1, 3), lwd = 2, bty = "n")
dev.off()

png("fig4b_consumption_ratio.png", width = fig_width, height = 500, res = fig_res)
plot(macro$date, macro$cy, type = "l", col = "firebrick4", lwd = 2,
     xlab = "Date", ylab = expression(C[t] / Y[t]), main = expression("Consumption ratio: " * C[t] / Y[t]))
legend("topleft", legend = expression(C[t] / Y[t]), col = "firebrick4", lty = 1, lwd = 2, bty = "n")
dev.off()

png("fig5b_abs_returns.png", width = 1800, height = 900, res = fig_res)
par(mfrow = c(2, 2), mar = c(4.2, 4.2, 3, 1))
plot(fx$dates, abs(fx$returns$CNY), type = "l", col = "steelblue4", lwd = 1.5,
     xlab = "Date", ylab = expression(abs(e[t])), main = expression("CNY absolute returns: " * abs(e[t])))
legend("topleft", legend = "CNY", col = "steelblue4", lty = 1, lwd = 1.5, bty = "n")
plot(fx$dates, abs(fx$returns$USD), type = "l", col = "firebrick4", lwd = 1.5,
     xlab = "Date", ylab = expression(abs(e[t])), main = expression("USD absolute returns: " * abs(e[t])))
legend("topleft", legend = "USD", col = "firebrick4", lty = 1, lwd = 1.5, bty = "n")
plot(fx$dates, abs(fx$returns$TWI), type = "l", col = "darkgreen", lwd = 1.5,
     xlab = "Date", ylab = expression(abs(e[t])), main = expression("TWI absolute returns: " * abs(e[t])))
legend("topleft", legend = "TWI", col = "darkgreen", lty = 1, lwd = 1.5, bty = "n")
plot(fx$dates, abs(fx$returns$SDR), type = "l", col = "purple4", lwd = 1.5,
     xlab = "Date", ylab = expression(abs(e[t])), main = expression("SDR absolute returns: " * abs(e[t])))
legend("topleft", legend = "SDR", col = "purple4", lty = 1, lwd = 1.5, bty = "n")
dev.off()

for (name in names(q6_final_fits)) {
  png(sprintf("fig6_vol_%s.png", name), width = fig_width, height = 500, res = fig_res)
  plot(fx$dates, sigma(q6_final_fits[[name]]), type = "l", col = "steelblue4", lwd = 1.5,
       xlab = "Date", ylab = expression(sigma[t]), main = bquote("Conditional volatility: " * .(name) * ", " * sigma[t]))
  legend("topleft", legend = bquote(.(name) ~ sigma[t]), col = "steelblue4", lty = 1, lwd = 1.5, bty = "n")
  dev.off()
}

plot_corr_diagnostic <- function(x, type = c("acf", "pacf"), main, bar_col) {
  type <- match.arg(type)
  corr <- if (type == "acf") {
    out <- acf(x, lag.max = 30, plot = FALSE)
    data.frame(lag = as.numeric(out$lag)[-1], value = as.numeric(out$acf)[-1])
  } else {
    out <- pacf(x, lag.max = 30, plot = FALSE)
    data.frame(lag = as.numeric(out$lag), value = as.numeric(out$acf))
  }
  ci <- 1.96 / sqrt(length(x))
  y_lim <- range(c(corr$value, -ci, ci), na.rm = TRUE)
  plot(corr$lag, corr$value, type = "h", lwd = 2, col = bar_col,
       xlab = "Lag", ylab = toupper(type), main = main, ylim = y_lim)
  abline(h = 0, col = "gray40")
  abline(h = c(-ci, ci), col = "steelblue3", lty = 2)
}

png("fig6_sqstd_acf_pacf.png", width = 1800, height = 1400, res = fig_res)
par(mfrow = c(4, 2), mar = c(4.2, 4.2, 3, 1))
for (name in names(q6_final_fits)) {
  z2 <- as.numeric(residuals(q6_final_fits[[name]], standardize = TRUE))^2
  plot_corr_diagnostic(z2, "acf", bquote("ACF of squared standardised residuals: " * .(name)), "steelblue4")
  plot_corr_diagnostic(z2, "pacf", bquote("PACF of squared standardised residuals: " * .(name)), "firebrick4")
}
dev.off()

cat("Regenerated reported figures, CSV tables, and analysis_results.rds\n")
