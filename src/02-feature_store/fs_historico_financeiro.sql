-- Histórico de pagamentos até a data de referência
WITH tb_historico AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Informações de renda por cliente e safra
tb_renda AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        RENDA_MES_ANTERIOR
    FROM credit_score.data.info
),

-- Total de valor a pagar por cliente e safra
fs_mensal AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        SUM(VALOR_A_PAGAR) AS VALOR_A_PAGAR_TOTAL_MES
    FROM tb_historico
    GROUP BY ID_CLIENTE, SAFRA_REF
),

-- Base de features mensais: diferença e razão entre valor a pagar e renda
fs_base AS (
    SELECT
        m.ID_CLIENTE,
        m.SAFRA_REF,
        m.VALOR_A_PAGAR_TOTAL_MES,
        i.RENDA_MES_ANTERIOR,
        m.VALOR_A_PAGAR_TOTAL_MES - i.RENDA_MES_ANTERIOR AS DIFERENCA_VALOR_RENDA,
        m.VALOR_A_PAGAR_TOTAL_MES / (CASE WHEN i.RENDA_MES_ANTERIOR = 0 THEN 1 ELSE i.RENDA_MES_ANTERIOR END) AS RAZAO_VALOR_RENDA
    FROM fs_mensal m
    LEFT JOIN tb_renda i
        ON m.ID_CLIENTE = i.ID_CLIENTE
        AND m.SAFRA_REF = i.SAFRA_REF
),

-- Razão entre taxa e valor a pagar por documento
fs_documento AS (
    SELECT
        ID_CLIENTE,
        ID_DOCUMENTO,
        TAXA / (CASE WHEN VALOR_A_PAGAR = 0 THEN 1 ELSE VALOR_A_PAGAR END) AS RAZAO_TAXA_VALOR_A_PAGAR
    FROM tb_historico
),

-- Features históricas agregadas por cliente
fs_historico_financeiro AS (
    SELECT
        ID_CLIENTE,

        -- Diferença valor-renda: últimos 3 meses
        AVG(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MED_DIFF_VALOR_RENDA_3M,
        MIN(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MIN_DIFF_VALOR_RENDA_3M,
        MAX(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MAX_DIFF_VALOR_RENDA_3M,

        -- Diferença valor-renda: últimos 6 meses
        AVG(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MED_DIFF_VALOR_RENDA_6M,
        MIN(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MIN_DIFF_VALOR_RENDA_6M,
        MAX(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MAX_DIFF_VALOR_RENDA_6M,

        -- Diferença valor-renda: último ano
        AVG(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MED_DIFF_VALOR_RENDA_1A,
        MIN(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MIN_DIFF_VALOR_RENDA_1A,
        MAX(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN DIFERENCA_VALOR_RENDA END) AS MAX_DIFF_VALOR_RENDA_1A,

        -- Diferença valor-renda: todo histórico
        AVG(DIFERENCA_VALOR_RENDA) AS MED_DIFF_VALOR_RENDA_VIDA,
        MIN(DIFERENCA_VALOR_RENDA) AS MIN_DIFF_VALOR_RENDA_VIDA,
        MAX(DIFERENCA_VALOR_RENDA) AS MAX_DIFF_VALOR_RENDA_VIDA,

        -- Razão valor-renda: últimos 3 meses
        AVG(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MED_RAZAO_VALOR_RENDA_3M,
        MIN(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MIN_RAZAO_VALOR_RENDA_3M,
        MAX(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MAX_RAZAO_VALOR_RENDA_3M,

        -- Razão valor-renda: últimos 6 meses
        AVG(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MED_RAZAO_VALOR_RENDA_6M,
        MIN(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MIN_RAZAO_VALOR_RENDA_6M,
        MAX(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MAX_RAZAO_VALOR_RENDA_6M,

        -- Razão valor-renda: último ano
        AVG(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MED_RAZAO_VALOR_RENDA_1A,
        MIN(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MIN_RAZAO_VALOR_RENDA_1A,
        MAX(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RAZAO_VALOR_RENDA END) AS MAX_RAZAO_VALOR_RENDA_1A,

        -- Razão valor-renda: todo histórico
        AVG(RAZAO_VALOR_RENDA) AS MED_RAZAO_VALOR_RENDA_VIDA,
        MIN(RAZAO_VALOR_RENDA) AS MIN_RAZAO_VALOR_RENDA_VIDA,
        MAX(RAZAO_VALOR_RENDA) AS MAX_RAZAO_VALOR_RENDA_VIDA

    FROM fs_base
    GROUP BY ID_CLIENTE
)

-- Seleção final: features por documento e cliente
SELECT
    d.ID_CLIENTE,
    d.ID_DOCUMENTO,
    CAST('{dt_ref}' AS DATE) AS DATA_REF,
    d.RAZAO_TAXA_VALOR_A_PAGAR,
    h.MED_DIFF_VALOR_RENDA_3M,
    h.MIN_DIFF_VALOR_RENDA_3M,
    h.MAX_DIFF_VALOR_RENDA_3M,
    h.MED_DIFF_VALOR_RENDA_6M,
    h.MIN_DIFF_VALOR_RENDA_6M,
    h.MAX_DIFF_VALOR_RENDA_6M,
    h.MED_DIFF_VALOR_RENDA_1A,
    h.MIN_DIFF_VALOR_RENDA_1A,
    h.MAX_DIFF_VALOR_RENDA_1A,
    h.MED_DIFF_VALOR_RENDA_VIDA,
    h.MIN_DIFF_VALOR_RENDA_VIDA,
    h.MAX_DIFF_VALOR_RENDA_VIDA,
    h.MED_RAZAO_VALOR_RENDA_3M,
    h.MIN_RAZAO_VALOR_RENDA_3M,
    h.MAX_RAZAO_VALOR_RENDA_3M,
    h.MED_RAZAO_VALOR_RENDA_6M,
    h.MIN_RAZAO_VALOR_RENDA_6M,
    h.MAX_RAZAO_VALOR_RENDA_6M,
    h.MED_RAZAO_VALOR_RENDA_1A,
    h.MIN_RAZAO_VALOR_RENDA_1A,
    h.MAX_RAZAO_VALOR_RENDA_1A,
    h.MED_RAZAO_VALOR_RENDA_VIDA,
    h.MIN_RAZAO_VALOR_RENDA_VIDA,
    h.MAX_RAZAO_VALOR_RENDA_VIDA
FROM fs_documento d
LEFT JOIN fs_historico_financeiro h
    ON d.ID_CLIENTE = h.ID_CLIENTE