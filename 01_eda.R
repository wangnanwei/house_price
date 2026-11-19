library(tidyverse)
dtrain<-read_csv("train.csv",show_col_types = FALSE)
dtest<-read_csv("test.csv")

str(dtrain)
dtrain$logSalePrice=log1p(dtrain$SalePrice)
ggplot(data=dtrain,aes(x=logSalePrice))+geom_histogram(fill="skyblue",colour = "black",binwidth=0.1)






# ---------------------------------------------------------------------------
# Section: profile all 79 columns
# ---------------------------------------------------------------------------
# Mechanical facts behind codebook.md: type, distinct values, missing share,
# the most common value and its share. Run the whole file; each block prints
# one table. Id and SalePrice are excluded — they are identifiers/target.

profile_cols <- function(df) {
  tibble(column = names(df)) |>
    mutate(
      cls        = map_chr(column, ~ class(df[[.x]])[1]),
      n_distinct = map_int(column, ~ n_distinct(df[[.x]], na.rm = TRUE)),
      na_pct     = map_dbl(column, ~ round(100 * mean(is.na(df[[.x]])), 1)),
      top_value  = map_chr(column, function(nm) {
        v <- df[[nm]][!is.na(df[[nm]])]
        if (!length(v)) return(NA_character_)
        names(sort(table(v), decreasing = TRUE))[1]
      }),
      top_share  = map_dbl(column, function(nm) {
        v <- df[[nm]][!is.na(df[[nm]])]
        if (!length(v)) return(NA_real_)
        round(100 * max(table(v)) / length(v), 1)
      })
    )
}

# Profiling runs on the raw features only: Id, SalePrice and the derived
# logSalePrice added above are not predictors, so they are excluded here.
prof <- profile_cols(dtrain |> select(-any_of(c("Id", "SalePrice", "logSalePrice"))))

# 1. Missing values, worst first. NA here can be a category, not a gap.
prof |>
  select(column, na_pct, n_distinct, top_value) |>
  arrange(desc(na_pct)) |>
  print(n = 79)

# 2. Near-constant: one value holds >=95% of the non-missing rows.
print(
  prof |>
    filter(top_share >= 95) |>
    arrange(desc(top_share))
)

# 3. The 14 columns where NA is a documented level ("no pool", "no garage").
na_is_category <- c(
  "Alley", "BsmtQual", "BsmtCond", "BsmtExposure", "BsmtFinType1", "BsmtFinType2",
  "FireplaceQu", "GarageType", "GarageFinish", "GarageQual", "GarageCond",
  "PoolQC", "Fence", "MiscFeature"
)

print(
  prof |>
    filter(column %in% na_is_category) |>
    arrange(desc(na_pct))
)

# 4. Numeric columns with few distinct values: codes, counts or cycles,
#    not quantities. Candidates for factor().
print(
  prof |>
    filter(cls == "numeric", n_distinct <= 15) |>
    arrange(n_distinct)
)

# 5. Sanity check: every column accounted for exactly once.
cat("columns profiled:", nrow(prof), "\n")


# ---------------------------------------------------------------------------
# Section: inspect one variable at a time
# ---------------------------------------------------------------------------
# profile_cols() gives the mechanical facts for all 79 columns in one table.
# This section is the next pass: one variable, its distribution, its outliers
# and its relationship with the target — the evidence behind each `Decision`
# cell in codebook.md. Call it as you walk through a family.

library(patchwork)

inspect_col <- function(df, nm) {
  x <- df[[nm]]
  y <- df$logSalePrice
  cat("\n--- ", nm, " ---\n", sep = "")

  if (is.numeric(x)) {
    q <- quantile(x, c(0, .25, .5, .75, 1), na.rm = TRUE)
    cat("numeric | NA:", sum(is.na(x)),
        "| zeros:", round(100 * mean(x == 0, na.rm = TRUE), 1), "%",
        "| distinct:", n_distinct(x, na.rm = TRUE),
        "| cor with log price:", round(cor(x, y, use = "complete.obs"), 3), "\n")
    cat("min | Q1 | median | Q3 | max:", paste(round(q, 1), collapse = " | "), "\n")

    p1 <- ggplot(tibble(x = x), aes(x = x)) +
      geom_histogram(fill = "skyblue", colour = "black", bins = 30) +
      labs(x = nm, y = NULL, title = "distribution")

    p2 <- ggplot(tibble(x = x, y = y), aes(x = x, y = y)) +
      geom_point(alpha = 0.4) +
      geom_smooth(method = "loess", se = FALSE, colour = "firebrick") +
      labs(x = nm, y = "log price", title = "against the target")

    print(p1 + p2)

  } else {
    # Levels sorted by median price: shows both the ordering and how few
    # houses sit in each level, which is what decides "dummy or drop".
    lv <- tibble(x = x, y = y) |>
      group_by(level = replace_na(x, "(NA)")) |>
      summarise(n = n(), median_log = median(y, na.rm = TRUE), .groups = "drop") |>
      arrange(median_log)

    print(lv, n = 30)

    print(
      ggplot(lv, aes(x = median_log, y = fct_reorder(level, median_log), fill = n)) +
        geom_col() +
        labs(x = "median log price", y = NULL, title = nm, fill = "houses")
    )
  }
  invisible(NULL)
}

# Several columns in a row — handy for one family at a time.
inspect_cols <- function(df, cols) {
  for (nm in cols) inspect_col(df, nm)
}

# Usage examples (run them one at a time in the console):
# inspect_col(dtrain, "GrLivArea")
# inspect_col(dtrain, "OverallQual")
# inspect_col(dtrain, "Neighborhood")
# inspect_cols(dtrain, c("LotArea", "LotFrontage"))
