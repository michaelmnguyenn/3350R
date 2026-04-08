suppressPackageStartupMessages({
  library(readxl)
  library(rugarch)
})

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

garch_unconditional_variance <- function(fit) {
  cf <- coef(fit)
  persistence <- sum(cf[grep("alpha|beta", names(cf))], na.rm = TRUE) +
    if ("gamma1" %in% names(cf)) 0.5 * unname(cf["gamma1"]) else 0
  if (persistence >= 1) {
    c(persistence = persistence, model_variance = NA_real_)
  } else {
    c(persistence = persistence, model_variance = unname(cf["omega"] / (1 - persistence)))
  }
}

fit_from_spec <- function(x, arma_order, variance_model, garch_order, distribution) {
  spec <- ugarchspec(
    variance.model = list(model = variance_model, garchOrder = garch_order),
    mean.model = list(armaOrder = arma_order, include.mean = TRUE),
    distribution.model = distribution
  )
  ugarchfit(spec, data = x, solver = "hybrid")
}

fx <- load_fx_data()

final_specs <- data.frame(
  currency = c("CNY", "USD", "TWI", "SDR"),
  mean_model = c("ARMA(2,3)", "ARMA(0,0)", "ARMA(1,0)", "ARMA(0,1)"),
  variance_model = c("sGARCH", "sGARCH", "sGARCH", "sGARCH"),
  garch_p = c(1, 3, 1, 4),
  garch_q = c(3, 3, 3, 4),
  distribution = c("norm", "norm", "norm", "norm"),
  stringsAsFactors = FALSE
)

parse_mean_model <- function(model_label) {
  as.integer(regmatches(model_label, gregexpr("[0-9]+", model_label))[[1]])
}

final_fits <- lapply(seq_len(nrow(final_specs)), function(i) {
  row <- final_specs[i, ]
  fit_from_spec(
    fx$returns[[row$currency]],
    parse_mean_model(row$mean_model),
    row$variance_model,
    c(row$garch_p, row$garch_q),
    row$distribution
  )
})
names(final_fits) <- final_specs$currency

diagnostics <- do.call(rbind, lapply(names(final_fits), function(name) {
  fit <- final_fits[[name]]
  z <- as.numeric(residuals(fit, standardize = TRUE))
  arma_order <- parse_mean_model(final_specs[final_specs$currency == name, "mean_model"])
  data.frame(
    currency = name,
    lb_z_p = lb_p_value(z, 10, sum(arma_order)),
    lb_z2_p_course = lb_p_value(z^2, 10, 0),
    lb_z2_p_adjusted = lb_p_value(z^2, 10, 2)
  )
}))

coefficients_long <- do.call(rbind, lapply(names(final_fits), function(name) {
  cf <- coef(final_fits[[name]])
  data.frame(currency = name, term = names(cf), estimate = as.numeric(cf))
}))

q7_variances <- do.call(rbind, lapply(names(final_fits), function(name) {
  uv <- garch_unconditional_variance(final_fits[[name]])
  sample_var <- var(fx$returns[[name]])
  data.frame(
    currency = name,
    persistence = uv["persistence"],
    model_variance = uv["model_variance"],
    sample_variance = sample_var,
    ratio = uv["model_variance"] / sample_var
  )
}))

q8_probabilities <- do.call(rbind, lapply(names(final_fits), function(name) {
  fit <- final_fits[[name]]
  fc <- ugarchforecast(fit, n.ahead = 2)
  mu <- as.numeric(fitted(fc))
  sigma <- as.numeric(sigma(fc))
  prob_fn <- function(m, s) pnorm(0.01, mean = m, sd = s)
  data.frame(
    currency = name,
    mu_t1 = mu[1], sigma_t1 = sigma[1], prob_t1 = prob_fn(mu[1], sigma[1]),
    mu_t2 = mu[2], sigma_t2 = sigma[2], prob_t2 = prob_fn(mu[2], sigma[2])
  )
}))

for (name in names(final_fits)) {
  png(sprintf("fig6_vol_%s.png", name), width = 1500, height = 500, res = 150)
  plot(fx$dates, sigma(final_fits[[name]]), type = "l", col = "steelblue4", lwd = 1.5,
       xlab = "", ylab = "sigma_t", main = sprintf("Conditional volatility: %s", name))
  dev.off()
}

write.csv(final_specs, "q6_final_specs.csv", row.names = FALSE)
write.csv(diagnostics, "q6_final_diagnostics.csv", row.names = FALSE)
write.csv(coefficients_long, "q6_final_coefficients_long.csv", row.names = FALSE)
write.csv(q7_variances, "q7_final_variances.csv", row.names = FALSE)
write.csv(q8_probabilities, "q8_final_probabilities.csv", row.names = FALSE)
