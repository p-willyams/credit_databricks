<img width="1920" height="1080" alt="Credit risk" src="https://github.com/user-attachments/assets/cb1dd443-d37c-44dc-8e80-94322f8a33b5" />

> :information_source: For the Portuguese version of this README, see the file **README_PT.md**.

## Project Overview

A **machine learning model for credit default prediction** that reduced financial losses by **R$ 2.29 million** and generated an **additional R$ 41.4 million** in financial value while maintaining the same credit approval rate.

### Highlights

* **AUC-ROC: 0.9764** | **KS: 0.8497** — Strong discriminative power
* **53% less default** among approved clients compared to the current policy
* **30% reduction** in Loss Rate
* **100+ features** extracted from payment history, registration and behavioral data
* Developed in **Databricks** using **Feature Store** and **MLflow**

---

## Business Problem

**Identify clients with higher risk of default** to reduce financial losses without affecting the approval of good clients.

**Target:** Payment delayed by 5 or more days past due date.

**Output:** Default probability (0 to 1) for each charge.

---

## Data & Infrastructure

### Execution in Databricks

Project developed in **Databricks** using Feature Store, Spark, and MLflow.

**Required tables:**

* `credit_score.data.cadastral` — Customer profile and registration data (1,315 clients)
* `credit_score.data.info` — Monthly financial information (24,401 records)
* `credit_score.data.pagamentos` — Collection/payment history (77,414 records)

---

## Solution

**XGBoost model** with **100+ features** organized in Feature Store:

* Registration and sociodemographic data
* Payment history (delays, early payments, on-time payments)
* Income and employee patterns
* Temporal variables (3-, 6-, and 12-month windows)
* Charge characteristics

**Data Leakage Prevention:** Only information available up to the reference date is used, and the dataset is split **chronologically** (60% train / 20% validation / 20% test) rather than randomly, simulating a real credit scenario where the model is trained on the past and applied to the future.

### Model selection

Three classification algorithms were compared using the same preprocessing pipeline (missing-value treatment with a custom `NullImputer`, date feature extraction, One-Hot Encoding, and Min-Max Scaling), with every experiment logged in **MLflow**:

* **XGBoost** — tree-based boosting model
* **Logistic Regression** — linear baseline for interpretability
* **Random Forest** — tree ensemble for nonlinear relationships

**XGBoost** was selected for the final model based on its superior AUC-ROC/KS performance and generalization between validation and test.

---

## Model Performance

Confusion matrix for threshold 0.28 on the test set:

```
[[26780   694]
 [  558  1423]]
```

**Test set results:**

* Accuracy:  **0.9575**
* Precision: **0.6722**
* Recall:    **0.7183**
* F1 Score:  **0.6945**
* AUC-ROC:   **0.9764**

Validation and test results are close, indicating **good generalization ability**.

---

## Risk Analysis by Score Range

To verify if the predicted probability captures different risk levels, clients were grouped by score range:

 Score Range   | Observed Default Rate |
 ------------- | --------------------:|
 0.00 – 0.10   |                   1% |
 0.10 – 0.20   |                  24% |
 0.20 – 0.30   |                  34% |
 0.30 – 0.40   |                  40% |
 0.40 – 0.50   |                  50% |
 0.50 – 0.60   |                  56% |
 0.60 – 1.00   |                  79% |

Results show a **clear relationship between score and observed default**, indicating excellent **risk ranking capability**.

---

## Financial Impact

Comparison between the model and the existing credit policy (proxy), both with a **90.34% approval rate**:

 Indicator                 | Proxy        | Model          | Improvement |
 ------------------------- | -----------: | -------------: | ----------: |
 Approval rate             | 90.34%       | 90.34%         | —           |
 Default rate (approved)   | 2.71%        | **1.28%**      | **-53%**    |
 Loss Rate                 | 2.38%        | **1.67%**      | **-30%**    |
 Approved amount           | 1,351,959,098 | **1,369,286,836** | +17,327,738 |
 Lost amount               | 32,232,028   | **22,861,917** | **-9,370,111** |
 Financial result          | 1,319,727,070 | **1,346,424,919** | **+26,697,849** |

### Estimated Gains

Keeping the same approval rate, the model delivers:

* **53% less default** among approved clients
* **30% reduction** in Loss Rate
* **R$ 9.37 million less** in losses
* **R$ 26.7 million** additional financial value generated
* **~3% increase** in value generated

The model selects a portfolio with **lower risk, lower financial loss, and higher generated value**.

---

## Key Results

✓ **AUC 0.9764 / KS 0.8497** — Strong discriminative power

✓ **Score vs. Default:** 0.0–0.1 → 1% | 0.6–1.0 → 79%

✓ **Financial impact:** +R$ 26.7 mi and -53% default

✓ **Good generalization** between validation and test

✓ **Same approval rate:** 90.34% for both proxy and model

---

## Execution Pipeline

```text
Exploration → Feature Engineering → Feature Store → Training → Evaluation → MLflow → Prediction
```

---

## Project Structure

```text
credit_databricks/
├── LICENSE
├── requirements.txt
├── README.md                          # This file
├── README_PT.md                       # Portuguese version
├── ENGLISH/
│   └── src/
│       ├── 01-initial_exploration/
│       │   ├── 01_data_exploration.ipynb   # Raw data exploration
│       │   └── 02-feature_store.ipynb      # Feature Store design
│       ├── 02-feature_store/
│       │   ├── fs_cadastral.sql            # Registration & sociodemographic features
│       │   ├── fs_temporal.sql             # Temporal features
│       │   ├── fs_income_history.sql       # Income history features
│       │   ├── fs_income.sql               # Income features
│       │   ├── fs_employees.sql            # Employee-related features
│       │   ├── fs_payment_history.sql      # Payment history features
│       │   └── ingestion.ipynb             # Builds/updates the Feature Store tables
│       └── 03-model_inad/
│           ├── fl_default.sql              # Query that builds the labeled sample (target)
│           ├── train.ipynb                 # Model selection, training, evaluation & MLflow
│           └── predict.ipynb               # Loads the model and scores new charges
└── PORTUGUESE/
    └── src/                            # Same pipeline, documented in Portuguese
        └── ...
```

---

## How to Run the Project

This project runs on **Databricks**, using **Unity Catalog**, **Feature Engineering (Feature Store)**, and **MLflow**. The steps below assume you have a Databricks workspace with a running cluster and access to the source tables.

### 1. Import the repository into Databricks

* In your Databricks workspace, go to **Workspace → Import** and upload the repository (or clone it directly via **Repos** if using Git integration).
* Attach the notebooks to a cluster with **Databricks Runtime for Machine Learning** (includes `pandas`, `numpy`, `scikit-learn`, `mlflow`, and `scipy` pre-installed).

### 2. Install additional dependencies

Only two extra libraries are required — they are installed inside the notebooks themselves via `%pip install`, or can be installed once on the cluster:

```bash
pip install databricks-feature-engineering xgboost
```

### 3. Prepare the source tables

Make sure the following tables exist in your Unity Catalog (schema `credit_score.data`):

* `credit_score.data.cadastral`
* `credit_score.data.info`
* `credit_score.data.pagamentos`

### 4. Explore the data (optional)

Run the notebooks in `ENGLISH/src/01-initial_exploration/` to understand the raw data and the Feature Store design:

```text
01_data_exploration.ipynb
02-feature_store.ipynb
```

### 5. Build the Feature Store

Run `ENGLISH/src/02-feature_store/ingestion.ipynb`. This notebook reads each `fs_*.sql` query and writes the results into the Feature Store (`feature_store.credit_score.*`), partitioned by `REF_DATE`, for the list of reference dates defined in the notebook (e.g. `'2018-10'` to `'2021-06'` for training).

> :warning: Adjust the `dates` list inside the notebook to the reference-date range you want to (re)process. Re-running for a date already ingested merges/replaces the data for that date.

### 6. Train the model

Run `ENGLISH/src/03-model_inad/train.ipynb`. This notebook:

1. Builds the labeled training sample from `fl_default.sql`, joined with the Feature Store tables via `FeatureLookup`;
2. Splits the data **chronologically** into train / validation / test (60% / 20% / 20%);
3. Compares **XGBoost**, **Logistic Regression**, and **Random Forest**, logging every run to **MLflow**;
4. Retrains the final **XGBoost** pipeline and logs it to MLflow, printing the `run_id` of the saved model.

> :information_source: Copy the printed `run_id` — you will need it in the next steps (evaluation cells inside `train.ipynb`, and in `predict.ipynb`).

### 7. Ingest the most recent reference date

After training, run the **"Final Ingestion Before Prediction"** section at the end of `ingestion.ipynb`, updating the `dates` list with the most recent reference date (e.g. `'2021-07'`), so the Feature Store has up-to-date features available for scoring.

### 8. Generate predictions

Run `ENGLISH/src/03-model_inad/predict.ipynb`, updating the `run_id` in the model-loading cell (`mlflow.sklearn.load_model("runs:/<run_id>/model")`) to the one saved in step 6. The notebook:

1. Builds the prediction set for the most recent `REF_DATE` using the same `FeatureLookup`s as training;
2. Scores each record with the trained model (`pred` and `proba` columns);
3. Joins the predictions with real payment outcomes and computes **AUC** and **KS** on this most recent batch, as a final sanity check before using the scores in production.

---

## Tech Stack

**Core:** Python, SQL, XGBoost, Pandas, Scikit-learn

**Platform:** Databricks (Spark, Feature Store, MLflow, Unity Catalog)

---

## Conclusion

A complete **default prediction** solution built with a Feature Store architecture, data-leakage prevention, and a full financial impact assessment.

> **Result:** an XGBoost model (AUC 0.9764) that **reduces losses by R$ 9.37 million** and generates **R$ 26.7 million** in additional financial value, while maintaining the same 90.34% approval rate and reducing default among approved clients by **53%**.
