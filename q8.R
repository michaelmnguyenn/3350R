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

# data ends 12/01/2026, so T+1 = 13/01/2026 and T+2 = 14/01/2026

# refit best GJR-GARCH models from Q6
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

# forecast 2 steps ahead and compute P(e < 0.01%)
# using Student-t distribution with estimated degrees of freedom
prob_below <- function(fit, label)
{
  fc  <- ugarchforecast(fit, n.ahead = 2)
  mu  <- as.numeric(fitted(fc))
  sig <- as.numeric(sigma(fc))
  nu  <- as.numeric(coef(fit)["shape"])

  cat(label, "- mu forecast:    ", round(mu,  5), "\n")
  cat(label, "- sigma forecast: ", round(sig, 5), "\n")

  # P(e < 0.01) under scaled Student-t
  p13 <- pt((0.01 - mu[1]) / sig[1], df = nu)
  p14 <- pt((0.01 - mu[2]) / sig[2], df = nu)

  cat(label, "- P(e < 0.01) on 13/01/2026:", round(p13, 6), "\n")
  cat(label, "- P(e < 0.01) on 14/01/2026:", round(p14, 6), "\n\n")
}

prob_below(fit_cny, "CNY")
prob_below(fit_usd, "USD")
prob_below(fit_twi, "TWI")
prob_below(fit_sdr, "SDR")
