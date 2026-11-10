CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.refined_data_bi.dim_tempo`
AS
SELECT
  data_sinistro,
  dia_da_semana,
  turno
FROM
  `project-f1079166-4703-4cc3-975.trusted_data.trusted_accidents`
WHERE
  data_sinistro  is not null
;

CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.refined_data_bi.dim_localizacao` 
AS
SELECT distinct
  GENERATE_UUID() AS sk_localizacao,
  cod_ibge,
  municipio,
  regiao_administrativa,
  administracao,
  conservacao,
  circunscricao,
  tipo_via,
  logradouro,
  tipo_local,
  latitude,
  longitude
FROM
  `project-f1079166-4703-4cc3-975.trusted_data.trusted_accidents`
;

CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.refined_data_bi.fct_acidente` 
AS
SELECT distinct
  id_sinistro,
  id_pessoa,
  id_veiculo,
  tp_sinistro_primario,
  flg_atrop_pedestre,
  flg_atrop_vitima_fora_veic,
  flg_colisao_frontal,
  flg_colisao_lateral,
  flg_colisao_transversal,
  flg_colisao_outros,
  flg_choque,
  flg_atrop_animal,
  flg_capotamento,
  flg_engavetamento,
  flg_tombamento,
  flg_outros,
  qtd_pedestre, 
  qtd_bicicleta, 
  qtd_motocicleta, 
  qtd_automovel, 
  qtd_onibus, 
  qtd_caminhao, 
  qtd_veic_outros, 
  qtd_gravidade_fatal, 
  qtd_gravidade_grave, 
  qtd_gravidade_leve, 
  qtd_gravidade_ileso
FROM
  `project-f1079166-4703-4cc3-975.trusted_data.trusted_accidents`
;

CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.refined_data_bi.dim_pessoa` 
AS
SELECT DISTINCT
  id_pessoa,
  tipo_de_pessoa,
  tipo_veiculo_pessoa,
  sexo,
  idade,
  faixa_etaria_demografica,
  categoria_profissao,
  grau_de_instrucao,
  nacionalidade
FROM 
  `project-f1079166-4703-4cc3-975.trusted_data.trusted_people`
WHERE id_pessoa IS NOT NULL;

CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.refined_data_bi.dim_veiculo`
AS
SELECT DISTINCT
  id_veiculo,
  marca_modelo,
  ano_fab,
  ano_modelo,
  cor_veiculo,
  tipo_veiculo
FROM 
  `project-f1079166-4703-4cc3-975.trusted_data.trusted_vehicles`
WHERE id_veiculo IS NOT NULL; 