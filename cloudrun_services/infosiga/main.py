from datetime import datetime
import os
import zipfile
from pathlib import Path
from google.cloud import storage

# Configuração de diretórios e data
user_profile = os.environ.get("USERPROFILE", "C:\\Users\\Default")
pasta_origem = (
    Path(user_profile) / "AppData" / "Local" / "Temp" / "seade_dados"
)
current_date = datetime.now().strftime("%Y-%m-%d")

zip_filename = f"dados_infosiga_{current_date}.zip"
zip_path = pasta_origem / zip_filename

# Mapeamento de prefixos para seus respectivos buckets
BUCKETS = {
    "pessoas_": "dados-infosiga-pessoas",
    "sinistros_": "dados-infosiga-sinistros",
    "veiculos_": "dados-infosiga-veiculos",
}


def upload_to_gcs(file_path, bucket_name, blob_name):
  client = storage.Client()
  bucket = client.bucket(bucket_name)
  blob = bucket.blob(blob_name)
  blob.upload_from_filename(str(file_path))
  print(f"[OK] Enviado {file_path.name} para gs://{bucket_name}/{blob_name}")


def main():
  if not zip_path.exists():
    print(f"[ERRO] Arquivo ZIP não encontrado em: {zip_path}")
    return

  print(f"📂 Descompactando {zip_filename}...")
  extract_dir = pasta_origem / "extracted_infosiga"
  extract_dir.mkdir(exist_ok=True)

  with zipfile.ZipFile(zip_path, "r") as zip_ref:
    zip_ref.extractall(extract_dir)

  print("🚀 Iniciando upload dos arquivos CSV para o GCS...")
  # Percorre recursivamente os arquivos extraídos
  for file_path in extract_dir.rglob("*"):
    if file_path.is_file():
      filename = file_path.name
      for prefix, bucket_name in BUCKETS.items():
        if filename.startswith(prefix):
          p = Path(filename)
          blob_name = f"{p.stem}_{current_date}{p.suffix}"
          upload_to_gcs(file_path, bucket_name, blob_name)

  print("Processo do Infosiga concluído com sucesso!")


if __name__ == "__main__":
  main()