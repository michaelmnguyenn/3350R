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

fig_width  <- 1500
fig_height <- 600
fig_res    <- 150

quarter_labels <- paste(rep(2024:2025, each = 4), paste0("Q", 1:4), sep = "")
eval_quarters  <- quarter_labels[1:7]

# Data

load_macro_data <- function() {
  df_full <- read_excel("MacroData (1).xlsx", sheet = "data")
  names(df_full)[1:5] <- c("date", "p", "r", "y", "c")
  df_full <- as.data.frame(df_full[, 1:5])
  df_full$date <- as.Date(df_full$date)
  df <- df_full[1:260, ]
  df$pt    <- log(df$p)
  df$yt    <- log(df$y)
  df$ct    <- log(df$c)
  df$dpt   <- c(NA_real_, diff(df$pt))
  df$dyt   <- c(NA_real_, diff(df$yt))
  df$dct   <- c(NA_real_, diff(df$ct))
  df$trend <- seq_len(nrow(df))
  df$rr    <- df$r - 100 * df$dpt
  df$cy    <- df$c / df$y
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
  idx  <- 0
  for (d in d_values) {
    for (p in 0:p_max) {
      for (q in 0:q_max) {
        fit <- tryCatch(
          Arima(series, order = c(p, d, q),
                include.mean  = (d == 0),
                include.drift = (d > 0),
                method = "ML"),
          error = function(e) NULL
        )
        if (!is.null(fit)) {
          idx <- idx + 1
          fits[[idx]] <- fit
          rows[[idx]] <- data.frame(
            d = d, p = p, q = q,
            aic  = AIC(fit),
            bic  = BIC(fit),
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
        include.mean  = (order_vec[2] == 0),
        include.drift = (order_vec[2] > 0),
        method = "ML")
}

engle_arch_lm <- function(x, lags = 10) {
  e2 <- x^2
  n  <- length(e2) - lags
  y  <- e2[(lags + 1):length(e2)]
  X  <- sapply(seq_len(lags), function(j) e2[(lags + 1 - j):(length(e2) - j)])
  fit <- lm(y ~ X)
  lm_stat <- n * summary(fit)$r.squared
  p_value  <- 1 - pchisq(lm_stat, df = lags)
  c(statistic = lm_stat, p_value = p_value)
}

fit_garch_candidate <- function(x, arma_order, variance_model, garch_order, distribution) {
  spec <- ugarchspec(
    variance.model     = list(model = variance_model, garchOrder = garch_order),
    mean.model         = list(armaOrder = arma_order, include.mean = TRUE),
    distribution.model = distribution
  )
  fit <- ugarchfit(spec, data = x, solver = "hybrid")
  z   <- as.numeric(residuals(fit, standardize = TRUE))
  ic  <- infocriteria(fit)
  data.frame(
    variance_model = variance_model,
    garch_p        = garch_order[1],
    garch_q        = garch_order[2],
    distribution   = distribution,
    aic     = ic[1],
    bic     = ic[2],
    lb_z_p  = lb_p_value(z,   lag = 10, fitdf = sum(arma_order)),
    lb_z2_p = lb_p_value(z^2, lag = 10, fitdf = 2)
  )
}

macro <- load_macro_data()
fx    <- load_fx_data()

dpt_ts <- ts(na.omit(macro$dpt), start = c(1959, 2), frequency = 4)
rt_ts  <- ts(macro$r,             start = c(1959, 1), frequency = 4)
rr_ts  <- ts(na.omit(macro$rr),  start = c(1959, 2), frequency = 4)
cy_ts  <- ts(macro$cy,            start = c(1959, 1), frequency = 4)

# Q1

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

# Q2

q2_dpt_search <- search_arima(dpt_ts, d_values = 0,        p_max = 10, q_max = 10, lb_lag = 12)
q2_dpt_models <- list(
  "ARIMA(2,0,10)" = fit_exact_arima(dpt_ts, c(2, 0, 10)),
  "ARIMA(4,0,9)"  = fit_exact_arima(dpt_ts, c(4, 0, 9)),
  "ARIMA(2,0,9)"  = fit_exact_arima(dpt_ts, c(2, 0, 9))
)
q2_dpt_forecasts <- lapply(q2_dpt_models, function(fit) {
  forecast::forecast(fit, h = 8, level = c(68, 95))
})

q2_rt_search   <- search_arima(rt_ts, d_values = c(0, 1), p_max = 10, q_max = 10, lb_lag = 12)
q2_rt_adequate <- q2_rt_search$info[q2_rt_search$info$lb_p > 0.05, ]
q2_rt_adequate <- q2_rt_adequate[order(q2_rt_adequate$aic), ]

# Q3

actual_p_future <- attr(macro, "p_future")
actual_dpt      <- diff(log(c(macro$p[260], actual_p_future)))
q3_eval <- do.call(rbind, lapply(names(q2_dpt_forecasts), function(nm) {
  pred <- as.numeric(q2_dpt_forecasts[[nm]]$mean[1:7])
  data.frame(
    model = nm,
    msfe  = mean((actual_dpt - pred)^2),
    rmsfe = sqrt(mean((actual_dpt - pred)^2)),
    mae   = mean(abs(actual_dpt - pred))
  )
}))

# Q4

q4_rr_search <- search_arima(rr_ts, d_values = c(0, 1), p_max = 10, q_max = 10, lb_lag = 20)
q4_rr_fit    <- fit_exact_arima(rr_ts, c(8, 0, 1))
q4_cy_search <- search_arima(cy_ts, d_values = c(0, 1), p_max = 4,  q_max = 4,  lb_lag = 20)
q4_cy_fit    <- fit_exact_arima(cy_ts, c(3, 1, 3))

# Q5

q5_sample_vars <- sapply(fx$returns, var)

# Q6

all_mean_orders <- do.call(c, lapply(0:3, function(p) lapply(0:3, function(q) c(p, q))))

q6_mean_screen <- do.call(rbind, lapply(names(fx$returns), function(name) {
  x <- fx$returns[[name]]
  do.call(rbind, lapply(all_mean_orders, function(ord) {
    fit <- tryCatch(
      Arima(x, order = c(ord[1], 0, ord[2]), include.mean = TRUE, method = "ML"),
      error = function(e) NULL
    )
    if (is.null(fit)) return(NULL)
    data.frame(
      currency = name,
      model    = sprintf("ARMA(%d,%d)", ord[1], ord[2]),
      aic      = AIC(fit),
      bic      = BIC(fit),
      lb_p     = lb_p_value(residuals(fit), lag = 10, fitdf = sum(ord))
    )
  }))
}))

q6_arch_tests <- do.call(rbind, lapply(names(fx$returns), function(name) {
  x    <- fx$returns[[name]]
  arch <- engle_arch_lm(x, lags = 10)
  data.frame(
    currency = name,
    arch_lm  = arch["statistic"],
    arch_p   = arch["p_value"],
    lb_sq_p  = lb_p_value(x^2, lag = 10, fitdf = 0)
  )
}))

q6_mean_orders  <- list(CNY = c(0, 0), USD = c(0, 0), TWI = c(1, 0), SDR = c(0, 1))
garch_orders    <- list(c(1, 1), c(1, 2))
variance_models <- c("sGARCH", "gjrGARCH")
distributions   <- c("norm", "std")

q6_garch_screen <- do.call(rbind, lapply(names(q6_mean_orders), function(name) {
  x   <- fx$returns[[name]]
  ord <- q6_mean_orders[[name]]
  out <- do.call(rbind, lapply(variance_models, function(vm) {
    do.call(rbind, lapply(garch_orders, function(go) {
      do.call(rbind, lapply(distributions, function(dist) {
        tryCatch(fit_garch_candidate(x, ord, vm, go, dist), error = function(e) NULL)
      }))
    }))
  }))
  out$currency   <- name
  out$mean_model <- sprintf("ARMA(%d,%d)", ord[1], ord[2])
  out
}))

select_best_garch <- function(screen, currency) {
  rows <- screen[screen$currency == currency, ]
  adq  <- rows[rows$lb_z_p > 0.05 & rows$lb_z2_p > 0.05, ]
  if (nrow(adq) == 0) adq <- rows[rows$lb_z_p > 0.05, ]
  if (nrow(adq) == 0) adq <- rows
  adq[which.min(adq$aic), ]
}

make_garch_fit_from_spec <- function(x, arma_order, variance_model, garch_order, distribution) {
  spec <- ugarchspec(
    variance.model     = list(model = variance_model, garchOrder = garch_order),
    mean.model         = list(armaOrder = arma_order, include.mean = TRUE),
    distribution.model = distribution
  )
  ugarchfit(spec, data = x, solver = "hybrid")
}

q6_final_fits <- lapply(names(q6_mean_orders), function(name) {
  best <- select_best_garch(q6_garch_screen, name)
  make_garch_fit_from_spec(
    fx$returns[[name]],
    arma_order     = q6_mean_orders[[name]],
    variance_model = as.character(best$variance_model),
    garch_order    = c(best$garch_p, best$garch_q),
    distribution   = as.character(best$distribution)
  )
})
names(q6_final_fits) <- names(q6_mean_orders)

q6_best_specs <- do.call(rbind, lapply(names(q6_mean_orders), function(name) {
  select_best_garch(q6_garch_screen, name)
}))

q6_coefficients <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  cf <- coef(q6_final_fits[[name]])
  data.frame(
    currency = name,
    mu     = unname(cf["mu"]),
    ar1    = if ("ar1"    %in% names(cf)) unname(cf["ar1"])    else NA_real_,
    ma1    = if ("ma1"    %in% names(cf)) unname(cf["ma1"])    else NA_real_,
    omega  = unname(cf["omega"]),
    alpha1 = unname(cf["alpha1"]),
    beta1  = unname(cf["beta1"]),
    gamma1 = if ("gamma1" %in% names(cf)) unname(cf["gamma1"]) else NA_real_,
    shape  = if ("shape"  %in% names(cf)) unname(cf["shape"])  else NA_real_
  )
}))

q6_diagnostics <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  fit <- q6_final_fits[[name]]
  z   <- as.numeric(residuals(fit, standardize = TRUE))
  data.frame(
    currency = name,
    lb_z_p   = lb_p_value(z,   lag = 10, fitdf = sum(q6_mean_orders[[name]])),
    lb_z2_p  = lb_p_value(z^2, lag = 10, fitdf = 2)
  )
}))

garch_unconditional_variance <- function(fit) {
  cf        <- coef(fit)
  has_gamma <- "gamma1" %in% names(cf)
  persistence <- if (has_gamma) {
    unname(cf["alpha1"] + cf["beta1"] + 0.5 * cf["gamma1"])
  } else {
    unname(cf["alpha1"] + cf["beta1"])
  }
  list(
    persistence    = persistence,
    model_variance = unname(cf["omega"] / (1 - persistence))
  )
}

q7_variances <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  uv         <- garch_unconditional_variance(q6_final_fits[[name]])
  sample_var <- q5_sample_vars[[name]]
  data.frame(
    currency        = name,
    persistence     = uv$persistence,
    model_variance  = uv$model_variance,
    sample_variance = sample_var,
    ratio           = uv$model_variance / sample_var
  )
}))

q8_probabilities <- do.call(rbind, lapply(names(q6_final_fits), function(name) {
  fit   <- q6_final_fits[[name]]
  fc    <- ugarchforecast(fit, n.ahead = 2)
  mu    <- as.numeric(fitted(fc))
  sigma <- as.numeric(sigma(fc))
  cf    <- coef(fit)
  dist  <- fit@model$modeldesc$distribution
  shape <- if ("shape" %in% names(cf)) unname(cf["shape"]) else NA_real_
  skew  <- if ("skew"  %in% names(cf)) unname(cf["skew"])  else NA_real_
  prob_fn <- function(m, s) {
    if (dist == "std" && !is.na(shape)) {
      pdist("std", q = 0.01, mu = m, sigma = s, shape = shape)
    } else if (dist == "norm") {
      pnorm(0.01, mean = m, sd = s)
    } else {
      pdist(dist, q = 0.01, mu = m, sigma = s,
            shape = if (!is.na(shape)) shape else 5,
            skew  = if (!is.na(skew))  skew  else 1)
    }
  }
  data.frame(
    currency = name,
    mu_t1    = mu[1],  sigma_t1 = sigma[1],  prob_t1 = prob_fn(mu[1], sigma[1]),
    mu_t2    = mu[2],  sigma_t2 = sigma[2],  prob_t2 = prob_fn(mu[2], sigma[2])
  )
}))

save_figures <- function() {
  png("fig1_log_levels.png", width = 1800, height = 600, res = fig_res)
  par(mfrow = c(1, 3), mar = c(3.5, 4, 3, 1))
  plot(macro$date, macro$pt, type = "l", col = "steelblue4", lwd = 2, xlab = "", ylab = "log level", main = "log(P_t)")
  plot(macro$date, macro$yt, type = "l", col = "firebrick4", lwd = 2, xlab = "", ylab = "log level", main = "log(Y_t)")
  plot(macro$date, macro$ct, type = "l", col = "darkgreen",  lwd = 2, xlab = "", ylab = "log level", main = "log(C_t)")
  dev.off()

  png("fig2_log_diffs.png", width = 1800, height = 900, res = fig_res)
  par(mfrow = c(2, 2), mar = c(3.5, 4, 3, 1))
  plot(macro$date[-1], macro$dpt[-1], type = "l", col = "steelblue4", lwd = 2, xlab = "", ylab = "diff log", main = "Delta p_t")
  plot(macro$date[-1], macro$dyt[-1], type = "l", col = "firebrick4", lwd = 2, xlab = "", ylab = "diff log", main = "Delta y_t")
  plot(macro$date[-1], macro$dct[-1], type = "l", col = "darkgreen",  lwd = 2, xlab = "", ylab = "diff log", main = "Delta c_t")
  plot(macro$date,     macro$r,       type = "l", col = "black",      lwd = 2, xlab = "", ylab = "percent",  main = "r_t")
  dev.off()

  best_fc <- q2_dpt_forecasts[["ARIMA(2,0,10)"]]
  png("fig2a_forecast.png", width = 1600, height = 650, res = fig_res)
  plot(best_fc, include = 20, main = "Inflation forecasts 2024-2025", xlab = "", ylab = "Delta p_t", col = "steelblue4")
  lines(q2_dpt_forecasts[["ARIMA(4,0,9)"]]$mean, col = "firebrick4", lty = 2, lwd = 2)
  lines(q2_dpt_forecasts[["ARIMA(2,0,9)"]]$mean, col = "darkgreen",  lty = 3, lwd = 2)
  legend("topleft", legend = c("ARIMA(2,0,10)", "ARIMA(4,0,9)", "ARIMA(2,0,9)"),
         col = c("steelblue4", "firebrick4", "darkgreen"), lty = 1:3, lwd = 2, bty = "n")
  dev.off()

  actual_ts <- ts(actual_dpt, start = c(2024, 1), frequency = 4)
  png("fig3_actual_vs_forecast.png", width = 1600, height = 650, res = fig_res)
  plot(best_fc, include = 20, main = "Inflation: forecasts vs actual 2024-2025Q3", xlab = "", ylab = "Delta p_t", col = "steelblue4")
  lines(q2_dpt_forecasts[["ARIMA(4,0,9)"]]$mean, col = "firebrick4", lty = 2, lwd = 2)
  lines(q2_dpt_forecasts[["ARIMA(2,0,9)"]]$mean, col = "darkgreen",  lty = 3, lwd = 2)
  lines(actual_ts, col = "black", lwd = 2)
  legend("topright", legend = c("ARIMA(2,0,10)", "ARIMA(4,0,9)", "ARIMA(2,0,9)", "Actual"),
         col = c("steelblue4", "firebrick4", "darkgreen", "black"),
         lty = c(1, 2, 3, 1), lwd = 2, bty = "n")
  dev.off()

  png("fig4a_real_rate.png", width = fig_width, height = 500, res = fig_res)
  matplot(macro$date[-1], cbind(macro$dpt[-1] * 100, macro$rr[-1], macro$r[-1]),
          type = "l", lty = 1, lwd = 2,
          col  = c("steelblue4", "black", "firebrick4"),
          xlab = "", ylab = "Percent",
          main = "Inflation, real interest rate and nominal interest rate")
  legend("topleft",
         legend = c("Inflation (100*Delta p_t)", "Real rate (rr_t)", "Nominal rate (r_t)"),
         col = c("steelblue4", "black", "firebrick4"), lty = 1, lwd = 2, bty = "n")
  dev.off()

  png("fig4b_consumption_ratio.png", width = fig_width, height = 500, res = fig_res)
  plot(macro$date, macro$cy, type = "l", col = "firebrick4", lwd = 2,
       xlab = "", ylab = "C_t / Y_t", main = "Consumption ratio")
  dev.off()

  png("fig5b_abs_returns.png", width = 1800, height = 900, res = fig_res)
  par(mfrow = c(2, 2), mar = c(3.5, 4, 3, 1))
  plot(fx$dates, abs(fx$returns$CNY), type = "l", col = "steelblue4", lwd = 1.5, xlab = "", ylab = "|e_t|", main = "CNY")
  plot(fx$dates, abs(fx$returns$USD), type = "l", col = "firebrick4", lwd = 1.5, xlab = "", ylab = "|e_t|", main = "USD")
  plot(fx$dates, abs(fx$returns$TWI), type = "l", col = "darkgreen",  lwd = 1.5, xlab = "", ylab = "|e_t|", main = "TWI")
  plot(fx$dates, abs(fx$returns$SDR), type = "l", col = "purple4",    lwd = 1.5, xlab = "", ylab = "|e_t|", main = "SDR")
  dev.off()

  for (name in names(q6_final_fits)) {
    png(sprintf("fig6_vol_%s.png", name), width = fig_width, height = 500, res = fig_res)
    plot(fx$dates, sigma(q6_final_fits[[name]]), type = "l", col = "steelblue4", lwd = 1.5,
         xlab = "", ylab = "sigma_t", main = sprintf("Conditional volatility: %s", name))
    dev.off()
  }
}

build_results <- function() {
  list(
    q1 = list(
      trend_table = data.frame(
        series    = c("p_t", "y_t", "c_t"),
        intercept = sapply(q1_trends, function(x) coef(x)[1]),
        trend     = sapply(q1_trends, function(x) coef(x)[2]),
        trend_se  = sapply(q1_trends, function(x) summary(x)$coefficients[2, 2]),
        r_squared = sapply(q1_trends, function(x) summary(x)$r.squared)
      ),
      mean_table = data.frame(
        series = c("Delta p_t", "Delta y_t", "Delta c_t"),
        mean   = unname(q1_means)
      )
    ),
    q2 = list(
      dpt_search     = q2_dpt_search$info,
      rt_search      = q2_rt_search$info,
      rt_adequate    = q2_rt_adequate,
      forecast_table = data.frame(
        quarter    = quarter_labels,
        arima_2_10 = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,10)"]]$mean),
        arima_4_9  = as.numeric(q2_dpt_forecasts[["ARIMA(4,0,9)"]]$mean),
        arima_2_9  = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,9)"]]$mean),
        lo68 = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,10)"]]$lower[, 1]),
        hi68 = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,10)"]]$upper[, 1]),
        lo95 = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,10)"]]$lower[, 2]),
        hi95 = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,10)"]]$upper[, 2])
      )
    ),
    q3 = list(
      actual_table = data.frame(
        quarter    = eval_quarters,
        actual     = actual_dpt,
        arima_2_10 = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,10)"]]$mean[1:7]),
        arima_4_9  = as.numeric(q2_dpt_forecasts[["ARIMA(4,0,9)"]]$mean[1:7]),
        arima_2_9  = as.numeric(q2_dpt_forecasts[["ARIMA(2,0,9)"]]$mean[1:7])
      ),
      metrics = q3_eval
    ),
    q4 = list(
      rr_stats  = c(min  = min(macro$rr[-1], na.rm = TRUE),
                    max  = max(macro$rr[-1], na.rm = TRUE),
                    mean = mean(macro$rr[-1], na.rm = TRUE)),
      cy_stats  = c(min  = min(macro$cy, na.rm = TRUE),
                    max  = max(macro$cy, na.rm = TRUE),
                    mean = mean(macro$cy, na.rm = TRUE)),
      rr_model  = q4_rr_fit,
      rr_search = q4_rr_search$info,
      cy_model  = q4_cy_fit,
      cy_search = q4_cy_search$info
    ),
    q5 = list(sample_variances = q5_sample_vars),
    q6 = list(
      mean_screen  = q6_mean_screen,
      arch_tests   = q6_arch_tests,
      garch_screen = q6_garch_screen,
      best_specs   = q6_best_specs,
      coefficients = q6_coefficients,
      diagnostics  = q6_diagnostics
    ),
    q7 = list(variance_table = q7_variances),
    q8 = list(probability_table = q8_probabilities)
  )
}

results <- build_results()
saveRDS(results, "analysis_results.rds")
save_figures()

if (sys.nframe() == 0) {
  cat("\n=== Q6 best specs ===\n");    print(q6_best_specs)
  cat("\n=== Q6 diagnostics ===\n");   print(q6_diagnostics)
  cat("\n=== Q7 variances ===\n");     print(q7_variances)
  cat("\n=== Q8 probabilities ===\n"); print(q8_probabilities)
}
