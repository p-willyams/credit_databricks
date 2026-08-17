# Databricks notebook source
# MAGIC %md
# MAGIC # The Feature Store Approach

# COMMAND ----------

# MAGIC %md
# MAGIC To organize the variables used in the model, a **Feature Store** approach was adopted. The goal is to separate **feature engineering** from the modeling stage, allowing the same variables to be used consistently for both training and prediction.
# MAGIC
# MAGIC Feature engineering:
# MAGIC
# MAGIC The creation of variables is performed using **SQL queries**, stored in separate *.sql* files. This organization keeps the logic of each feature group isolated and makes maintenance and reuse easier.
# MAGIC
# MAGIC The structure follows, for example:
# MAGIC
# MAGIC text
# MAGIC feature_store/
# MAGIC ├── fs_cadastral.sql
# MAGIC ├── fs_temporal.sql
# MAGIC ├── fs_historico_financeiro.sql
# MAGIC ├── fs_renda.sql
# MAGIC ├── fs_funcionarios.sql
# MAGIC └── fs_historico_pagamentos.sql
# MAGIC
# MAGIC
# MAGIC The queries are parameterized by the reference period. This way, the same query can be executed for different months, generating features corresponding to each DATA_REF.
# MAGIC
# MAGIC Feature Store ingestion:
# MAGIC
# MAGIC The execution of the queries is centralized in an **ingestion notebook**. This notebook reads each *.sql* file, runs the query for the defined periods, and writes the results to the respective Feature Store tables.
# MAGIC
# MAGIC The flow can be represented as follows:
# MAGIC
# MAGIC text
# MAGIC Raw data
# MAGIC      ↓
# MAGIC SQL queries
# MAGIC      ↓
# MAGIC Feature engineering
# MAGIC      ↓
# MAGIC Ingestion notebook
# MAGIC      ↓
# MAGIC Feature Store
# MAGIC      ↓
# MAGIC Training Set / Prediction
# MAGIC
# MAGIC
# MAGIC On the first run, if the table does not exist yet, it is created with:
# MAGIC
# MAGIC * *ID_CLIENTE*
# MAGIC * *ID_DOCUMENTO*
# MAGIC * *DATA_REF*
# MAGIC
# MAGIC as feature keys;
# MAGIC
# MAGIC * *DATA_REF* as the partitioning column.
# MAGIC
# MAGIC On subsequent runs, new periods are added using **merge**, allowing the Feature Store to be updated without recreating the entire table.
# MAGIC
# MAGIC Usage in training:
# MAGIC
# MAGIC During training, the different feature tables are retrieved via the *FeatureEngineeringClient* and joined to the main dataset using the defined keys.
# MAGIC
# MAGIC This enables the construction of a **unique training set**, combining the necessary cadastral, temporal, and historical information for the model.
# MAGIC
# MAGIC An important advantage of this approach is ensuring that feature engineering is **reproducible and organized**, as well as facilitating the use of the same features later in the prediction process.
# MAGIC
# MAGIC > **Important:** Since this is a temporal problem, historical features must be constructed using only information available up to the respective *DATA_REF*. This prevents future information from being used during training and reduces the risk of *data leakage*.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC The features were divided into different groups according to their origin and purpose:
# MAGIC
# MAGIC * **Cadastral**: cadastral characteristics of the clients;
# MAGIC * **Temporal**: information related to the reference period;
# MAGIC * **Financial history**: characteristics related to financial behavior;
# MAGIC * **Income**: information and variations related to income;
# MAGIC * **Employees**: history and behavior of the number of employees;
# MAGIC * **Payment history**: metrics related to payment behavior.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC # Features Ideas

# COMMAND ----------

# MAGIC %md
# MAGIC ## Feature Store Cadastral

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC **Key:** ID_CLIENTE
# MAGIC
# MAGIC Features related to client registration characteristics and the client's relationship with the company.
# MAGIC
# MAGIC **Features**
# MAGIC
# MAGIC * **Client region:** geographic region obtained from registration information.
# MAGIC * **Relationship duration:** time elapsed between the client's registration date and the reference date.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC ## Feature Store Income

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC **Key:** ID_CLIENTE, SAFRA_REF
# MAGIC
# MAGIC Features designed to represent the **level, behavior, trend, and stability of the client's income over time**.
# MAGIC
# MAGIC **Income Aggregations**
# MAGIC
# MAGIC Statistics are calculated for income considering different time windows.
# MAGIC
# MAGIC 3 months
# MAGIC
# MAGIC * Average income.
# MAGIC * Sum of income.
# MAGIC * Lowest income.
# MAGIC * Highest income.
# MAGIC
# MAGIC 6 months
# MAGIC
# MAGIC * Average income.
# MAGIC * Sum of income.
# MAGIC * Lowest income.
# MAGIC * Highest income.
# MAGIC
# MAGIC 12 months
# MAGIC
# MAGIC * Average income.
# MAGIC * Sum of income.
# MAGIC * Lowest income.
# MAGIC * Highest income.
# MAGIC
# MAGIC Lifetime
# MAGIC
# MAGIC * Historical average income.
# MAGIC * Historical sum of income.
# MAGIC * Historical lowest income.
# MAGIC * Historical highest income.
# MAGIC
# MAGIC **Trends**
# MAGIC
# MAGIC Aimed at identifying how the client's income is evolving over time, comparing previous periods with more recent periods.
# MAGIC
# MAGIC * Income growth over 3 months.
# MAGIC * Income growth over 6 months.
# MAGIC * Income growth over 12 months.
# MAGIC * Income reduction over 3 months.
# MAGIC * Income reduction over 6 months.
# MAGIC * Income reduction over 12 months.
# MAGIC
# MAGIC These measures are calculated **temporally**, using only periods prior to SAFRA_REF.
# MAGIC
# MAGIC **Variability**
# MAGIC
# MAGIC Aimed at measuring the **stability of the client's income**.
# MAGIC
# MAGIC * Standard deviation of income over 3 months.
# MAGIC * Standard deviation of income over 6 months.
# MAGIC * Standard deviation of income over 12 months.
# MAGIC * Coefficient of variation of income.
# MAGIC
# MAGIC **History**
# MAGIC
# MAGIC Aimed at identifying prolonged periods of income reduction, representing possible changes in the client's financial behavior.
# MAGIC
# MAGIC * **Consecutive months of decline:** number of consecutive months in which income decreased compared to the previous period.
# MAGIC
# MAGIC > The windows and metrics presented represent initial hypotheses. During development, they may be adjusted, removed, or complemented according to data availability and analysis results.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC ## Feature Store Employees

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC **Key:** ID_CLIENTE, SAFRA_REF
# MAGIC
# MAGIC The Employee Feature Store aims to represent the **size, evolution, and stability of the client's workforce** over time. This information can help the model identify changes in the company's structure that may be related to default risk.
# MAGIC
# MAGIC **Features**
# MAGIC
# MAGIC Current workforce
# MAGIC
# MAGIC * Current number of employees.
# MAGIC
# MAGIC Workforce growth
# MAGIC
# MAGIC Calculates the evolution of the number of employees in different time windows:
# MAGIC
# MAGIC * Workforce growth over the last 3 months.
# MAGIC * Workforce growth over the last 6 months.
# MAGIC * Workforce growth over the last 12 months.
# MAGIC * Workforce growth over the entire available history.
# MAGIC
# MAGIC Workforce reduction
# MAGIC
# MAGIC Identifies reductions in the number of employees:
# MAGIC
# MAGIC * Workforce reduction over the last 3 months.
# MAGIC * Workforce reduction over the last 6 months.
# MAGIC * Workforce reduction over the last 12 months.
# MAGIC * Workforce reduction over the entire available history.
# MAGIC
# MAGIC Historical statistics
# MAGIC
# MAGIC Seeks to identify relevant variations in the workforce:
# MAGIC
# MAGIC * Largest monthly growth observed.
# MAGIC * Largest monthly drop observed.
# MAGIC
# MAGIC Comparison with company size
# MAGIC
# MAGIC Compares the client's current number of employees with the expected behavior for companies of the same size:
# MAGIC
# MAGIC * Difference between the current number of employees and the average number of employees for the respective company size.
# MAGIC
# MAGIC Efficiency
# MAGIC
# MAGIC Relates the workforce size to the company's income:
# MAGIC
# MAGIC * **Income per employee:** monthly income divided by the number of employees.
# MAGIC
# MAGIC > **Note:** these are the initially proposed features. During exploration and modeling, new variables may be created, some may be modified, and others may be discarded if they show little relevance, availability issues, or risk of *data leakage*.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC ## Feature Store Payment History

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC **Key:** ID_CLIENTE, SAFRA_REF
# MAGIC
# MAGIC The Payment History Feature Store aims to represent the **financial behavior and punctuality of the client over time**. The variables are constructed from the history of charges and payments, using different time windows.
# MAGIC
# MAGIC **Features**
# MAGIC
# MAGIC Delays
# MAGIC
# MAGIC Identifies the frequency and intensity of client delays:
# MAGIC
# MAGIC * Delay flag in the last 3 months.
# MAGIC * Delay flag in the last 6 months.
# MAGIC * Delay flag in the last 12 months.
# MAGIC * Delay flag throughout the entire history.
# MAGIC * Number of delays in the last 3 months.
# MAGIC * Number of delays in the last 6 months.
# MAGIC * Number of delays in the last 12 months.
# MAGIC * Number of delays throughout the entire history.
# MAGIC * Days since the last delay.
# MAGIC * Average days of delay.
# MAGIC * Maximum days of delay.
# MAGIC
# MAGIC Payments
# MAGIC
# MAGIC Characterizes the client's payment behavior:
# MAGIC
# MAGIC * Days since the last payment.
# MAGIC * Number of early payments.
# MAGIC * Average days of anticipation.
# MAGIC * Number of payments made on due date.
# MAGIC
# MAGIC Invoices
# MAGIC
# MAGIC Represents the volume and values of charges:
# MAGIC
# MAGIC * Number of invoices.
# MAGIC * Average invoice value.
# MAGIC * Highest invoice value.
# MAGIC * Total amount paid in the last 3 months.
# MAGIC * Total amount paid in the last 6 months.
# MAGIC * Total amount paid in the last 12 months.
# MAGIC
# MAGIC Punctuality
# MAGIC
# MAGIC Measures the client's behavior regarding payment deadlines:
# MAGIC
# MAGIC * Percentage of payments made on time.
# MAGIC
# MAGIC Dates
# MAGIC
# MAGIC Characterizes intervals related to the billing and payment cycle:
# MAGIC
# MAGIC * Average term between issuance and due date.
# MAGIC * Minimum term between issuance and due date.
# MAGIC * Maximum term between issuance and due date.
# MAGIC * Days remaining until due date.
# MAGIC * Average days between issuance and payment.
# MAGIC
# MAGIC Billing
# MAGIC
# MAGIC Relates the charge amount to the available payment term:
# MAGIC
# MAGIC * Charge value per day.
# MAGIC
# MAGIC > **Note:** these are the initially proposed features. The final definition may change during exploration and modeling, including the creation of new variables, removal of less relevant variables, and adjustments to time windows. Features must also respect the availability of information at the time of prediction, avoiding *data leakage*.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC ## Feature Store Temporal

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC **Key:** ID_CLIENTE, SAFRA_REF
# MAGIC
# MAGIC The Temporal Feature Store aims to represent the **client's relationship with time**, using information available at the moment of prediction. These variables help the model capture aspects related to relationship duration and billing cycles.
# MAGIC
# MAGIC Features
# MAGIC
# MAGIC Relationship
# MAGIC
# MAGIC * Days since client registration.
# MAGIC
# MAGIC Billing
# MAGIC
# MAGIC * Days until due date.
# MAGIC * Time between issuance and due date.
# MAGIC
# MAGIC Payment history
# MAGIC
# MAGIC * Days since last payment.
# MAGIC * Days since last delay.
# MAGIC
# MAGIC > **Note:** these are the initially proposed features. The final definition may change during exploration and modeling, depending on information availability, predictive relevance, and the need to avoid *data leakage*.
# MAGIC