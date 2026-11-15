# Importa bibliotecas necessárias para manipulação de datas, sistema operacional, Flask e BigQuery
from datetime import datetime
import os
from flask import Flask, jsonify
from google.cloud import bigquery

# Inicializa a aplicação web utilizando o framework Flask
app = Flask(__name__)

# Configuração de variáveis globais contendo o ID do projeto GCP e o dataset de destino
PROJECT_ID = "project-f1079166-4703-4cc3-975"
DATASET_ID = "raw_data"

# Define a rota principal ouvindo requisições HTTP do tipo POST (acionada pelo Cloud Workflows/Eventarc)
@app.route("/", methods=["POST"])
def run_ingestion():
  try:
    # Inicializa o cliente do BigQuery utilizando o ID do projeto configurado
    client = bigquery.Client(project=PROJECT_ID)

    # Lista de dicionários contendo o mapeamento das tabelas de destino no BigQuery e as URIs dos arquivos CSV no Cloud Storage
    tabelas_para_carregar = [
        {
            "tabela": "raw_seade_ipdm",
            "uri": "gs://dados_seade_idpm/ipdm.csv",
        },
        {
            "tabela": "raw_seade_grupos_ipdm",
            "uri": "gs://dados_seade_idpm_grupos/grupos.csv",
        },
        {
            "tabela": "raw_seade_entorno_ipvs",
            "uri": "gs://dados-seade-ipvs-entorno/entorno.csv",
        },
        {
            "tabela": "raw_seade_mortalidade",
            "uri": "gs://dados-seade-mortalidade/mortalidade_geral.csv",
        },
        {
            "tabela": "raw_infosiga_pessoas",
            "uri": "gs://dados-infosiga-pessoas/pessoas_*.csv",
        },
        {
            "tabela": "raw_infosiga_sinistros",
            "uri": "gs://dados-infosiga-sinistros/sinistros_*.csv",
        },
        {
            "tabela": "raw_infosiga_veiculos",
            "uri": "gs://dados-infosiga-veiculos/veiculos_*.csv",
        },
    ]

    # Dicionário para armazenar os resultados de sucesso de cada carga de tabela
    results = {}

    # Itera sobre cada item da lista para realizar a carga automatizada no BigQuery
    for item in tabelas_para_carregar:
      # Constrói o identificador completo da tabela (projeto.dataset.tabela)
      table_id = f"{PROJECT_ID}.{DATASET_ID}.{item['tabela']}"
      
      # Configura o comportamento do job de carregamento no BigQuery
      job_config = bigquery.LoadJobConfig(
          source_format=bigquery.SourceFormat.CSV, # Define que o formato de origem é CSV
          skip_leading_rows=1,                     # Pula o cabeçalho do arquivo CSV (primeira linha)
          autodetect=True,                         # Detecta automaticamente o esquema das colunas
          write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE, # Substitui os dados da tabela a cada execução (sobrepõe)
      )

      # Inicia o job assíncrono para carregar os dados diretamente do Google Cloud Storage para a tabela
      load_job = client.load_table_from_uri(
          item["uri"], table_id, job_config=job_config
      )
      load_job.result() # Aguarda a conclusão síncrona da execução do job de carga

      # Recupera metadados da tabela de destino para confirmar o número de linhas inseridas
      destination_table = client.get_table(table_id)
      results[item["tabela"]] = (
          f"Sucesso. Linhas carregadas: {destination_table.num_rows}"
      )

    # Retorna uma resposta HTTP 200 contendo o JSON de sucesso e os detalhes de linhas carregadas por tabela
    return (
        jsonify({
            "status": "success",
            "message": "Cargas raw concluídas com sucesso!",
            "details": results,
        }),
        200,
    )

  except Exception as e:
    # Captura qualquer exceção ocorrida no pipeline, exibe no console e retorna um erro HTTP 500
    print(f"Erro no pipeline: {str(e)}")
    return jsonify({"status": "error", "message": str(e)}), 500

# Bloco de execução principal para iniciar o servidor web localmente ou no Cloud Run
if __name__ == "__main__":
  # Lê a porta definida nas variáveis de ambiente do Cloud Run (padrão 8080)
  port = int(os.environ.get("PORT", 8080))
  # Inicia a aplicação Flask escutando em todas as interfaces de rede (0.0.0.0) na porta especificada
  app.run(host="0.0.0.0", port=port)
