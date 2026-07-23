
WITH tb_historico AS (

    SELECT DISTINCT
        ID_CLIENTE,
        ID_DOCUMENTO
    FROM credit_score.data.pagamentos
        WHERE SAFRA_REF < '{dt_ref}'

),

tb_funcionarios AS (

    SELECT
        ID_CLIENTE,
        SAFRA_REF,
        NO_FUNCIONARIOS,
        RENDA_MES_ANTERIOR
    FROM credit_score.data.info
        WHERE SAFRA_REF < '{dt_ref}'

),

tb_porte AS (

    SELECT
        ID_CLIENTE,
        PORTE
    FROM credit_score.data.cadastral

),

tb_media_porte AS (

    SELECT
        p.PORTE,
        AVG(f.NO_FUNCIONARIOS) AS MEDIA_PORTE_FUNCIONARIOS
    FROM tb_funcionarios f
    JOIN tb_porte p
      ON f.ID_CLIENTE = p.ID_CLIENTE
    GROUP BY p.PORTE

),

fs_marcos_func AS (

    SELECT

        ID_CLIENTE,

        MAX_BY(NO_FUNCIONARIOS, SAFRA_REF) AS NO_FUNCIONARIOS_ATUAL,

        MAX_BY(
            CASE
                    WHEN SAFRA_REF <= date_add(MONTH,-3,'{dt_ref}')
                THEN NO_FUNCIONARIOS
            END,
            CASE
                    WHEN SAFRA_REF <= date_add(MONTH,-3,'{dt_ref}')
                THEN SAFRA_REF
            END
        ) AS NO_FUNCIONARIOS_3M,

        MAX_BY(
            CASE
                    WHEN SAFRA_REF <= date_add(MONTH,-6,'{dt_ref}')
                THEN NO_FUNCIONARIOS
            END,
            CASE
                    WHEN SAFRA_REF <= date_add(MONTH,-6,'{dt_ref}')
                THEN SAFRA_REF
            END
        ) AS NO_FUNCIONARIOS_6M,

        MAX_BY(
            CASE
                    WHEN SAFRA_REF <= date_add(YEAR,-1,'{dt_ref}')
                THEN NO_FUNCIONARIOS
            END,
            CASE
                    WHEN SAFRA_REF <= date_add(YEAR,-1,'{dt_ref}')
                THEN SAFRA_REF
            END
        ) AS NO_FUNCIONARIOS_12M,

        MIN_BY(NO_FUNCIONARIOS, SAFRA_REF) AS NO_FUNCIONARIOS_VIDA,

        MAX_BY(RENDA_MES_ANTERIOR, SAFRA_REF) AS RENDA_ATUAL

    FROM tb_funcionarios
    GROUP BY ID_CLIENTE

),

fs_crescimento_func AS (

    SELECT

        *,

        (NO_FUNCIONARIOS_ATUAL-NO_FUNCIONARIOS_3M)
/NULLIF(NO_FUNCIONARIOS_3M,0) AS CRESCIMENTO_FUNC_3M,

        (NO_FUNCIONARIOS_3M-NO_FUNCIONARIOS_ATUAL)
/NULLIF(NO_FUNCIONARIOS_3M,0) AS REDUCAO_FUNC_3M,

        (NO_FUNCIONARIOS_ATUAL-NO_FUNCIONARIOS_6M)
/NULLIF(NO_FUNCIONARIOS_6M,0) AS CRESCIMENTO_FUNC_6M,

        (NO_FUNCIONARIOS_6M-NO_FUNCIONARIOS_ATUAL)
/NULLIF(NO_FUNCIONARIOS_6M,0) AS REDUCAO_FUNC_6M,

        (NO_FUNCIONARIOS_ATUAL-NO_FUNCIONARIOS_12M)
/NULLIF(NO_FUNCIONARIOS_12M,0) AS CRESCIMENTO_FUNC_12M,

        (NO_FUNCIONARIOS_12M-NO_FUNCIONARIOS_ATUAL)
/NULLIF(NO_FUNCIONARIOS_12M,0) AS REDUCAO_FUNC_12M,

        (NO_FUNCIONARIOS_ATUAL-NO_FUNCIONARIOS_VIDA)
/NULLIF(NO_FUNCIONARIOS_VIDA,0) AS CRESCIMENTO_FUNC_VIDA,

        (NO_FUNCIONARIOS_VIDA-NO_FUNCIONARIOS_ATUAL)
/NULLIF(NO_FUNCIONARIOS_VIDA,0) AS REDUCAO_FUNC_VIDA

    FROM fs_marcos_func

),

fs_variacoes AS (

    SELECT

        ID_CLIENTE,

        MAX(VARIACAO) AS MAIOR_CRESCIMENTO_MENSAL,

        MIN(VARIACAO) AS MAIOR_QUEDA_MENSAL

    FROM (

        SELECT

            ID_CLIENTE,

            (
                NO_FUNCIONARIOS
                - LAG(NO_FUNCIONARIOS) OVER(
                    PARTITION BY ID_CLIENTE
                    ORDER BY SAFRA_REF
                )
            )
            /
            NULLIF(
                LAG(NO_FUNCIONARIOS) OVER(
                    PARTITION BY ID_CLIENTE
                    ORDER BY SAFRA_REF
                ),
                0
            ) AS VARIACAO

        FROM tb_funcionarios

    ) x

    GROUP BY ID_CLIENTE

),

fs_funcionarios AS (

    SELECT

        c.ID_CLIENTE,

        c.NO_FUNCIONARIOS_ATUAL,
        c.NO_FUNCIONARIOS_3M,
        c.NO_FUNCIONARIOS_6M,
        c.NO_FUNCIONARIOS_12M,
        c.NO_FUNCIONARIOS_VIDA,

        c.CRESCIMENTO_FUNC_3M,
        c.REDUCAO_FUNC_3M,

        c.CRESCIMENTO_FUNC_6M,
        c.REDUCAO_FUNC_6M,

        c.CRESCIMENTO_FUNC_12M,
        c.REDUCAO_FUNC_12M,

        c.CRESCIMENTO_FUNC_VIDA,
        c.REDUCAO_FUNC_VIDA,

        v.MAIOR_CRESCIMENTO_MENSAL,
        v.MAIOR_QUEDA_MENSAL,

        c.RENDA_ATUAL
            / NULLIF(c.NO_FUNCIONARIOS_ATUAL,0)
            AS RAZAO_RENDA_POR_FUNCIONARIO,

        c.NO_FUNCIONARIOS_ATUAL
            - mp.MEDIA_PORTE_FUNCIONARIOS
            AS DIF_PARA_MEDIA_PORTE

    FROM fs_crescimento_func c

    LEFT JOIN tb_porte tp
      ON c.ID_CLIENTE=tp.ID_CLIENTE

    LEFT JOIN tb_media_porte mp
      ON tp.PORTE=mp.PORTE

    LEFT JOIN fs_variacoes v
      ON c.ID_CLIENTE=v.ID_CLIENTE

)

SELECT

    h.ID_DOCUMENTO,
    h.ID_CLIENTE,

    CAST('{dt_ref}' AS DATE) AS DATA_REF,

    f.NO_FUNCIONARIOS_ATUAL,
    f.NO_FUNCIONARIOS_3M,
    f.NO_FUNCIONARIOS_6M,
    f.NO_FUNCIONARIOS_12M,
    f.NO_FUNCIONARIOS_VIDA,

    f.CRESCIMENTO_FUNC_3M,
    f.REDUCAO_FUNC_3M,

    f.CRESCIMENTO_FUNC_6M,
    f.REDUCAO_FUNC_6M,

    f.CRESCIMENTO_FUNC_12M,
    f.REDUCAO_FUNC_12M,

    f.CRESCIMENTO_FUNC_VIDA,
    f.REDUCAO_FUNC_VIDA,

    f.MAIOR_CRESCIMENTO_MENSAL,
    f.MAIOR_QUEDA_MENSAL,

    f.RAZAO_RENDA_POR_FUNCIONARIO,

    f.DIF_PARA_MEDIA_PORTE

FROM tb_historico h

LEFT JOIN fs_funcionarios f
    ON h.ID_CLIENTE = f.ID_CLIENTE