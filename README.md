# Projeto Segurança Viária e Mortalidade - Mackenzie Hands On
Este repositório contém uma solução completa de **Engenharia de Dados, Modelagem Analítica e Machine Learning (K-Means)** para análise de acidentes de trânsito e indicadores socioeconômicos (IPDM) no **Estado de São Paulo**, utilizando dados públicos do **InfoSiga SP** e da **SEADE**.

A arquitetura é totalmente serverless e nativa da **Google Cloud Platform (GCP)**, integrando ingestão automatizada via eventos, orquestração com Workflows, transformação com **Dataform**, infraestrutura como código com **Terraform** e entrega de valor por meio de um aplicativo web interativo em **Streamlit** executado no **Cloud Run**.

---

## 🏗️ Arquitetura Geral do Sistema (E2E)

![Arquitetura E2E da Solução](https://github.com/murillonardi/mack_hands_on_seguranca_viaria/blob/main/documentacoes/arquitetura_e2e.png)

##🛠️ Tecnologias e Ferramentas Utilizadas
**Cloud & Serverless**: Google Cloud Platform (GCP), Cloud Run, Cloud Storage, Artifact Registry, Eventarc, Cloud Workflows.

**Engenharia de Dados**: BigQuery, Dataform (SQLX), Python (Pandas).

**Infraestrutura como Código (IaC)**: Terraform, GitHub Actions (CI/CD).

**Data Science & Visualização**: Scikit-Learn (K-Means), Streamlit, Plotly, Jupyter Notebooks.

---

##📂 Estrutura de Diretórios e Descrição dos Arquivos

Abaixo está o detalhamento de cada pasta e arquivo presente no repositório:

* 📁 **`.github/workflows/`** — Automação de CI/CD[cite: 4]
  * 📄 `deploy.yml`: Pipeline no GitHub Actions responsável pelo build e push das imagens Docker no Artifact Registry e pela execução automatizada do Terraform (`init` e `apply`)[cite: 2, 4].

* 📁 **`cloudrun_services/`** — Microserviços containerizados executados no Google Cloud Run[cite: 4]
  * 📁 **`dashboard/`** — Aplicação web analítica interativa[cite: 4]
    * 📄 `Dockerfile`: Configuração de build e ambiente da imagem Docker do Streamlit[cite: 4].
    * 📄 `main.py`: Código-fonte principal do dashboard (Streamlit, Pandas, Plotly e clusterização K-Means em tempo real)[cite: 4].
    * 📄 `requirements.txt`: Lista de dependências Python necessárias para o dashboard (`streamlit`, `pandas`, `scikit-learn`, `plotly`)[cite: 4].
  * 📁 **`raw_data_create/`** — Serviço serverless de ingestão de dados[cite: 4]
    * 📄 `Dockerfile`: Configuração de build do container responsável pela carga inicial de dados[cite: 4].
    * 📄 `main.py`: Script Python que lê os arquivos brutos do Cloud Storage e carrega as tabelas *Raw* no BigQuery[cite: 4].
    * 📄 `requirements.txt`: Dependências do microserviço de ingestão (`google-cloud-bigquery`, `db-dtypes`)[cite: 4].

* 📁 **`definitions/`** — Modelos de transformação de dados e pipelines SQLX no Dataform[cite: 4]
  * 📁 **`refined/`** — Camada analítica final e features de Machine Learning[cite: 4]
    * 📄 `refined_ml_features.sqlx`: Tabela consolidada e normalizada com os indicadores por município/ano usados como entrada no K-Means[cite: 4].
    * 📄 `star_schema.sqlx`: Modelagem dimensional final estruturada em *Star Schema* (tabelas fato de acidentes e dimensões de tempo/localização)[cite: 4].
  * 📁 **`trusted/`** — Camada de dados limpos, tipados e padronizados[cite: 4]
    * 📄 `trusted_accidents.sqlx`: Tratamento, limpeza e padronização dos registros de sinistros de trânsito[cite: 4].
    * 📄 `trusted_people.sqlx`: Limpeza e estruturação dos dados demográficos e de gravidade das vítimas envolvidas[cite: 4].
    * 📄 `trusted_seade_idpm.sqlx`: Integração e tratamento dos indicadores socioeconômicos municipais (IPDM - Fundação SEADE)[cite: 4].
    * 📄 `trusted_seade_mortality.sqlx`: Tratamento das estatísticas vitais e taxas de mortalidade da SEADE[cite: 4].
    * 📄 `trusted_vehicles.sqlx`: Categorização e limpeza da frota e tipos de veículos envolvidos nos acidentes[cite: 4].

* 📁 **`documentacoes/`** — Documentação técnica e diagramas de arquitetura[cite: 4]
  * 🖼️ `arquitetura_e2e.png`: Diagrama visual ilustrando o fluxo de dados ponta a ponta na GCP[cite: 4].
  * 📄 `catalogo_de_dados_trusted.md`: Dicionário de dados detalhando esquemas, tipos e regras de negócio das tabelas da camada *Trusted*[cite: 4].

* 📁 **`download_files/`** — Utilitários locais de extração[cite: 4]
  * 📄 `file_download_exec.ps1`: Script PowerShell para automatizar o download, descompactação e upload inicial das bases públicas[cite: 4].

* 📁 **`eda/`** — Análise Exploratória de Dados (Notebooks)[cite: 4]
  * 📓 `EDA - raw_accidents.ipynb`: Exploração estatística, verificação de nulos e distribuição da base bruta de acidentes[cite: 4].
  * 📓 `EDA - raw_vehicles.ipynb`: Análise exploratória da base bruta de veículos envolvidos[cite: 4].
  * 📓 `EDA_raw_people.ipynb`: Análise exploratória dos registros brutos de vítimas e pessoas envolvidas[cite: 4].

* 📁 **`machine learning/`** — Prototipagem e validação de modelos[cite: 4]
  * 📓 `modelo_cluster.ipynb`: Experimentação, escolha do número ideal de clusters ($k=5$) e validação do algoritmo K-Means[cite: 4].

* 📁 **`terraform/`** — Infraestrutura como Código (IaC) na Google Cloud Platform[cite: 4]
  * 📄 `main.tf`: Provisionamento principal dos recursos na GCP (serviços Cloud Run, permissões IAM e Artifact Registry)[cite: 4].
  * 📄 `variables.tf`: Declaração das variáveis de entrada do Terraform (`project_id`, `region`, URIs das imagens Docker)[cite: 4].
  * 📄 `workflows.tf`: Configuração da orquestração serverless (Cloud Workflows, gatilhos Eventarc e Service Accounts dedicadas)[cite: 3, 4].

* 📄 **`.gitignore`** — Regras de arquivos e diretórios ignorados pelo controle de versão Git (ex.: `node_modules/`)[cite: 4].
* 📄 **`workflow_settings.yaml`** — Arquivo de configuração global do projeto e repositórios no Dataform[cite: 4].
* 📄 **`README.md`** — Documentação principal e guia de implantação do repositório[cite: 4].

---

##🚀 Como Executar o Projeto Localmente

**1. Executar o Dashboard Streamlit**
Certifique-se de ter o Python 3.10+ instalado. Navegue até a pasta do dashboard e instale as dependências:

`cd cloudrun_services/dashboard
pip install -r requirements.txt`

Certifique-se de que os arquivos de dados consolidados ou as exportações necessárias estejam na raiz ou configure os caminhos, em seguida execute:

`streamlit run main.py`

**2. Provisionar a Infraestrutura com Terraform**
Para aplicar a infraestrutura na GCP via Terraform:

`cd terraform
terraform init
terraform plan -var="project_id=SEU_PROJECT_ID" -var="region=us-central1"
terraform apply`

##📄 Licença
Desenvolvido para fins educacionais e aplicados de engenharia de dados e segurança viária.

