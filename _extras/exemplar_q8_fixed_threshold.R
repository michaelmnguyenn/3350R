## Replicate exemplar Q8 logic exactly, but with threshold = 0.01
## Models chosen exactly as exemplar hard-codes them:
##   CNY: ARMA(2,2)-GARCH(1,2)  [garchOrder=c(1,2) in rugarch]
##   USD: ARMA(2,2)-GARCH(2,2)  [garchOrder=c(2,2)]
##   TWI: ARMA(2,2)-GARCH(2,2)  [garchOrder=c(2,2)]
##   SDR: ARMA(2,2)-GARCH(2,1)  [garchOrder=c(1,2) -> ph=2,qh=1]
## NOTE: exemplar uses garchOrder = c(qh, ph) where qh=ARCH, ph=GARCH

library(readxl)
library(rugarch)

setwd("/Users/michael/Documents/GitHub/3350R")
ex <- read_excel("EXRATE (1).xlsx", sheet = "All")

CNY <- as.matrix(ex$CNY)
USD <- as.matrix(ex$USD)
TWI <- as.matrix(ex$TWI)
SDR <- as.matrix(ex$SDR)

rCNY <- 100 * diff(log(CNY))
rUSD <- 100 * diff(log(USD))
rTWI <- 100 * diff(log(TWI))
rSDR <- 100 * diff(log(SDR))

threshold <- 0.01   # FIXED (exemplar had 0.0001)

fit_and_forecast <- function(r, pm, qm, garch_alpha, garch_beta, label) {
  spec <- ugarchspec(
    mean.model     = list(armaOrder = c(pm, qm)),
    variance.model = list(garchOrder = c(garch_alpha, garch_beta))
  )
  fit <- ugarchfit(spec, r, solver = "hybrid")
  fc  <- ugarchforecast(fit, n.ahead = 2)
  mu    <- as.numeric(fitted(fc))
  sigma <- as.numeric(sigma(fc))
  prob  <- pnorm(threshold, mean = mu, sd = sigma)
  data.frame(
    Currency = label,
    Day      = c("13 Jan", "14 Jan"),
    mu       = round(mu, 4),
    var      = round(sigma^2, 4),
    sigma    = round(sigma, 4),
    prob     = round(prob, 4)
  )
}

# Exemplar model specs (garchOrder = c(qh, ph) i.e. c(ARCH_order, GARCH_order)):
#  CNY: pm=2,qm=2, qh=1,ph=2  -> garchOrder=c(1,2)
#  USD: pm=2,qm=2, qh=2,ph=2  -> garchOrder=c(2,2)
#  TWI: pm=2,qm=2, qh=2,ph=2  -> garchOrder=c(2,2)
#  SDR: pm=2,qm=2, qh=1,ph=2  -> garchOrder=c(1,2)

res_cny <- fit_and_forecast(rCNY, 2, 2, 1, 2, "CNY")
res_usd <- fit_and_forecast(rUSD, 2, 2, 2, 2, "USD")
res_twi <- fit_and_forecast(rTWI, 2, 2, 2, 2, "TWI")
res_sdr <- fit_and_forecast(rSDR, 2, 2, 1, 2, "SDR")

results <- rbind(res_cny, res_usd, res_twi, res_sdr)
print(results, row.names = FALSE)
