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

        -- grau_de_instrucao
        COUNT(DISTINCT CASE WHEN grau_de_instrucao = 'BÁSICO' THEN id_pessoa END) AS qtd_ensino_basico,
        COUNT(DISTINCT CASE WHEN grau_de_instrucao = 'MÉDIO' THEN id_pessoa END) AS qtd_ensino_medio,
        COUNT(DISTINCT CASE WHEN grau_de_instrucao = 'SUPERIOR' THEN id_pessoa END) AS qtd_ensino_superior,
        
        -- nacionalidade
        COUNT(DISTINCT CASE WHEN nacionalidade = 'BRASILEIRA' THEN id_pessoa END) AS qtd_nacionalidade_brasileira,
        COUNT(DISTINCT CASE WHEN nacionalidade = 'ESTRANGEIRA' THEN id_pessoa END) AS qtd_nacionalidade_estrangeira,
        
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
        COUNT(DISTINCT CASE WHEN UPPER(TRIM(tipo_veiculo)) LIKE '%MOTO%' THEN id_veiculo END) AS qtd_veiculos_moto,
        COUNT(DISTINCT CASE WHEN UPPER(TRIM(tipo_veiculo)) LIKE '%AUTOMOVEL%' OR UPPER(TRIM(tipo_veiculo)) LIKE '%CARRO%' THEN id_veiculo END) AS qtd_veiculos_automovel
    FROM 
        `project-f1079166-4703-4cc3-975.refined_data_bi.dim_veiculo`
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
        p.* except (id_sinistro),
        v.* except(id_sinistro)
    FROM 
        `project-f1079166-4703-4cc3-975.refined_data_bi.fct_acidente` f
    INNER JOIN 
      `project-f1079166-4703-4cc3-975.refined_data_bi.dim_localizacao` l ON f.id_sinistro = l.id_sinistro
    LEFT JOIN 
        `project-f1079166-4703-4cc3-975.refined_data_bi.dim_tempo` t ON f.data_sinistro = t.data_sinistro
    LEFT JOIN 
        pessoas_agregadas_sinistro p ON f.id_sinistro = p.id_sinistro
    LEFT JOIN 
        veiculos_agregados_sinistro v ON f.id_sinistro = v.id_sinistro
),

-- Padroniza o ano da base de IPDM (convertendo para INT64 caso necessário)
ipdm_padronizado AS (
    SELECT
        cod_ibge,
        municipio,
        CAST(ano_original AS INT64) AS ano,
        ipdm_riqueza,
        ipdm_escolaridade,
        ipdm_longevidade,
        ipdm_geral
    FROM 
      `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_ipdm`
),
-- Padroniza o ano da mortalidade extraindo o ano da data (YYYY-MM-DD)
mortalidade_padronizada AS (
    SELECT
        cod_ibge,
        CAST(EXTRACT(YEAR FROM data_ano_referencia) AS INT64) AS ano,
        pop_total AS numero_habitantes,
        mx_15a29,
        mx_total
    FROM 
      `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_mortality`
),

agregado_por_municipio AS (
    -- Agrega anualmente por município gerando as proporções relativas exigidas
    SELECT
        cod_ibge,
        EXTRACT(YEAR FROM data_sinistro) AS ano,
        COUNT(DISTINCT id_sinistro) AS num_acidentes_regiao,
        
        -- Proporções de veículos (% do total)
        SAFE_DIVIDE(SUM(qtd_veiculos_moto), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_moto,
        SAFE_DIVIDE(SUM(qtd_veiculos_automovel), SUM(NULLIF(total_veiculos_envolvidos, 0))) AS pct_veiculos_automovel,
        
        -- Proporções demográficas e de instrução (% do total de pessoas)
        SAFE_DIVIDE(SUM(qtd_pedestre), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_pessoa_pedestre,
        SAFE_DIVIDE(SUM(qtd_passageiro), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_pessoa_pedestre,
        SAFE_DIVIDE(SUM(qtd_condutor), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_pessoa_pedestre,
        SAFE_DIVIDE(SUM(qtd_pessoa_outros), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_pessoa_pedestre,

        SAFE_DIVIDE(SUM(qtd_nacionalidade_brasileira), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_nacionalidade_brasileira,
        SAFE_DIVIDE(SUM(qtd_nacionalidade_estrangeira), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_nacionalidade_estrangeira,
        SAFE_DIVIDE(SUM(qtd_ensino_basico), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_ensino_basico,
        SAFE_DIVIDE(SUM(qtd_ensino_superior), SUM(NULLIF(total_pessoas_envolvidas, 0))) AS pct_ensino_superior,
        
        -- Proporção temporal (ex: acidentes no turno da noite)
        SAFE_DIVIDE(
            COUNT(DISTINCT CASE WHEN UPPER(TRIM(turno)) LIKE '%NOITE%' OR UPPER(TRIM(turno)) LIKE '%NOTURNO%' THEN id_sinistro END),
            COUNT(DISTINCT id_sinistro)
        ) AS pct_acidentes_noite,
        
        -- Numero de acidentes fatais
        SUM(CASE WHEN qtd_gravidade_fatal > 0 THEN 1 ELSE 0 END) AS num_acidentes_fatais
    FROM 
        sinistros_completos
    GROUP BY 
      ALL
),
populacao_base AS (
    -- Extrai a população oficial da base de mortalidade da SEADE
    SELECT
        cod_ibge,
        CAST(EXTRACT(YEAR FROM data_ano_referencia) AS INT64) AS ano,
        pop_total AS numero_habitantes
    FROM 
        `project-f1079166-4703-4cc3-975.trusted_data.trusted_seade_mortality`
)
SELECT
    -- Chaves e Contexto
    COALESCE(a.cod_ibge, i.cod_ibge, m.cod_ibge) AS cod_ibge,
    COALESCE(a.ano, i.ano, pop.ano) AS ano,
    SAFE.PARSE_DATE('%Y-%m-%d', CONCAT(CAST(COALESCE(a.ano, i.ano, pop.ano) AS STRING), '-01-01')) AS data_referencia,
    
    -- 1. Variáveis brutas exigidas (população e acidentes para normalização em Python)
    COALESCE(pop.numero_habitantes, 0) AS numero_habitantes,
    COALESCE(a.num_acidentes_regiao, 0) AS num_acidentes_regiao,
    
    -- 2. Índice de fatalidade proporcional à população (por 100k habitantes)
    SAFE_DIVIDE(COALESCE(a.num_acidentes_fatais, 0), COALESCE(pop.numero_habitantes, 1)) * 100000 AS indice_fatalidade_proporcional_100k,
    
    -- 3. Features relativas de Veículos (% do total)
    COALESCE(a.pct_veiculos_moto, 0.0) AS pct_veiculos_moto,
    COALESCE(a.pct_veiculos_automovel, 0.0) AS pct_veiculos_automovel,
    
    -- 4. Features relativas de Pessoas / Demografia / Instrução (% do total)
    COALESCE(a.pct_nacionalidade_estrangeira, 0.0) AS pct_nacionalidade_estrangeira,
    COALESCE(a.pct_ensino_basico, 0.0) AS pct_ensino_basico,
    COALESCE(a.pct_ensino_superior, 0.0) AS pct_ensino_superior,
    
    -- 5. Features relativas de Tempo (% do total)
    COALESCE(a.pct_acidentes_noite, 0.0) AS pct_acidentes_noite,
    
    -- 6. Dimensões do IPDM (Socioeconômico)
    i.ipdm_riqueza,
    i.ipdm_escolaridade,
    i.ipdm_longevidade,
    i.ipdm_geral,
    
    -- 7. Saúde / Mortalidade SEADE
    m.mx_15a29,
    m.mx_total

FROM 
    agregado_por_municipio a
FULL OUTER JOIN 
    ipdm_padronizado i
    ON a.cod_ibge = i.cod_ibge AND a.ano = i.ano
FULL OUTER JOIN 
    mortalidade_padronizada m
    ON COALESCE(a.cod_ibge, i.cod_ibge) = m.cod_ibge AND COALESCE(a.ano, i.ano) = m.ano
LEFT JOIN 
    populacao_base pop
    ON COALESCE(a.cod_ibge, i.cod_ibge) = pop.cod_ibge AND COALESCE(a.ano, i.ano) = pop.ano;