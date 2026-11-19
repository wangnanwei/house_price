# Codebook — Ames Housing (79 columns)

**Source of definitions:** `data_description.txt` (Dean De Cock, as shipped with the competition).
**Source of counts:** measured on `train.csv` (1,460 rows) — `n_distinct`, NA share, dominant value.
**Status:** decisions are *proposals* for step 3 onward, not final. Step 1 records what exists; the
right-hand column is a first reading of it.

Type vocabulary: **continuous** · **count** · **ordinal** (levels have an order, given in the cell) ·
**nominal** (no order) · **flag** (binary) · **code** (numeric-looking, not a quantity).

NA vocabulary: **none** = a real category ("no pool"), **unknown** = genuinely missing, **—** = no NAs.

---

## 1. Structure, lot & location (22)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `MSSubClass` | code, 15 levels (20, 30, 60, 90, 190…) | — | factor. Numeric but a dwelling-type code; overlaps `BldgType` + `HouseStyle` |
| `MSZoning` | nominal, 5 | — | factor |
| `Street` | flag (Pave / Grvl) | — | **drop** — 1,454/1,460 Pave |
| `Alley` | flag (Pave / Grvl) | none — no alley access | factor with a "None" level (93.8% none), or drop |
| `LotShape` | ordinal Reg < IR1 < IR2 < IR3 | — | ordinal 0–3 |
| `LandContour` | nominal, 4 | — | factor (90% Lvl) |
| `Utilities` | flag (AllPub / NoSeWa) | — | **drop** — 1,459/1,460 AllPub |
| `LotConfig` | nominal, 5 | — | factor |
| `LandSlope` | ordinal Gtl < Mod < Sev | — | **drop** or binary — 95% Gtl |
| `Neighborhood` | nominal, 25 | — | factor — the main location signal |
| `Condition1` | nominal, 9 | — | factor |
| `Condition2` | nominal, 8 | — | **drop** — 99% Norm |
| `BldgType` | nominal, 5 | — | factor |
| `HouseStyle` | nominal, 8 | — | factor |
| `RoofStyle` | nominal, 6 | — | factor, or drop — 78% Gable |
| `RoofMatl` | nominal, 8 | — | **drop** — 98% CompShg |
| `Exterior1st` | nominal, 15 | — | factor; group levels with <10 houses |
| `Exterior2nd` | nominal, 16 | — | factor — but near-duplicate of `Exterior1st`; keep one |
| `MasVnrType` | nominal, 4 (+NA) | unknown (8 rows) | factor; the 8 NAs are houses with no veneer → "None" |
| `Foundation` | nominal, 6 | — | factor |
| `GarageType` | nominal, 6 | none — no garage | factor with a "None" level |
| `GarageFinish` | ordinal Fin > RFn > Unf | none — no garage | ordinal 0–3, NA = 0 |

## 2. Size / area (19)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `LotFrontage` | continuous (feet) | unknown, 17.7% | impute median **within** `Neighborhood` |
| `LotArea` | continuous (sq ft) | — | log1p |
| `MasVnrArea` | continuous (sq ft) | unknown (8 rows) | NA → 0; 59% are already 0 |
| `BsmtFinSF1` | continuous (sq ft) | — | keep; 32% zero |
| `BsmtFinSF2` | continuous (sq ft) | — | 89% zero — drop or fold into a total |
| `BsmtUnfSF` | continuous (sq ft) | — | keep |
| `TotalBsmtSF` | continuous (sq ft) | — | log1p — exactly `SF1 + SF2 + UnfSF`, so collinear with all three |
| `1stFlrSF` | continuous (sq ft) | — | log1p |
| `2ndFlrSF` | continuous (sq ft) | — | log1p, 57% zero |
| `LowQualFinSF` | continuous (sq ft) | — | **drop** — 98% zero |
| `GrLivArea` | continuous (sq ft) | — | log1p — strongest size predictor |
| `WoodDeckSF` | continuous (sq ft) | — | keep, or flag (52% zero) |
| `OpenPorchSF` | continuous (sq ft) | — | keep (45% zero) |
| `EnclosedPorch` | continuous (sq ft) | — | flag (86% zero) |
| `3SsnPorch` | continuous (sq ft) | — | **drop** or flag — 98% zero |
| `ScreenPorch` | continuous (sq ft) | — | flag (92% zero) |
| `PoolArea` | continuous (sq ft) | — | **drop** — 99.5% zero, same information as `PoolQC` |
| `GarageArea` | continuous (sq ft) | — | log1p — duplicates `GarageCars` |
| `MiscVal` | continuous ($) | — | **drop** or flag — 96% zero |

## 3. Quality / condition (ordinal) (17)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `OverallQual` | ordinal 1–10 | — | keep as numeric — 0.79 correlation with price, strongest single variable |
| `OverallCond` | ordinal 1–10 | — | keep as numeric, but 56% are 5, so little spread |
| `ExterQual` | ordinal Po < Fa < TA < Gd < Ex (4 observed) | — | 0–5 |
| `ExterCond` | ordinal, 5 | — | 0–5 — 88% TA, nearly constant |
| `BsmtQual` | ordinal, 4 observed | none — no basement | 0–5, NA = 0 |
| `BsmtCond` | ordinal, 4 observed | none — no basement | 0–5, NA = 0 — 92% TA |
| `BsmtExposure` | ordinal Gd > Av > Mn > No | none — no basement | 0–4, NA = 0 |
| `BsmtFinType1` | ordinal GLQ > ALQ > BLQ > Rec > LwQ > Unf | none — no basement | 0–6, NA = 0 |
| `BsmtFinType2` | ordinal, same scale | none — no basement | 0–6, NA = 0 — 88% Unf |
| `HeatingQC` | ordinal, 5 | — | 0–5 |
| `KitchenQual` | ordinal, 4 observed | — | 0–5 |
| `Functional` | ordinal Typ > Min1 > Min2 > Mod > Maj1 > Maj2 > Sev > Sal (7 observed) | — | 0–7 — 93% Typ |
| `FireplaceQu` | ordinal, 5 | none — no fireplace | 0–5, NA = 0 |
| `GarageQual` | ordinal, 5 | none — no garage | 0–5, NA = 0 — 95% TA |
| `GarageCond` | ordinal, 5 | none — no garage | 0–5, NA = 0 — 96% TA |
| `PavedDrive` | ordinal Y > P > N | — | 0–2, or flag — 92% Y |
| `PoolQC` | ordinal, 3 observed | none — no pool | **drop** — 99.5% none |

## 4. Age / time (5)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `YearBuilt` | year | — | derive `Age = YrSold − YearBuilt` |
| `YearRemodAdd` | year | — | derive `RemodAge = YrSold − YearRemodAdd` |
| `GarageYrBlt` | year | none — no garage | NA → `YearBuilt`; derive garage age |
| `MoSold` | month, 1–12 | — | factor (seasonality), not continuous |
| `YrSold` | year, 5 levels | — | factor; also only used to build the age features |

## 5. Rooms & counts (9)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `BsmtFullBath` | count 0–3 | — | keep |
| `BsmtHalfBath` | count 0–2 | — | keep, or merge into `TotalBath` — 94% zero |
| `FullBath` | count 0–3 | — | keep |
| `HalfBath` | count 0–2 | — | keep |
| `BedroomAbvGr` | count 0–8 | — | keep |
| `KitchenAbvGr` | count 1–3 | — | **drop** or fold — 95% are 1 |
| `TotRmsAbvGrd` | count 2–14 | — | keep, but strongly correlated with `GrLivArea` |
| `Fireplaces` | count 0–3 | — | keep (47% zero) |
| `GarageCars` | count 0–4 | — | keep — 0.64 correlation; collinear with `GarageArea` |

## 6. Systems (3)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `Heating` | nominal, 6 | — | **drop** — 98% GasA |
| `CentralAir` | flag (Y / N) | — | factor — 93% Y, but the 7% is a real signal |
| `Electrical` | nominal, 5 | unknown (1 row) | mode impute; 91% SBrkr |

## 7. Extras present / absent (2)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `Fence` | nominal, 4 | none — no fence | **drop**, or a single `has_fence` flag |
| `MiscFeature` | nominal, 4 | none — none | **drop**, or a flag — 96% none |

## 8. Sale (2)

| Column | Type | NA means | Decision |
|---|---|---|---|
| `SaleType` | nominal, 9 | — | factor; 87% WD, group the rest |
| `SaleCondition` | nominal, 6 | — | factor — 82% Normal; `Partial` and `New` matter |

---

## Checks on this table

**Every column appears exactly once:** 22 + 19 + 17 + 5 + 9 + 3 + 2 + 2 = **79**.

**`NA` is a category, not a gap** — 14 columns, confirmed by the dictionary listing `NA` as a level:

`Alley` (93.8% none), `Fence` (80.8%), `MiscFeature` (96.3%), `PoolQC` (99.5%),
`FireplaceQu` (47.3%), `GarageType` / `GarageFinish` / `GarageQual` / `GarageCond` (5.5% each),
`BsmtQual` / `BsmtCond` / `BsmtFinType1` / `BsmtFinType2` (2.5%), `BsmtExposure` (2.6%).

**Genuinely missing** (must be imputed or the rows lost): `LotFrontage` 17.7%,
`MasVnrType` / `MasVnrArea` 0.5% (8 rows), `Electrical` 1 row. That is all.

**Near-constant, ≥95% one value** — 12 columns carrying almost no information:
`Utilities` (99.9%), `Street` (99.6%), `Condition2` (99.0%), `RoofMatl` (98.2%),
`Heating` (97.8%), `LowQualFinSF` (98.2% zero), `3SsnPorch` (98.4% zero), `PoolArea` (99.5% zero),
`MiscVal` (96.4% zero), `KitchenAbvGr` (95.3% one), `GarageQual` (95.1% TA), `GarageCond` (96.2% TA).

**Numeric-looking codes / cycles:** `MSSubClass` (type code), `MoSold` (month), `YrSold` (5 years).
These are factors, not quantities; treat them as continuous and the coefficient is meaningless.
