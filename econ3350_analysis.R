# ============================================================
# ECON3350 Research Report – Complete Analysis
# ============================================================

suppressPackageStartupMessages({
  library(readxl)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(forecast)
  library(tseries)
  library(rugarch)
  library(FinTS)
})

setwd("/Users/michael/Downloads/ECON3350")
cat("Working directory:", getwd(), "\n\n")

# ============================================================
# LOAD DATA
# ============================================================

df_raw <- read_excel("MacroData (1).xlsx", sheet = "data")
names(df_raw)[1:5] <- c("date","p","r","y","c")
df_raw$date <- as.Date(df_raw$date)

# Estimation sample: 1959Q1–2023Q4 (260 observations)
df <- df_raw[1:260, ]
cat("=== MACRODATA: first/last rows ===\n")
print(head(df, 3)); print(tail(df, 3)); cat("\n")

# Compute log levels
df$p_t <- log(df$p)
df$y_t <- log(df$y)
df$c_t <- log(df$c)
df$trend <- 1:nrow(df)

# Compute log differences
df$dp <- c(NA, diff(df$p_t))
df$dy <- c(NA, diff(df$y_t))
df$dc <- c(NA, diff(df$c_t))

# ============================================================
# QUESTION 1
# ============================================================
cat("============================================================\n")
cat("QUESTION 1\n")
cat("============================================================\n\n")

# --- 1(a) Figure 1: log levels ---
fig1_data <- df %>%
  select(date, p_t, y_t, c_t) %>%
  pivot_longer(-date, names_to = "series", values_to = "value") %>%
  mutate(series = recode(series,
    p_t = "p[t]==log(P[t])",
    y_t = "y[t]==log(Y[t])",
    c_t = "c[t]==log(C[t])"))

fig1 <- ggplot(fig1_data, aes(x = date, y = value, color = series, linetype = series)) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = c("steelblue","firebrick","darkgreen"),
    labels = c(expression(p[t]==log(P[t])), expression(y[t]==log(Y[t])),
               expression(c[t]==log(C[t])))) +
  scale_linetype_manual(values = c("solid","dashed","dotted"),
    labels = c(expression(p[t]==log(P[t])), expression(y[t]==log(Y[t])),
               expression(c[t]==log(C[t])))) +
  labs(title = "Log Levels of US Macroeconomic Series (1959Q1–2023Q4)",
       x = "Date", y = "Log Level",
       color = "Series", linetype = "Series") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("fig1_log_levels.png", fig1, width = 10, height = 5, dpi = 150)
cat("Saved: fig1_log_levels.png\n")

# --- 1(a) Figure 2: log differences + r_t ---
fig2_data <- df %>%
  select(date, dp, dy, dc, r) %>%
  rename(`Delta*p[t]` = dp, `Delta*y[t]` = dy, `Delta*c[t]` = dc, `r[t]` = r) %>%
  pivot_longer(-date, names_to = "series", values_to = "value")

fig2 <- ggplot(fig2_data, aes(x = date, y = value, color = series, linetype = series)) +
  geom_line(linewidth = 0.5) +
  labs(title = "Log Differences and Interest Rate (1959Q1–2023Q4)",
       x = "Date", y = "Value",
       color = "Series", linetype = "Series") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("fig2_log_diffs.png", fig2, width = 10, height = 5, dpi = 150)
cat("Saved: fig2_log_diffs.png\n\n")

# --- 1(b)(i) Trend regressions ---
cat("--- 1(b)(i) Trend regressions ---\n")
lm_p <- lm(p_t ~ trend, data = df)
lm_y <- lm(y_t ~ trend, data = df)
lm_c <- lm(c_t ~ trend, data = df)

for (nm in c("p_t","y_t","c_t")) {
  mod <- get(paste0("lm_", substring(nm, 1, 1)))
  cf  <- coef(summary(mod))
  cat(sprintf("%-4s: mu=%.6f (SE=%.6f), delta=%.6f (SE=%.6f), R2=%.4f\n",
    nm, cf[1,1], cf[1,2], cf[2,1], cf[2,2], summary(mod)$r.squared))
}

# --- 1(b)(ii) Means of differences ---
cat("\n--- 1(b)(ii) Means of differences ---\n")
mean_dp <- mean(df$dp, na.rm = TRUE)
mean_dy <- mean(df$dy, na.rm = TRUE)
mean_dc <- mean(df$dc, na.rm = TRUE)
cat(sprintf("Mean Δp_t = %.6f\n", mean_dp))
cat(sprintf("Mean Δy_t = %.6f\n", mean_dy))
cat(sprintf("Mean Δc_t = %.6f\n", mean_dc))

cat("\n--- 1(b)(iii) Compare delta_hat to mu_hat ---\n")
cat(sprintf("p_t: delta_hat=%.6f  mu_hat(Δp)=%.6f  diff=%.2e\n",
  coef(lm_p)[2], mean_dp, abs(coef(lm_p)[2] - mean_dp)))
cat(sprintf("y_t: delta_hat=%.6f  mu_hat(Δy)=%.6f  diff=%.2e\n",
  coef(lm_y)[2], mean_dy, abs(coef(lm_y)[2] - mean_dy)))
cat(sprintf("c_t: delta_hat=%.6f  mu_hat(Δc)=%.6f  diff=%.2e\n",
  coef(lm_c)[2], mean_dc, abs(coef(lm_c)[2] - mean_dc)))

# ============================================================
# QUESTION 2
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 2\n")
cat("============================================================\n\n")

dp_ts <- ts(na.omit(df$dp), start = c(1959, 2), frequency = 4)
r_ts  <- ts(df$r,            start = c(1959, 1), frequency = 4)

# Unit root tests
cat("--- Unit root tests ---\n")
adf_dp  <- adf.test(dp_ts)
kpss_dp <- kpss.test(dp_ts, null = "Level")
cat(sprintf("Δp_t: ADF p=%.4f, KPSS stat=%.4f (crit 5%%=0.463)\n",
  adf_dp$p.value, kpss_dp$statistic))

adf_r  <- adf.test(r_ts)
kpss_r <- kpss.test(r_ts, null = "Level")
cat(sprintf("r_t:  ADF p=%.4f, KPSS stat=%.4f (crit 5%%=0.463)\n",
  adf_r$p.value, kpss_r$statistic))

# ACF/PACF plots (save to file)
png("fig2_acf_dp.png", width = 800, height = 400)
par(mfrow = c(1, 2))
acf(dp_ts,  lag.max = 20, main = "ACF of Δp_t")
pacf(dp_ts, lag.max = 20, main = "PACF of Δp_t")
dev.off()

png("fig2_acf_r.png", width = 800, height = 400)
par(mfrow = c(1, 2))
acf(r_ts,  lag.max = 20, main = "ACF of r_t")
pacf(r_ts, lag.max = 20, main = "PACF of r_t")
dev.off()
cat("Saved: ACF/PACF plots\n")

# auto.arima suggestions
cat("\n--- auto.arima suggestions ---\n")
auto_dp <- auto.arima(dp_ts, ic = "aic", stepwise = FALSE, approximation = FALSE)
auto_r  <- auto.arima(r_ts,  ic = "aic", stepwise = FALSE, approximation = FALSE)
cat("Δp_t: auto.arima suggests ARIMA(", paste(auto_dp$arma[c(1,6,2)], collapse=","), ")\n")
cat("r_t:  auto.arima suggests ARIMA(", paste(auto_r$arma[c(1,6,2)],  collapse=","), ")\n")
cat("Δp_t AIC:", AIC(auto_dp), " BIC:", BIC(auto_dp), "\n")
cat("r_t  AIC:", AIC(auto_r),  " BIC:", BIC(auto_r),  "\n")

# Fit candidate models for Δp_t (d=0 since Δp_t already differenced)
cat("\n--- Candidate ARIMA models for Δp_t ---\n")
orders_dp <- list(
  c(1,0,0), c(2,0,0), c(3,0,0),
  c(0,0,1), c(1,0,1), c(2,0,1),
  c(0,0,2), c(1,0,2))

fits_dp <- lapply(orders_dp, function(o) {
  tryCatch(Arima(dp_ts, order = o, include.mean = TRUE), error = function(e) NULL)
})
names(fits_dp) <- sapply(orders_dp, function(o) sprintf("ARMA(%d,%d)",o[1],o[3]))

aic_bic_dp <- sapply(fits_dp[!sapply(fits_dp, is.null)], function(f) c(AIC=AIC(f), BIC=BIC(f)))
aic_bic_dp <- aic_bic_dp[, order(aic_bic_dp["AIC", ])]
print(round(t(aic_bic_dp), 2))

# Best 3 by AIC
top3_dp_names <- colnames(aic_bic_dp)[1:3]
cat("\nTop 3 models for Δp_t:", paste(top3_dp_names, collapse=", "), "\n")

m1_dp <- fits_dp[[top3_dp_names[1]]]
m2_dp <- fits_dp[[top3_dp_names[2]]]
m3_dp <- fits_dp[[top3_dp_names[3]]]

cat("\nModel 1:", top3_dp_names[1], "\n")
print(summary(m1_dp))
cat("\nModel 2:", top3_dp_names[2], "\n")
print(summary(m2_dp))
cat("\nModel 3:", top3_dp_names[3], "\n")
print(summary(m3_dp))

# Candidate models for r_t
cat("\n--- Candidate ARIMA models for r_t ---\n")
# Determine d for r_t
d_r <- if (adf_r$p.value > 0.05) 1 else 0
cat("Using d =", d_r, "for r_t\n")

orders_r <- list(
  c(1,d_r,0), c(2,d_r,0), c(1,d_r,1),
  c(2,d_r,1), c(0,d_r,1), c(3,d_r,0))

fits_r <- lapply(orders_r, function(o) {
  tryCatch(Arima(r_ts, order = o, include.mean = TRUE), error = function(e) NULL)
})
names(fits_r) <- sapply(orders_r, function(o) sprintf("ARIMA(%d,%d,%d)",o[1],o[2],o[3]))

aic_bic_r <- sapply(fits_r[!sapply(fits_r, is.null)], function(f) c(AIC=AIC(f), BIC=BIC(f)))
aic_bic_r <- aic_bic_r[, order(aic_bic_r["AIC", ])]
print(round(t(aic_bic_r), 2))

top3_r_names <- colnames(aic_bic_r)[1:3]
cat("Top 3 models for r_t:", paste(top3_r_names, collapse=", "), "\n")

# Forecast Δp_t — 8 quarters ahead (2024Q1–2025Q4)
fc1 <- forecast(m1_dp, h = 8, level = c(80, 95))
fc2 <- forecast(m2_dp, h = 8, level = c(80, 95))
fc3 <- forecast(m3_dp, h = 8, level = c(80, 95))

cat("\n--- Forecasts for Δp_t (2024Q1–2025Q4) ---\n")
fc_labels <- paste0(rep(2024:2025, each=4), "Q", 1:4)
fc_out <- data.frame(
  Quarter = fc_labels,
  M1_mean = round(as.numeric(fc1$mean), 5),
  M1_lo95 = round(as.numeric(fc1$lower[,2]), 5),
  M1_hi95 = round(as.numeric(fc1$upper[,2]), 5),
  M2_mean = round(as.numeric(fc2$mean), 5),
  M3_mean = round(as.numeric(fc3$mean), 5))
print(fc_out)

# 2(a) Forecast plot
recent_dp <- df %>% filter(!is.na(dp)) %>% tail(20)
fc_dates <- seq(as.Date("2024-01-01"), by = "3 months", length.out = 8)

fc_df <- data.frame(
  date    = fc_dates,
  M1_mean = as.numeric(fc1$mean),
  M1_lo80 = as.numeric(fc1$lower[,1]), M1_hi80 = as.numeric(fc1$upper[,1]),
  M1_lo95 = as.numeric(fc1$lower[,2]), M1_hi95 = as.numeric(fc1$upper[,2]),
  M2_mean = as.numeric(fc2$mean),
  M3_mean = as.numeric(fc3$mean))

fig2a <- ggplot() +
  geom_line(data = recent_dp, aes(x = date, y = dp), color = "black", linewidth = 0.7) +
  geom_ribbon(data = fc_df, aes(x = date, ymin = M1_lo95, ymax = M1_hi95),
              fill = "steelblue", alpha = 0.15) +
  geom_ribbon(data = fc_df, aes(x = date, ymin = M1_lo80, ymax = M1_hi80),
              fill = "steelblue", alpha = 0.25) +
  geom_line(data = fc_df, aes(x = date, y = M1_mean, color = "Model 1"), linewidth = 0.8) +
  geom_line(data = fc_df, aes(x = date, y = M2_mean, color = "Model 2"),
            linetype = "dashed", linewidth = 0.8) +
  geom_line(data = fc_df, aes(x = date, y = M3_mean, color = "Model 3"),
            linetype = "dotted", linewidth = 0.8) +
  scale_color_manual(values = c("Model 1"="steelblue","Model 2"="firebrick","Model 3"="darkgreen")) +
  geom_vline(xintercept = as.Date("2024-01-01"), linetype = "dashed", color = "gray50") +
  labs(title = "Inflation (Δp_t) Forecasts for 2024Q1–2025Q4",
       subtitle = "Black = historical; shaded bands = 80%/95% CI for Model 1",
       x = "Date", y = "Δp_t (log difference)", color = "Forecast") +
  theme_bw(base_size = 11) + theme(legend.position = "bottom")

ggsave("fig2a_forecast.png", fig2a, width = 10, height = 5, dpi = 150)
cat("Saved: fig2a_forecast.png\n")

# Print CI width to quantify uncertainty
cat("\nCI width for Model 1 at h=1 (95%):",
  round(as.numeric(fc1$upper[1,2]) - as.numeric(fc1$lower[1,2]), 5), "\n")
cat("CI width for Model 1 at h=8 (95%):",
  round(as.numeric(fc1$upper[8,2]) - as.numeric(fc1$lower[8,2]), 5), "\n")

# ============================================================
# QUESTION 3
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 3\n")
cat("============================================================\n\n")

actual_P  <- c(14.663, 14.785, 14.898, 14.993, 15.100, 15.196, 15.294)
P_last    <- df$p[260]
all_P     <- c(P_last, actual_P)
actual_dp_eval <- diff(log(all_P))

cat("P_{2023Q4} from dataset:", round(P_last, 4), "\n")
cat("Actual Δp_t (2024Q1–2025Q3):", round(actual_dp_eval, 5), "\n\n")

# Point forecasts (first 7)
pf1 <- as.numeric(fc1$mean)[1:7]
pf2 <- as.numeric(fc2$mean)[1:7]
pf3 <- as.numeric(fc3$mean)[1:7]

MSFE <- function(a, p) mean((a - p)^2)
MAE  <- function(a, p) mean(abs(a - p))

eval_table <- data.frame(
  Model    = c(top3_dp_names[1], top3_dp_names[2], top3_dp_names[3]),
  MSFE     = round(c(MSFE(actual_dp_eval,pf1), MSFE(actual_dp_eval,pf2), MSFE(actual_dp_eval,pf3)), 8),
  RMSFE    = round(sqrt(c(MSFE(actual_dp_eval,pf1),MSFE(actual_dp_eval,pf2),MSFE(actual_dp_eval,pf3))),6),
  MAE      = round(c(MAE(actual_dp_eval,pf1),  MAE(actual_dp_eval,pf2),  MAE(actual_dp_eval,pf3)), 6))
print(eval_table)

# Show actual vs forecasts quarter by quarter
q3_comp <- data.frame(
  Quarter  = paste0(c(rep(2024,4),rep(2025,3)), "Q", c(1:4,1:3)),
  Actual   = round(actual_dp_eval, 5),
  Model1   = round(pf1, 5),
  Model2   = round(pf2, 5),
  Model3   = round(pf3, 5))
print(q3_comp)

# Coverage: are actuals inside 95% CI of Model 1?
ci_lo95 <- as.numeric(fc1$lower[1:7, 2])
ci_hi95 <- as.numeric(fc1$upper[1:7, 2])
in_ci   <- actual_dp_eval >= ci_lo95 & actual_dp_eval <= ci_hi95
cat("Actuals inside 95% CI of Model 1:", sum(in_ci), "/", 7, "\n")

# ============================================================
# QUESTION 4
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 4\n")
cat("============================================================\n\n")

df$rr <- df$r - df$dp          # real interest rate (dp has NA at row 1)
df$cy <- df$c / df$y            # consumption ratio

cat("Real rate summary:\n"); print(summary(df$rr))
cat("Consumption ratio summary:\n"); print(summary(df$cy))

# 4(a) Plot rr_t
fig4a <- ggplot(df[!is.na(df$rr), ], aes(x = date, y = rr)) +
  geom_line(color = "darkred", linewidth = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_hline(yintercept = mean(df$rr, na.rm = TRUE), linetype = "dotted", color = "blue") +
  annotate("text", x = as.Date("2010-01-01"), y = mean(df$rr, na.rm=TRUE) + 0.5,
           label = paste0("Mean = ", round(mean(df$rr, na.rm=TRUE), 2), "%"),
           color = "blue", size = 3) +
  labs(title = "Real Interest Rate rr_t = r_t - Δp_t (1959Q2–2023Q4)",
       x = "Date", y = "Real Interest Rate (%)") +
  theme_bw(base_size = 11)
ggsave("fig4a_real_rate.png", fig4a, width = 10, height = 4, dpi = 150)
cat("Saved: fig4a_real_rate.png\n")

# 4(b) Plot cy_t
fig4b <- ggplot(df, aes(x = date, y = cy)) +
  geom_line(color = "darkblue", linewidth = 0.6) +
  labs(title = "Consumption Ratio cy_t = C_t / Y_t (1959Q1–2023Q4)",
       x = "Date", y = expression(C[t] / Y[t])) +
  theme_bw(base_size = 11)
ggsave("fig4b_consumption_ratio.png", fig4b, width = 10, height = 4, dpi = 150)
cat("Saved: fig4b_consumption_ratio.png\n")

# 4(c) ARIMA for rr_t
rr_ts <- ts(na.omit(df$rr), start = c(1959, 2), frequency = 4)
cat("\n--- Unit root tests for rr_t ---\n")
adf_rr  <- adf.test(rr_ts)
kpss_rr <- kpss.test(rr_ts, null = "Level")
cat(sprintf("ADF p=%.4f, KPSS stat=%.4f\n", adf_rr$p.value, kpss_rr$statistic))

auto_rr <- auto.arima(rr_ts, ic = "aic", stepwise = FALSE, approximation = FALSE)
cat("\nBest ARIMA for rr_t:\n"); print(summary(auto_rr))

# Also check BIC best
auto_rr_bic <- auto.arima(rr_ts, ic = "bic", stepwise = FALSE, approximation = FALSE)
cat("\nBIC-selected ARIMA for rr_t:\n")
cat("ARIMA(", paste(auto_rr_bic$arma[c(1,6,2)], collapse=","), ")",
    "AIC:", AIC(auto_rr_bic), "BIC:", BIC(auto_rr_bic), "\n")

# 4(d) ARIMA for cy_t
cy_ts <- ts(df$cy, start = c(1959, 1), frequency = 4)
cat("\n--- Unit root tests for cy_t ---\n")
adf_cy  <- adf.test(cy_ts)
kpss_cy <- kpss.test(cy_ts, null = "Level")
cat(sprintf("ADF p=%.4f, KPSS stat=%.4f\n", adf_cy$p.value, kpss_cy$statistic))

auto_cy <- auto.arima(cy_ts, ic = "aic", stepwise = FALSE, approximation = FALSE)
cat("\nBest ARIMA for cy_t:\n"); print(summary(auto_cy))

auto_cy_bic <- auto.arima(cy_ts, ic = "bic", stepwise = FALSE, approximation = FALSE)
cat("\nBIC-selected ARIMA for cy_t:\n")
cat("ARIMA(", paste(auto_cy_bic$arma[c(1,6,2)], collapse=","), ")",
    "AIC:", AIC(auto_cy_bic), "BIC:", BIC(auto_cy_bic), "\n")

# ============================================================
# QUESTION 5
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 5\n")
cat("============================================================\n\n")

ex_raw <- read_excel("EXRATE (1).xlsx", sheet = "All")
ex <- ex_raw[, 1:5]
names(ex) <- c("Date","CNY","USD","TWI","SDR")
ex$Date <- as.Date(ex$Date)

# 2016 observations → 2015 returns
e_cny <- 100 * diff(log(ex$CNY))
e_usd <- 100 * diff(log(ex$USD))
e_twi <- 100 * diff(log(ex$TWI))
e_sdr <- 100 * diff(log(ex$SDR))
ex_dates <- ex$Date[-1]

cat("Return series lengths:", length(e_cny), "\n")
cat("Date range:", format(min(ex_dates)), "to", format(max(ex_dates)), "\n\n")

# 5(a) Sample variances
var_cny <- var(e_cny); var_usd <- var(e_usd)
var_twi <- var(e_twi); var_sdr <- var(e_sdr)

var_table <- data.frame(
  Currency  = c("CNY","USD","TWI","SDR"),
  Variance  = round(c(var_cny, var_usd, var_twi, var_sdr), 6),
  Std_Dev   = round(sqrt(c(var_cny, var_usd, var_twi, var_sdr)), 4))
cat("--- Sample variances ---\n")
print(var_table)

# Descriptive stats
cat("\n--- Return descriptive statistics ---\n")
desc <- data.frame(
  Currency = c("CNY","USD","TWI","SDR"),
  Mean   = round(c(mean(e_cny),mean(e_usd),mean(e_twi),mean(e_sdr)), 5),
  SD     = round(c(sd(e_cny),sd(e_usd),sd(e_twi),sd(e_sdr)), 4),
  Min    = round(c(min(e_cny),min(e_usd),min(e_twi),min(e_sdr)), 4),
  Max    = round(c(max(e_cny),max(e_usd),max(e_twi),max(e_sdr)), 4))
print(desc)

# 5(b) Plot |e_j,t|
abs_df <- data.frame(Date = ex_dates,
  CNY = abs(e_cny), USD = abs(e_usd),
  TWI = abs(e_twi), SDR = abs(e_sdr)) %>%
  pivot_longer(-Date, names_to = "Currency", values_to = "AbsReturn")

fig5b <- ggplot(abs_df, aes(x = Date, y = AbsReturn)) +
  geom_line(color = "steelblue", linewidth = 0.3) +
  facet_wrap(~ Currency, ncol = 2, scales = "free_y") +
  labs(title = "Absolute Daily Returns |e_{j,t}| by Currency (Jan 2018–Jan 2026)",
       x = "Date", y = "|Return| (%)") +
  theme_bw(base_size = 10)
ggsave("fig5b_abs_returns.png", fig5b, width = 10, height = 7, dpi = 150)
cat("Saved: fig5b_abs_returns.png\n")

# ============================================================
# QUESTION 6
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 6\n")
cat("============================================================\n\n")

fit_garch_best <- function(returns, dates, label) {
  cat("\n====", label, "====\n")

  # Step 1: Test for serial correlation in mean
  lb_ret <- Box.test(returns, lag = 10, type = "Ljung-Box")
  cat("Ljung-Box on returns (lag 10): p-value =", round(lb_ret$p.value, 4), "\n")

  # Step 2: Test for ARCH effects
  arch_test <- ArchTest(returns, lags = 10)
  cat("ARCH LM test (lag 10): p-value =", round(arch_test$p.value, 4), "\n")
  lb_sq <- Box.test(returns^2, lag = 10, type = "Ljung-Box")
  cat("Ljung-Box on returns^2 (lag 10): p-value =", round(lb_sq$p.value, 4), "\n")

  # Determine mean order from ACF/PACF
  acf_ret  <- acf(returns,  lag.max = 10, plot = FALSE)
  pacf_ret <- pacf(returns, lag.max = 10, plot = FALSE)
  sig_lags_acf  <- which(abs(acf_ret$acf[-1])  > 1.96/sqrt(length(returns)))
  sig_lags_pacf <- which(abs(pacf_ret$acf)      > 1.96/sqrt(length(returns)))
  cat("Significant ACF lags:", if(length(sig_lags_acf)==0) "none" else sig_lags_acf, "\n")
  cat("Significant PACF lags:", if(length(sig_lags_pacf)==0) "none" else sig_lags_pacf, "\n")

  # Step 3: Grid search over ARMA orders × distributions
  mean_orders <- list(c(0,0), c(1,0), c(0,1), c(1,1))
  dists       <- c("norm", "std")
  garch_orders <- list(c(1,1))  # GARCH(1,1) is standard

  results <- list()
  for (mo in mean_orders) {
    for (dist in dists) {
      for (go in garch_orders) {
        tag <- sprintf("ARMA(%d,%d)-GARCH(%d,%d)-%s", mo[1], mo[2], go[1], go[2], dist)
        spec <- ugarchspec(
          variance.model   = list(model = "sGARCH", garchOrder = go),
          mean.model       = list(armaOrder = mo, include.mean = TRUE),
          distribution.model = dist)
        fit <- tryCatch(
          ugarchfit(spec, data = returns, solver = "hybrid"),
          error = function(e) NULL)
        if (!is.null(fit) && fit@fit$convergence == 0) {
          ic  <- infocriteria(fit)
          results[[tag]] <- list(fit = fit, AIC = ic[1], BIC = ic[2])
        }
      }
    }
  }

  if (length(results) == 0) {
    cat("No converged models!\n")
    return(NULL)
  }

  ic_df <- data.frame(
    Model = names(results),
    AIC   = sapply(results, `[[`, "AIC"),
    BIC   = sapply(results, `[[`, "BIC"))
  ic_df <- ic_df[order(ic_df$AIC), ]
  cat("\nModel comparison (by AIC):\n")
  print(ic_df)

  best_name <- ic_df$Model[1]
  best_fit  <- results[[best_name]]$fit
  cat("\nBest model:", best_name, "\n")
  cat("Coefficients:\n")
  print(round(coef(best_fit), 6))

  # Diagnostics on best fit
  z   <- residuals(best_fit, standardize = TRUE)
  lb_z  <- Box.test(as.numeric(z),   lag = 10, type = "Ljung-Box")
  lb_z2 <- Box.test(as.numeric(z)^2, lag = 10, type = "Ljung-Box")
  cat(sprintf("LB on z (lag 10): p=%.4f | LB on z^2 (lag 10): p=%.4f\n",
    lb_z$p.value, lb_z2$p.value))

  # Plot conditional volatility
  sig_t  <- as.numeric(sigma(best_fit))
  vol_df <- data.frame(Date = dates, sigma = sig_t)
  pfig <- ggplot(vol_df, aes(x = Date, y = sigma)) +
    geom_line(color = "firebrick", linewidth = 0.4) +
    labs(title = paste("Conditional Volatility σ_t –", label),
         subtitle = best_name,
         x = "Date", y = "σ_t (%)") +
    theme_bw(base_size = 10)
  ggsave(paste0("fig6_vol_", label, ".png"), pfig, width = 10, height = 4, dpi = 150)
  cat("Saved: fig6_vol_", label, ".png\n", sep="")

  return(list(fit = best_fit, name = best_name, returns = returns))
}

res_cny <- fit_garch_best(e_cny, ex_dates, "CNY")
res_usd <- fit_garch_best(e_usd, ex_dates, "USD")
res_twi <- fit_garch_best(e_twi, ex_dates, "TWI")
res_sdr <- fit_garch_best(e_sdr, ex_dates, "SDR")

# ============================================================
# QUESTION 7
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 7\n")
cat("============================================================\n\n")

uncond_var_garch <- function(res, label, var_sample) {
  fit <- res$fit
  cf  <- coef(fit)
  # GARCH(1,1): omega, alpha1, beta1
  omega <- cf["omega"]
  alpha <- cf["alpha1"]
  beta  <- cf["beta1"]
  ab    <- alpha + beta
  cat(label, ": omega=", round(omega,6), " alpha=", round(alpha,4),
      " beta=", round(beta,4), " alpha+beta=", round(ab,6), "\n", sep="")
  if (ab < 1) {
    v <- omega / (1 - ab)
    cat(label, ": Unconditional variance (model) =", round(v,6),
        " | sample =", round(var_sample, 6), "\n")
    return(data.frame(Currency=label, AlphaBeta=round(ab,4),
      Var_Model=round(v,6), Var_Sample=round(var_sample,6),
      Ratio=round(v/var_sample,4)))
  } else {
    cat(label, ": IGARCH (alpha+beta >= 1) — unconditional variance undefined\n")
    return(data.frame(Currency=label, AlphaBeta=round(ab,4),
      Var_Model=NA, Var_Sample=round(var_sample,6), Ratio=NA))
  }
}

q7_rows <- list(
  uncond_var_garch(res_cny, "CNY", var_cny),
  uncond_var_garch(res_usd, "USD", var_usd),
  uncond_var_garch(res_twi, "TWI", var_twi),
  uncond_var_garch(res_sdr, "SDR", var_sdr))

q7_table <- do.call(rbind, q7_rows)
cat("\n--- Question 7 Summary Table ---\n")
print(q7_table)

# ============================================================
# QUESTION 8
# ============================================================
cat("\n============================================================\n")
cat("QUESTION 8\n")
cat("============================================================\n\n")

# Last date in data = 12/01/2026; forecast 2 steps ahead
# 13/01/2026 = T+1, 14/01/2026 = T+2

prob_below <- function(res, label) {
  fit  <- res$fit
  fc   <- ugarchforecast(fit, n.ahead = 2)
  mu   <- as.numeric(fitted(fc))
  sig  <- as.numeric(sigma(fc))
  dist <- fit@model$modeldesc$distribution
  threshold <- 0.01   # 0.01% return

  cat(label, ": dist =", dist, "\n")
  cat(label, ": mu_T+1 =", round(mu[1],6), " sigma_T+1 =", round(sig[1],6), "\n")
  cat(label, ": mu_T+2 =", round(mu[2],6), " sigma_T+2 =", round(sig[2],6), "\n")

  if (dist == "norm") {
    p13 <- pnorm(threshold, mean = mu[1], sd = sig[1])
    p14 <- pnorm(threshold, mean = mu[2], sd = sig[2])
  } else if (dist == "std") {
    nu  <- as.numeric(coef(fit)["shape"])   # degrees of freedom
    # Standardised t: z = (e - mu) / sig ~ t(nu)
    p13 <- pt((threshold - mu[1]) / sig[1], df = nu)
    p14 <- pt((threshold - mu[2]) / sig[2], df = nu)
  } else {
    p13 <- pnorm(threshold, mean = mu[1], sd = sig[1])
    p14 <- pnorm(threshold, mean = mu[2], sd = sig[2])
  }

  cat(label, ": P(e < 0.01%) on 13/01/2026 =", round(p13, 6), "\n")
  cat(label, ": P(e < 0.01%) on 14/01/2026 =", round(p14, 6), "\n\n")

  return(data.frame(Currency = label,
    mu_T1 = round(mu[1],5), sig_T1 = round(sig[1],5),
    mu_T2 = round(mu[2],5), sig_T2 = round(sig[2],5),
    P_13jan = round(p13, 6), P_14jan = round(p14, 6)))
}

q8_rows <- list(
  prob_below(res_cny, "CNY"),
  prob_below(res_usd, "USD"),
  prob_below(res_twi, "TWI"),
  prob_below(res_sdr, "SDR"))

q8_table <- do.call(rbind, q8_rows)
cat("--- Question 8 Summary Table ---\n")
print(q8_table)

cat("\n\n=== ANALYSIS COMPLETE ===\n")
cat("All figures saved to:", getwd(), "\n")
