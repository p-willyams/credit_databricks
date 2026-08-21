-- Payment history up to reference date
WITH payment_history AS (
    SELECT *
    FROM credit_score.data.pagamentos
    WHERE SAFRA_REF < '{dt_ref}'
),

-- Cadastral base enriched with historical information
base AS (
    SELECT
        a.ID_CLIENTE AS CLIENT_ID,
        a.SAFRA_REF AS REF_BATCH,
        a.ID_DOCUMENTO AS DOCUMENT_ID,
        c.DDD AS PHONE_DDD,
        c.FLAG_PF AS IS_INDIVIDUAL,
        c.DOMINIO_EMAIL AS EMAIL_DOMAIN,
        c.PORTE AS COMPANY_SIZE,
        c.SEGMENTO_INDUSTRIAL AS INDUSTRY_SEGMENT,
        c.DATA_CADASTRO AS REGISTRATION_DATE,
        -- Convert CEP_2_DIG to integer, handling 'na' values
        CAST(
            CASE
                WHEN LOWER(TRIM(c.CEP_2_DIG)) = 'na' THEN NULL
                ELSE TRIM(c.CEP_2_DIG)
            END
            AS INT
        ) AS ZIP2_DIG
    FROM payment_history a
    INNER JOIN credit_score.data.cadastral c
        ON a.ID_CLIENTE = c.ID_CLIENTE
),

-- Calculate base age, state and region from ZIP2_DIG
fs_cadastral_state AS (
    SELECT
        *,
        DATEDIFF('{dt_ref}', REGISTRATION_DATE) AS BASE_AGE,
        -- Mapping ZIP2_DIG to STATE
        CASE
            WHEN ZIP2_DIG BETWEEN 1 AND 19 THEN 'SP'
            WHEN ZIP2_DIG BETWEEN 20 AND 28 THEN 'RJ'
            WHEN ZIP2_DIG = 29 THEN 'ES'
            WHEN ZIP2_DIG BETWEEN 30 AND 39 THEN 'MG'
            WHEN ZIP2_DIG BETWEEN 40 AND 48 THEN 'BA'
            WHEN ZIP2_DIG = 49 THEN 'SE'
            WHEN ZIP2_DIG BETWEEN 50 AND 56 THEN 'PE'
            WHEN ZIP2_DIG = 57 THEN 'AL'
            WHEN ZIP2_DIG = 58 THEN 'PB'
            WHEN ZIP2_DIG = 59 THEN 'RN'
            WHEN ZIP2_DIG BETWEEN 60 AND 63 THEN 'CE'
            WHEN ZIP2_DIG = 64 THEN 'PI'
            WHEN ZIP2_DIG = 65 THEN 'MA'
            WHEN ZIP2_DIG BETWEEN 66 AND 68 THEN 'PA'
            WHEN ZIP2_DIG = 69 THEN 'AM'
            WHEN ZIP2_DIG BETWEEN 70 AND 72 THEN 'DF'
            WHEN ZIP2_DIG BETWEEN 73 AND 76 THEN 'GO'
            WHEN ZIP2_DIG = 77 THEN 'TO'
            WHEN ZIP2_DIG = 78 THEN 'MT'
            WHEN ZIP2_DIG = 79 THEN 'MS'
            WHEN ZIP2_DIG BETWEEN 80 AND 87 THEN 'PR'
            WHEN ZIP2_DIG BETWEEN 88 AND 89 THEN 'SC'
            WHEN ZIP2_DIG BETWEEN 90 AND 99 THEN 'RS'
            ELSE NULL
        END AS STATE,
        -- Mapping STATE to REGION
        CASE
            WHEN (CASE
                    WHEN ZIP2_DIG BETWEEN 1 AND 19 THEN 'SP'
                    WHEN ZIP2_DIG BETWEEN 20 AND 28 THEN 'RJ'
                    WHEN ZIP2_DIG = 29 THEN 'ES'
                    WHEN ZIP2_DIG BETWEEN 30 AND 39 THEN 'MG'
                    WHEN ZIP2_DIG BETWEEN 80 AND 87 THEN 'PR'
                    WHEN ZIP2_DIG BETWEEN 88 AND 89 THEN 'SC'
                    WHEN ZIP2_DIG BETWEEN 90 AND 99 THEN 'RS'
                END) IN ('SP', 'RJ', 'ES', 'MG', 'PR', 'SC', 'RS') THEN 'Southeast/South'
            WHEN (CASE
                    WHEN ZIP2_DIG BETWEEN 40 AND 48 THEN 'BA'
                    WHEN ZIP2_DIG = 49 THEN 'SE'
                    WHEN ZIP2_DIG BETWEEN 50 AND 56 THEN 'PE'
                    WHEN ZIP2_DIG = 57 THEN 'AL'
                    WHEN ZIP2_DIG = 58 THEN 'PB'
                    WHEN ZIP2_DIG = 59 THEN 'RN'
                    WHEN ZIP2_DIG BETWEEN 60 AND 63 THEN 'CE'
                    WHEN ZIP2_DIG = 64 THEN 'PI'
                    WHEN ZIP2_DIG = 65 THEN 'MA'
                END) IN ('BA', 'SE', 'PE', 'AL', 'PB', 'RN', 'CE', 'PI', 'MA') THEN 'Northeast'
            WHEN (CASE
                    WHEN ZIP2_DIG BETWEEN 66 AND 68 THEN 'PA'
                    WHEN ZIP2_DIG = 69 THEN 'AM'
                    WHEN ZIP2_DIG = 77 THEN 'TO'
                    WHEN ZIP2_DIG = 78 THEN 'MT'
                    WHEN ZIP2_DIG = 79 THEN 'MS'
                END) IN ('PA', 'AM', 'TO', 'MT', 'MS') THEN 'North/Midwest'
            WHEN (CASE
                    WHEN ZIP2_DIG BETWEEN 70 AND 72 THEN 'DF'
                    WHEN ZIP2_DIG BETWEEN 73 AND 76 THEN 'GO'
                END) IN ('DF', 'GO') THEN 'Midwest'
            ELSE NULL
        END AS REGION_NAME
    FROM base
)

-- Final selection of relevant columns
SELECT 
    CLIENT_ID,
    DOCUMENT_ID,
    PHONE_DDD,
    REGISTRATION_DATE,
    CAST('{dt_ref}' AS DATE) AS REF_DATE,
    EMAIL_DOMAIN,
    ZIP2_DIG,
    COMPANY_SIZE,
    INDUSTRY_SEGMENT,
    BASE_AGE,
    STATE,
    REGION_NAME
FROM fs_cadastral_state;
