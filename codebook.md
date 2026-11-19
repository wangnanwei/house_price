# Codebook — Ames Housing (79 columns), with profiling evidence

**Definitions:** `data_description.txt` (Dean De Cock, as shipped with the competition).
**Measurements:** `profiling_metrics.csv`, produced by `03_profile_report.R` from `train.csv` (1,460 rows).

`cor` = Pearson correlation with `log1p(SalePrice)`. `quad` = R² gain from adding x² to a linear
fit — the size of the *curvature*, i.e. how badly a straight line misses. `zero%` = share of
exactly zero. `lv` = number of observed levels, `min n` = smallest level's house count, `spread`
= range of median log price across levels, `rho` = Spearman correlation between the dictionary's
level order and median price (|rho| = 1 means the documented order is exactly how price moves).

Type vocabulary: **continuous** · **count** · **ordinal** (order given) · **nominal** (no order) ·
**flag** (binary) · **code** (numeric-looking, not a quantity).
NA vocabulary: **none** = a real category ("no pool") · **unknown** = genuinely missing · **—** = no NAs.

---

## The five problem classes found

| Problem | Column count | Consequence for step 3 |
|---|---|---|
| Skewed (|skew| ≥ 1) | 19 | needs `log1p` before entering a linear fit |
| Curvature (`quad` ≥ 0.02) | 13 | straight-line coefficient understates the effect |
| Rare levels (`min n` < 10) | 25 | dummy coefficients unstable; group into "Other" |
| Missing values | 19 | 14 are categories, only 4 are real gaps |
| Weak signal (|cor| < 0.05, `quad` < 0.01) | 5 | candidates to drop |

Overlap is heavy — one column often carries three tags, which is why 79 columns produce only
~35 usable predictors without derivation. Full per-column tags: `profiling_metrics.csv`.

---

## 1. Structure, lot & location (22)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `MSSubClass` | code, 15 lv | — | quad .035, cor −.07 | factor — curvature proves it is not a quantity |
| `MSZoning` | nominal, 5 | — | min n 10, spread 1.02 | factor |
| `Street` | flag | — | 99.6% Pave | **drop** |
| `Alley` | flag | none | 93.8% none, 91 houses | **drop** or `has_alley` flag |
| `LotShape` | ordinal 0–3 | — | spread .41 | ordinal |
| `LandContour` | nominal, 4 | — | min n 36, spread .47 | factor |
| `Utilities` | flag | — | 1 house not AllPub | **drop** |
| `LotConfig` | nominal, 5 | — | min n 4 | factor, rare levels → "Other" |
| `LandSlope` | ordinal, 3 | — | spread **.14**, rho −.5 | **drop** — 0.14 log units across all levels |
| `Neighborhood` | nominal, 25 | — | min n 2, spread **1.28** | factor — largest single categorical effect; group `<10` |
| `Condition1` | nominal, 9 | — | min n 2, spread .58 | factor, group rare |
| `Condition2` | nominal, 8 | — | 99% Norm | **drop** |
| `BldgType` | nominal, 5 | — | min n 31, spread .30 | factor |
| `HouseStyle` | nominal, 8 | — | min n 8, spread .56 | factor, group rare |
| `RoofStyle` | nominal, 6 | — | min n 2, spread .47 | `Gable` flag + Other |
| `RoofMatl` | nominal, 8 | — | 98% CompShg | **drop** |
| `Exterior1st` | nominal, 15 | — | min n **1**, spread 1.32 | factor — keep top 5 + "Other" |
| `Exterior2nd` | nominal, 16 | — | min n 1, spread 1.11 | near-duplicate of `Exterior1st`; **keep one** |
| `MasVnrType` | nominal, 4 | unknown (8) | min n 15 | factor; the 8 NAs are houses with no veneer → "None" |
| `Foundation` | nominal, 6 | — | min n 3, spread .68 | factor, group rare |
| `GarageType` | nominal, 6 | none | min n 6, spread .74 | factor + "None" level |
| `GarageFinish` | ordinal 3 | none | rho **−1**, min n 352 | ordinal, NA = 0 |

## 2. Size / area (19)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `LotFrontage` | continuous | unknown 17.7% | skew 2.16, cor .36, 12 extreme | impute median **within** `Neighborhood`, then `log1p` |
| `LotArea` | continuous | — | skew **12.2**, cor .26, quad .069, 34 extreme | `log1p` + cap at 99th pct |
| `MasVnrArea` | continuous | unknown (8) | 59% zero, skew 2.66, cor .43 | NA → 0; flag + `log1p` |
| `BsmtFinSF1` | continuous | — | 32% zero, cor .37 | keep |
| `BsmtFinSF2` | continuous | — | **89% zero**, cor **.005** | **drop** |
| `BsmtUnfSF` | continuous | — | cor .22 | keep |
| `TotalBsmtSF` | continuous | — | cor **.61**, quad .028 | `log1p`; = SF1+SF2+UnfSF, so collinear with all three |
| `1stFlrSF` | continuous | — | cor .60, quad .024 | `log1p` |
| `2ndFlrSF` | continuous | — | 57% zero, quad **.087** | presence flag + `log1p` |
| `LowQualFinSF` | continuous | — | 98% zero, cor −.04 | **drop** |
| `GrLivArea` | continuous | — | cor **.70**, quad .045 | `log1p` — strongest size predictor |
| `WoodDeckSF` | continuous | — | 52% zero, cor .33 | flag + `log1p` |
| `OpenPorchSF` | continuous | — | 45% zero, quad .075 | flag + `log1p` |
| `EnclosedPorch` | continuous | — | 86% zero, cor **−.15** | flag only; **negative** sign to investigate |
| `3SsnPorch` | continuous | — | 98% zero | **drop** |
| `ScreenPorch` | continuous | — | 92% zero, cor .12 | flag only |
| `PoolArea` | continuous | — | 99.5% zero, 7 houses | **drop** |
| `GarageArea` | continuous | — | cor .65 | duplicates `GarageCars` (.68); **keep one** |
| `MiscVal` | continuous | — | 96% zero, cor −.02 | **drop** |

## 3. Quality / condition (17)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `OverallQual` | ordinal 1–10 | — | cor **.82**, quad .001 | keep numeric — no curvature at all |
| `OverallCond` | ordinal 1–10 | — | cor **−.04**, quad **.029** | ordinal levels, not a slope; negative sign to investigate |
| `ExterQual` | ordinal 4 | — | rho **−1**, spread **1.49** | ordinal 0–5 |
| `ExterCond` | ordinal 5 | — | rho −.7, min n **1** | ordinal; group rare (88% TA) |
| `BsmtQual` | ordinal 4 | none | rho **−1**, NA → 0 | ordinal 0–5, NA = 0 |
| `BsmtCond` | ordinal 4 | none | rho −1, min n **2**, 92% TA | ordinal; nearly constant |
| `BsmtExposure` | ordinal 4 | none | rho **−1**, min n 114 | ordinal 0–4, NA = 0 |
| `BsmtFinType1` | ordinal 6 | none | spread .43 | ordinal 0–6, NA = 0 |
| `BsmtFinType2` | ordinal 6 | none | 88% Unf | **flag** `has_bsmt_fin2` instead of 6 dummies |
| `HeatingQC` | ordinal 5 | — | rho **−1**, min n 1 | ordinal 0–5, group rare |
| `KitchenQual` | ordinal 4 | — | rho **−1**, spread 1.01 | ordinal 0–5 |
| `Functional` | ordinal 7 | — | rho −.71, min n **1** | ordinal 0–7, group rare (93% Typ) |
| `FireplaceQu` | ordinal 5 | none | rho **−1**, NA → 0 | ordinal 0–5, NA = 0 |
| `GarageQual` | ordinal 5 | none | rho −.7, min n **3**, 95% TA | ordinal; nearly constant |
| `GarageCond` | ordinal 5 | none | rho −.6, min n 2, 96% TA | ordinal; nearly constant |
| `PavedDrive` | ordinal 3 | — | spread .42, 92% Y | flag `Paved` |
| `PoolQC` | ordinal 3 | none | 99.5% none, 7 houses | **drop** |

## 4. Age / time (5)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `YearBuilt` | year | — | cor .59, quad **.062** | age + age² (or spline) — straight line misses badly |
| `YearRemodAdd` | year | — | cor .57, quad .000 | derive `remod_age`, then linear is fine |
| `GarageYrBlt` | year | none | cor .54, quad .045, NA 81 | NA → `YearBuilt`; test has a **2207** typo — clip |
| `MoSold` | month | — | cor **.06** | **drop** as predictor, or a `peak_season` flag |
| `YrSold` | year, 5 lv | — | cor **−.04** | **drop** — use only to build the age features |

## 5. Rooms & counts (9)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `BsmtFullBath` | count 0–3 | — | 59% zero, cor .24 | keep |
| `BsmtHalfBath` | count 0–2 | — | **94% zero**, cor −.005 | **drop** |
| `FullBath` | count 0–3 | — | cor **.60** | keep |
| `HalfBath` | count 0–2 | — | 63% zero, cor .31 | keep |
| `BedroomAbvGr` | count 0–8 | — | cor .21, 1 extreme | keep |
| `KitchenAbvGr` | count 1–3 | — | **95% are 1**, cor −.15 | **drop** |
| `TotRmsAbvGrd` | count 2–14 | — | cor .53 | keep; heavily collinear with `GrLivArea` |
| `Fireplaces` | count 0–3 | — | 47% zero, quad .024 | flag + count |
| `GarageCars` | count 0–4 | — | cor **.68** | keep; the garage measure to retain |

## 6. Systems (3)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `Heating` | nominal, 6 | — | 98% GasA, min n 1 | **drop** |
| `CentralAir` | flag | — | min n **95**, spread .54 | keep flag — only 7% N, and it is real signal |
| `Electrical` | nominal, 5 | unknown (1) | 91% SBrkr, min n 1 | mode impute, collapse to 2 levels |

## 7. Extras present / absent (2)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `Fence` | nominal, 4 | none | 81% none, spread **.25** | `has_fence` flag only |
| `MiscFeature` | nominal, 4 | none | 96% none, min n 1 | **drop** |

## 8. Sale (2)

| Column | Type | NA means | Evidence | Decision |
|---|---|---|---|---|
| `SaleType` | nominal, 9 | — | 87% WD, min n 2 | factor, group rare |
| `SaleCondition` | nominal, 6 | — | spread **.88**, min n 4 | keep — price varies a lot; `Partial`/`New` matter |

---

## Checks on this table

**Every column appears exactly once:** 22 + 19 + 17 + 5 + 9 + 3 + 2 + 2 = **79**.

**`NA` is a category, not a gap** — 14 columns, per the dictionary: `Alley` (93.8%), `BsmtQual`,
`BsmtCond`, `BsmtFinType1`, `BsmtFinType2` (2.5%), `BsmtExposure` (2.6%), `FireplaceQu` (47.3%),
`GarageType` / `GarageFinish` / `GarageQual` / `GarageCond` (5.5%), `PoolQC` (99.5%),
`Fence` (80.8%), `MiscFeature` (96.3%).

**Genuinely missing — all four:** `LotFrontage` 17.7%, `MasVnrType` / `MasVnrArea` 8 rows,
`Electrical` 1 row.

**Documented order matches price** — 8 columns at |rho| = 1.00 (`ExterQual`, `BsmtQual`,
`BsmtCond`, `BsmtExposure`, `HeatingQC`, `KitchenQual`, `FireplaceQu`, `GarageFinish`). The
ordering in the dictionary is the ordering in the data, so one ordinal column beats 4–5 dummies.

**Order is imperfect** where rare levels distort it: `Functional` −.71 (min n 1), `ExterCond`
−.70 (min n 1), `GarageQual` −.70 (min n 3), `GarageCond` −.60 (min n 2). Group the rare levels
first, then encode.

**Curvature is not always what it looks like.** `2ndFlrSF` (.087), `OpenPorchSF` (.075),
`EnclosedPorch`, `WoodDeckSF`, `ScreenPorch`, `3SsnPorch` all pile up at zero. Their R² gain from
x² is mostly the *step* at zero — presence versus absence — not a smooth bend. `YearBuilt` (.062)
and `LotArea` (.069) are the genuine curves: a straight line really does miss them.

**Two negative correlations worth a look before trusting the coefficient:** `EnclosedPorch`
(−.15) and `KitchenAbvGr` (−.15), plus `OverallCond` (−.04) with curvature. Negative is plausible
here (`OverallCond` is high on old houses), but a linear fit will hand you a negative price
effect, which needs to be explained rather than shipped.
