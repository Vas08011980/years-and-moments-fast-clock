# Fast-clock power simulation: data generation and analysis functions
# Approximates the DSEM analysis with lme4 (observed person-mean centring).
# The full latent-centred DSEM check is in mplus/templates (run on a cluster).
suppressPackageStartupMessages(library(lme4))

# ---- Aim 2 (burst 1): moments within persons --------------------------------
# n        persons enrolled
# comp     mean prompt compliance (person compliance ~ Beta, mean = comp)
# b        average within-person lagged effect of x (digital exposure) on y (mood), standardised
# sd_b     between-person SD of that effect (heterogeneity)
# days, ppd  14 days x 4 prompts per day = 56 prompts
# phi      autoregression of y; icc of y; lags only within the same day
gen_burst <- function(n, comp, b, sd_b, days = 14, ppd = 4, phi = .30,
                      icc = .40, x_ar = .30, x_icc = .40, b_i = NULL) {
  T <- days * ppd
  if (is.null(b_i)) b_i <- rnorm(n, b, sd_b)
  mu   <- rnorm(n, 0, sqrt(icc))
  xm   <- rnorm(n, 0, sqrt(x_icc))
  # person compliance: Beta with mean comp and SD ~ .15
  k    <- comp * (1 - comp) / .15^2 - 1
  pc   <- rbeta(n, comp * k, (1 - comp) * k)
  wvar <- 1 - icc
  out <- vector("list", n)
  for (i in seq_len(n)) {
    xw <- numeric(T); y <- numeric(T)
    xw[1] <- rnorm(1, 0, sqrt(1 - x_icc))
    for (t in 2:T) xw[t] <- x_ar * xw[t - 1] + rnorm(1, 0, sqrt((1 - x_icc) * (1 - x_ar^2)))
    # residual variance chosen so within-person var(y) ~ wvar
    evar <- max(wvar * (1 - phi^2) - b_i[i]^2 * (1 - x_icc), .05)
    yw <- numeric(T); yw[1] <- rnorm(1, 0, sqrt(wvar))
    for (t in 2:T) yw[t] <- phi * yw[t - 1] + b_i[i] * xw[t - 1] + rnorm(1, 0, sqrt(evar))
    day <- rep(seq_len(days), each = ppd)
    obs <- rbinom(T, 1, pc[i]) == 1
    out[[i]] <- data.frame(id = i, t = seq_len(T), day = day,
                           x = xm[i] + xw, y = mu[i] + yw, obs = obs)
  }
  d <- do.call(rbind, out)
  d$x[!d$obs] <- NA; d$y[!d$obs] <- NA
  # within-day lags (the previous prompt, same day)
  d <- d[order(d$id, d$t), ]
  same <- c(FALSE, d$id[-1] == d$id[-nrow(d)] & d$day[-1] == d$day[-nrow(d)])
  d$y_lag <- ifelse(same, c(NA, d$y[-nrow(d)]), NA)
  d$x_lag <- ifelse(same, c(NA, d$x[-nrow(d)]), NA)
  d <- d[!is.na(d$y) & !is.na(d$y_lag) & !is.na(d$x_lag), ]
  # person-mean centring (within / between split)
  d$x_pm  <- ave(d$x_lag, d$id); d$x_wc <- d$x_lag - d$x_pm
  d$yl_wc <- d$y_lag - ave(d$y_lag, d$id)
  d
}

fit_burst <- function(d, test_slope_var = TRUE) {
  ctl <- lmerControl(calc.derivs = FALSE)
  m1 <- lmer(y ~ yl_wc + x_wc + x_pm + (1 + x_wc | id), data = d, REML = FALSE, control = ctl)
  z  <- summary(m1)$coefficients["x_wc", "t value"]
  res <- c(est = unname(fixef(m1)["x_wc"]), z = z, sig_fixed = abs(z) > 1.96,
           sd_hat = attr(VarCorr(m1)$id, "stddev")[["x_wc"]],
           n_obs = nrow(d), obs_pp = nrow(d) / length(unique(d$id)))
  if (test_slope_var) {
    m0 <- lmer(y ~ yl_wc + x_wc + x_pm + (1 | id), data = d, REML = FALSE, control = ctl)
    lr <- max(as.numeric(2 * (logLik(m1) - logLik(m0))), 0)
    p  <- .5 * pchisq(lr, 1, lower.tail = FALSE) + .5 * pchisq(lr, 2, lower.tail = FALSE)
    res <- c(res, sig_slope_var = p < .05)
  }
  list(res = res, model = m1)
}

# ---- Aim 3 (bridge): do daily processes predict next-burst wellbeing? -------
# 4 bursts, retention 100/92/84/75%; person slopes stable across bursts (r = .70)
# W_{k+1} = .60 W_k + gamma * z(b_ik) + e   (standardised full-scale wellbeing)
sim_bridge <- function(n, comp, b, sd_b, gamma, retain = c(1, .92, .84, .75),
                       r_slope = .70, w_ar = .60) {
  K <- length(retain)
  trait <- rnorm(n)
  bz <- sapply(1:K, function(k) r_slope^.5 * trait + sqrt(1 - r_slope) * rnorm(n))  # z-scaled slopes
  W <- matrix(NA, n, K); W[, 1] <- rnorm(n)
  for (k in 2:K) W[, k] <- w_ar * W[, k - 1] + gamma * bz[, k - 1] +
    rnorm(n, 0, sqrt(max(1 - w_ar^2 - gamma^2 - 2 * w_ar * gamma * 0, .05)))
  # monotone dropout
  last <- sapply(runif(n), function(u) max(which(u <= retain)))
  est <- matrix(NA, n, K)
  for (k in 1:K) {
    keep <- which(last >= k)
    d <- gen_burst(length(keep), comp, b, sd_b, b_i = b + sd_b * bz[keep, k])
    d$id <- keep[d$id]
    m <- lme4::lmer(y ~ yl_wc + x_wc + x_pm + (1 + x_wc | id), data = d, REML = FALSE,
                    control = lmerControl(calc.derivs = FALSE))
    re <- ranef(m)$id
    est[as.integer(rownames(re)), k] <- fixef(m)["x_wc"] + re[, "x_wc"]  # empirical Bayes person slope
  }
  long <- do.call(rbind, lapply(1:(K - 1), function(k) {
    ok <- which(last >= k + 1)
    data.frame(id = ok, W_next = W[ok, k + 1], W_now = W[ok, k], slope = est[ok, k])
  }))
  long <- long[!is.na(long$slope), ]
  long$slope_z <- (long$slope - mean(long$slope)) / sd(long$slope)
  mm <- lme4::lmer(W_next ~ W_now + slope_z + (1 | id), data = long, REML = FALSE,
                   control = lmerControl(calc.derivs = FALSE))
  z <- summary(mm)$coefficients["slope_z", "t value"]
  c(gamma_hat = unname(fixef(mm)["slope_z"]), z = z, sig = abs(z) > 1.96,
    n_retained_last = sum(last == K))
}
