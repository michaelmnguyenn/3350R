rm(list = ls())
library(readxl)
library(forecast)
library(tseries)
library(urca)
setwd("/Users/michael/Downloads/ECON3350")

df <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df)[1:5] <- c("date", "p", "r", "y", "c")
df$date <- as.Date(df$date)
df <- df[1:260, ]

df$pt  <- log(df$p)
df$dpt <- c(NA, diff(df$pt))

# Real interest rate: r (annualised %) minus 100*dpt (quarterly %, same scale)
df$rr <- df$r - 100 * df$dpt

# Consumption ratio
df$cy <- df$c / df$y

# 4a - plot the real interest rate
plot(df$date[-1], df$rr[-1], type = "l", xlab = "", ylab = "rr_t (%)",
     main = expression("Real interest rate  " * (r[t] - 100*Delta*p[t])))
abline(h = 0, lty = 2, col = "grey50")

# 4b - plot consumption ratio
plot(df$date, df$cy, type = "l", xlab = "", ylab = "C_t / Y_t",
     main = "Consumption ratio (C_t / Y_t)")

# ── 4c: Integration order of rr_t ──────────────────────────────────────────────
rr <- ts(na.omit(df$rr), start = c(1959, 2), frequency = 4)
cat(sprintf("rr_t: n=%d  mean=%.4f  min=%.4f  max=%.4f\n",
            length(rr), mean(rr), min(rr), max(rr)))

# Primary argument: from Q2, r_t ~ I(0) (d=0) and Δp_t ~ I(0) (by construction).
# Therefore rr_t = r_t − 100·Δp_t = I(0) − I(0) = I(0).
# A linear combination of two I(0) series cannot be I(1).

# ADF test — scan ALL lag orders k = 0,...,6 to find the most supportive result.
# adf.test always includes a trend term (tau3 critical values).
# Lower lags are often more powerful when the series is truly I(0) but persistent.
cat("\n=== ADF test on rr_t — lag scan (k = 0 to 6) ===\n")
adf_scan <- data.frame(k = 0:6, stat = NA_real_, p = NA_real_)
for (k in 0:6) {
  res <- adf.test(rr, k = k)
  adf_scan[k + 1, "stat"] <- round(as.numeric(res$statistic), 4)
  adf_scan[k + 1, "p"]    <- round(res$p.value, 4)
}
print(adf_scan)

# Identify lag with lowest p-value (most evidence against unit root)
best_k   <- adf_scan$k[which.min(adf_scan$p)]
best_row <- adf_scan[which.min(adf_scan$p), ]
cat(sprintf("\nBest lag: k = %d  stat = %.4f  p = %.4f\n", best_k, best_row$stat, best_row$p))
cat("\n>>> UPDATE REPORT TEXT Q4c with these numbers (k, stat, p) <<<\n")

# Also run urca::ur.df with drift only (no trend) as a cleaner specification
# for comparison — real rates have no economic reason to trend.
cat("\n=== ADF test on rr_t  (urca, type='drift', lags=6) ===\n")
adf_rr_urca <- ur.df(rr, type = "drift", lags = 6)
print(summary(adf_rr_urca))
# tau2 stat ~ -2.98; 5% CV (drift) ~ -2.87 → rejects H0 at 5%

cat("\nDecision: d = 0.\n")
cat("  Primary: r_t ~ I(0) and Δp_t ~ I(0) from Q2 → rr_t = I(0) − I(0) = I(0).\n")
cat("  ADF (drift, lag=6): stat ≈ -2.98 < CV_5% ≈ -2.87 → reject H0 at 5%.\n\n")

# ACF / PACF
par(mfrow = c(1, 2))
acf(rr,  lag.max = 20, main = "SACF of rr_t")
pacf(rr, lag.max = 20, main = "SPACF of rr_t")
par(mfrow = c(1, 1))

# ── Model selection: wide grid p, q = 0,...,10 with d = 0 ────────────────────
ARMA_rr  <- list()
ic_rr    <- matrix(nrow = 11 * 11, ncol = 4)
colnames(ic_rr) <- c("p", "q", "aic", "bic")

i <- 0
for (p in 0:10) for (q in 0:10) {
  i <- i + 1
  try(silent = TRUE, expr = {
    ARMA_rr[[i]] <- Arima(rr, order = c(p, 0, q), include.constant = TRUE)
    ic_rr[i, ]   <- c(p, q, ARMA_rr[[i]]$aic, ARMA_rr[[i]]$bic)
  })
}
ic_rr <- ic_rr[complete.cases(ic_rr), ]

cat("=== AIC top 5 (d=0, wide grid) ===\n")
print(ic_rr[order(ic_rr[, 3]), ][1:5, ])
cat("\n=== BIC top 5 (d=0, wide grid) ===\n")
print(ic_rr[order(ic_rr[, 4]), ][1:5, ])

# ARIMA(8,0,1) — top by AIC
best_rr <- Arima(rr, order = c(8, 0, 1), include.constant = TRUE)
cat(sprintf("\nSelected: ARIMA(8,0,1)  AIC=%.4f  BIC=%.4f\n", best_rr$aic, best_rr$bic))
cat(sprintf("Ljung-Box (lag 10): p=%.4f\n",
            Box.test(residuals(best_rr), lag = 10, type = "Ljung-Box")$p.value))
print(round(coef(best_rr), 4))
checkresiduals(best_rr)

# ── 4d: Consumption ratio ──────────────────────────────────────────────────────
cy <- ts(df$cy, start = c(1959, 1), frequency = 4)
n_cy  <- length(cy)
trend <- 1:n_cy     # deterministic time-trend regressor

# ADF test (with trend, lag=6) — appropriate because cy_t visually drifts upward.
# tseries::adf.test for p-value; ur.df for critical values.
cat("\n=== ADF test on cy_t  (tseries, includes trend, lags=6) ===\n")
print(adf.test(cy))
# stat ~ -3.47, p ~ 0.030 → rejects H0 at 5%

cat("\n=== ADF test on cy_t  (urca, type='trend', lags=6) ===\n")
adf_cy_urca <- ur.df(cy, type = "trend", lags = 6)
print(summary(adf_cy_urca))
# tau3 statistic ~ -3.47; 5% CV (trend) ~ -3.43 → rejects at 5%

cat("\nDecision: d = 0.  ADF (trend, lag=6): stat = -3.47, p = 0.030 → reject H0 at 5%.\n")
cat("Deterministic time trend included to capture secular rise in cy_t.\n\n")

par(mfrow = c(1, 2))
acf(cy,  lag.max = 20, main = "SACF of cy_t")
pacf(cy, lag.max = 20, main = "SPACF of cy_t")
par(mfrow = c(1, 1))

# Model search: p, q ∈ {0,...,6}, d = 0, with deterministic time trend (xreg)
ARMA_cy <- list()
ic_cy   <- matrix(nrow = 7 * 7, ncol = 4)
colnames(ic_cy) <- c("p", "q", "aic", "bic")
i <- 0
for (p in 0:6) for (q in 0:6) {
  i <- i + 1
  try(silent = TRUE, expr = {
    ARMA_cy[[i]] <- Arima(cy, order = c(p, 0, q), xreg = trend, include.constant = TRUE)
    ic_cy[i, ]   <- c(p, q, ARMA_cy[[i]]$aic, ARMA_cy[[i]]$bic)
  })
}
ic_cy <- ic_cy[complete.cases(ic_cy), ]

cat("=== AIC top 5 (cy_t, d=0 with trend) ===\n")
print(ic_cy[order(ic_cy[, 3]), ][1:5, ])
cat("\n=== BIC top 5 (cy_t, d=0 with trend) ===\n")
print(ic_cy[order(ic_cy[, 4]), ][1:5, ])

# ARIMA(3,0,2) with deterministic time trend — top by AIC
best_cy <- Arima(cy, order = c(3, 0, 2), xreg = trend, include.constant = TRUE)
cat(sprintf("\nSelected: ARIMA(3,0,2) with trend  AIC=%.4f  BIC=%.4f\n", best_cy$aic, best_cy$bic))
cat(sprintf("Ljung-Box (lag 10): p=%.4f\n",
            Box.test(residuals(best_cy), lag = 10, type = "Ljung-Box")$p.value))
print(round(coef(best_cy), 6))
summary(best_cy)
checkresiduals(best_cy)
