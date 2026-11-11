from datetime import datetime
import os
from pathlib import Path
from google.cloud import storage

user_profile = os.environ.get("USERPROFILE", "C:\\Users\\Default")
pasta_origem = (
    Path(user_profile) / "AppData" / "Local" / "Temp" / "seade_dados"
)
current_date = datetime.now().strftime("%Y-%m-%d")

nome_arquivo = f"ipdm_{current_date}.csv"
arquivo_path = pasta_origem / nome_arquivo
bucket_destino = "dados_seade_idpm"


def main():
  if not arquivo_path.exists():
    print(f"[ERRO] Arquivo não encontrado: {arquivo_path}")
    return

  print(f"🚀 Enviando {nome_arquivo} para o bucket {bucket_destino}...")
  client = storage.Client()
  bucket = client.bucket(bucket_destino)
  blob = bucket.blob(nome_arquivo)

  blob.upload_from_filename(str(arquivo_path))
  print(f"[OK] Upload concluído para gs://{bucket_destino}/{nome_arquivo}")


if __name__ == "__main__":
  main()