# ECON3350 Research Report

---

## Question 1

### 1(a) Exploratory Plots and Series Properties

**Figure 1**

**Figure 2**

The sample runs from 1959Q1 to 2023Q4 across the USA, giving 260 quarterly observations. The four series are the log price level `p_t`, log real GDP per capita `y_t`, log real consumption `c_t`, and the nominal 3-month T-bill rate `r_t`.

Looking at the level plots first, all three of `p_t`, `y_t`, and `c_t` drift steadily upward across the sample. Trending means like these make covariance stationarity in levels look unlikely. `y_t` and `c_t` follow each other closely, which is consistent with the idea that output and consumption share a common long-run growth path. `p_t` rises more steeply than the others, particularly through the inflationary period of the 1970s and early 1980s.

Once the series are differenced the picture changes considerably. `Δp_t`, `Δy_t`, and `Δc_t` fluctuate around fairly stable means rather than drifting upward. Inflation is still the noisiest of the three, but it does not trend. Output and consumption growth both dip sharply around the Global Financial Crisis and again in 2020, though they return to stable averages outside those episodes. The differenced series behave more like difference-stationary processes than trend-stationary ones.

`r_t` is harder to categorise. Rather than climbing steadily, it moves through slow-moving regimes: rising into the late 1970s and early 1980s, declining over the following decades, sitting near zero through much of the 2010s, then increasing again after 2021. Its defining feature is persistence, possibly with some regime change. A deterministic trend does not describe it well, and for this reason `r_t` should not be read in the same way as the log-level macro variables.

### 1(b)(i) Trend Regressions on Log Levels

| Series | Intercept | Trend (δ̂) | SE(Trend) | R² |
|---|---:|---:|---:|---:|
| `p_t` | 0.270678 | 0.010125 | 0.000147 | 0.9487 |
| `y_t` | 9.944853 | 0.004757 | 0.000042 | 0.9799 |
| `c_t` | 9.429001 | 0.005305 | 0.000043 | 0.9834 |

All three trend slopes are estimated precisely with very small standard errors, and the high R² values confirm that a simple linear trend accounts for most of the long-run variation in each log-level series.

### 1(b)(ii) Means of First Differences

| Series | Mean (μ̂) |
|---|---:|
| `Δp_t` | 0.009310 |
| `Δy_t` | 0.004919 |
| `Δc_t` | 0.005379 |

### 1(b)(iii) Rationale and Comparison

The trend regression and the mean of first differences measure average growth differently. The regression fits one straight line through the entire level series, while the mean of first differences just averages the quarter-to-quarter movements. For a difference-stationary series with a stable drift, the two approaches should produce similar numbers.

For `y_t` and `c_t` they do. The estimated trend slope for `y_t` is 0.004757, against a mean first difference of 0.004919. For `c_t`, the corresponding values are 0.005305 and 0.005379. The gap is wider for `p_t` (0.010125 versus 0.009310), which is not particularly surprising: the inflation surge of the 1970s and the subsequent disinflation distort a straight line fitted through the full sample more than they distort a simple average of quarterly changes.

The similarity of the numbers across all three series supports a difference-stationary reading. The regression forces a single linear path through 260 observations, which will always differ somewhat from period-by-period averaging. Even so, the close correspondence suggests the level series are driven by stochastic trends and stabilise after differencing. While this falls short of a formal unit-root test, it provides reasonable grounds for working with the differenced series in the ARIMA exercises that follow.

---

## Question 2

### 2(a) Model Selection

A broad grid of ARIMA(p,d,q) models was estimated for `Δp_t` and `r_t` over the full 1959Q1–2023Q4 sample, with `p, q` ranging from 0 to 10 and `d ∈ {0,1}`. Candidate models were ranked by AIC and BIC, then screened using the Ljung-Box test at 12 lags. Any specification leaving clear residual autocorrelation was excluded.

**Inflation** (`Δp_t`): Unit root testing and the exploratory plots both support treating `Δp_t` as stationary, so `d = 0` throughout. The three best-performing adequate specifications are:

| Inflation model | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,0,3) | −2686.38 | −2657.92 | 0.1010 |
| ARIMA(1,0,6) | −2685.30 | −2653.28 | 0.1150 |
| ARIMA(5,0,6) | −2685.21 | −2638.97 | 0.0687 |

All three capture the short-run dynamics of quarterly inflation reasonably well. ARIMA(3,0,3) is selected as the primary model: it has the lowest AIC and BIC in the set while passing the residual diagnostic screen.

**Interest rates** (`r_t`): The level plot for `r_t` suggests long swings and slow adjustment rather than steady trend growth, so both stationary and differenced specifications were considered. The full grid included some differenced specifications with slightly lower AIC values, but the level models were retained for the report because they match the visual interpretation of `r_t` as highly persistent without steady growth. Among the adequate level specifications, the three strongest candidates are:

| Interest rate model | AIC | BIC | Ljung-Box p-value | Selected |
|---|---:|---:|---:|---|
| ARIMA(4,0,6) | 477.47 | 520.19 | 0.1323 | Best adequate |
| ARIMA(8,0,1) | 478.25 | 517.41 | 0.2161 | Adequate |
| ARIMA(8,0,2) | 478.96 | 521.68 | 0.1584 | Adequate |

ARIMA(4,0,6) is retained as the benchmark given its lowest AIC among adequate level candidates and clean residual diagnostics. Since part (b) only asks for inflation forecasts, the interest-rate models are included to complete the selection exercise rather than to produce their own forecast set.

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

Across all three models, quarterly inflation gradually converges back toward a similar long-run mean. ARIMA(3,0,3) holds close to 0.0088–0.0089 throughout the horizon. ARIMA(1,0,6) sits a touch lower in the early quarters before converging. ARIMA(5,0,6) produces the lowest near-term forecasts of the three, though it too settles toward a similar level by 2025.

### 2(c) Policy Use and Forecast Uncertainty

Inflation forecasts matter for policy because spending and investment decisions are made based on where prices are expected to go, not where they are today. Central banks use forward-looking inflation estimates when calibrating interest rates. Fiscal authorities need them to assess real spending levels, tax revenues, and the real burden of debt.

Two types of uncertainty are worth distinguishing here. Innovation uncertainty arises from unpredictable future shocks, and it is the reason forecast intervals widen as the horizon extends. Model uncertainty is separate: the three specifications do not produce identical forecasts, particularly in the near term, which shows how sensitive the path is to the choice of model. The reported confidence bands capture the first kind of uncertainty, conditional on a single model. The spread across all three models speaks more directly to the second.

Beyond both of these, all forecasts assume the historical inflation process continues to hold out of sample. If the economy enters a new regime, whether through a supply disruption, a policy shift, or something else entirely, the model-based intervals may not adequately capture the true range of outcomes. The 68% and 95% bands summarise uncertainty under the assumption that the selected model remains the right one going forward, which is worth keeping in mind when interpreting them.

---

## Question 3

**Figures 4-6**

Actual quarterly inflation for 2024Q1–2025Q3 is computed as `Δp_t = log(P_t) − log(P_{t−1})`, anchored at `P_{2023Q4}` as the final in-sample observation.

| Quarter | Actual `Δp_t` | ARIMA(3,0,3) | ARIMA(1,0,6) | ARIMA(5,0,6) |
|---|---:|---:|---:|---:|
| 2024Q1 | 0.007964 | 0.008699 | 0.008527 | 0.008533 |
| 2024Q2 | 0.008313 | 0.008529 | 0.008246 | 0.008031 |
| 2024Q3 | 0.007613 | 0.008932 | 0.008493 | 0.007930 |
| 2024Q4 | 0.006339 | 0.008852 | 0.008212 | 0.007454 |
| 2025Q1 | 0.007146 | 0.008798 | 0.008218 | 0.007599 |
| 2025Q2 | 0.006288 | 0.008867 | 0.008348 | 0.008254 |
| 2025Q3 | 0.006477 | 0.008878 | 0.008419 | 0.008735 |

Question 3 asks for the three inflation forecasts from Question 2 to be evaluated against the realised inflation outcomes, so Figures 4-6 and the table above compare each forecast path with the actual series.

All three models over-predict inflation across most of the 2024–2025Q3 window. The actual values sit below each forecast path in nearly every quarter, so all three specifications expected inflation to be both higher and more persistent than it turned out to be.

Among the three, ARIMA(5,0,6) tracks the actual path most closely, particularly in 2024Q3 through 2025Q2. ARIMA(1,0,6) generally comes second, while ARIMA(3,0,3) produces the highest forecasts throughout and therefore the largest errors. Notably, the specification with the strongest in-sample fit by AIC and BIC is not the one that handles the out-of-sample disinflation best.

A reasonable interpretation is that inflation lost persistence after 2023 in a way the historical sample did not fully anticipate. All three models were trained on data that embedded a certain degree of inflationary momentum, and they projected that forward. The resulting errors are not scattered randomly across the models: they are systematic and shared, which points more toward a persistence problem or a mild regime change than to random model misspecification.

---

## Question 4

### 4(a) Real Interest Rate

**Figure 7**

Following the question's specification, the real rate proxy is defined as `rr_t = r_t − Δp_t`. Over the sample it has a mean of around 4.34, a minimum near 0.01, and a maximum of about 15.03.

The plot reveals that `rr_t` mostly tracks the nominal rate rather than inflation. Since `Δp_t` is small relative to `r_t`, subtracting it shifts the level only modestly. The same slow-moving persistence that defines `r_t` shows up here too: the proxy builds into the early 1980s, falls gradually through the following decades, and settles near zero through much of the 2010s before rising again.

### 4(b) Consumption Ratio

**Figure 8**

The consumption ratio `cy_t = C_t/Y_t` drifts upward across the sample, rising from around 0.590 in the early years to roughly 0.693 by 2023Q4. Short-run fluctuations are relatively contained. The main story is not volatility but the sustained long-run increase in consumption's share of GDP, which reflects household spending growing faster than output over the period.

### 4(c) Best Adequate ARIMA Model for the Real Rate

A model search over the proxy `rr_t = r_t − Δp_t` yields a differenced specification as the preferred choice rather than a stationary level model:

| Model for the real rate | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(7,1,5) | 474.05 | 523.79 | 0.9679 |

Key estimated coefficients include `φ₄ = 0.4564`, `φ₇ = −0.3841`, `θ₁ = 0.4736`, `θ₂ = −0.2673`, `θ₄ = −0.4045`, `θ₅ = −0.3704`, and `drift = 0.0015`.

This specification has the strongest information-criterion support among the adequate candidates and leaves no meaningful residual autocorrelation. The choice of `d = 1` also makes sense when looking at the plot: the proxy inherits a heavy low-frequency component from the nominal rate, and first differencing removes that slow-moving drift before the ARMA terms address the remaining short-run persistence and reversal. The very high Ljung-Box p-value reinforces that little autocorrelation is left in the residuals.

### 4(d) Best Adequate ARIMA Model for the Consumption Ratio

The model search covers `d ∈ {0,1}` and `p, q = 0,...,6`, evaluated on AIC, BIC, and residual diagnostics. Unlike the interest-rate proxy, the consumption ratio shows no sign of stabilising around a fixed level, which makes `d = 1` the more defensible choice. The selected model is:

| Model for the consumption ratio | AIC | BIC | Ljung-Box p-value |
|---|---:|---:|---:|
| ARIMA(3,1,3) | −2135.65 | −2107.20 | 0.7626 |

Key estimated coefficients: `φ₁ = 0.6092`, `φ₂ = −0.5732`, `φ₃ = 0.7553`, `θ₁ = −0.8316`, `θ₂ = 0.6862`, `θ₃ = −0.8547`, `drift = 0.0003`.

The model combines strong information-criterion support with clean residual diagnostics. The small positive drift picks up the average quarterly increase in the consumption share, while the AR and MA terms capture the remaining short-run persistence in the differenced series.

### 4(e) Policy Use

Real rate forecasts are useful because capital allocation and borrowing decisions respond to real financing costs, not nominal ones. From a monetary policy standpoint, the question is whether real rates are moving in a restrictive or accommodative direction and how quickly. The ARIMA model captures the persistence in the proxy and can provide a guide to how gradually real financing conditions are likely to evolve.

The consumption-ratio model is relevant to both monetary and fiscal authorities. A rising consumption share signals strong household demand and a falling saving rate. Fiscal policy makers need to account for this when modelling how households will respond to changes in taxes or transfers. On the monetary side, a high consumption share may imply greater sensitivity to interest-rate changes in aggregate demand, which would affect how much work a given rate move is likely to do.

---

## Question 5

### 5(a) Sample Variances

Daily returns are constructed as `e_{j,t} = 100 × [log(E_{j,t}) − log(E_{j,t−1})]` for `j ∈ {CNY, USD, TWI, SDR}`, as required in the question.

| Currency | Sample Variance |
|---|---:|
| CNY | 0.3369 |
| USD | 0.4381 |
| TWI | 0.2675 |
| SDR | 0.4492 |

Sample variance here estimates the unconditional variance of each return series and summarises average return variability over the full sample. The ranking runs SDR > USD > CNY > TWI, making SDR the most volatile on average and TWI the least.

Taken at face value, TWI returns were the smoothest over the period while USD and SDR were the most variable. A basket-index structure plausibly explains some of TWI's low variance through diversification, and a managed exchange-rate regime plausibly explains some of CNY's relatively contained variation, though neither of these is established by the variance estimates themselves. The statistics speak to the average volatility ranking only, not to its structural causes, and they say nothing about whether volatility was stable across the sample or concentrated in particular episodes.

### 5(b) Absolute Returns

**Figure 9**

The absolute-return plots for `|e_{j,t}|` show pronounced volatility clustering across all four currencies, particularly around March 2020 and in later parts of the sample. Large absolute returns tend to cluster together, as do quiet periods. All four series spike simultaneously at the onset of COVID-19, which is the most visible common feature across the plots.

This kind of clustering is not what would be expected under an iid constant-variance process. Sustained bursts of high or low activity across many consecutive observations point instead to time-varying conditional volatility, which is precisely the feature that GARCH-type models aim to capture.

---

## Question 6

### Testing for GARCH Effects

Before fitting a variance model, the Engle ARCH LM test with 10 lags was applied to each return series:

| Currency | ARCH LM Statistic | p-value | Ljung-Box on Squared Returns p-value |
|---|---:|---:|---:|
| CNY | 401.62 | p < 1e-15 | p < 1e-15 |
| USD | 275.60 | p < 1e-15 | p < 1e-15 |
| TWI | 484.45 | p < 1e-15 | p < 1e-15 |
| SDR | 426.45 | p < 1e-15 | p < 1e-15 |

Both tests reject constant variance very strongly for every series. The p-values are recorded as `p < 1e-15` because they are numerically indistinguishable from zero rather than literally equal to it. A constant-variance model is clearly not adequate for any of the four currencies, and GARCH-type modelling is well justified.

### Mean Equation Selection

A small ARMA grid was estimated for each return series to pin down sensible low-order mean dynamics before the conditional variance was modelled jointly. For USD, TWI, and SDR, the mean equations from that preliminary step carried through to the final ARMA-GARCH specifications unchanged. CNY was an exception: adding one extra MA term in the joint estimation improved the fit, so the final mean equation for CNY is `ARMA(2,3)` rather than the preliminary `ARMA(2,2)`.

Final mean equations:

- **CNY**: `ARMA(2,3)`
- **USD**: `ARMA(0,0)`
- **TWI**: `ARMA(1,0)`
- **SDR**: `ARMA(0,1)`

### Variance Model and Error Distribution

A broad range of `ARMA(p,q)-GARCH(p_sigma,q_sigma)` models was estimated for each currency, allowing `p_sigma, q_sigma` up to 4 and considering Normal, Student-t, and skewed-Student-t error distributions. To remain consistent with the question's framing, all final specifications use symmetric `GARCH` rather than asymmetric extensions. Model selection balanced three criteria:

- low information criteria, with particular weight on BIC;
- no remaining serial correlation in standardised residuals;
- no material remaining ARCH effects in squared standardised residuals, and persistence strictly below one so the long-run variance in Question 7 is well defined.

The selected models are:

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

Across all four currencies, the ARCH and GARCH coefficients sum to values close to one, reflecting highly persistent conditional volatility. Persistence stays below one in every case, which is what allows the long-run variance calculations in Question 7 to go through.

### Diagnostics and Volatility Plots

Ljung-Box results for the final models:

| Currency | LB on Std. Residuals | LB on Sq. Std. Residuals |
|---|---:|---:|
| CNY | 0.0749 | 0.1857 |
| USD | 0.7008 | 0.0509 |
| TWI | 0.5560 | 0.2421 |
| SDR | 0.9189 | 0.1508 |

All four models pass the Ljung-Box check on standardised residuals, indicating adequate mean equations. The squared-residual tests also pass at the 5% level for all currencies. TWI and SDR clear both comfortably, and the revised CNY specification performs better than earlier iterations. USD remains the most borderline case under the symmetric Normal GARCH constraint. Heavier-tailed symmetric alternatives were considered, but despite better information criteria they left noticeably stronger ARCH effects in the residuals. Asymmetric specifications like `gjrGARCH` improved the USD diagnostics further, but are not reported given the question is framed specifically around `ARMA-GARCH`. Under that constraint, `ARMA(0,0)-GARCH(3,3)` remains the most defensible USD choice.

Accordingly, the four specifications reported above are the final set of best adequate symmetric `ARMA-GARCH` models for Question 6.

**Figures 10-13**

All four conditional volatility series spike sharply around the COVID-19 shock in March 2020 and then decay slowly. TWI is the smoothest and least reactive throughout, while USD and SDR show the largest and most prolonged volatility bursts. This is consistent with the sample-variance evidence from Question 5 and reinforces the view that TWI is the most stable of the four return series.

---

## Question 7

For the symmetric GARCH models from Question 6, the unconditional variance exists when:

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

Persistence is below one in all four cases, so each currency has a finite unconditional variance. The values are still high, especially for USD and SDR, meaning volatility shocks take quite a while to decay even though the long-run variance is well defined.

Comparing the model-implied variances with the sample variances from Question 5 gives a useful cross-check. For CNY and TWI, the GARCH-implied variance comes in below the raw sample figure, which is consistent with stress episodes temporarily inflating observed variability. For USD and SDR the two numbers are nearly identical, suggesting the GARCH dynamics closely replicate average volatility for those currencies. The volatility ranking from Question 5 is unchanged: TWI is still the least volatile series and USD and SDR the most volatile.

---

## Question 8

The probability that the daily return falls below 0.01% on 13/01/2026 and 14/01/2026 is computed from the one-step-ahead and two-step-ahead conditional forecasts of the ARMA-GARCH models selected in Question 6. Returns are defined as `e_{j,t} = 100 × log(S_{j,t} / S_{j,t−1})`, placing them directly in percentage units, so the threshold of 0.01% corresponds to the value 0.01. All four models use Normal errors, so the Normal CDF applies.

| Currency | `μ_{T+1}` | `σ_{T+1}` | P(e < 0.01), 13 Jan | `μ_{T+2}` | `σ_{T+2}` | P(e < 0.01), 14 Jan |
|---|---:|---:|---:|---:|---:|---:|
| CNY | −0.0046 | 0.4547 | 0.5128 | −0.0036 | 0.5036 | 0.5108 |
| USD | −0.0104 | 0.4739 | 0.5172 | −0.0104 | 0.5096 | 0.5160 |
| TWI | −0.0030 | 0.3953 | 0.5131 | −0.0029 | 0.4221 | 0.5122 |
| SDR | −0.0190 | 0.4939 | 0.5234 | −0.0050 | 0.4892 | 0.5122 |

Every probability exceeds 0.5. This follows directly from the structure of the calculation: the threshold is close to zero and the conditional mean is negative for all four currencies on both days. When the forecast mean sits below zero, the majority of the Normal distribution falls below a near-zero threshold by construction.

From a downside-risk perspective, a lower probability is preferable because it indicates a smaller chance of earning below the 0.01% threshold. On **13 January 2026**, the ranking from lowest to highest downside risk is CNY (0.5128), TWI (0.5131), USD (0.5172), SDR (0.5234). On **14 January 2026**, it becomes CNY (0.5108), TWI (0.5122), SDR (0.5122, marginally above TWI at full precision), USD (0.5160).

CNY leads on both dates. Its forecast mean is closer to zero than the others, and its conditional volatility stays moderate relative to USD and SDR. TWI remains attractive given its low volatility, but the full forecast distribution gives CNY the edge. The implication for a risk-averse investor seeking to minimise the probability of falling below 0.01% is clear: **CNY is the preferred currency for both dates**. More broadly, this illustrates why conditional risk measures carry more information than unconditional variance summaries. The preferred asset is determined by the joint behaviour of the forecast mean and forecast variance, not by average sample volatility alone.
