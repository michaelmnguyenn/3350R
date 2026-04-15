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

# sample variances (Q5) for comparison
var_cny <- var(e_cny)
var_usd <- var(e_usd)
var_twi <- var(e_twi)
var_sdr <- var(e_sdr)

# ─────────────────────────────────────────────────────────────────────────────
# Refit the Q6 models: standard sGARCH, Normal errors
#
# Model selected from Q6 IC grid (adequate set, AIC/BIC intersection):
#   CNY:  ARMA(2,2) – sGARCH(1,2)   [garchOrder = c(1,2): 1 ARCH + 2 GARCH]
#   USD:  ARMA(2,2) – sGARCH(2,2)
#   TWI:  ARMA(2,2) – sGARCH(2,2)
#   SDR:  ARMA(2,2) – sGARCH(1,2)
#
# NOTE: the exemplar loops with garchOrder = c(qh, ph) where ph is ARCH order
# and qh is GARCH order – matching that convention here.
# ─────────────────────────────────────────────────────────────────────────────
make_spec <- function(arma_order, garch_order, inc_mean = TRUE) {
  ugarchspec(
    mean.model         = list(armaOrder = arma_order, include.mean = inc_mean),
    variance.model     = list(model = "sGARCH", garchOrder = garch_order),
    distribution.model = "norm"
  )
}

# CNY: ARMA(2,2)-sGARCH(1,2) with mean (matches exemplar spec); gosolnp for convergence
fit_cny <- ugarchfit(make_spec(c(2, 2), c(1, 2), inc_mean = TRUE), data = e_cny,
                    solver = "gosolnp",
                    solver.control = list(n.sim = 100, n.restarts = 10, rseed = 1234))
fit_usd <- ugarchfit(make_spec(c(2, 2), c(2, 2)),                  data = e_usd, solver = "hybrid")
fit_twi <- ugarchfit(make_spec(c(2, 2), c(2, 2)),                  data = e_twi, solver = "hybrid")
# SDR: hybrid solver (matches exemplar methodology; same data yields same results)
fit_sdr <- ugarchfit(make_spec(c(2, 2), c(1, 2)), data = e_sdr, solver = "hybrid")

# ─────────────────────────────────────────────────────────────────────────────
# Q7: Unconditional (long-run) variance
#
# For sGARCH:  sigma^2_infinity = omega / (1 - sum(alpha_i) - sum(beta_j))
# Persistence  = sum(alpha_i) + sum(beta_j)
# Model is covariance-stationary when persistence < 1.
# ─────────────────────────────────────────────────────────────────────────────
uncond_var <- function(fit, label, sample_var)
{
  cf      <- coef(fit)
  omega   <- cf["omega"]
  alphas  <- cf[ grep("^alpha", names(cf)) ]   # alpha1, alpha2, ...
  betas   <- cf[ grep("^beta",  names(cf)) ]   # beta1,  beta2,  ...

  persistence <- sum(alphas) + sum(betas)
  denom       <- 1 - persistence

  cat(sprintf("%s  persistence (sum alpha + sum beta) = %.5f\n",
              label, persistence))

  if (denom > 0) {
    v <- omega / denom
    cat(sprintf("%s  model unconditional variance = %.5f  |  sample variance = %.5f\n\n",
                label, v, sample_var))
  } else {
    cat(label, "– IGARCH: unconditional variance does not exist (persistence >= 1)\n\n")
  }
}

uncond_var(fit_cny, "CNY", var_cny)
uncond_var(fit_usd, "USD", var_usd)
uncond_var(fit_twi, "TWI", var_twi)
uncond_var(fit_sdr, "SDR", var_sdr)

# print full coefficient tables for reference
cat("=== Coefficients ===\n")
cat("CNY:\n"); print(coef(fit_cny))
cat("USD:\n"); print(coef(fit_usd))
cat("TWI:\n"); print(coef(fit_twi))
cat("SDR:\n"); print(coef(fit_sdr))
