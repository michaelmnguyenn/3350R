# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1: `fig1_log_levels.png`**

**Figure 2: `fig2_log_diffs.png`**

The quarterly data cover the USA over 1959Q1–2023Q4 (260 observations). The series are the log price level `p_t`, log real GDP per capita `y_t`, log real consumption `c_t`, and the nominal 3-month T-bill rate `r_t`.

The log-level plots of `p_t`, `y_t`, and `c_t` all show persistent upward movement over the sample. This suggests that these three processes have trending means and are unlikely to be covariance stationary in levels. `y_t` and `c_t` move closely together throughout, which is consistent with consumption and output sharing a common long-run growth path, while `p_t` rises more steeply, especially through the high-inflation period of the 1970s and early 1980s.

The log-difference plots of `Δp_t`, `Δy_t`, and `Δc_t` look much more stable than the level series. All three fluctuate around fairly constant means and do not display the same persistent upward movement, suggesting that differencing removes most of the trend. `Δp_t` is comparatively noisy but does not drift; `Δy_t` and `Δc_t` show very large negative observations around the Global Financial Crisis and again in 2020, but otherwise move around stable averages. This is consistent with the idea that the level processes are closer to difference stationary than trend stationary.

The nominal interest rate `r_t` behaves differently from the other three series. It does not show steady growth, but instead exhibits long swings and regime-like persistence: it rises into the late 1970s and early 1980s, declines over subsequent decades, remains close to zero for much of the 2010s, and rises again after 2021. So, answering the question directly, the dominant feature of `r_t` is strong level persistence and apparent regime change rather than deterministic trend growth. That means `r_t` should not be interpreted in the same way as the log-level macro series.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.944853 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.429001 | 0.005305 | 0.000043 | 0.9834 |

All three trend slope estimates are statistically significant with very small standard errors, and the high R² values confirm that a linear time trend accounts for most of the long-run variation in each log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Rationale and Comparison

These estimates describe average growth in two different ways. The time-trend regression estimates the average deterministic linear trend in the level series, while the mean of first differences estimates the average quarter-to-quarter growth rate. If a series is well described as difference stationary with a stable mean in first differences, the two estimates should be close.

In this sample the estimates are quite close. For `y_t`, the estimated trend is 0.004757 while the mean of `Δy_t` is 0.004919; for `c_t`, 0.005305 versus 0.005379. The gap is slightly larger for `p_t` (0.010125 versus 0.009310), which is consistent with the plot showing somewhat less smooth trend behaviour. The high-inflation 1970s and subsequent disinflation distort a single linear trend more than they distort the average of quarterly changes.

This comparison fits the idea of difference stationarity. The two numbers are not exactly the same because the regression imposes one straight line through the full sample, while the mean of first differences simply averages quarter-to-quarter changes. Even so, the closeness of the estimates supports the view that the level series have strong stochastic trends and are much more stable after differencing. This does not prove a unit root by itself, but it provides a clear rationale for working with the differenced series in later ARIMA analysis.

---

## Question 2

### 2(a) Model Selection

A broad set of ARIMA(p,d,q) models was estimated for `Δp_t` and `r_t` over 1959Q1–2023Q4, with `p, q` ranging from 0 to 10 and `d ∈ {0,1}`. Models were ranked by AIC and BIC and then screened using the Ljung-Box test at 12 lags. Models that left clear residual autocorrelation were not retained as adequate candidates.

**Inflation** (`Δp_t`): Unit root testing and the exploratory plots support treating `Δp_t` as stationary, so the appropriate differencing order is `d = 0`. The three best adequate models, ranked by AIC and passing the Ljung-Box screen at 12 lags, are:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,0,3) | −2686.38 | −2657.92 | 0.1010 |
| ARIMA(1,0,6) | −2685.30 | −2653.28 | 0.1150 |
| ARIMA(5,0,6) | −2685.21 | −2638.97 | 0.0687 |

All three models fit the short-run dynamics of quarterly inflation well. ARIMA(3,0,3) is the best adequate model because it combines adequacy with the lowest AIC and BIC of the reported candidates.

**Interest rates** (`r_t`): The plot for `r_t` shows long swings and slow adjustment rather than simple deterministic trend growth. That makes it reasonable to compare both stationary and differenced ARIMA specifications and then retain the adequate models with the strongest information-criterion support. In the final screen, the strongest adequate models are all level models (`d = 0`), so the evidence favours modelling `r_t` as highly persistent but not requiring differencing over this sample. The three strongest adequate models are:

| Interest rate model | AIC | BIC | Ljung-Box p-value | Selected |
|---|---:|---:|---:|---|
| ARIMA(4,0,6) | 477.47 | 520.19 | 0.1323 | Best adequate |
| ARIMA(8,0,1) | 478.25 | 517.41 | 0.2161 | Adequate |
| ARIMA(8,0,2) | 478.96 | 521.68 | 0.1584 | Adequate |

These models all imply strong persistence in the nominal rate. ARIMA(4,0,6) is retained as the best adequate benchmark because it has the lowest AIC among the reported adequate candidates while also passing the residual test. Since the forecasting exercise in part (b) only concerns inflation, the interest-rate models are reported here to complete the model-selection exercise rather than for forecasting.

### 2(b) Inflation Forecasts for 2024–2025

**Figure 3: `fig2a_forecast.png`**

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

All three models forecast quarterly inflation returning toward a similar long-run mean. ARIMA(3,0,3) stays close to 0.0088 to 0.0089, ARIMA(1,0,6) is slightly lower in the near term, and ARIMA(5,0,6) gives the lowest short-run forecasts.

### 2(c) Policy Use and Forecast Uncertainty

Forecasts of `Δp_t` are useful for policy because decisions depend on expected inflation, not just current inflation. Central banks use inflation forecasts when setting interest rates, and fiscal authorities use them when assessing real spending and debt outcomes.

The main source of uncertainty is innovation uncertainty: future shocks are unknown, so the predictive intervals widen with the forecast horizon. There is also model uncertainty because the three adequate specifications do not imply exactly the same forecast path, especially at short horizons. In other words, the reported intervals measure uncertainty conditional on a particular model, while the spread across the three models gives an additional sense of specification uncertainty.

These forecasts also assume parameter stability: the inflation process estimated on the historical sample continues to hold out of sample. If the economy moves into a new regime, for example after a supply shock or a change in policy behaviour, realised inflation can fall outside the model-based intervals. Quantitatively, this uncertainty is summarised by the 68% and 95% forecast bands, but those bands still condition on the maintained model being the correct one.

---

## Question 3

**Figure 4: `fig3_actual_vs_forecast.png`**

The actual quarterly inflation rates for 2024Q1–2025Q3 are computed from the price-level data as `Δp_t = log(P_t) − log(P_{t−1})`, using `P_{2023Q4}` as the last in-sample observation.

| Quarter | Actual `Δp_t` | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) |
|---|---:|---:|---:|---:|
| 2024Q1 | 0.007964 | 0.008699 | 0.008527 | 0.008533 |
| 2024Q2 | 0.008313 | 0.008529 | 0.008246 | 0.008031 |
| 2024Q3 | 0.007613 | 0.008932 | 0.008493 | 0.007930 |
| 2024Q4 | 0.006339 | 0.008852 | 0.008212 | 0.007454 |
| 2025Q1 | 0.007146 | 0.008798 | 0.008218 | 0.007599 |
| 2025Q2 | 0.006288 | 0.008867 | 0.008348 | 0.008254 |
| 2025Q3 | 0.006477 | 0.008878 | 0.008419 | 0.008735 |

Forecast performance:

| Model | MSFE | RMSFE | MAE |
|---|---:|---:|---:|
| ARIMA(3,0,3) | 3.3983e−06 | 0.001843 | 0.001631 |
| ARIMA(1,0,6) | 1.9668e−06 | 0.001402 | 0.001208 |
| ARIMA(5,0,6) | 1.5590e−06 | 0.001249 | 0.000994 |

ARIMA(5,0,6) performs best on all three measures. ARIMA(1,0,6) comes second, and ARIMA(3,0,3) performs worst of the three. So the model with the best out-of-sample performance is not the same as the model with the best in-sample AIC/BIC. The more important point, however, is that all three models over-predict inflation in the hold-out period.

This is not mainly a fitting failure in the narrow in-sample sense. The models were adequate on the pre-2024 sample, but the disinflation after 2021 proceeded faster than these backward-looking ARIMA specifications implied. That is why all three models make forecast errors in the same direction. So the evaluation suggests a common regime or persistence error, not just poor fit from one particular specification.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 5: `fig4a_real_rate.png`**

Following the exact wording of the question, the proxy is constructed as `rr_t = r_t − Δp_t`. Its sample mean is about 4.34, with a minimum close to 0.01 and a maximum about 15.03.

The plot suggests that this proxy is very similar to the nominal interest rate and much less stable than inflation. That follows mechanically from the definition in the assignment: `Δp_t` is small relative to `r_t`, so subtracting it changes the level only slightly. The dominant feature of `rr_t` is therefore the same long-run persistence seen in `r_t`, including the rise into the early 1980s, the decline over later decades, and the near-zero regime in the 2010s.

### 4(b) Consumption Ratio

**Figure 6: `fig4b_consumption_ratio.png`**

The dominant feature of the consumption ratio, `cy_t = C_t/Y_t`, is its persistent upward movement over the sample. The series rises from about 0.590 early in the sample to about 0.693 by 2023Q4, with only moderate short-run fluctuations around that upward path.

Economically, a rising consumption ratio means consumption has grown faster than output, so a larger share of GDP is being used for household spending. The main feature of the plot is not short-run volatility but a slow rise in the consumption share.

### 4(c) Best Adequate ARIMA Model for the Real Rate

For the proxy `rr_t = r_t − Δp_t`, the strongest adequate model in the search is a differenced ARIMA rather than a stationary level specification:

| Model for the real rate | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(7,1,5) | 474.05 | 523.79 | 0.9679 |

Key estimated coefficients include `φ₄ = 0.4564`, `φ₇ = −0.3841`, `θ₁ = 0.4736`, `θ₂ = −0.2673`, `θ₄ = −0.4045`, `θ₅ = −0.3704`, and `drift = 0.0015`.

This is the best adequate model because it has the strongest information-criterion support among the adequate candidates and leaves no meaningful residual autocorrelation. It captures the dominant feature of the plot because the proxy inherits substantial low-frequency movement from the nominal interest rate. The first difference removes that slow-moving level component, while the rich ARMA structure in the differenced series captures the remaining short-run persistence and reversal. The very high Ljung-Box p-value indicates that little residual autocorrelation remains.

### 4(d) Best Adequate ARIMA Model for the Consumption Ratio

A search over `d ∈ {0,1}` and `p, q = 0,...,6` was carried out using AIC, BIC, and residual diagnostics. Unlike the interest-rate series, the consumption ratio keeps trending upward through the sample, so differencing is the more convincing choice. The preferred model is:

| Model for the consumption ratio | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients: `φ₁ = 0.6092`, `φ₂ = −0.5732`, `φ₃ = 0.7553`, `θ₁ = −0.8316`, `θ₂ = 0.6862`, `θ₃ = −0.8547`, `drift = 0.0003`.

This is the best adequate model because it combines strong information-criterion support with adequate residual diagnostics. First differencing is appropriate here because the series does not move around one stable level. The small positive drift captures the average rise in the consumption share, while the AR and MA terms absorb short-run persistence.

### 4(e) Policy Use

A forecasting model for the real-rate proxy is useful because real rates matter more for intertemporal decisions than nominal rates do. For monetary policy, the issue is whether the policy stance is likely to remain restrictive or accommodative in real terms. The ARIMA model is useful because it captures the persistence and gradual adjustment in the proxy, which helps describe how quickly real financing conditions are changing and therefore answers the policy-use part of the question directly.

The consumption-ratio model is relevant for both monetary and fiscal policy. A rising consumption share suggests strong household demand and a lower saving rate. For fiscal policy, it helps assess how households may respond to taxes or transfers. For monetary policy, a high and rising consumption share may mean households are more sensitive to interest-rate changes.

---
## Question 5

### 5(a) Sample Variances

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

These sample variances estimate the unconditional variances of the return series and summarise their average volatility over the full sample. A larger value implies greater average variability in returns. The ranking is `SDR > USD > CNY > TWI`, so SDR is the most volatile on average and TWI the least volatile.

On the evidence of the sample variances alone, the safest conclusion is that TWI returns were the smoothest over the sample, while USD and SDR returns were the most variable. It is reasonable to relate TWI's low variance to the diversification of a basket index and CNY's lower variance to a more managed exchange-rate environment, but those are interpretations rather than conclusions proven by the variance estimates themselves. What the statistics directly establish is the average volatility ranking, not its structural cause, and they do not show whether volatility is constant through time.

### 5(b) Absolute Returns

**Figure 7: `fig5b_abs_returns.png`**

The plots of `|e_{j,t}|` show clear periods of low volatility followed by periods of much higher volatility, especially around March 2020 and again in later parts of the sample. Large absolute returns tend to be followed by further large returns, while calm stretches tend to persist. This is the standard volatility-clustering pattern. The most prominent shared spike occurs at the onset of COVID-19, where all four series show an abrupt and simultaneous jump.

This pattern is inconsistent with an iid constant-variance process. If returns were iid with constant variance, the absolute-return plots would not show such persistent bursts of activity. Instead, the evidence points to time-varying conditional volatility, which is exactly the feature that GARCH-type models are designed to capture.

---

## Question 6

### Testing for GARCH Effects

Before fitting a variance model, the Engle ARCH LM test with 10 lags was applied to each return series to confirm that conditional variance is time-varying:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | 0.0000 | 0.0000 |
| USD | 275.60 | 0.0000 | 0.0000 |
| TWI | 484.45 | 0.0000 | 0.0000 |
| SDR | 426.45 | 0.0000 | 0.0000 |

Both tests reject homoskedasticity overwhelmingly for every series. A constant-variance model is clearly inadequate for all four series, and GARCH-type modelling is warranted.

### Mean Equation Selection

A small ARMA grid was estimated first for each return series to identify sensible low-order mean dynamics before modelling conditional variance jointly. For USD, TWI, and SDR the final GARCH specifications kept the same mean equations as that first-stage screen. For CNY, the final joint ARMA-GARCH estimation improved slightly when one extra MA term was included, so the final mean equation is `ARMA(2,3)` rather than the preliminary `ARMA(2,2)`.

- **CNY**: `ARMA(2,3)`
- **USD**: `ARMA(0,0)`
- **TWI**: `ARMA(1,0)`
- **SDR**: `ARMA(0,1)`

### Variance Model and Error Distribution

A broad range of `ARMA(p,q)-GARCH(p_sigma,q_sigma)` models was then estimated for each currency, with `p_sigma, q_sigma` allowed to range up to 4 and Normal, Student-t, and skewed-Student-t errors considered. To match the literal wording of the question as closely as possible, the final reported specifications are all symmetric `GARCH` models rather than asymmetric extensions. Model choice was based on three requirements taken together:

- low information criteria, especially BIC;
- no remaining serial correlation in the standardised residuals;
- no important remaining ARCH effects in the squared standardised residuals, with a preference for models whose persistence is below one so Question 7 is well defined.

The final models selected for Question 6 are:

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

These fitted models all imply persistent conditional volatility because the ARCH and GARCH coefficients sum to values close to one, but the persistence remains below one in every selected specification. That is important because it means the models are both dynamically rich and still admissible for long-run variance calculations in Question 7.

### Diagnostics and Volatility Plots

The residual checks for the selected models are summarised below:

| Currency | LB on Std. Residuals | LB on Sq. Std. Residuals |
|---|---:|---:|
| CNY | 0.0749 | 0.1857 |
| USD | 0.7008 | 0.0509 |
| TWI | 0.5560 | 0.2421 |
| SDR | 0.9189 | 0.1508 |

All four models pass the Ljung-Box check on the standardised residuals, so the mean equations appear adequate. The squared-residual tests are also acceptable at the conventional 5% level for all four currencies. TWI and SDR are very comfortably adequate, and the revised CNY model is now clearly more convincing than before. USD remains the most borderline of the four under a symmetric Normal GARCH restriction: I explored heavier-tailed symmetric alternatives, but although they reduced AIC and BIC, they left much stronger residual ARCH effects. I also checked asymmetric specifications such as `gjrGARCH`, which improved the USD diagnostics further, but I have not reported them because the question is worded specifically in terms of `ARMA-GARCH`. So, answering the question directly, the reported set above is my final set of best adequate `ARMA-GARCH` models, with `ARMA(0,0)-GARCH(3,3)` retained as the best defensible USD choice under that literal restriction.

**Figures 8–11: `fig6_vol_CNY.png`, `fig6_vol_USD.png`, `fig6_vol_TWI.png`, `fig6_vol_SDR.png`**

All four conditional volatility series spike sharply during the COVID-19 episode in March 2020, then gradually decay. The TWI series is visibly the smoothest and least reactive, while USD and SDR show the largest and most persistent volatility bursts. This aligns well with the sample-variance evidence in Question 5 and supports the view that TWI is the most stable of the four exchange-rate return series.

---
## Question 7

For the symmetric GARCH models selected in Question 6, the unconditional variance exists when:

`sum alpha_i + sum beta_i < 1`

When that condition holds, the unconditional variance is:

`sigma_j^2 = omega / (1 - sum alpha_i - sum beta_i)`

Applying this to each fitted model:

| Currency | Persistence | Model Variance (σ̂²) | Sample Variance | Ratio |
|---|---:|---:|---:|---:|
| CNY | 0.9125 | 0.3179 | 0.3369 | 0.9436 |
| USD | 0.9529 | 0.4383 | 0.4381 | 1.0005 |
| TWI | 0.9005 | 0.2476 | 0.2675 | 0.9258 |
| SDR | 0.9243 | 0.4526 | 0.4492 | 1.0076 |

All four persistence measures are below 1, so finite unconditional variances exist for every currency. The persistence values are still high, especially for USD and SDR, so volatility shocks decay slowly even though the long-run variance is well defined.

Comparing these model-implied variances with the sample variances from Question 5 gives a useful diagnostic. For CNY and TWI, the unconditional variance is lower than the raw sample variance, which is consistent with the sample being lifted by temporary stress episodes. For USD and SDR, the model-implied and sample variances are almost identical, which suggests the estimated GARCH dynamics reproduce their average volatility very closely. The broad ranking is unchanged: TWI remains the least volatile series, while USD and SDR remain the most volatile.

---

## Question 8

The probability that the daily return falls below the threshold of 0.01% on 13/01/2026 and 14/01/2026 is computed from the one-step-ahead and two-step-ahead forecasts of the final ARMA-GARCH models selected in Question 6. Returns are defined as `e_{j,t} = 100 × log(S_{j,t} / S_{j,t−1})`, so they are already expressed in percentage units, and the threshold 0.01% corresponds directly to the value 0.01 in those units. Because all four final models are estimated under Normal errors, the Normal CDF is used here.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0046 | 0.4547 | 0.5128 | −0.0036 | 0.5036 | 0.5108 |
| USD | −0.0104 | 0.4739 | 0.5172 | −0.0104 | 0.5096 | 0.5160 |
| TWI | −0.0030 | 0.3953 | 0.5131 | −0.0029 | 0.4221 | 0.5122 |
| SDR | −0.0190 | 0.4939 | 0.5234 | −0.0050 | 0.4892 | 0.5122 |

All probabilities remain above 0.5 because the threshold is close to zero and the forecast means are negative in every case. When the conditional mean lies below zero, more than half of the Normal forecast distribution will fall below a threshold such as 0.01%.

A lower probability is preferable from a downside-risk perspective, since it means a smaller chance of earning less than the 0.01% threshold. On **13 January 2026**, the ranking from least to most downside risk is CNY (0.5128), TWI (0.5131), USD (0.5172), SDR (0.5234). On **14 January 2026**, the ranking is CNY (0.5108), TWI (0.5122), SDR (0.5122, marginally above TWI at full precision), USD (0.5160).

This ranking depends on both the conditional mean and the conditional volatility. The revised CNY model now produces the smallest downside-risk probability on both dates because its forecast mean is closer to zero than before while its forecast volatility remains moderate relative to USD and SDR. TWI still looks attractive because it has the lowest volatility, but CNY edges it out once the full forecast distribution is used. The investment implication is that a risk-averse investor who wants to minimise the probability of falling below 0.01% would choose **CNY for both 13 January 2026 and 14 January 2026**. This also shows why conditional risk measures are more informative than unconditional sample variances alone: the preferred asset depends on the joint behaviour of the conditional mean and conditional variance, not just on average sample volatility.
