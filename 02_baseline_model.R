# 02_baseline_model.R — the smallest model that could possibly work
# Purpose: get one honest number on held-out training data, so every later
# change (encoding, imputation, transforms) has to beat it. Nothing here
# uses test.csv.

library(tidyverse)

dtrain <- read_csv("train.csv", show_col_types = FALSE)

# 1. Target on the log scale: the competition metric is RMSE on log1p(price).
dtrain <- dtrain |> mutate(log_price = log1p(SalePrice))

# 2. Holdout split — 80% to fit, 20% to score. Fixed seed so it is repeatable.
set.seed(4053)
n_train <- round(0.8 * nrow(dtrain))
idx <- sample.int(nrow(dtrain), size = n_train)
tr <- dtrain[idx, ]
va <- dtrain[-idx, ]

cat("fit rows:", nrow(tr), " holdout rows:", nrow(va), "\n")

# 3. Five predictors that are complete in train and that you understand:
#    size, overall quality, age, basement size, garage capacity.
form <- log_price ~ GrLivArea + OverallQual + YearBuilt + TotalBsmtSF + GarageCars

fit <- lm(form, data = tr)
print(summary(fit))

# 4. Score on rows the model has never seen.
pred <- predict(fit, newdata = va)
rmsle_holdout <- sqrt(mean((pred - va$log_price)^2))
cat("holdout RMSLE:", round(rmsle_holdout, 5), "\n")

# 5. Scale check: what an intercept-only model scores (no information at all).
null_fit <- lm(log_price ~ 1, data = tr)
rmsle_null <- sqrt(mean((predict(null_fit, va) - va$log_price)^2))
cat("intercept-only RMSLE:", round(rmsle_null, 5), "\n")
cat("improvement:", round(rmsle_null - rmsle_holdout, 5), "\n")

# 6. The one plot that matters at this stage: residuals against prediction.
#    A pattern here means the linear form is wrong, not that the score is bad.
#    print() is explicit because source() does not auto-print objects.
print(
  tibble(pred = pred, resid = va$log_price - pred) |>
    ggplot(aes(x = pred, y = resid)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_smooth(method = "loess", se = FALSE, colour = "firebrick") +
    labs(x = "predicted log price", y = "residual (actual - predicted)",
         title = "Baseline residuals on the 20% holdout")
)
