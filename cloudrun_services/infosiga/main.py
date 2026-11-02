import os
import tempfile
import zipfile
import requests
from flask import Flask, jsonify
from google.cloud import storage

app = Flask(__name__)

INFOSIGA_URL = "https://infosiga.detran.sp.gov.br/painel/download/file/dados_infosiga.zip"

# Mapeamento de prefixo para o bucket correspondente
BUCKET_MAP = {
    "pessoas_": "dados-infosiga-pessoas",
    "sinistros_": "dados-infosiga-sinistros",
    "veiculos_": "dados-infosiga-veiculos",
}


@app.route("/", methods=["POST", "GET"])
def run_pipeline():
  storage_client = storage.Client()

  print("Iniciando download do arquivo ZIP do InfoSiga...")
  try:
    response = requests.get(INFOSIGA_URL, stream=True, timeout=300)
    response.raise_for_status()
  except requests.exceptions.RequestException as e:
    return (
        jsonify({
            "status": "error",
            "message": f"Falha ao baixar o arquivo: {str(e)}",
        }),
        500,
    )

  uploaded_files = []

  # Utiliza um diretório temporário para extração segura
  with tempfile.TemporaryDirectory() as tmpdir:
    zip_path = os.path.join(tmpdir, "dados_infosiga.zip")

    # Escreve o arquivo zip em chunks
    with open(zip_path, "wb") as f:
      for chunk in response.iter_content(chunk_size=8192):
        if chunk:
          f.write(chunk)

    print("Download concluído. Extraindo arquivos...")
    with zipfile.ZipFile(zip_path, "r") as zip_ref:
      zip_ref.extractall(tmpdir)

      for filename in zip_ref.namelist():
        # Ignora diretórios internos caso existam
        if filename.endswith("/"):
          continue

        base_name = os.path.basename(filename)
        target_bucket = None

        # Identifica o bucket de destino com base no prefixo
        for prefix, bucket_name in BUCKET_MAP.items():
          if base_name.startswith(prefix):
            target_bucket = bucket_name
            break

        if target_bucket:
          file_path = os.path.join(tmpdir, filename)
          if os.path.isfile(file_path):
            print(f"Enviando '{base_name}' para o bucket '{target_bucket}'...")
            bucket = storage_client.bucket(target_bucket)
            blob = bucket.blob(base_name)
            blob.upload_from_filename(file_path)

            uploaded_files.append({"file": base_name, "bucket": target_bucket})

  return (
      jsonify({
          "status": "success",
          "message": (
              "Pipeline de ingestão InfoSiga executada com sucesso!"
          ),
          "files_uploaded": uploaded_files,
      }),
      200,
  )


if __name__ == "__main__":
  port = int(os.environ.get("PORT", 8080))
  app.run(host="0.0.0.0", port=port)
