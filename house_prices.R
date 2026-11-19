# House Prices — starter script
# Open try1.Rproj in RStudio first; paths below are relative to the project root.

train <- read.csv("train.csv", stringsAsFactors = TRUE, na.strings = c("NA", ""))
test  <- read.csv("test.csv",  stringsAsFactors = TRUE, na.strings = c("NA", ""))

# The competition metric: RMSE on the log scale (log1p), lower is better.
rmsle <- function(actual, predicted) {
  sqrt(mean((log1p(predicted) - log1p(actual))^2))
}

# Shape of the data
cat("train:", nrow(train), "x", ncol(train), "\n")
cat("test :", nrow(test),  "x", ncol(test),  "\n")
cat("target:", min(train$SalePrice), "-", max(train$SalePrice),
    "median", median(train$SalePrice), "\n")
cat("missing values in train:", sum(is.na(train)), "\n")

# Which columns are categorical?
cat("categorical columns:", sum(vapply(train, is.factor, logical(1))), "\n")

# From here: build your own preprocessing, model, and submission.
