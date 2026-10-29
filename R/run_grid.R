# Runs the power grid for Aim 2 (fixed effect + heterogeneity) and Aim 3 (bridge).
# Usage: Rscript R/run_grid.R [reps] [cores]
args  <- commandArgs(TRUE)
reps  <- if (length(args) >= 1) as.integer(args[1]) else 150
cores <- if (length(args) >= 2) as.integer(args[2]) else parallel::detectCores()
source("R/sim_functions.R")
library(parallel)
RNGkind("L'Ecuyer-CMRG"); set.seed(20261030)

# ---- Aim 2 grid -------------------------------------------------------------
g2 <- expand.grid(n = c(250, 400, 550), comp = c(.60, .67, .78),
                  b = c(.05, .10, .15), sd_b = c(.10, .20))
run2 <- function(i) {
  p <- g2[i, ]
  r <- t(replicate(reps, tryCatch(
    suppressMessages(suppressWarnings(fit_burst(gen_burst(p$n, p$comp, p$b, p$sd_b))$res)),
    error = function(e) rep(NA, 7))))
  data.frame(p, reps_ok = sum(!is.na(r[, "z"])),
             power_fixed = mean(r[, "sig_fixed"], na.rm = TRUE),
             power_slope_var = mean(r[, "sig_slope_var"], na.rm = TRUE),
             bias_fixed = mean(r[, "est"], na.rm = TRUE) - p$b,
             mean_sd_hat = mean(r[, "sd_hat"], na.rm = TRUE),
             obs_per_person = mean(r[, "obs_pp"], na.rm = TRUE))
}
t0 <- Sys.time()
res2 <- do.call(rbind, mclapply(seq_len(nrow(g2)), run2, mc.cores = cores))
write.csv(res2, "results/power_aim2.csv", row.names = FALSE)
cat("Aim 2 done:", format(Sys.time() - t0), "\n")

# ---- Aim 3 grid -------------------------------------------------------------
g3 <- expand.grid(n = c(250, 400, 550), comp = .67, b = .10,
                  sd_b = c(.10, .20), gamma = c(.10, .20, .30))
run3 <- function(i) {
  p <- g3[i, ]
  r <- t(replicate(reps, tryCatch(
    suppressMessages(suppressWarnings(sim_bridge(p$n, p$comp, p$b, p$sd_b, p$gamma))),
    error = function(e) rep(NA, 4))))
  data.frame(p, reps_ok = sum(!is.na(r[, "z"])),
             power_bridge = mean(r[, "sig"], na.rm = TRUE),
             mean_gamma_hat = mean(r[, "gamma_hat"], na.rm = TRUE),
             retained_burst4 = mean(r[, "n_retained_last"], na.rm = TRUE))
}
t0 <- Sys.time()
res3 <- do.call(rbind, mclapply(seq_len(nrow(g3)), run3, mc.cores = cores))
write.csv(res3, "results/power_aim3.csv", row.names = FALSE)
cat("Aim 3 done:", format(Sys.time() - t0), "\n")
writeLines(capture.output(sessionInfo()), "results/sessionInfo.txt")
