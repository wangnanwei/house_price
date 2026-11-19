# House Prices — Project Introduction and Evaluation Method

**Competition:** [House Prices — Advanced Regression Techniques](https://www.kaggle.com/competitions/house-prices-advanced-regression-techniques) (Kaggle)
**Data:** Ames Housing dataset — `train.csv` (1,460 houses, 81 columns), `test.csv` (1,459 houses, 80 columns)
**Verified against the live competition pages:** 19 November 2026

---

## 1. The project, briefly

Predict the final sale price of a house from 79 variables describing it — size, quality, condition, basement, garage, neighbourhood, sale type. One number per test house, `SalePrice`.

The target ranges from \$34,900 to \$755,000 (median \$163,000) and is strongly right-skewed, so modelling is done on `log1p(SalePrice)`.

The real difficulty is the data, not the model: 7,829 missing values in training, and most of them do **not** mean "unknown". For many columns `NA` means "this house doesn't have that feature" — a house with no pool has `PoolQC = NA`, not an unknown pool quality. There are also 43 categorical variables, skewed continuous variables, and a couple of extreme outliers. Most of the work is deciding what each missing value means and how to encode categorical quality for a regression.

---

## 2. How submissions are scored

**Metric — RMSLE.** Root mean squared error between the log of the predicted price and the log of the observed price:

$$
\text{RMSLE} = \sqrt{\frac{1}{n}\sum_{i=1}^{n}\left(\log(\hat{y}_i) - \log(y_i)\right)^2}
$$

Lower is better. 0.12 ≈ a typical 12% relative error per house. The implementation uses `log1p`, so zero prices are defined.

**Why the log matters.** Errors become relative: a \$20,000 mistake on a \$100,000 house and a \$60,000 mistake on a \$300,000 house count the same. Without the log, the metric would be dominated by the few expensive houses.

Two consequences: train on `log1p(SalePrice)` and convert back with `expm1` before submitting; and never submit a price ≤ 0, because the log is undefined there.

**No public/private split here.** This competition has no end date and runs a rolling leaderboard. Its leaderboard page says: *"This leaderboard is calculated with all of the test data."* The score you see is over all 1,459 test houses — there is no hidden half, and therefore no protected holdout to catch leaderboard overfitting. Also note that the Ames data is public, so the top of the leaderboard is full of perfect 0.00000 scores from looked-up answers; rank is not a measure of model quality.

**Submission format.**

```
Id,SalePrice
1461,169000.1
1462,187724.1233
```

Exactly the 1,459 test `Id`s, one predicted price each. Missing rows, duplicate `Id`s, or extra columns are rejected.

**Limits.** 10 submissions per day; up to 2 final submissions for judging; teams of up to 10. Data is MIT-licensed, academic non-commercial use, no ranking points.

---

## 3. One thing to do before submitting

Submitting is the only way to get a leaderboard score, and there is a daily cap — so it is a poor way to compare models. Score your candidates locally instead: hold out part of `train.csv`, or use 5-fold cross-validation, and compute RMSLE on the log scale with the same folds for every model. That estimate ranks your options; the leaderboard only tells you where you landed.
