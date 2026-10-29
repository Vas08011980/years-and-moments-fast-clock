# Fills the Mplus templates for selected grid cells and runs them (needs Mplus + MplusAutomation).
# Run on a machine with Mplus, e.g. the RMIT cluster:  Rscript R/run_mplus_check.R
library(MplusAutomation)
fill <- function(tpl, out, n, comp, b, sd_b, gamma = .20, drop = .25) {
  wres <- round(.60 * (1 - .30^2) - b^2 * .55, 3)
  txt <- readLines(tpl)
  rep <- list(nobs = n * 56, n = n, miss = round(1 - comp, 2), wres = wres, b = b,
              vs = round(sd_b^2, 4), drop = drop, g_raw = round(gamma / sd_b, 3),
              wnext_res = round(1 - .60^2 - gamma^2, 3))
  for (k in names(rep)) txt <- gsub(paste0("\\[\\[", k, "\\]\\]"), rep[[k]], txt)
  writeLines(txt, out)
}
dir.create("mplus/runs", showWarnings = FALSE)
cells <- expand.grid(n = c(250, 400), comp = c(.60, .67), b = .10, sd_b = c(.10, .20))
for (i in seq_len(nrow(cells))) with(cells[i, ], {
  f2 <- sprintf("mplus/runs/aim2_n%d_c%02d_sd%02d.inp", n, comp * 100, sd_b * 100)
  f3 <- sub("aim2", "aim3", f2)
  fill("mplus/templates/aim2_dsem_montecarlo.inp", f2, n, comp, b, sd_b)
  fill("mplus/templates/aim3_bridge_dsem_montecarlo.inp", f3, n, comp, b, sd_b)
})
runModels("mplus/runs")
# Power = proportion of replications with the 95% credible interval excluding 0
# ("% Sig Coeff" column in the Monte Carlo output).
