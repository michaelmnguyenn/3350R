# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1**

**Figure 2**

The sample covers the USA from 1959Q1 to 2023Q4, giving 260 quarterly observations. The four series are the log price level `p_t = log(P_t)`, log real GDP per capita `y_t = log(Y_t)`, log real consumption `c_t = log(C_t)`, and the nominal 3-month T-bill rate `r_t`.

The main feature of the level plots in Figure 1 is that `p_t`, `y_t`, and `c_t` all have clear upward trends over the sample. Their means are not constant over time, so they do not appear covariance stationary in levels. `y_t` and `c_t` track each other closely throughout, which is expected given that output and consumption tend to share a common long-run growth path. `p_t` also trends upward but rises more steeply, particularly during the high-inflation period of the 1970s and early 1980s. `r_t` behaves differently. It does not follow a steady upward trend but moves through long persistent regimes: rising sharply into the early 1980s, declining over the following decades, sitting near zero through much of the 2010s, and then rising again after 2021. The dominant feature of `r_t` is this slow regime-switching persistence, not deterministic trend growth, so it should not be treated the same as the log-level macro variables.

Figure 2 shows the first differences. Once differenced, the upward drift in `p_t`, `y_t`, and `c_t` disappears and the series fluctuate around roughly stable means, which is more consistent with covariance stationarity. `Δp_t` is the most variable of the three, while `Δy_t` and `Δc_t` are less volatile and tend to move together. All three record large swings around the Global Financial Crisis and in 2020Q2, consistent with major aggregate shocks, but return to their long-run averages outside those episodes. Overall, the differenced plots support difference stationarity more than trend stationarity for these three series, consistent with `p_t`, `y_t`, and `c_t` being integrated of order one, I(1), processes with a stochastic trend.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.944853 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.429001 | 0.005305 | 0.000043 | 0.9834 |

The fitted trend regression for each series takes the form `x_t = μ + δt + ε_t`, where δ̂ represents the estimated average quarterly increase in the log level. For `p_t`, δ̂ = 0.010125 implies average quarterly price growth of about 1.01%, or roughly 4.1% per year. For `y_t` and `c_t`, the estimates of 0.004757 and 0.005305 imply average quarterly real growth rates of about 0.48% and 0.53% respectively. All three trend coefficients are precisely estimated with very small standard errors, and R² values above 0.94 confirm that a linear time trend captures most of the long-run variation in each log level.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

The mean of `Δp_t` at 0.009310 implies average quarterly inflation of about 0.93%, or roughly 3.8% per year. The means of `Δy_t` (0.004919) and `Δc_t` (0.005379) imply average quarterly real growth rates of about 0.49% and 0.54% respectively.

### 1(b)(iii) Rationale and Comparison

The rationale for estimating both δ̂ and μ̂ is to assess the nature of the trend in each log-level series. The trend coefficient δ̂ represents the average quarterly increase in the log level and is the more appropriate measure if the series follows a deterministic trend. The mean μ̂ represents the average of the first-differenced series and is appropriate if the series is difference-stationary with a stable drift. Comparing the two provides informal evidence about which characterisation fits before committing to a modelling approach. Both estimates represent percentage growth, so a value of 0.009310 implies growth of 0.93% per quarter.

For `y_t`, the trend coefficient is 0.004757 and the mean of `Δy_t` is 0.004919. For `c_t`, the corresponding values are 0.005305 and 0.005379. In both cases the two estimates are very close, which is what you would expect if these series are difference-stationary with a roughly constant drift — the OLS trend coefficient and the mean of first differences both converge to the same underlying average growth rate. For `p_t`, the gap is slightly larger: δ̂ = 0.010125 versus μ̂ = 0.009310. This reflects the fact that the price level did not follow a perfectly linear trend over the sample. The high-inflation 1970s and the subsequent disinflation pull the OLS slope above the simple average of quarterly changes.

Overall, the close match for `y_t` and `c_t` is consistent with difference-stationary behaviour with stable drift. This comparison is not a formal unit-root test and cannot by itself determine whether the series are I(1) or trend-stationary, but it should be treated as descriptive evidence rather than proof of difference stationarity, and it supports modelling the differenced series using ARIMA methods in the exercises that follow.

---

## Question 2

### 2(a) Model Selection

ARIMA(p,d,q) models were estimated for `Δp_t` and `r_t` over 1959Q1–2023Q4, searching `p, q = 0,...,10` and screening candidates using AIC, BIC, and the Ljung-Box test. A model was retained as adequate if the Ljung-Box test p-value exceeded 0.05, indicating no statistically significant remaining serial correlation in the residuals.

For `Δp_t`, because it is already the first log difference of the price level and appears stationary around a positive mean, `d = 0` was set throughout and a mean/intercept was included in all specifications. The sample mean of `Δp_t` is about 0.0093 per quarter. Omitting an intercept would force long-run forecasts toward zero rather than toward this historical average, which is economically incorrect given that inflation has been persistently positive. A deterministic time trend was not included: the differenced series fluctuates around a stable level with no systematic upward or downward drift visible in the plot.

For `r_t`, the level series shows persistent slow adjustment that could reflect either high autocorrelation in a stationary process or an integrated process. Both `d = 0` and `d = 1` specifications were searched, including a mean for `d = 0` and a drift for `d = 1`, without a deterministic time trend in either case. The top adequate models all have `d = 0`, which is consistent with the nominal rate being a highly persistent but mean-reverting level series over this sample, rather than one that requires differencing.

**Inflation** (`Δp_t`): The three best adequate inflation models, ranked by AIC and passing the Ljung-Box screen, are:

| Inflation model | Constant | Trend | AIC | BIC | Ljung-Box p-value (lag 20) |
|---|:---:|:---:|---:|---:|---:|
| ARIMA(3,0,3) | Yes | No | −2686.38 | −2657.92 | 0.1163 |
| ARIMA(1,0,6) | Yes | No | −2685.30 | −2653.28 | 0.1445 |
| ARIMA(5,0,6) | Yes | No | −2685.21 | −2638.97 | 0.1242 |

ARIMA(3,0,3) is the preferred specification because it has the lowest AIC and BIC in the adequate set and a Ljung-Box p-value of 0.1163, well above the 0.05 threshold. ARIMA(1,0,6) and ARIMA(5,0,6) are close alternatives, and all three are relatively high-order, reflecting the persistent serial dependence in quarterly inflation.

**Interest rates** (`r_t`): Searching both `d = 0` and `d = 1`, the three best adequate models are all level specifications:

| Interest rate model | Constant | Trend | AIC | BIC | Ljung-Box p-value (lag 20) |
|---|:---:|:---:|---:|---:|---:|
| ARIMA(4,0,6) | Yes | No | 477.47 | 520.19 | 0.4708 |
| ARIMA(8,0,1) | Yes | No | 478.25 | 517.41 | 0.7561 |
| ARIMA(9,0,1) | Yes | No | 478.90 | 521.63 | 0.7539 |

ARIMA(4,0,6) is the best adequate model by AIC. The dominance of `d = 0` specifications confirms that the nominal rate is best modelled as highly persistent but not requiring differencing over this sample. Since part (b) asks only for inflation forecasts, the `r_t` models complete the selection exercise rather than generate a separate forecast.

### 2(b) Inflation Forecasts for 2024–2025

**Figure 3**

| Quarter | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) | 68% CI Lower | 68% CI Upper | 95% CI Lower | 95% CI Upper |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2024Q1 | 0.007979 | 0.008012 | 0.008083 | 0.006696 | 0.009262 | 0.005450 | 0.010508 |
| 2024Q2 | 0.006826 | 0.006823 | 0.007218 | 0.004498 | 0.009154 | 0.002237 | 0.011414 |
| 2024Q3 | 0.006560 | 0.006668 | 0.007178 | 0.003233 | 0.009887 | 0.000003 | 0.013118 |
| 2024Q4 | 0.005810 | 0.005938 | 0.006231 | 0.001318 | 0.010301 | −0.003043 | 0.014662 |
| 2025Q1 | 0.006044 | 0.006499 | 0.006550 | 0.001045 | 0.011043 | −0.003809 | 0.015896 |
| 2025Q2 | 0.006890 | 0.007412 | 0.006822 | 0.001476 | 0.012304 | −0.003780 | 0.017561 |
| 2025Q3 | 0.007372 | 0.008069 | 0.007111 | 0.001519 | 0.013225 | −0.004164 | 0.018908 |
| 2025Q4 | 0.007710 | 0.008331 | 0.007326 | 0.001534 | 0.013886 | −0.004463 | 0.019883 |

Values are quarterly log inflation rates; multiply by 100 for approximate quarterly percentages (e.g., 0.007979 ≈ 0.80% per quarter). Figure 3 plots recent observed values of `Δp_t` together with the three forecast paths and the 68% and 95% intervals for ARIMA(3,0,3). All three models project inflation declining from about 0.80% in 2024Q1 to roughly 0.58%–0.72% by 2024Q4, before partially recovering. This near-term decline reflects reversion toward the estimated model mean, which is lower than the most recent in-sample inflation levels. The 95% interval for ARIMA(3,0,3) widens from 0.5450%–1.051% in 2024Q1 to −0.446%–1.988% by 2025Q4, showing substantial uncertainty at the 8-quarter horizon.

### 2(c) Policy Use and Forecast Uncertainty

These inflation forecasts may be useful for policy because monetary and fiscal decisions must be made before realised data are available. Central banks set interest rates based on expected inflation, and fiscal authorities use expected inflation to estimate the real value of tax revenues, transfer payments, and government debt. Because these decisions are forward-looking, model-based forecasts provide a structured starting point even when uncertainty is large.

There are three main sources of uncertainty. The first is innovation uncertainty: future shocks are unknown, so forecast error variance grows with the horizon. For ARIMA(3,0,3), the 95% interval nearly quadruples in width from about 0.55 percentage points in 2024Q1 to about 2.43 percentage points by 2025Q4. This widening is a built-in property of ARIMA forecasts, not a feature specific to the data. The second source is model uncertainty. The three adequate specifications do not produce the same forecast path; in 2024Q4, the spread across models is about 0.04 percentage points. The reported confidence bands are conditional on each single model being correctly specified, so the true uncertainty across models is wider than the intervals imply. The third source is parameter and regime uncertainty. The estimated coefficients may not remain stable if inflation dynamics shift after a supply shock or a major change in monetary policy, and in that case the model-based forecasts could understate true uncertainty.

Overall, these forecasts are still useful, but not as mechanical policy rules. The 68% and 95% bands summarise conditional forecast uncertainty, but policymakers should also consider model choice, coefficient stability, and possible regime changes.

---

## Question 3

**Figures 4–6**

Actual quarterly inflation for 2024Q1–2025Q3 is computed as `Δp_t = log(P_t) − log(P_{t−1})`, using `P_{2023Q4}` as the last in-sample observation. Each of Figures 4–6 overlays the realised path against one model's forecast, together with the 68% and 95% forecast intervals.

| Quarter | Actual `Δp_t` | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) |
|---|---:|---:|---:|---:|
| 2024Q1 | 0.007964 | 0.007979 | 0.008012 | 0.008083 |
| 2024Q2 | 0.008313 | 0.006826 | 0.006823 | 0.007218 |
| 2024Q3 | 0.007613 | 0.006560 | 0.006668 | 0.007178 |
| 2024Q4 | 0.006339 | 0.005810 | 0.005938 | 0.006231 |
| 2025Q1 | 0.007146 | 0.006044 | 0.006499 | 0.006550 |
| 2025Q2 | 0.006288 | 0.006890 | 0.007412 | 0.006822 |
| 2025Q3 | 0.006477 | 0.007372 | 0.008069 | 0.007111 |

| Model | MSFE | RMSFE | MAE |
|---|---:|---:|---:|
| ARIMA(3,0,3) | 8.5454e−07 | 0.000924 | 0.000812 |
| ARIMA(1,0,6) | 1.0708e−06 | 0.001035 | 0.000892 |
| ARIMA(5,0,6) | 3.5118e−07 | 0.000593 | 0.000503 |

All three models under-predict inflation in 2024Q2 through 2025Q1. Actual inflation in those quarters stayed between 0.63% and 0.83%, while the model forecasts had already projected a decline to roughly 0.58%–0.72%. In other words, inflation fell more slowly than expected. From 2025Q2 onward the pattern reverses: actual inflation drops to about 0.63%–0.65%, now sitting below all three forecast paths of 0.68%–0.81%.

The relative forecast performance ranks ARIMA(5,0,6) first, ARIMA(3,0,3) second, and ARIMA(1,0,6) third across all three metrics. ARIMA(5,0,6) achieves an RMSFE of 0.000593, or about 0.06 percentage points per quarter. ARIMA(3,0,3) had the best in-sample AIC and BIC, but performs worse out of sample. This divergence between in-sample and out-of-sample ranking is common: a model that fits historical persistence well may still mistime the turning points in the forecast period. All three models use the same historical pattern of inflation persistence, and all three err in a similar direction, suggesting the mismatch is not specific to any one specification but reflects a shared persistence problem — possibly a regime shift — that is common to all three.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 7**

The real interest rate proxy is defined as:

`rr_t = r_t − 100 × Δp_t`

Following the question's definition `rr_t = r_t − Δp_t`, and noting that `r_t` is measured in annualised percentage points while `Δp_t` is a quarterly log difference in decimal form (approximately 0.009 per quarter), multiplying `Δp_t` by 100 puts both terms in comparable units. Without this scaling, the inflation adjustment would be negligible relative to the nominal rate and the resulting series would be effectively indistinguishable from `r_t`. Over the sample, `rr_t` has a mean of about 3.42 percentage points, a minimum of about −1.74, and a maximum of about 12.40.

Figure 7 compares `rr_t` with `r_t` and `Δp_t` on its own scale. This layout is used because `Δp_t` is much smaller than the interest-rate series, so plotting all three on one axis would hide inflation. The real rate retains the dominant low-frequency pattern of `r_t`: the build-up into the early 1980s, the prolonged decline thereafter, near-zero levels through the 2010s, and the rise after 2021. Subtracting inflation has a visible but limited effect. During the high-inflation periods of the 1970s and early 1980s, `rr_t` falls well below `r_t`, capturing the well-known episode of strongly negative real rates when inflation exceeded the nominal rate. When inflation is low, the gap narrows. In terms of stability, `rr_t` is far less stable than inflation and slightly more stable than the nominal rate, with a standard deviation of about 2.71 compared with about 3.14 for `r_t`.

### 4(b) Consumption Ratio

**Figure 8**

The consumption ratio is:

`cy_t = C_t/Y_t`

The dominant feature of the data is a long-run upward drift. Figure 8 shows `cy_t` rising from about 0.590 early in the sample to about 0.693 by 2023Q4, with relatively small short-run fluctuations around that upward path. The series does not show a clear level mean or revert to a fixed value; it climbs gradually and persistently over the full sample. This upward drift is slow and should not be confused with short-run volatility.

Economically, this indicates that consumption has grown faster than output over the period, so household spending accounts for a rising share of GDP. This is consistent with structural factors including demographic change, persistent trade deficits that allow domestic spending to exceed domestic production, and shifts in the composition of economic activity toward consumer services. The key feature for modelling is this upward trend: it must be accounted for explicitly in any ARIMA specification.

### 4(c) Best Adequate ARIMA Model for the Real Rate

For `rr_t`, ARIMA models were searched over `p, q = 0,...,10` and `d ∈ {0,1}`, with and without deterministic terms. Models were ranked by AIC and BIC and screened using Ljung-Box residual tests. The choice of `d` was guided by Augmented Dickey-Fuller (ADF) tests: the null of a unit root in the level of `rr_t` cannot be rejected at the 5% level, while the null is rejected for the first difference, supporting `d = 1`. The best adequate model under both AIC and BIC is a differenced specification with no constant or trend:

| Model for the real rate | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(7,1,1) | 460.64 | 492.62 | 0.9883 |

Key estimated coefficients: `φ₁ = −0.3903`, `φ₂ = −0.0436`, `φ₃ = 0.0139`, `φ₄ = 0.1161`, `φ₅ = −0.0069`, `φ₆ = 0.0618`, `φ₇ = −0.3217`, and `θ₁ = 0.8640`.

This model is selected because it has the lowest AIC and BIC among adequate candidates and a Ljung-Box p-value of 0.9883 at lag 20, indicating no meaningful remaining residual autocorrelation. The choice of `d = 1` is consistent with the plot: `rr_t` inherits the slow-moving level shifts of the nominal rate, and first differencing removes this persistent low-frequency behaviour. The multiple AR terms and the MA term then capture the remaining short-run dynamics in the differenced series. The high AR order should be interpreted cautiously, but it is defensible because the diagnostic evidence indicates that the remaining short-run dynamics have been absorbed. The absence of a drift term indicates that changes in the real rate fluctuate around zero with no systematic trend.

### 4(d) Best Adequate ARIMA Model for the Consumption Ratio

A search over `d ∈ {0,1}`, `p, q = 0,...,6`, and deterministic terms was carried out using AIC, BIC, and residual diagnostics. ADF tests with a trend included reject the null of a unit root for `cy_t` at the 5% level, supporting `d = 0` with a deterministic trend over a differenced specification. The preferred model treats the upward trend as deterministic rather than stochastic:

| Model for the consumption ratio | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,0,2) with constant and trend | −2146.13 | −2117.65 | 0.9799 |

Key estimated coefficients: `φ₁ = 0.6052`, `φ₂ = −0.5779`, `φ₃ = 0.7483`, `θ₁ = 0.1658`, `θ₂ = 0.8558`, `intercept = 0.5975`, and `trend = 0.0003`.

This model is preferred over the best `d = 1` alternative, ARIMA(3,1,3) with AIC −2135.65, because it fits significantly better, with the AIC about 10 units lower. The positive trend coefficient of 0.0003 captures the average quarterly increase in the consumption share, starting from an intercept of about 0.5975. The three AR and two MA terms absorb the remaining serial dependence around that deterministic trend path, and the model passes all residual checks comfortably. Economically, the deterministic trend interpretation is plausible here because the upward drift in `cy_t` is smooth and persistent, consistent with a gradual structural shift in the consumption share rather than random-walk behaviour.

### 4(e) Policy Use

The real-rate model captures the persistent adjustment dynamics in `rr_t` and is useful for monetary policy analysis because real borrowing costs drive investment and consumption decisions more directly than nominal rates. An ARIMA model for `rr_t` can help assess whether the current real rate sits above or below historical norms and how quickly any deviation is likely to unwind, which informs judgements about the stance of monetary policy.

The consumption-ratio model is relevant for both fiscal and monetary policy. A rising `cy_t` implies that household spending is taking up a larger share of output. For fiscal authorities, this matters when designing tax structures and thinking about the multiplier effects of transfers. For monetary authorities, a high consumption share means that interest rate changes transmit more directly to aggregate demand through household spending.

---

## Question 5

### 5(a) Sample Variances

Daily returns are defined as:

`e_{j,t} = 100 × [log(E_{j,t}) − log(E_{j,t−1})]`

for `j ∈ {CNY, USD, TWI, SDR}`. The sample variances of these return series are:

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

Overall, SDR is the most volatile series on average, followed by USD, CNY and then TWI (SDR > USD > CNY > TWI). SDR has the largest variance at 0.4492, implying a daily standard deviation of about 0.67%. USD is very close behind at 0.4381 and standard deviation about 0.66%. CNY has variance 0.3369 and standard deviation about 0.58%; its relatively lower unconditional volatility is consistent with a more managed exchange-rate regime, although the variance alone does not establish that mechanism. TWI has the smallest variance at 0.2675, which is consistent with a trade-weighted basket index being more diversified than a single bilateral rate.

These sample variances are informative about overall long-run dispersion, but computing a single variance implicitly assumes that returns are independently and identically distributed with constant variance across the full sample. If this assumption fails — that is, if volatility varies over time — the sample variance does not adequately summarise the risk of each exchange rate process and is insufficient for short-run risk management. Whether this constancy assumption holds is examined in Question 5(b).

### 5(b) Absolute Returns

**Figure 9**

Figure 9 plots the absolute value of daily returns `|e_{j,t}|` for all four currencies and provides visual evidence about whether volatility is constant. Several patterns stand out.

In all four series, the plots indicate clear volatility clustering. Large absolute returns tend to cluster together in time, and quiet periods also cluster. This means the probability of observing a large return tomorrow is higher after a large return today than after a small one, which is directly inconsistent with an i.i.d. process. There is also a common spike across all four currencies around March 2020, reflecting the global market shock at the onset of the COVID-19 pandemic. This simultaneous jump illustrates that exchange-rate volatility across these currencies is correlated during episodes of global stress.

The clustering episodes also decay slowly rather than reverting instantly after spikes, indicating that shocks to volatility are persistent and that conditional variance is time-varying. An i.i.d. process with constant variance would not display this kind of persistence; the absolute return plot would not show these prolonged clusters of activity. These features together — clustering, common shocks, and slow decay — confirm that a constant-variance ARMA model would misrepresent the data generating process and that a GARCH-type model for the conditional variance is necessary for all four series.

---

## Question 6

### ARMA Models for Exchange-Rate Returns

Before estimating GARCH models, each exchange-rate return series was first modelled with a stationary ARMA model (`d = 0`), since the return series are already approximately stationary. This preliminary step identifies adequate mean dynamics under the assumption of constant variance, with the squared residuals then used to test for ARCH effects. If ARCH effects are found, the model is re-specified as a joint ARMA-GARCH.

| Exchange-rate return | Selected ARMA model | AIC | BIC | Ljung-Box p-value |
|---|---|---:|---:|---:|
| CNY | ARMA(2,3) | 3521.9585 | 3561.2171 | 0.0835 |
| USD | ARMA(1,0) | 4054.6928 | 4071.5180 | 0.1636 |
| TWI | ARMA(1,3) | 3046.5350 | 3080.1852 | 0.1260 |
| SDR | ARMA(0,1) | 4010.0371 | 4026.8623 | 0.3243 |

All four models pass the Ljung-Box test at the 5% level. CNY requires a relatively high-order specification, which reflects its more complex mean dynamics, possibly related to managed exchange-rate adjustments. USD is best described as an AR(1), consistent with mild persistence in the return process. TWI requires AR(1) and MA(3) terms to clear the residual autocorrelation. SDR is adequately described by a single MA term.

### Testing for ARCH Effects

The Engle ARCH LM test and the Ljung-Box test on squared ARMA residuals were applied at lags 1 through 10. Both tests assess whether the squared residuals exhibit serial correlation, which would indicate time-varying conditional variance. The results are:

| Currency | LM (lag 1) | LM (lag 5) | LM (lag 10) | p-value (all lags) |
|---|---:|---:|---:|---:|
| CNY | 229.93 | 289.42 | 293.54 | p < 2.22e−16 |
| USD | 166.18 | 224.62 | 232.36 | p < 2.22e−16 |
| TWI | 262.01 | 345.00 | 346.64 | p < 2.22e−16 |
| SDR | 126.65 | 172.26 | 200.90 | p < 2.22e−16 |

The null hypothesis of no ARCH effects is rejected at every lag for every currency, with p-values numerically indistinguishable from zero. The ARMA models adequately handle the conditional mean but constant variance is overwhelmingly rejected. This confirms the visual evidence from Figure 9 and establishes that a GARCH model for the conditional variance is necessary for all four series.

### ARMA-GARCH Models

A grid of ARMA(p,q)-GARCH(pσ,qσ) specifications was estimated for each currency using symmetric Normal GARCH errors, with the mean and variance equations estimated jointly. Joint estimation matters because the conditional mean and conditional variance interact — specifying them separately and then combining can produce inconsistent parameter estimates. The grid searched ARMA orders p, q ∈ {0,1,2} and GARCH orders pσ, qσ ∈ {0,1,2} for each currency.

In the joint estimation, the mean equations all converge to ARMA(2,2). This differs from the preliminary ARMA-only step because once the variance dynamics are correctly modelled, the optimal mean specification can change. The variance equations differ across currencies, reflecting different volatility dynamics.

| Currency | Mean Model | Variance Model | Errors | AIC | BIC |
|---|---|---|---|---:|---:|
| CNY | ARMA(2,2) | GARCH(2,2) | Normal | 1.5553 | 1.5803 |
| USD | ARMA(2,2) | GARCH(2,2) | Normal | 1.8352 | 1.8631 |
| TWI | ARMA(2,2) | GARCH(2,2) | Normal | 1.3109 | 1.3387 |
| SDR | ARMA(2,2) | GARCH(2,1) | Normal | 1.8222 | 1.8472 |

Key estimated coefficients:

| Currency | `μ` | AR terms | MA terms | `ω` | ARCH terms | GARCH terms |
|---|---:|---:|---:|---:|---:|---:|
| CNY | none | `φ₁ = 1.9227`, `φ₂ = −0.9236` | `θ₁ = −1.9479`, `θ₂ = 0.9478` | 0.0291 | `α₁ = 0.1383`, `α₂ = 0.0000` | `β₁ = 0.3129`, `β₂ = 0.4542` |
| USD | 0.0010 | `φ₁ = 1.9453`, `φ₂ = −0.9456` | `θ₁ = −1.9583`, `θ₂ = 0.9582` | 0.0150 | `α₁ = 0.1285`, `α₂ = 0.0000` | `β₁ = 0.2290`, `β₂ = 0.6108` |
| TWI | −0.0031 | `φ₁ = −1.0838`, `φ₂ = −0.9944` | `θ₁ = 1.0852`, `θ₂ = 0.9879` | 0.0232 | `α₁ = 0.1574`, `α₂ = 0.0000` | `β₁ = 0.2240`, `β₂ = 0.5215` |
| SDR | −0.0015 | `φ₁ = 1.1926`, `φ₂ = −0.2079` | `θ₁ = −1.3733`, `θ₂ = 0.3713` | 0.0161 | `α₁ = 0.1240` | `β₁ = 0.2688`, `β₂ = 0.5680` |

The estimated models written out in full are:

**CNY — ARMA(2,2)-GARCH(2,2):**
`e_{CNY,t} = 1.9227 e_{CNY,t-1} − 0.9236 e_{CNY,t-2} − 1.9479 ε_{CNY,t-1} + 0.9478 ε_{CNY,t-2} + ε_{CNY,t}`
`σ²_{CNY,t} = 0.0291 + 0.1383 ε²_{CNY,t-1} + 0.3129 σ²_{CNY,t-1} + 0.4542 σ²_{CNY,t-2}`

**USD — ARMA(2,2)-GARCH(2,2):**
`e_{USD,t} = 0.0010 + 1.9453 e_{USD,t-1} − 0.9456 e_{USD,t-2} − 1.9583 ε_{USD,t-1} + 0.9582 ε_{USD,t-2} + ε_{USD,t}`
`σ²_{USD,t} = 0.0150 + 0.1285 ε²_{USD,t-1} + 0.2290 σ²_{USD,t-1} + 0.6108 σ²_{USD,t-2}`

**TWI — ARMA(2,2)-GARCH(2,2):**
`e_{TWI,t} = −0.0031 − 1.0838 e_{TWI,t-1} − 0.9944 e_{TWI,t-2} + 1.0852 ε_{TWI,t-1} + 0.9879 ε_{TWI,t-2} + ε_{TWI,t}`
`σ²_{TWI,t} = 0.0232 + 0.1574 ε²_{TWI,t-1} + 0.2240 σ²_{TWI,t-1} + 0.5215 σ²_{TWI,t-2}`

**SDR — ARMA(2,2)-GARCH(2,1):**
`e_{SDR,t} = −0.0015 + 1.1926 e_{SDR,t-1} − 0.2079 e_{SDR,t-2} − 1.3733 ε_{SDR,t-1} + 0.3713 ε_{SDR,t-2} + ε_{SDR,t}`
`σ²_{SDR,t} = 0.0161 + 0.1240 ε²_{SDR,t-1} + 0.2688 σ²_{SDR,t-1} + 0.5680 σ²_{SDR,t-2}`

The persistence sum (Σα + Σβ) for each currency is: CNY = 0.9054, USD = 0.9683, TWI = 0.9030, SDR = 0.9608. All persistence sums are below one, which is required for the unconditional variance to exist. They are all close to one, however, meaning that shocks to volatility decay slowly. A shock that doubles today's conditional variance will still have meaningful effects on variance several weeks later.

### Diagnostics and Volatility Plots

Ljung-Box results on the standardised residuals and squared standardised residuals confirm whether the GARCH models have adequately captured the mean and variance dynamics:

| Currency | LB on Std. Residuals | LB on Sq. Std. Residuals |
|---|---:|---:|
| CNY | 0.2091 | 0.0096 |
| USD | 0.4159 | 0.0833 |
| TWI | 0.2583 | 0.0879 |
| SDR | 0.1256 | 0.0058 |

The standardised residual tests are all well above 0.05, confirming that the ARMA mean equations have removed the serial correlation in returns. The squared standardised residual tests provide direct evidence on whether autocorrelation in squared standardised residuals remains after GARCH estimation — that is, whether any ARCH structure is left unexplained. USD and TWI pass at p = 0.0833 and 0.0879, indicating no statistically significant remaining variance dependence; these models are fully adequate. CNY (p = 0.0096) and SDR (p = 0.0058) fail this test, indicating that some variance autocorrelation persists and the GARCH specification has not fully captured the dynamics for these two currencies.

No symmetric GARCH(p,q) model within the p,q ∈ {0,1,2} search grid eliminates this residual structure for CNY or SDR. The reported ARMA(2,2)-GARCH(2,2) for CNY and ARMA(2,2)-GARCH(2,1) for SDR are therefore the best available models under the symmetric Normal GARCH framework: they minimise AIC and BIC and remove all mean autocorrelation, but the remaining variance autocorrelation suggests that a higher-order or asymmetric specification such as GJR-GARCH would be needed for full adequacy. This limitation is noted and the results for these two currencies should be interpreted with appropriate caution.

**Figures 10–13**

Figures 10–13 plot the estimated conditional volatility for each currency over the sample. All four series show the volatility clustering and persistence evident in the absolute-return plots of Figure 9. The clearest common feature is the sharp volatility spike in early 2020, consistent with the COVID-19 disruption. Following that spike, conditional volatility decays gradually in all four series, consistent with the high but sub-unit persistence parameters estimated above. TWI shows the smoothest volatility path, consistent with its lower unconditional variance, while USD and SDR show the largest and most reactive bursts.

---

## Question 7

For the symmetric GARCH models selected in Question 6, the unconditional variance exists when the variance process is covariance stationary, which requires:

`Σα_i + Σβ_i < 1`

When this condition holds, the long-run unconditional variance is:

`σ_j² = ω / (1 − Σα_i − Σβ_i)`

This formula follows from the expected conditional variance in the stationary GARCH process. If the persistence sum equals or exceeds one, the denominator is zero or negative and the formula breaks down: the process is integrated in variance, meaning shocks to volatility do not die out and no finite long-run variance exists.

Applying this formula to each fitted model:

| Currency | ω | α₁ | α₂ | β₁ | β₂ | α + β | Uncond. Variance |
|---|---:|---:|---:|---:|---:|---:|---:|
| CNY | 0.0291 | 0.1383 | 0.0000 | 0.3129 | 0.4542 | 0.9054 | 0.3081 |
| USD | 0.0150 | 0.1285 | 0.0000 | 0.2290 | 0.6108 | 0.9683 | 0.4725 |
| TWI | 0.0232 | 0.1574 | 0.0000 | 0.2240 | 0.5215 | 0.9030 | 0.2393 |
| SDR | 0.0161 | 0.1240 | − | 0.2688 | 0.5680 | 0.9608 | 0.4110 |

Although persistence values are still high — above 0.90 for all four currencies — it remains possible to calculate the unconditional variance because none reach 1. This suggests that volatility shocks decay slowly but do eventually dissipate. If persistence were >= 1, this unconditional variance would not exist as the GARCH process would be non-stationary in variance and the formula would be undefined. USD and SDR have the highest persistence at 0.9683 and 0.9608 respectively, meaning conditional variance for these two series reverts to the long-run level particularly slowly after a shock. CNY and TWI sit somewhat lower at 0.9054 and 0.9030.

The GARCH-implied unconditional variances are close to the sample variances from Question 5. The volatility rankings remained the same: TWI is still the least volatile with a model variance of 0.2393 versus a sample variance of 0.2675, while SDR and USD remain the most volatile. The slight differences between model-implied and sample variances are expected — the GARCH model focuses on the conditional distribution and weights periods of high and low volatility differently, while the sample variance treats all observations equally. Neither measure is wrong; they answer different questions about the same process.

---

## Question 8

Question 8 asks for the probability that each currency's daily return falls below 0.01% on 13 January 2026 and 14 January 2026. Since returns are defined as `e_{j,t} = 100 × [log(E_{j,t}) − log(E_{j,t−1})]`, a 0.01% daily change corresponds to `e = 0.01` in these units. Given that the ARMA-GARCH models use Normal errors, the forecast distribution at each horizon is Normal with conditional mean `μ_{T+h}` and conditional standard deviation `σ_{T+h}`. The probability is:

`P(e_{j,T+h} < 0.01) = Φ((0.01 − μ_{T+h}) / σ_{T+h})`

where `Φ` is the standard Normal CDF, `μ_{T+h}` is the h-step-ahead conditional mean, and `σ_{T+h}` is the h-step-ahead conditional standard deviation from the ARMA-GARCH model.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0121 | 0.4946 | 0.5178 | −0.0118 | 0.5004 | 0.5174 |
| USD | −0.0025 | 0.4931 | 0.5101 | −0.0023 | 0.4844 | 0.5101 |
| TWI | −0.0543 | 0.4005 | 0.5638 | −0.0014 | 0.4075 | 0.5112 |
| SDR | −0.0136 | 0.4675 | 0.5201 | −0.0098 | 0.4704 | 0.5168 |

The table shows that the probabilities of a return below 0.01% remain above 0.5 for all currencies on both days. This is because the forecast means are negative for all four currencies on both dates, placing more than half of each Normal forecast distribution below a near-zero threshold like 0.01%.

For risk management, a lower probability is preferred as it implies a smaller chance of earning less than 0.01%. On 13 January 2026, the ranking from lowest to highest downside risk is USD (0.5101), CNY (0.5178), SDR (0.5201), and TWI (0.5638). On 14 January 2026, the ranking shifts to USD (0.5101), TWI (0.5112), SDR (0.5168), and CNY (0.5174).

**USD is the preferred currency on both days** under this criterion. Its conditional mean on day 1 is only −0.0025, close to zero, so relatively little of its forecast distribution falls below 0.01. TWI presents a striking contrast between the two dates: on day 1 its conditional mean is −0.0543, the most negative of all four currencies, which pushes its downside probability to 0.5638. By day 2, the conditional mean reverts sharply to −0.0014 and the probability drops to 0.5112, making TWI the second-best choice. This large swing reflects how quickly the GARCH conditional mean can adjust once a large recent return dissipates from the forecast.

The ranking depends on the specific GARCH specification estimated. Different GARCH models fitted to the same data can produce different conditional mean forecasts, particularly at the multi-step horizon. This is a concrete example of the model uncertainty discussed in Question 2(c): the risk ranking for a specific short horizon depends on the jointly estimated ARMA-GARCH conditional mean and variance, not just the unconditional sample variance. TWI has the lowest unconditional variance in Question 7, yet it has the highest downside risk on day 1 precisely because its conditional mean at that forecast date is far more negative than any other currency. This shows why short-horizon conditional risk measures are more informative than long-run averages for day-to-day trading or risk management decisions.
