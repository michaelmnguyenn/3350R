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

Unit root tests on Δp_t give an ADF p-value of 0.032 and a KPSS statistic of 0.731 (5% critical value is 0.463). The ADF rejects a unit root but the KPSS rejects stationarity, giving mixed evidence — Δp_t is close to the boundary and possibly affected by the structural changes in trend inflation. Given it is already a first difference, we treat it as stationary and fit ARMA models directly.

For r_t, the ADF p-value is 0.171 (fails to reject) and KPSS statistic is 1.763, strongly rejecting stationarity. We treat r_t as I(1) and fit ARIMA(p,1,q) models.

**ARMA models for Δp_t — AIC comparison**

| Model    | AIC      | BIC      |
|----------|----------|----------|
| ARMA(2,1)| −2579.82 | −2562.04 |
| ARMA(1,2)| −2565.91 | −2548.12 |
| ARMA(3,0)| −2543.72 | −2525.94 |
| ARMA(2,0)| −2543.28 | −2529.05 |
| ARMA(1,1)| −2539.69 | −2525.46 |

The three best by AIC are ARMA(2,1), ARMA(1,2), and ARMA(3,0). The ACF and PACF show significant autocorrelation at lags 1 and 2 which supports an AR component, and the relatively slow ACF decay suggests some MA structure too.

Estimated ARMA(2,1): ar₁ = 0.478 (SE = 0.056), ar₂ = 0.447 (SE = 0.056), ma₁ = 1.000 (SE = 0.016), mean = 0.0089, σ² = 2.625×10⁻⁶.

**ARIMA models for r_t — AIC comparison**

| Model        | AIC    | BIC    |
|--------------|--------|--------|
| ARIMA(2,1,1) | 504.38 | 518.61 |
| ARIMA(1,1,1) | 506.19 | 516.86 |
| ARIMA(3,1,0) | 507.93 | 522.16 |

### 2(a) — Forecast Plot

**[INSERT fig_q2_forecast.png]**

| Quarter | ARMA(2,1) | ARMA(1,2) | ARMA(3,0) | 95% CI lower | 95% CI upper |
|---------|-----------|-----------|-----------|-------------|-------------|
| 2024Q1  | 0.00907   | 0.00801   | 0.00849   | 0.00588      | 0.01225      |
| 2024Q2  | 0.00896   | 0.00805   | 0.00841   | 0.00329      | 0.01463      |
| 2024Q3  | 0.00900   | 0.00814   | 0.00838   | 0.00225      | 0.01575      |
| 2024Q4  | 0.00897   | 0.00823   | 0.00839   | 0.00120      | 0.01674      |
| 2025Q1  | 0.00898   | 0.00830   | 0.00843   | 0.00046      | 0.01749      |
| 2025Q2  | 0.00897   | 0.00837   | 0.00847   | −0.00019     | 0.01813      |
| 2025Q3  | 0.00896   | 0.00843   | 0.00852   | −0.00073     | 0.01866      |
| 2025Q4  | 0.00896   | 0.00849   | 0.00856   | −0.00120     | 0.01911      |

All three models converge fairly quickly toward the sample mean of around 0.009. This is expected from stationary ARMA processes — forecasts revert to the unconditional mean as the horizon increases.

### 2(b) — Policy Discussion

Inflation forecasts like these are directly useful for monetary policy. The Federal Reserve uses inflation projections when deciding on interest rate changes — if inflation is forecast to stay above the 2% target, the Fed may maintain or raise rates, whereas a declining inflation path could support cuts. Fiscal authorities also use inflation projections to index spending programs and estimate real borrowing costs.

There are several sources of uncertainty worth distinguishing. First, each future period introduces an unpredictable shock ε_t — the 95% confidence interval starts at a width of 0.00636 at h=1 and widens to 0.02031 at h=8, directly showing how much this accumulates. Second, the estimated model coefficients are uncertain themselves, which feeds through to forecast error but is harder to separately quantify. Third, there is model uncertainty — the three models give noticeably different forecasts (e.g., at h=1 the range is 0.00801 to 0.00907), and all three may be misspecified in some way. Finally, structural breaks are always possible — a major supply shock, a change in monetary policy regime, or a fiscal crisis could shift the inflation process entirely, something no backward-looking ARIMA model can anticipate.

---

## Question 3

### Forecast Evaluation

Using the actual P_t values from the table and P_{2023Q4} = 14.547 from the dataset, the actual Δp_t values for 2024Q1–2025Q3 are:

| Quarter | Actual Δp_t | ARMA(2,1) | ARMA(1,2) | ARMA(3,0) |
|---------|------------|-----------|-----------|-----------|
| 2024Q1  | 0.00798    | 0.00907   | 0.00801   | 0.00849   |
| 2024Q2  | 0.00829    | 0.00896   | 0.00805   | 0.00841   |
| 2024Q3  | 0.00761    | 0.00900   | 0.00814   | 0.00838   |
| 2024Q4  | 0.00636    | 0.00897   | 0.00823   | 0.00839   |
| 2025Q1  | 0.00711    | 0.00898   | 0.00830   | 0.00843   |
| 2025Q2  | 0.00634    | 0.00897   | 0.00837   | 0.00847   |
| 2025Q3  | 0.00643    | 0.00896   | 0.00843   | 0.00852   |

**Forecast performance:**

| Model     | MSFE       | RMSFE    | MAE      |
|-----------|------------|----------|----------|
| ARMA(2,1) | 3.89×10⁻⁶ | 0.001973 | 0.001829 |
| ARMA(1,2) | 1.92×10⁻⁶ | 0.001384 | 0.001129 |
| ARMA(3,0) | 2.24×10⁻⁶ | 0.001496 | 0.001284 |

ARMA(1,2) performs best on both MSFE and MAE, roughly halving the error of ARMA(2,1). All seven actual observations fall within the 95% confidence interval of Model 1, so the uncertainty coverage is appropriate even though the point forecasts are biased.

All three models systematically overpredict inflation throughout the evaluation window — they forecast around 0.009 while actual inflation was trending down from 0.008 toward 0.006. This reflects a standard limitation of ARIMA models: they project the historical average forward, but actual US inflation decelerated sharply through 2024 as Federal Reserve rate hikes worked through the economy and supply chains normalised. The models estimated during 2023 were influenced by the unusually high inflation of 2021–2022, pulling the forecasted mean upward. ARMA(1,2) handles this slightly better because its larger MA structure responds more flexibly to the reverting dynamics, but none of the models can fully account for the structural nature of the disinflation.

---

## Question 4

### 4(a) — Real Interest Rate

**[INSERT fig4a_realrate.png]**

The real interest rate rr_t = r_t − Δp_t ranges from 0.007 to 15.03 with a mean of 4.34 across the sample. Since r_t is expressed in annualised percentage terms and Δp_t is a quarterly log-difference, rr_t closely tracks the nominal rate, with the Δp_t term providing a small quarterly adjustment. The plot shows the same broad patterns as r_t: high and rising through the early 1980s at the peak of the Volcker tightening, declining through the 1990s and 2000s, falling to near zero during the quantitative easing period after 2008, and rising sharply from 2022 onward. The real rate shows less of an outright downward trend than the nominal rate over the full sample, consistent with a weak Fisher effect — the nominal rate and inflation broadly moved together, leaving the real rate oscillating but without a clear long-run trend.

**ARIMA for rr_t:**

ADF (p = 0.109) and KPSS (stat = 1.782) both indicate rr_t is non-stationary, so d=1. The best model by AIC is ARIMA(2,1,2)(0,0,1)[4] — AIC = 484.66. The seasonal MA(1) term picks up residual quarterly regularities in Treasury bill rates.

| Parameter | Estimate | SE    |
|-----------|----------|-------|
| ar₁       | −1.273   | 0.074 |
| ar₂       | −0.508   | 0.077 |
| ma₁       | 1.770    | 0.054 |
| ma₂       | 0.874    | 0.046 |
| sma₁      | 0.127    | 0.086 |

The complex AR-MA structure captures the strong persistence in rr_t alongside the oscillating behaviour visible in the plot.

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

**Step 2: Mean equation**

Ljung-Box tests on raw returns show serial correlation in CNY (p = 0.002), TWI (p = 0.0001), and SDR (p ≈ 0), but not USD (p = 0.056). This guides the ARMA order: USD and CNY use ARMA(0,0), TWI uses ARMA(1,0) to remove the autocorrelation, and SDR uses ARMA(0,1).

**Step 3: Variance equation and distribution**

A grid search over symmetric GARCH(1,1) and asymmetric GJR-GARCH(1,1) under both Normal and Student-t errors is conducted. The Student-t distribution consistently produces lower AIC (by approximately 0.04–0.05 across all series), confirming that exchange rate returns have heavier tails than the normal. GJR-GARCH(1,1) additionally outperforms symmetric GARCH(1,1) by AIC, with the leverage parameter γ > 0 capturing asymmetric volatility responses.

**Final model selection:**

| Currency | Mean Model | GARCH Type     | Errors    | AIC    | BIC    |
|----------|-----------|----------------|-----------|--------|--------|
| CNY      | ARMA(0,0) | GJR-GARCH(1,1) | Student-t | 1.5243 | 1.5410 |
| USD      | ARMA(0,0) | GJR-GARCH(1,1) | Student-t | 1.7963 | 1.8130 |
| TWI      | ARMA(1,0) | GJR-GARCH(1,1) | Student-t | 1.2830 | 1.3024 |
| SDR      | ARMA(0,1) | GJR-GARCH(1,1) | Student-t | 1.7938 | 1.8132 |

**Estimated coefficients:**

*CNY:* μ = −0.014, ω = 0.0067, α = 0.014, β = 0.932, γ = 0.062, ν = 8.0

*USD:* μ = −0.014, ω = 0.0042, α = 0.001, β = 0.961, γ = 0.052, ν = 8.5

*TWI:* μ = −0.007, φ₁ = −0.040, ω = 0.0070, α = 0.022, β = 0.919, γ = 0.055, ν = 8.0

*SDR:* μ = −0.008, θ₁ = −0.181, ω = 0.0055, α = 0.018, β = 0.949, γ = 0.036, ν = 7.8

The large β estimates (0.88–0.96) across all series indicate high persistence in conditional volatility — a shock today will take a long time to decay. The positive γ confirms the leverage effect: negative return shocks produce a larger increase in volatility than positive shocks of the same magnitude. The Student-t degrees of freedom (ν ≈ 7.5–8.5) confirms the presence of heavy tails not captured by the Normal.

**Diagnostics:**

| Currency | LB on z (p) | LB on z² (p) |
|----------|-------------|--------------|
| CNY      | 0.44 ✓     | 0.0002       |
| USD      | 0.69 ✓     | 0.0000       |
| TWI      | 0.69 ✓     | 0.0000       |
| SDR      | 0.94 ✓     | 0.0000       |

The mean equations are well-specified — the Ljung-Box on standardised residuals is insignificant for all series. The squared standardised residuals still show some serial correlation, suggesting GJR-GARCH(1,1) does not perfectly capture all volatility dynamics. This is common in high-frequency financial data particularly given the COVID-19 outlier in March 2020, and GJR-GARCH(1,1) remains the standard benchmark in the literature.

**[INSERT fig6_vol_CNY.png]**
**[INSERT fig6_vol_USD.png]**
**[INSERT fig6_vol_TWI.png]**
**[INSERT fig6_vol_SDR.png]**

The conditional volatility plots show the COVID-19 spike in March 2020 as the dominant event across all currencies, with elevated but lower volatility around 2022–2023. The TWI shows the most contained spike, consistent with its lower sample variance.

---

## Question 7

### Unconditional Variance: Model vs Sample

For a GJR-GARCH(1,1) model the unconditional variance (assuming covariance stationarity) is:

σ² = ω / (1 − α − β − γ/2)

This requires α + β + γ/2 < 1, which holds for all four series:

| Currency | α+β+γ/2 | σ²_model | σ²_sample | Ratio |
|----------|---------|---------|-----------|-------|
| CNY      | 0.9771  | 0.2925  | 0.3369    | 0.868 |
| USD      | 0.9879  | 0.3455  | 0.4381    | 0.789 |
| TWI      | 0.9685  | 0.2234  | 0.2675    | 0.835 |
| SDR      | 0.9848  | 0.3638  | 0.4492    | 0.810 |

Since α + β + γ/2 < 1 for all currencies, the unconditional variance is well-defined — none of the series exhibit IGARCH behaviour, where the unconditional variance would be infinite.

The model estimates are consistently 13–21% below the sample variances. This is primarily because the sample period (January 2018–January 2026) includes the COVID-19 shock in March 2020, an extreme volatility event that disproportionately inflates the sample variance relative to the long-run unconditional level. The GARCH model, by modelling time-varying volatility explicitly, can distinguish the temporary COVID spike from the underlying long-run variance. The relative ordering across currencies is preserved (TWI lowest, SDR/USD highest), which is consistent with the results in Question 5.

---

## Question 8

### Probability of Return Below 0.01%

Using the fitted GJR-GARCH models, two-step ahead forecasts of conditional mean and standard deviation are computed from the last observation (12 January 2026). Under the Student-t distribution with estimated degrees of freedom ν, the probability is:

P(e_{j,t} < 0.01) = P(t_ν < (0.01 − μ_{T+h}) / σ_{T+h})

**Results:**

| Currency | μ_{T+1} | σ_{T+1} | P(13/01) | μ_{T+2} | σ_{T+2} | P(14/01) |
|----------|--------|--------|---------|--------|--------|---------|
| CNY      | −0.0143 | 0.4524 | 0.5207  | −0.0143 | 0.4547 | 0.5206  |
| USD      | −0.0140 | 0.4432 | 0.5209  | −0.0140 | 0.4452 | 0.5209  |
| TWI      | −0.0070 | 0.3775 | 0.5174  | −0.0068 | 0.3809 | 0.5170  |
| SDR      | −0.0230 | 0.4449 | 0.5286  | −0.0084 | 0.4477 | 0.5159  |

All probabilities are slightly above 0.50 because mean returns are slightly negative — the AUD has depreciated modestly, so there is a marginally higher chance that any given day's return falls below 0.01%.

For a foreign currency investor, a higher P(e < 0.01%) means a higher chance of earning essentially zero or negative returns on that day — more risk. The preferred currency is the one with the **lowest** probability.

On **13 January**, the safest investment is **TWI** (P = 0.5174), followed by CNY (0.5207), USD (0.5209), and SDR (0.5286). TWI benefits from its low conditional volatility (σ = 0.378%) — because the spread of possible return outcomes is smaller, the probability mass below the 0.01% threshold is lower. SDR is riskiest on this date because its conditional mean for T+1 is unusually negative (−0.023%) due to the MA(1) momentum effect, pushing more probability mass below the threshold.

On **14 January**, the ranking shifts: SDR (0.5159) becomes the safest as its mean reverts back to −0.008%, while TWI remains consistently low at 0.517. USD stays the same at 0.5209 since its conditional mean barely changes across horizons.

In practice, a risk manager would favour **TWI** across both days given its consistently low downside probability. This reflects a broader principle: for short-term FX positions, using the GARCH-implied conditional variance to update risk estimates daily is more informative than using the unconditional sample variance, because it captures the current state of the market — whether conditions are calm or volatile — and prices risk accordingly.
