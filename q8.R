rm(list = ls())
library(readxl)
library(rugarch)

setwd("/Users/michael/Downloads/ECON3350")

ex <- read_excel("EXRATE (1).xlsx", sheet = "All")
ex <- ex[, 1:5]
names(ex) <- c("Date", "CNY", "USD", "TWI", "SDR")
ex$Date <- as.Date(ex$Date)

e_cny <- 100 * diff(log(ex$CNY))
e_usd <- 100 * diff(log(ex$USD))
e_twi <- 100 * diff(log(ex$TWI))
e_sdr <- 100 * diff(log(ex$SDR))

# data ends 12/01/2026  →  T+1 = 13/01/2026,  T+2 = 14/01/2026

# ─────────────────────────────────────────────────────────────────────────────
# Fit Q6 models (same specs as q7.R):
#   CNY: ARMA(2,2)-sGARCH(1,2), with intercept  (include.mean=TRUE)
#   USD: ARMA(2,2)-sGARCH(2,2), with intercept  (include.mean=TRUE)
#   TWI: ARMA(2,2)-sGARCH(2,2), with intercept  (include.mean=TRUE)
#   SDR: ARMA(2,2)-sGARCH(1,2), with intercept  (include.mean=TRUE)
# ─────────────────────────────────────────────────────────────────────────────
make_spec <- function(arma_order, garch_order, inc_mean = TRUE) {
  ugarchspec(
    mean.model         = list(armaOrder = arma_order, include.mean = inc_mean),
    variance.model     = list(model = "sGARCH", garchOrder = garch_order),
    distribution.model = "norm"
  )
}

# CNY: ARMA(2,2)-sGARCH(1,2) with mean (exemplar spec); gosolnp for reliable convergence
fit_cny <- ugarchfit(make_spec(c(2, 2), c(1, 2), inc_mean = TRUE), data = e_cny,
                    solver = "gosolnp",
                    solver.control = list(n.sim = 100, n.restarts = 10, rseed = 1234))
fit_usd <- ugarchfit(make_spec(c(2, 2), c(2, 2)),                    data = e_usd, solver = "hybrid")
fit_twi <- ugarchfit(make_spec(c(2, 2), c(2, 2)),                    data = e_twi, solver = "hybrid")

# SDR: hybrid solver (matches exemplar methodology)
fit_sdr <- ugarchfit(make_spec(c(2, 2), c(1, 2)), data = e_sdr, solver = "hybrid")

# ─────────────────────────────────────────────────────────────────────────────
# Q8: 2-step-ahead forecast and P(e_t < 0.01%)
#
# Distribution assumption: Normal  →  use pnorm()
# P(e_{T+h} < 0.01 | I_T) = Phi( (0.01 - mu_{T+h}) / sigma_{T+h} )
# ─────────────────────────────────────────────────────────────────────────────
prob_below <- function(fit, label) {
  fc  <- ugarchforecast(fit, n.ahead = 2)
  mu  <- as.numeric(fitted(fc))
  sig <- as.numeric(sigma(fc))

  cat(sprintf("%s  mu forecast:    %8.5f  %8.5f\n", label, mu[1],  mu[2]))
  cat(sprintf("%s  sigma forecast: %8.5f  %8.5f\n", label, sig[1], sig[2]))

  # P(e < 0.01) under Normal(mu, sigma^2)
  p13 <- pnorm(0.01, mean = mu[1], sd = sig[1])
  p14 <- pnorm(0.01, mean = mu[2], sd = sig[2])

  cat(sprintf("%s  P(e < 0.01) on 13/01/2026: %.4f  (%.2f%%)\n", label, p13, 100*p13))
  cat(sprintf("%s  P(e < 0.01) on 14/01/2026: %.4f  (%.2f%%)\n\n", label, p14, 100*p14))

  data.frame(
    Day         = c("13/01/2026", "14/01/2026"),
    Mu          = round(mu,  4),
    Sigma       = round(sig, 4),
    Probability = round(c(p13, p14), 4)
  )
}

results_cny <- prob_below(fit_cny, "CNY")
results_usd <- prob_below(fit_usd, "USD")
results_twi <- prob_below(fit_twi, "TWI")
results_sdr <- prob_below(fit_sdr, "SDR")

cat("=== CNY ===\n"); print(results_cny)
cat("=== USD ===\n"); print(results_usd)
cat("=== TWI ===\n"); print(results_twi)
cat("=== SDR ===\n"); print(results_sdr)
