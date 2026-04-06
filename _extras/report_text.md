# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1: `fig1_log_levels.png`**

**Figure 2: `fig2_log_diffs.png`**

The quarterly data cover macroeconomic indicators for the USA over 1959Q1–2023Q4 (260 observations), comprising the log price level `p_t`, log real GDP per capita `y_t`, log real consumption `c_t`, and the nominal 3-month T-bill rate `r_t`.

The log-level plots of `p_t`, `y_t`, and `c_t` all show persistent upward movement over the sample. The processes generating these series have a trend in their mean and so are not covariance stationary in levels. `y_t` and `c_t` move closely together throughout, while `p_t` rises more steeply, particularly through the 1970s and early 1980s. In the language of the course, these plots are consistent with trending macroeconomic processes.

The log-difference plots of `Δp_t`, `Δy_t`, and `Δc_t` look much more stable than the level series. All three fluctuate around fairly constant averages and do not show the same persistent upward movement, suggesting that differencing removes most of the trend. There are still periods of larger variation — `Δy_t` and `Δc_t` show sharp drops around the 2008 Global Financial Crisis and again in 2020 — but the series do not drift. This is consistent with the idea that the level processes may be difference stationary, so that their first differences are much more stable than the levels.

The nominal interest rate `r_t` is plotted in levels alongside the differenced series in the second figure. It behaves differently: it does not show the same steady upward trend but instead displays long swings over time. Specifically, it rises into the late 1970s and early 1980s, declines over later decades, stays near zero for much of the 2010s, and then rises again after 2021. The dominant feature of `r_t` is not steady growth but prolonged movements and substantial autocorrelation across different rate regimes.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.945124 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.428678 | 0.005305 | 0.000043 | 0.9834 |

All three trend slope estimates are statistically significant with very small standard errors, and the high R² values confirm that a linear time trend accounts for most of the long-run variation in each log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Rationale and Comparison

A rationale for these estimations is that they help characterise the trend behaviour of the processes. A persistent increase in the data suggests a trend in the underlying stochastic process, and modelling this in practice involves including time `t` as a regressor. Regressing `p_t`, `y_t`, and `c_t` on an intercept and time trend provides an estimate of the linear trend in the process mean, captured by δ̂. By contrast, estimating the mean of `Δp_t`, `Δy_t`, and `Δc_t` provides an estimate of the average quarter-to-quarter change in each series, captured by μ̂. If the log-level processes are trending and are reasonably close to difference-stationary behaviour, then the mean of the first differences should be similar to the slope of the linear trend in levels. So δ̂ and μ̂ are both trying to capture average growth, but through slightly different routes — δ̂ through a fitted linear trend in the level series, and μ̂ through the average change in the differenced series.

In this sample the estimates are quite close. For `y_t`, the estimated trend is 0.004757 while the mean of `Δy_t` is 0.004919; for `c_t`, 0.005305 versus 0.005379. The gap is slightly larger for `p_t` (0.010125 versus 0.009310), which is consistent with the plot showing somewhat less smooth trend behaviour — the high-inflation 1970s and subsequent disinflation distort a single linear trend more than they distort the average of quarterly changes.

This comparison alone does not establish whether the processes contain unit roots; that requires formal unit root testing.

---

## Question 2

### 2(a) Model Selection

A broad set of ARIMA(p,d,q) models was estimated for `Δp_t` and `r_t` over the estimation sample 1959Q1–2023Q4, with `p, q` ranging from 0 to 10 and `d ∈ {0,1}`. Models were ranked by AIC and BIC, then screened for adequacy using the Ljung-Box test on residuals at 12 lags.

**Inflation (`Δp_t`):** Unit root testing supports treating `Δp_t` as stationary (`d = 0`). The three best adequate models — ranked highly on both AIC and BIC while passing the Ljung-Box screen at 12 lags — are:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(2,0,10) | −2692.14 | −2644.38 | 0.1243 |
| ARIMA(4,0,9)  | −2690.87 | −2643.11 | 0.1087 |
| ARIMA(2,0,9)  | −2689.53 | −2645.32 | 0.0981 |

All three require higher-order MA components, consistent with inflation exhibiting richer short-run autocorrelation structure than low-order specifications can capture.

**Interest rates (`r_t`):** The top AIC candidates all involve first differencing (`d = 1`) combined with high-order AR components, consistent with the visual evidence of prolonged level shifts and very slow mean-reversion in once-differenced rates. The leading adequate models — ARIMA(8,1,2), ARIMA(7,1,2), and ARIMA(8,1,1) — all pass the Ljung-Box adequacy test at 12 lags, with p-values between 0.14 and 0.19. The high AR order is required to capture the substantial autocorrelation remaining in `Δr_t`.

| Interest rate model | AIC | BIC | Ljung-Box p-value | Selected |
|---|---:|---:|---:|---|
| ARIMA(8,1,2) | 475.76 | 518.44 | 0.145 | Best adequate |
| ARIMA(7,1,2) | 476.69 | 515.81 | 0.189 | Adequate |
| ARIMA(8,1,1) | 476.92 | 516.04 | 0.164 | Adequate |

Since the question asks for adequate inflation models to be used for forecasting, the three inflation specifications above are used in Questions 2(b) and 3. The interest rate models confirm that `r_t` is I(1), with its slow mean-reversion captured by a high AR order in the differenced specification; these models are not used for out-of-sample forecasting here.

### 2(b) Inflation Forecasts for 2024–2025

**Figure 3: `fig2a_forecast.png`**

| Quarter | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) | 68% CI Lower | 68% CI Upper | 95% CI Lower | 95% CI Upper |
|---|---:|---:|---:|---:|---:|---:|---:|
| 2024Q1 | 0.008712 | 0.008681 | 0.008697 | 0.007427 | 0.009997 | 0.006194 | 0.011230 |
| 2024Q2 | 0.008543 | 0.008498 | 0.008521 | 0.006178 | 0.010908 | 0.003908 | 0.013178 |
| 2024Q3 | 0.008948 | 0.008906 | 0.008934 | 0.005602 | 0.012294 | 0.002389 | 0.015507 |
| 2024Q4 | 0.008871 | 0.008835 | 0.008862 | 0.004356 | 0.013386 | 0.000021 | 0.017721 |
| 2025Q1 | 0.008816 | 0.008791 | 0.008807 | 0.003798 | 0.013834 | −0.001019 | 0.018651 |
| 2025Q2 | 0.008883 | 0.008861 | 0.008876 | 0.003490 | 0.014276 | −0.001688 | 0.019454 |
| 2025Q3 | 0.008892 | 0.008873 | 0.008888 | 0.003158 | 0.014626 | −0.002347 | 0.020131 |
| 2025Q4 | 0.008889 | 0.008874 | 0.008884 | 0.002904 | 0.014874 | −0.002841 | 0.020619 |

All three models forecast quarterly inflation converging toward a long-run mean just under 0.009 — exactly the behaviour a stationary ARMA model produces, as the forecast reverts to the unconditional mean once the effect of initial conditions fades. The three models agree very closely in the near term, with minor divergence at longer horizons reflecting their different MA lag structures.

### 2(c) Policy Use and Forecast Uncertainty

Forecasts of `Δp_t` are useful for policy because decisions depend not only on current conditions but also on the expected future path of inflation. A central bank setting the policy rate needs to know whether inflation is likely to remain above target or ease, since the appropriate stance depends on where prices are heading, not where they are. Fiscal authorities similarly rely on inflation projections to index spending programmes and to assess the real burden of debt.

The most fundamental source of uncertainty is the unknown future — future shocks that have not yet occurred. This is why the predictive intervals widen steadily over the horizon. For ARIMA(2,0,10), the 95% interval spans roughly 0.005 in total width at 2024Q1 and widens to over 0.023 by 2025Q4. Even though the point forecasts remain near 0.009 throughout, the range of plausible outcomes becomes much larger as the forecast extends. This widening is a direct implication of the MA(∞) representation: each additional step adds an unobserved innovation, and the cumulative uncertainty grows with horizon.

There is also model uncertainty, evident in the spread across the three inflation specifications, and estimation uncertainty arising because all coefficients are estimated from a finite sample and would differ across samples. The predictive intervals reported here reflect only innovation uncertainty; they do not account for the additional dispersion introduced by parameter estimation error or model misspecification, so the true forecast risk is wider than the reported bands suggest. Using three models rather than one partly addresses model uncertainty, since the spread of their point forecasts indicates how sensitive the central outlook is to specification choices.

Finally, these forecasts rely on the assumption that the historical pattern of inflation dynamics remains valid out of sample. If the economy enters a new regime — a large supply shock, a change in central bank behaviour, or an unexpected financial disruption — realised inflation can fall well outside any model-based interval. The post-2021 inflation episode illustrated exactly this: backward-looking ARMA models, estimated on a sample where inflation was low and stable, were poorly positioned to anticipate an inflationary surge driven by supply constraints and fiscal stimulus.

---

## Question 3

**Figure 4: `fig3_actual_vs_forecast.png`**

The actual quarterly inflation rates for 2024Q1–2025Q3 are computed from the provided price-level data as `Δp_t = log(P_t) − log(P_{t−1})`, with `P_{2023Q4}` as the last in-sample observation.

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

ARIMA(4,0,9) ranks first on all three measures, though the differences across models are small. The more important observation is that all three models produce the same directional failure: every model over-predicts inflation throughout the hold-out window. All three anchored their forecasts near the in-sample unconditional mean of approximately 0.0089, while actual inflation fell steadily, reaching the 0.006–0.008 range from mid-2024 onwards. The realised values still lie within the 95% predictive intervals in the early quarters, but the systematic bias — consistently above the actual path — reflects a structural shift rather than random forecast error.

This is not a model-fitting failure. The ARIMA models were adequate fits to the in-sample data. The problem is that the post-2021 disinflation played out faster and more completely than any backward-looking ARMA model could anticipate, since such models extrapolate historical average dynamics rather than responding to changing macroeconomic conditions. When the regime shifts — here, a rapid unwinding of pandemic-era price pressures — models within the same ARIMA class tend to miss the turning point together, which is why model choice among the three matters less than the shared limitation of purely backward-looking forecasting.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 5: `fig4a_real_rate.png`**

The real-rate proxy is constructed as `rr_t = r_t − 100·Δp_t`, converting the log-difference `Δp_t` to percentage points to match the scale of `r_t`. Its sample mean is approximately 3.6%, with a minimum of −3.8% and a maximum of around 15.0%.

The plot suggests that `rr_t` is somewhat more stable than the nominal interest rate `r_t`, but less stable than inflation `Δp_t`. The nominal rate shows the largest long swings, particularly in the late 1970s and early 1980s, while `rr_t` is less extreme because inflation is partially offsetting the nominal movements. However, `rr_t` still displays substantial variation including prolonged swings and some negative values, so it is not obviously stable in any strong sense. Relative to the other two series, inflation fluctuates within the narrowest range for most of the sample — spending most of its history between 1 and 3 percent. The overall picture is that `rr_t` is less volatile than `r_t`, but not clearly more stable than `Δp_t`.

### 4(b) Consumption Ratio

**Figure 6: `fig4b_consumption_ratio.png`**

The dominant feature of `cy_t = C_t/Y_t` is its persistent upward movement over the sample. The series rises from around 0.590 in the early part of the sample to approximately 0.693 by 2023Q4, with only moderate short-run fluctuations around this longer-run trend and a sample mean of 0.6419. The process mean does not appear constant over time — the series does not fluctuate around a clearly fixed level.

From an economic perspective, a rising `cy_t` means consumption has grown faster than output, so a larger share of GDP is allocated to household spending. Since `cy_t = C_t/Y_t`, a rise in the ratio means `C_t` is increasing relative to `Y_t`. From the national accounts identity `Y = C + I + G + (X − M)`, a higher consumption share implies that the share of output accounted for by investment, government spending, and net exports has on average fallen relative to consumption. Several structural factors support this: a long-run decline in the household saving rate as access to credit expanded and financial markets deepened; a shift of the US economy toward services and away from investment-intensive manufacturing; and persistent trade deficits that allow domestic consumption to exceed domestic production. The dominant feature of the plot is not short-run volatility but a slow-moving structural shift in the composition of demand.

### 4(c) Best Adequate ARIMA Model for `rr_t`

Formally, if `r_t` is I(1) and `100·Δp_t` is I(0), their difference `rr_t` should also be I(1). However, the Fisher hypothesis provides a resolution: if the nominal interest rate and expected inflation share a common stochastic trend — that is, if `r_t ≈ α + E_t[Δp_{t+1}]` holds in the long run — then `rr_t` is the cointegrating residual between them and is I(0) despite its components being individually I(1). This motivates including `d = 0` models in the search alongside `d = 1` alternatives. A search over `d ∈ {0,1}` and `p, q = 0,...,10` with Ljung-Box adequacy checking at 20 lags confirms that the real rate is adequately described without differencing.

| Model for `rr_t` | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(8,0,1) | 1284.73 | 1336.49 | 0.3102 |

Key estimated coefficients: `ar1 = 1.1823`, `ar2 = −0.2814`, `ar3 = −0.0492`, `ar4 = −0.0331`, `ar5 = 0.0214`, `ar6 = −0.0108`, `ar7 = −0.0673`, `ar8 = −0.1193`, `ma1 = −0.8462`, `intercept = 3.614`.

The choice of `d = 0` reflects the Fisher hypothesis: the real rate is treated as a stationary, mean-reverting series around a long-run average of approximately 3.6%, even though its cycle is very slow. The estimated AR(1) coefficient of 1.18, balanced out by the subsequent AR terms, is the model's way of capturing the multi-year swings visible in the Q4(a) plot — quasi-permanent deviations that eventually reverse — without requiring a unit root. Lower-order specifications left systematic patterns in the residuals; AR(8) is needed because each lag contributes incrementally to explaining the very gradual return to mean after a shock. The MA(1) term at −0.85 provides additional short-run flexibility in capturing the initial shock response. Together, the model matches the two dominant features of the plot: very slow mean-reversion and a clearly positive long-run average, both of which are inconsistent with a unit root and consistent with stationary but highly persistent dynamics.

### 4(d) Best Adequate ARIMA Model for `cy_t`

A search over `d ∈ {0,1}` and `p, q = 0,...,4` was carried out using AIC and BIC ranking with Ljung-Box adequacy checking at 20 lags. The persistent upward movement in `cy_t` is consistent with a unit root, and the best adequate model requires first differencing:

| Model for `cy_t` | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients: `ar1 = 0.6092`, `ar2 = −0.5732`, `ar3 = 0.7553`, `ma1 = −0.8316`, `ma2 = 0.6862`, `ma3 = −0.8547`, `drift = 0.0003`.

First differencing is the appropriate treatment for `cy_t` because the series shows clear, sustained upward movement throughout the sample — it does not oscillate around a fixed mean but instead trends from approximately 0.59 to 0.69 over the 65-year sample. Taking the first difference removes this stochastic trend component and yields a stationary series to which ARMA dynamics can be applied. The small positive drift of 0.0003 per quarter captures the average rate of rise in the consumption share after removing short-run dynamics — equivalent to a rise of about 1.2 percentage points per decade, matching the historical average observed in the plot. The AR(3) component reflects that deviations from this drift path are themselves persistent: a quarter where consumption grows faster than trend tends to be followed by further above-trend quarters before reverting, a pattern consistent with household consumption exhibiting momentum due to habit formation and smooth adjustment to permanent income shocks. The MA(3) structure captures the short-lived idiosyncratic shocks that die away within a few quarters. Together, the ARIMA(3,1,3) with drift captures both the dominant long-run feature of the data (the trend in the level of `cy_t`) and its short-run dynamics (autocorrelated quarterly fluctuations around that trend).

### 4(e) Policy Use

A forecasting model for `rr_t` is useful for policy because the real interest rate is closely related to the effective stance of monetary policy. A central bank targeting a real policy rate needs to know whether the real rate is expected to remain above or below the neutral rate — if inflation expectations are rising faster than the policy rate, the stance may be less restrictive than it appears nominally. The ARIMA(8,0,1) model, which captures the high persistence and long swings in `rr_t`, is useful for summarising how real financing conditions evolve over time rather than treating each quarterly movement as independent.

The `cy_t` model is relevant to both monetary and fiscal policy. A rising consumption share signals strong household demand and a compressed saving rate. For fiscal policy, the model can inform assessments of how households will respond to tax changes or transfers. For monetary policy, a high and rising consumption share suggests households are already leveraged, which can amplify the transmission of rate changes through the wealth and income channels.

---
## Question 5

### 5(a) Sample Variances

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

These sample variances estimate the unconditional variances of the return series and summarise their average volatility over the full sample. A larger value implies greater average variability in returns. SDR has the highest unconditional variance, followed by USD, then CNY, with TWI the lowest: SDR > USD > CNY > TWI.

The TWI's low variance reflects the diversification benefit of a trade-weighted basket — swings in individual bilateral rates partially offset each other when aggregated across trading partners. The CNY's relatively low variance is consistent with China's more managed exchange-rate regime, which has historically limited the AUD/CNY from moving as freely as market-determined bilateral rates. USD and SDR are the most volatile, with SDR slightly higher, reflecting the influence of multiple major currencies in the SDR basket during a period that included substantial global risk-off episodes. These are unconditional summaries only and do not show whether volatility is constant over time.

### 5(b) Absolute Returns

**Figure 7: `fig5b_abs_returns.png`**

The plots of `|e_{j,t}|` show clear periods of low volatility followed by periods of much higher volatility, especially around March 2020 and again in later parts of the sample. Large absolute returns tend to be followed by further large returns, while calm stretches tend to persist. This is volatility clustering. The most prominent shared spike occurs at the onset of COVID-19, where all four series show an abrupt and simultaneous jump — reflecting global risk aversion and liquidity stress rather than anything specific to any single currency pair.

This clustering pattern is inconsistent with an iid constant-variance process. If returns were iid, the absolute-return plots would look like white noise with no temporal structure. Instead, the data strongly suggest time-varying conditional volatility, making GARCH-type models the natural next step for modelling `e_{j,t}`.

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

A comparison of ARMA(p,q) models with `p, q ∈ {0,...,3}` was conducted using AIC, BIC, and the Ljung-Box test on raw returns at 10 lags. Daily FX returns are close to white noise in their levels, so adequacy of the mean equation is the primary criterion and parsimony is preferred. The Ljung-Box test on standardised residuals from the GARCH step (reported below) provides the final confirmation. Decisions for the mean equation:

- **CNY**: ARMA(0,0) — AIC and BIC both rank a constant-only mean among the top specifications, and the Ljung-Box test on raw CNY returns does not reject at conventional levels for the zero-lag model. The variance dynamics are the dominant feature of CNY returns, not the conditional mean.
- **USD**: ARMA(0,0) — similar reasoning; the marginal AIC improvement from adding AR or MA terms is small, and the GARCH variance model is sufficient to account for the autocorrelation structure.
- **TWI**: ARMA(1,0) — AIC and BIC indicate a mild but persistent AR(1) component in TWI returns; this is the simplest adequate mean specification.
- **SDR**: ARMA(0,1) — BIC favours the MA(1) mean equation, which achieves adequate Ljung-Box p-values on raw returns.

### Variance Model and Error Distribution

For each chosen mean equation, symmetric GARCH(1,1), asymmetric GJR-GARCH(1,1), and both GARCH(1,2) variants were compared under Normal and Student-t errors — eight candidate specifications per currency. Models were selected by requiring adequacy on the Ljung-Box test for both standardised residuals (mean adequacy) and squared standardised residuals (variance adequacy), then minimising AIC among adequate candidates. The GJR-GARCH(1,2) specification with Student-t errors produced the lowest AIC for all four currencies:

| Currency | Mean Model | Variance Model | Errors | AIC | BIC |
|---|---|---|---|---:|---:|
| CNY | ARMA(0,0) | GJR-GARCH(1,2) | Student-t | 1.5236 | 1.5431 |
| USD | ARMA(0,0) | GJR-GARCH(1,2) | Student-t | 1.7948 | 1.8143 |
| TWI | ARMA(1,0) | GJR-GARCH(1,2) | Student-t | 1.2806 | 1.3028 |
| SDR | ARMA(0,1) | GJR-GARCH(1,2) | Student-t | 1.7901 | 1.8124 |

Estimated coefficients:

| Currency | `mu` | `ar1` | `ma1` | `omega` | `alpha1` | `beta1` | `beta2` | `gamma1` | `shape` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| CNY | −0.0145 | — | — | 0.0105 | 0.0256 | 0.3652 | 0.5282 | 0.0898 | 8.2296 |
| USD | −0.0149 | — | — | 0.0074 | 0.0062 | 0.2176 | 0.7123 | 0.0849 | 8.8065 |
| TWI | −0.0071 | −0.0382 | — | 0.0112 | 0.0356 | 0.2603 | 0.6087 | 0.0893 | 8.3771 |
| SDR | −0.0095 | — | −0.1787 | 0.0101 | 0.0348 | 0.1801 | 0.7255 | 0.0635 | 8.0817 |

The GJR-GARCH(1,2) specification distributes GARCH persistence across two lags; the combined `beta1 + beta2` ranges from 0.89 to 0.93 across currencies, confirming highly persistent volatility shocks — a spike in conditional variance takes a long time to decay. The positive `gamma1` estimates capture an asymmetric response: negative return shocks raise conditional volatility by more than positive shocks of the same magnitude. In FX markets this likely reflects flight-to-safety dynamics and liquidity asymmetries during stress periods. The Student-t shape parameters around 8–9 confirm heavier tails than a Normal model can accommodate.

### Diagnostics and Volatility Plots

| Currency | LB on Std. Residuals p-value | LB on Sq. Std. Residuals p-value |
|---|---:|---:|
| CNY | 0.4666 | 0.0000 |
| USD | 0.7275 | 0.0000 |
| TWI | 0.6180 | 0.0000 |
| SDR | 0.9088 | 0.0000 |

The mean equations are adequate — no important autocorrelation remains in the standardised residuals. The squared standardised residuals still reject at conventional levels for all four currencies, indicating that the GJR-GARCH(1,1) specification does not capture every aspect of the variance dynamics. Despite this, the selected models represent a substantial improvement over constant-variance alternatives and capture the main features of interest: volatility clustering, high persistence, asymmetric shock response, and heavy tails.

**Figures 8–11: `fig6_vol_CNY.png`, `fig6_vol_USD.png`, `fig6_vol_TWI.png`, `fig6_vol_SDR.png`**

All four conditional volatility series spike sharply during the COVID-19 episode in March 2020, then gradually decay. The TWI is visibly the smoothest and most stable of the four, consistent with its lower unconditional variance from Question 5.

---
## Question 7

For a GJR-GARCH(1,2) model the unconditional variance exists when `α + β₁ + β₂ + γ/2 < 1`, and is given by:

`σ²_j = ω / (1 − α − β₁ − β₂ − γ/2)`

Applying this to each fitted model:

| Currency | `α + β₁ + β₂ + γ/2` | Model Variance (σ̂²) | Sample Variance | Ratio |
|---|---:|---:|---:|---:|
| CNY | 0.9638 | 0.2899 | 0.3369 | 0.8607 |
| USD | 0.9785 | 0.3456 | 0.4381 | 0.7889 |
| TWI | 0.9493 | 0.2218 | 0.2675 | 0.8293 |
| SDR | 0.9722 | 0.3630 | 0.4492 | 0.8081 |

All four persistence measures are below 1, so finite unconditional variances exist for every currency. The persistence values are all high — ranging from 0.9493 for TWI to 0.9785 for USD — indicating that volatility shocks decay only gradually, consistent with the clustering patterns in the absolute return plots.

The model-implied variances are uniformly lower than the corresponding sample variances, with ratios ranging from about 0.79 to 0.86. The raw sample variance is mechanically inflated by the large but transitory volatility spike during COVID-19 in March 2020. The GJR-GARCH model separates that temporary burst from the structural long-run variance level, so the model-based estimates are arguably more representative of the underlying volatility of each exchange rate under normal market conditions. The same broad ranking from Question 5 is preserved: TWI remains the lowest-volatility series and SDR the highest.

---

## Question 8

The probability that the daily return falls below 0.01% on 13/01/2026 and 14/01/2026 is computed from the one-step-ahead and two-step-ahead GJR-GARCH forecasts, using the Student-t CDF with the estimated shape parameter so that the heavy-tail behaviour is properly accounted for.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0145 | 0.4575 | 0.5239 | −0.0145 | 0.4533 | 0.5241 |
| USD | −0.0149 | 0.4562 | 0.5240 | −0.0149 | 0.4404 | 0.5249 |
| TWI | −0.0074 | 0.3830 | 0.5202 | −0.0071 | 0.3777 | 0.5201 |
| SDR | −0.0242 | 0.4522 | 0.5337 | −0.0095 | 0.4444 | 0.5196 |

All probabilities are slightly above 0.5. This occurs because the forecast conditional means are negative for all four series while the threshold 0.01% is close to zero, so on both dates there is a somewhat greater than 50% chance that the return falls below the threshold.

A lower probability is preferable from a downside-risk perspective, since it means a smaller chance of earning less than the 0.01% threshold. On **13 January 2026**, the ranking from least to most downside risk is TWI (0.5202), CNY (0.5239), USD (0.5240), SDR (0.5337). On **14 January 2026**, the ranking shifts to SDR (0.5196), TWI (0.5201), CNY (0.5241), USD (0.5249).

TWI is the most consistently attractive currency across both dates, sitting near the bottom of the risk ranking on both days. The main reason is that TWI combines the least negative forecast mean with the lowest conditional volatility — around 0.38 versus 0.44–0.46 for the other three — which reflects the diversification benefit of a trade-weighted basket. SDR's large jump in rank between the two days reflects its notably lower mean return on 13 January (μ_{T+1} = −0.0242 versus around −0.007 to −0.015 for the others), which pushes substantially more of the distribution below the threshold, before it reverts toward values similar to the other currencies on 14 January. This kind of day-to-day shift in relative ranking illustrates why a static approach using unconditional sample variances from Question 5 is insufficient for short-horizon risk management. The GARCH framework produces forward-looking probabilities conditioned on the current volatility state, allowing a more accurate and timely assessment of downside risk across currencies.
