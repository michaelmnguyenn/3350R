# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1**

**Figure 2**

The sample is the USA quarterly macroeconomic sample from 1959Q1 to 2023Q4, giving 260 observations. In Question 1(a), the log series are `p_t = log(P_t)`, `y_t = log(Y_t)`, and `c_t = log(C_t)`. The interest rate is not logged, so the fourth series is the nominal 3-month T-bill rate `r_t`.

The first figure plots `p_t`, `y_t`, and `c_t`. The main property of all three log-level series is that they trend upward over the sample. This means their levels do not fluctuate around a constant mean, so they do not look covariance stationary in levels. `y_t` and `c_t` move closely together, which is what we would expect if output and consumption share a common long-run growth path. `p_t` also trends upward, but it rises more sharply in the 1970s and early 1980s, which is consistent with the high-inflation period.

The second figure plots the log differences `Δp_t`, `Δy_t`, and `Δc_t` together with `r_t`. The main property of the differenced log series is that the upward trend is removed. `Δp_t`, `Δy_t`, and `Δc_t` fluctuate around fairly stable means instead of drifting upward. `Δp_t` is still more variable than the other two growth rates, while `Δy_t` and `Δc_t` have large negative observations around the Global Financial Crisis and again in 2020. This evidence suggests that the log-level series are more naturally treated as difference-stationary than as stationary in levels.

The interest rate `r_t` has a different main property. It does not have the same steady upward trend as `p_t`, `y_t`, or `c_t`. Instead, it is highly persistent and moves through long regimes: it rises into the late 1970s and early 1980s, declines over later decades, sits near zero through much of the 2010s, and rises again after 2021. Therefore, the evidence in the plot suggests persistence and possible regime change rather than deterministic trend growth.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.944853 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.429001 | 0.005305 | 0.000043 | 0.9834 |

These regressions estimate how much of the average movement in each log-level series can be captured by an intercept and a linear time trend. The estimated trend coefficients are positive for all three series: 0.010125 for `p_t`, 0.004757 for `y_t`, and 0.005305 for `c_t`. The standard errors are small and the R² values are high, so the linear time trend captures a large part of the long-run movement in each log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Rationale and Comparison

The simple rationale for undertaking the above estimations is that both exercises measure the average growth or drift in the process, but they do it in different ways. The trend coefficient `δ̂` from the regression of the log level on time measures the average slope of the log-level series over the full sample. The mean `μ̂` of the first difference measures the average quarter-to-quarter change in the log series. If a log-level process is well described as having a stochastic trend with a stable drift, these two estimates should be similar.

Based on this rationale, `δ̂` and `μ̂` are close for `y_t` and `c_t`. For `y_t`, the time trend coefficient is 0.004757 and the mean of `Δy_t` is 0.004919. For `c_t`, the time trend coefficient is 0.005305 and the mean of `Δc_t` is 0.005379. These are very similar, so the regression trend and the average first difference are capturing almost the same average growth rate.

For `p_t`, the time trend coefficient is 0.010125 and the mean of `Δp_t` is 0.009310. The difference is larger, but the estimates are still of the same order. The reason the gap is larger is that inflation does not follow one smooth linear path over the full sample: the high-inflation period of the 1970s and early 1980s and the later disinflation affect the fitted straight-line trend. Overall, the comparison supports the view that the log-level variables contain stochastic trends and become much more stable after differencing.

---

## Question 2

### 2(a) Model Selection

Question 2 asks for the three best ARIMA(p,d,q) models for inflation, `Δp_t`, and interest rates, `r_t`, using data only up to 2023Q4. I therefore treated 2024 and 2025 as the holdout period and estimated ARIMA models only on the 1959Q1-2023Q4 sample. Candidate models were ranked using AIC and BIC and then checked using the Ljung-Box test at 12 lags. A model was treated as adequate only if it did not leave clear residual autocorrelation.

For inflation, `Δp_t` already behaves like a stationary series in the plots, so the inflation models were estimated with `d = 0`. The three best adequate inflation models are:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,0,3) | −2686.38 | −2657.92 | 0.1010 |
| ARIMA(1,0,6) | −2685.30 | −2653.28 | 0.1150 |
| ARIMA(5,0,6) | −2685.21 | −2638.97 | 0.0687 |

These results support the choice of ARIMA(3,0,3), ARIMA(1,0,6), and ARIMA(5,0,6) as the three inflation models. ARIMA(3,0,3) is the preferred inflation model because it has the lowest AIC and BIC among these adequate models and its Ljung-Box p-value is above 0.05.

For interest rates, `r_t` is highly persistent but does not show steady trend growth in the same way as the log-level macro variables. The full grid included both level and differenced specifications. Some differenced specifications had slightly lower AIC values, but the reported interest-rate models are the best adequate level specifications because they match the visual interpretation of `r_t` as persistent without deterministic growth. The three reported interest-rate models are:

| Interest rate model | AIC | BIC | Ljung-Box p-value | Selected |
|---|---:|---:|---:|---|
| ARIMA(4,0,6) | 477.47 | 520.19 | 0.1323 | Best adequate |
| ARIMA(8,0,1) | 478.25 | 517.41 | 0.2161 | Adequate |
| ARIMA(8,0,2) | 478.96 | 521.68 | 0.1584 | Adequate |

These results support ARIMA(4,0,6) as the interest-rate benchmark among the adequate level models. It has the lowest AIC in this reported set and passes the residual autocorrelation check. The interest-rate models are not used for the forecast exercise because Question 2(b) asks only for inflation forecasts.

### 2(b) Inflation Forecasts for 2024–2025

**Figure 3**

| Quarter | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) | 68% CI Lower | 68% CI Upper | 95% CI Lower | 95% CI Upper |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2024Q1 | 0.008699 | 0.008527 | 0.008533 | 0.007410 | 0.009988 | 0.006158 | 0.011240 |
| 2024Q2 | 0.008529 | 0.008246 | 0.008031 | 0.006188 | 0.010869 | 0.003916 | 0.013141 |
| 2024Q3 | 0.008932 | 0.008493 | 0.007930 | 0.005590 | 0.012273 | 0.002346 | 0.015518 |
| 2024Q4 | 0.008852 | 0.008212 | 0.007454 | 0.004378 | 0.013327 | 0.000034 | 0.017671 |
| 2025Q1 | 0.008798 | 0.008218 | 0.007599 | 0.003808 | 0.013787 | −0.001036 | 0.018630 |
| 2025Q2 | 0.008867 | 0.008348 | 0.008254 | 0.003504 | 0.014230 | −0.001702 | 0.019436 |
| 2025Q3 | 0.008878 | 0.008419 | 0.008735 | 0.003176 | 0.014581 | −0.002360 | 0.020117 |
| 2025Q4 | 0.008875 | 0.008482 | 0.008710 | 0.002923 | 0.014828 | −0.002857 | 0.020607 |

The table and Figure 3 answer Question 2(b) by using each of the three inflation models to forecast `Δp_t` for 2024 and 2025. The ARIMA(3,0,3) forecasts stay close to 0.0088-0.0089 across the eight-quarter horizon. ARIMA(1,0,6) gives slightly lower forecasts in the early quarters, and ARIMA(5,0,6) gives the lowest near-term forecasts. By 2025, all three models forecast inflation close to the same long-run level.

### 2(c) Policy Use and Forecast Uncertainty

These inflation forecasts may be useful for policy because policy decisions are forward looking. A central bank sets interest rates based on where inflation is expected to go, not only on current inflation. Fiscal authorities also need expected inflation when thinking about real spending, tax revenue, and the real value of debt.

The first source of uncertainty is shock uncertainty. Future shocks to inflation cannot be known in advance, which is why the forecast intervals widen as the forecast horizon gets longer. This is measured quantitatively by the 68% and 95% forecast intervals in the table. For example, the 95% interval for ARIMA(3,0,3) widens from 0.006158 to 0.011240 in 2024Q1 to -0.002857 to 0.020607 by 2025Q4.

The second source of uncertainty is model uncertainty. The three ARIMA models do not give exactly the same forecasts, especially in the early part of the horizon, so the policy conclusion depends partly on which adequate model is used. A third source is parameter or regime uncertainty: the forecasts assume the inflation process estimated up to 2023Q4 continues to apply in 2024 and 2025. If there is a policy change, supply shock, or regime shift, the model-based forecast intervals may understate the true uncertainty.

---

## Question 3

**Figures 4-6**

Question 3 provides new values of `P_t` for 2024Q1 to 2025Q3 and asks us to evaluate the relative forecast performance of the three inflation models. I first convert the new price-level data into actual quarterly inflation using `Δp_t = log(P_t) − log(P_{t−1})`, with `P_{2023Q4}` as the final in-sample price level.

| Quarter | Actual `Δp_t` | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) |
|---|---:|---:|---:|---:|
| 2024Q1 | 0.007964 | 0.008699 | 0.008527 | 0.008533 |
| 2024Q2 | 0.008313 | 0.008529 | 0.008246 | 0.008031 |
| 2024Q3 | 0.007613 | 0.008932 | 0.008493 | 0.007930 |
| 2024Q4 | 0.006339 | 0.008852 | 0.008212 | 0.007454 |
| 2025Q1 | 0.007146 | 0.008798 | 0.008218 | 0.007599 |
| 2025Q2 | 0.006288 | 0.008867 | 0.008348 | 0.008254 |
| 2025Q3 | 0.006477 | 0.008878 | 0.008419 | 0.008735 |

Figures 4-6 and the table compare each forecast path with the realised inflation outcomes. This directly evaluates the three models against the holdout data.

| Model | MSFE | RMSFE | MAE |
|---|---:|---:|---:|
| ARIMA(3,0,3) | 3.3983e-06 | 0.001843 | 0.001631 |
| ARIMA(1,0,6) | 1.9668e-06 | 0.001402 | 0.001208 |
| ARIMA(5,0,6) | 1.5590e-06 | 0.001249 | 0.000994 |

All three models over-predict inflation across most of the 2024-2025Q3 period. This means the actual inflation values are usually below the forecast values. The common direction of the errors matters: it shows that all three models expected inflation to be more persistent than it actually was.

The relative forecast performance is best for ARIMA(5,0,6), second best for ARIMA(1,0,6), and worst for ARIMA(3,0,3). ARIMA(5,0,6) tracks the actual path most closely, especially from 2024Q3 to 2025Q2. ARIMA(3,0,3) produces the highest forecasts and therefore the largest forecast errors. The important point is that the model with the best in-sample AIC and BIC is not the model with the best holdout performance.

The reason is that the historical sample gave the models evidence of inflation persistence, and the models projected that persistence into the holdout period. Actual inflation fell more quickly than the models expected. Therefore, the forecast performance suggests a common persistence or regime problem after 2023 rather than a problem with only one specific ARIMA specification.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 7**

Question 4 asks for a proxy for the real interest rate, so I construct `rr_t = r_t − Δp_t` using the full sample. Figure 7 plots this real interest-rate proxy. Over the sample, `rr_t` has a mean of about 4.34, a minimum near 0.01, and a maximum of about 15.03.

The evidence in the plot suggests that the real interest rate is not much more stable than the nominal interest rate. It mostly tracks the slow-moving behaviour of `r_t`, because quarterly inflation `Δp_t` is small relative to the level of the nominal interest rate. The real rate rises into the early 1980s, declines over later decades, sits near zero through much of the 2010s, and then rises again. Compared with inflation, `rr_t` is clearly more persistent and less centred around a stable short-run mean. Compared with `r_t`, it is only modestly shifted by subtracting inflation.

### 4(b) Consumption Ratio

**Figure 8**

Question 4 also asks for the consumption ratio, so I construct `cy_t = C_t/Y_t` and plot it in Figure 8. The dominant feature of the plot is a long-run upward drift. The ratio rises from about 0.590 early in the sample to about 0.693 by 2023Q4, while short-run fluctuations are relatively small.

The economic interpretation is that real personal consumption expenditure has grown faster than real GDP per capita over the sample. In other words, consumption has become a larger share of output. This can be interpreted as a rising household consumption share and, equivalently, a lower share of output going to saving, investment, government spending, or net exports, depending on the broader national accounts context.

### 4(c) Best Adequate ARIMA Model for the Real Rate

For `rr_t`, the best adequate ARIMA(p,d,q) model from the search is:

| Model for the real rate | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(7,1,5) | 474.05 | 523.79 | 0.9679 |

Key estimated coefficients include `φ₄ = 0.4564`, `φ₇ = −0.3841`, `θ₁ = 0.4736`, `θ₂ = −0.2673`, `θ₄ = −0.4045`, `θ₅ = −0.3704`, and `drift = 0.0015`.

This model is adequate because it has strong information-criterion support and a Ljung-Box p-value of 0.9679, so there is no evidence of meaningful residual autocorrelation. The model captures the dominant features of the plot by using `d = 1` to remove the slow-moving low-frequency behaviour in the real rate. After differencing, the AR and MA terms model the remaining short-run persistence and reversals. This is appropriate because the plot of `rr_t` is dominated by persistence inherited from the nominal interest rate.

### 4(d) Best Adequate ARIMA Model for the Consumption Ratio

For `cy_t`, the best adequate ARIMA(p,d,q) model from the search is:

| Model for the consumption ratio | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients: `φ₁ = 0.6092`, `φ₂ = −0.5732`, `φ₃ = 0.7553`, `θ₁ = −0.8316`, `θ₂ = 0.6862`, `θ₃ = −0.8547`, `drift = 0.0003`.

This model is adequate because it has strong information-criterion support and a Ljung-Box p-value of 0.7626. It captures the dominant feature of the plot by using `d = 1`, which is appropriate because the consumption ratio does not appear to stabilise around a fixed level. The positive drift term captures the average upward movement in the consumption share, while the AR and MA terms capture short-run movements around that upward path.

### 4(e) Policy Use

The real-rate model may be useful for policy because real borrowing costs matter for consumption, investment, and monetary transmission. A nominal interest rate is not enough by itself: policy makers need to know whether the real cost of borrowing is high or low after accounting for inflation. Since the ARIMA model captures the persistence in `rr_t`, it can help describe whether real financing conditions are likely to remain restrictive or accommodative.

The consumption-ratio model may be useful for policy because the consumption share is directly related to aggregate demand. A rising `cy_t` means consumption is becoming a larger part of output, so household behaviour becomes especially important for forecasting demand. Fiscal policy makers can use this information when thinking about tax and transfer policy, while monetary policy makers can use it when thinking about how interest-rate changes affect household spending.

---

## Question 5

### 5(a) Sample Variances

Question 5 asks us to construct `100` times the log-difference of each exchange rate. I therefore define daily returns as `e_{j,t} = 100 × [log(E_{j,t}) − log(E_{j,t−1})]` for `j ∈ {CNY, USD, TWI, SDR}`. The sample variances of these return series are:

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

The sample variance `σ̂²_{j,sample}` estimates the unconditional variance of each return process over the sample. The ranking is SDR > USD > CNY > TWI. This means SDR has the highest average return variability, USD is very close behind, CNY is lower, and TWI has the lowest average variability.

The brief interpretation is that TWI is the smoothest exchange-rate return series in the sample, while USD and SDR are the most variable. This is economically plausible because TWI and SDR are basket-type measures, although the sample variance alone does not prove the structural reason. The sample variance also does not tell us whether volatility is constant over time; it only summarises the average variability over the whole sample.

### 5(b) Absolute Returns

**Figure 9**

Question 5(b) asks what the plot of `|e_{j,t}|` suggests for modelling `e_{j,t}`. Figure 9 shows clear volatility clustering in all four return series. Large absolute returns tend to be followed by other large absolute returns, and quiet periods tend to be followed by other quiet periods. The most obvious common spike occurs around March 2020.

This pattern suggests that a constant-variance model would be inadequate. If the returns were iid with constant variance, the absolute returns would not show long clusters of high and low volatility. The plot therefore provides visual evidence for time-varying conditional volatility, which is exactly the feature that GARCH models are designed to capture.

---

## Question 6

### Testing for GARCH Effects

Question 6 asks for the best adequate ARMA(p,q)-GARCH(p_sigma,q_sigma) model for each return series, with diagnostics and discussion of testing for GARCH effects. Before fitting the GARCH models, I tested for GARCH effects by applying the Engle ARCH LM test with 10 lags and the Ljung-Box test on squared returns:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | p < 1e-15 | p < 1e-15 |
| USD | 275.60 | p < 1e-15 | p < 1e-15 |
| TWI | 484.45 | p < 1e-15 | p < 1e-15 |
| SDR | 426.45 | p < 1e-15 | p < 1e-15 |

Both tests give very strong evidence of GARCH effects for every return series. The p-values are reported as `p < 1e-15` because they are numerically indistinguishable from zero. This means the null of no ARCH effects or no autocorrelation in squared returns is rejected. Therefore, a constant-variance model is not adequate, and it is appropriate to use ARMA-GARCH models.

### Mean Equation Selection

The model selection first considered the mean equation, because the ARMA part should remove predictable movement in the conditional mean before the GARCH part models conditional volatility. A small ARMA grid was estimated for each return series. For USD, TWI, and SDR, the preliminary mean equations carried through to the final ARMA-GARCH specifications. CNY was the exception: allowing one extra MA term improved the joint model, so the final mean equation for CNY is `ARMA(2,3)`.

Final mean equations:

- **CNY**: `ARMA(2,3)`
- **USD**: `ARMA(0,0)`
- **TWI**: `ARMA(1,0)`
- **SDR**: `ARMA(0,1)`

### Variance Model and Error Distribution

A range of `ARMA(p,q)-GARCH(p_sigma,q_sigma)` models was then estimated for each currency. The variance orders allowed `p_sigma` and `q_sigma` up to 4, and Normal, Student-t, and skewed-Student-t errors were considered. To keep the final answer aligned with the question's ARMA-GARCH wording, the reported final specifications use symmetric GARCH models rather than asymmetric extensions. The selected model had to satisfy three criteria:

- low AIC and BIC, with particular weight on BIC;
- no important remaining autocorrelation in standardised residuals;
- no important remaining autocorrelation in squared standardised residuals, with volatility persistence below one so the unconditional variance in Question 7 is well defined.

The selected models are:

| Currency | Mean Model | Variance Model | Errors | AIC | BIC |
|---|---|---|---|---:|---:|
| CNY | ARMA(2,3) | GARCH(1,3) | Normal | 1.5490 | 1.5796 |
| USD | ARMA(0,0) | GARCH(3,3) | Normal | 1.8398 | 1.8620 |
| TWI | ARMA(1,0) | GARCH(1,3) | Normal | 1.3099 | 1.3294 |
| SDR | ARMA(0,1) | GARCH(4,4) | Normal | 1.8309 | 1.8615 |

Key estimated coefficients:

| Currency | `μ` | AR terms | MA terms | `ω` | ARCH terms | GARCH terms |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0041 | `φ₁ = 1.8724`, `φ₂ = −0.8741` | `θ₁ = −1.9067`, `θ₂ = 0.8956`, `θ₃ = 0.0109` | 0.0278 | `α₁ = 0.2034` | `β₁ = 0.1132`, `β₂ = 0.2223`, `β₃ = 0.3736` |
| USD | −0.0104 | none | none | 0.0206 | `α₁ = 0.1359`, `α₂ = 0.0090`, `α₃ = 0.0139` | `β₁ = 0.0000`, `β₂ = 0.3324`, `β₃ = 0.4616` |
| TWI | −0.0029 | `φ₁ = −0.0442` | none | 0.0246 | `α₁ = 0.1972` | `β₁ = 0.0897`, `β₂ = 0.1895`, `β₃ = 0.4241` |
| SDR | −0.0050 | none | `θ₁ = −0.1911` | 0.0342 | `α₁ = 0.1305`, `α₂ = 0.0000`, `α₃ = 0.0619`, `α₄ = 0.0769` | `β₁ = 0.0000`, `β₂ = 0.0000`, `β₃ = 0.1994`, `β₄ = 0.4556` |

These are the estimated final models. The ARCH and GARCH coefficients are the key variance-equation terms. Across all four currencies, the ARCH and GARCH coefficients sum to values close to one, so volatility is highly persistent. However, persistence remains below one in every case, which is important because it means the unconditional variance can be computed in Question 7.

### Diagnostics and Volatility Plots

Ljung-Box results for the final models:

| Currency | LB on Std. Residuals | LB on Sq. Std. Residuals |
|---|---:|---:|
| CNY | 0.0749 | 0.1857 |
| USD | 0.7008 | 0.0509 |
| TWI | 0.5560 | 0.2421 |
| SDR | 0.9189 | 0.1508 |

The diagnostics show that the final models are adequate for the purpose of this question. The Ljung-Box p-values on standardised residuals are above 0.05 for all four currencies, so the mean equations do not leave important serial correlation. The Ljung-Box p-values on squared standardised residuals are also above 0.05 using the reported course-style diagnostic, so the variance equations remove the main volatility clustering. USD is the most borderline case, with a squared-residual p-value of 0.0509, but it still passes this diagnostic at the 5% level under the symmetric Normal GARCH specification.

Accordingly, the four specifications reported above are the final best adequate symmetric ARMA-GARCH models for Question 6.

**Figures 10-13**

Figures 10-13 plot the estimated volatility for each process. The plots show that conditional volatility is not constant. All four volatility series spike around the COVID-19 shock in March 2020 and then decay gradually. TWI has the smoothest and least reactive estimated volatility, while USD and SDR show larger volatility bursts. This agrees with the sample-variance evidence from Question 5.

---

## Question 7

Question 7 asks whether it is possible to compute the model-implied unconditional variance `σ̂²_{j,model}` from the ARMA-GARCH models in Question 6 and to compare it with the sample variance from Question 5. For the symmetric GARCH models used here, the unconditional variance exists when:

`sum alpha_i + sum beta_i < 1`

If this condition holds, the model-implied unconditional variance is:

`sigma_j^2 = omega / (1 - sum alpha_i - sum beta_i)`

Applying this formula to each fitted model gives:

| Currency | Persistence | Model Variance (σ̂²) | Sample Variance | Ratio |
|---|---:|---:|---:|---:|
| CNY | 0.9125 | 0.3179 | 0.3369 | 0.9436 |
| USD | 0.9529 | 0.4383 | 0.4381 | 1.0005 |
| TWI | 0.9005 | 0.2476 | 0.2675 | 0.9258 |
| SDR | 0.9243 | 0.4526 | 0.4492 | 1.0076 |

It is possible to compute the unconditional variance for all four currencies because persistence is below one in every case. This means none of the selected GARCH models implies an infinite unconditional variance. The persistence values are still high, especially for USD and SDR, so volatility shocks are expected to decay slowly even though the long-run variance is finite.

Compared with the sample variances from Question 5, the model-implied variances are very similar. For CNY, the model variance is 0.3179 compared with a sample variance of 0.3369. For USD, the two are almost identical: 0.4383 and 0.4381. For TWI, the model variance is 0.2476 compared with 0.2675. For SDR, the model variance is 0.4526 compared with 0.4492. The ranking is therefore almost unchanged: TWI remains the least volatile, while USD and SDR remain the most volatile.

---

## Question 8

Question 8 asks for the probability of a return less than 0.01% for each currency on 13/01/2026 and 14/01/2026, and then asks how this information would be used in risk management. The probabilities are computed from the one-step-ahead and two-step-ahead forecasts of the ARMA-GARCH models selected in Question 6. Since the returns are defined as `e_{j,t} = 100 × log(S_{j,t} / S_{j,t−1})`, they are already in percentage units. Therefore, the threshold 0.01% is entered as 0.01 in the probability calculation. All four selected models use Normal errors, so the Normal CDF is used.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0046 | 0.4547 | 0.5128 | −0.0036 | 0.5036 | 0.5108 |
| USD | −0.0104 | 0.4739 | 0.5172 | −0.0104 | 0.5096 | 0.5160 |
| TWI | −0.0030 | 0.3953 | 0.5131 | −0.0029 | 0.4221 | 0.5122 |
| SDR | −0.0190 | 0.4939 | 0.5234 | −0.0050 | 0.4892 | 0.5122 |

All probabilities are greater than 0.5. This occurs because the threshold of 0.01 is close to zero and the forecast means are negative for all currencies on both days. When the forecast mean is below zero, more than half of the Normal forecast distribution lies below a near-zero positive threshold.

For risk management, the relevant interpretation is that a lower probability is preferred because it means a lower chance of earning less than 0.01%. On **13 January 2026**, the ranking from lowest to highest downside risk is CNY (0.5128), TWI (0.5131), USD (0.5172), and SDR (0.5234). On **14 January 2026**, the ranking is CNY (0.5108), TWI (0.5122), SDR (0.5122, marginally above TWI at full precision), and USD (0.5160).

Based on this risk-management criterion, **CNY is the preferred currency on both dates**. It has the lowest probability of falling below the 0.01% threshold on 13/01/2026 and 14/01/2026. TWI is also attractive because it has low volatility, but the full forecast distribution gives CNY the lower downside probability. This shows why the investment decision should use both the conditional mean and the conditional volatility, not only the unconditional variance from Question 5.
