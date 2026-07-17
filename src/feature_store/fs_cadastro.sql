WITH tb_ativa AS (

    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
      AND SAFRA_REF >= '{dt_ref}' - INTERVAL 31 DAY

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
        ) AS cep_2_dig
    FROM tb_ativa a
    INNER JOIN credit_score.data.cadastral c
        ON a.ID_CLIENTE = c.ID_CLIENTE

),

fs_cadastral_estado AS (

    SELECT
        *,
        DATEDIFF(SAFRA_REF, DATA_CADASTRO) AS idade_base_dias,
        CASE
            WHEN cep_2_dig BETWEEN 1 AND 19 THEN 'SP'
            WHEN cep_2_dig BETWEEN 20 AND 28 THEN 'RJ'
            WHEN cep_2_dig = 29 THEN 'ES'
            WHEN cep_2_dig BETWEEN 30 AND 39 THEN 'MG'
            WHEN cep_2_dig BETWEEN 40 AND 48 THEN 'BA'
            WHEN cep_2_dig = 49 THEN 'SE'
            WHEN cep_2_dig BETWEEN 50 AND 56 THEN 'PE'
            WHEN cep_2_dig = 57 THEN 'AL'
            WHEN cep_2_dig = 58 THEN 'PB'
            WHEN cep_2_dig = 59 THEN 'RN'
            WHEN cep_2_dig BETWEEN 60 AND 63 THEN 'CE'
            WHEN cep_2_dig = 64 THEN 'PI'
            WHEN cep_2_dig = 65 THEN 'MA'
            WHEN cep_2_dig BETWEEN 66 AND 68 THEN 'PA'
            WHEN cep_2_dig = 69 THEN 'AM'
            WHEN cep_2_dig BETWEEN 70 AND 72 THEN 'DF'
            WHEN cep_2_dig BETWEEN 73 AND 76 THEN 'GO'
            WHEN cep_2_dig = 77 THEN 'TO'
            WHEN cep_2_dig = 78 THEN 'MT'
            WHEN cep_2_dig = 79 THEN 'MS'
            WHEN cep_2_dig BETWEEN 80 AND 87 THEN 'PR'
            WHEN cep_2_dig BETWEEN 88 AND 89 THEN 'SC'
            WHEN cep_2_dig BETWEEN 90 AND 99 THEN 'RS'
            ELSE NULL
        END AS estado
    FROM base

)

SELECT *
FROM fs_cadastral_estado;