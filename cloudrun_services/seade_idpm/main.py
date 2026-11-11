import logging
import os
import time
import uuid

import functions_framework
import requests

from google.api_core.exceptions import GoogleAPICallError
from google.cloud import storage
from flask import jsonify


# Configurações
SEADE_URL = (
    "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/5684399c-2175-4749-8914-babd5c9eaaef/download/ipdm.csv"
)

BUCKET_NAME = "dados_seade_idpm"
DESTINATION_NAME = "ipdm.csv"

MAX_ATTEMPTS = 4

# Tamanho dos blocos de transferência
DOWNLOAD_CHUNK_SIZE = 1024 * 1024       # 1 MB
GCS_CHUNK_SIZE = 8 * 1024 * 1024        # 8 MB


logging.basicConfig(level=logging.INFO)


def is_retryable(exc):
    """Identifica erros que podem ser temporários."""

    if isinstance(exc, requests.HTTPError):
        status = exc.response.status_code if exc.response else None
        return status in (429, 500, 502, 503, 504)

    if isinstance(exc, requests.RequestException):
        return True

    if isinstance(exc, GoogleAPICallError):
        return getattr(exc, "code", None) in (
            429, 500, 502, 503, 504
        )

    return isinstance(exc, (TimeoutError, ConnectionError, OSError))


def download_and_upload():

    storage_client = storage.Client()
    bucket = storage_client.bucket(BUCKET_NAME)

    for attempt in range(1, MAX_ATTEMPTS + 1):

        stage_blob = None

        try:
            logging.info(
                "Iniciando download do SEADE. Tentativa %s/%s",
                attempt,
                MAX_ATTEMPTS
            )

            headers = {
                "User-Agent": "Mozilla/5.0 (compatible; SEADE-Data-Importer/1.0)",
                "Accept": "text/csv,*/*"
            }

            with requests.get(
                SEADE_URL,
                headers=headers,
                stream=True,
                timeout=(20, 120),
                allow_redirects=True
            ) as response:

                logging.info(
                    "Resposta SEADE: HTTP %s | Content-Type: %s",
                    response.status_code,
                    response.headers.get("Content-Type")
                )

                response.raise_for_status()

                content_type = response.headers.get(
                    "Content-Type", ""
                ).lower()

                if "text/html" in content_type:
                    raise RuntimeError(
                        "O SEADE retornou HTML em vez do arquivo CSV."
                    )

                # Nome temporário exclusivo para esta tentativa
                stage_name = (
                    f"_staging/ipdm_{uuid.uuid4().hex}.csv"
                )

                stage_blob = bucket.blob(stage_name)

                bytes_downloaded = 0

                # Upload em streaming diretamente para o GCS
                with stage_blob.open(
                    "wb",
                    chunk_size=GCS_CHUNK_SIZE,
                    content_type="text/csv",
                    timeout=180
                ) as destination:

                    for chunk in response.iter_content(
                        chunk_size=DOWNLOAD_CHUNK_SIZE
                    ):

                        if chunk:
                            destination.write(chunk)
                            bytes_downloaded += len(chunk)

                if bytes_downloaded == 0:
                    raise RuntimeError(
                        "O arquivo recebido está vazio."
                    )

            logging.info(
                "Download concluído. Total transferido: %s bytes",
                bytes_downloaded
            )

            # Publica o arquivo definitivo somente após o upload completo
            final_blob = bucket.copy_blob(
                stage_blob,
                bucket,
                new_name=DESTINATION_NAME
            )

            logging.info(
                "Upload concluído: gs://%s/%s",
                BUCKET_NAME,
                DESTINATION_NAME
            )

            # Remove o objeto temporário
            try:
                stage_blob.delete()
            except Exception:
                logging.warning(
                    "Não foi possível remover o arquivo temporário: %s",
                    stage_name,
                    exc_info=True
                )

            return {
                "success": True,
                "bucket": BUCKET_NAME,
                "file": DESTINATION_NAME,
                "bytes": bytes_downloaded
            }

        except Exception as exc:

            logging.exception(
                "Erro na tentativa %s: %s",
                attempt,
                str(exc)
            )

            # Limpeza de eventual arquivo temporário
            if stage_blob is not None:
                try:
                    stage_blob.delete()
                except Exception:
                    logging.warning(
                        "Falha ao remover objeto temporário.",
                        exc_info=True
                    )

            if attempt >= MAX_ATTEMPTS or not is_retryable(exc):
                raise

            wait_seconds = min(2 ** (attempt - 1), 30)

            logging.warning(
                "Erro temporário. Nova tentativa em %s segundos.",
                wait_seconds
            )

            time.sleep(wait_seconds)


@functions_framework.http
def importar_csv(request):

    try:
        result = download_and_upload()

        return jsonify(result), 200

    except requests.RequestException as exc:

        status = (
            exc.response.status_code
            if isinstance(exc, requests.HTTPError)
            and exc.response is not None
            else None
        )

        logging.exception("Falha na comunicação com o SEADE.")

        return jsonify({
            "success": False,
            "error": "Falha ao obter o CSV do SEADE.",
            "seade_http_status": status
        }), 502

    except Exception:

        logging.exception("Falha durante a importação.")

        return jsonify({
            "success": False,
            "error": "Falha na importação. Consulte os logs."
        }), 500
