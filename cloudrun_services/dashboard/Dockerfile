FROM python:3.10-slim

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala dependências do sistema se necessário
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copia os arquivos de dependência e instala
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o código da aplicação e as bases de dados para dentro do container
COPY . /app

# Expõe a porta que o Streamlit utiliza por padrão
EXPOSE 8080

# Configura o Streamlit para rodar na porta 8080 e escutar em todas as interfaces
CMD ["streamlit", "run", "app.py", "--server.port=8080", "--server.address=0.0.0.0", "--server.headless=true"]
