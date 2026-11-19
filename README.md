# House Prices — Ames, Iowa (STAT4053)

Working R/RStudio project for the Kaggle
[House Prices — Advanced Regression Techniques](https://www.kaggle.com/competitions/house-prices-advanced-regression-techniques)
competition, built from scratch.

## What the task is

Predict `SalePrice` for 1,459 test houses from 79 variables describing each home.
Training data: 1,460 houses. Metric: RMSLE — RMSE between log(predicted) and
log(actual), lower is better (see `EVALUATION.md`).

## Files

| File | What it is |
|---|---|
| `train.csv` | 1,460 labelled houses, 81 columns |
| `test.csv` | 1,459 houses to predict, 80 columns |
| `house_prices.R` | starter script: loads data, defines the RMSLE helper |
| `EVALUATION.md` | short notes on the task, the metric, the submission format |
| `try1.Rproj` | RStudio project file |

## Running

Open `try1.Rproj` in RStudio, then run `house_prices.R`. Paths are relative to
the project root, so no `setwd()` is needed.

## Submitting

Build `submission.csv` with columns `Id,SalePrice` — exactly the 1,459 test ids,
one positive predicted price each. Limit is 10 submissions per day.

## Data notes

`NA` in this dataset often means "this house does not have that feature"
(e.g. `PoolQC = NA` means no pool), not "unknown". Decide per column before
imputing. The data is MIT-licensed and the competition allows academic use only.
