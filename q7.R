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

# sample variances (from Q5) for comparison
var_cny <- var(e_cny)
var_usd <- var(e_usd)
var_twi <- var(e_twi)
var_sdr <- var(e_sdr)

# refit the best GJR-GARCH(1,1) models selected in Q6
spec_gjr <- ugarchspec(
  variance.model     = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model         = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "std")

spec_twi <- ugarchspec(
  variance.model     = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model         = list(armaOrder = c(1, 0), include.mean = TRUE),
  distribution.model = "std")

spec_sdr <- ugarchspec(
  variance.model     = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model         = list(armaOrder = c(0, 1), include.mean = TRUE),
  distribution.model = "std")

fit_cny <- ugarchfit(spec_gjr, data = e_cny, solver = "hybrid")
fit_usd <- ugarchfit(spec_gjr, data = e_usd, solver = "hybrid")
fit_twi <- ugarchfit(spec_twi, data = e_twi, solver = "hybrid")
fit_sdr <- ugarchfit(spec_sdr, data = e_sdr, solver = "hybrid")

# GJR-GARCH unconditional variance formula: omega / (1 - alpha - beta - gamma/2)
# only exists when alpha + beta + gamma/2 < 1 (covariance stationarity)
uncond_var <- function(fit, label, sample_var)
{
  cf    <- coef(fit)
  omega <- cf["omega"]
  alpha <- cf["alpha1"]
  beta  <- cf["beta1"]
  gamma <- cf["gamma1"]

  denom <- 1 - alpha - beta - gamma / 2
  cat(label, "- persistence (alpha + beta + gamma/2) =",
      round(alpha + beta + gamma / 2, 5), "\n")

  if (denom > 0)
  {
    v <- omega / denom
    cat(label, "- model unconditional variance:", round(v, 5),
        " | sample variance:", round(sample_var, 5), "\n\n")
  }
  else
  {
    cat(label, "- IGARCH: unconditional variance does not exist\n\n")
  }
}

uncond_var(fit_cny, "CNY", var_cny)
uncond_var(fit_usd, "USD", var_usd)
uncond_var(fit_twi, "TWI", var_twi)
uncond_var(fit_sdr, "SDR", var_sdr)
