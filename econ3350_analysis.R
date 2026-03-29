rm(list = ls())

suppressPackageStartupMessages({
  library(readxl)
  library(forecast)
  library(rugarch)
})

setwd(tryCatch(
  dirname(rstudioapi::getActiveDocumentContext()$path),
  error = function(e) getwd()
))

fig_width <- 1500
fig_height <- 600
fig_res <- 150

quarter_labels <- paste(rep(2024:2025, each = 4), paste0("Q", 1:4), sep = "")
eval_quarters <- quarter_labels[1:7]
actual_p_2024_2025 <- c(14.663, 14.785, 14.898, 14.993, 15.100, 15.196, 15.294)

load_macro_data <- function() {
  df <- read_excel("MacroData (1).xlsx", sheet = "data")
  names(df)[1:5] <- c("date", "p", "r", "y", "c")
  df <- as.data.frame(df[1:260, ])
  df$date <- as.Date(df$date)
  df$pt <- log(df$p)
  df$yt <- log(df$y)
  df$ct <- log(df$c)
  df$dpt <- c(NA_real_, diff(df$pt))
  df$dyt <- c(NA_real_, diff(df$yt))
  df$dct <- c(NA_real_, diff(df$ct))
  df$trend <- seq_len(nrow(df))
  df$rr <- df$r - df$dpt
  df$cy <- df$c / df$y
  df
}

load_fx_data <- function() {
  ex <- read_excel("EXRATE (1).xlsx", sheet = "All")
  names(ex)[1:5] <- c("date", "CNY", "USD", "TWI", "SDR")
  ex <- as.data.frame(ex[, 1:5])
  ex$date <- as.Date(ex$date)
  returns <- lapply(ex[, c("CNY", "USD", "TWI", "SDR")], function(x) {
    100 * diff(log(x))
  })
  list(
    data = ex,
    dates = ex$date[-1],
    returns = returns
  )
}

adf_pick <- function(x) {
  out <- suppressWarnings(capture.output(obj <- aTSA::adf.test(x)))
  obj$type2[which.min(obj$type2[, "p.value"]), ]
}

kpss_pick <- function(x) {
  out <- suppressWarnings(capture.output(obj <- aTSA::kpss.test(x)))
  obj["type 2", ]
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
          Arima(
            series,
            order = c(p, d, q),
            include.mean = (d == 0),
            include.drift = (d > 0),
            method = "ML"
          ),
          error = function(e) NULL
        )
        if (!is.null(fit)) {
          idx <- idx + 1
          fits[[idx]] <- fit
          rows[[idx]] <- data.frame(
            d = d,
            p = p,
            q = q,
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
  Arima(
    series,
    order = order_vec,
    include.mean = (order_vec[2] == 0),
    include.drift = (order_vec[2] > 0),
    method = "ML"
  )
}

engle_arch_lm <- function(x, lags = 10) {
  e2 <- x^2
  n <- length(e2) - lags
  y <- e2[(lags + 1):length(e2)]
  X <- sapply(seq_len(lags), function(j) e2[(lags + 1 - j):(length(e2) - j)])
  fit <- lm(y ~ X)
  lm_stat <- n * summary(fit)$r.squared
  p_value <- 1 - pchisq(lm_stat, df = lags)
  c(statistic = lm_stat, p_value = p_value)
}

fit_garch_candidate <- function(x, arma_order, variance_model, distribution) {
  spec <- ugarchspec(
    variance.model = list(model = variance_model, garchOrder = c(1, 1)),
    mean.model = list(armaOrder = arma_order, include.mean = TRUE),
    distribution.model = distribution
  )
  fit <- ugarchfit(spec, data = x, solver = "hybrid")
  z <- as.numeric(residuals(fit, standardize = TRUE))
  ic <- infocriteria(fit)
  data.frame(
    variance_model = variance_model,
    distribution = distribution,
    aic = ic[1],
    bic = ic[2],
    lb_z_p = lb_p_value(z, lag = 10, fitdf = sum(arma_order)),
    lb_z2_p = lb_p_value(z^2, lag = 10, fitdf = 2)
  )
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

q2_dpt_search <- search_arima(dpt_ts, d_values = 0, p_max = 4, q_max = 4, lb_lag = 12)
q2_dpt_models <- list(
  "ARMA(3,3)" = fit_exact_arima(dpt_ts, c(3, 0, 3)),
  "ARMA(3,4)" = fit_exact_arima(dpt_ts, c(3, 0, 4)),
  "ARMA(4,3)" = fit_exact_arima(dpt_ts, c(4, 0, 3))
)
q2_dpt_forecasts <- lapply(q2_dpt_models, function(fit) {
  forecast::forecast(fit, h = 8, level = c(80, 95))
})

q2_rt_search <- search_arima(rt_ts, d_values = 1, p_max = 4, q_max = 4, lb_lag = 12)

actual_dpt <- diff(log(c(macro$p[260], actual_p_2024_2025)))
q3_eval <- do.call(
  rbind,
  lapply(names(q2_dpt_forecasts), function(model_name) {
    pred <- as.numeric(q2_dpt_forecasts[[model_name]]$mean[1:7])
    data.frame(
      model = model_name,
      msfe = mean((actual_dpt - pred)^2),
      rmsfe = sqrt(mean((actual_dpt - pred)^2)),
      mae = mean(abs(actual_dpt - pred))
    )
  })
)

q4_rr_search <- search_arima(rr_ts, d_values = 1, p_max = 6, q_max = 6, lb_lag = 20)
q4_rr_fit <- fit_exact_arima(rr_ts, c(3, 1, 6))
q4_cy_search <- search_arima(cy_ts, d_values = c(0, 1), p_max = 4, q_max = 4, lb_lag = 20)
q4_cy_fit <- fit_exact_arima(cy_ts, c(3, 1, 3))

q5_sample_vars <- sapply(fx$returns, var)

q6_mean_screen <- do.call(
  rbind,
  lapply(names(fx$returns), function(name) {
    x <- fx$returns[[name]]
    orders <- list(c(0, 0), c(1, 0), c(0, 1), c(1, 1))
    do.call(
      rbind,
      lapply(orders, function(ord) {
        fit <- Arima(x, order = c(ord[1], 0, ord[2]), include.mean = TRUE, method = "ML")
        data.frame(
          currency = name,
          model = sprintf("ARMA(%d,%d)", ord[1], ord[2]),
          aic = AIC(fit),
          bic = BIC(fit),
          lb_p = lb_p_value(residuals(fit), lag = 10, fitdf = sum(ord))
        )
      })
    )
  })
)

q6_arch_tests <- do.call(
  rbind,
  lapply(names(fx$returns), function(name) {
    x <- fx$returns[[name]]
    arch <- engle_arch_lm(x, lags = 10)
    data.frame(
      currency = name,
      arch_lm = arch["statistic"],
      arch_p = arch["p_value"],
      lb_sq_p = lb_p_value(x^2, lag = 10, fitdf = 0)
    )
  })
)

q6_mean_orders <- list(CNY = c(0, 0), USD = c(0, 0), TWI = c(1, 0), SDR = c(0, 1))

q6_garch_screen <- do.call(
  rbind,
  lapply(names(q6_mean_orders), function(name) {
    x <- fx$returns[[name]]
    ord <- q6_mean_orders[[name]]
    out <- do.call(
      rbind,
      lapply(c("sGARCH", "gjrGARCH"), function(vm) {
        do.call(
          rbind,
          lapply(c("norm", "std"), function(dist) {
            fit_garch_candidate(x, ord, vm, dist)
          })
        )
      })
    )
    out$currency <- name
    out$mean_model <- sprintf("ARMA(%d,%d)", ord[1], ord[2])
    out
  })
)

make_final_garch_fit <- function(x, arma_order) {
  spec <- ugarchspec(
    variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
    mean.model = list(armaOrder = arma_order, include.mean = TRUE),
    distribution.model = "std"
  )
  ugarchfit(spec, data = x, solver = "hybrid")
}

q6_final_fits <- list(
  CNY = make_final_garch_fit(fx$returns$CNY, c(0, 0)),
  USD = make_final_garch_fit(fx$returns$USD, c(0, 0)),
  TWI = make_final_garch_fit(fx$returns$TWI, c(1, 0)),
  SDR = make_final_garch_fit(fx$returns$SDR, c(0, 1))
)

q6_coefficients <- do.call(
  rbind,
  lapply(names(q6_final_fits), function(name) {
    cf <- coef(q6_final_fits[[name]])
    data.frame(
      currency = name,
      mu = unname(cf["mu"]),
      ar1 = if ("ar1" %in% names(cf)) unname(cf["ar1"]) else NA_real_,
      ma1 = if ("ma1" %in% names(cf)) unname(cf["ma1"]) else NA_real_,
      omega = unname(cf["omega"]),
      alpha1 = unname(cf["alpha1"]),
      beta1 = unname(cf["beta1"]),
      gamma1 = unname(cf["gamma1"]),
      shape = unname(cf["shape"])
    )
  })
)

q6_diagnostics <- do.call(
  rbind,
  lapply(names(q6_final_fits), function(name) {
    fit <- q6_final_fits[[name]]
    z <- as.numeric(residuals(fit, standardize = TRUE))
    data.frame(
      currency = name,
      lb_z_p = lb_p_value(z, lag = 10, fitdf = sum(q6_mean_orders[[name]])),
      lb_z2_p = lb_p_value(z^2, lag = 10, fitdf = 2)
    )
  })
)

gjr_unconditional_variance <- function(fit) {
  cf <- coef(fit)
  persistence <- unname(cf["alpha1"] + cf["beta1"] + 0.5 * cf["gamma1"])
  variance <- unname(cf["omega"] / (1 - persistence))
  c(persistence = persistence, model_variance = variance)
}

q7_variances <- do.call(
  rbind,
  lapply(names(q6_final_fits), function(name) {
    uv <- gjr_unconditional_variance(q6_final_fits[[name]])
    sample_var <- q5_sample_vars[[name]]
    data.frame(
      currency = name,
      persistence = unname(uv["persistence"]),
      model_variance = unname(uv["model_variance"]),
      sample_variance = sample_var,
      ratio = unname(uv["model_variance"]) / sample_var
    )
  })
)

q8_probabilities <- do.call(
  rbind,
  lapply(names(q6_final_fits), function(name) {
    fit <- q6_final_fits[[name]]
    fc <- ugarchforecast(fit, n.ahead = 2)
    mu <- as.numeric(fitted(fc))
    sigma <- as.numeric(sigma(fc))
    shape <- unname(coef(fit)["shape"])
    data.frame(
      currency = name,
      mu_t1 = mu[1],
      sigma_t1 = sigma[1],
      prob_t1 = pdist("std", q = 0.01, mu = mu[1], sigma = sigma[1], shape = shape),
      mu_t2 = mu[2],
      sigma_t2 = sigma[2],
      prob_t2 = pdist("std", q = 0.01, mu = mu[2], sigma = sigma[2], shape = shape)
    )
  })
)

save_figures <- function() {
  png("fig1_log_levels.png", width = 1800, height = 600, res = fig_res)
  par(mfrow = c(1, 3), mar = c(3.5, 4, 3, 1))
  plot(macro$date, macro$pt, type = "l", col = "steelblue4", lwd = 2, xlab = "", ylab = "log level", main = "log(P_t)")
  plot(macro$date, macro$yt, type = "l", col = "firebrick4", lwd = 2, xlab = "", ylab = "log level", main = "log(Y_t)")
  plot(macro$date, macro$ct, type = "l", col = "darkgreen", lwd = 2, xlab = "", ylab = "log level", main = "log(C_t)")
  dev.off()

  png("fig2_log_diffs.png", width = 1800, height = 900, res = fig_res)
  par(mfrow = c(2, 2), mar = c(3.5, 4, 3, 1))
  plot(macro$date[-1], macro$dpt[-1], type = "l", col = "steelblue4", lwd = 2, xlab = "", ylab = "diff log", main = "Delta p_t")
  plot(macro$date[-1], macro$dyt[-1], type = "l", col = "firebrick4", lwd = 2, xlab = "", ylab = "diff log", main = "Delta y_t")
  plot(macro$date[-1], macro$dct[-1], type = "l", col = "darkgreen", lwd = 2, xlab = "", ylab = "diff log", main = "Delta c_t")
  plot(macro$date, macro$r, type = "l", col = "black", lwd = 2, xlab = "", ylab = "percent", main = "r_t")
  dev.off()

  best_fc <- q2_dpt_forecasts[["ARMA(3,3)"]]
  png("fig2a_forecast.png", width = 1600, height = 650, res = fig_res)
  plot(best_fc, include = 20, main = "Inflation forecasts for 2024-2025", xlab = "", ylab = "Delta p_t", col = "steelblue4")
  lines(q2_dpt_forecasts[["ARMA(3,4)"]]$mean, col = "firebrick4", lty = 2, lwd = 2)
  lines(q2_dpt_forecasts[["ARMA(4,3)"]]$mean, col = "darkgreen", lty = 3, lwd = 2)
  legend("topleft", legend = c("ARMA(3,3)", "ARMA(3,4)", "ARMA(4,3)"), col = c("steelblue4", "firebrick4", "darkgreen"), lty = 1:3, lwd = 2, bty = "n")
  dev.off()

  png("fig4a_real_rate.png", width = fig_width, height = 500, res = fig_res)
  plot(macro$date[-1], macro$rr[-1], type = "l", col = "steelblue4", lwd = 2, xlab = "", ylab = "percent", main = "Real interest rate proxy")
  abline(h = mean(macro$rr[-1], na.rm = TRUE), lty = 2, col = "grey40")
  dev.off()

  png("fig4b_consumption_ratio.png", width = fig_width, height = 500, res = fig_res)
  plot(macro$date, macro$cy, type = "l", col = "firebrick4", lwd = 2, xlab = "", ylab = "C_t / Y_t", main = "Consumption ratio")
  dev.off()

  png("fig5b_abs_returns.png", width = 1800, height = 900, res = fig_res)
  par(mfrow = c(2, 2), mar = c(3.5, 4, 3, 1))
  plot(fx$dates, abs(fx$returns$CNY), type = "l", col = "steelblue4", lwd = 1.5, xlab = "", ylab = "|e_t|", main = "CNY")
  plot(fx$dates, abs(fx$returns$USD), type = "l", col = "firebrick4", lwd = 1.5, xlab = "", ylab = "|e_t|", main = "USD")
  plot(fx$dates, abs(fx$returns$TWI), type = "l", col = "darkgreen", lwd = 1.5, xlab = "", ylab = "|e_t|", main = "TWI")
  plot(fx$dates, abs(fx$returns$SDR), type = "l", col = "purple4", lwd = 1.5, xlab = "", ylab = "|e_t|", main = "SDR")
  dev.off()

  for (name in names(q6_final_fits)) {
    png(sprintf("fig6_vol_%s.png", name), width = fig_width, height = 500, res = fig_res)
    plot(fx$dates, sigma(q6_final_fits[[name]]), type = "l", col = "steelblue4", lwd = 1.5, xlab = "", ylab = "sigma_t", main = sprintf("Conditional volatility: %s", name))
    dev.off()
  }
}

build_results <- function() {
  list(
    q1 = list(
      trend_table = data.frame(
        series = c("p_t", "y_t", "c_t"),
        intercept = sapply(q1_trends, function(x) coef(x)[1]),
        trend = sapply(q1_trends, function(x) coef(x)[2]),
        trend_se = sapply(q1_trends, function(x) summary(x)$coefficients[2, 2]),
        r_squared = sapply(q1_trends, function(x) summary(x)$r.squared)
      ),
      mean_table = data.frame(
        series = c("Delta p_t", "Delta y_t", "Delta c_t"),
        mean = unname(q1_means)
      )
    ),
    q2 = list(
      adf_dpt = adf_pick(dpt_ts),
      kpss_dpt = kpss_pick(dpt_ts),
      adf_rt = adf_pick(rt_ts),
      kpss_rt = kpss_pick(rt_ts),
      dpt_search = q2_dpt_search$info,
      rt_search = q2_rt_search$info,
      forecast_table = data.frame(
        quarter = quarter_labels,
        arma_33 = as.numeric(q2_dpt_forecasts[["ARMA(3,3)"]]$mean),
        arma_34 = as.numeric(q2_dpt_forecasts[["ARMA(3,4)"]]$mean),
        arma_43 = as.numeric(q2_dpt_forecasts[["ARMA(4,3)"]]$mean),
        lo95 = as.numeric(q2_dpt_forecasts[["ARMA(3,3)"]]$lower[, 2]),
        hi95 = as.numeric(q2_dpt_forecasts[["ARMA(3,3)"]]$upper[, 2])
      )
    ),
    q3 = list(
      actual_table = data.frame(
        quarter = eval_quarters,
        actual = actual_dpt,
        arma_33 = as.numeric(q2_dpt_forecasts[["ARMA(3,3)"]]$mean[1:7]),
        arma_34 = as.numeric(q2_dpt_forecasts[["ARMA(3,4)"]]$mean[1:7]),
        arma_43 = as.numeric(q2_dpt_forecasts[["ARMA(4,3)"]]$mean[1:7])
      ),
      metrics = q3_eval
    ),
    q4 = list(
      rr_stats = c(min = min(macro$rr[-1], na.rm = TRUE), max = max(macro$rr[-1], na.rm = TRUE), mean = mean(macro$rr[-1], na.rm = TRUE)),
      cy_stats = c(min = min(macro$cy, na.rm = TRUE), max = max(macro$cy, na.rm = TRUE), mean = mean(macro$cy, na.rm = TRUE)),
      rr_model = q4_rr_fit,
      rr_search = q4_rr_search$info,
      cy_model = q4_cy_fit,
      cy_search = q4_cy_search$info
    ),
    q5 = list(sample_variances = q5_sample_vars),
    q6 = list(
      mean_screen = q6_mean_screen,
      arch_tests = q6_arch_tests,
      garch_screen = q6_garch_screen,
      coefficients = q6_coefficients,
      diagnostics = q6_diagnostics
    ),
    q7 = list(variance_table = q7_variances),
    q8 = list(probability_table = q8_probabilities)
  )
}

results <- build_results()
saveRDS(results, "analysis_results.rds")
save_figures()

if (sys.nframe() == 0) {
  print(results$q2$forecast_table)
  print(results$q3$metrics)
  print(results$q7$variance_table)
  print(results$q8$probability_table)
}
