FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Inicializa a função HTTP utilizando Functions Framework
CMD exec functions-framework \
    --target=importar_csv \
    --source=main.py \
    --host=0.0.0.0 \
    --port=${PORT:-8080}
