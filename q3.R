rm(list = ls())
library(readxl)
library(forecast)

setwd("/Users/michael/Downloads/ECON3350")

df <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df)[1:5] <- c("date", "p", "r", "y", "c")
df$date <- as.Date(df$date)
df <- df[1:260, ]

df$pt  <- log(df$p)
df$dpt <- c(NA, diff(df$pt))

dpt <- ts(na.omit(df$dpt), start = c(1959, 2), frequency = 4)

# refit the 3 best models from Q2
m_21 <- Arima(dpt, order = c(2, 0, 1))
m_12 <- Arima(dpt, order = c(1, 0, 2))
m_30 <- Arima(dpt, order = c(3, 0, 0))

fc1 <- forecast(m_21, h = 8, level = c(80, 95))
fc2 <- forecast(m_12, h = 8, level = c(80, 95))
fc3 <- forecast(m_30, h = 8, level = c(80, 95))

# actual P_t values from the Q3 table (2024Q1 to 2025Q3)
actual_P <- c(14.663, 14.785, 14.898, 14.993, 15.100, 15.196, 15.294)

# need P_2023Q4 from our dataset to compute log-difference
P_last   <- df$p[260]
P_last

all_P      <- c(P_last, actual_P)
actual_dpt <- diff(log(all_P))
actual_dpt

# point forecasts for the first 7 quarters
pf1 <- as.numeric(fc1$mean)[1:7]
pf2 <- as.numeric(fc2$mean)[1:7]
pf3 <- as.numeric(fc3$mean)[1:7]

# forecast evaluation metrics
MSFE <- function(actual, pred) mean((actual - pred)^2)
MAE  <- function(actual, pred) mean(abs(actual - pred))

MSFE(actual_dpt, pf1); MSFE(actual_dpt, pf2); MSFE(actual_dpt, pf3)
MAE(actual_dpt,  pf1); MAE(actual_dpt,  pf2); MAE(actual_dpt,  pf3)

# quarter by quarter comparison
data.frame(
  quarter = c("2024Q1", "2024Q2", "2024Q3", "2024Q4", "2025Q1", "2025Q2", "2025Q3"),
  actual  = round(actual_dpt, 5),
  ARMA21  = round(pf1, 5),
  ARMA12  = round(pf2, 5),
  ARMA30  = round(pf3, 5))

# check if actuals fall inside 95% CI of best model
lo95 <- as.numeric(fc1$lower[1:7, 2])
hi95 <- as.numeric(fc1$upper[1:7, 2])
actual_dpt >= lo95 & actual_dpt <= hi95
