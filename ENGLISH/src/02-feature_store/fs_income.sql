-- Payment history up to reference date
WITH payment_history AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Selection of unique documents by customer
fs_documentos_unicos AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        ID_DOCUMENTO AS DOCUMENT_ID
    FROM payment_history
),

-- Income base up to reference date
income_base AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        SAFRA_REF AS REF_CROP,
        CAST(RENDA_MES_ANTERIOR AS DOUBLE) AS PREV_MONTH_INCOME
    FROM credit_score.data.info
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Income milestones: current and previous periods
income_milestones AS (
    SELECT
        CLIENT_ID,
        MAX_BY(PREV_MONTH_INCOME, REF_CROP) AS CURRENT_INCOME,
        MAX_BY(
            CASE WHEN REF_CROP <= date_add(MONTH, -3, '{dt_ref}') THEN PREV_MONTH_INCOME END,
            CASE WHEN REF_CROP <= date_add(MONTH, -3, '{dt_ref}') THEN REF_CROP END
        ) AS INCOME_3M_AGO,
        MAX_BY(
            CASE WHEN REF_CROP <= date_add(MONTH, -6, '{dt_ref}') THEN PREV_MONTH_INCOME END,
            CASE WHEN REF_CROP <= date_add(MONTH, -6, '{dt_ref}') THEN REF_CROP END
        ) AS INCOME_6M_AGO,
        MAX_BY(
            CASE WHEN REF_CROP <= date_add(YEAR, -1, '{dt_ref}') THEN PREV_MONTH_INCOME END,
            CASE WHEN REF_CROP <= date_add(YEAR, -1, '{dt_ref}') THEN REF_CROP END
        ) AS INCOME_1Y_AGO
    FROM income_base
    GROUP BY CLIENT_ID
),

-- Calculation of absolute and percentual income growth
income_growth AS (
    SELECT
        CLIENT_ID,
        CURRENT_INCOME - INCOME_3M_AGO AS ABS_INCOME_GROWTH_3M,
        (CURRENT_INCOME - INCOME_3M_AGO) / (CASE WHEN INCOME_3M_AGO = 0 THEN 1 ELSE INCOME_3M_AGO END) AS PERC_INCOME_GROWTH_3M,
        CURRENT_INCOME - INCOME_6M_AGO AS ABS_INCOME_GROWTH_6M,
        (CURRENT_INCOME - INCOME_6M_AGO) / (CASE WHEN INCOME_6M_AGO = 0 THEN 1 ELSE INCOME_6M_AGO END) AS PERC_INCOME_GROWTH_6M,
        CURRENT_INCOME - INCOME_1Y_AGO AS ABS_INCOME_GROWTH_1Y,
        (CURRENT_INCOME - INCOME_1Y_AGO) / (CASE WHEN INCOME_1Y_AGO = 0 THEN 1 ELSE INCOME_1Y_AGO END) AS PERC_INCOME_GROWTH_1Y
    FROM income_milestones
),

-- Income statistics by period
income_stats AS (
    SELECT
        CLIENT_ID,
        AVG(CASE WHEN REF_CROP >= date_add(MONTH, -3, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS AVG_INCOME_3M,
        MIN(CASE WHEN REF_CROP >= date_add(MONTH, -3, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS MIN_INCOME_3M,
        MAX(CASE WHEN REF_CROP >= date_add(MONTH, -3, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS MAX_INCOME_3M,
        SUM(CASE WHEN REF_CROP >= date_add(MONTH, -3, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS SUM_INCOME_3M,
        AVG(CASE WHEN REF_CROP >= date_add(MONTH, -6, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS AVG_INCOME_6M,
        MIN(CASE WHEN REF_CROP >= date_add(MONTH, -6, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS MIN_INCOME_6M,
        MAX(CASE WHEN REF_CROP >= date_add(MONTH, -6, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS MAX_INCOME_6M,
        SUM(CASE WHEN REF_CROP >= date_add(MONTH, -6, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS SUM_INCOME_6M,
        AVG(CASE WHEN REF_CROP >= date_add(YEAR, -1, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS AVG_INCOME_1Y,
        MIN(CASE WHEN REF_CROP >= date_add(YEAR, -1, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS MIN_INCOME_1Y,
        MAX(CASE WHEN REF_CROP >= date_add(YEAR, -1, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS MAX_INCOME_1Y,
        SUM(CASE WHEN REF_CROP >= date_add(YEAR, -1, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS SUM_INCOME_1Y,
        AVG(PREV_MONTH_INCOME) AS AVG_INCOME_LIFETIME,
        MIN(PREV_MONTH_INCOME) AS MIN_INCOME_LIFETIME,
        MAX(PREV_MONTH_INCOME) AS MAX_INCOME_LIFETIME,
        STDDEV(CASE WHEN REF_CROP >= date_add(MONTH, -3, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS STDDEV_INCOME_3M,
        STDDEV(CASE WHEN REF_CROP >= date_add(MONTH, -6, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS STDDEV_INCOME_6M,
        STDDEV(CASE WHEN REF_CROP >= date_add(YEAR, -1, '{dt_ref}') THEN PREV_MONTH_INCOME END) AS STDDEV_INCOME_1Y,
        STDDEV(PREV_MONTH_INCOME) AS STDDEV_INCOME_LIFETIME
    FROM income_base
    GROUP BY CLIENT_ID
),

-- Month-over-month income drop flag
income_drop_flag AS (
    SELECT
        CLIENT_ID,
        REF_CROP,
        PREV_MONTH_INCOME,
        CASE
            WHEN PREV_MONTH_INCOME < LAG(PREV_MONTH_INCOME) OVER (
                PARTITION BY CLIENT_ID ORDER BY REF_CROP
            ) THEN 1
            ELSE 0
        END AS DROP_FLAG
    FROM income_base
),

-- Identification of consecutive income drop blocks
drop_blocks_temp AS (
    SELECT
        CLIENT_ID,
        REF_CROP,
        DROP_FLAG,
        ROW_NUMBER() OVER (PARTITION BY CLIENT_ID ORDER BY REF_CROP)
        - ROW_NUMBER() OVER (PARTITION BY CLIENT_ID, DROP_FLAG ORDER BY REF_CROP) AS BLOCK_ID
    FROM income_drop_flag
),

drop_blocks AS (
    SELECT
        CLIENT_ID,
        BLOCK_ID,
        COUNT(*) AS BLOCK_SIZE,
        MAX(REF_CROP) AS BLOCK_END
    FROM drop_blocks_temp
    WHERE DROP_FLAG = 1
    GROUP BY CLIENT_ID, BLOCK_ID
),

-- Last period for each customer
last_period AS (
    SELECT
        CLIENT_ID,
        MAX(REF_CROP) AS LAST_REF_CROP
    FROM income_base
    GROUP BY CLIENT_ID
),

-- Number of consecutive income drops up to last period
current_streak AS (
    SELECT
        l.CLIENT_ID,
        COALESCE(b.BLOCK_SIZE, 0) AS CONSECUTIVE_INCOME_DROP_MONTHS
    FROM last_period l
    LEFT JOIN drop_blocks b
        ON l.CLIENT_ID = b.CLIENT_ID
        AND l.LAST_REF_CROP = b.BLOCK_END
)

-- Final selection with all metrics
SELECT
    doc.CLIENT_ID,
    doc.DOCUMENT_ID,
    CAST('{dt_ref}' AS DATE) AS REF_DATE,
    r.SUM_INCOME_3M,
    r.AVG_INCOME_3M,
    r.MIN_INCOME_3M,
    r.MAX_INCOME_3M,
    r.STDDEV_INCOME_3M,
    r.SUM_INCOME_6M,
    r.AVG_INCOME_6M,
    r.MIN_INCOME_6M,
    r.MAX_INCOME_6M,
    r.STDDEV_INCOME_6M,
    r.SUM_INCOME_1Y,
    r.AVG_INCOME_1Y,
    r.MIN_INCOME_1Y,
    r.MAX_INCOME_1Y,
    r.STDDEV_INCOME_1Y,
    r.AVG_INCOME_LIFETIME,
    r.MIN_INCOME_LIFETIME,
    r.MAX_INCOME_LIFETIME,
    r.STDDEV_INCOME_LIFETIME,
    c.ABS_INCOME_GROWTH_3M,
    c.PERC_INCOME_GROWTH_3M,
    c.ABS_INCOME_GROWTH_6M,
    c.PERC_INCOME_GROWTH_6M,
    c.ABS_INCOME_GROWTH_1Y,
    c.PERC_INCOME_GROWTH_1Y,
    s.CONSECUTIVE_INCOME_DROP_MONTHS
FROM unique_documents doc
LEFT JOIN income_stats r
    ON doc.CLIENT_ID = r.CLIENT_ID
LEFT JOIN income_growth c
    ON doc.CLIENT_ID = c.CLIENT_ID
LEFT JOIN current_streak s
    ON doc.CLIENT_ID = s.CLIENT_ID