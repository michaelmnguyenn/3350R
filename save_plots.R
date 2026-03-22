# Run this script to save all report figures as PNG files.
# Source each question's core code but wrap plot calls in png()/dev.off().

rm(list = ls())
library(readxl)
library(forecast)
library(aTSA)
library(rugarch)

setwd("/Users/michael/Downloads/ECON3350")

# ---- Q1 plots ----
df <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df)[1:5] <- c("date", "p", "r", "y", "c")
df$date <- as.Date(df$date)
df <- df[1:260, ]
df$pt  <- log(df$p); df$yt <- log(df$y); df$ct <- log(df$c)
df$dpt <- c(NA, diff(df$pt))
df$dyt <- c(NA, diff(df$yt))
df$dct <- c(NA, diff(df$ct))
df$trend <- 1:nrow(df)

png("fig1_log_levels.png", width = 1800, height = 600, res = 150)
par(mfrow = c(1, 3))
plot(df$date, df$pt, type = "l", xlab = "", ylab = "log(P)", main = "p_t = log(P_t)")
plot(df$date, df$yt, type = "l", xlab = "", ylab = "log(Y)", main = "y_t = log(Y_t)")
plot(df$date, df$ct, type = "l", xlab = "", ylab = "log(C)", main = "c_t = log(C_t)")
dev.off()

png("fig2_log_diffs.png", width = 1800, height = 900, res = 150)
par(mfrow = c(2, 2))
plot(df$date[-1], df$dpt[-1], type = "l", xlab = "", ylab = "Delta p_t", main = "Inflation (Delta p_t)")
plot(df$date[-1], df$dyt[-1], type = "l", xlab = "", ylab = "Delta y_t", main = "GDP growth (Delta y_t)")
plot(df$date[-1], df$dct[-1], type = "l", xlab = "", ylab = "Delta c_t", main = "Consumption growth (Delta c_t)")
plot(df$date, df$r, type = "l", xlab = "", ylab = "r_t (%)", main = "T-bill rate (r_t)")
dev.off()

# ---- Q2 forecast plot ----
dpt <- ts(na.omit(df$dpt), start = c(1959, 2), frequency = 4)
m_21 <- Arima(dpt, order = c(2, 0, 1))
m_12 <- Arima(dpt, order = c(1, 0, 2))
m_30 <- Arima(dpt, order = c(3, 0, 0))
fc1  <- forecast(m_21, h = 8, level = c(80, 95))
fc2  <- forecast(m_12, h = 8, level = c(80, 95))
fc3  <- forecast(m_30, h = 8, level = c(80, 95))

png("fig2a_forecast.png", width = 1500, height = 600, res = 150)
plot(fc1, include = 20, main = "Inflation forecasts 2024Q1-2025Q4",
     xlab = "", ylab = "Delta p_t", col = "steelblue")
lines(fc2$mean, col = "red", lty = 2)
lines(fc3$mean, col = "darkgreen", lty = 3)
legend("topleft", legend = c("ARMA(2,1)", "ARMA(1,2)", "ARMA(3,0)"),
       col = c("steelblue", "red", "darkgreen"), lty = 1:3, bty = "n")
dev.off()

# ---- Q4 plots ----
df$rr <- df$r - df$dpt
df$cy <- df$c / df$y

png("fig4a_real_rate.png", width = 1500, height = 500, res = 150)
plot(df$date[-1], df$rr[-1], type = "l", xlab = "", ylab = "rr_t (%)",
     main = "Real interest rate (r_t - Delta p_t)")
abline(h = 0, lty = 2, col = "grey50")
dev.off()

png("fig4b_consumption_ratio.png", width = 1500, height = 500, res = 150)
plot(df$date, df$cy, type = "l", xlab = "", ylab = "C_t / Y_t",
     main = "Consumption ratio (C_t / Y_t)")
dev.off()

# ---- Q5 absolute returns plot ----
ex <- read_excel("EXRATE (1).xlsx", sheet = "All")
ex <- ex[, 1:5]
names(ex) <- c("Date", "CNY", "USD", "TWI", "SDR")
ex$Date <- as.Date(ex$Date)
e_cny <- 100 * diff(log(ex$CNY))
e_usd <- 100 * diff(log(ex$USD))
e_twi <- 100 * diff(log(ex$TWI))
e_sdr <- 100 * diff(log(ex$SDR))
dates <- ex$Date[-1]

png("fig5b_abs_returns.png", width = 1800, height = 900, res = 150)
par(mfrow = c(2, 2))
plot(dates, abs(e_cny), type = "l", xlab = "", ylab = "|e_t| (%)", main = "CNY")
plot(dates, abs(e_usd), type = "l", xlab = "", ylab = "|e_t| (%)", main = "USD")
plot(dates, abs(e_twi), type = "l", xlab = "", ylab = "|e_t| (%)", main = "TWI")
plot(dates, abs(e_sdr), type = "l", xlab = "", ylab = "|e_t| (%)", main = "SDR")
dev.off()

# ---- Q6 volatility plots ----
gjr_spec <- function(pm, qm) {
  ugarchspec(
    variance.model     = list(model = "gjrGARCH", garchOrder = c(1, 1)),
    mean.model         = list(armaOrder = c(pm, qm), include.mean = TRUE),
    distribution.model = "std")
}
fit_cny <- ugarchfit(gjr_spec(0, 0), data = e_cny, solver = "hybrid")
fit_usd <- ugarchfit(gjr_spec(0, 0), data = e_usd, solver = "hybrid")
fit_twi <- ugarchfit(gjr_spec(1, 0), data = e_twi, solver = "hybrid")
fit_sdr <- ugarchfit(gjr_spec(0, 1), data = e_sdr, solver = "hybrid")

save_vol <- function(fit, dates, label) {
  fname <- paste0("fig6_vol_", label, ".png")
  png(fname, width = 1500, height = 500, res = 150)
  sig <- as.numeric(sigma(fit))
  plot(dates, sig, type = "l", xlab = "", ylab = "sigma_t (%)",
       main = paste("Conditional volatility -", label))
  dev.off()
}
save_vol(fit_cny, dates, "CNY")
save_vol(fit_usd, dates, "USD")
save_vol(fit_twi, dates, "TWI")
save_vol(fit_sdr, dates, "SDR")

cat("All figures saved.\n")
