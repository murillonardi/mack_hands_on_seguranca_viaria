from datetime import datetime
import os
from flask import Flask, jsonify
from google.cloud import bigquery

app = Flask(__name__)

PROJECT_ID = "project-f1079166-4703-4cc3-975"
DATASET_ID = "raw_data"


@app.route("/", methods=["POST"])
def run_ingestion():
  try:
    client = bigquery.Client(project=PROJECT_ID)

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

    results = {}

    for item in tabelas_para_carregar:
      table_id = f"{PROJECT_ID}.{DATASET_ID}.{item['tabela']}"
      job_config = bigquery.LoadJobConfig(
          source_format=bigquery.SourceFormat.CSV,
          skip_leading_rows=1,
          autodetect=True,
          write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
      )

      load_job = client.load_table_from_uri(
          item["uri"], table_id, job_config=job_config
      )
      load_job.result()

      destination_table = client.get_table(table_id)
      results[item["tabela"]] = (
          f"Sucesso. Linhas carregadas: {destination_table.num_rows}"
      )

    return (
        jsonify({
            "status": "success",
            "message": "Cargas raw concluídas com sucesso!",
            "details": results,
        }),
        200,
    )

  except Exception as e:
    print(f"Erro no pipeline: {str(e)}")
    return jsonify({"status": "error", "message": str(e)}), 500


if __name__ == "__main__":
  port = int(os.environ.get("PORT", 8080))
  app.run(host="0.0.0.0", port=port)