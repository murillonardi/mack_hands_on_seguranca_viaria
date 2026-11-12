# Usa uma imagem oficial leve do Python
FROM python:3.11-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala as dependências do sistema necessárias
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copia e instala as dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir flask

# Copia o código da aplicação para o container
COPY main.py .

# Define a porta padrão exigida pelo Cloud Run
ENV PORT=8080

# Executa a aplicação usando o Python diretamente
CMD ["python", "main.py"]