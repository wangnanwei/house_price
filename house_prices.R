# House Prices — starter script
# Open try1.Rproj in RStudio first; paths below are relative to the project root,
# so no setwd() is needed.

library(tidyverse)

# readr (part of tidyverse) parses the "NA" strings as missing by default
# and guesses column types. Character columns stay <chr>, not <fct>.
train <- read_csv("train.csv", show_col_types = FALSE)
test  <- read_csv("test.csv",  show_col_types = FALSE)

# The competition metric: RMSE on the log scale (log1p), lower is better.
rmsle <- function(actual, predicted) {
  sqrt(mean((log1p(predicted) - log1p(actual))^2))
}

# Shape
dim(train)
dim(test)

# Target summary
summary(train$SalePrice)

# A few columns to orient yourself
train |>
  select(Id, SalePrice, OverallQual, GrLivArea, Neighborhood, YearBuilt) |>
  glimpse()

# Missing values per column, worst first
train |>
  summarise(across(everything(), ~ sum(is.na(.x)))) |>
  pivot_longer(everything(), names_to = "column", values_to = "n_missing") |>
  filter(n_missing > 0) |>
  arrange(desc(n_missing)) |>
  print(n = 20)

# How many columns are non-numeric?
train |> keep(~ !is.numeric(.x)) |> length()

# From here: build your own preprocessing, model, and submission.
