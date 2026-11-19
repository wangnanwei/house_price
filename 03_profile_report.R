# 03_profile_report.R — evidence for the codebook, all 79 columns at once
# Produces profiling_metrics.csv: one row per column with the numbers that
# justify its Decision in codebook.md. Reads train.csv only.

library(tidyverse)

dtrain <- read_csv("train.csv", show_col_types = FALSE)
feats  <- dtrain |> select(-any_of(c("Id", "SalePrice")))
y      <- log1p(dtrain$SalePrice)

# Ordered label sets taken from data_description.txt. If a column's values sit
# inside one of these sets, the column is ordinal and a rank correlation tells
# us whether the dictionary order actually tracks price.
ord_sets <- list(
  qual      = c("Ex", "Gd", "TA", "Fa", "Po"),
  functional = c("Typ", "Min1", "Min2", "Mod", "Maj1", "Maj2", "Sev"),
  exposure  = c("Gd", "Av", "Mn", "No"),
  finish    = c("Fin", "RFn", "Unf"),
  fence     = c("GdPr", "MnPrv", "GdWo", "MnWw"),
  prox      = c("AbBr3", "AbBr4"),
  slope     = c("Sev", "Mod", "Gtl")
)

row_num <- function(nm, x) {
  xs <- x[!is.na(x)]
  q  <- quantile(xs, c(.25, .5, .75), names = FALSE)
  iqr <- q[3] - q[1]
  r2_lin  <- summary(lm(y ~ x))$r.squared
  r2_quad <- summary(lm(y ~ x + I(x^2)))$r.squared
  tibble(
    column     = nm,
    kind       = if (n_distinct(xs) <= 15) "numeric (few values)" else "numeric",
    n_na       = sum(is.na(x)),
    n_distinct = n_distinct(xs),
    skew       = round(e1071_skew(xs), 2),
    cor        = round(cor(xs, y[!is.na(x)], method = "pearson"), 3),
    zeros_pct  = round(100 * mean(xs == 0), 1),
    quad_gain  = round(r2_quad - r2_lin, 3),
    out_hi     = sum(xs > q[3] + 3 * iqr),
    n_levels   = NA_integer_, min_level_n = NA_integer_, ord_rho = NA_real_,
    spread     = NA_real_
  )
}

e1071_skew <- function(v) {
  m <- mean(v); s <- sd(v)
  if (s == 0) return(0)
  mean(((v - m) / s)^3)
}

row_cat <- function(nm, x) {
  xs <- x[!is.na(x)]
  tb <- table(xs)
  lv <- names(tb); cnt <- as.integer(tb)
  med <- map_dbl(lv, ~ median(y[!is.na(x) & x == .x]))
  ord_rho <- NA_real_
  for (s in ord_sets) {
    if (all(lv %in% s)) {
      ord_rho <- round(cor(match(lv, s), med, method = "spearman"), 3)
      break
    }
  }
  tibble(
    column     = nm, kind = "categorical",
    n_na       = sum(is.na(x)), n_distinct = length(lv),
    skew = NA_real_, cor = NA_real_, zeros_pct = NA_real_, quad_gain = NA_real_,
    out_hi = NA_integer_,
    n_levels   = length(lv),
    min_level_n = min(cnt),
    ord_rho    = ord_rho,
    spread     = round(diff(range(med)), 2)
  )
}

metrics <- map2_dfr(names(feats), feats, ~ if (is.numeric(.y)) row_num(.x, .y) else row_cat(.x, .y))

# Problem tags — each one is a decision trigger, not a judgement.
tag <- function(r) {
  t <- character(0)
  if (!is.na(r$n_na) && r$n_na > 0) t <- c(t, "missing")
  if (!is.na(r$quad_gain) && r$quad_gain >= 0.02) t <- c(t, "nonlinear")
  if (!is.na(r$skew) && abs(r$skew) >= 1) t <- c(t, "skewed")
  if (!is.na(r$cor) && abs(r$cor) < 0.05 && (is.na(r$quad_gain) || r$quad_gain < 0.01))
    t <- c(t, "weak signal")
  if (!is.na(r$out_hi) && r$out_hi > 0) t <- c(t, "outliers")
  if (r$kind == "numeric (few values)") t <- c(t, "few numeric values")
  if (!is.na(r$n_levels) && r$n_levels >= 10) t <- c(t, "many levels")
  if (!is.na(r$min_level_n) && r$min_level_n < 10) t <- c(t, "rare levels")
  if (!is.na(r$ord_rho)) t <- c(t, "ordinal")
  paste(t, collapse = "; ")
}

metrics <- metrics |> mutate(problems = map_chr(seq_len(nrow(metrics)), ~ tag(metrics[.x, ])))
write_csv(metrics, "profiling_metrics.csv")

cat("columns:", nrow(metrics), "\n\n")
cat("--- tag counts ---\n")
metrics |> separate_longer_delim(problems, ";") |>
  mutate(problems = str_squish(problems)) |> filter(problems != "") |>
  count(problems, sort = TRUE) |> print()

cat("\n--- weak signal ---\n")
metrics |> filter(str_detect(problems, "weak signal")) |>
  select(column, kind, cor, quad_gain) |> print(n = 30)

cat("\n--- strong nonlinearity (quad gain >= 0.02) ---\n")
metrics |> filter(!is.na(quad_gain), quad_gain >= 0.02) |>
  select(column, cor, quad_gain) |> arrange(desc(quad_gain)) |> print(n = 30)

cat("\n--- ordinal columns: does dictionary order track price? ---\n")
metrics |> filter(!is.na(ord_rho)) |>
  select(column, n_levels, ord_rho) |> arrange(ord_rho) |> print(n = 30)

cat("\n--- categoricals with rare levels or many levels ---\n")
metrics |> filter(!is.na(n_levels)) |>
  filter(n_levels >= 10 | min_level_n < 10) |>
  select(column, n_levels, min_level_n, spread) |>
  arrange(desc(n_levels), min_level_n) |> print(n = 30)
