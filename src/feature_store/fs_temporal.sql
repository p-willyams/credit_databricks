WITH tb_historico AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

fs_temporal AS (
    SELECT
        ID_CLIENTE,
        ID_DOCUMENTO,
        SAFRA_REF,
        DATEDIFF(DATA_VENCIMENTO, '{dt_ref}') AS DIAS_VENCIMENTO,
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
        DATEDIFF(DATA_VENCIMENTO,'{dt_ref}') AS PRAZO_VENC,
        DATEDIFF(
            '{dt_ref}',
            LAST_VALUE(
                CASE
                    WHEN DATA_PAGAMENTO > DATA_VENCIMENTO AND DATA_PAGAMENTO <= '{dt_ref}'
                    THEN DATA_PAGAMENTO
                END
            ) IGNORE NULLS OVER (
                PARTITION BY ID_CLIENTE
                ORDER BY SAFRA_REF
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            )
        ) AS DIAS_ULT_ATRASO,
        DATEDIFF(
            '{dt_ref}',
            LAST_VALUE(
                CASE
                    WHEN DATA_PAGAMENTO >= DATA_VENCIMENTO + INTERVAL 5 DAY  AND DATA_PAGAMENTO <= '{dt_ref}'
                    THEN DATA_PAGAMENTO
                END
            ) IGNORE NULLS OVER (
                PARTITION BY ID_CLIENTE
                ORDER BY SAFRA_REF
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            )
        ) AS DIAS_ULT_INAD,
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

SELECT
    ID_CLIENTE,
    ID_DOCUMENTO,
    '{dt_ref}' AS DATA_REF,
    DIAS_VENCIMENTO,
    DIAS_ULT_PAG,
    PRAZO_VENC,
    DIAS_ULT_ATRASO,
    DIAS_ULT_INAD,
    DIAS_ULT_EMISSAO
FROM fs_temporal