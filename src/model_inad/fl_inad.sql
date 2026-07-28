WITH datas AS (
    SELECT explode(
        sequence(
            DATE '2018-10-01',
            DATE '2021-06-01',
            interval 1 month
        )
    ) AS DATA_REF
)

SELECT
    p.ID_DOCUMENTO,
    p.ID_CLIENTE,
    d.DATA_REF,
    CASE
        WHEN DATEDIFF(p.DATA_PAGAMENTO, p.DATA_VENCIMENTO) >= 5 THEN 1
        ELSE 0
    END AS FL_INAD
FROM credit_score.data.pagamentos p
JOIN datas d
    ON p.SAFRA_REF < d.DATA_REF;
