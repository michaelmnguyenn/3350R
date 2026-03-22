rm(list = ls())
library(readxl)
library(forecast)
library(rugarch)
library(dplyr)

setwd(tryCatch(
  dirname(rstudioapi::getActiveDocumentContext()$path),
  error = function(e) getwd()
))

ex <- read_excel("EXRATE (1).xlsx", sheet = "All")
ex <- ex[, 1:5]
names(ex) <- c("Date", "CNY", "USD", "TWI", "SDR")
ex$Date <- as.Date(ex$Date)

e_cny <- 100 * diff(log(ex$CNY))
e_usd <- 100 * diff(log(ex$USD))
e_twi <- 100 * diff(log(ex$TWI))
e_sdr <- 100 * diff(log(ex$SDR))

dates <- ex$Date[-1]

# plot returns - shows the volatility clustering motivating GARCH
par(mfrow = c(2, 2))
plot(dates, e_cny, type = "l", xlab = "", ylab = "returns (%)", main = "CNY returns")
plot(dates, e_usd, type = "l", xlab = "", ylab = "returns (%)", main = "USD returns")
plot(dates, e_twi, type = "l", xlab = "", ylab = "returns (%)", main = "TWI returns")
plot(dates, e_sdr, type = "l", xlab = "", ylab = "returns (%)", main = "SDR returns")
par(mfrow = c(1, 1))

# helper function to run the full ARMA -> BP test -> ARMA-GARCH grid workflow for one series
fit_garch_series <- function(ret, series_name)
{
  cat("\n\n#", series_name, "\n\n")

  # step 1: ARMA model selection (nested loop, tut03 pattern)
  ARMA_est <- list()
  ic_arma <- matrix(nrow = 4 * 4, ncol = 4)
  colnames(ic_arma) <- c("p", "q", "aic", "bic")
  for (p in 0:3)
  {
    for (q in 0:3)
    {
      i <- p * 4 + q + 1
      ARMA_est[[i]] <- Arima(ret, order = c(p, 0, q))
      ic_arma[i, ] <- c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
    }
  }
  ic_aic_arma <- ic_arma[order(ic_arma[, 3]), ][1:10, ]
  ic_bic_arma <- ic_arma[order(ic_arma[, 4]), ][1:10, ]
  cat("ARMA AIC top 10:\n"); print(ic_aic_arma)
  cat("ARMA BIC top 10:\n"); print(ic_bic_arma)

  # step 2: squared residuals from best ARMA, plot and ACF
  best_aic_idx <- which.min(ic_arma[, 3])
  pm0 <- ic_arma[best_aic_idx, 1]
  qm0 <- ic_arma[best_aic_idx, 2]
  best_arma <- Arima(ret, order = c(pm0, 0, qm0))

  e2 <- resid(best_arma)^2
  plot(dates, e2, type = "l", xlab = "", ylab = "squared residuals",
       main = paste(series_name, "- squared ARMA residuals"))
  Sys.sleep(2)
  acf(e2, lag.max = 10, main = paste(series_name, "- SACF of squared residuals"))
  Sys.sleep(2)

  # step 3: Breusch-Pagan LM test for ARCH effects (tut05 section 5 pattern)
  bptest <- matrix(nrow = 10, ncol = 5)
  colnames(bptest) <- c("p", "q", "j", "LM-stat", "p-value")
  e2_v <- as.vector(e2)
  f <- formula(e2_v ~ 1)
  for (j in 1:10)
  {
    f <- update.formula(f, paste("~ . + lag(e2_v, n =", j, ")"))
    bp_reg <- lm(f)
    LM_j   <- length(e2_v) * summary(bp_reg)$r.squared
    bptest[j, ] <- c(pm0, qm0, j, LM_j, 1 - pchisq(LM_j, df = j))
  }
  cat(series_name, "BP LM test results:\n"); print(bptest)

  # step 4: ARMA-GARCH grid search (tut05 section 6 pattern)
  # use GJR-GARCH with Student-t as the variance model throughout
  # pm, qm in 0:2, ph, qh in 0:2 -> 81 combinations
  AG_est <- list()
  ic_ag  <- matrix(nrow = 3^4, ncol = 6)
  colnames(ic_ag) <- c("pm", "qm", "ph", "qh", "aic", "bic")
  i <- 0
  for (pm in 0:2)
  {
    for (qm in 0:2)
    {
      for (ph in 0:2)
      {
        for (qh in 0:2)
        {
          i <- i + 1
          ic_ag[i, 1:4] <- c(pm, qm, ph, qh)

          if (ph == 0 && qh == 0)
          {
            # constant variance case: use arfimaspec/arfimafit as rugarch recommends
            mod       <- arfimaspec(mean.model = list(armaOrder = c(pm, qm)))
            AG_est[[i]] <- arfimafit(mod, ret)
            ic_ag[i, 5:6] <- infocriteria(AG_est[[i]])[1:2]
          }
          else
          {
            try(silent = TRUE, expr =
            {
              spec      <- ugarchspec(
                variance.model = list(model = "gjrGARCH", garchOrder = c(ph, qh)),
                mean.model     = list(armaOrder = c(pm, qm)),
                distribution.model = "std")
              AG_est[[i]] <- ugarchfit(spec, ret, solver = "hybrid")
              ic_ag[i, 5:6] <- infocriteria(AG_est[[i]])[1:2]
            })
          }
        }
      }
    }
  }

  ic_aic_ag <- ic_ag[order(ic_ag[, 5]), ][1:10, ]
  ic_bic_ag <- ic_ag[order(ic_ag[, 6]), ][1:10, ]
  cat(series_name, "ARMA-GARCH AIC top 10:\n"); print(ic_aic_ag)
  cat(series_name, "ARMA-GARCH BIC top 10:\n"); print(ic_bic_ag)

  # adequate set = intersection of top 10 AIC and top 10 BIC
  ic_int_ag <- intersect(as.data.frame(ic_aic_ag), as.data.frame(ic_bic_ag))
  n_adq     <- min(3, nrow(ic_int_ag))
  adq_ag    <- as.matrix(arrange(as.data.frame(ic_int_ag[1:n_adq, ]), pm, qm, ph, qh))
  cat(series_name, "adequate set:\n"); print(adq_ag)

  adq_idx <- match(data.frame(t(adq_ag[, 1:4])), data.frame(t(ic_ag[, 1:4])))

  # step 5: check standardised residuals for models in adequate set
  nmods <- length(adq_idx)
  for (k in 1:nmods)
  {
    mname <- paste0("ARMA(", adq_ag[k, 1], ",", adq_ag[k, 2],
                    ")-GJR-GARCH(", adq_ag[k, 3], ",", adq_ag[k, 4], ")")
    z <- AG_est[[adq_idx[k]]]@fit$z
    acf(z, lag.max = 10,
        main = paste(series_name, mname, "standardised residuals ACF"))
    Sys.sleep(1)
    acf(z^2, lag.max = 10,
        main = paste(series_name, mname, "standardised residuals^2 ACF"))
    Sys.sleep(1)
  }

  # step 6: volatility plot for best model
  best_ag_idx <- adq_idx[1]
  sig <- as.numeric(sigma(AG_est[[best_ag_idx]]))
  best_name <- paste0("ARMA(", adq_ag[1, 1], ",", adq_ag[1, 2],
                      ")-GJR-GARCH(", adq_ag[1, 3], ",", adq_ag[1, 4], ")")
  plot(dates, sig, type = "l", xlab = "", ylab = "sigma_t (%)",
       main = paste(series_name, best_name, "- conditional volatility"))
  Sys.sleep(2)

  return(list(AG_est = AG_est, ic_ag = ic_ag, adq_ag = adq_ag, adq_idx = adq_idx))
}

# run the full workflow for all four currencies
# each one takes a few minutes because of the 81-model grid
res_cny <- fit_garch_series(e_cny, "CNY")
res_usd <- fit_garch_series(e_usd, "USD")
res_twi <- fit_garch_series(e_twi, "TWI")
res_sdr <- fit_garch_series(e_sdr, "SDR")

# final fitted objects to be used in Q7 and Q8
fit_cny <- res_cny$AG_est[[res_cny$adq_idx[1]]]
fit_usd <- res_usd$AG_est[[res_usd$adq_idx[1]]]
fit_twi <- res_twi$AG_est[[res_twi$adq_idx[1]]]
fit_sdr <- res_sdr$AG_est[[res_sdr$adq_idx[1]]]

# print final model summaries
fit_cny
fit_usd
fit_twi
fit_sdr
