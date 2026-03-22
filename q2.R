rm(list = ls())
library(readxl)
library(forecast)
library(aTSA)

setwd(tryCatch(
  dirname(rstudioapi::getActiveDocumentContext()$path),
  error = function(e) getwd()
))

df <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df)[1:5] <- c("date", "p", "r", "y", "c")
df$date <- as.Date(df$date)
df <- df[1:260, ]

df$pt  <- log(df$p)
df$dpt <- c(NA, diff(df$pt))

dpt <- ts(na.omit(df$dpt), start = c(1959, 2), frequency = 4)
rt  <- ts(df$r, start = c(1959, 1), frequency = 4)

# unit root tests - Delta p_t should be stationary, r_t is less clear
adf.test(dpt)
adf.test(rt)

# ACF/PACF to guide order selection
par(mfrow = c(2, 2))
acf(dpt,  lag.max = 20, main = "SACF of Delta p_t")
pacf(dpt, lag.max = 20, main = "SPACF of Delta p_t")
acf(rt,   lag.max = 20, main = "SACF of r_t")
pacf(rt,  lag.max = 20, main = "SPACF of r_t")
par(mfrow = c(1, 1))

# model selection for Delta p_t - nested loop over p and q
ARMA_est <- list()
ic_dpt <- matrix(nrow = 4 * 4, ncol = 4)
colnames(ic_dpt) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_est[[i]] <- Arima(dpt, order = c(p, 0, q))
    ic_dpt[i, ] <- c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
  }
}

# sort by AIC and BIC separately, look at top 10 each
ic_aic_dpt <- ic_dpt[order(ic_dpt[, 3]), ][1:10, ]
ic_bic_dpt <- ic_dpt[order(ic_dpt[, 4]), ][1:10, ]
ic_aic_dpt
ic_bic_dpt

# take the intersection of both top-10 lists as the adequate set
ic_int_dpt <- intersect(as.data.frame(ic_aic_dpt), as.data.frame(ic_bic_dpt))
ic_int_dpt

# pick 3 models for reporting - ARMA(2,1), ARMA(1,2), ARMA(3,0)
m_21 <- Arima(dpt, order = c(2, 0, 1))
m_12 <- Arima(dpt, order = c(1, 0, 2))
m_30 <- Arima(dpt, order = c(3, 0, 0))

summary(m_21)
summary(m_12)
summary(m_30)

# check residuals for each candidate
checkresiduals(m_21)
Sys.sleep(2)
checkresiduals(m_12)
Sys.sleep(2)
checkresiduals(m_30)
Sys.sleep(2)

# same process for r_t - treat as I(1) based on ADF result
ARMA_est_r <- list()
ic_r <- matrix(nrow = 4 * 4, ncol = 4)
colnames(ic_r) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_est_r[[i]] <- Arima(rt, order = c(p, 1, q))
    ic_r[i, ] <- c(p, q, ARMA_est_r[[i]]$aic, ARMA_est_r[[i]]$bic)
  }
}

ic_aic_r <- ic_r[order(ic_r[, 3]), ][1:10, ]
ic_bic_r <- ic_r[order(ic_r[, 4]), ][1:10, ]
ic_aic_r
ic_bic_r

# forecast Delta p_t 8 quarters ahead (2024Q1 to 2025Q4)
fc1 <- forecast(m_21, h = 8, level = c(80, 95))
fc2 <- forecast(m_12, h = 8, level = c(80, 95))
fc3 <- forecast(m_30, h = 8, level = c(80, 95))

# 2a - plot forecasts - base R forecast plot with all 3 models overlaid
plot(fc1, include = 20, main = "Delta p_t forecasts (2024Q1-2025Q4)",
     xlab = "", ylab = "Delta p_t", col = "steelblue")
lines(fc2$mean, col = "red", lty = 2)
lines(fc3$mean, col = "darkgreen", lty = 3)
legend("topleft", legend = c("ARMA(2,1)", "ARMA(1,2)", "ARMA(3,0)"),
       col = c("steelblue", "red", "darkgreen"), lty = 1:3, bty = "n")

fc1
fc2
fc3

# CI width at h=1 vs h=8 shows how uncertainty grows with horizon
as.numeric(fc1$upper[1, 2]) - as.numeric(fc1$lower[1, 2])
as.numeric(fc1$upper[8, 2]) - as.numeric(fc1$lower[8, 2])
