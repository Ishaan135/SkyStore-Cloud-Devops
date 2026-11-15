$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot
Write-Host "=== SkyStore Cloud & DevOps Demo ===" -ForegroundColor Cyan
docker info *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Starting Docker Desktop..."
  Start-Process "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe"
  do { Start-Sleep 3; docker info *> $null } until ($LASTEXITCODE -eq 0)
}
docker compose up -d --build
Write-Host "Waiting for services..."
foreach ($u in 'http://localhost:3000','http://localhost:8080/login') {
  for ($i=0; $i -lt 90; $i++) { try { Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 2 | Out-Null; break } catch { Start-Sleep 2 } }
}
Start-Process 'http://localhost:4000'
Start-Process 'http://localhost:3000'
Start-Process 'http://localhost:8080/job/SkyStore-Pipeline/'
Write-Host "Ready. Dashboard: http://localhost:4000" -ForegroundColor Green
