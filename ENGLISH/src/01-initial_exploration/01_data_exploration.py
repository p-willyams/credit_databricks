# Databricks notebook source
# /// script
# [tool.databricks.environment]
# environment_version = "5"
# ///
# MAGIC %md
# MAGIC # Project Objective

# COMMAND ----------

# MAGIC %md
# MAGIC The objective of this project is to develop a **predictive model capable of estimating the probability of default on monthly charges made to customers**.
# MAGIC
# MAGIC Default is defined as a payment made **5 days or more after the due date**.
# MAGIC
# MAGIC The model should generate a probability of default for each record in the payment database, which represents the most recent charges from the "company".
# MAGIC
# MAGIC For model development, different sources of information about customers are available:
# MAGIC
# MAGIC * **Payment history**, containing information about payment behavior;
# MAGIC * **Registration and profile data** of customers;
# MAGIC * **Monthly information**, such as income and number of employees;
# MAGIC * Other historical information that may help identify patterns associated with default.
# MAGIC
# MAGIC The solution should consider aspects such as:
# MAGIC
# MAGIC * data treatment and quality;
# MAGIC * variable creation and selection;
# MAGIC * proper separation between training, validation, and testing;
# MAGIC * model performance evaluation;
# MAGIC * interpretation of results;
# MAGIC * comparison with an existing decision rule (*proxy*).
# MAGIC
# MAGIC The final output should contain **only the probability of default for each charge**, with values between `0` and `1`.
# MAGIC
# MAGIC It is not necessary to transform these probabilities into a binary classification of defaulter or non-defaulter.
# MAGIC
# MAGIC > **Note:** the definition of default used in this project — **5 days or more of delay** — is adopted as the rule for target construction and model evaluation.
# MAGIC

# COMMAND ----------

# MAGIC %md
# MAGIC # DataBase

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC The project provides **three databases** containing registration, behavioral, and financial information about customers. The datasets were extracted from a billing system and represent a realistic operational scenario.
# MAGIC
# MAGIC The tables are mainly related through:
# MAGIC
# MAGIC * **ID_CLIENTE**: uniquely identifies each customer;
# MAGIC * **SAFRA_REF**: represents the reference period of the charge.
# MAGIC
# MAGIC Available datasets
# MAGIC
# MAGIC  Base                                  | Description                                                                       | Granularity        |
# MAGIC  ------------------------------------- | --------------------------------------------------------------------------------- | ------------------ |
# MAGIC  cadastral                  | Registration information, such as registration date, company size, ZIP code, and email domain. | Customer           |
# MAGIC  info                      | Monthly information, such as income and number of employees.                             | Customer × month   |
# MAGIC  pagamentos          | Most recent charges, used to generate model training and predictions.                           | Customer × charge  |
# MAGIC
# MAGIC ### Role of each dataset
# MAGIC
# MAGIC The **cadastral** dataset contains more static information about customers, while the **info** dataset allows tracking characteristics that may vary over time.
# MAGIC
# MAGIC The **pagamentos** dataset is used for model development. As it contains due and payment dates, it is possible to identify which charges were in default according to the rule
# MAGIC

# COMMAND ----------

cadastral_df = spark.table("credit_score.data.cadastral")
display(cadastral_df.limit(10))

# COMMAND ----------

num_rows = cadastral_df.count()
num_cols = len(cadastral_df.columns)
display(spark.createDataFrame([(num_rows, num_cols)], ["num_rows", "num_columns"]))

# COMMAND ----------

display(cadastral_df.dtypes)

# COMMAND ----------

display(cadastral_df.select("DDD").distinct())

# COMMAND ----------

display(cadastral_df.select("CEP_2_DIG").distinct())

# COMMAND ----------

from pyspark.sql.functions import col, count, when

total_count = cadastral_df.count()
missing_pct_df = (
    cadastral_df.select([
        (count(when(col(c).isNull(), c)) / total_count * 100).alias(c)
        for c in cadastral_df.columns
    ])
)
display(missing_pct_df)

# COMMAND ----------

# MAGIC %md
# MAGIC # Info

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC The **info** dataset contains monthly information related to customers, allowing tracking of characteristics that may vary over time. Each record represents a customer in a specific reference period (SAFRA_REF).
# MAGIC
# MAGIC The dataset has **24,401 records and 4 variables**.
# MAGIC
# MAGIC Data Dictionary
# MAGIC
# MAGIC  Variable             | Description                                              | Type     | Notes                                     |
# MAGIC  -------------------- | -------------------------------------------------------- | -------- | ------------------------------------------ |
# MAGIC  ID_CLIENTE           | Unique customer identifier                               | Integer  | Key for linking between datasets           |
# MAGIC  SAFRA_REF            | Reference period of the information                      | Date     | Represents the reference month             |
# MAGIC  RENDA_MES_ANTERIOR   | Income recorded in the month prior to the reference      | Numeric  | ~2.94% null values                        |
# MAGIC  NO_FUNCIONARIOS      | Number of employees of the customer                      | Numeric  | ~5.13% null values                        |
# MAGIC
# MAGIC Observed Points
# MAGIC
# MAGIC * The dataset has a **temporal structure**, allowing analysis of the evolution of customer characteristics over the months.
# MAGIC * RENDA_MES_ANTERIOR has approximately **2.94% missing values**.
# MAGIC * NO_FUNCIONARIOS has approximately **5.13% missing values**.
# MAGIC * ID_CLIENTE and SAFRA_REF do not have missing values and will be important for temporal relationships with other datasets.
# MAGIC * As this information varies over time, it is important to ensure that, when constructing variables, only information **available up to the reference period** is used, avoiding information leakage (*data leakage*).
# MAGIC

# COMMAND ----------

info_df = spark.table("credit_score.data.info")
display(info_df.limit(10))


# COMMAND ----------

num_rows = info_df.count()
num_cols = len(info_df.columns)
display(spark.createDataFrame([(num_rows, num_cols)], ["num_rows", "num_cols"]))

# COMMAND ----------

display(info_df.dtypes)

# COMMAND ----------

from pyspark.sql.functions import col, count, when

total_count = info_df.count()
missing_pct_df = (
    info_df.select([
        (count(when(col(c).isNull(), c)) / total_count * 100).alias(c)
        for c in info_df.columns
    ])
)
display(missing_pct_df)

# COMMAND ----------

# MAGIC %md
# MAGIC # Payments

# COMMAND ----------

# MAGIC %md
# MAGIC
# MAGIC The **payments** dataset contains the history of charges and payments made by customers. Each record represents a charge associated with a customer and a reference period.
# MAGIC
# MAGIC This is one of the main datasets for the project, as it contains the **due and payment dates**, allowing the identification of delinquency according to the defined rule.
# MAGIC
# MAGIC The dataset has **77,414 records and 8 variables**.
# MAGIC
# MAGIC Data Dictionary
# MAGIC
# MAGIC  Variable                 | Description                                 | Type     | Notes                               |
# MAGIC  ------------------------ | ------------------------------------------- | -------- | ------------------------------------ |
# MAGIC  ID_CLIENTE               | Customer identifier                         | Integer  | Key for linking                     |
# MAGIC  SAFRA_REF                | Reference period of the charge              | Date     | Allows temporal relationships        |
# MAGIC  DATA_EMISSAO_DOCUMENTO   | Charge issue date                           | Date     | No missing values                    |
# MAGIC  DATA_PAGAMENTO           | Payment date                                | Date     | No missing values                    |
# MAGIC  DATA_VENCIMENTO          | Charge due date                             | Date     | No missing values                    |
# MAGIC  VALOR_A_PAGAR            | Charge amount                               | Numeric  | ~1.51% missing values                |
# MAGIC  TAXA                     | Charge-associated fee                       | Numeric  | No missing values                    |
# MAGIC  ID_DOCUMENTO             | Unique document/charge identifier           | Integer  | Key for the document                 |
# MAGIC
# MAGIC
# MAGIC Observed Points
# MAGIC
# MAGIC * The dataset contains the necessary information for **constructing the target variable**, by comparing DATA_PAGAMENTO and DATA_VENCIMENTO.
# MAGIC * The rule used in the project considers a charge **delinquent when payment occurs 5 days or more after the due date**.
# MAGIC * VALOR_A_PAGAR has approximately **1.51% missing values**, which need to be handled during development.
# MAGIC * ID_DOCUMENTO allows individual identification of each charge and is also used for linking with other project information.
# MAGIC * The available dates allow the construction of variables related to **payment behavior and history of delays**.
# MAGIC

# COMMAND ----------

pagamentos_df = spark.table("credit_score.data.pagamentos")
display(pagamentos_df.limit(10))


# COMMAND ----------

num_rows = pagamentos_df.count()
num_cols = len(pagamentos_df.columns)
display(spark.createDataFrame([(num_rows, num_cols)], ["num_rows", "num_cols"]))

# COMMAND ----------

display(pagamentos_df.dtypes)

# COMMAND ----------

from pyspark.sql.functions import col, count, when

total_count = pagamentos_df.count()
missing_pct_df = (
    pagamentos_df.select([
        (count(when(col(c).isNull(), c)) / total_count * 100).alias(c)
        for c in pagamentos_df.columns
    ])
)
display(missing_pct_df)