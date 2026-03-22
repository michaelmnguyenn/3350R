rm(list = ls())
library(readxl)
library(forecast)
library(aTSA)

setwd("/Users/michael/Downloads/ECON3350")

df <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df)[1:5] <- c("date", "p", "r", "y", "c")
df$date <- as.Date(df$date)
df <- df[1:260, ]

df$pt  <- log(df$p)
df$dpt <- c(NA, diff(df$pt))

# real interest rate = nominal rate minus quarterly inflation
df$rr <- df$r - df$dpt

# consumption ratio = C / Y (raw levels, not logs)
df$cy <- df$c / df$y

# 4a - plot the real interest rate
plot(df$date[-1], df$rr[-1], type = "l", xlab = "", ylab = "rr_t (%)",
     main = "Real interest rate (r_t - Delta p_t)")
abline(h = 0, lty = 2, col = "grey50")

# 4b - plot consumption ratio
plot(df$date, df$cy, type = "l", xlab = "", ylab = "C_t / Y_t",
     main = "Consumption ratio (C_t / Y_t)")

# 4c - ARIMA model selection for real interest rate
rr <- ts(na.omit(df$rr), start = c(1959, 2), frequency = 4)

adf.test(rr)

par(mfrow = c(1, 2))
acf(rr,  lag.max = 20, main = "SACF of rr_t")
pacf(rr, lag.max = 20, main = "SPACF of rr_t")
par(mfrow = c(1, 1))

# nested loop for rr_t with d=1 (consistent with near unit root in ADF)
ARMA_rr <- list()
ic_rr <- matrix(nrow = 4 * 4, ncol = 4)
colnames(ic_rr) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_rr[[i]] <- Arima(rr, order = c(p, 1, q))
    ic_rr[i, ] <- c(p, q, ARMA_rr[[i]]$aic, ARMA_rr[[i]]$bic)
  }
}

ic_rr[order(ic_rr[, 3]), ][1:5, ]
ic_rr[order(ic_rr[, 4]), ][1:5, ]

# best model for rr_t
best_rr <- Arima(rr, order = c(2, 1, 2), seasonal = c(0, 0, 1))
summary(best_rr)
checkresiduals(best_rr)

# 4d - ARIMA model selection for consumption ratio
cy <- ts(df$cy, start = c(1959, 1), frequency = 4)

adf.test(cy)

par(mfrow = c(1, 2))
acf(cy,  lag.max = 20, main = "SACF of cy_t")
pacf(cy, lag.max = 20, main = "SPACF of cy_t")
par(mfrow = c(1, 1))

ARMA_cy <- list()
ic_cy <- matrix(nrow = 4 * 4, ncol = 4)
colnames(ic_cy) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_cy[[i]] <- Arima(cy, order = c(p, 1, q))
    ic_cy[i, ] <- c(p, q, ARMA_cy[[i]]$aic, ARMA_cy[[i]]$bic)
  }
}

ic_cy[order(ic_cy[, 3]), ][1:5, ]
ic_cy[order(ic_cy[, 4]), ][1:5, ]

# best model for cy_t
best_cy <- Arima(cy, order = c(2, 1, 2))
summary(best_cy)
checkresiduals(best_cy)
