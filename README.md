# Years and moments — Fast clock: What happens day to day? Young adults online, moment by moment

**Monte Carlo power simulation for the measurement-burst study (preliminary, v0.1.0)**
Vasileios Stavropoulos, RMIT University · ORCID [0000-0001-6964-4662](https://orcid.org/0000-0001-6964-4662)

This repository checks whether the planned fast-clock study (≈400 young adults aged 18–25 enrolled, ≈300 retained; four 14-day bursts six months apart; four prompts a day) is large enough to answer three questions:

1. **Average daily effect:** does digital exposure (e.g., late-night AI use) carry over into later mood?
2. **For whom:** does that effect differ between young people?
3. **Do days add up:** does a young person's daily effect at one burst predict their wellbeing six months later?

**Interactive explorer:** [vas08011980.github.io/years-and-moments-fast-clock](https://vas08011980.github.io/years-and-moments-fast-clock/) (also `index.html` in this repository).

Effect sizes and compliance come from the literature (Beyens et al., 2020; Wen et al., 2017); see [`assumptions.csv`](assumptions.csv).

## Main results (400 enrolled)

| Question | Result |
|---|---|
| Average daily effect | Power ≥ .83 for an effect of .05 and 1.00 for ≥ .10, at 60–78% compliance |
| For whom (between-person differences) | Power 1.00 for Beyens-level heterogeneity (SD .20); .73–.97 for modest heterogeneity (SD .10), depending on compliance |
| Do days add up (bridge, 67% compliance) | Power ≥ .83 for bridge effects ≥ .20; .33–.73 for .10 |

**Decision:** N ≈ 400 is adequate for the two daily questions (average effect and for whom). The bridge test is confirmatory for effects ≥ .20; smaller effects are reported as estimates with intervals. Pilot estimates (months 7–12) replace the design assumptions before the final N is fixed. Full write-up: [`report.md`](report.md).

## Contents

| Path | Content |
|---|---|
| `report.md` | Report: question, assumptions, method, results, decision, limitations |
| `assumptions.csv` | Every simulated parameter with its source |
| `R/sim_functions.R` | Data generation and analysis (lme4 approximation of DSEM) |
| `R/run_grid.R` | Runs the full grid (`Rscript R/run_grid.R 150 <cores>`) |
| `R/make_figures.R` | Figures 1–3 |
| `R/run_mplus_check.R` | Fills and runs the Mplus DSEM Monte Carlo templates for confirmation |
| `mplus/templates/` | Latent-centred DSEM Monte Carlo inputs (daily effect and bridge) |
| `results/` | Power tables (`power_aim2.csv`, `power_aim3.csv`), run log, R session info |
| `figures/` | Power curves |
| `index.html` | Interactive explorer of the power results (served on GitHub Pages) |

## Reproduce

```bash
Rscript R/run_grid.R 150 2   # ~70 min on 2 cores
Rscript R/make_figures.R
```

Requires R ≥ 4.3 with `lme4` and `ggplot2`. The Mplus check needs Mplus 8+ and `MplusAutomation`.

## Limitations

Power is estimated for simulated data with normally distributed residuals, exposure measured without error, and prompts missed at random (each person's compliance drawn from a beta distribution), analysed with a model that matches the generating structure. Measurement error in exposure, non-random missingness or misspecification in real data would reduce power. The bridge effect has no direct empirical anchor and is simulated as a range (.10–.30). The lme4 models use observed rather than latent person-mean centring; the Mplus DSEM templates provide the latent-centred check. In the bridge analysis, each person's daily effect is estimated per burst (empirical Bayes) before entering the regression, so the estimated bridge coefficient is smaller than the generating value (about .07 for a generating value of .20 at N = 400, SD .10); bridge power refers to detecting the effect, not to recovering its size.

## References

- Beyens, I., Pouwels, J. L., van Driel, I. I., Keijsers, L., & Valkenburg, P. M. (2020). The effect of social media on well-being differs from adolescent to adolescent. *Scientific Reports, 10*, 10763. https://doi.org/10.1038/s41598-020-67727-7
- Schultzberg, M., & Muthén, B. (2018). Number of subjects and time points needed for multilevel time-series analysis. *Structural Equation Modeling, 25*(4), 495–515. https://doi.org/10.1080/10705511.2017.1392862
- Wen, C. K. F., Schneider, S., Stone, A. A., & Spruijt-Metz, D. (2017). Compliance with mobile ecological momentary assessment protocols in children and adolescents. *JMIR, 19*(4), e132. https://doi.org/10.2196/jmir.6641

Code and code write-up were prepared with assistance from Claude (Anthropic); the study design, assumptions and interpretation are the author's.

MIT licence. Cite via `CITATION.cff`.
