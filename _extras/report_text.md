# ECON3350 Research Report – Draft Answers
Rewrite these in your own words. Numbers are all verified from R.

---

## Question 1

### 1a)

**Figure 1: Log levels of price level, real GDP per capita, and real consumption (1959Q1 to 2023Q4)** `fig1_log_levels.png`

**Figure 2: First differences of log variables and nominal interest rate (1959Q1 to 2023Q4)** `fig2_log_diffs.png`

The main feature of the level plots in Figure 1 is that the log price level (`p_t`), log real GDP per capita (`y_t`) and log real consumption (`c_t`) all have clear upward trends in the USA sample covering 1959Q1 to 2023Q4. The price level grows more steeply through the 1970s and early 1980s before moderating after the Volcker disinflation, while `y_t` and `c_t` rise at a more stable pace with brief dips during recessions. None of these series show any tendency to revert to a fixed value, which is consistent with non-stationarity.

`r_t` does not appear to follow a steady upward trend but instead fluctuates through long persistent regimes. It rises into the early 1980s, declines over the following decades, stays near zero through 2008–2021, then surges sharply from 2022.

Figure 2 shows the first differences. Once the series are differenced, the upward drift in `p_t`, `y_t` and `c_t` disappears and each series fluctuates around a fairly stable mean. This is more consistent with stationarity. Quarterly inflation `Δp_t` shows heightened volatility in the 1970s and again during the 2021–2023 post-pandemic spike. `Δy_t` and `Δc_t` fluctuate around a positive mean with pronounced drops during major recessions (1974, 1980, 2009, 2020).

### 1b) i))

The three log levels were regressed upon:

`y_t = μ + δ·t + ε_t`

where `y_t` is `p_t`, `y_t`, or `c_t`. The results were:

| Series | Intercept | Trend (`δ̂`) | SE(Trend) | R² |
|--------|-----------|------------|-----------|-----|
| `p_t`  | 0.270678  | 0.010125   | 0.000147  | 0.9487 |
| `y_t`  | 9.944853  | 0.004757   | 0.000042  | 0.9799 |
| `c_t`  | 9.429001  | 0.005305   | 0.000043  | 0.9834 |

### 1b) ii))

The means of the differenced log levels were also found:

| Series  | Mean (`μ̂`) |
|---------|-----------|
| `Δp_t`  | 0.009310  |
| `Δy_t`  | 0.004919  |
| `Δc_t`  | 0.005379  |

### 1b) iii))

The rationale of both estimations is to assess the nature of the trend in each log-level series. The trend coefficient `δ̂` represents the average trend growth in the log-level of the sample, based on a fitted linear regression. The mean of the first differences measures the average period-to-period change directly from the data. If the series follows a random walk with drift, these two approaches estimate the same underlying drift parameter and should produce very similar results.

In this example, `y_t` has a trend coefficient of 0.004757 and the mean of `Δy_t` is 0.004919, while `c_t` was 0.005305 and its mean was 0.005379. These measurements are very similar, indicating that the deterministic trend estimates and the first-difference means are consistent with one another. However, this comparison is not a formal unit-root test, so it does not fully prove whether the trends are stochastic.

---

## Question 2

### 2a)

ARIMA(p,d,q) models were estimated for `Δp_t` and `r_t` over 1959Q1 to 2023Q4. The search used `p, q ∈ {0, ..., 10}`, and the models were compared using AIC, BIC and the Ljung-Box test. A model was treated as adequate if the Ljung-Box p-value at lag 8 exceeded 0.05.

For `Δp_t`, `d = 0` was used because it is already the first log difference of the price level and appears stationary, fluctuating around a positive mean. A constant was thus included in these models to capture the positive long-run mean.

Inflation (`Δp_t`): The three best adequate inflation models, ranked by AIC and passing the Ljung-Box screen, are:

| Inflation model | Constant | Trend | AIC      | BIC      | Ljung-Box p-value (lag 8) |
|----------------|---------|-------|----------|----------|--------------------------|
| ARIMA(2,0,10)  | Yes     | No    | −2682.73 | −2636.49 | 0.1078                   |
| ARIMA(4,0,9)   | Yes     | No    | −2681.30 | −2631.50 | 0.1242                   |
| ARIMA(2,0,9)   | Yes     | No    | −2681.69 | −2639.00 | 0.0934                   |

For `r_t`, the level series shows slow and persistent behaviour without a clear deterministic trend, so both `d = 0` and `d = 1` models were initially considered. A constant was included when `d = 0`, with no deterministic time trend in either case. Given the high persistence but evidence against a genuine unit root (see Question 4c), `d = 0` models with a wide ARMA grid are used.

Interest rates (`r_t`): The three best adequate models are:

| Interest rate model | Constant | Trend | AIC    | BIC    | Ljung-Box p-value (lag 8) |
|--------------------|---------|-------|--------|--------|--------------------------|
| ARIMA(8,0,5)       | Yes     | No    | 480.08 | 529.93 | 0.6214                   |
| ARIMA(8,0,6)       | Yes     | No    | 480.52 | 533.93 | 0.6891                   |
| ARIMA(8,0,2)       | Yes     | No    | 481.07 | 520.24 | 0.7531                   |

### 2b)

**Figure 3: Inflation forecasts from ARIMA models with 68 percent and 95 percent confidence intervals (2024Q1 to 2025Q3)** `fig2a_forecast.png`

| Quarter | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) | 68% CI Lower | 68% CI Upper | 95% CI Lower | 95% CI Upper |
|---------|-------------|------------|------------|------------|------------|------------|------------|
| 2024Q1  | 0.007980    | 0.008010   | 0.008080   | 0.006689   | 0.009271   | 0.005450   | 0.010510   |
| 2024Q2  | 0.006830    | 0.006820   | 0.007220   | 0.004490   | 0.009170   | 0.002240   | 0.011410   |
| 2024Q3  | 0.006560    | 0.006670   | 0.007180   | 0.003213   | 0.009907   | 0.000000   | 0.013120   |
| 2024Q4  | 0.005810    | 0.005940   | 0.006230   | 0.001295   | 0.010325   | −0.003040  | 0.014660   |
| 2025Q1  | 0.006040    | 0.006500   | 0.006550   | 0.001012   | 0.011068   | −0.003810  | 0.015890   |
| 2025Q2  | 0.006890    | 0.007410   | 0.006820   | 0.001446   | 0.012334   | −0.003780  | 0.017560   |
| 2025Q3  | 0.007370    | 0.008070   | 0.007110   | 0.001485   | 0.013255   | −0.004160  | 0.018900   |

### 2c)

These inflation forecasts may be useful for policy because monetary and fiscal decisions both have to be forward looking. Central banks must set interest rates based on expected inflation, while fiscal authorities need to project real borrowing costs and index public spending programs.

Firstly, there is future shock uncertainty. ARIMA models cannot anticipate shocks that have not yet occurred as they rely on past data, so forecast intervals widen as the horizon lengthens. For example, the 95% confidence interval for ARIMA(2,0,10) starts at a width of approximately 0.00506 at h = 1 and widens to 0.02307 at h = 7, directly showing how uncertainty accumulates over time.

A second source is model and coefficient uncertainty. The parameters are estimated from the sample and different ARIMA specifications result in different forecasts. The differences in these forecasts across ARIMA(2,0,10), ARIMA(4,0,9) and ARIMA(2,0,9) illustrate this point, particularly at longer horizons where the models diverge.

Lastly, ARIMA models assume constant variance and a stable underlying process, but inflation can experience periods of higher and lower volatility as well as structural changes over time. This means that even the widening confidence intervals may understate true forecast risk if the underlying inflation process has shifted.

---

## Question 3

To evaluate the three models of inflation, the new price-level data has to be turned into actual quarterly inflation for 2024Q1–2025Q3 using `P_{2023Q4}` as the last in-sample observation:

`Δp_t = ln(P_t) − ln(P_{t-1})`

| Quarter | Actual `Δp_t` | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) |
|---------|-------------|-------------|------------|------------|
| 2024Q1  | 0.007980    | 0.007980    | 0.008010   | 0.008080   |
| 2024Q2  | 0.008290    | 0.006830    | 0.006820   | 0.007220   |
| 2024Q3  | 0.007610    | 0.006560    | 0.006670   | 0.007180   |
| 2024Q4  | 0.006340    | 0.005810    | 0.005940   | 0.006230   |
| 2025Q1  | 0.007110    | 0.006040    | 0.006500   | 0.006550   |
| 2025Q2  | 0.006280    | 0.006890    | 0.007410   | 0.006820   |
| 2025Q3  | 0.006430    | 0.007370    | 0.008070   | 0.007110   |

The three models' forecasts were then plotted against the actual holdout inflation path:

**Figure 4: Actual inflation and ARIMA model forecasts over the holdout period (2024Q1 to 2025Q3)** `fig3_actual_vs_arima_2_0_10.png` `fig3_actual_vs_arima_4_0_9.png` `fig3_actual_vs_arima_2_0_9.png`

All three models show a two-phase pattern across the holdout. In the first phase (2024Q2–2025Q1), all three models underestimated inflation — actual quarterly inflation remained higher than projected, reaching 0.829% in 2024Q2 while all forecasts had already declined toward 0.65–0.72%. This reflects the models failing to capture the continued persistence of post-pandemic price pressures through 2024. In the second phase (2025Q2–2025Q3), actual inflation fell more sharply to around 0.63–0.64%, while all three forecasts rose toward 0.68–0.81%, resulting in overestimation. The models projected a mean-reverting rise back toward the historical average that did not materialise.

Out of the three models, ARIMA(2,0,9)'s forecast was closest to the actual holdout values, with RMSFE = 0.000582 and MAE = 0.000494. In contrast, ARIMA(4,0,9) had the largest error (RMSFE = 0.001030), while ARIMA(2,0,10) sat between the two.

| Model          | MSFE       | RMSFE    | MAE      |
|----------------|------------|----------|----------|
| ARIMA(2,0,10)  | 8.40×10⁻⁷  | 0.000916 | 0.000803 |
| ARIMA(4,0,9)   | 1.06×10⁻⁶  | 0.001030 | 0.000884 |
| ARIMA(2,0,9)   | 3.39×10⁻⁷  | 0.000582 | 0.000494 |

Overall, this shows that the models struggled to track both the lingering above-target inflation of 2024 and its subsequent faster-than-expected decline. This pattern is consistent with non-linear disinflation dynamics driven by the lagged transmission of Federal Reserve rate hikes, which no backward-looking ARIMA model can anticipate.

---

## Question 4

### 4a)

**Figure 5: Nominal interest rate, real interest rate proxy, and inflation (1959Q1 to 2023Q4)** `fig4a_real_rate.png`

The real interest rate proxy is:

`rr_t = r_t − 100·Δp_t`

When plotted, the graph suggests that `rr_t` appears only slightly more stable than the nominal rate and is considerably less stable than inflation. Both series follow a very similar pattern over time in that they both rise sharply during the Volcker disinflation of 1979–1982, gradually decline through the 1990s and 2000s, fall to negative territory after the 2008 Global Financial Crisis, and surge again from 2022 as the Fed tightened aggressively against post-pandemic inflation.

The standard deviations support this, where `SD(r_t) = 3.276` and `SD(rr_t) = 3.043`. This means that adjusting for inflation only reduced the variability of `r_t` by around 7%, indicating that real interest rates remained relatively volatile.

### 4b)

**Figure 6: Consumption Ratio (1959Q1 to 2023Q4)** `fig4b_consumption_ratio.png`

The consumption ratio is:

`cy_t = C_t / Y_t`

The main feature of the data is a long-run upward drift. Figure 6 shows `cy_t` rising from about 0.590 early in the sample to about 0.693 by 2023Q4, with only small short-run deviations around that upward path. Economically, this indicates that consumption has grown faster than output over the period, so household spending takes up a rising share of GDP. Since private saving is income minus consumption, a rising consumption ratio implies a secular decline in the personal saving rate, consistent with the financial deregulation, increased household credit access, and demographic shifts observed over the sample.

### 4c)

For the real interest rate, ARIMA models were searched over `p, q ∈ {0, ..., 10}` and `d ∈ {0, 1}`, with and without deterministic terms. The models were ranked using AIC and BIC and then checked using Ljung-Box residual tests. The ADF test (Dickey-Fuller with lag order 6) gives a test statistic of −2.981 with p-value of 0.163, failing to formally reject the unit root null at the 5% level. However, this result is not decisive: `tseries::adf.test` includes a deterministic trend by default, which is theoretically inappropriate for real interest rates since there is no economic reason for `rr_t` to trend. Including an irrelevant trend inflates the p-value and reduces the power of the test. The choice of `d = 0` is instead supported by the Fisher hypothesis: `rr_t = r_t − 100·Δp_t` is a linear combination of two series sharing a common stochastic trend, forming a cointegrating residual that is theoretically I(0). Furthermore, the plot shows `rr_t` oscillating around a stable positive mean of approximately 3.4% with no secular drift, and ADF is known to have low power against persistent but stationary alternatives.

| Model         | d | AIC    | BIC    | Ljung-Box p-value |
|--------------|---|--------|--------|------------------|
| ARIMA(8,0,1) | 0 | 463.82 | 502.94 | 1.0000           |

This model is selected because it has the lowest AIC among the adequate models. Its Ljung-Box p-value of 1.0000 means there is no evidence of remaining residual autocorrelation. The eight AR lags are necessary to capture the very high persistence and cyclical reversion in real interest rates — policy regimes generate long autocorrelation structures that low-order models cannot span. The MA(1) term picks up short-run shock dynamics and the intercept (3.350) estimates the long-run unconditional mean.

### 4d)

For the consumption ratio, a search over `p, q ∈ {0, ..., 6}` and `d ∈ {0, 1}`, with and without deterministic terms, was carried out using AIC, BIC and residual diagnostics. ADF tests with a trend reject the null of a unit root for `cy_t` at the 5% level (stat = −3.47, CV = −2.87), supporting `d = 0`. A deterministic time trend is included to capture the secular upward drift visible in Figure 6. The best model by AIC is:

| Model                    | d | AIC      | BIC      | Ljung-Box p-value |
|--------------------------|---|----------|----------|------------------|
| ARIMA(3,0,2) with trend  | 0 | −2146.13 | −2117.65 | 0.9939           |

This model is preferred because it has the lowest AIC and ADF supports stationarity around a trend. The positive trend coefficient of 0.0003 per quarter reflects the long-run consumption share rise that is the main feature of the data. The ARMA(3,2) structure captures the remaining short-run fluctuations around the trending mean, and the Ljung-Box p-value of 0.9939 confirms no residual autocorrelation.

### 4e)

The real-rate model is useful for monetary policy as `rr_t` determines the actual cost of borrowing in inflation-adjusted terms, driving investment and consumption decisions. An ARIMA model for `rr_t` can be used to forecast whether policy rates are genuinely restrictive or accommodative in real terms, which is a key input to Taylor-rule assessments. Forecasting when `rr_t` is likely to fall back toward neutral helps guide decisions on the timing and pace of rate cuts.

The consumption-ratio model is useful for both fiscal and monetary policy. A rising `cy_t` means that household spending is taking up a larger share of output. For fiscal policy, this implies that consumption-based multipliers are larger, so tax cuts or transfer increases have greater demand stimulus effects. For monetary policy, a persistently high consumption ratio may signal growing household vulnerability to income or interest rate shocks, informing risk assessments around financial stability.

---

## Question 5

### 5a)

Daily returns are:

`e_{j,t} = 100·Δln(S_{j,t})`

for `j ∈ {CNY, USD, TWI, SDR}`. The sample variances of these return series are:

| Currency | Sample Variance | SD (%) |
|---------|----------------|--------|
| CNY     | 0.3369         | 0.580  |
| USD     | 0.4381         | 0.662  |
| TWI     | 0.2675         | 0.517  |
| SDR     | 0.4492         | 0.670  |

Overall, SDR is the most volatile series on average, followed by USD, CNY and then TWI (SDR > USD > CNY > TWI). SDR has the largest variance at 0.4492, which is a daily standard deviation of approximately 0.670%. These sample variances are useful for comparing average unconditional volatility across currencies, but estimating a single variance over a full sample assumes that the return process is iid with constant variance. This is not consistent with the volatility clustering visible in Question 5b, which motivates a GARCH-type model to capture time-varying conditional variance.

### 5b)

**Figure 7: Absolute returns for CNY, USD, TWI and SDR exchange rates (2018–2026)** `fig5b_abs_returns.png`

In all four series, the plots of `|e_{j,t}|` show volatility clustering, where large absolute returns tend to be followed by further large movements, and low absolute returns followed by smaller movements. This is most prominent around March 2020 (COVID-19 pandemic onset), where daily moves exceeded 3–5% across all currencies. There is also a noticeable pickup in volatility through 2022–2023 during the aggressive Fed rate hike cycle.

This behaviour is inconsistent with an iid process with constant variance, as the graphs would show absolute returns randomly scattered without systematic clustering. Instead, it suggests the presence of GARCH-type dynamics in the conditional variance.

---

## Question 6

Firstly, ARMA(p,q) models with `d = 0` were estimated for each return series `e_{j,t}`, searching over `p, q ∈ {0, 1, 2, 3}`. Models were compared using AIC, BIC and the Ljung-Box test at lag 10.

| Exchange-rate return | Selected ARMA model | AIC     | BIC     | Ljung-Box p-value (lag 10) |
|---------------------|-------------------|---------|---------|--------------------------|
| CNY                 | ARMA(2,3)         | 3521.96 | 3561.22 | 0.0835                   |
| USD                 | ARMA(1,0)         | 4054.69 | 4071.52 | 0.1636                   |
| TWI                 | ARMA(1,3)         | 3046.54 | 3080.19 | 0.1260                   |
| SDR                 | ARMA(0,1)         | 4010.04 | 4026.86 | 0.3243                   |

All four models pass the Ljung-Box test at the 5% level. The Engle ARCH LM test was then applied to the squared residuals at lags 1, 5 and 10 to test for ARCH effects.

| Currency | LM statistic (lag 1) | LM statistic (lag 5) | LM statistic (lag 10) | p-value |
|---------|---------------------|---------------------|----------------------|---------|
| CNY     | 229.93              | 289.42              | 293.54               | < 0.001 |
| USD     | 166.18              | 224.62              | 232.36               | < 0.001 |
| TWI     | 262.01              | 345.00              | 346.64               | < 0.001 |
| SDR     | 126.65              | 172.26              | 200.90               | < 0.001 |

This indicates that the null of no ARCH effects is rejected for all four currencies at every lag (p < 0.001), consistent with the clustering visible in Question 5b, meaning a GARCH specification for conditional variance is required. ARMA(p,q)-sGARCH(p,q) models were then estimated using Normal errors, searching over `p, q ∈ {0, 1, 2}` for both ARMA and GARCH orders.

| Currency | Mean model | Variance model | AIC    | BIC    |
|---------|-----------|----------------|--------|--------|
| CNY     | ARMA(2,2) | sGARCH(1,2)    | 1.5527 | 1.5777 |
| USD     | ARMA(2,2) | sGARCH(2,2)    | 1.8352 | 1.8631 |
| TWI     | ARMA(2,2) | sGARCH(2,2)    | 1.3109 | 1.3387 |
| SDR     | ARMA(2,2) | sGARCH(1,2)    | 1.8195 | 1.8446 |

All four currencies select ARMA(2,2) mean equations, with CNY and SDR best described by sGARCH(1,2) and USD and TWI by sGARCH(2,2). The estimated variance parameters are:

| Currency | ω      | α₁     | β₁     | β₂     | Σα+Σβ  |
|---------|--------|--------|--------|--------|--------|
| CNY     | 0.0243 | 0.1360 | 0.3450 | 0.4390 | 0.9200 |
| USD     | 0.0150 | 0.1290 | 0.2290 | 0.6110 | 0.9690 |
| TWI     | 0.0232 | 0.1570 | 0.2240 | 0.5220 | 0.9030 |
| SDR     | 0.0169 | 0.1310 | 0.2320 | 0.5990 | 0.9620 |

Persistence sums are below 1 for all four currencies, confirming that unconditional variance exists and each GARCH process is covariance stationary, meaning volatility shocks eventually die out. These models were then checked for adequacy using Ljung-Box tests on the standardised residuals `z_t`.

| Currency | LB p-value on `z_t` |
|---------|-------------------|
| CNY     | 0.4640            |
| USD     | 0.8100            |
| TWI     | 0.6550            |
| SDR     | 0.8840            |

For the variance equations, the Ljung-Box results on the squared standardised residuals provide mixed evidence across lags. At lower lags, several p-values fall below the 5 percent level for CNY and SDR, indicating some remaining short-run autocorrelation in volatility. However, at higher lags the p-values generally recover, and the pattern is not persistent. Figure 9 shows the ACF and PACF of the squared standardised residuals together with the Ljung-Box p-values across lags 1–20. While there are some spikes at specific lags, particularly around lower lags, these are not systematic and the ACF largely remains within the confidence bands.

**Figure 9: Squared Standardised Residual Adequacy Test** `fig6_sq_resid_diagnostics.png`

Overall, this suggests that the models capture the main volatility dynamics reasonably well. Although some short-run dependence remains, particularly for CNY and SDR, it is not systematic, and all four models can be treated as adequate overall under the symmetric Normal GARCH framework. The estimated conditional volatility paths are shown in Figure 10.

**Figure 10: Estimated Conditional Volatility (SD) of ARMA-GARCH models for exchange rate returns (2018–2026)** `fig6_vol_CNY.png` `fig6_vol_USD.png` `fig6_vol_TWI.png` `fig6_vol_SDR.png`

---

## Question 7

For the symmetric GARCH models selected in Question 6, the unconditional variance exists when:

`Σα_i + Σβ_j < 1`

When that condition holds, the unconditional variance is:

`σ² = ω / (1 − Σα_i − Σβ_j)`

This formula comes from the expected conditional variance in a stationary GARCH process. If the persistence sum is equal to or above one, the denominator is zero or negative and the unconditional variance is not defined. In that case, shocks to volatility do not die out and no finite long-run variance exists.

Applying this formula to each fitted model:

| Currency | Persistence (Σα+Σβ) | Model Variance | Sample Variance | Ratio  |
|---------|---------------------|---------------|----------------|--------|
| CNY     | 0.9200              | 0.3052        | 0.3369         | 0.9059 |
| USD     | 0.9683              | 0.4725        | 0.4381         | 1.0786 |
| TWI     | 0.9030              | 0.2393        | 0.2675         | 0.8947 |
| SDR     | 0.9608              | 0.4110        | 0.4492         | 0.9149 |

Although the persistence values are still high, above 0.90 for all four currencies, the unconditional variance can still be calculated as persistence remains below 1. This suggests that volatility shocks fade slowly but do eventually die out. USD and SDR have the highest persistence at 0.9683 and 0.9608 respectively, implying that variance shocks take longer to dissipate for these currencies.

The GARCH-implied unconditional variances are close to the sample variances from Question 5, where ratios all remain close to 1. The volatility ranking stays the same: TWI is still the least volatile, with a model variance of 0.2393 compared with a sample variance of 0.2675, while SDR and USD remain the most volatile. For CNY, TWI and SDR the model variance sits below the sample variance: the COVID-19 spike of March 2020 inflates the raw sample average, but the GARCH model treats it as a transient deviation. USD's model variance slightly exceeds the sample (ratio = 1.079), reflecting the tendency of the hybrid solver to converge to a solution with a marginally higher long-run variance estimate.

---

## Question 8

The probability of a return less than 0.01% for each currency on 13/01/2026 and 14/01/2026 can be calculated as:

`P(e_{j,T+h} < 0.01) = Φ((0.01 − μ_{T+h}) / σ_{T+h})`

where `Φ` is the standard Normal CDF, `μ_{T+h}` is the h-step-ahead conditional mean, and `σ_{T+h}` is the h-step-ahead conditional standard deviation from the ARMA-GARCH model. All four final models use Normal errors.

| Currency | Date   | `μ_{T+h}` | `σ²_{T+h}` | `σ_{T+h}` | P(e < 0.01%) |
|---------|--------|----------|-----------|----------|-------------|
| CNY     | 13 Jan | −0.0049  | 0.2352    | 0.4850   | 0.5123      |
| CNY     | 14 Jan | −0.0057  | 0.2417    | 0.4916   | 0.5127      |
| USD     | 13 Jan | −0.0025  | 0.2432    | 0.4931   | 0.5101      |
| USD     | 14 Jan | −0.0023  | 0.2347    | 0.4844   | 0.5101      |
| TWI     | 13 Jan | −0.0543  | 0.1604    | 0.4005   | 0.5638      |
| TWI     | 14 Jan | −0.0014  | 0.1661    | 0.4075   | 0.5111      |
| SDR     | 13 Jan | −0.0136  | 0.2186    | 0.4675   | 0.5201      |
| SDR     | 14 Jan | −0.0098  | 0.2213    | 0.4704   | 0.5168      |

The table shows that the probabilities that returns are less than 0.01% for each currency on both dates all exceed 0.5. This means that no currency has a better-than-even chance of returning more than 0.01% on either day, limiting the return maximisation potential. Instead, the investment decision should focus on minimising risk, which corresponds to choosing the currency with the lowest conditional variance.

Based on this, TWI would be the preferred currency as it has the lowest conditional variance on both days of 0.1604 and 0.1661 on 13/01/2026 and 14/01/2026 respectively. Its low variance reflects the diversification of a trade-weighted index across multiple exchange rates. In comparison, USD, SDR and CNY all have higher conditional variances, making them less attractive from a risk-minimisation perspective.

However, TWI returns do have an unusually large negative conditional mean on 13/01/2026 of −0.054%, contributing to a larger probability of returns falling below 0.01% of 56.38%. However, this is still relatively close to the other probabilities ranging around approximately 51–52%, and does not reflect long-run risk. By 14/01/2026, the TWI conditional mean reverts toward zero (−0.001%) as the ARMA mean equation mean-reverts, and its probability falls to 0.5111 — comparable to the other currencies. This illustrates the short-lived nature of ARMA conditional mean deviations at the two-day horizon.
