# Backup FreeLLMAPI data for Railway (or any Docker) migration.
# Creates backups/railway-YYYYMMDD-HHMMSS/ with freeapi.db + ENCRYPTION_KEY reminder.

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DbPath = Join-Path $Root "server\data\freeapi.db"
$EnvPath = Join-Path $Root ".env"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$OutDir = Join-Path $Root "backups\railway-$Stamp"

if (-not (Test-Path $DbPath)) {
    Write-Error "Database not found at $DbPath. Start the server locally once and configure keys first."
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
Copy-Item $DbPath (Join-Path $OutDir "freeapi.db")

if (Test-Path $EnvPath) {
    $keyLine = Get-Content $EnvPath | Where-Object { $_ -match '^\s*ENCRYPTION_KEY=' } | Select-Object -First 1
    if ($keyLine) {
        $keyLine | Set-Content (Join-Path $OutDir "ENCRYPTION_KEY.txt")
        Write-Host "Saved ENCRYPTION_KEY to backup folder (keep private)."
    } else {
        Write-Warning "No ENCRYPTION_KEY= line in .env. Add it manually before Railway deploy."
    }
} else {
    Write-Warning "No .env file. Set ENCRYPTION_KEY in Railway Variables manually."
}

Write-Host ""
Write-Host "Backup complete: $OutDir"
Write-Host "  - freeapi.db"
Write-Host "  - ENCRYPTION_KEY.txt (if present)"
Write-Host ""
Write-Host "Next: see docker/RAILWAY.md for Railway deploy steps."
