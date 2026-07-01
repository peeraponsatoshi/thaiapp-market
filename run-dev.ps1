[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# Thai App Market - Development Server
# ============================================================

$Host.UI.RawUI.WindowTitle = "Thai App Market - Dev Server"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Thai App Market - Dev Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Check Node.js ---
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Write-Host "[ERROR] Node.js not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Node.js: https://nodejs.org/" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}

$nodeVersion = & node -v
Write-Host "[OK] Node.js: $nodeVersion" -ForegroundColor Green

# --- Check npx ---
$npxPath = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npxPath) {
    Write-Host "[ERROR] npx not found!" -ForegroundColor Red
    Write-Host "Please install latest Node.js with npx" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host "[OK] npx ready" -ForegroundColor Green

# --- Auto-install Dependencies ---
if (-not (Test-Path "node_modules")) {
    Write-Host ""
    Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
    & npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies!" -ForegroundColor Red
        Read-Host "Press Enter to close"
        exit 1
    }
    Write-Host "[OK] Dependencies installed" -ForegroundColor Green
}

# --- Start Dev Server ---
$port = 3000

Write-Host ""
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "  Starting Dev Server..." -ForegroundColor Cyan
Write-Host "  URL:  http://localhost:$port" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host ""

try {
    & npx -y serve . -l $port
} catch {
    Write-Host ""
    Write-Host "[ERROR] Server stopped: $_" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close"