-- Payment history up to reference date
WITH payment_history AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Temporal metrics calculation for each client and document
fs_temporal AS (
    SELECT
        ID_CLIENTE AS CLIENT_ID,
        ID_DOCUMENTO AS DOCUMENT_ID,
        SAFRA_REF AS REF_BATCH,
        -- Days until document due date in relation to the reference date
        DATEDIFF(DATA_VENCIMENTO, '{dt_ref}') AS DAYS_UNTIL_DUE,
        -- Days since last payment made before the reference date
        DATEDIFF(
            '{dt_ref}',
            LAST_VALUE(
                CASE
                    WHEN DATA_PAGAMENTO < '{dt_ref}'
                    THEN DATA_PAGAMENTO
                END
            ) IGNORE NULLS OVER (
                PARTITION BY ID_CLIENTE
                ORDER BY SAFRA_REF
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            )
        ) AS DAYS_SINCE_LAST_PAYMENT,
        -- Term until document due date in relation to the reference date
        DATEDIFF(DATA_VENCIMENTO, '{dt_ref}') AS TERM_UNTIL_DUE,
        -- Days since the last document issued before the reference date
        DATEDIFF(
            '{dt_ref}',
            MAX(
                CASE
                    WHEN DATA_EMISSAO_DOCUMENTO < '{dt_ref}'
                    THEN DATA_EMISSAO_DOCUMENTO
                END
            ) OVER (
                PARTITION BY ID_CLIENTE
            )
        ) AS DAYS_SINCE_LAST_ISSUE
    FROM payment_history
)

-- Final selection of temporal metrics
SELECT
    CLIENT_ID,
    DOCUMENT_ID,
    CAST('{dt_ref}' AS DATE) AS REF_DATE,
    DAYS_UNTIL_DUE,
    DAYS_SINCE_LAST_PAYMENT,
    TERM_UNTIL_DUE,
    DAYS_SINCE_LAST_ISSUE
FROM fs_temporal