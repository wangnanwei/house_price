library(tidyverse)
dtrain<-read_csv("train.csv",show_col_types = FALSE)
dtest<-read_csv("test.csv")

str(dtrain)
dtrain$logSalePrice=log1p(dtrain$SalePrice)
ggplot(data=dtrain,aes(x=logSalePrice))+geom_histogram(fill="skyblue",colour = "black",binwidth=0.1)




dtrain$PoolQC


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
