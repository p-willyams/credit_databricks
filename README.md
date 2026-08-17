# Credit Risk Model - Default Prediction (English Version)

> **Note:** This is the English version of the credit risk project.
> For the Portuguese version, see the `PORTUGUESE` folder.

## Project Structure

```
ENGLISH/
└── src/
    ├── 01-initial_exploration/
    │   ├── 01_data_exploration.ipynb
    │   └── 02-feature_store.ipynb
    ├── 02-feature_store/
    │   ├── fs_cadastral.sql
    │   ├── fs_funcionarios.sql
    │   ├── fs_historico_financeiro.sql
    │   ├── fs_historico_pagamentos.sql
    │   ├── fs_renda.sql
    │   ├── fs_temporal.sql
    │   └── ingestao.ipynb
    └── 03-model_inad/
        ├── fl_inad.sql
        ├── predict.ipynb
        └── train.ipynb
```

## Files Description

### 01-initial_exploration/
* **01_data_exploration.ipynb**: Initial data exploration and analysis
* **02-feature_store.ipynb**: Feature store setup and preparation

### 02-feature_store/
* **fs_cadastral.sql**: Cadastral features (region, company size, registration date)
* **fs_funcionarios.sql**: Employee-related features (headcount growth, ratios)
* **fs_historico_financeiro.sql**: Financial history features (income, payment patterns)
* **fs_historico_pagamentos.sql**: Payment history features (delays, early payments, on-time rate)
* **fs_renda.sql**: Income features (trends, stability, growth)
* **fs_temporal.sql**: Temporal features (days to due date, recency metrics)
* **ingestao.ipynb**: Feature store ingestion pipeline

### 03-model_inad/
* **fl_inad.sql**: Default flag generation (5+ days delay = default)
* **train.ipynb**: Model training pipeline (XGBoost)
* **predict.ipynb**: Prediction pipeline

## Translation Status

**SQL Files:** ✓ Completed
* All SQL files have been translated with English comments
* SQL logic remains unchanged (same table/column names)

**Notebooks:** ⚠️ Partial
* Notebook structures created
* Content translation in progress
* Code cells remain unchanged (language-agnostic)
* Markdown cells need translation

## Usage

This project must be executed on **Databricks** using:
* Databricks Tables
* Spark
* Feature Store
* MLflow

Required tables:
* `credit_score.data.cadastral`
* `credit_score.data.info`
* `credit_score.data.pagamentos`

## Execution Flow

```
Data Exploration → Feature Engineering → Feature Store → 
Training → Evaluation → MLflow → Prediction
```

For detailed information about the project, methodology, and results, 
see the main README.md in the root directory.
