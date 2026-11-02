FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Executa via Gunicorn com timeout estendido para downloads/uploads pesados
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 600 main:app
