CREATE OR REPLACE TABLE `project-f1079166-4703-4cc3-975.trusted_data.trusted_people` 
PARTITION BY DATE_TRUNC(data_sinistro, MONTH)
AS
SELECT
    id_sinistro,
    id_pessoa,
    id_veiculo,
    cod_ibge,
    
    -- Padronizacao de textos e remocao de espaços extras
    UPPER(TRIM(municipio)) AS municipio,
    UPPER(TRIM(regiao_administrativa)) AS regiao_administrativa,
    UPPER(TRIM(tipo_via)) AS tipo_via,
    
    -- Tratamento de termos "NAO DISPONIVEL" ou nulos para padronizar
    COALESCE(NULLIF(UPPER(TRIM(tipo_veiculo_vitima)), 'NAO DISPONIVEL'), null) AS tipo_veiculo_vitima,
    COALESCE(NULLIF(UPPER(TRIM(tipo_de_vitima)), 'NAO DISPONIVEL'), null) AS tipo_de_vitima,
    --COALESCE(NULLIF(UPPER(TRIM(modo_transporte_vitima)), 'NAO DISPONIVEL'), null) AS modo_transporte_vitima, -- campo redundante com tipo_veiculo_vitima
    COALESCE(NULLIF(UPPER(TRIM(sexo)), 'NAO DISPONIVEL'), null) AS sexo,
    
    idade,
    
    faixa_etaria_demografica,
    --faixa_etaria_legal, -- reducao de informacoes para modelo
    
    -- Tratamento de profissoes nulas, não disponíveis e redudantes
    CASE 
        -- Transporte e Logística
        WHEN UPPER(TRIM(profissao)) LIKE '%MOTORISTA%' 
          OR UPPER(TRIM(profissao)) LIKE '%MOTO-BOY%' 
          OR UPPER(TRIM(profissao)) LIKE '%MOTOCICLISTA%' 
          OR UPPER(TRIM(profissao)) LIKE '%ENTREGADOR%' 
          OR UPPER(TRIM(profissao)) LIKE '%CAMINHONEIRO%' 
          OR UPPER(TRIM(profissao)) LIKE '%TAXISTA%' THEN 'TRANSPORTE / LOGÍSTICA'
        
        -- Construção Civil e Prestadores
        WHEN UPPER(TRIM(profissao)) LIKE '%PEDREIRO%' 
          OR UPPER(TRIM(profissao)) LIKE '%CONSTRUTOR%' 
          OR UPPER(TRIM(profissao)) LIKE '%ELETRICISTA%' 
          OR UPPER(TRIM(profissao)) LIKE '%PINTOR%' 
          OR UPPER(TRIM(profissao)) LIKE '%CARPINTEIRO%' 
          OR UPPER(TRIM(profissao)) LIKE '%MARCENEIRO%' THEN 'PRESTADOR DE SERVIÇO'
        
        -- Segurança Pública e Privada
        WHEN UPPER(TRIM(profissao)) LIKE '%POLICIAL%' 
          OR UPPER(TRIM(profissao)) LIKE '%GUARDA%' 
          OR UPPER(TRIM(profissao)) LIKE '%VIGILANTE%' 
          OR UPPER(TRIM(profissao)) LIKE '%SEGURANCA%' THEN 'SEGURANÇA'
        
        -- Comércio
        WHEN UPPER(TRIM(profissao)) LIKE '%VENDEDOR%' 
          OR UPPER(TRIM(profissao)) LIKE '%COMERCIANTE%' 
          OR UPPER(TRIM(profissao)) LIKE '%EMPRESARIO%' THEN 'COMÉRCIO'
        
        -- Autônomos
        WHEN UPPER(TRIM(profissao)) LIKE '%AUTONOMO%' THEN 'AUTÔNOMO'
        
        -- Saúde
        WHEN UPPER(TRIM(profissao)) LIKE '%MEDICO%' 
          OR UPPER(TRIM(profissao)) LIKE '%ENFERMEIRO%' 
          OR UPPER(TRIM(profissao)) LIKE '%FISIOTERAPEUTA%' 
          OR UPPER(TRIM(profissao)) LIKE '%FARMACEUTICO%' THEN 'SAÚDE'
        
        -- Estudantes
        WHEN UPPER(TRIM(profissao)) LIKE '%ESTUDANTE%' THEN 'ESTUDANTE'
        
        -- Aposentados e Pensionistas
        WHEN UPPER(TRIM(profissao)) LIKE '%APOSENTADO%' 
          OR UPPER(TRIM(profissao)) LIKE '%PENSIONISTA%' THEN 'APOSENTADO'
        
        -- Serviços Domésticos
        WHEN UPPER(TRIM(profissao)) LIKE '%DOMESTICA%' 
          OR UPPER(TRIM(profissao)) LIKE '%DO LAR%' 
          OR UPPER(TRIM(profissao)) LIKE '%FAXINEIRO%' THEN 'SERVIÇOS DOMÉSTICOS'
        
        -- Desempregados
        WHEN UPPER(TRIM(profissao)) LIKE '%DESEMPREGADO%' THEN 'DESEMPREGADO'
        
        -- Não informados ou nulos
        WHEN profissao IS NULL 
          OR UPPER(TRIM(profissao)) IN ('NÃO INFORMADO', 'NAO DISPONIVEL', '-') THEN null
        
        -- Demais profissões que aparecem em menor volume
        ELSE 'OUTRAS OCUPAÇÕES'
    END AS categoria_profissao,
    
    -- Mantendo grau de instrucao tratado
    COALESCE(UPPER(TRIM(grau_de_instrucao)), null) AS grau_de_instrucao,
    
    -- Tratamento de nacionalidade para redução de cardinalidade
    CASE 
        -- Agrupa todas as variações de brasileiro
        WHEN UPPER(TRIM(nacionalidade)) IN ('BRASILEIRA', 'BRASILEIRO', 'BRAS', 'BRASILEIRA_EUA') THEN 'BRASILEIRA'
        
        -- Agrupa nulos, vazios ou termos inválidos
        WHEN nacionalidade IS NULL 
          OR UPPER(TRIM(nacionalidade)) IN ('NÃO INFORMADO', 'NAO DISPONIVEL', 'INEXISTE', '-', '') THEN null
        
        -- Demais países / nacionalidades viram o grupo de estrangeiros
        ELSE 'ESTRANGEIRA'
    END AS nacionalidade,
    
    -- Datas e campos temporais
    data_sinistro, -- remocao dos campos ano_sinistro, mes_sinistro, dia_sinistro e ano_mes_sinistro para redução de informacoes no modelo

    UPPER(TRIM(gravidade_lesao)) AS gravidade_lesao,

    -- Criacao da variavel alvo (Target)
    CASE 
        WHEN UPPER(TRIM(gravidade_lesao)) = 'FATAL' OR data_obito IS NOT NULL THEN TRUE 
        ELSE FALSE
    END AS foi_fatal,

    data_obito, -- remocao dos campos ano_obito, mes_obito, dia_obito e ano_mes_obito para redução de informacoes no modelo
    
    COALESCE(NULLIF(UPPER(TRIM(local_obito)), 'NAO DISPONIVEL'), null) AS local_obito,
    COALESCE(NULLIF(UPPER(TRIM(local_via)), 'NAO DISPONIVEL'), null) AS local_via,

    tempo_sinistro_obito AS dias_para_obito

FROM `project-f1079166-4703-4cc3-975.raw_data.raw_people`;