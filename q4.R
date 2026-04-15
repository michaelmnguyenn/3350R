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

# --- ADF (standard, for reference) ---
# H0: unit root.  tseries::adf.test includes a trend term; lag = floor((n-1)^1/3) = 6.
cat("\n=== ADF test on rr_t (standard, with trend) ===\n")
adf_rr <- adf.test(rr)
print(adf_rr)
# Result: stat=-2.981, p=0.163 — fails to reject at 5%.
# NOTE: including a trend is inappropriate for real interest rates (no theory for trend).

# --- DF-GLS (Elliott, Rothenberg, Stock 1996) ---
# More powerful than ADF: GLS detrending under H1 removes the trend/drift before testing.
# H0: unit root.  model="constant" = drift only (correct for rr_t).
cat("\n=== DF-GLS test on rr_t ===\n")
dfgls_rr <- ur.ers(rr, type = "DF-GLS", model = "constant", lag.max = 6)
summary(dfgls_rr)
# stat = -2.249, 5% critical = -1.94  → REJECT at 5%

# ── Decision: d = 0 ─────────────────────────────────────────────────────────
# DF-GLS: stat=-2.249 < 5% critical -1.94 → reject unit root at 5%.
# Justification:
#  1. DF-GLS is specifically designed to improve power of ADF against near-I(0).
#     Standard ADF fails (low power) because it includes a trend and uses OLS detrending.
#  2. Fisher hypothesis: rr_t = r_t - 100*dpt is theoretically I(0) (cointegrating residual).
#     A unit root would imply ever-drifting real rates, contradicting monetary equilibrium.
#  3. Plot confirms rr_t oscillates around ~3.4% with no secular drift.
cat("\nDecision: d = 0  (DF-GLS rejects unit root at 5%; Fisher hypothesis confirms I(0)).\n\n")

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

# ARIMA(8,0,1): top by AIC and in BIC top-5 (appears in intersection)
best_rr <- Arima(rr, order = c(8, 0, 1), include.constant = TRUE)
cat(sprintf("\nSelected: ARIMA(8,0,1)  AIC=%.4f  BIC=%.4f\n", best_rr$aic, best_rr$bic))
cat(sprintf("Ljung-Box (lag 10): p=%.4f\n",
            Box.test(residuals(best_rr), lag = 10, type = "Ljung-Box")$p.value))
print(round(coef(best_rr), 4))
checkresiduals(best_rr)

# ── 4d: Consumption ratio ──────────────────────────────────────────────────────
cy <- ts(df$cy, start = c(1959, 1), frequency = 4)

cat("\n=== ADF test on cy_t ===\n")
adf_cy <- adf.test(cy)
print(adf_cy)

par(mfrow = c(1, 2))
acf(cy,  lag.max = 20, main = "SACF of cy_t")
pacf(cy, lag.max = 20, main = "SPACF of cy_t")
par(mfrow = c(1, 1))

ARMA_cy <- list()
ic_cy   <- matrix(nrow = 4 * 4, ncol = 4)
colnames(ic_cy) <- c("p", "q", "aic", "bic")
for (p in 0:3) for (q in 0:3) {
  i <- p * 4 + q + 1
  ARMA_cy[[i]] <- Arima(cy, order = c(p, 1, q))
  ic_cy[i, ]   <- c(p, q, ARMA_cy[[i]]$aic, ARMA_cy[[i]]$bic)
}

cat("=== AIC top 5 (cy_t) ===\n")
print(ic_cy[order(ic_cy[, 3]), ][1:5, ])

best_cy <- Arima(cy, order = c(2, 1, 2))
summary(best_cy)
checkresiduals(best_cy)
