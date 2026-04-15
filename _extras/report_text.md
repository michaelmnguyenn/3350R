# ECON3350 Research Report – Draft Answers
Rewrite these in your own words. Numbers are all verified from R.

---

## Question 1

### 1(a)

**[INSERT fig1_loglevels.png]**

**[INSERT fig2_logdiffs.png]**

Looking at the log levels, all three series trend upward across the sample. The log price level p_t rises steadily, with noticeably faster growth during the 1970s oil shock period before moderating after the Volcker disinflation in the early 1980s. Log GDP per capita y_t and log consumption c_t move almost in parallel throughout — both grow at a fairly consistent pace with brief dips during recessions. None of these series show any tendency to revert to a fixed value, which suggests they are non-stationary.

In the second plot, differencing removes the trends and the series look much more stable. Quarterly inflation Δp_t bounces around with heightened volatility in the 1970s and again during the 2021-2023 post-pandemic spike, but otherwise sits fairly low from the 1990s onward. Δy_t and Δc_t both fluctuate around a positive mean with clear drops during the major recessions (1974, 1980, 2009, 2020). The interest rate r_t shows no upward trend but is quite persistent — high and rising through the late 1970s and early 1980s, then declining over subsequent decades, falling to near zero after 2008, and sharply rising again from 2022.

### 1(b)

**Part (i) — Trend regressions**

| Series | Intercept (μ̂) | Trend (δ̂) | SE(δ̂)   | R²    |
|--------|--------------|-----------|---------|-------|
| p_t    | 0.271        | 0.010125  | 0.000147 | 0.949 |
| y_t    | 9.945        | 0.004757  | 0.000042 | 0.980 |
| c_t    | 9.429        | 0.005305  | 0.000043 | 0.983 |

All trend coefficients are highly significant. The high R² values confirm a linear trend explains most of the variation in each series.

**Part (ii) — Means of first differences**

| Series | Mean (μ̂) |
|--------|----------|
| Δp_t   | 0.009310 |
| Δy_t   | 0.004919 |
| Δc_t   | 0.005379 |

**Part (iii)**

These two exercises both try to measure the same thing: the average rate of change of each series over time. If a series follows a random walk with drift (y_t = y_{t-1} + δ + ε_t), then regressing the level on a time trend gives δ̂ as an estimate of that drift. Alternatively, first-differencing gives Δy_t = δ + ε_t, so the sample mean of the differences estimates the same drift. Both methods should give nearly identical answers.

Looking at the numbers this holds well: for y_t the trend coefficient is 0.004757 vs mean of Δy of 0.004919, and for c_t it's 0.005305 vs 0.005379. The small difference for p_t (0.010125 vs 0.009310) is likely due to the structural shift in trend inflation — the OLS regression weighs the high-inflation 1970s and early 1980s differently than the sample mean approach when there is a structural break.

---

## Question 2

### Model Selection

**Stationarity tests**

Unit root tests on Δp_t give an ADF p-value of 0.032 — marginal rejection of a unit root — so we treat it as stationary and fit ARMA models directly (d = 0). For r_t, the ADF p-value is 0.171 (fails to reject the unit root). However, following the exemplar approach, we conduct a wide grid search with d = 0 and large ARMA orders (p, q = 0,...,10) to capture the high persistence of interest rates without imposing a unit root. This avoids the over-differencing that d = 1 can introduce when the series is merely highly persistent rather than genuinely non-stationary.

**ARIMA models for Δp_t — AIC comparison (top 5, wide grid p,q = 0:10, d = 0)**

| Model          | AIC        | BIC        |
|----------------|------------|------------|
| ARIMA(3,0,6)   | −2682.912  | −2647.343  |
| ARIMA(2,0,10)  | −2682.726  | −2636.487  |
| ARIMA(4,0,7)   | −2681.982  | −2639.300  |
| ARIMA(2,0,9)   | −2681.685  | −2639.003  |
| ARIMA(4,0,9)   | −2681.300  | −2631.504  |

The three selected models are ARIMA(2,0,10), ARIMA(4,0,9), and ARIMA(2,0,9) — all stationary (d = 0), no constant, with the top AIC values and adequate residual diagnostics. Selected ARIMA(2,0,10) coefficients: ar₁ = 1.414, ar₂ = −0.418, ma₁–ma₁₀ capture complex lag dynamics (see R output).

**ARIMA models for r_t — AIC comparison (top 5, wide grid p,q = 0:10, d = 0)**

| Model          | AIC     | BIC     |
|----------------|---------|---------|
| ARIMA(8,0,5)   | 480.08  | 529.93  |
| ARIMA(8,0,6)   | 480.52  | 533.93  |
| ARIMA(9,0,5)   | 480.73  | 534.14  |
| ARIMA(8,0,2)   | 481.07  | 520.24  |
| ARIMA(4,0,6)   | 481.11  | 520.27  |

The three selected models are ARIMA(8,0,5), ARIMA(8,0,6), and ARIMA(8,0,2). Large AR orders (p = 8) are needed to capture the long memory and slow mean-reversion of interest rates without differencing.

### 2(a) — Forecast Plot

**[INSERT fig2a_forecast.png]**

**[INSERT fig2b_r_forecast.png]**

**Inflation forecasts (h = 1 to 7 quarters ahead, 95% CI for ARIMA(2,0,10)):**

| Quarter | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) | 95% CI lower | 95% CI upper |
|---------|---------------|--------------|--------------|-------------|-------------|
| 2024Q1  | 0.00798       | 0.00801      | 0.00808      | 0.00545      | 0.01051      |
| 2024Q2  | 0.00683       | 0.00682      | 0.00722      | 0.00224      | 0.01141      |
| 2024Q3  | 0.00656       | 0.00667      | 0.00718      | 0.00000      | 0.01312      |
| 2024Q4  | 0.00581       | 0.00594      | 0.00623      | −0.00304     | 0.01466      |
| 2025Q1  | 0.00604       | 0.00650      | 0.00655      | −0.00381     | 0.01590      |
| 2025Q2  | 0.00689       | 0.00741      | 0.00682      | −0.00378     | 0.01756      |
| 2025Q3  | 0.00737       | 0.00807      | 0.00711      | −0.00416     | 0.01891      |

All three inflation models quickly move away from the last observed value and converge toward the long-run mean (around 0.007–0.008). The 95% interval widens from ±0.00253 at h=1 to ±0.01154 at h=7, reflecting the accumulation of forecast uncertainty.

**Interest rate forecasts (h = 1 to 7 quarters ahead, ARIMA(8,0,5) point forecasts):**

| Quarter | ARIMA(8,0,5) | 95% CI lower | 95% CI upper |
|---------|-------------|-------------|-------------|
| 2024Q1  | 5.200       | 4.053        | 6.347        |
| 2024Q2  | 5.135       | 3.095        | 7.175        |
| 2024Q3  | 4.726       | 2.231        | 7.221        |
| 2024Q4  | 4.316       | 1.349        | 7.283        |
| 2025Q1  | 4.109       | 0.679        | 7.539        |
| 2025Q2  | 3.826       | 0.018        | 7.635        |
| 2025Q3  | 3.467       | −0.709       | 7.642        |

The interest rate forecast declines gradually from 5.20% toward the long-run mean, consistent with the high-rate environment observed from 2022-2023 moderating over the forecast horizon.

### 2(b) — Policy Discussion

Inflation forecasts like these are directly useful for monetary policy. The Federal Reserve uses inflation projections when deciding on interest rate changes — if inflation is forecast to stay above the 2% target, the Fed may maintain or raise rates, whereas a declining inflation path could support cuts. Fiscal authorities also use inflation projections to index spending programs and estimate real borrowing costs.

There are several sources of uncertainty worth distinguishing. First, each future period introduces an unpredictable shock ε_t — the 95% confidence interval for ARIMA(2,0,10) starts at a width of 0.00506 at h=1 and widens to 0.02307 at h=7, directly showing how much this accumulates. Second, the estimated model coefficients are uncertain themselves, which feeds through to forecast error but is harder to separately quantify. Third, there is model uncertainty — the three models give slightly different forecasts (e.g., at h=1 the range is 0.00798 to 0.00808), and all three may be misspecified in some way. Finally, structural breaks are always possible — a major supply shock, a change in monetary policy regime, or a fiscal crisis could shift the inflation process entirely, something no backward-looking ARIMA model can anticipate.

---

## Question 3

### Forecast Evaluation

Using the actual P_t values from the table and P_{2023Q4} = 14.547 from the dataset, the actual Δp_t values for 2024Q1–2025Q3 are:

| Quarter | Actual Δp_t | ARIMA(2,0,10) | ARIMA(4,0,9) | ARIMA(2,0,9) |
|---------|------------|---------------|--------------|--------------|
| 2024Q1  | 0.00798    | 0.00798       | 0.00801      | 0.00808      |
| 2024Q2  | 0.00829    | 0.00683       | 0.00682      | 0.00722      |
| 2024Q3  | 0.00761    | 0.00656       | 0.00667      | 0.00718      |
| 2024Q4  | 0.00636    | 0.00581       | 0.00594      | 0.00623      |
| 2025Q1  | 0.00711    | 0.00604       | 0.00650      | 0.00655      |
| 2025Q2  | 0.00634    | 0.00689       | 0.00741      | 0.00682      |
| 2025Q3  | 0.00643    | 0.00737       | 0.00807      | 0.00711      |

**Forecast performance:**

| Model          | MSFE       | RMSFE    | MAE      |
|----------------|------------|----------|----------|
| ARIMA(2,0,10)  | 8.40×10⁻⁷ | 0.000916 | 0.000803 |
| ARIMA(4,0,9)   | 1.06×10⁻⁶ | 0.001030 | 0.000884 |
| ARIMA(2,0,9)   | 3.39×10⁻⁷ | 0.000582 | 0.000494 |

ARIMA(2,0,9) performs best on both MSFE and MAE — roughly 60% lower error than ARIMA(2,0,10). All seven actual observations fall within the 95% confidence interval of Model 1 (ARIMA(2,0,10)), so the uncertainty coverage is appropriate even though point forecasts diverge from actuals at longer horizons.

The models perform well at h=1 (ARIMA(2,0,10) achieves near-perfect 2024Q1 forecast) but diverge at longer horizons. This reflects the difficulty all ARIMA models face with inflation: they project from historical dynamics, but actual US inflation decelerated sharply through 2024 as Federal Reserve rate hikes worked through the economy. ARIMA(2,0,9) handles the medium-run better because its large MA order adapts more flexibly to the reverting pattern, but none of the models can fully anticipate the structural nature of the disinflation.

---

## Question 4

### 4(a) — Real Interest Rate

**[INSERT fig4a_realrate.png]**

The real interest rate rr_t = r_t − Δp_t ranges from 0.007 to 15.03 with a mean of 4.34 across the sample. Since r_t is expressed in annualised percentage terms and Δp_t is a quarterly log-difference, rr_t closely tracks the nominal rate, with the Δp_t term providing a small quarterly adjustment. The plot shows the same broad patterns as r_t: high and rising through the early 1980s at the peak of the Volcker tightening, declining through the 1990s and 2000s, falling to near zero during the quantitative easing period after 2008, and rising sharply from 2022 onward. The real rate shows less of an outright downward trend than the nominal rate over the full sample, consistent with a weak Fisher effect — the nominal rate and inflation broadly moved together, leaving the real rate oscillating but without a clear long-run trend.

**ARIMA for rr_t:**

The ADF test (H₀: unit root) is used to determine the integration order. The full aTSA table (Types I–III, lags 0–4) shows that the closest result to rejection is Type II (with drift, no trend) at lag 3: ADF = −2.57, p = 0.105 — right at the 10% boundary. While this is borderline, it does not cleanly reject the unit root at conventional significance levels.

However, setting d = 0 is supported on economic grounds: real interest rates are widely regarded as I(0) in the macroeconomics literature (Fisher hypothesis, monetary policy mean-reversion). The plot confirms that rr_t oscillates around a positive long-run mean of approximately 4.26% without any apparent drift, consistent with stationarity. The near-rejection in the ADF is likely a consequence of the high persistence in rr_t — a well-known source of low power in unit root tests — rather than genuine non-stationarity.

We therefore set d = 0. A wide ARIMA(p, 0, q) grid search (p, q = 0,...,10) is conducted and ARIMA(8, 0, 1) is selected by AIC — AIC = 477.10, BIC = 516.22:

| Parameter  | Estimate | SE    |
|------------|----------|-------|
| ar₁        | 0.605    | —     |
| ar₂        | 0.341    | —     |
| ar₃        | 0.101    | —     |
| ar₄        | 0.097    | —     |
| ar₅        | −0.171   | —     |
| ar₆        | 0.103    | —     |
| ar₇        | −0.405   | —     |
| ar₈        | 0.274    | —     |
| ma₁        | 0.869    | —     |
| intercept  | 4.231    | —     |

The eight AR lags capture the high persistence and slow reversion characteristic of real interest rates. The MA(1) term handles the short-run shock dynamics. The intercept (4.23) directly estimates the long-run mean of the real interest rate.

### 4(b) — Consumption Ratio

**[INSERT fig4b_consratio.png]**

The consumption ratio cy_t = C_t/Y_t rises from around 0.59 in 1959 to approximately 0.69 by 2023, with a sample mean of 0.642. The dominant feature is a persistent upward trend — consumption has grown as a larger share of GDP over the six-decade sample. This pattern is consistent with the decline in the US personal saving rate over the same period, driven by easier access to credit and financial innovation, wealth effects from rising equity and housing prices, and demographic shifts as baby boomers moved into peak consumption phases of the lifecycle. Permanent income theory also predicts that as credit markets deepen, households can smooth consumption more effectively, raising the long-run consumption-income ratio.

**ARIMA for cy_t:**

ADF (p = 0.030) provides borderline rejection of a unit root but KPSS (stat = 4.14) strongly rejects stationarity, pointing to a trending series. Best model by AIC is ARIMA(2,1,2) — AIC = −2129.79. Differencing removes the trend and the ARMA(2,2) structure captures short-run fluctuations.

| Parameter | Estimate | SE    |
|-----------|----------|-------|
| ar₁       | −0.341   | 0.136 |
| ar₂       | −0.848   | 0.089 |
| ma₁       | 0.208    | 0.149 |
| ma₂       | 0.841    | 0.069 |

### 4(e) — Policy Implications

The rr_t model helps central banks assess whether the current stance of monetary policy is genuinely restrictive or accommodative in real terms. Rather than looking only at the nominal rate, policymakers can use the model to forecast real rates and judge whether they are above or below the neutral real rate — a key input to the Taylor rule.

The cy_t model is useful for fiscal policymakers and aggregate demand analysis. A rising consumption ratio signals households are spending a growing fraction of income, which affects the size of fiscal multipliers — tax cuts or transfers have larger demand effects when households have a high propensity to consume. Central banks also track cy_t as an indicator of household vulnerability: a very high consumption-to-income ratio may suggest excessive borrowing and rising financial fragility.

---

## Question 5

### 5(a) — Sample Variances

| Currency | σ²_sample | SD (%)  |
|----------|-----------|---------|
| CNY      | 0.3369    | 0.580   |
| USD      | 0.4381    | 0.662   |
| TWI      | 0.2675    | 0.517   |
| SDR      | 0.4492    | 0.670   |

TWI has the lowest variance, which makes sense given it is a trade-weighted average across multiple bilateral rates — diversification across trading partners smooths out bilateral movements. SDR has the highest, despite also being a basket, because it includes GBP and JPY which can move significantly against the AUD. CNY is less volatile than USD, reflecting the People's Bank of China's managed float where daily movements are constrained by intervention. USD/AUD is a freely floating bilateral rate exposed to commodity cycles and monetary policy divergence, which drives its higher variance.

### 5(b) — Absolute Returns Plot

**[INSERT fig5_absreturns.png]**

All four series show clear volatility clustering — large absolute returns bunch together in time, and quiet periods also cluster. The most obvious spike across all currencies is March 2020 (COVID-19 pandemic onset), where daily moves exceeded 3–5%. There is also a noticeable pickup in volatility through 2022–2023 during the aggressive Fed rate hike cycle. These patterns directly motivate GARCH-type models: the constant-variance assumption of ARMA is clearly violated, and the conditional variance needs to be modelled explicitly.

---

## Question 6

### Model Selection Process

**Step 1: Testing for ARCH effects**

Before fitting GARCH models, the presence of conditional heteroskedasticity is confirmed. The ARCH LM test (Engle, 1982) gives p ≈ 0 at lag 10 for all four currencies, and the Ljung-Box test on squared returns is also p ≈ 0 for all series. Both tests decisively reject the null of constant variance.

**Step 2: Mean and variance equation selection**

A joint ARMA(p,q)-GARCH(ph,qh) grid search is conducted over p, q ∈ {0,1,2} and ph, qh ∈ {0,1,2} (81 combinations per currency), using standard sGARCH with Normal errors. Models are selected from the adequate set — the intersection of the top-10 AIC and top-10 BIC candidates.

**Final model selection:**

| Currency | Mean Model | GARCH Type    | Errors | AIC    | BIC    |
|----------|-----------|---------------|--------|--------|--------|
| CNY      | ARMA(2,2) | sGARCH(2,2)  | Normal | 1.5553 | 1.5803 |
| USD      | ARMA(2,2) | sGARCH(2,2)  | Normal | 1.8352 | 1.8631 |
| TWI      | ARMA(2,2) | sGARCH(2,2)  | Normal | 1.3109 | 1.3387 |
| SDR      | ARMA(2,2) | sGARCH(2,1)  | Normal | 1.8195 | 1.8446 |

**Estimated coefficients:**

*CNY (no intercept):* ar₁ = 1.923, ar₂ = −0.924, ma₁ = −1.948, ma₂ = 0.948, ω = 0.0291, α₁ = 0.138, α₂ ≈ 0, β₁ = 0.313, β₂ = 0.454

*USD:* μ = 0.001, ar₁ = 1.945, ar₂ = −0.946, ma₁ = −1.958, ma₂ = 0.958, ω = 0.0150, α₁ = 0.129, α₂ ≈ 0, β₁ = 0.229, β₂ = 0.611

*TWI:* μ = −0.003, ar₁ = −1.084, ar₂ = −0.994, ma₁ = 1.085, ma₂ = 0.988, ω = 0.0232, α₁ = 0.157, α₂ ≈ 0, β₁ = 0.224, β₂ = 0.522

*SDR:* μ = −0.004, ar₁ = 1.012, ar₂ = −0.030, ma₁ = −1.191, ma₂ = 0.188, ω = 0.0169, α₁ = 0.131, β₁ = 0.232, β₂ = 0.599

The sum of ARCH (α) and GARCH (β) coefficients is close to but below 1 for all series, indicating high but stationary volatility persistence — shocks to variance decay slowly. The ARMA(2,2) structure in the mean equation captures the short-run autocorrelation in daily returns, with near-cancelling AR and MA roots reflecting the high-frequency but weak serial dependence.

**Diagnostics (Ljung-Box, 10 lags):**

| Currency | LB on z (p)  | LB on z² (p) |
|----------|-------------|--------------|
| CNY      | 0.394 ✓    | 0.010        |
| USD      | 0.640 ✓    | 0.083 ✓     |
| TWI      | 0.460 ✓    | 0.088 ✓     |
| SDR      | 0.267 ✓    | 0.006        |

All mean equations are well-specified (LB on z insignificant for all). USD and TWI pass the squared-residual test, while CNY and SDR show mild remaining ARCH effects — a common feature in high-frequency FX data given the extreme COVID-19 volatility event in March 2020.

The combined ACF/PACF/Ljung-Box diagnostic figure for squared standardised residuals z² (lags 1–20) is shown below:

**[INSERT fig6_sq_resid_diagnostics.png]**

**[INSERT fig6_vol_CNY.png]**
**[INSERT fig6_vol_USD.png]**
**[INSERT fig6_vol_TWI.png]**
**[INSERT fig6_vol_SDR.png]**

The conditional volatility plots show the COVID-19 spike in March 2020 as the dominant event across all currencies, with elevated but lower volatility around 2022–2023. TWI shows the most contained spike, consistent with its lower sample variance.

---

## Question 7

### Unconditional Variance: Model vs Sample

For a standard sGARCH model with ARCH orders α₁, …, αₚ and GARCH orders β₁, …, βq the unconditional variance (assuming covariance stationarity) is:

σ² = ω / (1 − Σαᵢ − Σβⱼ)

This requires Σαᵢ + Σβⱼ < 1, which holds for all four series:

| Currency | Persistence (Σα+Σβ) | σ²_model | σ²_sample | Ratio  |
|----------|---------------------|---------|-----------|--------|
| CNY      | 0.9054              | 0.3081  | 0.3369    | 0.9146 |
| USD      | 0.9683              | 0.4725  | 0.4381    | 1.0786 |
| TWI      | 0.9030              | 0.2393  | 0.2675    | 0.8947 |
| SDR      | 0.9623              | 0.4474  | 0.4492    | 0.9960 |

Since persistence < 1 for all currencies, the unconditional variance is well-defined — none of the series exhibit IGARCH behaviour.

For CNY, TWI, and SDR the model variance sits close to or below the sample variance. CNY (ratio = 0.91) and TWI (ratio = 0.89) sit slightly below their sample variances because the March 2020 COVID-19 spike inflates the sample average but is treated as a temporary deviation by the GARCH model. SDR has a ratio of 0.996 — the GARCH long-run variance almost exactly matches the sample, indicating the model cleanly captures the unconditional volatility level. USD's model variance slightly exceeds its sample variance (ratio = 1.08), suggesting the GARCH long-run level is marginally above the in-sample average. The relative ordering across currencies (TWI lowest, USD/SDR highest) is consistent with the sample variances from Question 5.

---

## Question 8

### Probability of Return Below 0.01%

Using the fitted sGARCH models, two-step ahead forecasts of conditional mean and standard deviation are computed from the last observation (12 January 2026). Under the Normal distribution assumed for the errors, the probability is:

P(e_{j,t} < 0.01) = Φ((0.01 − μ_{T+h}) / σ_{T+h})

where Φ is the standard Normal CDF.

**Results:**

| Currency | μ_{T+1}  | σ_{T+1} | P(13/01) | μ_{T+2}  | σ_{T+2} | P(14/01) |
|----------|---------|--------|---------|---------|--------|---------|
| CNY      | −0.0121 | 0.4946 | 0.5178  | −0.0118 | 0.5004 | 0.5174  |
| USD      | −0.0025 | 0.4931 | 0.5101  | −0.0023 | 0.4844 | 0.5101  |
| TWI      | −0.0543 | 0.4005 | 0.5638  | −0.0014 | 0.4075 | 0.5111  |
| SDR      | −0.0505 | 0.4792 | 0.5503  | −0.0332 | 0.4797 | 0.5359  |

All probabilities are slightly above 0.50 because mean returns are slightly negative — the AUD has depreciated modestly on average over the sample, so there is a marginally higher chance any given day's return falls below the 0.01% threshold.

For a foreign currency investor, a higher P(e < 0.01%) means a higher chance of earning essentially zero or negative returns — more downside risk. The preferred currency is the one with the **lowest** probability.

On **13 January**, the safest investment is **USD** (P = 0.5101), followed by CNY (0.5178), SDR (0.5503), and TWI (0.5638). Both SDR and TWI show elevated downside risk on this date: TWI's T+1 conditional mean is −0.0543% (driven by ARMA(2,2) momentum amplifying the most recent negative return) and SDR's mean is −0.0505%, both pushing significant probability mass below the threshold despite moderate unconditional volatility.

On **14 January**, the ranking shifts as the ARMA mean equations partially revert. TWI (0.5111) drops sharply to near-USD levels and becomes second-safest, while **USD** (0.5101) remains the safest. CNY (0.5174) stays stable. SDR (0.5359), however, remains notably elevated — its ARMA(2,2) mean equation reverts more slowly, maintaining a conditional mean of −0.0332% at T+2, making it the riskiest currency on the second day.

This illustrates how short-run ARMA dynamics can dominate the 1-step forecast but the degree of washout by the 2-step horizon varies by currency: TWI reverts almost completely, while SDR retains meaningful downside skew.

In practice, a risk manager would favour **USD** given its consistently low and stable downside probability across both horizons. This is consistent with USD/AUD having a near-zero conditional mean (close to random-walk behaviour) and moderate volatility — making it the most predictably neutral investment over a 2-day window.
