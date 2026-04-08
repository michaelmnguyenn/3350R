getwd()
rm(list = ls())
#Q1
mydata <- read.delim("MacroData.csv", header = TRUE,  sep = ",")

sel_sample <- mydata$date >= as.Date("1959-01-01") &
  mydata$date <= as.Date("2023-10-01")
mydata$date <- as.Date(mydata$date)

y <- as.matrix(mydata$y[sel_sample])
p <- as.matrix(mydata$p[sel_sample])
r <- as.matrix(mydata$r[sel_sample])
c <- as.matrix(mydata$c[sel_sample])
dates <- mydata$date[sel_sample]

pt <- log(p)
yt <- log(y)
ct <- log(c)

#-----------------
par(mar = c(5, 4, 4, 4))   # give space for right axis

ylim_left  <- range(pt, na.rm = TRUE)
ylim_right <- range(c(yt, ct), na.rm = TRUE)

# First plot: pt on left axis
plot(dates, pt,
     type = "l",
     col = "blue",
     lwd = 2,
     ylim = ylim_left,
     xlim = range(dates),
     xlab = "Time (Quarters)",
     ylab = "pt",
     main = "Log Levels: pt vs yt vs ct (Dual Axis)")

# Overlay second plot: yt and ct on right axis
par(new = TRUE)

plot(dates, yt,
     type = "l",
     col = "red",
     lwd = 2,
     ylim = ylim_right,
     xlim = range(dates),
     axes = FALSE,
     xlab = "",
     ylab = "",
     bty = "n")

lines(dates, ct, col = "green", lwd = 2)

axis(4)
mtext("yt and ct", side = 4, line = 3)

legend("topleft",
       legend = c("pt", "yt", "ct"),
       col = c("blue", "red", "green"),
       lty = 1,
       lwd = 2)
#___------------------------


head(mydata$date)
class(mydata$date) #checking the class of the date, was shown as characters from the original data
mydata$date <- as.Date(mydata$date) #needed to change from character to int

dpt <- diff(pt)
dyt <- diff(yt)
dct <- diff(ct)
r_aligned <- r[-1]
dates_aligned <-dates[-1]

matplot(dates_aligned,
        cbind(dpt, dyt, dct),
        type = "l",
        lty = 1,
        lwd = 2,
        col = c("blue", "red", "green"),
        xlab = "Time (Quarters)",
        ylab = "Delta values",
        main = "Log Differences: Δpt, Δyt and Δct")

legend("topleft",
       legend = c("Δpt", "Δyt", "Δct"),
       col = c("blue", "red", "green"),
       lty = 1,
       lwd = 2)

plot(dates_aligned, cbind(r_aligned), type = "l", xlab = "Time (Quarters)", ylab= "Nominal Rates", main = "3-Month Treasury Bill Secondary Market Rate")

#Q1 b) 

#simple regression
t <- 1:length(pt)
reg_pt <- lm(pt~t)
reg_yt <- lm(yt~t)
reg_ct <- lm(ct~t)

summary(reg_pt) # in log form the intercept is 0.272 and a time value of 1.01%
summary(reg_yt) # time growth is 0.475%, 9.945 at the intercept
summary(reg_ct) # 9.429 intercept and a growth of 0.530%

#finding the mean growth rate, compare with the trend from part 1 

mean(dpt) # the mean growth is 0.931%
mean(dyt) #the mean growth is 0.490%
mean(dct) # the mean growht is 0.537%

#The similarity between the estimated time trend coefficient and the mean of the 
#differenced series suggests that the observed trend in levels is driven by 
#accumulated changes rather than a fixed deterministic path. 
#This is consistent with a stochastic trend (I(1) process with drift), 
#where growth arises from persistent shocks.

#We undertake these estimations to understand the underlying growth behaviour of the time 
#series and to determine whether growth is better characterised as a deterministic trend or
#as average changes over time. This helps identify the nature of the data generating process, 
#which is central in time series analysis

#The time trend coefficient (), from the regression model captures deterministic trend component of the series
#It measures the systematic and predictable increase in variable based on time. On the otherhand
#the mean of the differenced series captures the average growth rate (), reflecting how the series
#evolves period to period, including the effects of the shock.

#As the estimates yielded very similar results (for yt 0.475% vs 0.490%, pt 1.01% vs 0.931%, ct 0.530% vs 0.537%)

#-------------------------------------------------------#


#Q2 #this is for the set up on forecasting and residual checking
library(forecast)
checkresiduals1 <- function(object, lag, df=NULL, test, plot=TRUE, ...) {
  showtest <- TRUE
  if (missing(test)) {
    if (is.element("lm", class(object))) {
      test <- "BG"
    } else {
      test <- "LB"
    }
    showtest <- TRUE
  }
  else if (test != FALSE) {
    test <- match.arg(test, c("LB", "BG"))
    showtest <- TRUE
  }
  else {
    showtest <- FALSE
  }
  
  # Extract residuals
  if (is.element("ts", class(object)) | is.element("numeric", class(object))) {
    residuals <- object
    object <- list(method = "Missing")
  }
  else {
    residuals <- residuals(object)
  }
  
  if (length(residuals) == 0L) {
    stop("No residuals found")
  }
  
  if ("ar" %in% class(object)) {
    method <- paste("AR(", object$order, ")", sep = "")
  } else if (!is.null(object$method)) {
    method <- object$method
  } else if ("HoltWinters" %in% class(object)) {
    method <- "HoltWinters"
  } else if ("StructTS" %in% class(object)) {
    method <- "StructTS"
  } else {
    method <- try(as.character(object), silent = TRUE)
    if ("try-error" %in% class(method)) {
      method <- "Missing"
    } else if (length(method) > 1 | base::nchar(method[1]) > 50) {
      method <- "Missing"
    }
  }
  if (method == "Missing") {
    main <- "Residuals"
  } else {
    main <- paste("Residuals from", method)
  }
  
  if (plot) {
    suppressWarnings(ggtsdisplay(residuals, plot.type = "histogram", main = main, ...))
  }
  
  # Check if we have the model
  if (is.element("forecast", class(object))) {
    object <- object$model
  }
  
  if (is.null(object) | !showtest) {
    return(invisible())
  }
  
  # Seasonality of data
  freq <- frequency(residuals)
  
  # Find model df
  if(grepl("STL \\+ ", method)){
    warning("The fitted degrees of freedom is based on the model used for the seasonally adjusted data.")
  }
  df <- modeldf(object)
  
  if (missing(lag)) {
    lag <- ifelse(freq > 1, 2 * freq, 10)
    lag <- min(lag, round(length(residuals)/5))
    lag <- max(df+3, lag)
  }
  
  if (!is.null(df)) {
    if (test == "BG") {
      # Do Breusch-Godfrey test
      BGtest <- lmtest::bgtest(object, order = lag)
      BGtest$data.name <- main
      print(BGtest)
      return(BGtest$p.value)
    }
    else {
      # Do Ljung-Box test
      LBtest <- Box.test(zoo::na.approx(residuals), fitdf = df, lag = lag, type = "Ljung")
      LBtest$method <- "Ljung-Box test"
      LBtest$data.name <- main
      names(LBtest$statistic) <- "Q*"
      print(LBtest)
      cat(paste("Model df: ", df, ".   Total lags used: ", lag, "\n\n", sep = ""))
      return(LBtest$p.value)
    }
  }
  
}

#Arima for change in inflation 

TT <- length(dpt)

ARIMA_est_dpt <- list()

ic_arima_dpt <- matrix(nrow = (2 * 2 + 2) * 4^2, ncol = 7)
colnames(ic_arima_dpt) <- c("const", "trend", "p", "d", "q", "aic", "bic")

i <- 0
for (d in 0:1)
{
  for (const in 0:1)
  {
    for (p in 0:10)
    {
      for (q in 0:10)
      {
        i <- i + 1
        d1 <- as.logical(d)
        c1 <- as.logical(const)
        
        try(silent = TRUE, expr =
              {
                ARIMA_est_dpt[[i]] <- Arima(dpt, order = c(p, d, q),
                                            include.constant = c1)
                
                ic_arima_dpt[i, ] <- c(const, 0, p, d, q,
                                       ARIMA_est_dpt[[i]]$aic,
                                       ARIMA_est_dpt[[i]]$bic)
              })
        
        if (const)
        {
          # only allow a trend when there is a constant
          i <- i + 1
          
          if (d1)
          {
            x <- c(0, cumsum(1:(TT - 1)))
          }
          else
          {
            x <- NULL
          }
          
          try(silent = TRUE, expr =
                {
                  ARIMA_est_dpt[[i]] <- Arima(dpt, order = c(p, d, q),
                                              xreg = x,
                                              include.constant = c1,
                                              include.drift = TRUE)
                  
                  ic_arima_dpt[i, ] <- c(const, 1, p, d, q,
                                         ARIMA_est_dpt[[i]]$aic,
                                         ARIMA_est_dpt[[i]]$bic)
                })
        }
      }
    }
  }
}

# top 10 by AIC and BIC

ic_aic_dpt <- ic_arima_dpt[order(ic_arima_dpt[, 6]), ][1:10, ]
ic_bic_dpt <- ic_arima_dpt[order(ic_arima_dpt[, 7]), ][1:10, ]

ic_aic_dpt
ic_bic_dpt

ic_int_dpt <- intersect(as.data.frame(ic_aic_dpt),
                               as.data.frame(ic_bic_dpt)) 
ic_int_dpt

#finding the union
ic_uni_dpt <- unique(rbind(ic_aic_dpt, ic_bic_dpt))
# Top 10 models according to BIC
ic_uni_dpt[order(ic_uni_dpt[, 7]),][1:10, ]

# Top 10 models according to AIC
ic_uni_dpt[order(ic_uni_dpt[, 6]),][1:10, ]

#const trend p d  q       aic       bic
#[1,]     0     0 3 0  6 -2682.912 -2647.343
#[2,]     0     0 2 0 10 -2682.726 -2636.487*
#[3,]     0     0 2 0  5 -2681.689 -2653.234
#[4,]     0     0 2 0  9 -2681.685 -2639.003*
#[5,]     0     0 1 0 10 -2681.487 -2638.805
#[6,]     0     0 4 0  9 -2681.301 -2631.506*
#[7,]     0     0 6 0 10 -2681.267 -2620.801
#[8,]     0     0 4 0  5 -2681.098 -2645.530
#[9,]     0     0 5 0  9 -2680.818 -2627.465
#[10,]     0     0 3 0  3 -2680.306 -2655.408

#checking residuals
#model 1
checkresiduals1(Arima(dpt, order = c(2,0,10), include.constant = FALSE))

# Model 2
checkresiduals1(Arima(dpt, order = c(2,0,9), include.constant = FALSE))

# Model 3: (0,0,3,0,3)
checkresiduals1(Arima(dpt, order = c(3,0,3), include.constant = FALSE))

#ATENTTION: all residuals for white noise were rejected as they were all below 
#p values of 5%, this potentially suggests that the model used is inadequate or 
#not enough lag is included.DO I INCREASE? or CHOOSE ANOTHER ONE FOR 0,0,3,0,3

#in the end, the model was expanded with high parsimony, 
#[2,]     0     0 2 0 10 -2682.726 -2636.487*
#[4,]     0     0 2 0  9 -2681.685 -2639.003*
#[6,]     0     0 4 0  9 -2681.301 -2631.506*

checkresiduals1(Arima(dpt, order = c(2,0,10), include.constant = FALSE))
checkresiduals1(Arima(dpt, order = c(2,0,9), include.constant = FALSE))
checkresiduals1(Arima(dpt, order = c(4,0,9), include.constant = FALSE))

#Forecasting

dpt_ts <- ts(dpt, start = c(1959, 2), frequency = 4)
hrz <- 7

# fit models
fit1 <- Arima(dpt_ts, order = c(2,0,10), include.constant = FALSE)
fit2 <- Arima(dpt_ts, order = c(4,0,9), include.constant = FALSE)
fit3 <- Arima(dpt_ts, order = c(2,0,9), include.constant = FALSE)

# forecasts
fcst1 <- forecast(fit1, h = hrz, level = c(68,95))

fcst2 <- forecast(fit2, h = hrz, level = c(68,95))

fcst3 <- forecast(fit3, h = hrz, level = c(68,95))


# plot 1

plot(fcst1,
     include = length(dpt_ts),
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "Dpt - ARIMA(2,0,10)")

# plot 2

plot(fcst2,
     include = length(dpt_ts),
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "Dpt - ARIMA(4,0,9)")

# plot 3

plot(fcst3,
     include = length(dpt_ts),
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "Dpt - ARIMA(2,0,9)")

#---------------------------------#
#repeat this for interest rates

TT <- length(r)

ARIMA_est_r <- list()
ic_arima_r <- matrix(nrow = (2 * 2 + 2) * 4^2, ncol = 7)
colnames(ic_arima_r) <- c("const", "trend", "p", "d", "q", "aic", "bic")

i <- 0
for (d in 0:1)
{
  for (const in 0:1)
  {
    for (p in 0:10)
    {
      for (q in 0:10)
      {
        i <- i + 1
        d1 <- as.logical(d)
        c1 <- as.logical(const)
        
        try(silent = TRUE, expr =
              {
                ARIMA_est_r[[i]] <- Arima(r,
                                          order = c(p, d, q),
                                          include.constant = c1)
                
                ic_arima_r[i, ] <- c(const, 0, p, d, q,
                                     ARIMA_est_r[[i]]$aic,
                                     ARIMA_est_r[[i]]$bic)
              })
        
        if (const)
        {
          # only allow a trend when there is a constant
          i <- i + 1
          
          if (d1)
          {
            x <- c(0, cumsum(1:(TT - 1)))
          }
          else
          {
            x <- NULL
          }
          
          try(silent = TRUE, expr =
                {
                  ARIMA_est_r[[i]] <- Arima(r,
                                            order = c(p, d, q),
                                            xreg = x,
                                            include.constant = c1,
                                            include.drift = TRUE)
                  
                  ic_arima_r[i, ] <- c(const, 1, p, d, q,
                                       ARIMA_est_r[[i]]$aic,
                                       ARIMA_est_r[[i]]$bic)
                })
        }
      }
    }
  }
}

# top 10 by AIC and BIC
ic_aic_r <- ic_arima_r[order(ic_arima_r[, 6]), ][1:10, ]
ic_bic_r <- ic_arima_r[order(ic_arima_r[, 7]), ][1:10, ]

ic_aic_r
ic_bic_r

# union of top AIC and BIC models
ic_uni_r <- unique(rbind(ic_aic_r, ic_bic_r))

# Top 10 in the union by BIC
ic_uni_r[order(ic_uni_r[, 7]), ][1:10, ]

# Top 10 in the union by AIC
ic_uni_r[order(ic_uni_r[, 6]), ][1:10, ]


#top three:
#     const trend p d q      aic      bic
#[1,]     0     0 2 1 2 486.4558 504.2400
#[2,]     0     0 3 1 2 487.9652 509.3061
#[3,]     1     0 2 1 2 488.4234 509.7644
#interest rates appear to be non=stationary as all models have first differencing
#This is expected for interest rates does not change very quickly despite it
#revolving around economic conditions. 

#check residuals
# Model 1 (0,0,2,1,2)
checkresiduals1(Arima(r, order = c(8,0,5), include.constant = FALSE)) #(0.692)
# Model 2 (0,0,3,1,2)
checkresiduals1(Arima(r, order = c(8,0,6), include.constant = FALSE)) #(0.5)
# Model 3: (1,0,2,1,2)
checkresiduals1(Arima(r, order = c(8,0,2), include.constant = FALSE)) #(0.19)

#all models are below p value of 0.01, hence suggests that the model is inadequate
#so we had to increase the model size, 0:10s

r_ts <- ts(r, start = c(1959, 2), frequency = 4)
hrz <- 7

# fit models
fit1_r <- Arima(r_ts, order = c(8,0,5), include.constant = FALSE)
fit2_r <- Arima(r_ts, order = c(8,0,6), include.constant = FALSE)
fit3_r  <- Arima(r_ts, order = c(8,0,2), include.constant = FALSE)

# forecasts
fcst1_r <- forecast(fit1_r, h = hrz, level = c(68,95))

fcst2_r <- forecast(fit2_r, h = hrz, level = c(68,95))

fcst3_r <- forecast(fit3_r, h = hrz, level = c(68,95))

# plot 1

plot(fcst1_r,
     include = length(r_ts),
     ylab = expression(r[t]),
     xlab = "Time",
     main = "r - ARIMA(8,0,5)")

# plot 2

plot(fcst2_r,
     include = length(r_ts),
     ylab = expression(r[t]),
     xlab = "Time",
     main = "r - ARIMA(8,0,6)")

# plot 3

plot(fcst3_r,
     include = length(r_ts),
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "r - ARIMA(8,0,2)")

#---------------------------#

#Q3 

# select future price level observations
sel_future <- mydata$date >= as.Date("2023-10-01") &
  mydata$date <= as.Date("2025-07-01")

P_future <- as.numeric(mydata$p[sel_future])

# last observed price level from estimation sample (2023Q4)
P_2023Q4 <- as.numeric(tail(sel_sample, 1))

# combine 2023Q4 with future P_t values
P_all_future <- c(P_2023Q4, P_future)

# convert to actual future inflation: Δp_t = log(P_t) - log(P_{t-1})
actual_dpt_future <- diff(log(P_all_future))

# make quarterly ts object
actual_dpt_future_ts <- ts(actual_dpt_future,
                           start = c(2023, 4),
                           frequency = 4)

actual_dpt_future
actual_dpt_future_ts

plot(fcst1,
     include = 0,
     xlim = c(2024, 2025.5),
     xaxt = "n",
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "ARIMA(2,0,10)")

lines(actual_dpt_future_ts, col = "black", lwd = 2)

ticks <- seq(2024, 2025.5, by = 0.25)
labels <- paste0(floor(ticks), " Q", as.integer((ticks %% 1) * 4 + 1))

# only label every second tick
labels[c(FALSE, TRUE)] <- NA
axis(1, at = ticks, labels = labels)

legend("topright",
       legend = c("Forecast", "Actual Data"),
       col = c("blue", "black"),
       lwd = 2,
       bty = "n")   # removes box (optional)

#plot 2
plot(fcst2,
     include = 0,
     xlim = c(2024, 2025.5),
     xaxt = "n",
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "ARIMA(4,0,9)")

lines(actual_dpt_future_ts, col = "black", lwd = 2)

ticks <- seq(2024, 2025.5, by = 0.25)
labels <- paste0(floor(ticks), " Q", as.integer((ticks %% 1) * 4 + 1))

# only label every second tick
labels[c(FALSE, TRUE)] <- NA
axis(1, at = ticks, labels = labels)

legend("topright",
       legend = c("Forecast", "Actual Data"),
       col = c("blue", "black"),
       lwd = 2,
       bty = "n")   # removes box (optional)

#plot 3
plot(fcst3,
     include = 0,
     xlim = c(2024, 2025.5),
     xaxt = "n",
     ylab = expression(Delta*p[t]),
     xlab = "Time",
     main = "ARIMA(2,0,9)")

lines(actual_dpt_future_ts, col = "black", lwd = 2)

ticks <- seq(2024, 2025.5, by = 0.25)
labels <- paste0(floor(ticks), " Q", as.integer((ticks %% 1) * 4 + 1))

# only label every second tick
labels[c(FALSE, TRUE)] <- NA

axis(1, at = ticks, labels = labels)

legend("topright",
       legend = c("Forecast", "Actual Data"),
       col = c("blue", "black"),
       lwd = 2,
       bty = "n")   # removes box (optional)

#--------------------------------
#The selection of ARIMA(3,0,3) with no constant suggests that the change in inflation (Δpt) 
#is well described as a stationary process with short-run dynamics driven by past values and '
#shocks. This is consistent with the course theory that macroeconomic variables are often 
#integrated of order one, and their first differences are stationary. 

#The absence of a constant implies that Δpt fluctuates around a stable mean without deterministic 
#growth, which aligns with economic intuition that inflation changes are mean-reverting rather than 
#trending.

#The forecasts produced by the different ARIMA(3,0,3) specifications are very similar, indicating that the forecasts are robust to small specification changes. This is consistent with findings from the tutorial that different ARMA models often generate similar forecasts when they adequately capture the data dynamics .
#However, the models struggle to capture sharp movements in inflation, particularly during periods of large shocks. The forecasts remain smooth and revert towards the mean, while actual values exhibit volatility. This reflects a key limitation of ARIMA models, which rely on historical patterns and cannot anticipate structural changes or unexpected shocks.
#The widening prediction intervals over time indicate increasing uncertainty as the forecast horizon increases, which is expected in macroeconomic forecasting.
#CHANGE CHANGE CHANGE
#------------------------------



rrt <- r_aligned - 100*dpt #the log change were in decimals so not unit constant
all.equal(length(r[-1]), length(dpt)) # check if they aligned
cyt <- c/y

plot(dates_aligned, cbind(rrt), type = "l", xlab = "Time (Quarters)", ylab= "Rate", main = "Real 3-Month Treasury Bill Secondary Market Rate")
plot(dates_aligned, cbind(dpt*100), type = "l", xlab = "Time (Quarters)", ylab= "Rate", main = "Inflation")

matplot(dates_aligned,
        cbind(dpt*100, rrt, r_aligned),
        type = "l",
        lty = 1,
        lwd = 2,
        col = c("blue", "black", "grey"),
        xlab = "Time (Quarters)",
        ylab = "Rates",
        main = "Comparing real interest to nominal interest and inflation")

legend("topleft",
       legend = c("Δpt", "rrt", "rt"),
       col = c("blue", "black", "grey"),
       lty = 1,
       lwd = 2)

#From comparison between the real and nominal interest rate depicts a more stable yet still volatile movement
#This suggests that the main drivers of the variability and swings of the market rate - especially during the 
# 1970s and 80s - is less so influenced by inflation but rather monetary policies and other macroeconomic factors.

#Furthermore, infaltion is more stable for it moves within a very narrow band between -1 and 3 percent
#whereas nominal and real interests spike to as high as 15% and 12%. 


#Overall, the evidence suggests that the real interest rate is slightly more stable than the nominal 
#interest rate, but still highly volatile, and significantly less stable than inflation.

plot(dates, cbind(cyt), type = "l", xlab = "Time (Quarters)", ylab= "Ratio", main = "Consumption Ratio")


#from the consumption ratio plot, we recognise a smooth upwards trending since the 1970s with only 
#minor fluctuations around the trend.
#
#From an economic perspective, this suggests that consumptino has been growing more than output 
#over the same period, leading to an increased share of GDP being allocated to consumption.
#This reflects a structural shifts within the economy and may suggest an underlying stochastic 
#process despite the data appearing to be determinimistic.In particular, this suggest that the US has 
#a dominant importer as it relies more heavily on consumption than manufacturing and exports. 


#Report an estimation of the best adequate ARIMA(p, d, q) model for rrt
#Discuss how the model captures the dominant features of the plot in Question 4a.
TT <- length(rrt)

ARIMA_est_rrt <- list()
ic_arima_rrt <- matrix(nrow = (2 * 2 + 2) * 4^2, ncol = 7)
colnames(ic_arima_rrt) <- c("const", "trend", "p", "d", "q", "aic", "bic")

i <- 0
for (d in 0:1)
{
  for (const in 0:1)
  {
    for (p in 0:10)
    {
      for (q in 0:10)
      {
        i <- i + 1
        d1 <- as.logical(d)
        c1 <- as.logical(const)

        try(silent = TRUE, expr =
        {
          ARIMA_est_rrt[[i]] <- Arima(rrt,
                                      order = c(p, d, q),
                                      include.constant = c1)

          ic_arima_rrt[i, ] <- c(const, 0, p, d, q,
                                 ARIMA_est_rrt[[i]]$aic,
                                 ARIMA_est_rrt[[i]]$bic)
        })

        if (const)
        {
          # only allow trend when there is a constant
          i <- i + 1

          if (d1)
          {
            x <- c(0, cumsum(1:(TT - 1)))
          }
          else
          {
            x <- NULL
          }

          try(silent = TRUE, expr =
          {
            ARIMA_est_rrt[[i]] <- Arima(rrt,
                                        order = c(p, d, q),
                                        xreg = x,
                                        include.constant = c1,
                                        include.drift = TRUE)

            ic_arima_rrt[i, ] <- c(const, 1, p, d, q,
                                   ARIMA_est_rrt[[i]]$aic,
                                   ARIMA_est_rrt[[i]]$bic)
          })
        }
      }
    }
  }
}

# remove rows where estimation failed
ic_arima_rrt <- ic_arima_rrt[complete.cases(ic_arima_rrt), ]

# top 10 by AIC and BIC
ic_aic_rrt <- ic_arima_rrt[order(ic_arima_rrt[, 6]), ][1:10, ]
ic_bic_rrt <- ic_arima_rrt[order(ic_arima_rrt[, 7]), ][1:10, ]

ic_aic_rrt
ic_bic_rrt

# union of top AIC and BIC sets
ic_uni_rrt <- unique(rbind(ic_aic_rrt, ic_bic_rrt))

ic_uni_rrt

# show union ranked by BIC and AIC
ic_uni_rrt[order(ic_uni_rrt[, 7]), ][1:min(10, nrow(ic_uni_rrt)), ]
ic_uni_rrt[order(ic_uni_rrt[, 6]), ][1:min(10, nrow(ic_uni_rrt)), ]

#the best fitted model is arima(0,0,8,0,1)

checkresiduals1(Arima(rrt, order = c(8,0,5
                                     ), include.constant = FALSE)) #p=0.307

#Report an estimation of the best adequate ARIMA(p, d, q) model for cyt
#Discuss how the model captures the dominant features of the plot in Question 4b.


TT <- length(cyt)

ARIMA_est_cyt <- list()
ic_arima_cyt <- matrix(nrow = (2 * 1 + 2) * 4^2, ncol = 7)
colnames(ic_arima_cyt) <- c("const", "trend", "p", "d", "q", "aic", "bic")

i <- 0
for (d in 0:1)
{
  for (const in 0:1)
  {
    for (p in 0:3)
    {
      for (q in 0:3)
      {
        i <- i + 1
        d1 <- as.logical(d)
        c1 <- as.logical(const)
        
        try(silent = TRUE, expr =
              {
                ARIMA_est_cyt[[i]] <- Arima(cyt,
                                            order = c(p, d, q),
                                            include.constant = c1)
                
                ic_arima_cyt[i, ] <- c(const, 0, p, d, q,
                                       ARIMA_est_cyt[[i]]$aic,
                                       ARIMA_est_cyt[[i]]$bic)
              })
        
        if (const)
        {
          # only allow trend when there is a constant
          i <- i + 1
          
          if (d1)
          {
            x <- c(0, cumsum(1:(TT - 1)))
          }
          else
          {
            x <- NULL
          }
          
          try(silent = TRUE, expr =
                {
                  ARIMA_est_cyt[[i]] <- Arima(cyt,
                                              order = c(p, d, q),
                                              xreg = x,
                                              include.constant = c1,
                                              include.drift = TRUE)
                  
                  ic_arima_cyt[i, ] <- c(const, 1, p, d, q,
                                         ARIMA_est_cyt[[i]]$aic,
                                         ARIMA_est_cyt[[i]]$bic)
                })
        }
      }
    }
  }
}

# remove rows where estimation failed
ic_arima_cyt <- ic_arima_cyt[complete.cases(ic_arima_cyt), ]

# top 10 by AIC and BIC

ic_aic_cyt <- ic_arima_cyt[order(ic_arima_cyt[, 6]), ][1:10, ]

ic_bic_cyt <- ic_arima_cyt[order(ic_arima_cyt[, 7]), ][1:10, ]

ic_aic_cyt
ic_bic_cyt

# union of top AIC and BIC sets
ic_uni_cyt <- unique(rbind(ic_aic_cyt, ic_bic_cyt))

ic_uni_cyt

# show union ranked by BIC and AIC
ic_uni_cyt[order(ic_uni_cyt[, 7]), ][1:min(10, nrow(ic_uni_cyt)), ]
ic_uni_cyt[order(ic_uni_cyt[, 6]), ][1:min(10, nrow(ic_uni_cyt)), ]

# const trend p d q       aic       bic
# [1,]     1     1 3 0 2 -2146.133 -2117.648
# [2,]     1     1 3 0 1 -2145.637 -2120.712
# [3,]     1     1 3 0 3 -2144.156 -2112.110
# [4,]     1     1 2 0 0 -2142.424 -2124.621
# [5,]     1     1 1 0 1 -2142.296 -2124.492
# [6,]     1     1 1 0 0 -2140.925 -2126.682
# [7,]     1     1 1 0 2 -2140.619 -2119.254
# [8,]     1     1 3 0 0 -2140.425 -2119.061
# [9,]     1     1 2 0 1 -2140.424 -2119.060
# [10,]     1     1 1 0 3 -2140.228 -2115.303
# [11,]     0     0 0 1 1 -2127.425 -2120.312
# [12,]     0     0 1 1 0 -2127.151 -2120.037
# [13,]     0     0 0 1 0 -2122.228 -2118.671

#the best fitted model is arima(3,0,2

checkresiduals1(Arima(cyt, order = c(3,0,2), include.constant = TRUE, include.drift = TRUE)) 
checkresiduals1(Arima(cyt, order = c(3,0,1), include.constant = TRUE, include.drift = TRUE))  
checkresiduals1(Arima(cyt, order = c(3,0,3), include.constant = TRUE, include.drift = TRUE))






