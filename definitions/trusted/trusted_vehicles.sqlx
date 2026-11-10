CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.trusted_data.trusted_vehicles`
PARTITION BY DATE_TRUNC(data_sinistro, MONTH)
AS
SELECT
    id_sinistro,
    id_veiculo,
    
    -- Padronização e limpeza da marca e modelo
    COALESCE(NULLIF(UPPER(TRIM(marca_modelo)), 'NAO DISPONIVEL'), null) AS marca_modelo,
    
    ano_fab,
    ano_modelo,
    
    -- Padronização da cor do veículo, unificação de maiúsculas/minúsculas tratamento de nulos
    CASE 
        -- BRANCO / BRANCA
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'BRANC%' THEN 'BRANCA'
        
        -- PRETO / PRETA
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'PRET%' THEN 'PRETA'
        
        -- PRATA
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'PRAT%' THEN 'PRATA'
        
        -- CINZA (incluindo variações de frotas e tons)
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'CINZ%' THEN 'CINZA'
        
        -- VERMELHO / VERMELHA
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'VERMELH%' THEN 'VERMELHA'
        
        -- AZUL
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'AZUL%' THEN 'AZUL'
        
        -- VERDE
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'VERD%' THEN 'VERDE'
        
        -- AMARELO / AMARELA
        WHEN UPPER(TRIM(cor_veiculo)) LIKE 'AMAREL%' THEN 'AMARELO'
        
        -- Demais cores bem definidas na base
        WHEN UPPER(TRIM(cor_veiculo)) IN ('BEGE', 'MARROM', 'ROSA', 'ROXA', 'LARANJA', 'DOURADA', 'GRENA') THEN UPPER(TRIM(cor_veiculo))
        
        -- Casos especiais, fantasias, camuflagens ou múltiplos tons
        WHEN UPPER(TRIM(cor_veiculo)) IN ('FANTASIA', 'VERMELHA/PRETA', 'CIN/VER/PRE', 'CAMUFLADO URBANO', 'CAMUFLADO RURAL', 'BRANCA/VERMELHA', 'BRANCA/CINZA BANDEIR', 'BRANCA/CINZA ESCURO') THEN 'MULTICOLORIDA / FANTASIA'
        
        -- 11. Nulos, não informados ou sem identificação
        WHEN cor_veiculo IS NULL 
          OR UPPER(TRIM(cor_veiculo)) IN ('NÃO INFORMADO', 'NAO DISPONIVEL', 'SEM IDENTIFICAÇÃO', 'SEM IDENTIFICAÃO', '-', '') THEN null
          
        -- Qualquer outro caso residual
        ELSE 'OUTRAS'
    END AS cor_veiculo,
    
    -- Padronização do tipo de veículo
    COALESCE(NULLIF(UPPER(TRIM(tipo_veiculo)), 'NAO DISPONIVEL'), null) AS tipo_veiculo,
    
    -- Campos temporais padronizados
    data_sinistro, -- remocacao de campos redundantes: ano_sinistro, mes_sinistro, ano_mes_sinistro

FROM `project-f1079166-4703-4cc3-975.raw_data.raw_vehicles`;