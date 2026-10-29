suppressPackageStartupMessages(library(ggplot2))
a2 <- read.csv("results/power_aim2.csv"); a3 <- read.csv("results/power_aim3.csv")
th <- theme_minimal(base_size = 11) + theme(legend.position = "bottom", panel.grid.minor = element_blank())
a2$compliance <- factor(paste0("Compliance ", round(a2$comp * 100), "%"),
                        levels = paste0("Compliance ", c(60, 67, 78), "%"))
a2$hetero <- factor(ifelse(a2$sd_b == .1, "Heterogeneity SD = .10", "Heterogeneity SD = .20"))
p1 <- ggplot(a2, aes(n, power_fixed, colour = factor(b))) +
  geom_hline(yintercept = .8, linetype = 2, colour = "grey40") + geom_line(linewidth = .9) + geom_point() +
  facet_grid(hetero ~ compliance) + scale_y_continuous(limits = c(0, 1)) +
  scale_x_continuous(breaks = c(250, 400, 550)) +
  labs(x = "Persons enrolled", y = "Power", colour = "Average within-person effect",
       title = "Aim 2: average daily carry-over effect") + th
ggsave("figures/fig1_aim2_fixed_effect.png", p1, width = 8, height = 5.2, dpi = 110)
p2 <- ggplot(subset(a2, b == .10), aes(n, power_slope_var, colour = hetero)) +
  geom_hline(yintercept = .8, linetype = 2, colour = "grey40") + geom_line(linewidth = .9) + geom_point() +
  facet_wrap(~compliance) + scale_y_continuous(limits = c(0, 1)) +
  scale_x_continuous(breaks = c(250, 400, 550)) +
  labs(x = "Persons enrolled", y = "Power", colour = NULL,
       title = "Aim 2: detecting that the effect differs between young people (average effect .10)") + th
ggsave("figures/fig2_aim2_heterogeneity.png", p2, width = 8, height = 3.6, dpi = 110)
a3$hetero <- factor(ifelse(a3$sd_b == .1, "Heterogeneity SD = .10", "Heterogeneity SD = .20"))
p3 <- ggplot(a3, aes(n, power_bridge, colour = factor(gamma))) +
  geom_hline(yintercept = .8, linetype = 2, colour = "grey40") + geom_line(linewidth = .9) + geom_point() +
  facet_wrap(~hetero) + scale_y_continuous(limits = c(0, 1)) +
  scale_x_continuous(breaks = c(250, 400, 550)) +
  labs(x = "Persons enrolled (25% lost by burst 4)", y = "Power", colour = "True bridge effect",
       title = "Aim 3: daily slope at one burst predicting wellbeing at the next (compliance 67%)") + th
ggsave("figures/fig3_aim3_bridge.png", p3, width = 8, height = 3.6, dpi = 110)
