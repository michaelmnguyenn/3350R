getwd()
rm(list = ls())
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
returns <- cbind(CNY, USD, TWI, SDR)

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

e2_arma <- list()
for (i in 1:nmods)
{
  e2_arma[[i]] <- resid(ARMA_est[[adq_idx_arma[i]]]) ^ 2
  
  title_p_q <- paste("ARMA(",
                     as.character(adq_set_arma[i, 1]), ", ",
                     as.character(adq_set_arma[i, 2]), ")",
                     sep = "")
  plot(date[-1], e2_arma[[i]], type = "l",
       xlab = "", ylab = "squared resid",
       main = paste("Plot: ", title_p_q))
  
  Sys.sleep(2)
  
  acf(e2_arma[[i]], xlab = "", ylab = "",
      main = paste("SACF: ", title_p_q))
  Sys.sleep(2)


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
  fit_USD <- Arima(rCNY, order = c(1, 0, 0))   # ARMA(1,3)
  
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
  fit_TWI <- Arima(rCNY, order = c(1, 0, 3))   # ARMA(1,3)
  
  # Squared residuals
  e2_TWI <- resid(fit_TWI)^2
  
  # Plot squared residuals
  plot(date[-1], e2_TWI, type = "l",
       xlab = "", ylab = "squared resid",
       main = "Plot: rTWI ARMA(1,3)")
  
  # ACF of squared residuals
  acf(e2_TWI, xlab = "", ylab = "",
      main = "SACF: rTWI ARMA(1,3)")
  
  