-- Histórico de pagamentos até a data de referência
WITH tb_historico AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Seleção de documentos únicos por cliente
fs_documentos_unicos AS (
    SELECT
        ID_CLIENTE,
        ID_DOCUMENTO
    FROM tb_historico
),

-- Base de renda até a data de referência
tb_renda_base AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        CAST(RENDA_MES_ANTERIOR AS DOUBLE) AS RENDA_MES_ANTERIOR
    FROM credit_score.data.info
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Marcos de renda: renda atual e em períodos anteriores
fs_marcos AS (
    SELECT
        ID_CLIENTE,
        MAX_BY(RENDA_MES_ANTERIOR, SAFRA_REF) AS RENDA_ATUAL,
        MAX_BY(
            CASE WHEN SAFRA_REF <= date_add(MONTH, -3, '{dt_ref}') THEN RENDA_MES_ANTERIOR END,
            CASE WHEN SAFRA_REF <= date_add(MONTH, -3, '{dt_ref}') THEN SAFRA_REF END
        ) AS RENDA_3M_ATRAS,
        MAX_BY(
            CASE WHEN SAFRA_REF <= date_add(MONTH, -6, '{dt_ref}') THEN RENDA_MES_ANTERIOR END,
            CASE WHEN SAFRA_REF <= date_add(MONTH, -6, '{dt_ref}') THEN SAFRA_REF END
        ) AS RENDA_6M_ATRAS,
        MAX_BY(
            CASE WHEN SAFRA_REF <= date_add(YEAR, -1, '{dt_ref}') THEN RENDA_MES_ANTERIOR END,
            CASE WHEN SAFRA_REF <= date_add(YEAR, -1, '{dt_ref}') THEN SAFRA_REF END
        ) AS RENDA_1A_ATRAS
    FROM tb_renda_base
    GROUP BY ID_CLIENTE
),

-- Cálculo de crescimento absoluto e percentual da renda
fs_crescimento AS (
    SELECT
        ID_CLIENTE,
        RENDA_ATUAL - RENDA_3M_ATRAS AS CRESCIMENTO_ABS_RENDA_3M,
        (RENDA_ATUAL - RENDA_3M_ATRAS) / (CASE WHEN RENDA_3M_ATRAS = 0 THEN 1 ELSE RENDA_3M_ATRAS END) AS CRESCIMENTO_PERC_RENDA_3M,
        RENDA_ATUAL - RENDA_6M_ATRAS AS CRESCIMENTO_ABS_RENDA_6M,
        (RENDA_ATUAL - RENDA_6M_ATRAS) / (CASE WHEN RENDA_6M_ATRAS = 0 THEN 1 ELSE RENDA_6M_ATRAS END) AS CRESCIMENTO_PERC_RENDA_6M,
        RENDA_ATUAL - RENDA_1A_ATRAS AS CRESCIMENTO_ABS_RENDA_1A,
        (RENDA_ATUAL - RENDA_1A_ATRAS) / (CASE WHEN RENDA_1A_ATRAS = 0 THEN 1 ELSE RENDA_1A_ATRAS END) AS CRESCIMENTO_PERC_RENDA_1A
    FROM fs_marcos
),

-- Estatísticas de renda por períodos
fs_renda AS (
    SELECT
        ID_CLIENTE,
        AVG(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MED_RENDA_3M,
        MIN(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MIN_RENDA_3M,
        MAX(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MAX_RENDA_3M,
        SUM(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS SOMA_RENDA_3M,
        AVG(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MED_RENDA_6M,
        MIN(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MIN_RENDA_6M,
        MAX(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MAX_RENDA_6M,
        SUM(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS SOMA_RENDA_6M,
        AVG(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MED_RENDA_1A,
        MIN(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MIN_RENDA_1A,
        MAX(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS MAX_RENDA_1A,
        SUM(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS SOMA_RENDA_1A,
        AVG(RENDA_MES_ANTERIOR) AS MED_RENDA_VIDA,
        MIN(RENDA_MES_ANTERIOR) AS MIN_RENDA_VIDA,
        MAX(RENDA_MES_ANTERIOR) AS MAX_RENDA_VIDA,
        STDDEV(CASE WHEN SAFRA_REF >= date_add(MONTH, -3, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS STD_RENDA_3M,
        STDDEV(CASE WHEN SAFRA_REF >= date_add(MONTH, -6, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS STD_RENDA_6M,
        STDDEV(CASE WHEN SAFRA_REF >= date_add(YEAR, -1, '{dt_ref}') THEN RENDA_MES_ANTERIOR END) AS STD_RENDA_1A,
        STDDEV(RENDA_MES_ANTERIOR) AS STD_RENDA_VIDA
    FROM tb_renda_base
    GROUP BY ID_CLIENTE
),

-- Flag de queda de renda mês a mês
fs_flag_queda AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        RENDA_MES_ANTERIOR,
        CASE
            WHEN RENDA_MES_ANTERIOR < LAG(RENDA_MES_ANTERIOR) OVER (
                PARTITION BY ID_CLIENTE ORDER BY SAFRA_REF
            ) THEN 1
            ELSE 0
        END AS FLAG_QUEDA
    FROM tb_renda_base
),

-- Identificação de blocos consecutivos de queda de renda
fs_ilhas AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        FLAG_QUEDA,
        ROW_NUMBER() OVER (PARTITION BY ID_CLIENTE ORDER BY SAFRA_REF)
        - ROW_NUMBER() OVER (PARTITION BY ID_CLIENTE, FLAG_QUEDA ORDER BY SAFRA_REF) AS ILHA_ID
    FROM fs_flag_queda
),

fs_blocos_queda AS (
    SELECT
        ID_CLIENTE,
        ILHA_ID,
        COUNT(*) AS TAMANHO_BLOCO,
        MAX(SAFRA_REF) AS FIM_BLOCO
    FROM fs_ilhas
    WHERE FLAG_QUEDA = 1
    GROUP BY ID_CLIENTE, ILHA_ID
),

-- Última safra de cada cliente
fs_ultima_safra AS (
    SELECT
        ID_CLIENTE,
        MAX(SAFRA_REF) AS ULTIMA_SAFRA
    FROM tb_renda_base
    GROUP BY ID_CLIENTE
),

-- Quantidade de meses consecutivos de queda até a última safra
fs_streak_atual AS (
    SELECT
        u.ID_CLIENTE,
        COALESCE(b.TAMANHO_BLOCO, 0) AS MESES_CONSECUTIVOS_QUEDA
    FROM fs_ultima_safra u
    LEFT JOIN fs_blocos_queda b
        ON u.ID_CLIENTE = b.ID_CLIENTE
        AND u.ULTIMA_SAFRA = b.FIM_BLOCO
)

-- Seleção final com todas as métricas
SELECT
    doc.ID_CLIENTE,
    doc.ID_DOCUMENTO,
    CAST('{dt_ref}' AS DATE) AS DATA_REF,
    r.SOMA_RENDA_3M,
    r.MED_RENDA_3M,
    r.MIN_RENDA_3M,
    r.MAX_RENDA_3M,
    r.STD_RENDA_3M,
    r.SOMA_RENDA_6M,
    r.MED_RENDA_6M,
    r.MIN_RENDA_6M,
    r.MAX_RENDA_6M,
    r.STD_RENDA_6M,
    r.SOMA_RENDA_1A,
    r.MED_RENDA_1A,
    r.MIN_RENDA_1A,
    r.MAX_RENDA_1A,
    r.STD_RENDA_1A,
    r.MED_RENDA_VIDA,
    r.MIN_RENDA_VIDA,
    r.MAX_RENDA_VIDA,
    r.STD_RENDA_VIDA,
    c.CRESCIMENTO_ABS_RENDA_3M,
    c.CRESCIMENTO_PERC_RENDA_3M,
    c.CRESCIMENTO_ABS_RENDA_6M,
    c.CRESCIMENTO_PERC_RENDA_6M,
    c.CRESCIMENTO_ABS_RENDA_1A,
    c.CRESCIMENTO_PERC_RENDA_1A,
    s.MESES_CONSECUTIVOS_QUEDA
FROM fs_documentos_unicos doc
LEFT JOIN fs_renda r
    ON doc.ID_CLIENTE = r.ID_CLIENTE
LEFT JOIN fs_crescimento c
    ON doc.ID_CLIENTE = c.ID_CLIENTE
LEFT JOIN fs_streak_atual s
    ON doc.ID_CLIENTE = s.ID_CLIENTE