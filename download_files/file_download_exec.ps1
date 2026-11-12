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

    Write-Host "Baixando SDK..." -NoNewline
    try {
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -TimeoutSec 600
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO]: Falha ao baixar o SDK: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host "Extraindo arquivos..." -NoNewline
    if (Test-Path $sdkDir) { Remove-Item -Recurse -Force $sdkDir }
    Expand-Archive -Path $zipPath -DestinationPath $sdkDir -Force
    Write-Host " [OK]" -ForegroundColor Green

    $installBat = Join-Path $sdkDir "google-cloud-sdk\install.bat"
    & $installBat --quiet --path-update false --usage-reporting false | Out-Null
    Write-Host " [OK]" -ForegroundColor Green

    $gcloudCommand = $gcloudExe
    $gsutilCommand = $gsutilExe

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

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

# ==========================================
# 3. DOWNLOAD E UPLOAD DOS ARQUIVOS SEADE (CSV DIRETOS)
# ==========================================
$fontesSeade = @(
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

foreach ($item in $fontesSeade) {
    $nomeArquivo = "$($item.NomeBase)_$dataAtual$($item.Ext)"
    $caminhoLocal = Join-Path $pastaDestino $nomeArquivo
    $destinoGcs = "gs://$($item.Bucket)/$nomeArquivo"

    Write-Host "--------------------------------------------------"
    Write-Host "Processando SEADE: $($item.NomeBase)" -ForegroundColor Yellow

    Write-Host "Baixando da internet..." -NoNewline
    try {
        Invoke-WebRequest -Uri $item.Url -OutFile $caminhoLocal -Headers $headers -TimeoutSec 300
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO NO DOWNLOAD]: $_" -ForegroundColor Red
        continue
    }

    Write-Host "Enviando para $destinoGcs..." -NoNewline
    try {
        & $gsutilCommand cp $caminhoLocal $destinoGcs | Out-Null
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO NO UPLOAD]: $_" -ForegroundColor Red
    }
}

# ==========================================
# 4. DOWNLOAD, EXTRAÇÃO E ROTEAMENTO DO INFOSIGA (ZIP VIA CURL)
# ==========================================
Write-Host "--------------------------------------------------"
Write-Host "Processando Infosiga (Pacote ZIP)" -ForegroundColor Yellow

$infosigaZipUrl = "https://infosiga.detran.sp.gov.br/painel/download/file/dados_infosiga.zip"
$zipFilePath = Join-Path $pastaDestino "dados_infosiga.zip"
$extractPath = Join-Path $pastaDestino "infosiga_extracted"

Write-Host "Baixando ZIP do Infosiga via curl..." -NoNewline
try {
    # O parâmetro -L segue redirecionamentos e o -A simula um navegador real para passar pelo WAF do portal
    & curl.exe -L -s -S -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -o "$zipFilePath" "$infosigaZipUrl"
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    Write-Host " [ERRO NO DOWNLOAD DO ZIP]: $_" -ForegroundColor Red
}

if (Test-Path $zipFilePath) {
    $fileInfo = Get-Item $zipFilePath
    
    # Valida se o arquivo baixado tem um tamanho plausível (maior que 100KB)
    if ($fileInfo.Length -lt 102400) {
        Write-Host " [ERRO] O arquivo baixado é muito pequeno ($($fileInfo.Length) bytes). O portal bloqueou a requisição automatizada." -ForegroundColor Red
        Remove-Item -Force $zipFilePath
    } else {
        Write-Host "Extraindo arquivos ZIP..." -NoNewline
        if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath }
        
        try {
            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            Write-Host " [OK]" -ForegroundColor Green

            # Varre os CSVs e faz o upload para o bucket correto
            $csvFiles = Get-ChildItem -Path $extractPath -Filter "*.csv" -Recurse
            foreach ($csv in $csvFiles) {
                $fileName = $csv.Name
                $filePath = $csv.FullName
                $targetBucket = $null

                if ($fileName.StartsWith("pessoas_")) {
                    $targetBucket = "dados-infosiga-pessoas"
                } elseif ($fileName.StartsWith("sinistros_")) {
                    $targetBucket = "dados-infosiga-sinistros"
                } elseif ($fileName.StartsWith("veiculos_")) {
                    $targetBucket = "dados-infosiga-veiculos"
                }

                if ($null -ne $targetBucket) {
                    $destinoGcs = "gs://$targetBucket/$fileName"
                    Write-Host "Enviando $fileName para $targetBucket..." -NoNewline
                    try {
                        & $gsutilCommand cp $filePath $destinoGcs | Out-Null
                        Write-Host " [OK]" -ForegroundColor Green
                    } catch {
                        Write-Host " [ERRO NO UPLOAD]: $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host "ℹ️ Arquivo CSV ignorado (fora dos prefixos mapeados): $fileName" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host " [ERRO NA EXTRAÇÃO]: $_" -ForegroundColor Red
        }

        # Remove o arquivo ZIP temporário
        Remove-Item -Force $zipFilePath -ErrorAction SilentlyContinue
    }
}

Write-Host "`n✨ Sincronização completa de todas as fontes realizada com sucesso!" -ForegroundColor Cyan