# Define a pasta de destino em C:/Users/<usuario>/AppData/Local/Temp/seade_dados
$userProfile = $env:USERPROFILE
$pastaDestino = Join-Path $userProfile "AppData\Local\Temp\seade_dados"

if (!(Test-Path $pastaDestino)) {
    New-Item -ItemType Directory -Force -Path $pastaDestino | Out-Null
}

$dataAtual = Get-Date -Format "yyyy-MM-dd"
Write-Host "📁 Destino dos downloads: $pastaDestino" -ForegroundColor Cyan

# Lista de arquivos
$fontes = @(
    @{ Url = "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/8e2b513f-1449-463c-b75b-82f2b029ba38/download/grupos.csv"; Nome = "grupos.csv" },
    @{ Url = "https://repositorio.seade.gov.br/dataset/f714bdee-3f8c-464e-9e45-07a0e444937a/resource/5684399c-2175-4749-8914-babd5c9eaaef/download/ipdm.csv"; Nome = "ipdm.csv" },
    @{ Url = "https://repositorio.seade.gov.br/dataset/ceb51484-b92f-4c06-a611-87abc493ce47/resource/a06203b9-6716-4685-9053-25e788571941/download/mortalidade_geral.csv"; Nome = "mortalidade_geral.csv" },
    @{ Url = "https://repositorio.seade.gov.br/dataset/27830d72-14ea-4acc-a458-d95ce71994cf/resource/4956eb14-b5ba-4cbc-8edc-ff024ef06a87/download/infra_ipvs_entorno_esp.csv"; Nome = "infra_ipvs_entorno_esp.csv" },
    @{ Url = "https://infosiga.detran.sp.gov.br/painel/download/file/dados_infosiga.zip"; Nome = "dados_infosiga.zip" }
)

foreach ($item in $fontes) {
    $ext = [System.IO.Path]::GetExtension($item.Nome)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($item.Nome)
    $nomeComData = "${stem}_${dataAtual}${ext}"
    $caminhoCompleto = Join-Path $pastaDestino $nomeComData

    Write-Host "Baixando: $($item.Nome)..." -NoNewline
    try {
        $headers = @{ "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
        Invoke-WebRequest -Uri $item.Url -OutFile $caminhoCompleto -Headers $headers -TimeoutSec 300
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [ERRO]: $_" -ForegroundColor Red
    }
}

Write-Host "`nProcesso concluído!" -ForegroundColor Cyan