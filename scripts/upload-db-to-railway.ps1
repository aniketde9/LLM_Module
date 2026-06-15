# Upload local freeapi.db to Railway volume (maps to /app/server/data in the container).
# Prerequisites: railway CLI logged in (`railway login`), project linked (`railway link -s "@freellmapi/server"`).

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DbPath = Join-Path $Root "server\data\freeapi.db"
$VolumeName = if ($env:RAILWAY_VOLUME_NAME) { $env:RAILWAY_VOLUME_NAME } else { "@freellmapi/server-volume" }

if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Error "Railway CLI not found. Run: npm install -g @railway/cli"
}

if (-not (Test-Path $DbPath)) {
    Write-Error "Database not found at $DbPath"
}

Write-Host "Checkpointing SQLite WAL (stop local server first)..."
Push-Location $Root
node -e "const Database = require('better-sqlite3'); const db = new Database('server/data/freeapi.db'); db.pragma('wal_checkpoint(TRUNCATE)'); db.close();"
Pop-Location

$sizeKb = [math]::Round((Get-Item $DbPath).Length / 1024, 1)
Write-Host "Uploading freeapi.db (${sizeKb} KB) to volume $VolumeName ..."

railway volume files --volume $VolumeName upload $DbPath "/freeapi.db" --overwrite

Write-Host ""
Write-Host "If stale WAL files cause issues after a prior empty deploy, delete them manually:"
Write-Host "  railway volume files --volume '$VolumeName' delete /freeapi.db-wal --yes"
Write-Host "  railway volume files --volume '$VolumeName' delete /freeapi.db-shm --yes"
Write-Host ""
Write-Host "Redeploying service..."
railway redeploy -y

Write-Host ""
Write-Host "Done. Log in on your Railway URL with your LOCAL dashboard email/password."
