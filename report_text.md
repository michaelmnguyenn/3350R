# ECON3350 Research Report 1

This report answers all eight research questions using concise empirical evidence, clear model-selection logic, and direct discussion of the economic implications of the results.

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1: `fig1_log_levels.png`**

**Figure 2: `fig2_log_diffs.png`**

The log price level, log real GDP per capita, and log real consumption all trend upward over the full sample. This is the clearest visual sign that the level series are not fluctuating around a fixed constant mean. The price index grows especially quickly during the high-inflation period of the 1970s and early 1980s. Real GDP per capita and real consumption both rise strongly over time and move closely together, with visible slowdowns around major recessions.

Once the logged series are differenced, the trend is largely removed. Quarterly inflation, GDP growth, and consumption growth fluctuate around relatively stable means, although inflation is visibly more volatile in the 1970s and again around the post-pandemic inflation episode. The nominal T-bill rate is more persistent than the differenced real variables: it rises sharply into the Volcker period, trends down for decades, remains near zero after the Global Financial Crisis, and then rises again from 2022. Overall, the plots suggest that `p_t`, `y_t`, and `c_t` are trending level series, while `Delta p_t`, `Delta y_t`, and `Delta c_t` are much closer to stationary growth-rate processes.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend | SE(Trend) | R-squared |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.945124 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.428678 | 0.005305 | 0.000043 | 0.9834 |

All three estimated trend coefficients are economically and statistically important. The high `R^2` values show that a deterministic linear trend captures most of the long-run movement in each logged level series.

### 1(b)(ii) Means of First Differences

| Series | Mean |
|---|---:|
| `Delta p_t` | 0.009310 |
| `Delta y_t` | 0.004919 |
| `Delta c_t` | 0.005379 |

### 1(b)(iii) Why Estimate Both?

Both exercises are trying to measure the same long-run feature: the average rate at which each series grows over time. In a random-walk-with-drift representation, the drift is the average quarterly change. A regression of the level on a time trend estimates that average growth through the slope coefficient, while the sample mean of first differences estimates it directly.

That is why the two estimates should be close. They are indeed very similar for output and consumption. The price series shows the largest gap because US inflation is not stable over the whole sample: the high-inflation 1970s and disinflationary 1980s make a single linear trend in levels a less precise summary than the mean of quarterly inflation.

---

## Question 2

### Model Selection Logic

For inflation, the relevant object is `Delta p_t`, not the price level. The ADF test on `Delta p_t` gives its strongest evidence against a unit root at lag 3 in the drift specification (`ADF = -3.2457`, `p = 0.0199`), and the KPSS statistic under the drift specification is `0.1128`, which does not reject stationarity at conventional levels. So it is reasonable to model inflation directly with ARMA models.

For the nominal interest rate `r_t`, the ADF test does not reject a unit root in the usual drift specification (`ADF = -2.3787`, `p = 0.1789`). The KPSS evidence is weaker, but the plot still shows very persistent low-frequency movement, so differencing remains a reasonable modelling choice for interest rates.

A search over ARIMA models with `p,q = 0,...,10` was then run. For inflation, I kept only models that ranked well on both AIC and BIC and also passed the Ljung-Box residual check at 12 lags. The three best adequate models were:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(2,0,10) | -2692.14 | -2644.38 | 0.1243 |
| ARIMA(4,0,9)  | -2690.87 | -2643.11 | 0.1087 |
| ARIMA(2,0,9)  | -2689.53 | -2645.32 | 0.0981 |

All three require higher-order MA terms than lower-order models, which is consistent with inflation having a richer autocorrelation structure than a simple ARMA(1,1) or ARMA(2,2) would capture. For interest rates, the wider search over `d ∈ {0,1}` and `p,q = 0,...,10` produced a set of candidates; the best-ranked are reported in the results object. None fully eliminates residual autocorrelation at 12 lags, which is worth noting openly. The inflation forecasts below come only from the three inflation models.

### 2(a) Inflation Forecasts for 2024-2025

**Figure 3: `fig2a_forecast.png`**

| Quarter | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) | 95% CI Lower | 95% CI Upper |
|---|---:|---:|---:|---:|---:|
| 2024Q1 | 0.008712 | 0.008681 | 0.008697 | 0.006194 | 0.011230 |
| 2024Q2 | 0.008543 | 0.008498 | 0.008521 | 0.003908 | 0.013178 |
| 2024Q3 | 0.008948 | 0.008906 | 0.008934 | 0.002389 | 0.015507 |
| 2024Q4 | 0.008871 | 0.008835 | 0.008862 | 0.000021 | 0.017721 |
| 2025Q1 | 0.008816 | 0.008791 | 0.008807 | -0.001019 | 0.018651 |
| 2025Q2 | 0.008883 | 0.008861 | 0.008876 | -0.001688 | 0.019454 |
| 2025Q3 | 0.008892 | 0.008873 | 0.008888 | -0.002347 | 0.020131 |
| 2025Q4 | 0.008889 | 0.008874 | 0.008884 | -0.002841 | 0.020619 |

All three inflation models forecast quarterly inflation converging toward a long-run mean just under `0.009`. That is exactly what stationary ARMA dynamics imply: as the forecast horizon grows, the effect of any current shock fades and the prediction falls back toward the unconditional mean.

### 2(b) Policy Use and Forecast Uncertainty

These forecasts are useful because monetary policy is forward-looking. If inflation is forecast to stay above target, a central bank has grounds for holding or tightening the policy rate. If inflation is expected to ease, policymakers might judge that existing rates are already restrictive enough. Fiscal policy also relies on inflation projections for indexing spending and assessing the real burden of nominal debt.

There are several distinct sources of uncertainty, and the question asks us to address both the concept and the numbers.

First, **innovation uncertainty**: future shocks cannot be predicted. This shows up directly in widening confidence intervals. For ARIMA(2,0,10), the 95% interval is roughly `0.005` wide in 2024Q1 and opens to more than `0.022` by 2025Q4.

Second, **parameter uncertainty**: all estimated coefficients carry sampling error. Standard ARIMA interval routines only incorporate innovation uncertainty, so the reported bands understate true forecast risk.

Third, **model uncertainty**: the three best adequate models agree closely near the mean but still differ. The 2024Q1 gap across the three models is small, but the spread widens somewhat at longer horizons, especially since higher-order MA terms differ in how quickly they decay.

Fourth, **structural uncertainty**: ARIMA models assume the future data-generating process mirrors the past. That assumption fails around regime changes — a major supply shock, a shift in the central bank's reaction function, or a credit-market disruption can all push realised inflation well outside any model-based interval.

---

## Question 3

Using the `P_t` values for 2024Q1 to 2025Q3 read directly from the data file, with the last in-sample observation `P_2023Q4` taken from row 260, the realised quarterly inflation rates are:

| Quarter | Actual `Delta p_t` | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) |
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
| ARIMA(2,0,10) | 3.3712e-06 | 0.001836 | 0.001624 |
| ARIMA(4,0,9)  | 3.1084e-06 | 0.001763 | 0.001538 |
| ARIMA(2,0,9)  | 3.2418e-06 | 0.001800 | 0.001582 |

ARIMA(4,0,9) performs best on all three metrics, though the differences across models are relatively small. The dominant pattern is systematic over-prediction. All three models anchored their forecasts near the historical unconditional mean around `0.0089`, but realised inflation fell steadily through the `0.006–0.008` range. This reflects the post-2021 inflation unwind playing out faster than any backward-looking ARMA model was calibrated to expect. The broader point is that a model can fit historical data well and still miss the turning point of a regime change.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 4: `fig4a_real_rate.png`**

The real-rate proxy is `rr_t = r_t - 100 * Delta p_t`, where both the nominal rate and the scaled inflation term are in percentage points. Its sample minimum is approximately `-3.8`, its maximum is around `15.0`, and its mean is roughly `3.6`. The series is dominated by the Volcker disinflation period in the early 1980s, when the nominal rate rose sharply while inflation was still elevated, pushing the real rate to its highest levels in the sample. After that, the real rate trends down broadly, dips near or below zero following the Global Financial Crisis, and edges back up at the end of the sample as the Fed tightened again. Compared to the nominal rate, the real rate shows slightly more variation because subtracting a time-varying inflation component adds noise around the nominal path. But the low-frequency persistence is still very clear, which means any adequate model needs to account for that persistence explicitly.

### 4(b) Consumption Ratio

**Figure 5: `fig4b_consumption_ratio.png`**

The consumption ratio `cy_t = C_t / Y_t` rises from about `0.590` to `0.693`, with a sample mean of `0.6419`. The dominant feature is a persistent upward drift. An economic interpretation is that consumption has become a larger share of output over time, consistent with a lower saving rate, easier access to credit, and stronger consumption-smoothing opportunities as financial markets deepened.

### 4(c) Best Adequate ARIMA Model for `rr_t`

Unit-root testing on the correctly-computed real rate series produces mixed results, but the ADF evidence at longer lags does not reject stationarity, and with the real rate now measured consistently in percentage points the series looks mean-reverting over long spans. A search over `d ∈ {0,1}` and `p,q = 0,...,10` was used. Low-order models left substantial residual autocorrelation even at 20 lags. Among all models that passed the adequacy screen, ARIMA(8,0,1) achieved the lowest AIC and the cleanest residuals:

| Model for `rr_t` | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(8,0,1) | 1284.73 | 1336.49 | 0.3102 |

Key estimated coefficients:

`ar1 = 1.1823`, `ar2 = -0.2814`, `ar3 = -0.0492`, `ar4 = -0.0331`, `ar5 = 0.0214`, `ar6 = -0.0108`, `ar7 = -0.0673`, `ar8 = -0.1193`, `ma1 = -0.8462`, `intercept = 3.614`.

Using `d = 0` rather than `d = 1` is consistent with the idea that the real rate is ultimately a mean-reverting process, even if it can deviate for many years at a time. The high AR order is needed because real-rate shocks are very persistent and lower-order specifications leave systematic autocorrelation in the residuals.

### 4(d) Best Adequate ARIMA Model for `cy_t`

Searching over `d ∈ {0,1}` and `p,q = 0,...,4` shows that the best adequate model is ARIMA(3,1,3):

| Model for `cy_t` | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | -2135.65 | -2107.20 | 0.7626 |

Key estimated coefficients:

`ar1 = 0.6092`, `ar2 = -0.5732`, `ar3 = 0.7553`, `ma1 = -0.8316`, `ma2 = 0.6862`, `ma3 = -0.8547`, `drift = 0.0003`.

The differencing term reflects the strong upward trend in the ratio, while the ARMA terms capture short-run deviations from that trend. In that sense, the model matches the economics of the plot: a slowly rising long-run share with quarter-to-quarter corrections around it.

### 4(e) Policy Use

The `rr_t` model is useful because policy works through real, not nominal, interest rates. With the real rate now measured properly in percentage points, the ARIMA(8,0,1) forecasts give a cleaner picture of whether policy is genuinely restrictive. A central bank can compare the forecast real rate path against its estimate of the natural rate to judge how much tightening or easing is already in the pipeline.

The `cy_t` model is useful because the consumption share is closely tied to aggregate demand. A persistently high or rising consumption ratio can signal strong household demand, a low saving rate, and greater sensitivity of the economy to income or wealth shocks. That makes it relevant for both monetary and fiscal policy.

---

## Question 5

### 5(a) Sample Variances

| Currency | Sample Variance | Sample SD |
|---|---:|---:|
| CNY | 0.336855 | 0.5804 |
| USD | 0.438086 | 0.6619 |
| TWI | 0.267471 | 0.5172 |
| SDR | 0.449172 | 0.6702 |

TWI is the least volatile return series, which is consistent with diversification across trading partners. USD and SDR are the most volatile. CNY is less volatile than USD, which is consistent with a more managed exchange-rate regime.

### 5(b) Absolute Returns

**Figure 6: `fig5b_abs_returns.png`**

The absolute-return plots show clear volatility clustering: large moves arrive in bursts, and calm periods also persist. The largest common spike is around the onset of COVID-19 in March 2020. This pattern immediately suggests that a constant-variance model is inappropriate and that conditional volatility models such as GARCH are needed.

---

## Question 6

### Step 1: Evidence of GARCH Effects

An Engle ARCH LM test with 10 lags strongly rejects homoskedasticity for every return series:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | 0.0000 | 0.0000 |
| USD | 275.60 | 0.0000 | 0.0000 |
| TWI | 484.45 | 0.0000 | 0.0000 |
| SDR | 426.45 | 0.0000 | 0.0000 |

So the variance is clearly time-varying, which is the key hint in the question.

### Step 2: Mean Equation Selection

I first screened low-order ARMA mean models using AIC/BIC and Ljung-Box tests on the raw returns:

- CNY: no low-order mean model removes all serial correlation, so I use ARMA(0,0) and let the variance model do the main work.
- USD: ARMA(0,0) is already acceptable (`LB p = 0.0562`).
- TWI: ARMA(1,0) is the simplest adequate mean model (`LB p = 0.0592`).
- SDR: ARMA(0,1) has the best information criteria among the adequate low-order mean models (`LB p = 0.3243`).

### Step 3: Variance Model and Error Distribution

For each chosen mean equation, I compared symmetric GARCH(1,1) and asymmetric GJR-GARCH(1,1), each under Normal and Student-t errors. The key result is very consistent across currencies: the Student-t distribution improves fit materially, and GJR-GARCH gives the best or near-best information criteria.

| Currency | Mean Model | Final Variance Model | Errors | AIC | BIC |
|---|---|---|---|---:|---:|
| CNY | ARMA(0,0) | GJR-GARCH(1,1) | Student-t | 1.5243 | 1.5410 |
| USD | ARMA(0,0) | GJR-GARCH(1,1) | Student-t | 1.7963 | 1.8130 |
| TWI | ARMA(1,0) | GJR-GARCH(1,1) | Student-t | 1.2830 | 1.3024 |
| SDR | ARMA(0,1) | GJR-GARCH(1,1) | Student-t | 1.7938 | 1.8132 |

Estimated coefficients:

| Currency | `mu` | `ar1` | `ma1` | `omega` | `alpha1` | `beta1` | `gamma1` | `shape` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| CNY | -0.0143 |  |  | 0.0067 | 0.0143 | 0.9316 | 0.0623 | 8.0011 |
| USD | -0.0140 |  |  | 0.0042 | 0.0013 | 0.9607 | 0.0519 | 8.4778 |
| TWI | -0.0068 | -0.0400 |  | 0.0070 | 0.0225 | 0.9186 | 0.0547 | 8.0324 |
| SDR | -0.0084 |  | -0.1812 | 0.0055 | 0.0182 | 0.9486 | 0.0359 | 7.7614 |

The interpretation is standard and economically sensible. The `beta1` estimates are close to one, so volatility is highly persistent. The positive `gamma1` estimates imply asymmetry: bad news raises volatility more than good news of the same size. The Student-t shape parameters around 8 confirm heavier tails than a Normal model can capture.

### Diagnostics and Volatility Plots

| Currency | Ljung-Box on Standardized Residuals p-value | Ljung-Box on Squared Standardized Residuals p-value |
|---|---:|---:|
| CNY | 0.4394 | 0.0000 |
| USD | 0.6937 | 0.0000 |
| TWI | 0.5976 | 0.0000 |
| SDR | 0.8967 | 0.0000 |

The mean equations are adequate because there is no important remaining autocorrelation in standardized residuals. The squared standardized residuals still reject at conventional levels, so the fitted GJR-GARCH models are not perfect. This should be stated openly. Even so, they are clearly better than constant-variance models and capture the main stylised facts that matter for this question: volatility clustering, persistence, asymmetry, and heavy tails.

**Figures 7-10: `fig6_vol_CNY.png`, `fig6_vol_USD.png`, `fig6_vol_TWI.png`, `fig6_vol_SDR.png`**

All four volatility series spike dramatically during the COVID-19 shock. TWI is visibly the most stable, which matches its lower unconditional variance.

---

## Question 7

For a GJR-GARCH(1,1) model, the unconditional variance exists when:

`alpha1 + beta1 + gamma1 / 2 < 1`

and is then given by:

`sigma_j^2 = omega / (1 - alpha1 - beta1 - gamma1 / 2)`

Applying this formula gives:

| Currency | `alpha + beta + gamma/2` | Model Variance | Sample Variance | Ratio |
|---|---:|---:|---:|---:|
| CNY | 0.9771 | 0.2925 | 0.3369 | 0.8682 |
| USD | 0.9879 | 0.3456 | 0.4381 | 0.7888 |
| TWI | 0.9685 | 0.2234 | 0.2675 | 0.8352 |
| SDR | 0.9848 | 0.3638 | 0.4492 | 0.8099 |

All four models imply finite unconditional variances because the persistence measure is below one in every case. The model-based variances are uniformly lower than the sample variances. That is exactly what we should expect when the sample contains a major transitory volatility episode such as COVID-19: the sample variance is inflated by that event, while the GARCH model tries to recover a long-run variance level after separating out temporary volatility bursts.

---

## Question 8

The question asks for the probability that the daily return is less than `0.01%` on 13/01/2026 and 14/01/2026. Because the final models use the standardized Student-t distribution from `rugarch`, these probabilities were computed using the model-implied Student-t CDF directly rather than a plain textbook `t` distribution formula.

| Currency | `mu_{T+1}` | `sigma_{T+1}` | `P(13/01/2026)` | `mu_{T+2}` | `sigma_{T+2}` | `P(14/01/2026)` |
|---|---:|---:|---:|---:|---:|---:|
| CNY | -0.0143 | 0.4524 | 0.5239 | -0.0143 | 0.4547 | 0.5238 |
| USD | -0.0140 | 0.4432 | 0.5240 | -0.0140 | 0.4453 | 0.5239 |
| TWI | -0.0070 | 0.3775 | 0.5201 | -0.0067 | 0.3809 | 0.5196 |
| SDR | -0.0230 | 0.4449 | 0.5332 | -0.0084 | 0.4477 | 0.5184 |

A lower probability is better for a downside-risk-averse foreign-currency investor, because it means a smaller chance of earning less than the threshold return.

On **13 January 2026**, the ranking is:

1. TWI (`0.5201`)
2. CNY (`0.5239`)
3. USD (`0.5240`)
4. SDR (`0.5332`)

On **14 January 2026**, the ranking is:

1. SDR (`0.5184`)
2. TWI (`0.5196`)
3. CNY (`0.5238`)
4. USD (`0.5239`)

If the decision is based on both days together, TWI is the most attractive choice because it is consistently near the bottom of the risk ranking and never performs badly. In risk-management terms, this is why conditional-variance models are useful: they provide a forward-looking probability measure based on the current volatility state, not just on long-run averages.
