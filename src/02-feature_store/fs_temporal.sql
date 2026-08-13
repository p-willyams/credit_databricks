-- Histórico de pagamentos até a data de referência
WITH tb_historico AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Cálculo de métricas temporais para cada cliente e documento
fs_temporal AS (
    SELECT
        ID_CLIENTE,
        ID_DOCUMENTO,
        SAFRA_REF,
        -- Dias até o vencimento do documento em relação à data de referência
        DATEDIFF(DATA_VENCIMENTO, '{dt_ref}') AS DIAS_VENCIMENTO,
        -- Dias desde o último pagamento realizado antes da data de referência
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
        ) AS DIAS_ULT_PAG,
        -- Prazo até o vencimento do documento em relação à data de referência
        DATEDIFF(DATA_VENCIMENTO,'{dt_ref}') AS PRAZO_VENC,
        -- Dias desde a última emissão de documento antes da data de referência
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
        ) AS DIAS_ULT_EMISSAO
    FROM tb_historico
)

-- Seleção final das métricas temporais
SELECT
    ID_CLIENTE,
    ID_DOCUMENTO,
    CAST('{dt_ref}' AS DATE) AS DATA_REF,
    DIAS_VENCIMENTO,
    DIAS_ULT_PAG,
    PRAZO_VENC,
    DIAS_ULT_EMISSAO
FROM fs_temporal