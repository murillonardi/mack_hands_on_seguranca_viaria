CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.refined_data_ml.refined_ml_features`
PARTITION BY DATE_TRUNC(data_referencia, YEAR)
AS
WITH pessoas_agregadas_sinistro AS (
  -- Agrega os atributos da dim_pessoa por sinistro 
  SELECT
    id_sinistro,
    COUNT(DISTINCT id_pessoa) AS total_pessoas_envolvidas,

    -- tipo_de_pessoa
    COUNT(DISTINCT CASE WHEN tipo_de_pessoa = 'PEDESTRE' THEN id_pessoa END) AS qtd_pedestre,
    COUNT(DISTINCT CASE WHEN tipo_de_pessoa = 'PASSAGEIRO' THEN id_pessoa END) AS qtd_passageiro,
    COUNT(DISTINCT CASE WHEN tipo_de_pessoa = 'CONDUTOR' THEN id_pessoa END) AS qtd_condutor,
    COUNT(DISTINCT CASE WHEN tipo_de_pessoa is null THEN id_pessoa END) AS qtd_pessoa_outros,

    -- sexo
    COUNT(DISTINCT CASE WHEN sexo = 'MASCULINO' THEN id_pessoa END) AS qtd_sexo_masculino,
    COUNT(DISTINCT CASE WHEN sexo = 'FEMININO' THEN id_pessoa END) AS qtd_sexo_feminino,
    COUNT(DISTINCT CASE WHEN sexo is null THEN id_pessoa END) AS qtd_sexo_nao_disponivel,

    -- faixa_etaria no mesmo grão que a base de mortalidade
    COUNT(DISTINCT CASE WHEN idade BETWEEN 0 AND 14 THEN id_pessoa END) AS qtd_idade_0a14,
    COUNT(DISTINCT CASE WHEN idade BETWEEN 15 AND 29 THEN id_pessoa END) AS qtd_idade_15a29,
    COUNT(DISTINCT CASE WHEN idade BETWEEN 30 AND 44 THEN id_pessoa END) AS qtd_idade_30a44,
    COUNT(DISTINCT CASE WHEN idade BETWEEN 45 AND 59 THEN id_pessoa END) AS qtd_idade_45a59,
    COUNT(DISTINCT CASE WHEN idade >= 60 THEN id_pessoa END) AS qtd_idade_60_plus,

    -- grau_de_instrucao
    COUNT(DISTINCT CASE WHEN grau_de_instrucao = 'BÁSICO' THEN id_pessoa END) AS qtd_ensino_basico,
    COUNT(DISTINCT CASE WHEN grau_de_instrucao = 'MÉDIO' THEN id_pessoa END) AS qtd_ensino_medio,
    COUNT(DISTINCT CASE WHEN grau_de_instrucao = 'SUPERIOR' THEN id_pessoa END) AS qtd_ensino_superior,
        
    -- nacionalidade
    COUNT(DISTINCT CASE WHEN nacionalidade = 'BRASILEIRA' THEN id_pessoa END) AS qtd_nacionalidade_brasileira,
    COUNT(DISTINCT CASE WHEN nacionalidade = 'ESTRANGEIRA' THEN id_pessoa END) AS qtd_nacionalidade_estrangeira,
    COUNT(DISTINCT CASE WHEN nacionalidade is null THEN id_pessoa END) AS qtd_nacionalidade_nao_disponivel,
        
  FROM 
    `project-f1079166-4703-4cc3-975.refined_data_bi.dim_pessoa`
  GROUP BY 
    id_sinistro
),

veiculos_agregados_sinistro AS (
  -- Agrega os atributos da dim_veiculo por sinistro
  SELECT
    id_sinistro,
    COUNT(DISTINCT id_veiculo) AS total_veiculos_envolvidos,

    -- tipo_veiculo
    COUNT(DISTINCT CASE WHEN tipo_veiculo = 'AUTOMOVEL' THEN id_veiculo END) AS qtd_veiculos_carro,
    COUNT(DISTINCT CASE WHEN tipo_veiculo = 'BICICLETA' THEN id_veiculo END) AS qtd_veiculos_bicicleta,
    COUNT(DISTINCT CASE WHEN tipo_veiculo = 'CAMINHAO' THEN id_veiculo END) AS qtd_veiculos_caminhao,
    COUNT(DISTINCT CASE WHEN tipo_veiculo = 'MOTOCICLETA' THEN id_veiculo END) AS qtd_veiculos_motocicleta,
    COUNT(DISTINCT CASE WHEN tipo_veiculo = 'ONIBUS' THEN id_veiculo END) AS qtd_veiculos_onibus,
    COUNT(DISTINCT CASE WHEN tipo_veiculo = 'OUTROS' OR tipo_veiculo is null THEN id_veiculo END) AS qtd_veiculos_outros,

    -- idade_veiculo (calcula quantos anos o veiculo tinha no ano do acidente)
    COUNT(DISTINCT CASE WHEN (EXTRACT(YEAR FROM data_sinistro) - ano_fab) BETWEEN 0 AND 5 THEN id_veiculo END) AS qtd_frota_0a5,
    COUNT(DISTINCT CASE WHEN (EXTRACT(YEAR FROM data_sinistro) - ano_fab) BETWEEN 6 AND 10 THEN id_veiculo END) AS qtd_frota_6a10,
    COUNT(DISTINCT CASE WHEN (EXTRACT(YEAR FROM data_sinistro) - ano_fab) BETWEEN 11 AND 15 THEN id_veiculo END) AS qtd_frota_11a15,
    COUNT(DISTINCT CASE WHEN (EXTRACT(YEAR FROM data_sinistro) - ano_fab) BETWEEN 16 AND 20 THEN id_veiculo END) AS qtd_frota_16a20,
    COUNT(DISTINCT CASE WHEN (EXTRACT(YEAR FROM data_sinistro) - ano_fab) > 20 THEN id_veiculo END) AS qtd_frota_20_plus,
    COUNT(DISTINCT CASE WHEN ano_fab IS NULL THEN id_veiculo END) AS qtd_frota_idade_desconhecida
  FROM 
    `project-f1079166-4703-4cc3-975.refined_data_bi.dim_veiculo`
  INNER JOIN  
    `project-f1079166-4703-4cc3-975.refined_data_bi.fct_acidente`  USING(id_sinistro)
  GROUP BY 
    id_sinistro
),

sinistros_completos AS (
  -- Junta a Fato com as dimensões de tempo e os resumos de pessoas/veículos
  SELECT
    f.* except (qtd_pedestre),
    l.cod_ibge,
    t.turno,
    t.dia_da_semana,
    p.* except(id_sinistro),
    v.* except (id_sinistro)
  FROM 
    `project-f1079166-4703-4cc3-975.refined_data_bi.fct_acidente` f
  INNER JOIN 
    `project-f1079166-4703-4cc3-975.refined_data_bi.dim_localizacao` l USING(id_sinistro)
  LEFT JOIN 
    `project-f1079166-4703-4cc3-975.refined_data_bi.dim_tempo` t USING(id_sinistro,data_sinistro)
  LEFT JOIN 
    pessoas_agregadas_sinistro p USING(id_sinistro)
  LEFT JOIN 
    veiculos_agregados_sinistro v USING(id_sinistro)
  WHERE
    cod_ibge <> 3500000 -- municipio invalido
),

-- Padroniza o ano da base de IPDM
ipdm_original AS (
  SELECT
    cod_ibge,
    CAST(ano_original AS INT64) AS ano,
    ipdm_riqueza,
    ipdm_escolaridade,
    ipdm_longevidade,
    ipdm_geral
  FROM 
   `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_ipdm`
),

-- Padroniza o ano da base de mortalidade
mortalidade_padronizada AS (
  SELECT
    cod_ibge,
    CAST(EXTRACT(YEAR FROM data_ano_referencia) AS INT64) AS ano,
    pop_total,
    mx_0a14,
    mx_15a29,
    mx_30a44, 
    mx_45a59, 
    mx_60_plus,
    mx_total
  FROM 
   `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_mortality`
  WHERE
    CAST(EXTRACT(YEAR FROM data_ano_referencia) AS INT64) BETWEEN 2014 and 2024
    and cod_ibge <> 3500000 -- municipio invalido
),

-- Calcula ipdm para anos sem registro
ipdm_preenchido AS (
  SELECT
    m.cod_ibge,
    m.ano,
    
    -- Puxa o último valor válido (do ano par) para o ano ímpar adiante
    LAST_VALUE(i.ipdm_riqueza IGNORE NULLS) OVER(PARTITION BY m.cod_ibge ORDER BY m.ano ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ipdm_riqueza,
    LAST_VALUE(i.ipdm_escolaridade IGNORE NULLS) OVER(PARTITION BY m.cod_ibge ORDER BY m.ano ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ipdm_escolaridade,
    LAST_VALUE(i.ipdm_longevidade IGNORE NULLS) OVER(PARTITION BY m.cod_ibge ORDER BY m.ano ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ipdm_longevidade,
    LAST_VALUE(i.ipdm_geral IGNORE NULLS) OVER(PARTITION BY m.cod_ibge ORDER BY m.ano ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ipdm_geral
  FROM mortalidade_padronizada m
  LEFT JOIN ipdm_original i ON m.cod_ibge = i.cod_ibge AND m.ano = i.ano
),

agregado_por_municipio AS (
  -- Agrega anualmente por município gerando as proporções relativas exigidas
  SELECT
    cod_ibge,
    CAST(EXTRACT(YEAR FROM data_sinistro) AS INT64) AS ano,
    COUNT(DISTINCT id_sinistro) AS num_acidentes_regiao,

    -- PROPORÇÃO DE PESSOAS

    -- tipo_de_pessoa
    SAFE_DIVIDE(SUM(qtd_pedestre), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_pedestre,
    SAFE_DIVIDE(SUM(qtd_passageiro), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_passageiro,
    SAFE_DIVIDE(SUM(qtd_condutor), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_condutor,
    SAFE_DIVIDE(SUM(qtd_pessoa_outros), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_pessoa_outros,

    -- sexo
    SAFE_DIVIDE(SUM(qtd_sexo_masculino), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_sexo_masculino,
    SAFE_DIVIDE(SUM(qtd_sexo_feminino), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_sexo_feminino,
    SAFE_DIVIDE(SUM(qtd_sexo_nao_disponivel), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_sexo_nao_disponivel,

    -- faixa etaria
    SAFE_DIVIDE(SUM(qtd_idade_0a14), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_idade_0a14,
    SAFE_DIVIDE(SUM(qtd_idade_15a29), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_idade_15a29,
    SAFE_DIVIDE(SUM(qtd_idade_30a44), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_idade_30a44,
    SAFE_DIVIDE(SUM(qtd_idade_45a59), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_idade_45a59,
    SAFE_DIVIDE(SUM(qtd_idade_60_plus), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_idade_60_plus,
     
    -- grau de instrucao
    SAFE_DIVIDE(SUM(qtd_ensino_basico), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_ensino_basico,
    SAFE_DIVIDE(SUM(qtd_ensino_medio), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_ensino_medio,
    SAFE_DIVIDE(SUM(qtd_ensino_superior), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_ensino_superior,

    -- nacionalidade
    SAFE_DIVIDE(SUM(qtd_nacionalidade_brasileira), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_nacionalidade_brasileira,
    SAFE_DIVIDE(SUM(qtd_nacionalidade_estrangeira), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_nacionalidade_estrangeira,
    SAFE_DIVIDE(SUM(qtd_nacionalidade_nao_disponivel), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_nacionalidade_nao_disponivel,

    -- PROPORÇÃO DE VEICULOS

    -- tipo de veiculo
    SAFE_DIVIDE(SUM(qtd_veiculos_carro), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_carro,
    SAFE_DIVIDE(SUM(qtd_veiculos_bicicleta), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_bicicleta,
    SAFE_DIVIDE(SUM(qtd_veiculos_caminhao), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_caminhao,
    SAFE_DIVIDE(SUM(qtd_veiculos_motocicleta), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_motocicleta,
    SAFE_DIVIDE(SUM(qtd_veiculos_onibus), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_onibus,
    SAFE_DIVIDE(SUM(qtd_veiculos_outros), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_outros,
        
    -- idade veiculo
    SAFE_DIVIDE(SUM(qtd_frota_0a5), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_frota_0a5,
    SAFE_DIVIDE(SUM(qtd_frota_6a10), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_frota_6a10,
    SAFE_DIVIDE(SUM(qtd_frota_11a15), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_frota_11a15,
    SAFE_DIVIDE(SUM(qtd_frota_16a20), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_frota_16a20,
    SAFE_DIVIDE(SUM(qtd_frota_20_plus), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_frota_20_plus,
    
    -- PROPORCAO TEMPORAL
    
    -- turno
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN turno = 'MANHA' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidentes_manha,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN turno = 'TARDE' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidentes_tarde,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN turno = 'NOITE' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidentes_noite,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN turno = 'MADRUGADA' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidentes_madrugada,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN turno is null THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidentes_turno_nao_disponivel,


    -- PROPORCAO ATRIBUTOS DO ACIDENTE
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN tp_sinistro_primario = 'ATROPELAMENTO' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidente_primario_atropelamento,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN tp_sinistro_primario = 'CHOQUE' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidente_primario_choque,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN tp_sinistro_primario = 'COLISAO' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidente_primario_colisao,
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN tp_sinistro_primario = 'OUTROS' THEN id_sinistro END), COUNT(DISTINCT id_sinistro)
    ) AS pct_acidente_primario_outros,
    

    SAFE_DIVIDE(COUNTIF(flg_atrop_pedestre) + COUNTIF(flg_atrop_vitima_fora_veic), COUNT(id_sinistro)) AS pct_atropelamento_pedestre,
    SAFE_DIVIDE(COUNTIF(flg_colisao_frontal), COUNT(id_sinistro)) AS pct_colisao_frontal,
    SAFE_DIVIDE(COUNTIF(flg_colisao_lateral), COUNT(id_sinistro)) AS pct_colisao_lateral,
    SAFE_DIVIDE(COUNTIF(flg_colisao_transversal), COUNT(id_sinistro)) AS pct_colisao_transversal,
    SAFE_DIVIDE(COUNTIF(flg_capotamento), COUNT(id_sinistro)) AS pct_capotamento,

    SAFE_DIVIDE(COUNTIF(flg_choque), COUNT(id_sinistro)) AS pct_choque,
    SAFE_DIVIDE(COUNTIF(flg_atrop_animal), COUNT(id_sinistro)) AS pct_atrop_animal,
    SAFE_DIVIDE(COUNTIF(flg_engavetamento), COUNT(id_sinistro)) AS pct_engavetamento,
    SAFE_DIVIDE(COUNTIF(flg_tombamento), COUNT(id_sinistro)) AS pct_tombamento,
    
    SAFE_DIVIDE(SUM(qtd_motocicleta), COUNT(id_sinistro)) AS pct_envolvem_motocicleta,
    SAFE_DIVIDE(SUM(qtd_bicicleta), COUNT(id_sinistro)) AS pct_envolvem_bicicleta,
    SAFE_DIVIDE(SUM(qtd_automovel), COUNT(id_sinistro)) AS pct_envolvem_carro,
    SAFE_DIVIDE(SUM(qtd_onibus), COUNT(id_sinistro)) AS pct_envolvem_onibus,
    SAFE_DIVIDE(SUM(qtd_caminhao), COUNT(id_sinistro)) AS pct_envolvem_caminhao,

    SAFE_DIVIDE(SUM(qtd_gravidade_fatal), COUNT(id_sinistro)) AS pct_acidentes_fatais,
    SAFE_DIVIDE(SUM(qtd_gravidade_grave), COUNT(id_sinistro)) AS pct_acidentes_graves,
    SAFE_DIVIDE(SUM(qtd_gravidade_leve), COUNT(id_sinistro)) AS pct_acidentes_leves,
    SAFE_DIVIDE(SUM(qtd_gravidade_ileso), COUNT(id_sinistro)) AS pct_acidentes_ilesos,
  FROM 
    sinistros_completos
  WHERE
    CAST(EXTRACT(YEAR FROM data_sinistro) AS INT64) BETWEEN 2015 AND 2024 -- base de 2014 do infosiga tem pouco dado
  GROUP BY ALL
)

SELECT
  COALESCE(a.cod_ibge, m.cod_ibge) AS cod_ibge,
  COALESCE(a.ano, m.ano) AS ano,
  a.* except(num_acidentes_regiao, ano, cod_ibge),
  SAFE_DIVIDE(a.num_acidentes_regiao, m.pop_total) * 100000 AS taxa_acidentes_100k,
  (SAFE_DIVIDE(a.num_acidentes_regiao, m.pop_total) * 100000) * a.pct_acidentes_fatais AS indice_fatalidade_proporcional_100k,

  -- Métricas do IPDM 
  ipdm_riqueza,
  ipdm_escolaridade,
  ipdm_longevidade,
  ipdm_geral,
  
  -- Métrics Mortalidade SEADE
  mx_0a14,
  mx_15a29,
  mx_30a44, 
  mx_45a59, 
  mx_60_plus,
  mx_total

FROM 
    agregado_por_municipio a
FULL OUTER JOIN 
    ipdm_preenchido i
    USING(ano,cod_ibge)
FULL OUTER JOIN 
    mortalidade_padronizada m
    USING(ano,cod_ibge)