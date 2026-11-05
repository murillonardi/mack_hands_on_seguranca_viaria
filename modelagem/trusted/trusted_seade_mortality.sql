CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_mortality`
PARTITION BY data_ano_referencia
AS
WITH prep AS (
  SELECT 
    SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(CAST(ano AS STRING), '-01-01')) AS data_ano_referencia,
    cod_ibge, 
    COALESCE(obitos_0a14, 0) AS obitos_0a14,
    COALESCE(obitos_15a29, 0) AS obitos_15a29,
    COALESCE(obitos_30a44, 0) AS obitos_30a44,
    COALESCE(obitos_45a59, 0) AS obitos_45a59,
    COALESCE(`obitos_60e+`, 0) AS obitos_60_plus,
    COALESCE(obitos_ignorado, 0) AS obitos_ignorado,
    COALESCE(obitos_total, 0) AS obitos_total,
    COALESCE(pop_0a14, 0) AS pop_0a14,
    COALESCE(pop_15a29, 0) AS pop_15a29,
    COALESCE(pop_30a44, 0) AS pop_30a44,
    COALESCE(pop_45a59, 0) AS pop_45a59,
    COALESCE(`pop_60e+`, 0) AS pop_60_plus,
    COALESCE(pop_total, 0) AS pop_total,
    COALESCE(mx_0a14, 0.0) AS mx_0a14,
    COALESCE(mx_15a29, 0.0) AS mx_15a29,
    COALESCE(mx_30a44, 0.0) AS mx_30a44,
    COALESCE(mx_45a59, 0.0) AS mx_45a59,
    COALESCE(`mx_60e+`, 0.0) AS mx_60_plus,
    COALESCE(mx_total, 0.0) AS mx_total
  FROM 
    `project-f1079166-4703-4cc3-975.raw_data.raw_seade_mortality`
)

SELECT * FROM prep
WHERE data_ano_referencia >= '2014-01-01' -- recupera somente a partir de 2014

