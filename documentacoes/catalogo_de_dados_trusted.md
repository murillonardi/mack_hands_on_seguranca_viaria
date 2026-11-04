# 📊 Dicionário de Dados - Camada Trusted (InfoSiga / MBA)

Este repositório contém a documentação técnica e os metadados oficiais da camada **Trusted** da arquitetura medalhão para os dados de acidentes de trânsito (InfoSiga).

---

## 1. Tabela: `trusted_accidents`
> **Descrição:** Tabela Trusted padronizada com ocorrências de acidentes, coordenadas geográficas, contagem de veículos/vítimas e flags de tipologia.

| Nome do Campo | Tipo de Dado | Aceita Nulo | Descrição / Metadado |
| :--- | :--- | :---: | :--- |
| `id_sinistro` | `INT64` | SIM | Identificador único e chave primária do sinistro |
| `tipo_registro` | `STRING` | SIM | Tipo de registro do sinistro (ex: Sinistro Não Fatal, Fatal, Notificação) |
| `data_sinistro` | `DATE` | SIM | Data em que o sinistro ocorreu |
| `ano_sinistro` | `INT64` | SIM | Ano da ocorrência do sinistro |
| `mes_sinistro` | `INT64` | SIM | Mês da ocorrência do sinistro |
| `dia_sinistro` | `INT64` | SIM | Dia do mês da ocorrência |
| `hora_sinistro` | `STRING` | SIM | Horário em que o sinistro foi registrado |
| `ano_mes_sinistro` | `STRING` | SIM | Ano e Mês concatenados (YYYY-MM) |
| `dia_da_semana` | `STRING` | SIM | Dia da semana da ocorrência |
| `turno` | `STRING` | SIM | Periodo do dia (MANHA, TARDE, NOITE, MADRUGADA) |
| `logradouro` | `STRING` | SIM | Nome do logradouro/rua/avenida da ocorrência |
| `numero_logradouro` | `STRING` | SIM | Número aproximado ou altura do logradouro |
| `tipo_via` | `STRING` | SIM | Tipo da via (RODOVIA, VIA URBANA, etc.) |
| `tipo_local` | `STRING` | SIM | Tipo do local (CRUZAMENTO, PISTA CENTRAL, etc.) |
| `latitude` | `FLOAT64` | SIM | Coordenada geográfica de Latitude |
| `longitude` | `FLOAT64` | SIM | Coordenada geográfica de Longitude |
| `cod_ibge` | `INT64` | SIM | Código IBGE do município |
| `municipio` | `STRING` | SIM | Nome do município da ocorrência |
| `regiao_administrativa` | `STRING` | SIM | Região administrativa do Estado |
| `administracao` | `STRING` | SIM | Órgão ou entidade responsável pela administração da via |
| `conservacao` | `STRING` | SIM | Especificação detalhada da empresa/concessionária responsável pela via |
| `circunscricao` | `STRING` | SIM | Esfera de circunscrição da via (Municipal, Estadual ou Federal) |
| `tp_sinistro_primario` | `STRING` | SIM | Tipologia primária principal do sinistro |
| `qtd_pedestre` | `INT64` | SIM | Quantidade total de pedestres envolvidos |
| `qtd_bicicleta` | `INT64` | SIM | Quantidade total de bicicletas envolvidas |
| `qtd_motocicleta` | `INT64` | SIM | Quantidade total de motocicletas envolvidas |
| `qtd_automovel` | `INT64` | SIM | Quantidade total de automóveis envolvidos |
| `qtd_onibus` | `INT64` | SIM | Quantidade total de ônibus envolvidos |
| `qtd_caminhao` | `INT64` | SIM | Quantidade total de caminhões envolvidos |
| `qtd_veic_outros` | `INT64` | SIM | Quantidade de outros veículos envolvidos (consolidada com veículos não disponíveis) |
| `qtd_gravidade_fatal` | `INT64` | SIM | Quantidade de vítimas fatais no sinistro |
| `qtd_gravidade_grave` | `INT64` | SIM | Quantidade de vítimas com ferimentos graves |
| `qtd_gravidade_leve` | `INT64` | SIM | Quantidade de vítimas com ferimentos leves |
| `qtd_gravidade_ileso` | `INT64` | SIM | Quantidade de pessoas que saíram ilesas |
| `qtd_gravidade_nao_disponivel` | `INT64` | SIM | Quantidade de envolvidos sem gravidade especificada |
| `flg_atrop_pedestre` | `BOOL` | SIM | Indica se o sinistro envolveu atropelamento de pedestre |
| `flg_atrop_vitima_fora_veic` | `BOOL` | SIM | Indica se envolveu atropelamento de vítima fora do veículo |
| `flg_colisao_frontal` | `BOOL` | SIM | Indica se o sinistro envolveu colisão frontal |
| `flg_colisao_lateral` | `BOOL` | SIM | Indica se o sinistro envolveu colisão lateral |
| `flg_colisao_transversal` | `BOOL` | SIM | Indica se o sinistro envolveu colisão transversal |
| `flg_colisao_outros` | `BOOL` | SIM | Indica se envolveu outros tipos de colisão não especificados |
| `flg_choque` | `BOOL` | SIM | Indica se o sinistro envolveu choque contra obstáculo fixo |
| `flg_atrop_animal` | `BOOL` | SIM | Indica se envolveu atropelamento de animal |
| `flg_capotamento` | `BOOL` | SIM | Indica se o sinistro envolveu capotamento |
| `flg_engavetamento` | `BOOL` | SIM | Indica se envolveu engavetamento de múltiplos veículos |
| `flg_tombamento` | `BOOL` | SIM | Indica se o sinistro envolveu tombamento de veículo |
| `flg_outros` | `BOOL` | SIM | Indica se envolveu outras tipologias de sinistro |
| `flg_nao_disponivel` | `BOOL` | SIM | Indica quando a tipologia específica não estava disponível nos registros |

---

## 2. Tabela: `trusted_vehicles`
> **Descrição:** Tabela Trusted padronizada com dados individuais dos veículos envolvidos em acidentes.

| Nome do Campo | Tipo de Dado | Aceita Nulo | Descrição / Metadado |
| :--- | :--- | :---: | :--- |
| `id_sinistro` | `INT64` | SIM | Identificador único do sinistro (Chave estrangeira) |
| `id_veiculo` | `INT64` | SIM | Identificador único do veículo envolvido |
| `cod_ibge` | `INT64` | SIM | Código IBGE do município da ocorrência |
| `municipio` | `STRING` | SIM | Nome do município do registro |
| `regiao_administrativa` | `STRING` | SIM | Região administrativa da ocorrência |
| `tipo_via` | `STRING` | SIM | Tipo da via (RODOVIA, VIA URBANA, etc.) |
| `local_via` | `STRING` | SIM | Detalhe do trecho/local da via |
| `tipo_veiculo` | `STRING` | SIM | Categoria do veículo (Automóvel, Moto, Caminhão, etc.) |
| `marca_modelo` | `STRING` | SIM | Marca e modelo padronizados do veículo |
| `ano_fabricacao` | `INT64` | SIM | Ano de fabricação do veículo |
| `ano_modelo` | `INT64` | SIM | Ano do modelo do veículo |
| `cor` | `STRING` | SIM | Cor do veículo |
| `categoria` | `STRING` | SIM | Categoria de licenciamento ou uso do veículo |
| `data_sinistro` | `DATE` | SIM | Data em que o sinistro ocorreu |

---

## 3. Tabela: `trusted_people`
> **Descrição:** Tabela Trusted com perfil demográfico, gravidade e registros de envolvidos/vítimas nos sinistros.

| Nome do Campo | Tipo de Dado | Aceita Nulo | Descrição / Metadado |
| :--- | :--- | :---: | :--- |
| `id_sinistro` | `INT64` | SIM | Identificador único do sinistro (Chave estrangeira) |
| `id_pessoa` | `INT64` | SIM | Identificador único da pessoa envolvida |
| `id_veiculo` | `INT64` | SIM | Identificador do veículo associado à pessoa (se houver) |
| `cod_ibge` | `INT64` | SIM | Código IBGE do município |
| `municipio` | `STRING` | SIM | Município da ocorrência |
| `regiao_administrativa` | `STRING` | SIM | Região administrativa |
| `tipo_via` | `STRING` | SIM | Tipo da via |
| `local_via` | `STRING` | SIM | Detalhamento do local na via |
| `tipo_veiculo_vitima` | `STRING` | SIM | Tipo de veículo em que a vítima estava |
| `tipo_de_vitima` | `STRING` | SIM | Papel da pessoa no sinistro (Condutor, Passageiro, Pedestre) |
| `sexo` | `STRING` | SIM | Sexo informado da pessoa |
| `idade` | `INT64` | SIM | Idade em anos (com tratamentos de inconsistências) |
| `faixa_etaria_demografica` | `STRING` | SIM | Agrupamento de faixa etária padronizado |
| `categoria_profissao` | `STRING` | SIM | Categoria profissional da vítima |
| `grau_de_instrucao` | `STRING` | SIM | Nível de escolaridade |
| `nacionalidade` | `STRING` | SIM | Nacionalidade informada |
| `data_sinistro` | `DATE` | SIM | Data da ocorrência do sinistro |
| `gravidade_lesao` | `STRING` | SIM | Classificação da lesão (Fatal, Grave, Leve, Ileso) |
| `foi_fatal` | `BOOL` | SIM | Indicador booleano (TRUE/FALSE) se houve óbito |
| `data_obito` | `DATE` | SIM | Data do óbito (quando aplicável) |
| `local_obito` | `LOCAL` | SIM | Local onde o óbito foi constatado |
| `dias_para_obito` | `INT64` | SIM | Quantidade de dias transcorridos entre o sinistro e o óbito |
