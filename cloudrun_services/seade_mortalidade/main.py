import os
import requests
from flask import Flask, jsonify
from google.cloud import storage
from datetime import datetime

app = Flask(__name__)

SEADE_URL = "https://repositorio.seade.gov.br/dataset/ceb51484-b92f-4c06-a611-87abc493ce47/resource/a06203b9-6716-4685-9053-25e788571941/download/mortalidade_geral.csv"
BUCKET_NAME = os.environ.get("BUCKET_NAME", "dados-seade-mortalidade")
FILE_NAME = "seade_mortalidade_geral_{CURRENT_DATE}.csv"
CURRENT_DATE = datetime.now().strftime("%Y%m%d")

@app.route("/", methods=["POST", "GET"])
def run_pipeline():
  storage_client = storage.Client()
  print(f"Iniciando download do arquivo {FILE_NAME}...")

  try:
    response = requests.get(SEADE_URL, stream=True, timeout=300)
    response.raise_for_status()
  except requests.exceptions.RequestException as e:
    return (
        jsonify({
            "status": "error",
            "message": f"Falha ao baixar o arquivo: {str(e)}",
        }),
        500,
    )

  try:
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(FILE_NAME)

    print(f"Enviando arquivo para o bucket GCS '{BUCKET_NAME}'...")
    response.raw.decode_content = True
    blob.upload_from_file(response.raw, content_type="text/csv")
    print("Upload concluído com sucesso!")
  except Exception as e:
    return (
        jsonify({
            "status": "error",
            "message": f"Falha no upload para o GCS: {str(e)}",
        }),
        500,
    )

  return (
      jsonify({
          "status": "success",
          "message": f"Pipeline {FILE_NAME} executada com sucesso!",
          "bucket": BUCKET_NAME,
          "file": FILE_NAME,
      }),
      200,
  )


if __name__ == "__main__":
  port = int(os.environ.get("PORT", 8080))
  app.run(host="0.0.0.0", port=port)
