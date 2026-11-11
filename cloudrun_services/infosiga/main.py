from datetime import datetime
import os
from flask import Flask, jsonify
from google.cloud import storage

app = Flask(__name__)

# Buckets onde os arquivos foram salvos externamente
BUCKETS = {
    "pessoas": "dados-infosiga-pessoas",
    "sinistros": "dados-infosiga-sinistros",
    "veiculos": "dados-infosiga-veiculos",
}


@app.route("/", methods=["POST"])
def process_infosiga():
  try:
    current_date = datetime.now().strftime("%Y-%m-%d")
    storage_client = storage.Client()

    results = {}

    for tipo, bucket_name in BUCKETS.items():
      bucket = storage_client.bucket(bucket_name)

      # Procura o arquivo com a data de hoje no bucket
      prefix = f"dados_infosiga_{tipo}_{current_date}"
      blobs = list(bucket.list_blobs(prefix=prefix))

      if not blobs:
        results[tipo] = "Nenhum arquivo encontrado para hoje no GCS"
        continue

      # Pega o arquivo mais recente correspondente
      blob = blobs[0]
      local_path = f"/tmp/{blob.name}"

      # Baixa para o diretório temporário do Linux (/tmp) do Cloud Run
      blob.download_to_filename(local_path)
      print(f"Arquivo {blob.name} baixado com sucesso para o container.")

      # ---> AQUI ENTRA A SUA LÓGICA DE PROCESSAMENTO / CARGA NO BIGQUERY <---
      # Exemplo: ler o CSV usando pandas e carregar no BigQuery

      results[tipo] = "Processado com sucesso"

    return jsonify({"status": "success", "details": results}), 200

  except Exception as e:
    print(f"Erro interno no processamento: {str(e)}")
    return jsonify({"status": "error", "message": str(e)}), 500


if __name__ == "__main__":
  port = int(os.environ.get("PORT", 8080))
  app.run(host="0.0.0.0", port=port)
