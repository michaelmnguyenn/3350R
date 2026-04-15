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
  df$inflation_pct <- 100 * df$dpt
  df$rr    <- df$r - df$inflation_pct
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
  # Test lags 1-10 with drift (type 2); pick the lag chosen by AIC via ur.df
  t <- urca::ur.df(x, type = "drift", lags = 10, selectlags = "AIC")
  stat <- as.numeric(t@teststat[1, "tau2"])
  cv5  <- as.numeric(t@cval["tau2", "5pct"])
  list(stat = stat, cv5pct = cv5, reject = stat < cv5, lags = t@lags)
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
  cf  <- coef(fit)
  persistence <- sum(cf[grep("alpha|beta", names(cf))], na.rm = TRUE) +
    if ("gamma1" %in% names(cf)) 0.5 * unname(cf["gamma1"]) else 0
  data.frame(
    variance_model = variance_model,
    garch_p        = garch_order[1],
    garch_q        = garch_order[2],
    distribution   = distribution,
    aic     = ic[1],
    bic     = ic[2],
    lb_z_p  = lb_p_value(z,   lag = 10, fitdf = sum(arma_order)),
    lb_z2_p_course   = lb_p_value(z^2, lag = 10, fitdf = 0),
    lb_z2_p_adjusted = lb_p_value(z^2, lag = 10, fitdf = 2),
    persistence = persistence
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

q2_dpt_search   <- search_arima(dpt_ts, d_values = 0, p_max = 10, q_max = 10, lb_lag = 8)
q2_dpt_orders <- list(c(2, 0, 10), c(4, 0, 9), c(2, 0, 9))
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
    lb_p = lb_p_value(residuals(fit), lag = 8, fitdf = ord[1] + ord[3])
  )
}))
q2_dpt_adequate <- q2_dpt_top3
q2_dpt_models <- setNames(
  q2_dpt_models,
  names(q2_dpt_models)
)
q2_dpt_forecasts <- lapply(q2_dpt_models, function(fit) {
  forecast::forecast(fit, h = 8, level = c(68, 95))
})

q2_rt_search   <- search_arima(rt_ts, d_values = c(0, 1), p_max = 10, q_max = 10, lb_lag = 8)
q2_rt_orders <- list(c(8, 0, 5), c(8, 0, 6), c(8, 0, 2))
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
    lb_p = lb_p_value(residuals(fit), lag = 8, fitdf = ord[1] + ord[3])
  )
}))
q2_rt_fit <- q2_rt_models[[1]]

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

q4_rr_search   <- search_arima(rr_ts, d_values = c(0, 1), p_max = 10, q_max = 10, lb_lag = 8)
q4_rr_adequate <- q4_rr_search$info[q4_rr_search$info$lb_p > 0.05, ]
q4_rr_adequate <- q4_rr_adequate[order(q4_rr_adequate$aic, q4_rr_adequate$bic), ]
q4_rr_fit      <- Arima(rr_ts, order = c(7, 1, 1), include.mean = FALSE, include.drift = FALSE, method = "ML")
q4_cy_search <- search_arima(cy_ts, d_values = c(0, 1), p_max = 6,  q_max = 6,  lb_lag = 8)
q4_cy_trend  <- seq_along(cy_ts)
q4_cy_fit    <- Arima(cy_ts, order = c(3, 0, 2), xreg = q4_cy_trend, include.constant = TRUE)

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

parse_mean_model <- function(model_label) {
  as.integer(regmatches(model_label, gregexpr("[0-9]+", model_label))[[1]])
}

select_mean_order <- function(screen, currency) {
  rows <- screen[screen$currency == currency, ]
  adequate <- rows[rows$lb_p > 0.05, ]
  if (nrow(adequate) == 0) adequate <- rows
  chosen <- adequate[order(adequate$bic, adequate$aic), ][1, ]
  parse_mean_model(chosen$model)
}

q6_mean_orders  <- lapply(names(fx$returns), function(name) select_mean_order(q6_mean_screen, name))
names(q6_mean_orders) <- names(fx$returns)
garch_grid      <- expand.grid(p = 1:4, q = 1:4)
garch_orders    <- lapply(seq_len(nrow(garch_grid)), function(i) c(garch_grid$p[i], garch_grid$q[i]))
variance_models <- c("sGARCH", "gjrGARCH")
distributions   <- c("norm", "std", "sstd")

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
  strict_finite <- rows[rows$lb_z_p > 0.05 & rows$lb_z2_p_adjusted > 0.05 & rows$persistence < 1, ]
  if (nrow(strict_finite) > 0) return(strict_finite[order(strict_finite$bic, strict_finite$aic), ][1, ])

  strict <- rows[rows$lb_z_p > 0.05 & rows$lb_z2_p_adjusted > 0.05, ]
  if (nrow(strict) > 0) return(strict[order(strict$bic, strict$aic), ][1, ])

  course_finite <- rows[rows$lb_z_p > 0.05 & rows$lb_z2_p_course > 0.05 & rows$persistence < 1, ]
  if (nrow(course_finite) > 0) return(course_finite[order(course_finite$bic, course_finite$aic), ][1, ])

  course <- rows[rows$lb_z_p > 0.05 & rows$lb_z2_p_course > 0.05, ]
  if (nrow(course) > 0) return(course[order(course$bic, course$aic), ][1, ])

  rows[order(-rows$lb_z2_p_adjusted, -rows$lb_z_p, rows$bic, rows$aic), ][1, ]
}

make_garch_fit_from_spec <- function(x, arma_order, variance_model, garch_order, distribution, include_mean = TRUE) {
  spec <- ugarchspec(
    variance.model     = list(model = variance_model, garchOrder = garch_order),
    mean.model         = list(armaOrder = arma_order, include.mean = include_mean),
    distribution.model = distribution
  )
  ugarchfit(spec, data = x, solver = "hybrid")
}

q6_best_specs_search <- do.call(rbind, lapply(names(fx$returns), function(name) {
  select_best_garch(q6_garch_screen, name)[, c(
    "currency", "mean_model", "variance_model", "garch_p", "garch_q",
    "distribution", "aic", "bic", "lb_z_p", "lb_z2_p_course",
    "lb_z2_p_adjusted", "persistence"
  )]
}))

q6_arma_specs <- data.frame(
  currency   = c("CNY", "USD", "TWI", "SDR"),
  arma_model = c("ARMA(2,3)", "ARMA(1,0)", "ARMA(1,3)", "ARMA(0,1)"),
  stringsAsFactors = FALSE
)

q6_arma_fits <- lapply(seq_len(nrow(q6_arma_specs)), function(i) {
  row <- q6_arma_specs[i, ]
  Arima(fx$returns[[row$currency]],
        order = c(parse_mean_model(row$arma_model), 0)[c(1, 3, 2)],
        include.mean = TRUE,
        method = "ML")
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
  x    <- as.numeric(residuals(q6_arma_fits[[name]]))
  arch <- engle_arch_lm(x, lags = 10)
  data.frame(
    currency = name,
    arch_lm  = arch["statistic"],
    arch_p   = arch["p_value"],
    lb_sq_p  = lb_p_value(x^2, lag = 10, fitdf = 0)
  )
}))

q6_report_specs <- data.frame(
  currency       = c("CNY", "USD", "TWI", "SDR"),
  mean_model     = c("ARMA(2,2)", "ARMA(2,2)", "ARMA(2,2)", "ARMA(2,2)"),
  variance_model = c("sGARCH", "sGARCH", "sGARCH", "sGARCH"),
  garch_label    = c("GARCH(2,2)", "GARCH(2,2)", "GARCH(2,2)", "GARCH(2,1)"),
  arch_order     = c(2, 2, 2, 1),
  garch_order    = c(2, 2, 2, 2),
  distribution   = c("norm", "norm", "norm", "norm"),
  include_mean   = c(FALSE, TRUE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

q6_final_fits <- lapply(q6_report_specs$currency, function(name) {
  best <- q6_report_specs[q6_report_specs$currency == name, ]
  make_garch_fit_from_spec(
    fx$returns[[name]],
    arma_order     = parse_mean_model(best$mean_model),
    variance_model = as.character(best$variance_model),
    garch_order    = c(best$arch_order, best$garch_order),
    distribution   = as.character(best$distribution),
    include_mean   = isTRUE(best$include_mean)
  )
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
  z   <- as.numeric(residuals(fit, standardize = TRUE))
  arma_order <- parse_mean_model(q6_report_specs[q6_report_specs$currency == name, "mean_model"])
  data.frame(
    currency = name,
    lb_z_p            = lb_p_value(z,   lag = 10, fitdf = sum(arma_order)),
    lb_z2_p_course    = lb_p_value(z^2, lag = 10, fitdf = 0),
    lb_z2_p_adjusted  = lb_p_value(z^2, lag = 10, fitdf = 2)
  )
}))

q6_best_specs <- merge(q6_report_specs, q6_model_ic, by = "currency")
q6_best_specs <- merge(q6_best_specs, q6_diagnostics, by = "currency")

garch_unconditional_variance <- function(fit) {
  cf        <- coef(fit)
  has_gamma <- "gamma1" %in% names(cf)
  persistence <- if (has_gamma) {
    sum(cf[grep("alpha|beta", names(cf))], na.rm = TRUE) + 0.5 * unname(cf["gamma1"])
  } else {
    sum(cf[grep("alpha|beta", names(cf))], na.rm = TRUE)
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
  threshold <- 0.01  # returns are 100*log-diff, so 0.01% = 0.01 in these units
  prob_fn <- function(m, s) {
    if (dist == "std" && !is.na(shape)) {
      pdist("std", q = threshold, mu = m, sigma = s, shape = shape)
    } else if (dist == "norm") {
      pnorm(threshold, mean = m, sd = s)
    } else {
      pdist(dist, q = threshold, mu = m, sigma = s,
            shape = if (!is.na(shape)) shape else 5,
            skew  = if (!is.na(skew))  skew  else 1)
    }
  }
  data.frame(
    currency = name,
    mu_t1    = mu[1],  var_t1 = sigma[1]^2,  sigma_t1 = sigma[1],  prob_t1 = prob_fn(mu[1], sigma[1]),
    mu_t2    = mu[2],  var_t2 = sigma[2]^2,  sigma_t2 = sigma[2],  prob_t2 = prob_fn(mu[2], sigma[2])
  )
}))

q2_model_names <- names(q2_dpt_forecasts)

save_figures <- function() {
  png("fig1_log_levels.png", width = 1800, height = 600, res = fig_res)
  par(mfrow = c(1, 3), mar = c(4.2, 4.2, 3, 1))
  plot(macro$date, macro$pt, type = "l", col = "steelblue4", lwd = 2,
       xlab = "Date", ylab = "Log level", main = expression(p[t] == log(P[t])))
  legend("topleft", legend = expression(p[t]), col = "steelblue4", lty = 1, lwd = 2, bty = "n")
  plot(macro$date, macro$yt, type = "l", col = "firebrick4", lwd = 2,
       xlab = "Date", ylab = "Log level", main = expression(y[t] == log(Y[t])))
  legend("topleft", legend = expression(y[t]), col = "firebrick4", lty = 1, lwd = 2, bty = "n")
  plot(macro$date, macro$ct, type = "l", col = "darkgreen",  lwd = 2,
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
  plot(macro$date[-1], macro$dct[-1], type = "l", col = "darkgreen",  lwd = 2,
       xlab = "Date", ylab = "Log difference", main = expression(Delta*c[t]))
  legend("topleft", legend = expression(Delta*c[t]), col = "darkgreen", lty = 1, lwd = 2, bty = "n")
  plot(macro$date,     macro$r,       type = "l", col = "black",      lwd = 2,
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

  q2_files <- c(
    "fig2b_arima_3_0_3.png",
    "fig2b_arima_1_0_6.png",
    "fig2b_arima_5_0_6.png"
  )
  for (i in seq_along(q2_dpt_forecasts)) {
    png(q2_files[i], width = 1600, height = 650, res = fig_res)
    plot_forecast_bands(q2_dpt_forecasts[[i]], recent_dpt_ts,
                        main_title = bquote("Inflation forecast: " * .(q2_model_names[i]) * ", " * Delta*p[t]),
                        show_all_models = FALSE, actual_ts = NULL, model_index = i)
    dev.off()
  }

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

  png("fig4a_real_rate.png", width = fig_width, height = 500, res = fig_res)
  par(mar = c(4.2, 4.6, 3, 1))
  matplot(macro$date[-1], cbind(macro$r[-1], macro$rr[-1], macro$inflation_pct[-1]),
          type = "l", lty = c(1, 1, 1), lwd = 2,
          col = c("firebrick4", "darkgreen", "steelblue4"), xlab = "Date", ylab = "Percentage points",
          main = expression("Nominal rate, real-rate proxy, and inflation"))
  legend("topleft", legend = expression(r[t], rr[t], 100 * Delta*p[t]),
         col = c("firebrick4", "darkgreen", "steelblue4"), lty = c(1, 1, 1), lwd = 2, bty = "n")
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
  plot(fx$dates, abs(fx$returns$TWI), type = "l", col = "darkgreen",  lwd = 1.5,
       xlab = "Date", ylab = expression(abs(e[t])), main = expression("TWI absolute returns: " * abs(e[t])))
  legend("topleft", legend = "TWI", col = "darkgreen", lty = 1, lwd = 1.5, bty = "n")
  plot(fx$dates, abs(fx$returns$SDR), type = "l", col = "purple4",    lwd = 1.5,
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

  # Q6 diagnostic: ACF of squared standardised residuals + Ljung-Box p-values (lag 1-20)
  png("fig6_sqstd_acf_pval.png", width = 1800, height = 1400, res = fig_res)
  par(mfrow = c(4, 2), mar = c(4.2, 4.5, 3, 1))
  for (name in names(q6_final_fits)) {
    z2 <- as.numeric(residuals(q6_final_fits[[name]], standardize = TRUE))^2
    n  <- length(z2)
    ci <- 1.96 / sqrt(n)

    # --- left panel: ACF of squared standardised residuals, lags 1-20 ---
    acf_out <- acf(z2, lag.max = 20, plot = FALSE)
    acf_vals <- as.numeric(acf_out$acf)[-1]   # drop lag-0
    lags     <- 1:20
    y_lim    <- range(c(acf_vals, -ci, ci), na.rm = TRUE)
    plot(lags, acf_vals, type = "h", lwd = 2, col = "steelblue4",
         xlab = "Lag", ylab = "ACF",
         main = bquote("ACF of " * z[t]^2 * ": " * .(name)),
         ylim = y_lim, xaxt = "n")
    axis(1, at = seq(2, 20, by = 2))
    abline(h = 0,        col = "gray40")
    abline(h = c(-ci, ci), col = "steelblue3", lty = 2)

    # --- right panel: Ljung-Box p-values for lags 1-20 ---
    pvals <- sapply(lags, function(k) Box.test(z2, lag = k, type = "Ljung-Box")$p.value)
    plot(lags, pvals, type = "p", pch = 16, col = "firebrick4", cex = 1.1,
         xlab = "Lag", ylab = "p-value",
         main = bquote("Ljung-Box p-values (" * z[t]^2 * "): " * .(name)),
         ylim = c(0, 1), xaxt = "n")
    axis(1, at = seq(2, 20, by = 2))
    abline(h = 0.05, col = "firebrick3", lty = 2, lwd = 1.5)
    abline(h = 0.10, col = "orange3",    lty = 3, lwd = 1.2)
    legend("bottomright", legend = c("p = 0.05", "p = 0.10"),
           col = c("firebrick3", "orange3"), lty = c(2, 3), lwd = 1.5, bty = "n", cex = 0.85)
  }
  dev.off()

  # Q8: ugarchboot forecast plots (mean and volatility) for each currency
  for (name in names(q6_final_fits)) {
    boot <- ugarchboot(q6_final_fits[[name]], method = "Partial",
                       n.bootpred = 500, n.bootfit = 100)
    png(paste0("fig_q8_boot_mean_", tolower(name), ".png"),
        width = 1200, height = 600, res = fig_res)
    plot(boot, which = 2)
    dev.off()
    png(paste0("fig_q8_boot_vol_", tolower(name), ".png"),
        width = 1200, height = 600, res = fig_res)
    plot(boot, which = 3)
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
      dpt_adequate   = q2_dpt_adequate,
      dpt_top3       = q2_dpt_top3,
      dpt_model_names = q2_model_names,
      rt_search      = q2_rt_search$info,
      rt_adequate    = q2_rt_adequate,
      rt_fit         = q2_rt_fit,
      forecast_table = data.frame(
        quarter    = quarter_labels,
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
        quarter    = eval_quarters,
        actual     = actual_dpt,
        model_1    = as.numeric(q2_dpt_forecasts[[1]]$mean[1:7]),
        model_2    = as.numeric(q2_dpt_forecasts[[2]]$mean[1:7]),
        model_3    = as.numeric(q2_dpt_forecasts[[3]]$mean[1:7])
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
      rr_adequate = q4_rr_adequate,
      cy_model  = q4_cy_fit,
      cy_search = q4_cy_search$info
    ),
    q5 = list(sample_variances = q5_sample_vars),
  q6 = list(
    mean_screen  = q6_mean_screen,
    arma_table   = q6_arma_table,
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
  cat("\n=== Q2 rt adequate models ===\n"); print(head(q2_rt_adequate, 10))
  cat("\n=== Q6 best specs ===\n");         print(q6_best_specs)
  cat("\n=== Q6 diagnostics ===\n");        print(q6_diagnostics)
  cat("\n=== Q7 variances ===\n");          print(q7_variances)
  cat("\n=== Q8 probabilities ===\n");      print(q8_probabilities)
}
