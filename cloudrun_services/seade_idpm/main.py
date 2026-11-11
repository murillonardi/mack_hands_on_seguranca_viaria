import os
import requests
from flask import Flask, jsonify
from google.cloud import storage
from datetime import datetime

app = Flask(__name__)

SEADE_URL = "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/5684399c-2175-4749-8914-babd5c9eaaef/download/ipdm.csv"
BUCKET_NAME = os.environ.get("BUCKET_NAME", "dados_seade_idpm")
CURRENT_DATE = datetime.now().strftime("%Y%m%d")
FILE_NAME = f"seade_ipdm_{CURRENT_DATE}.csv"
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

@app.route("/", methods=["POST", "GET"])
def run_pipeline():
  storage_client = storage.Client()
  print(f"Iniciando download do arquivo {FILE_NAME}...")

  try:
    response = requests.get(SEADE_URL, headers=HEADERS, timeout=300)
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
