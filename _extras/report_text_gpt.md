# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1**

**Figure 2**

The sample covers the USA from 1959Q1 to 2023Q4, giving 260 quarterly observations in total. The four variables are the log price level `p_t`, log real GDP per capita `y_t`, log real consumption `c_t`, and the nominal 3-month T-bill rate `r_t`.

The first thing that jumps out from the level plots is the sustained upward movement in `p_t`, `y_t`, and `c_t` — a pattern that immediately calls covariance stationarity in levels into question. `y_t` and `c_t` track each other closely, which is consistent with the idea that output and consumption share a common long-run growth path. `p_t` climbs more steeply, particularly during the inflationary surge of the 1970s and early 1980s.

Moving to first differences changes the picture considerably. `Δp_t`, `Δy_t`, and `Δc_t` all settle into fluctuations around fairly stable means, rather than drifting persistently upward. Inflation remains the noisiest of the three, but it no longer trends. Output and consumption growth both show large negative observations around the Global Financial Crisis and in 2020, yet they recover to stable averages outside those episodes. On balance, the differenced plots look more consistent with difference-stationary processes than trend-stationary ones.

`r_t` tells a different story altogether. Rather than trending upward, it moves through long, persistent swings: rising into the late 1970s and early 1980s, declining gradually over the following decades, sitting close to zero for much of the 2010s, and then rising again after 2021. The dominant feature is slow-moving persistence — possibly with regime change — not deterministic trend growth. For that reason, `r_t` should not be interpreted in the same way as the log-level macro variables.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.944853 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.429001 | 0.005305 | 0.000043 | 0.9834 |

Each estimated trend slope is highly significant, with very small standard errors, and the high R² values confirm that a simple linear trend accounts for most of the long-run variation in these log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Rationale and Comparison

These two sets of estimates approach average growth from different angles. The time-trend regression picks up the average linear path through the level series, while the mean of first differences simply averages quarter-to-quarter changes. If a series is better thought of as difference stationary with a stable mean in first differences, these two numbers should come out close to one another.

That is broadly what we see. For `y_t`, the trend estimate is 0.004757 against a first-difference mean of 0.004919; for `c_t`, the corresponding values are 0.005305 and 0.005379. The gap is somewhat larger for `p_t` (0.010125 versus 0.009310), which makes sense given the plot — the inflation surge of the 1970s and the subsequent disinflation pull the fitted trend in a way that a simple average of quarterly changes is less sensitive to.

Overall, the comparison supports the difference-stationary interpretation. The estimates are not identical because the regression forces a single straight line through the entire sample, whereas the mean of first differences just averages period-by-period movements. Even so, their similarity suggests that the level series are driven mainly by stochastic trends and stabilise considerably after differencing. That is not a formal unit-root test, but it does provide a sensible basis for working with the differenced series in the ARIMA exercises that follow.

---

## Question 2

### 2(a) Model Selection

I estimated a broad grid of ARIMA(p,d,q) models for `Δp_t` and `r_t` over 1959Q1–2023Q4, letting `p, q = 0,...,10` and `d ∈ {0,1}`. Models were first ranked by AIC and BIC, then screened with the Ljung-Box test at 12 lags. Any specification leaving obvious residual autocorrelation was dropped.

**Inflation** (`Δp_t`): Unit root testing and the exploratory plots support treating `Δp_t` as stationary, so `d = 0` throughout. The three best adequate models, ranked by AIC and passing the Ljung-Box screen at 12 lags, are:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,0,3) | −2686.38 | −2657.92 | 0.1010 |
| ARIMA(1,0,6) | −2685.30 | −2653.28 | 0.1150 |
| ARIMA(5,0,6) | −2685.21 | −2638.97 | 0.0687 |

All three capture the short-run dynamics of quarterly inflation reasonably well. Among them, ARIMA(3,0,3) stands out as the best adequate model: it combines the lowest AIC and BIC in the reported set with acceptable residual diagnostics.

**Interest rates** (`r_t`): The plot for `r_t` shows long swings and slow adjustment rather than a simple upward trend, so it makes sense to compare both stationary and differenced ARIMA specifications before settling on a final choice. In the end, the strongest adequate models are all level specifications (`d = 0`), suggesting that `r_t` is best treated as highly persistent but not requiring differencing over this sample. The three strongest adequate models are:

| Interest rate model | AIC | BIC | Ljung-Box p-value | Selected |
|---|---:|---:|---:|---|
| ARIMA(4,0,6) | 477.47 | 520.19 | 0.1323 | Best adequate |
| ARIMA(8,0,1) | 478.25 | 517.41 | 0.2161 | Adequate |
| ARIMA(8,0,2) | 478.96 | 521.68 | 0.1584 | Adequate |

All three point to strong persistence in the nominal rate. ARIMA(4,0,6) is retained as the best adequate benchmark on the strength of its AIC and its clean residual check. Since part (b) asks only for inflation forecasts, the `r_t` models are included here to complete the selection exercise rather than to produce a separate forecast.

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

All three models converge toward a similar long-run mean. ARIMA(3,0,3) holds close to 0.0088–0.0089 throughout the horizon, ARIMA(1,0,6) sits slightly lower early on, and ARIMA(5,0,6) produces the lowest near-term forecasts of the group.

### 2(c) Policy Use and Forecast Uncertainty

Inflation forecasts matter for policy precisely because decisions are made in forward-looking terms — central banks set interest rates based on where inflation is headed, not just where it is today, and fiscal authorities lean on the same projections when assessing real spending, revenue, and debt dynamics.

There are two main layers of uncertainty worth distinguishing here. The first is innovation uncertainty: because future shocks are unknown, the predictive intervals widen as the horizon lengthens. The second is model uncertainty, visible in the fact that the three adequate specifications do not produce exactly the same forecast path, especially in the near term. In other words, the reported bands capture uncertainty conditional on a single model, while the spread across the three specifications gives a separate read on how sensitive the conclusions are to the choice of model.

These forecasts also rest on the assumption of parameter stability — that is, the inflation process estimated from the historical sample carries forward unchanged. If the economy shifts regime (following a supply shock or a significant policy change, for instance), realised inflation could easily fall outside the model-based intervals. The 68% and 95% bands summarise forecast uncertainty, but they do so under the maintained assumption that the chosen model remains appropriate.

---

## Question 3

**Figures 4-6**

Actual quarterly inflation rates for 2024Q1–2025Q3 are computed from the price-level data as `Δp_t = log(P_t) − log(P_{t−1})`, using `P_{2023Q4}` as the last in-sample observation.

| Quarter | Actual `Δp_t` | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) |
|---|---:|---:|---:|---:|
| 2024Q1 | 0.007964 | 0.008699 | 0.008527 | 0.008533 |
| 2024Q2 | 0.008313 | 0.008529 | 0.008246 | 0.008031 |
| 2024Q3 | 0.007613 | 0.008932 | 0.008493 | 0.007930 |
| 2024Q4 | 0.006339 | 0.008852 | 0.008212 | 0.007454 |
| 2025Q1 | 0.007146 | 0.008798 | 0.008218 | 0.007599 |
| 2025Q2 | 0.006288 | 0.008867 | 0.008348 | 0.008254 |
| 2025Q3 | 0.006477 | 0.008878 | 0.008419 | 0.008735 |

Question 3 requires the three inflation forecasts from Question 2 to be compared with realised inflation, so Figures 4-6 and the table above report each forecast path against the actual series.

The broad pattern is clear: all three models over-predict inflation for most of the 2024–2025Q3 period, with realised values consistently falling below the forecast paths. Each specification, in short, expected inflation to be higher and more persistent than it turned out to be.

Among the three, `ARIMA(5,0,6)` generally tracks the realised path most closely — notably in 2024Q3, 2024Q4, 2025Q1, and 2025Q2. `ARIMA(1,0,6)` typically comes next, while `ARIMA(3,0,3)` tends to produce the highest forecasts and therefore the largest over-predictions. The model with the strongest in-sample information-criterion support is, somewhat ironically, the one that handles the subsequent disinflation least well out of sample.

One plausible reading of this is that inflation became less persistent after 2023 than the estimation sample implied. All three ARIMA models were fitted on earlier data, so they projected forward a degree of persistence that did not carry over into 2024–2025. The resulting forecast errors look less like isolated random misses and more like a systematic persistence problem — or perhaps a mild regime shift — common to all three specifications.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 7**

Following the question's definition, the proxy is `rr_t = r_t − Δp_t`, with a sample mean of about 4.34, a minimum near 0.01, and a maximum of about 15.03.

The plot makes it immediately clear that this proxy behaves far more like the nominal rate than like inflation. Since `Δp_t` is small relative to `r_t`, subtracting it changes the level only slightly. What dominates is the same slow-moving persistence seen in `r_t` itself — the build-up into the early 1980s, the long decline that followed, and the near-zero regime during the 2010s.

### 4(b) Consumption Ratio

**Figure 8**

The consumption ratio `cy_t = C_t/Y_t` drifts gradually upward across the sample, rising from around 0.590 early on to roughly 0.693 by 2023Q4, with only moderate short-run variation around that path. The main story here is not volatility but trend: over several decades, household spending has taken up a larger and larger share of GDP. Consumption, in other words, has consistently grown faster than output.

### 4(c) Best Adequate ARIMA Model for the Real Rate

For `rr_t = r_t − Δp_t`, the best adequate model turns out to be a differenced specification rather than a stationary level model:

| Model for the real rate | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(7,1,5) | 474.05 | 523.79 | 0.9679 |

Key estimated coefficients include `φ₄ = 0.4564`, `φ₇ = −0.3841`, `θ₁ = 0.4736`, `θ₂ = −0.2673`, `θ₄ = −0.4045`, `θ₅ = −0.3704`, and `drift = 0.0015`.

This is the preferred specification because it offers the strongest information-criterion support among adequate candidates while leaving almost no residual autocorrelation — as the notably high Ljung-Box p-value suggests. The choice also makes sense visually: the proxy inherits a substantial low-frequency component from the nominal rate, so first differencing removes the slow-moving level behaviour and the ARMA terms pick up the remaining short-run persistence and reversal.

### 4(d) Best Adequate ARIMA Model for the Consumption Ratio

A search over `d ∈ {0,1}` and `p, q = 0,...,6` was conducted using AIC, BIC, and residual diagnostics. Unlike the interest-rate proxy, the consumption ratio keeps drifting upward through the sample, which makes differencing the more defensible choice. The preferred model is:

| Model for the consumption ratio | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients: `φ₁ = 0.6092`, `φ₂ = −0.5732`, `φ₃ = 0.7553`, `θ₁ = −0.8316`, `θ₂ = 0.6862`, `θ₃ = −0.8547`, `drift = 0.0003`.

This model combines strong information-criterion support with clean residual diagnostics. First differencing is natural here because the series shows no tendency to revert to a stable level. The small positive drift captures the average long-run increase in the consumption share, and the AR and MA terms absorb the remaining short-run dynamics.

### 4(e) Policy Use

A forecasting model for the real-rate proxy is useful because the intertemporal decisions that drive consumption and investment depend on real rather than nominal interest rates. From a monetary policy perspective, the key practical question is whether the policy stance is likely to remain restrictive or accommodative in real terms. The ARIMA model speaks to this because it captures the persistence and gradual adjustment of the proxy — giving some purchase on how quickly real financing conditions are likely to change.

The consumption-ratio model has relevance for both monetary and fiscal policy. A rising consumption share reflects strong household demand and a declining saving rate. For fiscal authorities, that matters when thinking through how households might respond to changes in taxes or transfers. For monetary policymakers, a high and rising share suggests households may be increasingly sensitive to movements in interest rates.

---

## Question 5

### 5(a) Sample Variances

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

These sample variances estimate the unconditional variance of each return series and give a rough picture of average volatility over the full sample. The ranking runs `SDR > USD > CNY > TWI`, meaning SDR was the most volatile and TWI the most stable.

Taking these estimates at face value, the safest conclusion is simply that TWI returns were the smoothest over the sample, while USD and SDR were the most variable. It is tempting to link TWI's low variance to the diversification effect of a basket index, and CNY's relatively low figure to a more managed exchange-rate regime, but those remain interpretations rather than findings the variance estimates themselves establish. What the statistics directly show is the average volatility ranking — not the structural cause behind it, and not whether volatility was constant over time.

### 5(b) Absolute Returns

**Figure 9**

The absolute-return plots `|e_{j,t}|` display clear clusters of elevated and subdued activity, particularly around March 2020 and in later parts of the sample. Large absolute returns tend to follow other large returns, while quiet stretches also persist for extended periods — the classic volatility-clustering signature. The most obvious common spike appears at the onset of COVID-19, when all four series jump sharply and simultaneously.

This behaviour is hard to square with an iid constant-variance process. Under constant variance, the absolute-return plots should look uniformly noisy rather than exhibiting prolonged bursts of activity. The evidence points instead to time-varying conditional volatility — exactly what GARCH-type models are built to handle.

---

## Question 6

### Testing for GARCH Effects

Before fitting any variance model, the Engle ARCH LM test with 10 lags was applied to each return series to confirm that conditional variance is in fact time-varying:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | p < 1e-15 | p < 1e-15 |
| USD | 275.60 | p < 1e-15 | p < 1e-15 |
| TWI | 484.45 | p < 1e-15 | p < 1e-15 |
| SDR | 426.45 | p < 1e-15 | p < 1e-15 |

Both tests reject homoskedasticity very strongly for every series. The p-values are written as `p < 1e-15` because they are numerically indistinguishable from zero, not because they are exactly zero. A constant-variance model is clearly inadequate for all four currencies, and GARCH-type modelling is warranted.

### Mean Equation Selection

Before modelling the conditional variance, I estimated a small ARMA grid for each return series to identify sensible low-order mean dynamics. For USD, TWI, and SDR, the final GARCH specifications kept the same mean equations from that preliminary screen. CNY improved slightly once an additional MA term was introduced in the joint ARMA-GARCH estimation, so its final mean equation is `ARMA(2,3)` rather than the preliminary `ARMA(2,2)`.

- **CNY**: `ARMA(2,3)`
- **USD**: `ARMA(0,0)`
- **TWI**: `ARMA(1,0)`
- **SDR**: `ARMA(0,1)`

### Variance Model and Error Distribution

A broad grid of `ARMA(p,q)-GARCH(p_sigma,q_sigma)` models was then estimated for each currency, allowing `p_sigma, q_sigma` up to 4 and comparing Normal, Student-t, and skewed-Student-t errors. To stay within the literal framing of the question, all final reported specifications use symmetric `GARCH` rather than asymmetric extensions. Selection was based on three criteria jointly:

- low information criteria, with particular weight on BIC;
- no remaining serial correlation in the standardised residuals;
- no important ARCH effects left in the squared standardised residuals, and a preference for persistence below one so that Question 7 is well defined.

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

All fitted models imply highly persistent conditional volatility, with ARCH and GARCH coefficients summing close to one. That said, persistence stays strictly below one in every selected specification — a property that matters because it guarantees the long-run variance calculations in Question 7 are well defined, while still capturing the volatility clustering visible in the data.

### Diagnostics and Volatility Plots

Residual checks for the selected models are summarised below:

| Currency | LB on Std. Residuals | LB on Sq. Std. Residuals |
|---|---:|---:|
| CNY | 0.0749 | 0.1857 |
| USD | 0.7008 | 0.0509 |
| TWI | 0.5560 | 0.2421 |
| SDR | 0.9189 | 0.1508 |

All four models pass the Ljung-Box check on the standardised residuals, so the mean equations appear adequate. The squared-residual tests are also acceptable at the 5% level across the board. TWI and SDR sit comfortably inside the adequate range, and the revised CNY model is notably cleaner than the earlier version. USD remains the most borderline case under the symmetric Normal GARCH constraint. I did explore heavier-tailed symmetric alternatives, but while they reduced AIC and BIC, they left stronger residual ARCH effects. Asymmetric specifications such as `gjrGARCH` improved the USD diagnostics further, but they are not reported here because the question is framed in terms of `ARMA-GARCH` specifically. On balance, `ARMA(0,0)-GARCH(3,3)` remains the most defensible USD choice within that restriction.

Accordingly, the four specifications reported above are my final set of best adequate symmetric `ARMA-GARCH` models for Question 6.

**Figures 10-13**

All four conditional volatility series spike sharply around the COVID-19 episode in March 2020 and then decay only gradually. TWI is visibly the smoothest and least reactive series, while USD and SDR show the largest and most persistent volatility bursts — a pattern consistent with the sample-variance evidence from Question 5, and further support for the view that TWI is the most stable of the four exchange-rate return series.

---

## Question 7

For the symmetric GARCH models selected in Question 6, the unconditional variance exists when:

`sum alpha_i + sum beta_i < 1`

When that condition holds, the unconditional variance is given by:

`sigma_j^2 = omega / (1 - sum alpha_i - sum beta_i)`

Applying this to each fitted model:

| Currency | Persistence | Model Variance (σ̂²) | Sample Variance | Ratio |
|---|---:|---:|---:|---:|
| CNY | 0.9125 | 0.3179 | 0.3369 | 0.9436 |
| USD | 0.9529 | 0.4383 | 0.4381 | 1.0005 |
| TWI | 0.9005 | 0.2476 | 0.2675 | 0.9258 |
| SDR | 0.9243 | 0.4526 | 0.4492 | 1.0076 |

Persistence falls below 1 for all four currencies, so each has a finite unconditional variance. The values are still high — particularly for USD and SDR — which means volatility shocks die out slowly even though they do eventually dissipate.

Comparing the model-implied variances with the sample variances from Question 5 is instructive. For CNY and TWI, the unconditional variance comes out below the raw sample figure, which is consistent with temporary stress episodes (like the COVID shock) inflating sample volatility above its long-run level. For USD and SDR, the two measures are almost identical, suggesting that the estimated GARCH dynamics reproduce average volatility very closely across the full sample. The overall ranking does not change: TWI remains the least volatile series, and USD and SDR the most volatile.

---

## Question 8

The probability that the daily return falls below the 0.01% threshold on 13/01/2026 and 14/01/2026 is computed from the one-step-ahead and two-step-ahead forecasts of the final ARMA-GARCH models from Question 6. Returns are defined as `e_{j,t} = 100 × log(S_{j,t} / S_{j,t−1})`, so they are already in percentage units and the threshold corresponds directly to the value 0.01. Since all four final models are estimated under Normal errors, the Normal CDF is used throughout.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0046 | 0.4547 | 0.5128 | −0.0036 | 0.5036 | 0.5108 |
| USD | −0.0104 | 0.4739 | 0.5172 | −0.0104 | 0.5096 | 0.5160 |
| TWI | −0.0030 | 0.3953 | 0.5131 | −0.0029 | 0.4221 | 0.5122 |
| SDR | −0.0190 | 0.4939 | 0.5234 | −0.0050 | 0.4892 | 0.5122 |

All of these probabilities exceed 0.5, which follows naturally from the fact that the threshold is close to zero and the forecast means are negative in every case. When the conditional mean lies below zero, more than half of the Normal forecast distribution will fall below a threshold like 0.01%.

From a downside-risk perspective, a lower probability is preferable — it means a smaller chance of earning less than the 0.01% threshold. On **13 January 2026**, the ranking from least to most downside risk is CNY (0.5128), TWI (0.5131), USD (0.5172), and SDR (0.5234). On **14 January 2026**, the ranking shifts to CNY (0.5108), TWI (0.5122), SDR (0.5122, marginally above TWI at full precision), and USD (0.5160).

What drives this ranking is the interplay between the conditional mean and conditional volatility. The revised CNY model delivers the lowest downside-risk probability on both dates because its forecast mean sits closer to zero than the other currencies, while its forecast volatility stays moderate relative to USD and SDR. TWI still looks attractive given its low volatility, but once the full forecast distribution is accounted for, CNY edges ahead. The investment implication is fairly clear: a risk-averse investor seeking to minimise the probability of falling below the 0.01% threshold would choose **CNY on both 13 January 2026 and 14 January 2026**. More broadly, this illustrates why conditional risk measures are more informative than unconditional sample variances alone — the preferred asset depends on the joint behaviour of the conditional mean and conditional variance, not just average historical volatility.
