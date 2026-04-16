## Run exemplar Research script 2 logic exactly, using our data file
## Captures all Q5-Q8 outputs without interactive plots

library(readxl)
library(forecast)
library(rugarch)

setwd("/Users/michael/Documents/GitHub/3350R")

# ── Data ─────────────────────────────────────────────────────────────────────
mydata <- read_excel("EXRATE (1).xlsx", sheet = "All")
CNY <- as.matrix(mydata$CNY)
USD <- as.matrix(mydata$USD)
TWI <- as.matrix(mydata$TWI)
SDR <- as.matrix(mydata$SDR)
date <- as.Date(mydata$Date)

rCNY <- 100 * diff(log(CNY))
rUSD <- 100 * diff(log(USD))
rTWI <- 100 * diff(log(TWI))
rSDR <- 100 * diff(log(SDR))

# ── Q5a: Sample variances ─────────────────────────────────────────────────────
cat("\n=== Q5a: Sample variances ===\n")
returns <- cbind(rCNY, rUSD, rTWI, rSDR)
colnames(returns) <- c("CNY", "USD", "TWI", "SDR")
print(round(apply(returns, 2, var), 6))

# ── Q5b/Q6: ARMA model selection (exemplar uses Arima, p/q in 0:3) ───────────
cat("\n=== Q6: ARMA model selection ===\n")
fit_arma <- function(r, name) {
  ic <- matrix(nrow = 4*4, ncol = 4)
  colnames(ic) <- c("p","q","aic","bic")
  est <- list()
  for (p in 0:3) for (q in 0:3) {
    i <- p*4 + q + 1
    est[[i]] <- Arima(r, order = c(p,0,q))
    ic[i,] <- c(p, q, est[[i]]$aic, est[[i]]$bic)
  }
  aic_top <- ic[order(ic[,3]),][1:10,]
  bic_top <- ic[order(ic[,4]),][1:10,]
  int_set <- intersect(as.data.frame(aic_top[,1:2]), as.data.frame(bic_top[,1:2]))
  cat(name, "- AIC/BIC intersection:\n"); print(int_set)
  list(est=est, ic=ic, aic_top=aic_top, bic_top=bic_top)
}
arma_cny <- fit_arma(rCNY, "CNY")
arma_usd <- fit_arma(rUSD, "USD")
arma_twi <- fit_arma(rTWI, "TWI")
arma_sdr <- fit_arma(rSDR, "SDR")

# Exemplar chosen ARMA models (from their comments):
# CNY: ARMA(2,3), USD: AR(1), TWI: ARMA(1,3), SDR: MA(1)
fit_CNY <- Arima(rCNY, order = c(2,0,3))
fit_USD <- Arima(rUSD, order = c(1,0,0))
fit_TWI <- Arima(rTWI, order = c(1,0,3))
fit_SDR <- Arima(rSDR, order = c(0,0,1))

cat("\n=== Q6: Ljung-Box on ARMA residuals ===\n")
for (nm in c("CNY","USD","TWI","SDR")) {
  fit <- get(paste0("fit_",nm))
  lb  <- Box.test(resid(fit), lag=10, type="Ljung-Box")
  cat(nm, "LB p-value:", round(lb$p.value,4), "\n")
}

# ── Q6: ARMA-GARCH selection (pm,qm,ph,qh in 0:2) ────────────────────────────
cat("\n=== Q6: ARMA-GARCH model selection ===\n")

fit_garch_grid <- function(r) {
  est <- list()
  ic  <- matrix(nrow=3^4, ncol=6)
  colnames(ic) <- c("pm","qm","ph","qh","aic","bic")
  i <- 0
  for (pm in 0:2) for (qm in 0:2) for (ph in 0:2) for (qh in 0:2) {
    i <- i + 1
    ic[i,1:4] <- c(pm,qm,ph,qh)
    if (ph==0 && qh==0) {
      spec <- arfimaspec(mean.model=list(armaOrder=c(pm,qm)))
      try(silent=TRUE, {
        est[[i]] <- arfimafit(spec, r)
        ic[i,5:6] <- infocriteria(est[[i]])[1:2]
      })
    } else {
      spec <- ugarchspec(mean.model=list(armaOrder=c(pm,qm)),
                         variance.model=list(garchOrder=c(qh,ph)))  # c(ARCH,GARCH)
      try(silent=TRUE, {
        est[[i]] <- ugarchfit(spec, r, solver="hybrid")
        ic[i,5:6] <- infocriteria(est[[i]])[1:2]
      })
    }
  }
  aic_top <- ic[order(ic[,5]),][1:40,]
  bic_top <- ic[order(ic[,6]),][1:40,]
  int_set <- intersect(as.data.frame(aic_top), as.data.frame(bic_top))
  list(est=est, ic=ic, int=int_set)
}

cat("Fitting CNY grid...\n"); g_cny <- fit_garch_grid(rCNY)
cat("Fitting USD grid...\n"); g_usd <- fit_garch_grid(rUSD)
cat("Fitting TWI grid...\n"); g_twi <- fit_garch_grid(rTWI)
cat("Fitting SDR grid...\n"); g_sdr <- fit_garch_grid(rSDR)

cat("\nCNY intersection (top 10):\n"); print(head(g_cny$int, 10))
cat("\nUSD intersection (top 10):\n"); print(head(g_usd$int, 10))
cat("\nTWI intersection (top 10):\n"); print(head(g_twi$int, 10))
cat("\nSDR intersection (top 10):\n"); print(head(g_sdr$int, 10))

# Exemplar model selections (from hardcoded idx in script):
# CNY: pm=2,qm=2,ph=2,qh=1  -> garchOrder=c(1,2)
# USD: pm=2,qm=2,ph=2,qh=2  -> garchOrder=c(2,2)
# TWI: pm=2,qm=2,ph=2,qh=2  -> garchOrder=c(2,2)
# SDR: pm=2,qm=2,ph=2,qh=1  -> garchOrder=c(1,2)

get_model <- function(grid, pm, qm, ph, qh) {
  ic <- grid$ic
  i  <- which(ic[,1]==pm & ic[,2]==qm & ic[,3]==ph & ic[,4]==qh)
  grid$est[[i]]
}

model_cny <- get_model(g_cny, 2,2,2,1)
model_usd <- get_model(g_usd, 2,2,2,2)
model_twi <- get_model(g_twi, 2,2,2,2)
model_sdr <- get_model(g_sdr, 2,2,2,1)

cat("\n=== Q6: Final model coefficients ===\n")
cat("CNY (ARMA(2,2)-GARCH(2,1)):\n"); print(round(coef(model_cny),6))
cat("USD (ARMA(2,2)-GARCH(2,2)):\n"); print(round(coef(model_usd),6))
cat("TWI (ARMA(2,2)-GARCH(2,2)):\n"); print(round(coef(model_twi),6))
cat("SDR (ARMA(2,2)-GARCH(2,1)):\n"); print(round(coef(model_sdr),6))

# ── Q7: Unconditional variance ────────────────────────────────────────────────
cat("\n=== Q7: Persistence and unconditional variance ===\n")
uncond_var <- function(model, label) {
  cf <- coef(model)
  nms <- names(cf)
  alpha <- cf[grep("^alpha", nms)]
  beta  <- cf[grep("^beta",  nms)]
  omega <- cf["omega"]
  pers  <- sum(alpha) + sum(beta)
  uvar  <- as.numeric(omega) / (1 - pers)
  cat(label, "| Persistence:", round(pers,4),
      "| omega:", round(omega,6),
      "| Unconditional var:", round(uvar,4), "\n")
}
uncond_var(model_cny, "CNY")
uncond_var(model_usd, "USD")
uncond_var(model_twi, "TWI")
uncond_var(model_sdr, "SDR")

cat("\nSample variances for comparison:\n")
print(round(apply(returns, 2, var), 4))

# ── Q8: Forecasts and probabilities ──────────────────────────────────────────
cat("\n=== Q8: Forecasts (ugarchforecast) ===\n")

# Exemplar uses threshold = 0.0001 (their value, which we know is wrong unit)
threshold_ex  <- 0.0001
threshold_fix <- 0.01

forecast_prob <- function(model, label, threshold) {
  fc    <- ugarchforecast(model, n.ahead=2)
  mu    <- as.numeric(fitted(fc))
  sigma <- as.numeric(sigma(fc))
  prob  <- pnorm(threshold, mean=mu, sd=sigma)
  data.frame(Currency=label,
             Day=c("13 Jan","14 Jan"),
             mu=round(mu,4), var=round(sigma^2,4),
             sigma=round(sigma,4), prob=round(prob,4))
}

res_ex <- rbind(
  forecast_prob(model_cny, "CNY", threshold_ex),
  forecast_prob(model_usd, "USD", threshold_ex),
  forecast_prob(model_twi, "TWI", threshold_ex),
  forecast_prob(model_sdr, "SDR", threshold_ex)
)
cat("\nExemplar threshold = 0.0001:\n")
print(res_ex, row.names=FALSE)

res_fix <- rbind(
  forecast_prob(model_cny, "CNY", threshold_fix),
  forecast_prob(model_usd, "USD", threshold_fix),
  forecast_prob(model_twi, "TWI", threshold_fix),
  forecast_prob(model_sdr, "SDR", threshold_fix)
)
cat("\nFixed threshold = 0.01:\n")
print(res_fix, row.names=FALSE)

cat("\n=== Q8: ugarchboot (set.seed(123), n.bootpred=5000) ===\n")
set.seed(123)
boot_results <- lapply(list(CNY=model_cny, USD=model_usd,
                             TWI=model_twi, SDR=model_sdr), function(m) {
  ugarchboot(m, method="Partial", n.bootpred=5000)
})

cat("Bootstrap forecast quantiles (T+1 and T+2 returns):\n")
for (nm in names(boot_results)) {
  b <- boot_results[[nm]]
  # forc slot has simulated paths: rows=n.ahead, cols=n.bootpred
  sims <- b@forc@forecast$seriesSim   # matrix [2 x 5000]
  cat(nm, "\n")
  cat("  T+1: mean=", round(mean(sims[1,]),4),
      " sd=", round(sd(sims[1,]),4),
      " P(<0.01)=", round(mean(sims[1,]<0.01),4), "\n")
  cat("  T+2: mean=", round(mean(sims[2,]),4),
      " sd=", round(sd(sims[2,]),4),
      " P(<0.01)=", round(mean(sims[2,]<0.01),4), "\n")
}
