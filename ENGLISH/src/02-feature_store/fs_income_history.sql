-- Payment history up to reference date
WITH tb_history AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Income information by customer and period
tb_income AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        SAFRA_REF AS REF_BATCH,
        RENDA_MES_ANTERIOR AS PREV_MONTH_INCOME
    FROM credit_score.data.info
),

-- Total amount to pay by customer and period
fs_monthly AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        SAFRA_REF AS REF_BATCH,
        SUM(VALOR_A_PAGAR) AS TOTAL_AMOUNT_TO_PAY_MONTH
    FROM credit_score.data.pagamentos
    GROUP BY ID_CLIENTE, SAFRA_REF
),

-- Monthly combined data
fs_monthly_combined AS (
    SELECT
        r.CLIENT_ID,
        r.REF_BATCH,
        r.PREV_MONTH_INCOME,
        COALESCE(m.TOTAL_AMOUNT_TO_PAY_MONTH, 0) AS TOTAL_AMOUNT_TO_PAY_MONTH,
        -- Income to payment ratio
        r.PREV_MONTH_INCOME / NULLIF(m.TOTAL_AMOUNT_TO_PAY_MONTH, 0) AS INCOME_TO_PAYMENT_RATIO
    FROM tb_income r
    LEFT JOIN fs_monthly m ON r.CLIENT_ID = m.CLIENT_ID AND r.REF_BATCH = m.REF_BATCH
    WHERE r.REF_BATCH < '{dt_ref}'
),

-- Historical metrics by customer
fs_financial_history AS (
    SELECT
        CLIENT_ID,
        AVG(PREV_MONTH_INCOME) AS AVG_HISTORICAL_INCOME,
        AVG(TOTAL_AMOUNT_TO_PAY_MONTH) AS AVG_HISTORICAL_PAYMENT,
        AVG(INCOME_TO_PAYMENT_RATIO) AS AVG_INCOME_PAYMENT_RATIO,
        MAX(INCOME_TO_PAYMENT_RATIO) AS MAX_INCOME_PAYMENT_RATIO,
        MIN(INCOME_TO_PAYMENT_RATIO) AS MIN_INCOME_PAYMENT_RATIO,
        COUNT(*) AS NUM_MONTHS_HISTORY
    FROM fs_monthly_combined
    GROUP BY CLIENT_ID
)

-- Final result: metrics by document and customer
SELECT
    h.ID_DOCUMENTO AS DOCUMENT_ID,
    h.ID_CLIENTE AS CLIENT_ID,
    CAST('{dt_ref}' AS DATE) AS REF_DATE,
    f.AVG_HISTORICAL_INCOME,
    f.AVG_HISTORICAL_PAYMENT,
    f.AVG_INCOME_PAYMENT_RATIO,
    f.MAX_INCOME_PAYMENT_RATIO,
    f.MIN_INCOME_PAYMENT_RATIO,
    f.NUM_MONTHS_HISTORY
FROM tb_history h
LEFT JOIN fs_financial_history f ON h.ID_CLIENTE = f.CLIENT_ID;
