-- Historical documents by customer, filtering by reference
WITH tb_history AS (
    SELECT
        ID_CLIENTE,
        ID_DOCUMENTO
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Employees and income by customer, filtering by reference
tb_employees AS (
    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        NO_FUNCIONARIOS,
        RENDA_MES_ANTERIOR
    FROM credit_score.data.info
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Company size by customer
tb_size AS (
    SELECT
        ID_CLIENTE,
        PORTE
    FROM credit_score.data.cadastral
),

-- Historical employee milestones and history availability flags
fs_employee_milestones AS (
    SELECT
        ID_CLIENTE,
        MAX_BY(NO_FUNCIONARIOS, SAFRA_REF) AS NO_FUNCIONARIOS_ATUAL,
        MAX_BY(
            CASE WHEN SAFRA_REF <= date_add(MONTH,-3,'{dt_ref}') THEN NO_FUNCIONARIOS END,
            CASE WHEN SAFRA_REF <= date_add(MONTH,-3,'{dt_ref}') THEN SAFRA_REF END
        ) AS NO_FUNCIONARIOS_3M,
        MAX_BY(
            CASE WHEN SAFRA_REF <= date_add(MONTH,-6,'{dt_ref}') THEN NO_FUNCIONARIOS END,
            CASE WHEN SAFRA_REF <= date_add(MONTH,-6,'{dt_ref}') THEN SAFRA_REF END
        ) AS NO_FUNCIONARIOS_6M,
        MAX_BY(
            CASE WHEN SAFRA_REF <= date_add(YEAR,-1,'{dt_ref}') THEN NO_FUNCIONARIOS END,
            CASE WHEN SAFRA_REF <= date_add(YEAR,-1,'{dt_ref}') THEN SAFRA_REF END
        ) AS NO_FUNCIONARIOS_12M,
        MIN_BY(NO_FUNCIONARIOS, SAFRA_REF) AS NO_FUNCIONARIOS_VIDA,
        MAX_BY(RENDA_MES_ANTERIOR, SAFRA_REF) AS RENDA_ATUAL,
        -- History availability flags
        MAX(CASE WHEN SAFRA_REF <= date_add(MONTH,-3,'{dt_ref}') THEN 1 ELSE 0 END) AS FLAG_HISTORICO_3M,
        MAX(CASE WHEN SAFRA_REF <= date_add(MONTH,-6,'{dt_ref}') THEN 1 ELSE 0 END) AS FLAG_HISTORICO_6M,
        MAX(CASE WHEN SAFRA_REF <= date_add(YEAR,-1,'{dt_ref}')  THEN 1 ELSE 0 END) AS FLAG_HISTORICO_12M,
        COUNT(*) AS QT_SAFRAS_HISTORICO
    FROM tb_employees
    GROUP BY ID_CLIENTE
),

-- Average employees by company size
tb_average_by_size AS (
    SELECT
        p.PORTE,
        AVG(m.NO_FUNCIONARIOS_ATUAL) AS MEDIA_PORTE_FUNCIONARIOS
    FROM fs_employee_milestones m
    JOIN tb_size p ON m.ID_CLIENTE = p.ID_CLIENTE
    GROUP BY p.PORTE
),

-- Overall average employees (fallback)
tb_overall_average AS (
    SELECT AVG(NO_FUNCIONARIOS_ATUAL) AS MEDIA_GERAL_FUNCIONARIOS
    FROM fs_employee_milestones
),

-- Employee growth calculation
fs_employee_growth AS (
    SELECT
        *,
        -- Growth in different periods, considering history flags
        (NO_FUNCIONARIOS_ATUAL - NO_FUNCIONARIOS_3M) / NULLIF(NO_FUNCIONARIOS_3M, 0) AS CRESCIMENTO_FUNC_3M,
        (NO_FUNCIONARIOS_ATUAL - NO_FUNCIONARIOS_6M) / NULLIF(NO_FUNCIONARIOS_6M, 0) AS CRESCIMENTO_FUNC_6M,
        (NO_FUNCIONARIOS_ATUAL - NO_FUNCIONARIOS_12M) / NULLIF(NO_FUNCIONARIOS_12M, 0) AS CRESCIMENTO_FUNC_12M,
        (NO_FUNCIONARIOS_ATUAL - NO_FUNCIONARIOS_VIDA) / NULLIF(NO_FUNCIONARIOS_VIDA, 0) AS CRESCIMENTO_FUNC_VIDA
    FROM fs_employee_milestones
),

-- Monthly employee variations
fs_variations AS (
    SELECT
        ID_CLIENTE,
        -- COALESCE to 0: with only 1 period there's no month-to-month variation to measure
        COALESCE(MAX(VARIACAO), 0) AS MAIOR_CRESCIMENTO_MENSAL,
        COALESCE(MIN(VARIACAO), 0) AS MAIOR_QUEDA_MENSAL,
        MAX(CASE WHEN VARIACAO IS NOT NULL THEN 1 ELSE 0 END) AS FLAG_HISTORICO_VARIACAO
    FROM (
        SELECT
            ID_CLIENTE,
            (
                NO_FUNCIONARIOS
                - LAG(NO_FUNCIONARIOS) OVER (PARTITION BY ID_CLIENTE ORDER BY SAFRA_REF)
            ) /
            NULLIF(
                LAG(NO_FUNCIONARIOS) OVER (PARTITION BY ID_CLIENTE ORDER BY SAFRA_REF),
                0
            ) AS VARIACAO
        FROM tb_employees
    ) x
    GROUP BY ID_CLIENTE
),

-- Consolidated metrics by customer
fs_employees AS (
    SELECT
        c.ID_CLIENTE,
        c.NO_FUNCIONARIOS_ATUAL,
        c.NO_FUNCIONARIOS_3M,
        c.NO_FUNCIONARIOS_6M,
        c.NO_FUNCIONARIOS_12M,
        c.NO_FUNCIONARIOS_VIDA,
        c.FLAG_HISTORICO_3M,
        c.FLAG_HISTORICO_6M,
        c.FLAG_HISTORICO_12M,
        c.QT_SAFRAS_HISTORICO,
        c.CRESCIMENTO_FUNC_3M,
        c.CRESCIMENTO_FUNC_6M,
        c.CRESCIMENTO_FUNC_12M,
        c.CRESCIMENTO_FUNC_VIDA,
        v.MAIOR_CRESCIMENTO_MENSAL,
        v.MAIOR_QUEDA_MENSAL,
        v.FLAG_HISTORICO_VARIACAO,
        c.RENDA_ATUAL / NULLIF(c.NO_FUNCIONARIOS_ATUAL, 0) AS RAZAO_RENDA_POR_FUNCIONARIO,
        -- Fallback: if customer has no registered SIZE (mp NULL), use overall average
        c.NO_FUNCIONARIOS_ATUAL - COALESCE(mp.MEDIA_PORTE_FUNCIONARIOS, mg.MEDIA_GERAL_FUNCIONARIOS) AS DIF_PARA_MEDIA_PORTE,
        CASE WHEN mp.MEDIA_PORTE_FUNCIONARIOS IS NULL THEN 1 ELSE 0 END AS FLAG_PORTE_AUSENTE
    FROM fs_employee_growth c
    LEFT JOIN tb_size tp ON c.ID_CLIENTE = tp.ID_CLIENTE
    LEFT JOIN tb_average_by_size mp ON tp.PORTE = mp.PORTE
    LEFT JOIN fs_variations v ON c.ID_CLIENTE = v.ID_CLIENTE
    CROSS JOIN tb_overall_average mg
)

-- Final result: metrics by document and customer
SELECT
    h.ID_DOCUMENTO,
    h.ID_CLIENTE,
    CAST('{dt_ref}' AS DATE) AS DATA_REF,
    f.NO_FUNCIONARIOS_ATUAL,
    f.NO_FUNCIONARIOS_3M,
    f.NO_FUNCIONARIOS_6M,
    f.NO_FUNCIONARIOS_12M,
    f.NO_FUNCIONARIOS_VIDA,
    f.FLAG_HISTORICO_3M,
    f.FLAG_HISTORICO_6M,
    f.FLAG_HISTORICO_12M,
    f.QT_SAFRAS_HISTORICO,
    f.CRESCIMENTO_FUNC_3M,
    f.CRESCIMENTO_FUNC_6M,
    f.CRESCIMENTO_FUNC_12M,
    f.CRESCIMENTO_FUNC_VIDA,
    f.MAIOR_CRESCIMENTO_MENSAL,
    f.MAIOR_QUEDA_MENSAL,
    f.FLAG_HISTORICO_VARIACAO,
    f.RAZAO_RENDA_POR_FUNCIONARIO,
    f.DIF_PARA_MEDIA_PORTE,
    f.FLAG_PORTE_AUSENTE
FROM tb_history h
LEFT JOIN fs_employees f ON h.ID_CLIENTE = f.ID_CLIENTE;
