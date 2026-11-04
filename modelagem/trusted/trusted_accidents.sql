CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.trusted_data.trusted_accidents`
PARTITION BY DATE_TRUNC(data_sinistro, MONTH)
AS
SELECT
    id_sinistro,
    
    -- Padronização do tipo de registro
    UPPER(TRIM(tipo_registro)) AS tipo_registro,
    
    -- Campos temporais padronizados
    data_sinistro, -- remocao de campos redundantes: ano_sinistro,mes_sinistro,dia_sinistro,ano_mes_sinistro, dia_da_semana
    hora_sinistro,
    UPPER(TRIM(dia_da_semana)) AS dia_da_semana,
    
    -- Padronização de turno
    COALESCE(NULLIF(UPPER(TRIM(turno)), 'NAO DISPONIVEL'), null) AS turno,
    
    -- Localização e Vias
    UPPER(TRIM(logradouro)) AS logradouro,
    COALESCE(NULLIF(UPPER(TRIM(tipo_via)), 'NAO DISPONIVEL'), null) AS tipo_via,
    COALESCE(NULLIF(UPPER(TRIM(tipo_local)), 'NAO DISPONIVEL'), null) AS tipo_local,
    
    -- Coordenadas geográficas
    latitude,
    longitude,
    
    cod_ibge,
    UPPER(TRIM(municipio)) AS municipio,
    UPPER(TRIM(regiao_administrativa)) AS regiao_administrativa,
    
    COALESCE(NULLIF(UPPER(TRIM(administracao)), 'NAO DISPONIVEL'), null) AS administracao,
    UPPER(TRIM(conservacao)) AS conservacao,
    COALESCE(NULLIF(UPPER(TRIM(circunscricao)), 'NAO DISPONIVEL'), null) AS circunscricao,
    
    -- Tipologia principal do sinistro
    COALESCE(NULLIF(UPPER(TRIM(tp_sinistro_primario)), 'NAO DISPONIVEL'), null) AS tp_sinistro_primario,
    
    -- Conversão de nulos para 0 nas contagens de veículos/envolvidos
    COALESCE(qtd_pedestre, 0) AS qtd_pedestre,
    COALESCE(qtd_bicicleta, 0) AS qtd_bicicleta,
    COALESCE(qtd_motocicleta, 0) AS qtd_motocicleta,
    COALESCE(qtd_automovel, 0) AS qtd_automovel,
    COALESCE(qtd_onibus, 0) AS qtd_onibus,
    COALESCE(qtd_caminhao, 0) AS qtd_caminhao,
    COALESCE(qtd_veic_outros, 0) + COALESCE(qtd_veic_nao_disponivel, 0) AS qtd_veic_outros,
    COALESCE(qtd_veic_nao_disponivel, 0) AS qtd_veic_nao_disponivel,
    
    -- Conversão de nulos para 0 nas contagens de gravidade
    COALESCE(qtd_gravidade_fatal, 0) AS qtd_gravidade_fatal,
    COALESCE(qtd_gravidade_grave, 0) AS qtd_gravidade_grave,
    COALESCE(qtd_gravidade_leve, 0) AS qtd_gravidade_leve,
    COALESCE(qtd_gravidade_ileso, 0) AS qtd_gravidade_ileso,
    COALESCE(qtd_gravidade_nao_disponivel, 0) AS qtd_gravidade_nao_disponivel,
    
    -- Conversão das flags de texto ('S' / NULL) para BOOLEANOS REAIS (TRUE / FALSE)
    IF(UPPER(TRIM(tp_sinistro_atrop_pedestre)) = 'S', TRUE, FALSE) AS flg_atrop_pedestre,
    IF(UPPER(TRIM(tp_sinistro_atrop_vitima_fora_veic)) = 'S', TRUE, FALSE) AS flg_atrop_vitima_fora_veic,
    IF(UPPER(TRIM(tp_sinistro_colisao_frontal)) = 'S', TRUE, FALSE) AS flg_colisao_frontal,
    IF(UPPER(TRIM(tp_sinistro_colisao_lateral)) = 'S', TRUE, FALSE) AS flg_colisao_lateral,
    IF(UPPER(TRIM(tp_sinistro_colisao_transversal)) = 'S', TRUE, FALSE) AS flg_colisao_transversal,
    IF(UPPER(TRIM(tp_sinistro_colisao_outros)) = 'S', TRUE, FALSE) AS flg_colisao_outros,
    IF(UPPER(TRIM(tp_sinistro_choque)) = 'S', TRUE, FALSE) AS flg_choque,
    IF(UPPER(TRIM(tp_sinistro_atrop_animal)) = 'S', TRUE, FALSE) AS flg_atrop_animal,
    IF(UPPER(TRIM(tp_sinistro_capotamento)) = 'S', TRUE, FALSE) AS flg_capotamento,
    IF(UPPER(TRIM(tp_sinistro_engavetamento)) = 'S', TRUE, FALSE) AS flg_engavetamento,
    IF(UPPER(TRIM(tp_sinistro_tombamento)) = 'S', TRUE, FALSE) AS flg_tombamento,
    IF(UPPER(TRIM(tp_sinistro_outros)) = 'S', TRUE, FALSE) AS flg_outros,
    IF(UPPER(TRIM(tp_sinistro_nao_disponivel)) = 'S', TRUE, FALSE) AS flg_nao_disponivel

FROM `project-f1079166-4703-4cc3-975.raw_data.raw_accidents`;