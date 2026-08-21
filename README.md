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

**Data Leakage Prevention:** Only information available up to the reference date is used.

---

## Model Performance

Confusion matrix for threshold 0.28 on the test set:

[[26780   694]
 [  558  1423]]


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

text
Exploration → Feature Engineering → Feature Store → Training → Evaluation → MLflow → Prediction