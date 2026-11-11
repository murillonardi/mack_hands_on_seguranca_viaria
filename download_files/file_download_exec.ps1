# Define caminhos padrão no perfil do usuário
$userProfile = $env:USERPROFILE
$pastaDestino = Join-Path $userProfile "AppData\Local\Temp\seade_dados"
$gcloudBinDir = Join-Path $userProfile "google-cloud-sdk\google-cloud-sdk\bin"
$gcloudExe = Join-Path $gcloudBinDir "gcloud.cmd"
$gsutilExe = Join-Path $gcloudBinDir "gsutil.cmd"

if (!(Test-Path $pastaDestino)) {
    New-Item -ItemType Directory -Force -Path $pastaDestino | Out-Null
}

$dataAtual = Get-Date -Format "yyyy-MM-dd"
Write-Host "📁 Destino local dos arquivos: $pastaDestino" -ForegroundColor Cyan
Write-Host "📅 Data de referência: $dataAtual`n" -ForegroundColor Cyan

# ==========================================
# 1. VERIFICAÇÃO E INSTALAÇÃO AUTOMÁTICA DO GCLOUD
# ==========================================
# Verifica se o gcloud está globalmente no sistema ou na pasta do usuário
$gcloudGlobal = Get-Command gcloud -ErrorAction SilentlyContinue

if ($null -ne $gcloudGlobal) {
    $gcloudCommand = "gcloud"
    $gsutilCommand = "gsutil"
    Write-Host "✅ Google Cloud CLI detectado globalmente no sistema." -ForegroundColor Green
} elseif (Test-Path $gcloudExe) {
    $gcloudCommand = $gcloudExe
    $gsutilCommand = $gsutilExe
    Write-Host "✅ Google Cloud CLI detectado na pasta do usuário." -ForegroundColor Green
} else {
    Write-Host "⚠️ Google Cloud CLI (gcloud) não encontrado na máquina." -ForegroundColor Yellow
    Write-Host "📥 Iniciando instalação automatizada do Google Cloud SDK (sem exigir Admin)..." -ForegroundColor Cyan

    $zipUrl = "https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip"
    $zipPath = Join-Path $pastaDestino "google-cloud-sdk.zip"
    $sdkDir = Join-Path $userProfile "google-cloud-sdk"

    # Baixa o SDK oficial do Google
    Write-Host "Baixando SDK..." -NoNewline
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -TimeoutSec 600
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO]: Falha ao baixar o SDK: $_" -ForegroundColor Red
        exit 1
    }

    # Extrai o arquivo ZIP
    Write-Host "Extraindo arquivos..." -NoNewline
    if (Test-Path $sdkDir) { Remove-Item -Recurse -Force $sdkDir }
    Expand-Archive -Path $zipPath -DestinationPath $sdkDir -Force
    Write-Host " [OK]" -ForegroundColor Green

    # Executa o instalador interno do SDK em modo silencioso
    Write-Host "Configurando ambiente..." -NoNewline
    $installBat = Join-Path $sdkDir "google-cloud-sdk\install.bat"
    & $installBat --quiet --path-update false --usage-reporting false | Out-Null
    Write-Host " [OK]" -ForegroundColor Green

    # Define os caminhos absolutos para uso imediato
    $gcloudCommand = $gcloudExe
    $gsutilCommand = $gsutilExe

    # Remove o instalador zip temporário
    Remove-Item -Force $zipPath
    Write-Host "✨ Google Cloud SDK instalado com sucesso!`n" -ForegroundColor Green
}

# ==========================================
# 2. VERIFICAÇÃO DE AUTENTICAÇÃO NO GCLOUD
# ==========================================
Write-Host "Verificando autenticação no Google Cloud..."
$authCheck = & $gcloudCommand auth list --format="value(account)" 2>&1

if ([string]::IsNullOrWhiteSpace($authCheck) -or $authCheck -like "*No credential*") {
    Write-Host "⚠️ Nenhuma conta autenticada detectada." -ForegroundColor Yellow
    Write-Host "🔐 Abrindo navegador para autenticação..." -ForegroundColor Cyan
    & $gcloudCommand auth login
    & $gcloudCommand auth application-default login
} else {
    Write-Host "✅ Sessão do Google Cloud autenticada com sucesso.`n" -ForegroundColor Green
}

# ==========================================
# 3. LISTA DE FONTES E EXECUÇÃO DO PIPELINE
# ==========================================
$fontes = @(
    @{
        Url = "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/5684399c-2175-4749-8914-babd5c9eaaef/download/ipdm.csv"
        NomeBase = "ipdm"
        Ext = ".csv"
        Bucket = "dados_seade_idpm"
    },
    @{
        Url = "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/8e2b513f-1449-463c-b75b-82f2b029ba38/download/grupos.csv"
        NomeBase = "grupos"
        Ext = ".csv"
        Bucket = "dados_seade_idpm_grupos"
    },
    @{
        Url = "https://repositorio.seade.gov.br/dataset/27830d72-14ea-4acc-a458-d95ce71994cf/resource/4956eb14-b5ba-4cbc-8edc-ff024ef06a87/download/infra_ipvs_entorno_esp.csv"
        NomeBase = "infra_ipvs_entorno_esp"
        Ext = ".csv"
        Bucket = "dados-seade-ipvs-entorno"
    },
    @{
        Url = "https://repositorio.seade.gov.br/dataset/ceb51484-b92f-4c06-a611-87abc493ce47/resource/a06203b9-6716-4685-9053-25e788571941/download/mortalidade_geral.csv"
        NomeBase = "mortalidade_geral"
        Ext = ".csv"
        Bucket = "dados-seade-mortalidade"
    }
)

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

foreach ($item in $fontes) {
    $nomeArquivo = "$($item.NomeBase)_$dataAtual$($item.Ext)"
    $caminhoLocal = Join-Path $pastaDestino $nomeArquivo
    $destinoGcs = "gs://$($item.Bucket)/$nomeArquivo"

    Write-Host "--------------------------------------------------"
    Write-Host "Processando: $($item.NomeBase)" -ForegroundColor Yellow

    # Download da internet para a máquina local
    Write-Host "Baixando da internet..." -NoNewline
    try {
        Invoke-WebRequest -Uri $item.Url -OutFile $caminhoLocal -Headers $headers -TimeoutSec 300
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO NO DOWNLOAD]: $_" -ForegroundColor Red
        continue
    }

    # Upload para o GCS usando o gsutil apontado corretamente
    Write-Host "Enviando para $destinoGcs..." -NoNewline
    try {
        & $gsutilCommand cp $caminhoLocal $destinoGcs | Out-Null
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO NO UPLOAD]: $_" -ForegroundColor Red
    }
}

Write-Host "`n✨ Sincronização completa realizada com sucesso!" -ForegroundColor Cyan
