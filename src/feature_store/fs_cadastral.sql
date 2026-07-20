WITH tb_historico AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

base AS (

    SELECT
        a.ID_CLIENTE,
        a.SAFRA_REF,
        a.ID_DOCUMENTO,
        c.DDD,
        c.FLAG_PF,
        c.DOMINIO_EMAIL,
        c.PORTE,
        c.SEGMENTO_INDUSTRIAL,
        c.DATA_CADASTRO,
        CAST(
            CASE
                WHEN LOWER(TRIM(c.CEP_2_DIG)) = 'na' THEN NULL
                ELSE TRIM(c.CEP_2_DIG)
            END
            AS INT
        ) AS CEP_2_DIG
    FROM tb_historico a
    INNER JOIN credit_score.data.cadastral c
        ON a.ID_CLIENTE = c.ID_CLIENTE

),

fs_cadastral_estado AS (

    SELECT
        *,
        DATEDIFF('{dt_ref}', DATA_CADASTRO) AS IDADE_BASE,
        CASE
            WHEN CEP_2_DIG BETWEEN 1 AND 19 THEN 'SP'
            WHEN CEP_2_DIG BETWEEN 20 AND 28 THEN 'RJ'
            WHEN CEP_2_DIG = 29 THEN 'ES'
            WHEN CEP_2_DIG BETWEEN 30 AND 39 THEN 'MG'
            WHEN CEP_2_DIG BETWEEN 40 AND 48 THEN 'BA'
            WHEN CEP_2_DIG = 49 THEN 'SE'
            WHEN CEP_2_DIG BETWEEN 50 AND 56 THEN 'PE'
            WHEN CEP_2_DIG = 57 THEN 'AL'
            WHEN CEP_2_DIG = 58 THEN 'PB'
            WHEN CEP_2_DIG = 59 THEN 'RN'
            WHEN CEP_2_DIG BETWEEN 60 AND 63 THEN 'CE'
            WHEN CEP_2_DIG = 64 THEN 'PI'
            WHEN CEP_2_DIG = 65 THEN 'MA'
            WHEN CEP_2_DIG BETWEEN 66 AND 68 THEN 'PA'
            WHEN CEP_2_DIG = 69 THEN 'AM'
            WHEN CEP_2_DIG BETWEEN 70 AND 72 THEN 'DF'
            WHEN CEP_2_DIG BETWEEN 73 AND 76 THEN 'GO'
            WHEN CEP_2_DIG = 77 THEN 'TO'
            WHEN CEP_2_DIG = 78 THEN 'MT'
            WHEN CEP_2_DIG = 79 THEN 'MS'
            WHEN CEP_2_DIG BETWEEN 80 AND 87 THEN 'PR'
            WHEN CEP_2_DIG BETWEEN 88 AND 89 THEN 'SC'
            WHEN CEP_2_DIG BETWEEN 90 AND 99 THEN 'RS'
            ELSE NULL
        END AS ESTADO,
        CASE
            WHEN (CASE
                    WHEN CEP_2_DIG BETWEEN 1 AND 19 THEN 'SP'
                    WHEN CEP_2_DIG BETWEEN 20 AND 28 THEN 'RJ'
                    WHEN CEP_2_DIG = 29 THEN 'ES'
                    WHEN CEP_2_DIG BETWEEN 30 AND 39 THEN 'MG'
                    WHEN CEP_2_DIG BETWEEN 40 AND 48 THEN 'BA'
                    WHEN CEP_2_DIG = 49 THEN 'SE'
                    WHEN CEP_2_DIG BETWEEN 50 AND 56 THEN 'PE'
                    WHEN CEP_2_DIG = 57 THEN 'AL'
                    WHEN CEP_2_DIG = 58 THEN 'PB'
                    WHEN CEP_2_DIG = 59 THEN 'RN'
                    WHEN CEP_2_DIG BETWEEN 60 AND 63 THEN 'CE'
                    WHEN CEP_2_DIG = 64 THEN 'PI'
                    WHEN CEP_2_DIG = 65 THEN 'MA'
                    WHEN CEP_2_DIG BETWEEN 66 AND 68 THEN 'PA'
                    WHEN CEP_2_DIG = 69 THEN 'AM'
                    WHEN CEP_2_DIG BETWEEN 70 AND 72 THEN 'DF'
                    WHEN CEP_2_DIG BETWEEN 73 AND 76 THEN 'GO'
                    WHEN CEP_2_DIG = 77 THEN 'TO'
                    WHEN CEP_2_DIG = 78 THEN 'MT'
                    WHEN CEP_2_DIG = 79 THEN 'MS'
                    WHEN CEP_2_DIG BETWEEN 80 AND 87 THEN 'PR'
                    WHEN CEP_2_DIG BETWEEN 88 AND 89 THEN 'SC'
                    WHEN CEP_2_DIG BETWEEN 90 AND 99 THEN 'RS'
                    ELSE NULL
                END) IN ('SP', 'RJ', 'ES', 'MG', 'PR', 'SC', 'RS') THEN 'Sudeste/Sul'
            WHEN (CASE
                    WHEN CEP_2_DIG BETWEEN 40 AND 48 THEN 'BA'
                    WHEN CEP_2_DIG = 49 THEN 'SE'
                    WHEN CEP_2_DIG BETWEEN 50 AND 56 THEN 'PE'
                    WHEN CEP_2_DIG = 57 THEN 'AL'
                    WHEN CEP_2_DIG = 58 THEN 'PB'
                    WHEN CEP_2_DIG = 59 THEN 'RN'
                    WHEN CEP_2_DIG BETWEEN 60 AND 63 THEN 'CE'
                    WHEN CEP_2_DIG = 64 THEN 'PI'
                    WHEN CEP_2_DIG = 65 THEN 'MA'
                END) IN ('BA', 'SE', 'PE', 'AL', 'PB', 'RN', 'CE', 'PI', 'MA') THEN 'Nordeste'
            WHEN (CASE
                    WHEN CEP_2_DIG BETWEEN 66 AND 68 THEN 'PA'
                    WHEN CEP_2_DIG = 69 THEN 'AM'
                    WHEN CEP_2_DIG = 77 THEN 'TO'
                    WHEN CEP_2_DIG = 78 THEN 'MT'
                    WHEN CEP_2_DIG = 79 THEN 'MS'
                END) IN ('PA', 'AM', 'TO', 'MT', 'MS') THEN 'Norte/Centro-Oeste'
            WHEN (CASE
                    WHEN CEP_2_DIG BETWEEN 70 AND 72 THEN 'DF'
                    WHEN CEP_2_DIG BETWEEN 73 AND 76 THEN 'GO'
                END) IN ('DF', 'GO') THEN 'Centro-Oeste'
            ELSE NULL
        END AS REGIAO
    FROM base

)

SELECT 
    ID_CLIENTE,
    ID_DOCUMENTO,
    DDD,
    DATA_CADASTRO,
    '{dt_ref}' AS DATA_REF,
    DOMINIO_EMAIL,
    CEP_2_DIG,
    PORTE,
    SEGMENTO_INDUSTRIAL,
    IDADE_BASE,
    ESTADO,
    REGIAO
FROM fs_cadastral_estado;