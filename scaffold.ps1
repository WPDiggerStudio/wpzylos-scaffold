# ============================================================================
# WPZylos Scaffold CLI
# ============================================================================
# Single command to manage your WPZylos plugin scaffold.
#
# Usage:
#   .\scaffold.ps1           # Interactive menu
#   .\scaffold.ps1 init      # Initialize plugin
#   .\scaffold.ps1 build     # Build for production
# ============================================================================

param(
    [Parameter(Position = 0)]
    [ValidateSet("init", "build", "")]
    [string]$Action,
    [Parameter(ValueFromRemainingArguments = $true)]
    $RemainingArgs
)

# ============================================================================
# Configuration
# ============================================================================

$SCRIPTS_DIR = ".scripts"
$VERSION = "1.0.0"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Logo {
    Write-Host ""
    Write-Host "  __          _______   _____      _            " -ForegroundColor Cyan
    Write-Host "  \ \        / /  __ \ |___  |    | |           " -ForegroundColor Cyan
    Write-Host "   \ \  /\  / /| |__) |   / / ___ | | ___  ___  " -ForegroundColor Cyan
    Write-Host "    \ \/  \/ / |  ___/   / / / _ \| |/ _ \/ __| " -ForegroundColor Cyan
    Write-Host "     \  /\  /  | |      / /_| (_) | | (_) \__ \ " -ForegroundColor Cyan
    Write-Host "      \/  \/   |_|     /_____\___/|_|\___/|___/ " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Scaffold CLI v$VERSION" -ForegroundColor Gray
    Write-Host ""
}

function Write-Menu {
    Write-Host "  What would you like to do?" -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] " -NoNewline -ForegroundColor Yellow
    Write-Host "Initialize Plugin" -ForegroundColor White
    Write-Host "        Set up plugin name, namespace, and configuration" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [2] " -NoNewline -ForegroundColor Yellow
    Write-Host "Build for Production" -ForegroundColor White
    Write-Host "        Run QA checks, scope dependencies, create ZIP" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    [0] " -NoNewline -ForegroundColor Yellow
    Write-Host "Exit" -ForegroundColor White
    Write-Host ""
}

function Get-PluginStatus {
    if (Test-Path ".plugin-config.json") {
        $config = Get-Content ".plugin-config.json" -Raw | ConvertFrom-Json
        Write-Host "  Current Plugin: " -NoNewline -ForegroundColor Gray
        Write-Host $config.plugin.name -ForegroundColor Green
        Write-Host "  Slug: " -NoNewline -ForegroundColor Gray
        Write-Host $config.plugin.slug -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host "  Status: " -NoNewline -ForegroundColor Gray
        Write-Host "Not initialized" -ForegroundColor Yellow
        Write-Host "  Run 'init' to set up your plugin" -ForegroundColor Gray
        Write-Host ""
    }
}

function Invoke-InitPlugin {
    $scriptPath = Join-Path $SCRIPTS_DIR "init-plugin.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath @RemainingArgs
    }
    else {
        Write-Host "Error: init-plugin.ps1 not found in $SCRIPTS_DIR" -ForegroundColor Red
        exit 1
    }
}

function Invoke-Build {
    $scriptPath = Join-Path $SCRIPTS_DIR "build.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath @RemainingArgs
    }
    else {
        Write-Host "Error: build.ps1 not found in $SCRIPTS_DIR" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# Main
# ============================================================================

# Handle direct action
if ($Action -eq "init") {
    Invoke-InitPlugin
    exit $LASTEXITCODE
}

if ($Action -eq "build") {
    Invoke-Build
    exit $LASTEXITCODE
}

# Interactive menu
Write-Logo
Get-PluginStatus
Write-Menu

$choice = Read-Host "  Enter choice [0-2]"

switch ($choice) {
    "1" {
        Write-Host ""
        Invoke-InitPlugin
    }
    "2" {
        Write-Host ""
        Invoke-Build
    }
    "0" {
        Write-Host ""
        Write-Host "  Goodbye!" -ForegroundColor Cyan
        exit 0
    }
    default {
        Write-Host ""
        Write-Host "  Invalid choice. Please enter 0, 1, or 2." -ForegroundColor Red
        exit 1
    }
}
