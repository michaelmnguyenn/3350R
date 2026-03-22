rm(list = ls())
library(readxl)

setwd(tryCatch(
  dirname(rstudioapi::getActiveDocumentContext()$path),
  error = function(e) getwd()
))

df <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df)[1:5] <- c("date", "p", "r", "y", "c")
df$date <- as.Date(df$date)

# use 1959Q1 to 2023Q4 only
df <- df[1:260, ]

# log levels
df$pt <- log(df$p)
df$yt <- log(df$y)
df$ct <- log(df$c)

# first differences
df$dpt <- c(NA, diff(df$pt))
df$dyt <- c(NA, diff(df$yt))
df$dct <- c(NA, diff(df$ct))

df$trend <- 1:nrow(df)

# Figure 1 - log levels of p, y, c
par(mfrow = c(1, 3))
plot(df$date, df$pt, type = "l", xlab = "", ylab = "log(P)", main = "p_t = log(P_t)")
plot(df$date, df$yt, type = "l", xlab = "", ylab = "log(Y)", main = "y_t = log(Y_t)")
plot(df$date, df$ct, type = "l", xlab = "", ylab = "log(C)", main = "c_t = log(C_t)")
par(mfrow = c(1, 1))

# Figure 2 - first differences and interest rate
par(mfrow = c(2, 2))
plot(df$date[-1], df$dpt[-1], type = "l", xlab = "", ylab = "Delta p_t",
     main = "Inflation rate (Delta p_t)")
plot(df$date[-1], df$dyt[-1], type = "l", xlab = "", ylab = "Delta y_t",
     main = "GDP growth (Delta y_t)")
plot(df$date[-1], df$dct[-1], type = "l", xlab = "", ylab = "Delta c_t",
     main = "Consumption growth (Delta c_t)")
plot(df$date, df$r, type = "l", xlab = "", ylab = "r_t (%)",
     main = "T-bill rate (r_t)")
par(mfrow = c(1, 1))

# 1b(i) - trend regressions on log levels
lm_p <- lm(pt ~ trend, data = df)
lm_y <- lm(yt ~ trend, data = df)
lm_c <- lm(ct ~ trend, data = df)

summary(lm_p)
summary(lm_y)
summary(lm_c)

# 1b(ii) - means of first differences
mean(df$dpt, na.rm = TRUE)
mean(df$dyt, na.rm = TRUE)
mean(df$dct, na.rm = TRUE)

# compare delta hat (trend slope) vs mu hat (mean difference) - should be close
coef(lm_p)["trend"]
coef(lm_y)["trend"]
coef(lm_c)["trend"]
