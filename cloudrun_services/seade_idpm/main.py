from datetime import datetime
import os
import requests
from google.cloud import storage

# Configurações
DATASET_PAGE = "https://repositorio.seade.gov.br/dataset/indice-paulista-de-desenvolvimento-municipal-ipdm/resource/5684399c-2175-4749-8914-babd5c9eaaef"
DOWNLOAD_URL = "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/5684399c-2175-4749-8914-babd5c9eaaef/download/ipdm.csv"
BUCKET_NAME = "dados_seade_idpm"

current_date = datetime.now().strftime("%Y-%m-%d")
BLOB_NAME = f"ipdm_{current_date}.csv"
TMP_PATH = f"/tmp/{BLOB_NAME}"


def main():
  # Usa requests.Session() para reter cookies automaticamente como um navegador real
  session = requests.Session()

  # Headers idênticos aos da sua captura de rede
  headers = {
      "User-Agent": (
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML,"
          " like Gecko) Chrome/154.0.0.0 Safari/537.36 OPR/138.0.0.0"
      ),
      "Accept": (
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"
      ),
      "Accept-Language": "en-US,en;q=0.9,pt-BR;q=0.8,pt;q=0.7",
      "Referer": DATASET_PAGE,
  }

  print("Passo 1: Acessando a página do dataset para inicializar a sessão e cookies...")
  try:
    # Simula a navegação abrindo a página web primeiro (pega o cookie 'ckan')
    session.get(DATASET_PAGE, headers=headers, timeout=30)
  except Exception as e:
    print(
        "Aviso ao acessar página de referência (prosseguindo para o download):"
        f" {e}"
    )

  print("Passo 2: Baixando o arquivo CSV utilizando a sessão autenticada...")
  response = session.get(
      DOWNLOAD_URL, headers=headers, timeout=300, stream=True
  )
  response.raise_for_status()

  with open(TMP_PATH, "wb") as f:
    for chunk in response.iter_content(chunk_size=8192):
      f.write(chunk)

  print("Download concluído. Enviando para o Google Cloud Storage...")

  # Upload para o GCS
  client = storage.Client()
  bucket = client.bucket(BUCKET_NAME)
  blob = bucket.blob(BLOB_NAME)
  blob.upload_from_filename(TMP_PATH)

  print(f"Arquivo enviado com sucesso para gs://{BUCKET_NAME}/{BLOB_NAME}")

  if os.path.exists(TMP_PATH):
    os.remove(TMP_PATH)


if __name__ == "__main__":
  main()
