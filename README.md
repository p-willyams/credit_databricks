<img width="1920" height="1080" alt="Credit risk" src="https://github.com/user-attachments/assets/cb1dd443-d37c-44dc-8e80-94322f8a33b5" />

> :information_source: For the Portuguese version of this README, see the file **README_PT.md**.

## Project Overview

A **machine learning model for credit default prediction** that reduced financial losses by **R$ 4.8 million** and generated an **additional R$ 31.4 million** in financial value while maintaining the same credit approval rate.

### Highlights

* **AUC-ROC: 0.9738** | **KS: 0.8497** — Strong discriminative power

* **49% less default** among approved clients compared to the current policy

* **21% reduction** in Loss Rate

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

**Data Leakage Prevention:** Only information available up to the reference date is used.

---

## Model Performance

The final model (**XGBoost**) was evaluated on three datasets:

| Metric   | Train   | Validation | Test       |
| -------- | ------- | ---------- | ---------- |
| AUC-ROC  | 0.9964  | 0.9759     | **0.9738** |
| KS       | 0.9437  | 0.8471     | **0.8497** |

**Test set results:**

* AUC-ROC: **0.9738**

* KS: **0.8497**

* F1-Score: **0.6658**

* Accuracy: **95.41%**

* Precision: **64.43%**

* Recall: **68.88%**

Validation and test results are close, indicating **good generalization ability**.

---

## Risk Analysis by Score Range

To verify if the predicted probability captures different risk levels, clients were grouped by score range:

| Score Range   | Observed Default Rate |
| ------------- | --------------------:|
| 0.00 – 0.10   |                   1% |
| 0.10 – 0.20   |                  24% |
| 0.20 – 0.30   |                  34% |
| 0.30 – 0.40   |                  40% |
| 0.40 – 0.50   |                  50% |
| 0.50 – 0.60   |                  56% |
| 0.60 – 1.00   |                  79% |

Results show a **clear relationship between score and observed default**, indicating excellent **risk ranking capability**.

---

## Financial Impact

Comparison between the model and the existing credit policy (proxy), both with a **90.50% approval rate**:

| Indicator                 | Proxy        | Model          | Improvement |
| ------------------------- | -----------: | -------------: | ----------: |
| Approval rate             | 90.50%       | 90.50%         | —           |
| Default rate (approved)   | 2.70%        | **1.38%**      | **-49%**    |
| Loss Rate                 | 1.87%        | **1.48%**      | **-21%**    |
| Approved amount            | R$ 1.345 bi  | **R$ 1.367 bi** | +R$ 21.8 mi |
| Lost amount               | R$ 25.1 mi   | **R$ 20.3 mi** | **-R$ 4.8 mi** |
| Financial result          | R$ 1.320 bi  | **R$ 1.347 bi** | **+R$ 31.4 mi** |

### Estimated Gains

Keeping the same approval rate, the model delivers:

* **49% less default** among approved clients

* **21% reduction** in Loss Rate

* **R$ 4.8 million less** in losses

* **R$ 31.4 million** additional financial value generated

* **~2% increase** in value generated

The model selects a portfolio with **lower risk, lower financial loss, and higher generated value**.

---

## Key Results

✓ **AUC 0.9738 / KS 0.8497** — Strong discriminative power

✓ **Score vs. Default:** 0.0–0.1 → 1% | 0.6–1.0 → 79%

✓ **Financial impact:** +R$ 31.4 mi and -49% default

✓ **Good generalization** between validation and test

✓ **Same approval rate:** 90.50% for both proxy and model

---

## Execution Pipeline

```text
Exploration → Feature Engineering → Feature Store → Training → Evaluation → MLflow → Prediction