rm(list = ls())
library(readxl)

setwd(tryCatch(
  dirname(rstudioapi::getActiveDocumentContext()$path),
  error = function(e) getwd()
))

ex <- read_excel("EXRATE (1).xlsx", sheet = "All")
ex <- ex[, 1:5]
names(ex) <- c("Date", "CNY", "USD", "TWI", "SDR")
ex$Date <- as.Date(ex$Date)

# compute 100 x log-difference returns for each currency
e_cny <- 100 * diff(log(ex$CNY))
e_usd <- 100 * diff(log(ex$USD))
e_twi <- 100 * diff(log(ex$TWI))
e_sdr <- 100 * diff(log(ex$SDR))

dates <- ex$Date[-1]

# 5a - sample variances
var(e_cny)
var(e_usd)
var(e_twi)
var(e_sdr)

# 5b - plot absolute returns to visualise volatility clustering
par(mfrow = c(2, 2))
plot(dates, abs(e_cny), type = "l", xlab = "", ylab = "|e_t| (%)", main = "CNY")
plot(dates, abs(e_usd), type = "l", xlab = "", ylab = "|e_t| (%)", main = "USD")
plot(dates, abs(e_twi), type = "l", xlab = "", ylab = "|e_t| (%)", main = "TWI")
plot(dates, abs(e_sdr), type = "l", xlab = "", ylab = "|e_t| (%)", main = "SDR")
par(mfrow = c(1, 1))
