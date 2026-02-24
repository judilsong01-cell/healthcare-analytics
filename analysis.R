# ============================================================
# Healthcare Analytics: Post-Operative Recovery Platform
# Author: Antonio Augusto
# Description: Data analysis & visualization in R using ggplot2
# Run: Rscript analysis.R  (requires packages below)
# ============================================================

# ─────────────────────────────────────────
# 0. SETUP
# ─────────────────────────────────────────
required_packages <- c("DBI", "RSQLite", "dplyr", "tidyr",
                       "ggplot2", "scales", "patchwork",
                       "lubridate", "viridis", "ggridges", "knitr")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}

# ─────────────────────────────────────────
# 1. LOAD DATA FROM SQLite
# ─────────────────────────────────────────
con <- dbConnect(RSQLite::SQLite(), dbname = "healthcare.db")

# Run schema + seed if DB is empty
if (!("patients" %in% dbListTables(con))) {
  sql_files <- c("sql/01_schema_and_data.sql")
  for (f in sql_files) {
    stmts <- strsplit(paste(readLines(f), collapse = "\n"), ";")[[1]]
    for (s in stmts) {
      s <- trimws(s)
      if (nchar(s) > 5) tryCatch(dbExecute(con, s), error = function(e) NULL)
    }
  }
}

patients     <- dbReadTable(con, "patients")
checkins     <- dbReadTable(con, "daily_checkins")
medications  <- dbReadTable(con, "medications")
alerts       <- dbReadTable(con, "alerts")
clinics      <- dbReadTable(con, "clinics")
dbDisconnect(con)

# ─────────────────────────────────────────
# 2. DATA WRANGLING
# ─────────────────────────────────────────
checkins_full <- checkins %>%
  left_join(patients, by = "patient_id") %>%
  left_join(clinics,  by = "clinic_id")  %>%
  mutate(
    checkin_date = as.Date(checkin_date),
    age_group = cut(age,
      breaks = c(0, 34, 49, 64, 100),
      labels = c("18–34", "35–49", "50–64", "65+"),
      right = TRUE
    )
  )

# ─────────────────────────────────────────
# 3. CUSTOM THEME (clinical minimal style)
# ─────────────────────────────────────────
theme_clinical <- function() {
  theme_minimal(base_family = "sans") +
  theme(
    plot.title    = element_text(size = 14, face = "bold",   colour = "#003366"),
    plot.subtitle = element_text(size = 10, colour = "#555555"),
    axis.title    = element_text(size = 10, colour = "#333333"),
    axis.text     = element_text(size = 9,  colour = "#444444"),
    panel.grid.minor  = element_blank(),
    panel.grid.major  = element_line(colour = "#EEEEEE"),
    strip.text        = element_text(face = "bold", colour = "#003366"),
    legend.title      = element_text(size = 9,  face = "bold"),
    legend.text       = element_text(size = 8),
    plot.background   = element_rect(fill = "white", colour = NA),
    panel.background  = element_rect(fill = "white", colour = NA)
  )
}

palette_surgery <- c(
  "Knee Replacement"  = "#0066CC",
  "Hip Replacement"   = "#10B981",
  "Appendectomy"      = "#F59E0B",
  "Cardiac Bypass"    = "#EF4444"
)

# ─────────────────────────────────────────
# PLOT 1: Recovery Trajectory by Surgery Type
# ─────────────────────────────────────────
df_traj <- checkins_full %>%
  group_by(surgery_type, day_post_op) %>%
  summarise(
    avg_score = mean(recovery_score),
    se = sd(recovery_score) / sqrt(n()),
    .groups = "drop"
  )

p1 <- ggplot(df_traj, aes(x = day_post_op, y = avg_score,
                           colour = surgery_type, fill = surgery_type)) +
  geom_ribbon(aes(ymin = avg_score - se, ymax = avg_score + se), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_colour_manual(values = palette_surgery, name = "Surgery Type") +
  scale_fill_manual(values = palette_surgery,   name = "Surgery Type") +
  scale_x_continuous(breaks = c(1, 4, 7, 8, 14)) +
  scale_y_continuous(limits = c(0, 100), labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Recovery Trajectory by Surgery Type",
    subtitle = "Average recovery score (± SE) across post-operative days",
    x = "Day Post-Operation", y = "Recovery Score"
  ) +
  theme_clinical()

# ─────────────────────────────────────────
# PLOT 2: Pain Level Distribution — Ridge Plot
# ─────────────────────────────────────────
p2 <- ggplot(checkins_full,
             aes(x = pain_level, y = surgery_type, fill = surgery_type)) +
  ggridges::geom_density_ridges(alpha = 0.7, scale = 0.9,
                                colour = "white", linewidth = 0.4) +
  scale_fill_manual(values = palette_surgery, guide = "none") +
  scale_x_continuous(breaks = 0:10) +
  labs(
    title    = "Pain Level Distribution by Surgery Type",
    subtitle = "Density of reported pain levels (0 = none, 10 = severe)",
    x = "Pain Level (0–10)", y = NULL
  ) +
  theme_clinical()

# ─────────────────────────────────────────
# PLOT 3: Temperature Evolution Over Days
# ─────────────────────────────────────────
df_temp <- checkins_full %>%
  group_by(day_post_op) %>%
  summarise(
    avg_temp = mean(temperature),
    fever_pct = mean(temperature >= 37.8) * 100,
    .groups = "drop"
  )

p3 <- ggplot(df_temp, aes(x = day_post_op)) +
  geom_hline(yintercept = 37.8, linetype = "dashed",
             colour = "#EF4444", linewidth = 0.8, alpha = 0.6) +
  geom_area(aes(y = avg_temp), fill = "#0066CC", alpha = 0.12) +
  geom_line(aes(y = avg_temp), colour = "#0066CC", linewidth = 1.2) +
  geom_point(aes(y = avg_temp, colour = avg_temp >= 37.8), size = 3) +
  scale_colour_manual(values = c("FALSE" = "#10B981", "TRUE" = "#EF4444"),
                      labels = c("Normal", "Above 37.8°C"),
                      name = "Status") +
  annotate("text", x = 14.2, y = 37.82, label = "Fever threshold (37.8°C)",
           hjust = 0, size = 3, colour = "#EF4444") +
  scale_x_continuous(breaks = c(1, 4, 7, 8, 14)) +
  scale_y_continuous(limits = c(36, 39.5)) +
  labs(
    title    = "Average Body Temperature Over Recovery",
    subtitle = "All patients combined — fever threshold at 37.8°C",
    x = "Day Post-Operation", y = "Temperature (°C)"
  ) +
  theme_clinical()

# ─────────────────────────────────────────
# PLOT 4: Alert Severity by Clinic (Heatmap)
# ─────────────────────────────────────────
df_alerts <- alerts %>%
  left_join(patients, by = "patient_id") %>%
  left_join(clinics,  by = "clinic_id")  %>%
  count(clinic_name, severity) %>%
  mutate(severity = factor(severity,
    levels = c("Low","Medium","High","Critical")))

p4 <- ggplot(df_alerts, aes(x = clinic_name, y = severity, fill = n)) +
  geom_tile(colour = "white", linewidth = 1.5, borderline = 0) +
  geom_text(aes(label = n), size = 5, fontface = "bold",
            colour = ifelse(df_alerts$n > 1.5, "white", "#333333")) +
  scale_fill_gradient(low = "#E8F4FD", high = "#003366",
                      name = "Alert\nCount") +
  labs(
    title    = "Alert Severity Heatmap by Clinic",
    subtitle = "Number of alerts by severity level across clinics",
    x = NULL, y = "Severity Level"
  ) +
  theme_clinical() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

# ─────────────────────────────────────────
# PLOT 5: Medication Adherence vs Recovery Score
# ─────────────────────────────────────────
df_med_rec <- medications %>%
  group_by(patient_id) %>%
  summarise(adherence = mean(taken) * 100, .groups = "drop") %>%
  left_join(
    checkins %>%
      filter(day_post_op == 14) %>%
      select(patient_id, recovery_score),
    by = "patient_id"
  ) %>%
  left_join(patients %>% select(patient_id, surgery_type), by = "patient_id") %>%
  drop_na()

p5 <- ggplot(df_med_rec,
             aes(x = adherence, y = recovery_score,
                 colour = surgery_type, size = recovery_score)) +
  geom_point(alpha = 0.85) +
  geom_smooth(method = "lm", formula = y ~ x,
              se = TRUE, colour = "#003366", fill = "#003366",
              alpha = 0.1, linewidth = 0.8, linetype = "dashed") +
  scale_colour_manual(values = palette_surgery, name = "Surgery") +
  scale_size_continuous(range = c(3, 8), guide = "none") +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Medication Adherence vs. Day-14 Recovery Score",
    subtitle = "Higher adherence correlates with better recovery outcomes",
    x = "Medication Adherence (%)", y = "Recovery Score at Day 14 (%)"
  ) +
  theme_clinical()

# ─────────────────────────────────────────
# PLOT 6: Clinic Performance KPI Dashboard
# ─────────────────────────────────────────
df_clinic_kpi <- checkins_full %>%
  group_by(clinic_name) %>%
  summarise(
    avg_recovery = mean(recovery_score),
    avg_pain     = mean(pain_level),
    avg_temp     = mean(temperature),
    .groups = "drop"
  ) %>%
  tidyr::pivot_longer(cols = c(avg_recovery, avg_pain, avg_temp),
                      names_to = "metric", values_to = "value") %>%
  mutate(
    metric_label = recode(metric,
      avg_recovery = "Recovery Score (%)",
      avg_pain     = "Pain Level (0–10)",
      avg_temp     = "Temperature (°C)"
    )
  )

p6 <- ggplot(df_clinic_kpi,
             aes(x = clinic_name, y = value, fill = clinic_name)) +
  geom_col(alpha = 0.85, width = 0.6) +
  facet_wrap(~ metric_label, scales = "free_y", ncol = 3) +
  scale_fill_manual(values = c("#0066CC","#10B981","#F59E0B"), guide = "none") +
  geom_text(aes(label = round(value, 1)),
            vjust = -0.4, size = 3.5, fontface = "bold", colour = "#333333") +
  labs(
    title    = "Clinic Performance Scorecard",
    subtitle = "Average KPIs across clinics",
    x = NULL, y = NULL
  ) +
  theme_clinical() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

# ─────────────────────────────────────────
# SAVE ALL PLOTS
# ─────────────────────────────────────────
dir.create("output_plots", showWarnings = FALSE)

plots <- list(
  "01_recovery_trajectory"  = p1,
  "02_pain_distribution"    = p2,
  "03_temperature_trend"    = p3,
  "04_alert_heatmap"        = p4,
  "05_adherence_vs_recovery"= p5,
  "06_clinic_scorecard"     = p6
)

for (nm in names(plots)) {
  ggsave(
    filename = file.path("output_plots", paste0(nm, ".png")),
    plot     = plots[[nm]],
    width    = 10, height = 6, dpi = 180, bg = "white"
  )
  cat(sprintf("✅ Saved: %s.png\n", nm))
}

# ─────────────────────────────────────────
# STATISTICAL SUMMARY (console output)
# ─────────────────────────────────────────
cat("\n══════════════════════════════════════════\n")
cat("  HEALTHCARE ANALYTICS — STATISTICAL SUMMARY\n")
cat("══════════════════════════════════════════\n\n")

cat("📊 Recovery Score by Surgery Type (Day 14):\n")
checkins_full %>%
  filter(day_post_op == 14) %>%
  group_by(surgery_type) %>%
  summarise(
    n       = n(),
    mean    = round(mean(recovery_score), 1),
    sd      = round(sd(recovery_score), 1),
    min     = min(recovery_score),
    max     = max(recovery_score)
  ) %>%
  print()

cat("\n📈 Correlation (Medication Adherence → Recovery):\n")
if (nrow(df_med_rec) >= 3) {
  ct <- cor.test(df_med_rec$adherence, df_med_rec$recovery_score)
  cat(sprintf("  r = %.3f  |  p = %.4f\n", ct$estimate, ct$p.value))
  cat(sprintf("  Interpretation: %s positive relationship\n",
    ifelse(ct$estimate > 0.7, "Strong", ifelse(ct$estimate > 0.4, "Moderate", "Weak"))))
}

cat("\n⚠️  Unresolved Critical Alerts:\n")
alerts %>%
  filter(resolved == 0, severity %in% c("Critical","High")) %>%
  left_join(patients, by = "patient_id") %>%
  select(patient_id, surgery_type, alert_type, severity, alert_date) %>%
  print()

cat("\nAnalysis complete. Check output_plots/ for visualizations.\n")
