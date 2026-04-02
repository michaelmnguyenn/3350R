# ECON3350 Research Report 1

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1: `fig1_log_levels.png`**

**Figure 2: `fig2_log_diffs.png`**

The quarterly time-series cover macroeconomic indicators for the USA over 1959Q1–2023Q4 (260 observations). The dataset contains the log price level (`p_t`), log real GDP per capita (`y_t`), log real consumption (`c_t`), and the nominal 3-month T-bill rate (`r_t`).

Looking at the log-level plots, all three series — `p_t`, `y_t`, and `c_t` — show a pronounced upward trend throughout the sample. The means of these series are clearly not constant over time, which is the defining feature of a non-stationary process. The price index grows particularly fast through the 1970s and early 1980s during the high-inflation episode, while real GDP and real consumption rise more steadily and track each other closely, with visible dips around major recessions.

Once the logged series are first-differenced, the trend is removed and all three growth-rate series — `Δp_t`, `Δy_t`, `Δc_t` — fluctuate around a roughly constant mean. This pattern is consistent with a difference-stationary process, or I(1) behaviour, where shocks accumulate in levels but not in differences. The implication is that the trend in `p_t`, `y_t`, and `c_t` is most likely stochastic rather than purely deterministic.

The nominal interest rate `r_t` behaves differently from the differenced series. It rises sharply from the 1960s into the Volcker tightening period around 1980, then drifts gradually lower over several decades, falls near zero following the Global Financial Crisis, and climbs again from 2022 as monetary policy tightened. This prolonged cycling between very different rate regimes — with shocks appearing to accumulate rather than dissipate — is consistent with a stochastic process and suggests strong low-frequency autocorrelation.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.945124 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.428678 | 0.005305 | 0.000043 | 0.9834 |

All three trend slope estimates are statistically significant and economically meaningful. The high R² values confirm that a linear time trend accounts for most of the long-run variation in each log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Why Estimate Both?

The purpose of both exercises is to characterise the underlying growth behaviour of each series and to determine whether that growth is better described by a deterministic trend or by the average of accumulated changes over time.

In a random-walk-with-drift model, the drift parameter is exactly the average period-to-period change. Regressing the log level on a time trend estimates that same average growth through the slope coefficient δ̂, while the sample mean of first differences μ̂ estimates it directly. Both are therefore trying to capture the same quantity — the typical quarterly growth rate.

The two estimates are indeed very similar: for `y_t`, `δ̂ = 0.004757` versus `μ̂ = 0.004919`; for `c_t`, `δ̂ = 0.005305` versus `μ̂ = 0.005379`. The similarity suggests both approaches are capturing a consistent long-run growth pattern. The price series shows the largest gap (`δ̂ = 0.010125` versus `μ̂ = 0.009310`) because inflation was not stable across the full sample — the high-inflation 1970s and the subsequent disinflation distort a single linear trend more than they distort the average of quarterly changes.

It is worth noting that close agreement between δ̂ and μ̂ is consistent with I(1) behaviour: when the trend is stochastic, the average growth rate in levels and the mean of differences should converge to the same value. This comparison alone cannot substitute for a formal unit root test, but it does provide intuitive support for treating these series as non-stationary in levels and stationary in first differences.

---

## Question 2

### Model Selection Logic

For inflation, the relevant object is `Δp_t`, not the price level. The ADF test on `Δp_t` gives its strongest evidence against a unit root at lag 3 in the drift specification (`ADF = −3.2457`, `p = 0.0199`), and the KPSS statistic under the drift specification is `0.1128`, which does not reject stationarity at conventional levels. Treating inflation as a stationary ARMA process is therefore well-supported.

For the nominal interest rate `r_t`, the ADF test does not reject a unit root in the usual drift specification (`ADF = −2.3787`, `p = 0.1789`). Combined with the visual evidence in Figure 2 — prolonged swings with no tendency to revert to a fixed mean — differencing appears warranted.

A search over ARIMA models with `p, q = 0,...,10` was run for both series, covering `d ∈ {0, 1}` for interest rates. For inflation, only models that ranked well on both AIC and BIC *and* passed the Ljung-Box residual check at 12 lags were retained. The three best adequate models for inflation were:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(2,0,10) | −2692.14 | −2644.38 | 0.1243 |
| ARIMA(4,0,9)  | −2690.87 | −2643.11 | 0.1087 |
| ARIMA(2,0,9)  | −2689.53 | −2645.32 | 0.0981 |

All three need higher-order MA terms than simpler specifications, which is consistent with inflation having a richer short-run autocorrelation structure than an ARMA(1,1) or ARMA(2,2) would capture. The three models agree closely in their AIC rankings, and all pass the adequacy screen.

For interest rates, the top candidates from the search — ranked by AIC from the union of the AIC-preferred and BIC-preferred sets — were:

| Interest rate model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(2,1,2) | 486.46 | 504.24 | 0.0031 |
| ARIMA(3,1,2) | 487.97 | 509.31 | 0.0044 |
| ARIMA(2,1,2) with drift | 488.42 | 509.76 | 0.0028 |

All three interest rate models require a first difference (`d = 1`), consistent with the unit-root evidence and the non-stationary visual impression from the time-series plot. However, none of these models fully clears the Ljung-Box adequacy screen at 12 lags, which is a known difficulty for interest rate series — the very high persistence in `r_t` tends to leave detectable autocorrelation in residuals even when the model order is relatively generous. Forecasting `Δp_t` below is therefore based entirely on the three adequate inflation models.

### 2(a) Inflation Forecasts for 2024–2025

**Figure 3: `fig2a_forecast.png`**

| Quarter | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) | 95% CI Lower | 95% CI Upper |
|---|---:|---:|---:|---:|---:|
| 2024Q1 | 0.008712 | 0.008681 | 0.008697 | 0.006194 | 0.011230 |
| 2024Q2 | 0.008543 | 0.008498 | 0.008521 | 0.003908 | 0.013178 |
| 2024Q3 | 0.008948 | 0.008906 | 0.008934 | 0.002389 | 0.015507 |
| 2024Q4 | 0.008871 | 0.008835 | 0.008862 | 0.000021 | 0.017721 |
| 2025Q1 | 0.008816 | 0.008791 | 0.008807 | −0.001019 | 0.018651 |
| 2025Q2 | 0.008883 | 0.008861 | 0.008876 | −0.001688 | 0.019454 |
| 2025Q3 | 0.008892 | 0.008873 | 0.008888 | −0.002347 | 0.020131 |
| 2025Q4 | 0.008889 | 0.008874 | 0.008884 | −0.002841 | 0.020619 |

All three models forecast quarterly inflation converging toward a long-run mean just under `0.009`. That is exactly the behaviour a stationary ARMA model produces: as the forecast horizon lengthens, the effect of any initial shock fades and the forecast gradually reverts to the unconditional mean. The three models agree very closely in the near-term but show minor divergence at longer horizons, reflecting their different MA lag structures.

### 2(b) Policy Use and Forecast Uncertainty

These forecasts are valuable because monetary and fiscal policy decisions are forward-looking. If inflation is expected to remain above target, a central bank has grounds for maintaining or raising the policy rate. Conversely, if the models signal a sustained easing of inflation, policymakers may judge that current settings are already restrictive enough without further tightening. Fiscal authorities also rely on inflation projections for indexing spending programs and for assessing the real burden of nominal debt.

There are several distinct sources of forecast uncertainty, both conceptual and quantitative.

**Innovation uncertainty** is the most fundamental: future shocks cannot be predicted. This is directly visible in the widening confidence intervals. For ARIMA(2,0,10), the 95% interval is roughly `0.005` wide at the one-quarter horizon (2024Q1) and expands to over `0.023` by 2025Q4. This widening makes intuitive sense because errors compound as the horizon grows.

**Parameter uncertainty** arises because all estimated coefficients carry sampling error. Standard ARIMA interval routines incorporate only innovation uncertainty, so the reported bands understate the true forecast risk. The more parameters a model has, the larger this additional source of error tends to be, which is part of why parsimony is valued.

**Model uncertainty** is evident in the spread across the three models. While all three agree that inflation will hover just below `0.009` in the near term, their point forecasts do diverge slightly at longer horizons due to differences in the MA decay structure.

**Structural uncertainty** is perhaps the most economically important but hardest to quantify. ARIMA models assume that the data-generating process in the future resembles the past. That assumption breaks down around regime changes — a large supply shock, a shift in the central bank's reaction function, or a financial disruption can all push realised inflation well outside any model-based interval, as the post-2021 episode made clear.

---

## Question 3

The actual quarterly inflation rates for 2024Q1–2025Q3 are computed from the provided price-level data using `Δp_t = log(P_t) − log(P_{t−1})`, with `P_{2023Q4}` taken as the last in-sample observation.

| Quarter | Actual `Δp_t` | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) |
|---|---:|---:|---:|---:|
| 2024Q1 | 0.007977 | 0.008712 | 0.008681 | 0.008697 |
| 2024Q2 | 0.008286 | 0.008543 | 0.008498 | 0.008521 |
| 2024Q3 | 0.007614 | 0.008948 | 0.008906 | 0.008934 |
| 2024Q4 | 0.006356 | 0.008871 | 0.008835 | 0.008862 |
| 2025Q1 | 0.007111 | 0.008816 | 0.008791 | 0.008807 |
| 2025Q2 | 0.006337 | 0.008883 | 0.008861 | 0.008876 |
| 2025Q3 | 0.006428 | 0.008892 | 0.008873 | 0.008888 |

Forecast performance:

| Model | MSFE | RMSFE | MAE |
|---|---:|---:|---:|
| ARIMA(2,0,10) | 3.3712e−06 | 0.001836 | 0.001624 |
| ARIMA(4,0,9)  | 3.1084e−06 | 0.001763 | 0.001538 |
| ARIMA(2,0,9)  | 3.2418e−06 | 0.001800 | 0.001582 |

Looking at the performance metrics, ARIMA(4,0,9) comes out slightly ahead on all three measures, though the differences across the three models are small. The bigger picture is that all three models produce very similar forecasts and share the same directional failure: every model over-predicts inflation throughout the evaluation window. All three anchored their forecasts near the historical unconditional mean of around `0.0089`, while actual inflation fell steadily into the `0.006–0.008` range from mid-2024 onwards.

This systematic over-prediction is not a model-fitting failure — the ARIMA models were adequate fits to the in-sample data. Rather, it reflects the post-2021 disinflation playing out faster and more completely than any backward-looking ARMA model was positioned to anticipate. A key takeaway is that when the macroeconomic regime shifts — here, a rapid unwinding of pandemic-era price pressures — all models that rely only on historical patterns will tend to miss the turning point together. The small performance gap between the three models reinforces that, in periods of regime change, model choice within the ARIMA class matters less than the fundamental limitation of backward-looking forecasting.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 4: `fig4a_real_rate.png`**

The real-rate proxy is constructed as `rr_t = r_t − 100·Δp_t`, where the scaling factor of 100 converts the log-difference `Δp_t` (a decimal) into percentage points so that it is on the same scale as `r_t` (which is already in percent), producing `rr_t` in percentage points. Its sample minimum is approximately `−3.8`, its maximum around `15.0`, and its mean is roughly `3.6`.

Comparing `rr_t` to the nominal rate `r_t` and to scaled inflation `100·Δp_t`, it is clear that inflation is the most stable of the three, averaging between 1 and 3 percent with a fairly narrow band. The real interest rate shows more variation than inflation but is slightly more stable than the nominal rate — the dominant nominal-rate swings, especially the spike to around 15% during the Volcker disinflation, are partly offset by the concurrent high inflation, leaving the real rate in a narrower range. The main volatility in `rr_t` comes from the early 1980s, when the Fed raised nominal rates sharply while inflation was still elevated before falling, creating the peak real rates visible in the plot. More recently, the real rate dips near or below zero after the Global Financial Crisis and edges back up as tightening resumed.

From the ARIMA modelling in Question 2, inflation (`d = 0`) and the interest rate framework both converge on `d = 0` for `rr_t` as well, suggesting the real rate is stationary — it fluctuates around a long-run mean, even if that mean-reversion is very slow.

### 4(b) Consumption Ratio

**Figure 5: `fig4b_consumption_ratio.png`**

The consumption ratio `cy_t = C_t/Y_t` rises from around `0.590` to `0.693` over the sample, with a sample mean of `0.6419`. The dominant feature is a persistent upward drift with only minor cyclical fluctuations around the trend.

From an economic perspective, this means consumption has grown faster than output over the same period, so a larger share of GDP is now allocated to household spending. This could reflect several structural changes: a long-run decline in the household saving rate as access to credit expanded and financial markets deepened; the shift of the US economy toward services and away from investment-intensive manufacturing; and persistent trade deficits that allow domestic consumption to exceed domestic production. Rather than suggesting a purely deterministic trend, the pattern is more consistent with a persistent, slowly-evolving structural shift or a near-unit-root stochastic process.

### 4(c) Best Adequate ARIMA Model for `rr_t`

A search over `d ∈ {0, 1}` and `p, q = 0,...,10` was carried out using both AIC/BIC ranking and Ljung-Box adequacy checking at 20 lags. Low-order models left substantial residual autocorrelation even at 20 lags, reflecting the high persistence of the real rate. Among all models that passed the adequacy screen, ARIMA(8,0,1) achieved the lowest AIC with clean residuals:

| Model for `rr_t` | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(8,0,1) | 1284.73 | 1336.49 | 0.3102 |

Key estimated coefficients:

`ar1 = 1.1823`, `ar2 = −0.2814`, `ar3 = −0.0492`, `ar4 = −0.0331`, `ar5 = 0.0214`, `ar6 = −0.0108`, `ar7 = −0.0673`, `ar8 = −0.1193`, `ma1 = −0.8462`, `intercept = 3.614`.

The choice of `d = 0` is consistent with the real rate being a stationary, mean-reverting process — despite its long cycles, it does eventually revert to a positive mean. The high AR order is the model's way of accommodating the very slow mean reversion: real-rate shocks are extremely persistent, and lower-order specifications left systematic patterns in the residuals. The large `ar1` coefficient close to 1 (with subsequent terms pulling it back) is the formal equivalent of saying the real rate is highly persistent but ultimately stationary.

### 4(d) Best Adequate ARIMA Model for `cy_t`

The consumption ratio trends upward throughout the sample, and ADF tests are consistent with a unit root. A search over `d ∈ {0, 1}` and `p, q = 0,...,4` shows the best adequate model is ARIMA(3,1,3):

| Model for `cy_t` | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients:

`ar1 = 0.6092`, `ar2 = −0.5732`, `ar3 = 0.7553`, `ma1 = −0.8316`, `ma2 = 0.6862`, `ma3 = −0.8547`, `drift = 0.0003`.

The first-differencing (`d = 1`) directly captures the strong upward trend — the series is not stationary in levels. The small positive drift term (`0.0003` per quarter) quantifies the average rate at which the consumption share rises once the short-run ARMA dynamics are accounted for. The ARMA(3,3) structure then captures the quarter-to-quarter deviations around that trend. In this sense the model closely mirrors the plot: a steadily rising long-run share with persistent but mean-reverting fluctuations around it.

### 4(e) Policy Use

The `rr_t` model matters for policy because central banks target real, not nominal, rates. A forecast of the real rate path — from the ARIMA(8,0,1) — lets policymakers assess whether the current stance is genuinely restrictive (real rate above the natural rate) or merely nominally tight. If the forecast suggests the real rate is set to decline because inflation expectations are rising faster than the policy rate, the central bank may need to act more aggressively than a nominal-rate view alone would imply.

The `cy_t` model is relevant to both monetary and fiscal policy. A rising consumption share signals strong and persistent household demand, a compressed saving rate, and potentially higher sensitivity to income shocks. For fiscal policy, the model can inform assessments of how households will respond to tax changes or transfers. For monetary policy, a high and rising consumption share suggests that households are already leveraged, which can amplify the transmission of rate changes through the wealth and income channels.

---

## Question 5

### 5(a) Sample Variances

| Currency | Sample Variance | Sample SD |
|---|---:|---:|
| CNY | 0.3369 | 0.5804 |
| USD | 0.4381 | 0.6619 |
| TWI | 0.2675 | 0.5172 |
| SDR | 0.4492 | 0.6702 |

The TWI has the lowest sample variance at `0.267`, which makes sense given that it is a trade-weighted basket of multiple currencies — diversification across trading partners smooths out some of the bilateral exchange-rate swings. The CNY variance of `0.337` is lower than for USD and SDR, which is consistent with China's more managed exchange-rate regime that has historically limited the AUD/CNY from moving as freely as market-determined bilateral rates. USD and SDR are the most volatile, with SDR slightly higher, reflecting the influence of multiple major currencies in the SDR basket during a period that included substantial global risk-off episodes.

It is worth noting that these figures summarise the unconditional dispersion over the full sample. They do not tell us whether volatility is constant over time, nor do they imply that returns are independently and identically distributed. As the next section shows, the constant-variance assumption fails clearly for all four series.

### 5(b) Absolute Returns

**Figure 6: `fig5b_abs_returns.png`**

Plotting `|e_{j,t}|` for each currency reveals clear volatility clustering: periods of large absolute returns are followed by more large returns, and calm stretches tend to persist. The most prominent shared spike occurs around the onset of COVID-19 in March 2020, where all four series show an abrupt and simultaneous jump in absolute returns. This common spike across all four AUD-based rates reflects global risk aversion and liquidity stress rather than anything specific to any single currency pair.

The clustering pattern is fundamentally inconsistent with an iid constant-variance process. If returns were iid, the absolute-return plots would look like white noise with no temporal structure. Instead, the data strongly suggest time-varying conditional volatility — heteroskedasticity — which makes GARCH-type models the natural next step.

---

## Question 6

### Step 1: Testing for GARCH Effects

Before fitting a variance model, it is necessary to confirm that the conditional variance of each return series is actually time-varying. The Engle ARCH LM test with 10 lags rejects homoskedasticity overwhelmingly for every series:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | 0.0000 | 0.0000 |
| USD | 275.60 | 0.0000 | 0.0000 |
| TWI | 484.45 | 0.0000 | 0.0000 |
| SDR | 426.45 | 0.0000 | 0.0000 |

Both the ARCH LM test and the Ljung-Box test on squared returns produce p-values of essentially zero, giving strong evidence that the conditional variance is not constant. A constant-variance model is clearly inadequate for all four series.

### Step 2: Mean Equation Selection

The first step in GARCH modelling is to find an adequate ARMA mean equation. A comparison of ARMA(p,q) models with `p, q ∈ {0,1}` using AIC, BIC, and Ljung-Box tests on raw returns gave the following decisions:

- **CNY**: No low-order mean model removes serial correlation in the returns themselves, so ARMA(0,0) is used and the variance model is relied upon to account for any remaining dependence in the squared process.
- **USD**: ARMA(0,0) already produces acceptable Ljung-Box p-values on the returns (`LB p = 0.0562`).
- **TWI**: ARMA(1,0) is the simplest adequate mean model (`LB p = 0.0592`), picking up a mild AR(1) component.
- **SDR**: ARMA(0,1) has the best information criteria among the adequate low-order candidates (`LB p = 0.3243`).

### Step 3: Variance Model and Error Distribution

For each chosen mean equation, symmetric GARCH(1,1) and asymmetric GJR-GARCH(1,1) were compared under both Normal and Student-t errors — four candidate specifications per currency. The pattern of results is strikingly consistent across all four series: the Student-t distribution improves the fit substantially, and GJR-GARCH wins outright or ties on the information criteria.

| Currency | Mean Model | Final Variance Model | Errors | AIC | BIC |
|---|---|---|---|---:|---:|
| CNY | ARMA(0,0) | GJR-GARCH(1,1) | Student-t | 1.5243 | 1.5410 |
| USD | ARMA(0,0) | GJR-GARCH(1,1) | Student-t | 1.7963 | 1.8130 |
| TWI | ARMA(1,0) | GJR-GARCH(1,1) | Student-t | 1.2830 | 1.3024 |
| SDR | ARMA(0,1) | GJR-GARCH(1,1) | Student-t | 1.7938 | 1.8132 |

Estimated coefficients:

| Currency | `mu` | `ar1` | `ma1` | `omega` | `alpha1` | `beta1` | `gamma1` | `shape` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| CNY | −0.0143 | — | — | 0.0067 | 0.0143 | 0.9316 | 0.0623 | 8.0011 |
| USD | −0.0140 | — | — | 0.0042 | 0.0013 | 0.9607 | 0.0519 | 8.4778 |
| TWI | −0.0068 | −0.0400 | — | 0.0070 | 0.0225 | 0.9186 | 0.0547 | 8.0324 |
| SDR | −0.0084 | — | −0.1812 | 0.0055 | 0.0182 | 0.9486 | 0.0359 | 7.7614 |

The `beta1` estimates are all close to 1, confirming that volatility shocks are highly persistent — a spike in conditional variance takes a long time to decay. The positive `gamma1` estimates capture the leverage effect: negative return shocks raise conditional volatility by more than positive shocks of the same magnitude, which is a well-established stylised fact in exchange-rate data. The Student-t shape parameters around 7–8 confirm that the return distributions have heavier tails than a Normal model can accommodate.

### Diagnostics and Volatility Plots

| Currency | LB on Std. Residuals p-value | LB on Sq. Std. Residuals p-value |
|---|---:|---:|
| CNY | 0.4394 | 0.0000 |
| USD | 0.6937 | 0.0000 |
| TWI | 0.5976 | 0.0000 |
| SDR | 0.8967 | 0.0000 |

The mean equations are adequate — there is no important remaining autocorrelation in the standardised residuals. The squared standardised residuals still reject at conventional levels for all four currencies, which means the GJR-GARCH models have not completely captured every aspect of the variance dynamics. This should be stated openly rather than glossed over. Even so, the GJR-GARCH specifications are clearly a substantial improvement over constant-variance models and capture the main features of interest: volatility clustering, high persistence, asymmetric response to shocks, and heavy tails.

**Figures 7–10: `fig6_vol_CNY.png`, `fig6_vol_USD.png`, `fig6_vol_TWI.png`, `fig6_vol_SDR.png`**

All four conditional volatility series spike dramatically during the COVID-19 episode. The TWI is visibly the smoothest and most stable of the four, consistent with its lower unconditional variance from Question 5.

---

## Question 7

For a GJR-GARCH(1,1) model, the unconditional variance exists when `α + β + γ/2 < 1`, and is then given by:

`σ²_j = ω / (1 − α − β − γ/2)`

Applying this to each fitted model:

| Currency | `α + β + γ/2` | Model Variance (σ̂²) | Sample Variance | Ratio |
|---|---:|---:|---:|---:|
| CNY | 0.9771 | 0.2925 | 0.3369 | 0.8682 |
| USD | 0.9879 | 0.3456 | 0.4381 | 0.7888 |
| TWI | 0.9685 | 0.2234 | 0.2675 | 0.8352 |
| SDR | 0.9848 | 0.3638 | 0.4492 | 0.8099 |

All four persistence measures are below 1, so finite unconditional variances exist for every currency. The model-implied variances are uniformly lower than the corresponding sample variances — the ratio ranges from about 0.79 to 0.87. This is precisely what one would expect when a large transitory volatility episode like COVID-19 is present in the sample. The sample variance is mechanically inflated by the 2020 spike, whereas the GJR-GARCH model tries to capture a long-run variance level that is appropriate after separating out temporary bursts. In that sense the model-based estimates are arguably more representative of the structural volatility of each exchange rate under normal market conditions than the raw sample variances are.

---

## Question 8

The question asks for the probability that the daily return falls below `0.01%` on 13/01/2026 and 14/01/2026. These probabilities are computed from the one-step-ahead and two-step-ahead forecasts of the GJR-GARCH models, using the model-implied Student-t CDF (`pdist("std", ...)` from `rugarch`) rather than a plain normal distribution, so that the heavy-tail behaviour captured in the shape parameter is properly accounted for.

| Currency | `μ_{T+1}` | `σ_{T+1}` | `P(e < 0.01), 13 Jan` | `μ_{T+2}` | `σ_{T+2}` | `P(e < 0.01), 14 Jan` |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0143 | 0.4524 | 0.5239 | −0.0143 | 0.4547 | 0.5238 |
| USD | −0.0140 | 0.4432 | 0.5240 | −0.0140 | 0.4453 | 0.5239 |
| TWI | −0.0070 | 0.3775 | 0.5201 | −0.0067 | 0.3809 | 0.5196 |
| SDR | −0.0230 | 0.4449 | 0.5332 | −0.0084 | 0.4477 | 0.5184 |

A lower probability is better for a downside-risk-averse foreign-currency investor because it means a smaller chance of earning less than the threshold return of `0.01%`.

On **13 January 2026**, the ranking from least to most downside risk is:

1. TWI (`0.5201`)
2. CNY (`0.5239`)
3. USD (`0.5240`)
4. SDR (`0.5332`)

On **14 January 2026**, the ranking shifts:

1. SDR (`0.5184`)
2. TWI (`0.5196`)
3. CNY (`0.5238`)
4. USD (`0.5239`)

The SDR's large jump in rank between the two days reflects a notably lower mean return (`μ_{T+1} = −0.0230`) on 13 January, which pushes more of the distribution below the threshold, before reverting to a value close to the other currencies on 14 January. This kind of day-to-day shift in relative ranking is exactly why a static mean-variance framework is insufficient for short-horizon risk management.

From a portfolio perspective, TWI looks the most consistently attractive over both days — it sits near the bottom of the risk ranking on both dates and never suffers the sharp one-day deterioration seen in SDR. This outcome is directly tied to TWI's lower conditional volatility (`σ` around 0.38 versus 0.44–0.45 for the others), which is in turn driven by the diversification benefits of a trade-weighted basket. The key contribution of the GARCH framework here is that these probabilities are forward-looking and conditioned on the current volatility state, rather than relying on the historical sample averages from Question 5.
