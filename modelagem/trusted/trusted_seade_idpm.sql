CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_ipdm`
PARTITION BY data_ano_referencia
AS
SELECT
    cod_ibge,
    UPPER(TRIM(Municipio)) AS municipio,
    Ano AS ano_original,
    
    -- Conversão do ano para o formato padrão de data (YYYY-01-01)
    SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(CAST(Ano AS STRING), '-01-01')) AS data_ano_referencia,
    
    MAX(CASE WHEN UPPER(TRIM(Tipo)) = 'RIQUEZA' THEN SAFE_CAST(Valor AS FLOAT64) END) AS ipdm_riqueza,
    MAX(CASE WHEN UPPER(TRIM(Tipo)) = 'ESCOLARIDADE' THEN SAFE_CAST(Valor AS FLOAT64) END) AS ipdm_escolaridade,
    MAX(CASE WHEN UPPER(TRIM(Tipo)) = 'LONGEVIDADE' THEN SAFE_CAST(Valor AS FLOAT64) END) AS ipdm_longevidade,
    MAX(CASE WHEN UPPER(TRIM(Tipo)) = 'IPDM' THEN SAFE_CAST(Valor AS FLOAT64) END) AS ipdm_geral

FROM `project-f1079166-4703-4cc3-975.raw_data.raw_seade_idpm`
GROUP BY ALL
