# 02_prepare_features.R
# ---------------------------------------------------------------------------
# Job: turn 79 raw columns into something a linear model can actually use.
# This is the only step that changes the data. Nothing is modelled here.
#
# Order matters: types first, then scale, then gaps, then the flags that
# depend on the gaps already being filled.
# ---------------------------------------------------------------------------

library(tidyverse)

train <- read_csv("train.csv", show_col_types = FALSE) |> mutate(log_price = log1p(SalePrice))
test  <- read_csv("test.csv",  show_col_types = FALSE)

cat("== input ==\n")
cat("train:", nrow(train), "x", ncol(train), " | test:", nrow(test), "x", ncol(test), "\n\n")

# 1. Drop ---------------------------------------------------------------
# Near-constant (>=95% one value) or measured correlation under 0.05 with no
# curvature, plus one duplicate column.
drop_cols <- c(
  "Street", "Utilities", "Condition2", "RoofMatl", "LandSlope",     # near-constant
  "PoolQC", "PoolArea", "MiscFeature", "MiscVal", "3SsnPorch",      # <=7 houses
  "LowQualFinSF", "BsmtFinSF2", "BsmtHalfBath", "KitchenAbvGr",     # 90%+ zero
  "Heating", "MoSold", "Alley",                                     # no signal
  "MSSubClass",                                                     # 15-level code
  "Exterior2nd"                                                     # duplicate of Exterior1st
)

train <- train |> select(-any_of(drop_cols))
test  <- test  |> select(-any_of(drop_cols))

# 2. Ordinal scales ----------------------------------------------------
# One number per level, worst = low. The dictionary order is the price order
# (|rho| = 1.00 on eight of these), so one slope replaces four dummies.
qual    <- c(Po = 1, Fa = 2, TA = 3, Gd = 4, Ex = 5)
funct   <- c(Sal = 0, Sev = 1, Maj2 = 2, Maj1 = 3, Mod = 4, Min2 = 5, Min1 = 6, Typ = 7)
bsmtfin <- c(Unf = 1, LwQ = 2, Rec = 3, BLQ = 4, ALQ = 5, GLQ = 6)
expos   <- c(No = 1, Mn = 2, Av = 3, Gd = 4)
gfin    <- c(Unf = 1, RFn = 2, Fin = 3)
drive   <- c(N = 0, P = 1, Y = 2)
shape   <- c(Reg = 0, IR1 = 1, IR2 = 2, IR3 = 3)
yesno   <- c(N = 0, Y = 1)

as_ord <- function(x, map) unname(map[as.character(x)])

ordinalise <- function(df) {
  df |> mutate(
    LotShape     = as_ord(LotShape, shape),
    ExterQual    = as_ord(ExterQual, qual),
    ExterCond    = as_ord(ExterCond, qual),
    BsmtQual     = as_ord(BsmtQual, qual),
    BsmtCond     = as_ord(BsmtCond, qual),
    HeatingQC    = as_ord(HeatingQC, qual),
    KitchenQual  = as_ord(KitchenQual, qual),
    FireplaceQu  = as_ord(FireplaceQu, qual),
    GarageQual   = as_ord(GarageQual, qual),
    GarageCond   = as_ord(GarageCond, qual),
    BsmtExposure = as_ord(BsmtExposure, expos),
    BsmtFinType1 = as_ord(BsmtFinType1, bsmtfin),
    BsmtFinType2 = as_ord(BsmtFinType2, bsmtfin),
    GarageFinish = as_ord(GarageFinish, gfin),
    Functional   = as_ord(Functional, funct),
    PavedDrive   = as_ord(PavedDrive, drive),
    CentralAir   = as_ord(CentralAir, yesno)
  )
}
train <- ordinalise(train)
test  <- ordinalise(test)

# NA here means "no basement / no garage / no fireplace": a real level, and
# the worst one. Encode as 0 instead of imputing a house into owning a garage.
ord_cols <- c("BsmtQual", "BsmtCond", "BsmtExposure", "BsmtFinType1", "BsmtFinType2",
              "FireplaceQu", "GarageFinish", "GarageQual", "GarageCond")
train <- train |> mutate(across(all_of(ord_cols), ~ replace_na(.x, 0)))
test  <- test  |> mutate(across(all_of(ord_cols), ~ replace_na(.x, 0)))

# 3. log1p on skewed sizes ---------------------------------------------
# Skew above 1 means a straight line is dominated by a few enormous values.
# log1p keeps zero at zero, so an empty basement stays empty.
log_cols <- c("LotFrontage", "LotArea", "MasVnrArea", "TotalBsmtSF", "GrLivArea",
              "2ndFlrSF", "BsmtFinSF1", "WoodDeckSF", "OpenPorchSF")
train <- train |> mutate(across(all_of(log_cols), ~ log1p(.x)))
test  <- test  |> mutate(across(all_of(log_cols), ~ log1p(.x)))

# 4. Fill the gaps -----------------------------------------------------
# LotFrontage is the only column missing in a pattern worth modelling: frontage
# is near-constant inside a neighbourhood, so use that median. The medians
# come from TRAIN ONLY — using test values here would build part of your
# validation score out of the data you are scoring on.
frontage_median <- train |>
  group_by(Neighborhood) |>
  summarise(med_front = median(LotFrontage, na.rm = TRUE), .groups = "drop")

fill_frontage <- function(df) {
  df |>
    left_join(frontage_median, by = "Neighborhood") |>
    mutate(LotFrontage = if_else(is.na(LotFrontage), log1p(med_front), LotFrontage),
           MasVnrArea  = replace_na(MasVnrArea, 0),
           MasVnrType  = replace_na(MasVnrType, "None"),
           Electrical  = replace_na(Electrical, "SBrkr")) |>
    select(-med_front)
}
train <- fill_frontage(train)
test  <- fill_frontage(test)

# A few columns are complete in train but not in test: those are real gaps and
# get a train median / mode. Nothing else is touched here. An NA in GarageType,
# Fence or GarageYrBlt means "no garage", "no fence", "no build year" — filling
# it would invent a garage the house does not have.
gap_cols <- c("MSZoning", "Exterior1st", "BsmtFinSF1", "BsmtUnfSF", "TotalBsmtSF",
              "BsmtFullBath", "KitchenQual", "Functional", "GarageCars", "GarageArea",
              "SaleType")

fill_leftovers <- function(df, ref, side) {
  fixed <- character(0)
  for (nm in intersect(gap_cols, names(df))) {
    if (!any(is.na(df[[nm]]))) next
    if (is.numeric(ref[[nm]])) {
      df[[nm]] <- replace_na(df[[nm]], median(ref[[nm]], na.rm = TRUE))
    } else {
      mode <- names(sort(table(ref[[nm]]), decreasing = TRUE))[1]
      df[[nm]] <- replace_na(df[[nm]], mode)
    }
    fixed <- c(fixed, nm)
  }
  if (length(fixed)) cat(side, "filled:", paste(fixed, collapse = ", "), "\n")
  df
}
train <- fill_leftovers(train, train, "train")
test  <- fill_leftovers(test,  train, "test ")

# 5. Presence flags ----------------------------------------------------
# The step at zero is what these areas really contribute: a house with a 200
# sq ft deck is not "200 units better", it is a different kind of house. The
# flag carries that, the area carries the size.
# No has_garage flag: "no garage" is already the "None" level of GarageType,
# and both cannot enter the same fit (they are exact complements, so lm()
# would return NA for one of them).
flag_me <- function(df) {
  df |> mutate(
    has_2nd_floor      = as.integer(`2ndFlrSF`    > 0),
    has_wood_deck      = as.integer(WoodDeckSF    > 0),
    has_open_porch     = as.integer(OpenPorchSF   > 0),
    has_enclosed_porch = as.integer(EnclosedPorch > 0),
    has_screen_porch   = as.integer(ScreenPorch   > 0),
    has_fireplace      = as.integer(Fireplaces    > 0),
    has_bsmt           = as.integer(TotalBsmtSF   > 0),
    has_fence          = as.integer(!is.na(Fence))
  )
}
train <- flag_me(train)
test  <- flag_me(test)

# Fence, EnclosedPorch and ScreenPorch keep only their flag: 81%, 86% and
# 92% empty, and the enclosed-porch area correlates *negatively* with price.
train <- train |> select(-Fence, -EnclosedPorch, -ScreenPorch)
test  <- test  |> select(-Fence, -EnclosedPorch, -ScreenPorch)

# 6. Keep the nominal columns as factors -------------------------------
# lm() builds the dummies itself, so the columns stay readable and R manages
# the reference levels. What lm() sees is the same model matrix either way —
# this changes what is stored, not the number of parameters fitted.
#
# Two things still have to be decided here, by us:
#   - levels with fewer than 10 houses in train are pooled into "Other"
#     (a coefficient from 3 houses is noise with a standard error attached)
#   - NA in a nominal column means "none" (no garage, no veneer), so it
#     becomes its own level instead of being imputed
# And one thing is decided for step 4: test values the model never saw are
# mapped to the reference level, so predict() cannot fail on a new level.
nom_cols <- c("MSZoning", "LandContour", "LotConfig", "Neighborhood",
              "Condition1", "BldgType", "HouseStyle", "RoofStyle", "Exterior1st",
              "Foundation", "GarageType", "SaleType", "SaleCondition", "Electrical",
              "MasVnrType")

to_factors <- function(cols, tr, te, min_n = 10) {
  for (nm in cols) {
    a <- as.character(tr[[nm]]); b <- as.character(te[[nm]])
    a[is.na(a)] <- "None"; b[is.na(b)] <- "None"
    tab  <- table(a, useNA = "no")
    keep <- names(tab)[tab >= min_n]
    a[!a %in% keep] <- "Other"
    b[!b %in% keep] <- "Other"
    lv <- sort(unique(a))
    b[!b %in% lv] <- lv[1]          # unseen test level -> reference level
    tr[[nm]] <- factor(a, levels = lv)
    te[[nm]] <- factor(b, levels = lv)
  }
  list(tr = tr, te = te)
}

fac <- to_factors(nom_cols, train, test)
train <- fac$tr
test  <- fac$te

# 7. Ages instead of years ---------------------------------------------
# A year is not a quantity to put a slope on: 1900->1950 is not the same step
# as 2000->2010. Age turns it into a decay from the sale date. Test contains
# GarageYrBlt = 2207 (a typo); pmax(..., 0) stops a negative age.
make_ages <- function(df) {
  df |> mutate(
    age        = pmax(YrSold - YearBuilt, 0),
    remod_age  = pmax(YrSold - YearRemodAdd, 0),
    garage_age = pmax(YrSold - coalesce(GarageYrBlt, YearBuilt), 0)
  )
}
train <- make_ages(train) |> select(-YearBuilt, -YearRemodAdd, -GarageYrBlt, -YrSold)
test  <- make_ages(test)  |> select(-YearBuilt, -YearRemodAdd, -GarageYrBlt, -YrSold)

# 8. Known collinearity, removed on purpose ----------------------------
# GrLivArea = 1stFlrSF + 2ndFlrSF + LowQualFinSF and the last one is dropped
# -> keep the total, drop the first floor.
# TotalBsmtSF = BsmtFinSF1 + BsmtFinSF2 + BsmtUnfSF -> drop the unfinished part.
# GarageArea and GarageCars describe the same garage -> keep the count.
redundant <- c("1stFlrSF", "BsmtUnfSF", "GarageArea")
train <- train |> select(-any_of(redundant))
test  <- test  |> select(-any_of(redundant))

# 9. Column names must be formula-safe --------------------------------
# "Wd Sdng" (space), "1.5Unf" (dot) and "2ndFlrSF" (leading digit) all break
# an explicit lm() formula. make.names() fixes all three; ~ . would hide it.
names(train) <- make.names(names(train), unique = TRUE)
names(test)  <- make.names(names(test),  unique = TRUE)

# 10. Final shape ----------------------------------------------------
train <- train |> select(Id, log_price, everything(), -SalePrice)
test  <- test  |> select(Id, everything())

feat_tr <- setdiff(names(train), c("Id", "log_price"))
feat_te <- setdiff(names(test),  "Id")
stopifnot(identical(sort(feat_tr), sort(feat_te)),
          all(map_lgl(train[feat_tr], ~ is.numeric(.x) || is.factor(.x))))

# What lm() will actually fit: factors expand into dummies internally, so the
# stored column count and the model matrix width are different numbers. Report
# both, because that difference is what governs overfitting.
mm_width <- ncol(model.matrix(~ . , data = train[feat_tr]))

cat("\n== output ==\n")
cat("stored feature columns:", length(feat_tr), " (from 79)\n")
n_fac  <- sum(map_lgl(train[feat_tr], is.factor))
n_flag <- sum(str_starts(feat_tr, "has_"))
n_ord  <- sum(feat_tr %in% c("LotShape", "ExterQual", "ExterCond", "BsmtQual", "BsmtCond",
                             "HeatingQC", "KitchenQual", "FireplaceQu", "GarageQual",
                             "GarageCond", "BsmtExposure", "BsmtFinType1", "BsmtFinType2",
                             "GarageFinish", "Functional", "PavedDrive", "CentralAir"))
n_num  <- length(feat_tr) - n_fac - n_flag - n_ord
cat("of which: ordinals", n_ord, "| numeric/count", n_num,
    "| flags", n_flag, "| factors", n_fac, "\n")
cat("model matrix width (incl. intercept):", mm_width,
    " -> parameters lm() fits:", mm_width - 1, "\n")
cat("rows per parameter:", round(nrow(train) / (mm_width - 1), 1), "\n")
cat("train:", nrow(train), "x", ncol(train), " | test:", nrow(test), "x", ncol(test), "\n")
cat("train NA cells:", sum(is.na(train)), " | test NA cells:", sum(is.na(test)), "\n")
cat("dropped:", length(drop_cols) + length(redundant) + 3 + 4, "raw columns\n")

cat("\nfactor levels:\n")
for (nm in nom_cols) cat(sprintf("  %-14s %2d\n", nm, nlevels(train[[nm]])))

# CSV for reading, RDS for modelling: a CSV cannot carry factor levels, and
# re-reading it as character would silently lose which level is the reference.
write_csv(train, "train_prepared.csv")
write_csv(test,  "test_prepared.csv")
saveRDS(train, "train_prepared.rds")
saveRDS(test,  "test_prepared.rds")
cat("\nwritten: train_prepared.{csv,rds}, test_prepared.{csv,rds}\n")
