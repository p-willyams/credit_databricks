-- Payment history up to reference date
WITH tb_history AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Income information by customer and period
tb_income AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        RENDA_MES_ANTERIOR
    FROM credit_score.data.info
),

-- Total amount to pay by customer and period
fs_monthly AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        SUM(VALOR_A_PAGAR) AS VALOR_A_PAGAR_TOTAL_MES
    FROM credit_score.data.pagamentos
    GROUP BY ID_CLIENTE, SAFRA_REF
),

-- Monthly combined data
fs_mensal_combinado AS (
    SELECT
        r.ID_CLIENTE,
        r.SAFRA_REF,
        r.RENDA_MES_ANTERIOR,
        COALESCE(m.VALOR_A_PAGAR_TOTAL_MES, 0) AS VALOR_A_PAGAR_TOTAL_MES,
        -- Income to payment ratio
        r.RENDA_MES_ANTERIOR / NULLIF(m.VALOR_A_PAGAR_TOTAL_MES, 0) AS RAZAO_RENDA_SOBRE_PAGAMENTO
    FROM tb_income r
    LEFT JOIN fs_monthly m ON r.ID_CLIENTE = m.ID_CLIENTE AND r.SAFRA_REF = m.SAFRA_REF
    WHERE r.SAFRA_REF < '{dt_ref}'
),

-- Historical metrics by customer
fs_historico_financeiro AS (
    SELECT
        ID_CLIENTE,
        AVG(RENDA_MES_ANTERIOR) AS RENDA_MEDIA_HISTORICO,
        AVG(VALOR_A_PAGAR_TOTAL_MES) AS PAGAMENTO_MEDIO_HISTORICO,
        AVG(RAZAO_RENDA_SOBRE_PAGAMENTO) AS RAZAO_MEDIA_RENDA_PAGAMENTO,
        MAX(RAZAO_RENDA_SOBRE_PAGAMENTO) AS RAZAO_MAX_RENDA_PAGAMENTO,
        MIN(RAZAO_RENDA_SOBRE_PAGAMENTO) AS RAZAO_MIN_RENDA_PAGAMENTO,
        COUNT(*) AS QT_MESES_HISTORICO
    FROM fs_mensal_combinado
    GROUP BY ID_CLIENTE
)

-- Final result: metrics by document and customer
SELECT
    h.ID_DOCUMENTO,
    h.ID_CLIENTE,
    CAST('{dt_ref}' AS DATE) AS DATA_REF,
    f.RENDA_MEDIA_HISTORICO,
    f.PAGAMENTO_MEDIO_HISTORICO,
    f.RAZAO_MEDIA_RENDA_PAGAMENTO,
    f.RAZAO_MAX_RENDA_PAGAMENTO,
    f.RAZAO_MIN_RENDA_PAGAMENTO,
    f.QT_MESES_HISTORICO
FROM tb_history h
LEFT JOIN fs_historico_financeiro f ON h.ID_CLIENTE = f.ID_CLIENTE;
