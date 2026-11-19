# 01_load_and_check.R
# ---------------------------------------------------------------------------
# Job: load the data and verify it is what we think it is. Changes nothing,
# writes nothing. Every check answers a question that would otherwise bite
# us later, silently.
# ---------------------------------------------------------------------------

library(tidyverse)

train <- read_csv("train.csv", show_col_types = FALSE)
test  <- read_csv("test.csv",  show_col_types = FALSE)

# 1. Shape ---------------------------------------------------------------
# Why: every later assumption (CV fold sizes, prediction row count) is built
# on these two numbers. Cheap to check, expensive to discover late.
cat("== shape ==\n")
cat("train:", nrow(train), "rows x", ncol(train), "cols\n")
cat("test :", nrow(test),  "rows x", ncol(test),  "cols\n\n")

# 2. The same features on both sides ------------------------------------
# Why: predict() silently produces wrong-length or wrong-order output if
# the test frame lacks a column the model was fitted on.
feat_train <- setdiff(names(train), c("Id", "SalePrice"))
feat_test  <- setdiff(names(test),  "Id")
cat("== features ==\n")
cat("count:", length(feat_train), "in train,", length(feat_test), "in test\n")
cat("identical sets:", identical(sort(feat_train), sort(feat_test)), "\n\n")

# 3. Types agree, column by column --------------------------------------
# Why: readr guesses types per file. A column that looks categorical in
# train can be guessed numeric in test (or vice versa), and rbind / predict
# then fail or coerce silently.
cls_train <- map_chr(train[feat_train], ~ class(.x)[1])
cls_test  <- map_chr(test[feat_test],  ~ class(.x)[1])
mismatch  <- names(cls_train)[cls_train != cls_test]
cat("== types ==\n")
cat("numeric:", sum(cls_train == "numeric"), " character:", sum(cls_train == "character"), "\n")
cat("mismatches:", if (length(mismatch)) paste(mismatch, collapse = ", ") else "none", "\n\n")

# 4. Keys ---------------------------------------------------------------
# Why: a duplicated Id means two rows describe one house, which breaks any
# row-level split and any submission that expects one row per Id.
cat("== keys ==\n")
cat("duplicated Ids:", sum(duplicated(train$Id)) + sum(duplicated(test$Id)), "\n")
cat("Id ranges:", min(train$Id), "-", max(train$Id), "and",
    min(test$Id), "-", max(test$Id), "\n")
cat("exact duplicate rows:", sum(duplicated(train)), "\n\n")

# 5. Where values are missing ------------------------------------------
# Why: not all NA is equal. Here NA is mostly a *category* ("no pool"), and
# only a few columns have real gaps. Counts now, meaning later.
na_tab <- train |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "column", values_to = "n_na") |>
  filter(n_na > 0) |>
  mutate(pct = round(100 * n_na / nrow(train), 1)) |>
  arrange(desc(n_na))

cat("== missing ==\n")
cat("train columns with any NA:", nrow(na_tab), "of", ncol(train), "\n")
print(na_tab, n = 40)
cat("total NA cells:", sum(na_tab$n_na), "\n\n")

# 6. The target ---------------------------------------------------------
# Why: the metric is RMSE on log(price), and least squares assumes residuals
# are roughly symmetric with stable variance. Raw price violates both;
# log price does not. Check with numbers, not belief.
skewness <- function(v) {
  s <- sd(v)
  mean(((v - mean(v)) / s)^3)
}

cat("== target ==\n")
print(summary(train$SalePrice))
cat("all prices positive:", all(train$SalePrice > 0), "\n")
cat("skewness raw:", round(skewness(train$SalePrice), 3),
    "| log1p:", round(skewness(log1p(train$SalePrice)), 3), "\n")
cat("sd of log price:", round(sd(log1p(train$SalePrice)), 4),
    "(an intercept-only model scores about this much RMSLE)\n\n")

# 7. See the target ----------------------------------------------------
print(
  train |>
    mutate(log_price = log1p(SalePrice)) |>
    ggplot(aes(x = log_price)) +
    geom_histogram(binwidth = 0.1, fill = "skyblue", colour = "black") +
    labs(x = "log(1 + SalePrice)", y = "houses",
         title = "Target on the log scale") +
    theme_minimal()
)
