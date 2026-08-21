-- Historical documents by customer, filtering by reference
WITH tb_history AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        ID_DOCUMENTO AS DOCUMENT_ID
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Employees and income by customer, filtering by reference
tb_employees AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        SAFRA_REF AS REF_BATCH,
        NO_FUNCIONARIOS AS NUM_EMPLOYEES,
        RENDA_MES_ANTERIOR AS PREV_MONTH_INCOME
    FROM credit_score.data.info
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Company size by customer
tb_size AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        PORTE AS COMPANY_SIZE
    FROM credit_score.data.cadastral
),

-- Historical employee milestones and history availability flags
fs_employee_milestones AS (
    SELECT
        CLIENT_ID,
        MAX_BY(NUM_EMPLOYEES, REF_BATCH) AS CURRENT_NUM_EMPLOYEES,
        MAX_BY(
            CASE WHEN REF_BATCH <= date_add(MONTH,-3,'{dt_ref}') THEN NUM_EMPLOYEES END,
            CASE WHEN REF_BATCH <= date_add(MONTH,-3,'{dt_ref}') THEN REF_BATCH END
        ) AS NUM_EMPLOYEES_3M,
        MAX_BY(
            CASE WHEN REF_BATCH <= date_add(MONTH,-6,'{dt_ref}') THEN NUM_EMPLOYEES END,
            CASE WHEN REF_BATCH <= date_add(MONTH,-6,'{dt_ref}') THEN REF_BATCH END
        ) AS NUM_EMPLOYEES_6M,
        MAX_BY(
            CASE WHEN REF_BATCH <= date_add(YEAR,-1,'{dt_ref}') THEN NUM_EMPLOYEES END,
            CASE WHEN REF_BATCH <= date_add(YEAR,-1,'{dt_ref}') THEN REF_BATCH END
        ) AS NUM_EMPLOYEES_12M,
        MIN_BY(NUM_EMPLOYEES, REF_BATCH) AS NUM_EMPLOYEES_LIFETIME,
        MAX_BY(PREV_MONTH_INCOME, REF_BATCH) AS CURRENT_INCOME,
        -- History availability flags
        MAX(CASE WHEN REF_BATCH <= date_add(MONTH,-3,'{dt_ref}') THEN 1 ELSE 0 END) AS HISTORY_FLAG_3M,
        MAX(CASE WHEN REF_BATCH <= date_add(MONTH,-6,'{dt_ref}') THEN 1 ELSE 0 END) AS HISTORY_FLAG_6M,
        MAX(CASE WHEN REF_BATCH <= date_add(YEAR,-1,'{dt_ref}')  THEN 1 ELSE 0 END) AS HISTORY_FLAG_12M,
        COUNT(*) AS NUM_HISTORY_BATCHES
    FROM tb_employees
    GROUP BY CLIENT_ID
),

-- Average employees by company size
tb_average_by_size AS (
    SELECT
        p.COMPANY_SIZE,
        AVG(m.CURRENT_NUM_EMPLOYEES) AS AVG_EMPLOYEES_BY_SIZE
    FROM fs_employee_milestones m
    JOIN tb_size p ON m.CLIENT_ID = p.CLIENT_ID
    GROUP BY p.COMPANY_SIZE
),

-- Overall average employees (fallback)
tb_overall_average AS (
    SELECT AVG(CURRENT_NUM_EMPLOYEES) AS OVERALL_AVG_EMPLOYEES
    FROM fs_employee_milestones
),

-- Employee growth calculation
fs_employee_growth AS (
    SELECT
        *,
        -- Growth in different periods, considering history flags
        (CURRENT_NUM_EMPLOYEES - NUM_EMPLOYEES_3M) / NULLIF(NUM_EMPLOYEES_3M, 0) AS EMPLOYEE_GROWTH_3M,
        (CURRENT_NUM_EMPLOYEES - NUM_EMPLOYEES_6M) / NULLIF(NUM_EMPLOYEES_6M, 0) AS EMPLOYEE_GROWTH_6M,
        (CURRENT_NUM_EMPLOYEES - NUM_EMPLOYEES_12M) / NULLIF(NUM_EMPLOYEES_12M, 0) AS EMPLOYEE_GROWTH_12M,
        (CURRENT_NUM_EMPLOYEES - NUM_EMPLOYEES_LIFETIME) / NULLIF(NUM_EMPLOYEES_LIFETIME, 0) AS EMPLOYEE_GROWTH_LIFETIME
    FROM fs_employee_milestones
),

-- Monthly employee variations
fs_variations AS (
    SELECT
        CLIENT_ID,
        -- COALESCE to 0: with only 1 period there's no month-to-month variation to measure
        COALESCE(MAX(VARIATION), 0) AS MAX_MONTHLY_GROWTH,
        COALESCE(MIN(VARIATION), 0) AS MAX_MONTHLY_DROP,
        MAX(CASE WHEN VARIATION IS NOT NULL THEN 1 ELSE 0 END) AS HISTORY_FLAG_VARIATION
    FROM (
        SELECT
            CLIENT_ID,
            (
                NUM_EMPLOYEES
                - LAG(NUM_EMPLOYEES) OVER (PARTITION BY CLIENT_ID ORDER BY REF_BATCH)
            ) /
            NULLIF(
                LAG(NUM_EMPLOYEES) OVER (PARTITION BY CLIENT_ID ORDER BY REF_BATCH),
                0
            ) AS VARIATION
        FROM tb_employees
    ) x
    GROUP BY CLIENT_ID
),

-- Consolidated metrics by customer
fs_employees AS (
    SELECT
        c.CLIENT_ID,
        c.CURRENT_NUM_EMPLOYEES,
        c.NUM_EMPLOYEES_3M,
        c.NUM_EMPLOYEES_6M,
        c.NUM_EMPLOYEES_12M,
        c.NUM_EMPLOYEES_LIFETIME,
        c.HISTORY_FLAG_3M,
        c.HISTORY_FLAG_6M,
        c.HISTORY_FLAG_12M,
        c.NUM_HISTORY_BATCHES,
        c.EMPLOYEE_GROWTH_3M,
        c.EMPLOYEE_GROWTH_6M,
        c.EMPLOYEE_GROWTH_12M,
        c.EMPLOYEE_GROWTH_LIFETIME,
        v.MAX_MONTHLY_GROWTH,
        v.MAX_MONTHLY_DROP,
        v.HISTORY_FLAG_VARIATION,
        c.CURRENT_INCOME / NULLIF(c.CURRENT_NUM_EMPLOYEES, 0) AS INCOME_PER_EMPLOYEE_RATIO,
        -- Fallback: if customer has no registered SIZE (mp NULL), use overall average
        c.CURRENT_NUM_EMPLOYEES - COALESCE(mp.AVG_EMPLOYEES_BY_SIZE, mg.OVERALL_AVG_EMPLOYEES) AS DIFF_FROM_SIZE_AVG,
        CASE WHEN mp.AVG_EMPLOYEES_BY_SIZE IS NULL THEN 1 ELSE 0 END AS FLAG_SIZE_MISSING
    FROM fs_employee_growth c
    LEFT JOIN tb_size tp ON c.CLIENT_ID = tp.CLIENT_ID
    LEFT JOIN tb_average_by_size mp ON tp.COMPANY_SIZE = mp.COMPANY_SIZE
    LEFT JOIN fs_variations v ON c.CLIENT_ID = v.CLIENT_ID
    CROSS JOIN tb_overall_average mg
)

-- Final result: metrics by document and customer
SELECT
    h.DOCUMENT_ID,
    h.CLIENT_ID,
    CAST('{dt_ref}' AS DATE) AS REF_DATE,
    f.CURRENT_NUM_EMPLOYEES,
    f.NUM_EMPLOYEES_3M,
    f.NUM_EMPLOYEES_6M,
    f.NUM_EMPLOYEES_12M,
    f.NUM_EMPLOYEES_LIFETIME,
    f.HISTORY_FLAG_3M,
    f.HISTORY_FLAG_6M,
    f.HISTORY_FLAG_12M,
    f.NUM_HISTORY_BATCHES,
    f.EMPLOYEE_GROWTH_3M,
    f.EMPLOYEE_GROWTH_6M,
    f.EMPLOYEE_GROWTH_12M,
    f.EMPLOYEE_GROWTH_LIFETIME,
    f.MAX_MONTHLY_GROWTH,
    f.MAX_MONTHLY_DROP,
    f.HISTORY_FLAG_VARIATION,
    f.INCOME_PER_EMPLOYEE_RATIO,
    f.DIFF_FROM_SIZE_AVG,
    f.FLAG_SIZE_MISSING
FROM tb_history h
LEFT JOIN fs_employees f ON h.CLIENT_ID = f.CLIENT_ID;