# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1**

**Figure 2**

The sample covers the USA from 1959Q1 to 2023Q4, so there are 260 quarterly observations in total. The variables are the log price level `p_t`, log real GDP per capita `y_t`, log real consumption `c_t`, and the nominal 3-month T-bill rate `r_t`.

What stands out first in the level plots is the steady upward movement in `p_t`, `y_t`, and `c_t`. That pattern points to trending means, so covariance stationarity in levels looks unlikely. The paths of `y_t` and `c_t` are especially close. That fits the idea that output and consumption share a common long-run growth path. `p_t`, by comparison, rises more sharply, especially during the inflationary period of the 1970s and early 1980s.

Once the series are differenced, the picture changes quite a bit. The plots of `Δp_t`, `Δy_t`, and `Δc_t` are much steadier than the corresponding level series, with fluctuations around fairly stable means instead of persistent upward drift. Inflation, `Δp_t`, is still the noisiest of the three, but it does not trend. Output and consumption growth record large negative observations around the Global Financial Crisis and again in 2020; outside those episodes, though, they return to fairly stable averages. Taken together, the plots look more like difference-stationary processes than trend-stationary ones.

`r_t` is different again. Rather than following a steady upward trend, it moves through long swings and highly persistent regimes: it rises into the late 1970s and early 1980s, trends downward over the following decades, sits close to zero for much of the 2010s, and then increases again after 2021. The dominant feature is persistence in levels, possibly with regime change, not deterministic trend growth. For that reason, `r_t` should not be read in the same way as the log-level macro variables.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.944853 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.429001 | 0.005305 | 0.000043 | 0.9834 |

Each estimated trend slope is highly significant, with very small standard errors. The high R² values also show that a simple linear trend explains most of the long-run variation in these log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Rationale and Comparison

These two sets of estimates measure average growth in different ways. The time-trend regression captures the average linear trend in the level series, while the mean of first differences captures average quarter-to-quarter growth. If a series is better viewed as difference stationary with a stable mean in first differences, those two numbers should be similar.

That is broadly what appears in this sample. For `y_t`, the estimated trend is 0.004757 and the mean of `Δy_t` is 0.004919; for `c_t`, the corresponding values are 0.005305 and 0.005379. The gap is a little larger for `p_t` (0.010125 versus 0.009310), which matches the plot, where inflation-related movements make the price trend less smooth across the full sample. A single straight line is naturally more affected by the inflation surge of the 1970s and the later disinflation than a simple average of quarterly changes.

Overall, the comparison supports the difference-stationary interpretation. The estimates are not identical because the regression forces one linear path through the entire sample, whereas the mean of first differences simply averages period-by-period movements. Even so, the similarity of the numbers suggests that the level series are driven by strong stochastic trends and become much more stable after differencing. That is not a formal unit-root test on its own, but it is a sensible reason to work with the differenced series in the later ARIMA exercises.

---

## Question 2

### 2(a) Model Selection

I estimated a broad set of ARIMA(p,d,q) models for `Δp_t` and `r_t` over 1959Q1–2023Q4, allowing `p, q = 0,...,10` and `d ∈ {0,1}`. The models were first ranked using AIC and BIC, then screened with the Ljung-Box test at 12 lags. Any specification that left obvious residual autocorrelation was dropped from the set of adequate candidates.

**Inflation** (`Δp_t`): Unit root testing and the exploratory plots support treating `Δp_t` as stationary, so the appropriate differencing order is `d = 0`. The three best adequate models, ranked by AIC and passing the Ljung-Box screen at 12 lags, are:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,0,3) | −2686.38 | −2657.92 | 0.1010 |
| ARIMA(1,0,6) | −2685.30 | −2653.28 | 0.1150 |
| ARIMA(5,0,6) | −2685.21 | −2638.97 | 0.0687 |

All three specifications capture the short-run dynamics of quarterly inflation reasonably well. Among them, ARIMA(3,0,3) is the best adequate model because it combines acceptable residual diagnostics with the lowest AIC and BIC in the reported set.

**Interest rates** (`r_t`): The plot for `r_t` shows long swings and slow adjustment rather than simple deterministic trend growth. That makes it reasonable to compare both stationary and differenced ARIMA specifications and then retain the adequate models with the strongest information-criterion support. In the final screen, the strongest adequate models are all level models (`d = 0`), so the evidence favours modelling `r_t` as highly persistent but not requiring differencing over this sample. The three strongest adequate models are:

| Interest rate model | AIC | BIC | Ljung-Box p-value | Selected |
|---|---:|---:|---:|---|
| ARIMA(4,0,6) | 477.47 | 520.19 | 0.1323 | Best adequate |
| ARIMA(8,0,1) | 478.25 | 517.41 | 0.2161 | Adequate |
| ARIMA(8,0,2) | 478.96 | 521.68 | 0.1584 | Adequate |

These models all point to strong persistence in the nominal rate. I retain ARIMA(4,0,6) as the best adequate benchmark because it has the lowest AIC among the reported adequate candidates and still passes the residual check. Since part (b) asks only for inflation forecasts, the `r_t` models are included to complete the selection exercise rather than to generate a separate set of forecasts here.

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

All three models imply that quarterly inflation moves back toward a similar long-run mean. ARIMA(3,0,3) stays close to 0.0088-0.0089, ARIMA(1,0,6) sits slightly lower early on, and ARIMA(5,0,6) produces the lowest short-run forecasts of the three.

### 2(c) Policy Use and Forecast Uncertainty

Forecasts of `Δp_t` matter for policy because policy decisions depend on expected inflation rather than inflation today alone. Central banks use them when setting interest rates, while fiscal authorities rely on them when assessing real spending, revenue, and debt outcomes.

The first source of uncertainty is innovation uncertainty: future shocks are unknown, so the predictive intervals widen as the horizon increases. There is also model uncertainty, since the three adequate specifications do not produce exactly the same forecast path, particularly in the near term. Put differently, the reported intervals measure uncertainty conditional on one model, while the spread across the three models gives a second sense of how much the answer depends on specification choice.

These forecasts also rely on parameter stability. They assume that the inflation process estimated from the historical sample continues to hold out of sample. If the economy shifts into a different regime, for instance after a supply shock or a policy change, realised inflation may fall outside the model-based intervals. The 68% and 95% bands summarise forecast uncertainty, but they still do so under the maintained assumption that the selected model remains appropriate.

---

## Question 3

**Figures 4-6**

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

Question 3 requires the inflation forecasts from Question 2 to be compared with the realised outcomes, so the three figures and the table above show each forecast path against the actual series.

The broad pattern is straightforward: all three models over-predict inflation through most of 2024–2025Q3, because the realised values sit below the forecast paths in nearly every quarter. Put simply, each specification expected inflation to be higher and more persistent than it actually was.

Of the three, `ARIMA(5,0,6)` generally sits closest to the realised path, especially in 2024Q3, 2024Q4, 2025Q1, and 2025Q2. `ARIMA(1,0,6)` is usually the next closest, whereas `ARIMA(3,0,3)` tends to produce the highest forecasts and hence the largest over-predictions. The model with the strongest in-sample AIC/BIC support is therefore not the one that tracks the subsequent disinflation best out of sample.

One plausible interpretation is that inflation became less persistent after 2023 than the estimation sample suggested. Because all three ARIMA models were fitted on earlier data, they projected forward a degree of persistence that did not fully carry into 2024–2025. The forecast errors therefore look less like isolated random misses and more like a shared persistence problem, or perhaps a mild regime shift.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 7**

Following the wording of the question exactly, the proxy is defined as `rr_t = r_t − Δp_t`. Its sample mean is about 4.34, with a minimum close to 0.01 and a maximum of about 15.03.

The plot shows that this proxy behaves much more like the nominal interest rate than like inflation. That is not surprising, since `Δp_t` is small relative to `r_t`, so subtracting it changes the level only slightly. The main feature of `rr_t` is the same slow-moving persistence seen in `r_t`, including the build-up into the early 1980s, the long decline afterwards, and the near-zero regime during the 2010s.

### 4(b) Consumption Ratio

**Figure 8**

The dominant feature of the consumption ratio, `cy_t = C_t/Y_t`, is its gradual upward drift over the sample. The series rises from about 0.590 early on to roughly 0.693 by 2023Q4, with only moderate short-run fluctuations around that path.

In economic terms, a rising consumption ratio means consumption has grown faster than output, so household spending takes up a larger share of GDP. The key pattern is not short-run volatility but the slow increase in the consumption share over time.

### 4(c) Best Adequate ARIMA Model for the Real Rate

For the proxy `rr_t = r_t − Δp_t`, the strongest adequate model in the search is a differenced ARIMA rather than a stationary level specification:

| Model for the real rate | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(7,1,5) | 474.05 | 523.79 | 0.9679 |

Key estimated coefficients include `φ₄ = 0.4564`, `φ₇ = −0.3841`, `θ₁ = 0.4736`, `θ₂ = −0.2673`, `θ₄ = −0.4045`, `θ₅ = −0.3704`, and `drift = 0.0015`.

This is the best adequate model because it offers the strongest information-criterion support among the adequate candidates while leaving no meaningful residual autocorrelation. That choice also fits the plot. The proxy inherits a substantial low-frequency component from the nominal interest rate, so first differencing removes the slow-moving level behaviour and the ARMA terms then pick up the remaining short-run persistence and reversal. The very high Ljung-Box p-value suggests that little residual autocorrelation is left behind.

### 4(d) Best Adequate ARIMA Model for the Consumption Ratio

A search over `d ∈ {0,1}` and `p, q = 0,...,6` was carried out using AIC, BIC, and residual diagnostics. Unlike the interest-rate series, the consumption ratio keeps trending upward through the sample, so differencing is the more convincing choice. The preferred model is:

| Model for the consumption ratio | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients: `φ₁ = 0.6092`, `φ₂ = −0.5732`, `φ₃ = 0.7553`, `θ₁ = −0.8316`, `θ₂ = 0.6862`, `θ₃ = −0.8547`, `drift = 0.0003`.

This is the best adequate model because it combines strong information-criterion support with acceptable residual diagnostics. First differencing is sensible here because the series does not fluctuate around a stable level. The small positive drift captures the average increase in the consumption share, while the AR and MA terms absorb the remaining short-run persistence.

### 4(e) Policy Use

A forecasting model for the real-rate proxy is useful because intertemporal decisions depend more on real rates than on nominal rates. From a monetary-policy perspective, the key question is whether the policy stance is likely to remain restrictive or accommodative in real terms. The ARIMA model helps because it captures the persistence and gradual adjustment in the proxy, which says something about how quickly real financing conditions are changing.

The consumption-ratio model is relevant for both monetary and fiscal policy as well. A rising consumption share points to strong household demand and a lower saving rate. For fiscal policy, that matters when thinking about how households might respond to taxes or transfers. For monetary policy, a high and rising consumption share may imply that households are more exposed to interest-rate movements.

---
## Question 5

### 5(a) Sample Variances

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

These sample variances estimate the unconditional variance of each return series and summarise average volatility over the full sample. A larger value means returns were more variable on average. The ranking is `SDR > USD > CNY > TWI`, so SDR is the most volatile series on average and TWI the least volatile.

Based on these variances alone, the safest conclusion is simply that TWI returns were the smoothest over the sample, while USD and SDR were the most variable. It is plausible to link TWI's low variance to the diversification of a basket index, and CNY's relatively low variance to a more managed exchange-rate environment, but those remain interpretations rather than findings established by the variance estimates themselves. What the statistics directly show is the average volatility ranking, not the underlying structural cause. Nor do they say anything about whether volatility is constant over time.

### 5(b) Absolute Returns

**Figure 9**

The plots of `|e_{j,t}|` show distinct clusters of low and high volatility, especially around March 2020 and again in later parts of the sample. Large absolute returns are followed by further large returns, while quiet periods also persist. That is the classic volatility-clustering pattern. The clearest common spike appears at the onset of COVID-19, when all four series jump sharply at the same time.

Such behaviour is not consistent with an iid constant-variance process. If returns were iid with constant variance, the absolute-return plots would not display these long bursts of activity. Instead, the evidence points to time-varying conditional volatility, which is exactly what GARCH-type models are designed to capture.

---

## Question 6

### Testing for GARCH Effects

Before fitting a variance model, the Engle ARCH LM test with 10 lags was applied to each return series to confirm that conditional variance is time-varying:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | p < 1e-15 | p < 1e-15 |
| USD | 275.60 | p < 1e-15 | p < 1e-15 |
| TWI | 484.45 | p < 1e-15 | p < 1e-15 |
| SDR | 426.45 | p < 1e-15 | p < 1e-15 |

Both tests reject homoskedasticity very strongly for every series. The p-values are written as `p < 1e-15` because they are numerically tiny rather than literally zero. On that evidence, a constant-variance model is clearly inadequate for all four currencies, and GARCH-type modelling is warranted.

### Mean Equation Selection

I first estimated a small ARMA grid for each return series to identify sensible low-order mean dynamics before modelling the conditional variance jointly. For USD, TWI, and SDR, the final GARCH specifications kept the same mean equations as that first-stage screen. CNY improved slightly once one additional MA term was included in the joint ARMA-GARCH estimation, so its final mean equation is `ARMA(2,3)` rather than the preliminary `ARMA(2,2)`.

- **CNY**: `ARMA(2,3)`
- **USD**: `ARMA(0,0)`
- **TWI**: `ARMA(1,0)`
- **SDR**: `ARMA(0,1)`

### Variance Model and Error Distribution

A broad range of `ARMA(p,q)-GARCH(p_sigma,q_sigma)` models was then estimated for each currency, allowing `p_sigma, q_sigma` up to 4 and considering Normal, Student-t, and skewed-Student-t errors. To stay as close as possible to the literal wording of the question, the final reported specifications are all symmetric `GARCH` models rather than asymmetric extensions. Model choice was based on three criteria taken together:

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

All of the fitted models imply persistent conditional volatility, since the ARCH and GARCH coefficients sum to values close to one. Even so, persistence remains below one in every selected specification. That matters because the models are rich enough to capture volatility clustering while still permitting the long-run variance calculations used in Question 7.

### Diagnostics and Volatility Plots

The residual checks for the selected models are summarised below:

| Currency | LB on Std. Residuals | LB on Sq. Std. Residuals |
|---|---:|---:|
| CNY | 0.0749 | 0.1857 |
| USD | 0.7008 | 0.0509 |
| TWI | 0.5560 | 0.2421 |
| SDR | 0.9189 | 0.1508 |

All four models pass the Ljung-Box check on the standardised residuals, so the mean equations look adequate. The squared-residual tests are also acceptable at the 5% level for all four currencies. TWI and SDR are comfortably adequate, and the revised CNY model is stronger than the earlier version. USD is still the most borderline case under a symmetric Normal GARCH restriction. I explored heavier-tailed symmetric alternatives, but while they improved AIC and BIC, they left much stronger residual ARCH effects. I also checked asymmetric specifications such as `gjrGARCH`, which improved the USD diagnostics further, but I have not reported them because the question is framed specifically in terms of `ARMA-GARCH`. On balance, the set reported above is my final set of best adequate `ARMA-GARCH` models. Under that restriction, `ARMA(0,0)-GARCH(3,3)` is still the most defensible USD choice.

**Figures 10-13**

All four conditional volatility series spike sharply around the COVID-19 episode in March 2020 and then decay only gradually. TWI is visibly the smoothest and least reactive series, whereas USD and SDR show the largest and most persistent volatility bursts. That lines up with the sample-variance evidence from Question 5 and supports the view that TWI is the most stable of the four exchange-rate return series.

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

All four persistence measures are below 1, so each currency has a finite unconditional variance. The persistence values are still high, especially for USD and SDR, which means volatility shocks die out slowly even though the long-run variance is well defined.

Comparing the model-implied variances with the sample variances from Question 5 is informative. For CNY and TWI, the unconditional variance is lower than the raw sample variance, which is consistent with temporary stress episodes pushing up sample volatility. For USD and SDR, the model-implied and sample variances are almost identical, suggesting that the estimated GARCH dynamics reproduce average volatility very closely. The overall ranking does not change: TWI remains the least volatile series, while USD and SDR remain the most volatile.

---

## Question 8

The probability that the daily return falls below the threshold of 0.01% on 13/01/2026 and 14/01/2026 is computed from the one-step-ahead and two-step-ahead forecasts of the final ARMA-GARCH models from Question 6. Returns are defined as `e_{j,t} = 100 × log(S_{j,t} / S_{j,t−1})`, so they are already in percentage units and the threshold 0.01% corresponds directly to the value 0.01. Because all four final models are estimated under Normal errors, the Normal CDF is used.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0046 | 0.4547 | 0.5128 | −0.0036 | 0.5036 | 0.5108 |
| USD | −0.0104 | 0.4739 | 0.5172 | −0.0104 | 0.5096 | 0.5160 |
| TWI | −0.0030 | 0.3953 | 0.5131 | −0.0029 | 0.4221 | 0.5122 |
| SDR | −0.0190 | 0.4939 | 0.5234 | −0.0050 | 0.4892 | 0.5122 |

All of these probabilities are above 0.5 because the threshold is close to zero and the forecast means are negative in every case. When the conditional mean lies below zero, more than half of the Normal forecast distribution will naturally fall below a threshold like 0.01%.

From a downside-risk perspective, a lower probability is better because it means a smaller chance of earning less than the 0.01% threshold. On **13 January 2026**, the ranking from least to most downside risk is CNY (0.5128), TWI (0.5131), USD (0.5172), and SDR (0.5234). On **14 January 2026**, the ranking is CNY (0.5108), TWI (0.5122), SDR (0.5122, marginally above TWI at full precision), and USD (0.5160).

That ranking depends on both the conditional mean and the conditional volatility. The revised CNY model now delivers the lowest downside-risk probability on both dates because its forecast mean is closer to zero than before while its forecast volatility stays moderate relative to USD and SDR. TWI still looks attractive because it has the lowest volatility, but once the full forecast distribution is taken into account, CNY edges ahead. The investment implication is clear: a risk-averse investor who wants to minimise the probability of falling below 0.01% would choose **CNY for both 13 January 2026 and 14 January 2026**. More broadly, this shows why conditional risk measures are more informative than unconditional sample variances alone. The preferred asset depends on the joint behaviour of the conditional mean and conditional variance, not just average sample volatility.
