getwd()
rm(list = ls())
library(forecast)
#Q5
mydata <- read.delim("EXRATE.csv", header = TRUE,  sep = ",")

#finding the 100*diff(log)

CNY <- as.matrix(mydata$CNY)
USD <- as.matrix(mydata$USD)
TWI <- as.matrix(mydata$TWI)
SDR <- as.matrix(mydata$SDR)

date <- as.Date(mydata$Date, format = "%d-%b-%Y")

rCNY <- 100*diff(log(CNY))
rUSD <- 100*diff(log(USD))
rTWI <- 100*diff(log(TWI))
rSDR <- 100*diff(log(SDR))

#by finding the variance, we can maybe assume hetereoscedasticity if we can maybe observe large variations in volatility.
# Combine into a matrix (clean structure)
returns <- cbind(rCNY, rUSD, rTWI, rSDR)

# Rename columns
colnames(returns) <- c("CNY", "USD", "TWI", "SDR")

# Compute sample variances
var_results <- apply(returns, 2, var)

# Print results
print(var_results)
# CNY       USD       TWI       SDR 
#0.3368546 0.4380863 0.2674710 0.4491718

#5b
str(date)
date_r <- date[-1]  # align with diff()

par(mfrow = c(2,2))

plot(date_r, abs(rCNY), type = "l", main = "|rCNY|", xlab = "Time", ylab = "")
plot(date_r, abs(rUSD), type = "l", main = "|rUSD|", xlab = "Time", ylab = "")
plot(date_r, abs(rTWI), type = "l", main = "|rTWI|", xlab = "Time", ylab = "")
plot(date_r, abs(rSDR), type = "l", main = "|rSDR|", xlab = "Time", ylab = "")


#next we assume homoskedasticity and find an ARMA model that is adequate, 

ARMA_est <- list()
ic_arma <- matrix( nrow = 4 * 4, ncol = 4 )
colnames(ic_arma) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_est[[i]] <- Arima(rCNY, order = c(p, 0, q))
    ic_arma[i,] <- c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
  }
}

ic_aic_arma <- ic_arma[order(ic_arma[,3]),][1:10,]

ic_bic_arma <- ic_arma[order(ic_arma[,4]),][1:10,]

# find the intersection of AIC and BIC preferred sets
ic_union_arma <- unique(rbind(
  as.data.frame(ic_aic_arma[, 1:2]),
  as.data.frame(ic_bic_arma[, 1:2])
))

ic_aic_arma
ic_bic_arma

ic_union_arma

ARMA_est <- list()
ic_arma <- matrix( nrow = 4 * 4, ncol = 4 )
colnames(ic_arma) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_est[[i]] <- Arima(rUSD, order = c(p, 0, q))
    ic_arma[i,] <- c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
  }
}

ic_aic_arma <- ic_arma[order(ic_arma[,3]),][1:10,]

ic_bic_arma <- ic_arma[order(ic_arma[,4]),][1:10,]

# find the intersection of AIC and BIC preferred sets
ic_int_arma <- intersect(as.data.frame(ic_aic_arma),
                         as.data.frame(ic_bic_arma))

ic_aic_arma
ic_bic_arma
ic_int_arma

ARMA_est <- list()
ic_arma <- matrix( nrow = 4 * 4, ncol = 4 )
colnames(ic_arma) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_est[[i]] <- Arima(rTWI, order = c(p, 0, q))
    ic_arma[i,] <- c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
  }
}

ic_aic_arma <- ic_arma[order(ic_arma[,3]),][1:10,]

ic_bic_arma <- ic_arma[order(ic_arma[,4]),][1:10,]

# find the intersection of AIC and BIC preferred sets
ic_int_arma <- intersect(as.data.frame(ic_aic_arma),
                         as.data.frame(ic_bic_arma))

ic_aic_arma
ic_bic_arma
ic_int_arma

ARMA_est <- list()
ic_arma <- matrix( nrow = 4 * 4, ncol = 4 )
colnames(ic_arma) <- c("p", "q", "aic", "bic")
for (p in 0:3)
{
  for (q in 0:3)
  {
    i <- p * 4 + q + 1
    ARMA_est[[i]] <- Arima(rSDR, order = c(p, 0, q))
    ic_arma[i,] <- c(p, q, ARMA_est[[i]]$aic, ARMA_est[[i]]$bic)
  }
}

ic_aic_arma <- ic_arma[order(ic_arma[,3]),][1:10,]

ic_bic_arma <- ic_arma[order(ic_arma[,4]),][1:10,]

# find the intersection of AIC and BIC preferred sets
ic_int_arma <- intersect(as.data.frame(ic_aic_arma),
                         as.data.frame(ic_bic_arma))

ic_aic_arma
ic_bic_arma
ic_int_arma

#rCNY first interested -> Arma(1,3) was not adequate
#rUSD AR(1) or ARMA(1,0)
#rTWI ARMA(1,3)
#rSDR MA(1) or ARMA(0,1)

#afterwards, we test the adequacy. 
library(forecast)

# Fit chosen models
fit_CNY <- Arima(rCNY, order = c(2, 0, 3))   # None of the BIC were adequate, however ARMA(2,3) was
fit_USD <- Arima(rUSD, order = c(1, 0, 0))   # AR(1) = ARMA(1,0)
fit_TWI <- Arima(rTWI, order = c(1, 0, 3))   # ARMA(1,3)
fit_SDR <- Arima(rSDR, order = c(0, 0, 1))   # MA(1) = ARMA(0,1)

# Check residuals one by one
checkresiduals(fit_CNY)
checkresiduals(fit_USD)
checkresiduals(fit_TWI)
checkresiduals(fit_SDR)


#to go into GARCH we look for heteroskedascity, where we have to check the squared residual 
#


  library(forecast)
  
  # Fit chosen model for rCNY
  fit_CNY <- Arima(rCNY, order = c(2, 0, 3))   # ARMA(2,3)
  
  # Squared residuals
  e2_CNY <- resid(fit_CNY)^2
  
  # Plot squared residuals
  plot(date[-1], e2_CNY, type = "l",
       xlab = "", ylab = "squared resid",
       main = "Plot: rCNY ARMA(2,3)")
# ACF of squared residuals
  acf(e2_CNY, xlab = "", ylab = "",
      main = "SACF: rCNY ARMA(2,3)")
  
  #--------------------------
  
  
  # Fit chosen model for rUSD
  fit_USD <- Arima(rUSD, order = c(1, 0, 0))   # ARMA(1,3)
  
  # Squared residuals
  e2_USD <- resid(fit_USD)^2
  
  # Plot squared residuals
  plot(date[-1], e2_USD, type = "l",
       xlab = "", ylab = "squared resid",
       main = "Plot: rUSD AR(1)")
  
  # ACF of squared residuals
  acf(e2_USD, xlab = "", ylab = "",
      main = "SACF: rUSD AR(1)")
  
  
  #------------------
  
  # Fit chosen model for rUSD
  fit_TWI <- Arima(rTWI, order = c(1, 0, 3))   # ARMA(1,3)
  
  # Squared residuals
  e2_TWI <- resid(fit_TWI)^2
  
  # Plot squared residuals
  plot(date[-1], e2_TWI, type = "l",
       xlab = "", ylab = "squared resid",
       main = "Plot: rTWI ARMA(1,3)")
  
  # ACF of squared residuals
  acf(e2_TWI, xlab = "", ylab = "",
      main = "SACF: rTWI ARMA(1,3)")
#-----------------------
  
  # Fit chosen model for rUSD
  fit_SDR <- Arima(rSDR, order = c(0, 0, 1))   # MA(1)
  
  # Squared residuals
  e2_SDR <- resid(fit_SDR)^2
  
  # Plot squared residuals
  plot(date[-1], e2_SDR, type = "l",
       xlab = "", ylab = "squared resid",
       main = "Plot: rSDR MA(1)")
  
  # ACF of squared residuals
  acf(e2_SDR, xlab = "", ylab = "",
      main = "SACF: rTWI MA(1)")
#----------
  #lm test and the bp test 
  e2_i <- as.vector(e2_CNY)
  
  bptest_CNY <- matrix(nrow = 10, ncol = 5)
  colnames(bptest_CNY) <- c("p", "q", "j", "LM-stat", "p-value")
  
  for (j in 1:10)
  {
    k <- j
    
    dat <- as.data.frame(embed(e2_i, j + 1))
    colnames(dat) <- c("y", paste0("lag", 1:j))
    
    f <- as.formula(
      paste("y ~", paste(colnames(dat)[-1], collapse = " + "))
    )
    
    bp_reg_j <- lm(f, data = dat)
    LM_j <- nrow(dat) * summary(bp_reg_j)$r.squared
    p_val_j <- format.pval(1 - pchisq(LM_j, df = j), digits = 5)
    
    bptest_CNY[k, ] <- c(2, 3, j, LM_j, p_val_j)
  }
  
  bptest_CNY
  
  #-------
  #USD
  #lm test and the bp test 
  e2_i <- as.vector(e2_USD)
  
  bptest_USD <- matrix(nrow = 10, ncol = 5)
  colnames(bptest_USD) <- c("p", "q", "j", "LM-stat", "p-value")
  
  for (j in 1:10)
  {
    k <- j
    
    dat <- as.data.frame(embed(e2_i, j + 1))
    colnames(dat) <- c("y", paste0("lag", 1:j))
    
    f <- as.formula(
      paste("y ~", paste(colnames(dat)[-1], collapse = " + "))
    )
    
    bp_reg_j <- lm(f, data = dat)
    LM_j <- nrow(dat) * summary(bp_reg_j)$r.squared
    p_val_j <- format.pval(1 - pchisq(LM_j, df = j), digits = 5)
    
    bptest_USD[k, ] <- c(1, 0, j, LM_j, p_val_j)
  }
  
  bptest_USD
  
  #-------
  #TWI
  #lm test and the bp test 
  e2_i <- as.vector(e2_TWI)
  
  bptest_TWI <- matrix(nrow = 10, ncol = 5)
  colnames(bptest_TWI) <- c("p", "q", "j", "LM-stat", "p-value")
  
  for (j in 1:10)
  {
    k <- j
    
    dat <- as.data.frame(embed(e2_i, j + 1))
    colnames(dat) <- c("y", paste0("lag", 1:j))
    
    f <- as.formula(
      paste("y ~", paste(colnames(dat)[-1], collapse = " + "))
    )
    
    bp_reg_j <- lm(f, data = dat)
    LM_j <- nrow(dat) * summary(bp_reg_j)$r.squared
    p_val_j <- format.pval(1 - pchisq(LM_j, df = j), digits = 5)
    
    bptest_TWI[k, ] <- c(1, 3, j, LM_j, p_val_j)
  }
  
  bptest_TWI
  
  #-------
  #SDR
  #lm test and the bp test 
  e2_i <- as.vector(e2_SDR)
  
  bptest_SDR <- matrix(nrow = 10, ncol = 5)
  colnames(bptest_SDR) <- c("p", "q", "j", "LM-stat", "p-value")
  
  for (j in 1:10)
  {
    k <- j
    
    dat <- as.data.frame(embed(e2_i, j + 1))
    colnames(dat) <- c("y", paste0("lag", 1:j))
    
    f <- as.formula(
      paste("y ~", paste(colnames(dat)[-1], collapse = " + "))
    )
    
    bp_reg_j <- lm(f, data = dat)
    LM_j <- nrow(dat) * summary(bp_reg_j)$r.squared
    p_val_j <- format.pval(1 - pchisq(LM_j, df = j), digits = 5)
    
    bptest_SDR[k, ] <- c(0, 1, j, LM_j, p_val_j)
  }
  
  bptest_SDR
  #all rejected the null hypothesis of no archc effect. As a result we conclude heteroskedascity 
  #there is an ARCH effect
  
  #since the tests show very persistent volatility -> GARCH
  library(dplyr)
  library(rugarch)
  r <- rCNY
  
  ARMA_GARCH_est <- list()
  ic_arma_garch <- matrix(nrow = 3^4, ncol = 6)
  colnames(ic_arma_garch) <- c("pm", "qm", "ph", "qh", "aic", "bic")
  
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
          ic_arma_garch[i, 1:4] <- c(pm, qm, ph, qh)
          
          if (ph == 0 && qh == 0)
          {
            ARMA_GARCH_mod <- arfimaspec(
              mean.model = list(armaOrder = c(pm, qm))
            )
            
            ARMA_GARCH_est[[i]] <- arfimafit(ARMA_GARCH_mod, r)
            
            ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
          }
          else
          {
            try(silent = TRUE, expr = {
              ARMA_GARCH_mod <- ugarchspec(
                mean.model = list(armaOrder = c(pm, qm)),
                variance.model = list(garchOrder = c(qh, ph)) #TESTING (ARCH,GARCH)
              )
              
              ARMA_GARCH_est[[i]] <- ugarchfit(
                ARMA_GARCH_mod, r, solver = "hybrid"
              )
              
              ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
            })
          }
        }
      }
    }
  }
  ic_aic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,5]), ][1:40, ]
  ic_bic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,6]), ][1:40, ]
  
  ic_aic_arma_garch
  ic_bic_arma_garch
  ic_int_arma_garch <- intersect(as.data.frame(ic_aic_arma_garch),
                                 as.data.frame(ic_bic_arma_garch))  
  ic_int_arma_garch
  
  
  #     pm qm ph qh      aic      bic
  # 1   2  2  2  1 1.551433 1.576483    ATTENTION!
  # 2   2  2  1  1 1.553662 1.575928    ATTENTION!
  # 3   2  1  2  1 1.560841 1.583108
  # 4   2  2  2  2 1.562093 1.589926
  # 5   2  1  2  2 1.564378 1.589427
  # 6   1  1  2  1 1.564874 1.584357
  # 7   0  0  2  1 1.564976 1.578893
  # 8   2  1  1  1 1.565313 1.584796
  # 9   0  1  2  1 1.565839 1.582539
  # 10  1  0  2  1 1.565844 1.582544
  
  adq_set_arma_garch <- as.matrix(ic_int_arma_garch[,1:4])
  
  # map adequate set back to original 81-model list
  adq_idx_arma_garch <- match(
    data.frame(t(adq_set_arma_garch)),
    data.frame(t(ic_arma_garch[,1:4]))
  )
  
  # select ARMA(2,2)-GARCH(1,2)
  idx_cny <- adq_idx_arma_garch[which(
    adq_set_arma_garch[,1] == 2 &
      adq_set_arma_garch[,2] == 2 &
      adq_set_arma_garch[,3] == 2 &
      adq_set_arma_garch[,4] == 1
  )]
  
  model_cny <- ARMA_GARCH_est[[idx_cny]]
  
  # residuals
  res <- model_cny@fit$z
  sig <- model_cny@fit$sigma
  stdres <- res / sig
  stdres2 <- stdres^2
  
  acf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) ACF")
  pacf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) PACF")
  
  acf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres ACF")
  pacf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres PACF")
  
  acf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres2 ACF")
  pacf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres2 PACF")
  
  #plotting
  
  plot(date[-1],
       model_cny@fit$var,
       type = "l",
       xlab = "",
       ylab = "Estimated volatility",
       main = "CNY: ARMA(2,2)-GARCH(2,1) volatility")
  
  #you will need this for question 7 to find the unconditional variance 
  coef(model_cny)

  #Forecasting
  # we set the seed so the results dont change every time
  set.seed(123)
  boot_cny <- ugarchboot(model_cny, method = "Partial", n.bootpred = 5000
                         )
  plot(boot_cny, which = 2) #this is the simulated forecast of mean 
  plot(boot_cny, which = 3) #this is the forecast of volatility 
  
  # CNY: Forecast + Probability
 
  # Forecast mean and sigma (2 days ahead)
  fc_cny <- ugarchforecast(model_cny, n.ahead = 2)
  
  mu_cny <- as.numeric(fitted(fc_cny))
  sigma_cny <- as.numeric(sigma(fc_cny))
  
  #Create results table
  results_cny <- data.frame(
    Day = c("13/01/2026", "14/01/2026"),
    Mu = mu_cny,
    Sigma = sigma_cny
  )
  
  #Compute probability (return < 0.01%)
  threshold <- 0.0001
  
  results_cny$Probability <- pnorm(
    threshold,
    mean = results_cny$Mu,
    sd = results_cny$Sigma
  )
  
  results_cny
  
  #----------------------------
  #USD
  
  r <- rUSD
  
  ARMA_GARCH_est <- list()
  ic_arma_garch <- matrix(nrow = 3^4, ncol = 6)
  colnames(ic_arma_garch) <- c("pm", "qm", "ph", "qh", "aic", "bic")
  
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
          ic_arma_garch[i, 1:4] <- c(pm, qm, ph, qh)
          
          if (ph == 0 && qh == 0)
          {
            ARMA_GARCH_mod <- arfimaspec(
              mean.model = list(armaOrder = c(pm, qm))
            )
            
            ARMA_GARCH_est[[i]] <- arfimafit(ARMA_GARCH_mod, r)
            
            ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
          }
          else
          {
            try(silent = TRUE, expr = {
              ARMA_GARCH_mod <- ugarchspec(
                mean.model = list(armaOrder = c(pm, qm)),
                variance.model = list(garchOrder = c(qh, ph))
              )
              
              ARMA_GARCH_est[[i]] <- ugarchfit(
                ARMA_GARCH_mod, r, solver = "hybrid"
              )
              
              ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
            })
          }
        }
      }
    }
  }
  ic_aic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,5]), ][1:40, ]
  ic_bic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,6]), ][1:40, ]
  
  ic_aic_arma_garch
  ic_bic_arma_garch
  ic_int_arma_garch <- intersect(as.data.frame(ic_aic_arma_garch),
                                 as.data.frame(ic_bic_arma_garch))  
  ic_int_arma_garch
  #     pm qm ph qh      aic      bic
  # 1   2  2  2  2 1.834596 1.862429
  # 2   0  0  2  1 1.839155 1.853071
  # 3   1  1  2  1 1.839921 1.859405
  # 4   0  1  2  1 1.840079 1.856779
  # 5   1  0  2  1 1.840080 1.856780
  # 6   0  0  2  2 1.840147 1.856847
  # 7   2  1  2  1 1.840809 1.863076
  # 8   1  2  2  1 1.840809 1.863076
  # 9   1  1  2  2 1.840914 1.863180
  # 10  0  2  2  1 1.841059 1.860542
  
  adq_set_arma_garch <- as.matrix(ic_int_arma_garch[,1:4])
  
  # map adequate set back to original 81-model list
  adq_idx_arma_garch <- match(
    data.frame(t(adq_set_arma_garch)),
    data.frame(t(ic_arma_garch[,1:4]))
  )
  
  # select ARMA(2,2)-GARCH(2,2)
  idx_usd <- adq_idx_arma_garch[which(
    adq_set_arma_garch[,1] == 2 &
      adq_set_arma_garch[,2] == 2 &
      adq_set_arma_garch[,3] == 2 &
      adq_set_arma_garch[,4] == 2
  )]
  
  model_usd <- ARMA_GARCH_est[[idx_usd]]
  
  # residuals
  res <- model_usd@fit$z
  sig <- model_usd@fit$sigma
  stdres <- res / sig
  stdres2 <- stdres^2
  
  acf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) ACF")
  pacf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) PACF")
  
  acf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres ACF")
  pacf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres PACF")
  
  acf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres2 ACF")
  pacf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres2 PACF")
  
  plot(date[-1],
       model_usd@fit$var,
       type = "l",
       xlab = "",
       ylab = "Estimated volatility",
       main = "USD: ARMA(2,2)-GARCH(2,2) volatility")
  
  coef(model_usd)
  
  #Forecasting
  # we set the seed so the results dont change every time
  set.seed(123)
  boot_usd <- ugarchboot(model_usd, method = "Partial", n.bootpred = 5000
  )
  plot(boot_usd, which = 2) #this is the simulated forecast of mean 
  plot(boot_usd, which = 3) #this is the forecast of volatility 
  
  # USD: Forecast + Probability
  
  # Forecast mean and sigma (2 days ahead)
  fc_usd <- ugarchforecast(model_usd, n.ahead = 2)
  
  mu_usd <- as.numeric(fitted(fc_usd))
  sigma_usd <- as.numeric(sigma(fc_usd))
  
  #Create results table
  results_usd <- data.frame(
    Day = c("13/01/2026", "14/01/2026"),
    Mu = mu_usd,
    Sigma = sigma_usd
  )
  
  #Compute probability (return < 0.01%)
  threshold <- 0.0001
  
  results_usd$Probability <- pnorm(
    threshold,
    mean = results_usd$Mu,
    sd = results_usd$Sigma
  )
  
  results_usd
  
#------------  
#TWI  
  r <- rTWI
  
  ARMA_GARCH_est <- list()
  ic_arma_garch <- matrix(nrow = 3^4, ncol = 6)
  colnames(ic_arma_garch) <- c("pm", "qm", "ph", "qh", "aic", "bic")
  
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
          ic_arma_garch[i, 1:4] <- c(pm, qm, ph, qh)
          
          if (ph == 0 && qh == 0)
          {
            ARMA_GARCH_mod <- arfimaspec(
              mean.model = list(armaOrder = c(pm, qm))
            )
            
            ARMA_GARCH_est[[i]] <- arfimafit(ARMA_GARCH_mod, r)
            
            ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
          }
          else
          {
            try(silent = TRUE, expr = {
              ARMA_GARCH_mod <- ugarchspec(
                mean.model = list(armaOrder = c(pm, qm)),
                variance.model = list(garchOrder = c(qh, ph))
              )
              
              ARMA_GARCH_est[[i]] <- ugarchfit(
                ARMA_GARCH_mod, r, solver = "hybrid"
              )
              
              ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
            })
          }
        }
      }
    }
  }
  ic_aic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,5]), ][1:40, ]
  ic_bic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,6]), ][1:40, ]
  
  ic_aic_arma_garch
  ic_bic_arma_garch
  ic_int_arma_garch <- intersect(as.data.frame(ic_aic_arma_garch),
                                 as.data.frame(ic_bic_arma_garch))  
  ic_int_arma_garch
  #    pm qm ph qh      aic      bic
  # 1   2  2  2  2 1.310895 1.338729
  # 2   1  1  2  1 1.312119 1.331602
  # 3   2  2  2  1 1.312766 1.337816
  # 4   1  1  2  2 1.313111 1.335378
  # 5   0  1  2  1 1.314018 1.330717
  # 6   1  0  2  1 1.314053 1.330753
  # 7   0  2  2  1 1.314947 1.334430
  # 8   0  1  2  2 1.315010 1.334493
  # 9   2  0  2  1 1.315034 1.334517
  # 10  1  0  2  2 1.315046 1.334529
  
  adq_set_arma_garch <- as.matrix(ic_int_arma_garch[,1:4])
  
  # map adequate set back to original 81-model list
  adq_idx_arma_garch <- match(
    data.frame(t(adq_set_arma_garch)),
    data.frame(t(ic_arma_garch[,1:4]))
  )
  
  # select ARMA(2,2)-GARCH(2,2)
  idx_twi <- adq_idx_arma_garch[which(
    adq_set_arma_garch[,1] == 2 &
      adq_set_arma_garch[,2] == 2 &
      adq_set_arma_garch[,3] == 2 &
      adq_set_arma_garch[,4] == 2
  )]
  
  model_twi <- ARMA_GARCH_est[[idx_twi]]
  
  # residuals
  res <- model_twi@fit$z
  sig <- model_twi@fit$sigma
  stdres <- res / sig
  stdres2 <- stdres^2
  
  acf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) ACF")
  pacf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) PACF")
  
  acf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres ACF")
  pacf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres PACF")
  
  acf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres2 ACF")
  pacf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,2) Stdres2 PACF")
  
  plot(date[-1],
       model_twi@fit$var,
       type = "l",
       xlab = "",
       ylab = "Estimated volatility",
       main = "TWI: ARMA(2,2)-GARCH(2,2) volatility")
  
  coef(model_twi)
  
  #Forecasting
  # we set the seed so the results dont change every time
  set.seed(123)
  boot_twi <- ugarchboot(model_twi, method = "Partial", n.bootpred = 5000
  )
  plot(boot_twi, which = 2) #this is the simulated forecast of mean 
  plot(boot_twi, which = 3) #this is the forecast of volatility 
  
  # USD: Forecast + Probability
  
  # Forecast mean and sigma (2 days ahead)
  fc_twi <- ugarchforecast(model_twi, n.ahead = 2)
  
  mu_twi <- as.numeric(fitted(fc_twi))
  sigma_twi <- as.numeric(sigma(fc_twi))
  
  #Create results table
  results_twi <- data.frame(
    Day = c("13/01/2026", "14/01/2026"),
    Mu = mu_twi,
    Sigma = sigma_twi
  )
  
  #Compute probability (return < 0.01%)
  threshold <- 0.0001
  
  results_twi$Probability <- pnorm(
    threshold,
    mean = results_twi$Mu,
    sd = results_twi$Sigma
  )
  
  results_twi
  
  #----------------
  #SDR
  r <- rSDR
  
  ARMA_GARCH_est <- list()
  ic_arma_garch <- matrix(nrow = 3^4, ncol = 6)
  colnames(ic_arma_garch) <- c("pm", "qm", "ph", "qh", "aic", "bic")
  
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
          ic_arma_garch[i, 1:4] <- c(pm, qm, ph, qh)
          
          if (ph == 0 && qh == 0)
          {
            ARMA_GARCH_mod <- arfimaspec(
              mean.model = list(armaOrder = c(pm, qm))
            )
            
            ARMA_GARCH_est[[i]] <- arfimafit(ARMA_GARCH_mod, r)
            
            ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
          }
          else
          {
            try(silent = TRUE, expr = {
              ARMA_GARCH_mod <- ugarchspec(
                mean.model = list(armaOrder = c(pm, qm)),
                variance.model = list(garchOrder = c(qh, ph))
              )
              
              ARMA_GARCH_est[[i]] <- ugarchfit(
                ARMA_GARCH_mod, r, solver = "hybrid"
              )
              
              ic_arma_garch[i, 5:6] <- infocriteria(ARMA_GARCH_est[[i]])[1:2]
            })
          }
        }
      }
    }
  }
  ic_aic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,5]), ][1:40, ]
  ic_bic_arma_garch <- ic_arma_garch[order(ic_arma_garch[,6]), ][1:40, ]
  
  ic_aic_arma_garch
  ic_bic_arma_garch
  ic_int_arma_garch <- intersect(as.data.frame(ic_aic_arma_garch),
                                 as.data.frame(ic_bic_arma_garch))  
 ic_int_arma_garch
 
 #    pm qm ph qh      aic      bic
 # 1   2  2  2  1 1.821043 1.846093
 # 2   2  2  2  2 1.824185 1.852018
 # 3   2  2  1  1 1.827956 1.850222
 # 4   2  2  1  2 1.829323 1.854373
 # 5   1  2  2  1 1.830821 1.853088
 # 6   1  2  2  2 1.831814 1.856864
 # 7   2  1  2  1 1.832032 1.854299
 # 8   2  1  2  2 1.833025 1.858075
 # 9   1  1  2  1 1.833891 1.853374
 # 10  0  1  2  1 1.833922 1.850621
 adq_set_arma_garch <- as.matrix(ic_int_arma_garch[,1:4])
 
 # map adequate set back to original 81-model list
 adq_idx_arma_garch <- match(
   data.frame(t(adq_set_arma_garch)),
   data.frame(t(ic_arma_garch[,1:4]))
 )
 
 # select ARMA(2,2)-GARCH(2,1)
 idx_sdr <- adq_idx_arma_garch[which(
   adq_set_arma_garch[,1] == 2 &
     adq_set_arma_garch[,2] == 2 &
     adq_set_arma_garch[,3] == 2 &
     adq_set_arma_garch[,4] == 1
 )]
 
 model_sdr <- ARMA_GARCH_est[[idx_sdr]]
 
 # residuals
 res <- model_sdr@fit$z
 sig <- model_sdr@fit$sigma
 stdres <- res / sig
 stdres2 <- stdres^2
 
 acf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) ACF")
 pacf(res, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) PACF")
 
 acf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres ACF")
 pacf(stdres, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres PACF")
 
 acf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres2 ACF")
 pacf(stdres2, lag.max = 10, main = "ARMA(2,2)-GARCH(2,1) Stdres2 PACF")
 
 plot(date[-1],
      model_twi@fit$var,
      type = "l",
      xlab = "",
      ylab = "Estimated volatility",
      main = "SDR: ARMA(2,2)-GARCH(2,1) volatility")
 
 coef(model_sdr)
 
 #Forecasting
 # we set the seed so the results dont change every time
 set.seed(123)
 boot_sdr <- ugarchboot(model_sdr, method = "Partial", n.bootpred = 5000
 )
 plot(boot_sdr, which = 2) #this is the simulated forecast of mean 
 plot(boot_sdr, which = 3) #this is the forecast of volatility 
 
 # SDR: Forecast + Probability
 
 # Forecast mean and sigma (2 days ahead)
 fc_sdr <- ugarchforecast(model_sdr, n.ahead = 2)
 
 mu_sdr <- as.numeric(fitted(fc_sdr))
 sigma_sdr <- as.numeric(sigma(fc_sdr))
 
 #Create results table
 results_sdr <- data.frame(
   Day = c("13/01/2026", "14/01/2026"),
   Mu = mu_sdr,
   Sigma = sigma_sdr
 )
 
 #Compute probability (return < 0.01%)
 threshold <- 0.0001
 
 results_sdr$Probability <- pnorm(
   threshold,
   mean = results_sdr$Mu,
   sd = results_sdr$Sigma
 )
 
 results_sdr
 #----------------

 
 
 
 
 