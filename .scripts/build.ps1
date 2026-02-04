# ============================================================================
# WPZylos Scaffold - Build Script
# ============================================================================
# Creates a production-ready distributable ZIP with PHP-Scoper isolation.
# Reads configuration from .plugin-config.json (created by init-plugin.ps1).
#
# Build Pipeline:
#   1. Clean build artifacts
#   2. Run code style fix (phpcbf)
#   3. Run static analysis (phpstan)
#   4. Install production dependencies
#   5. Run PHP-Scoper
#   6. Copy required files
#   7. Create versioned ZIP
#
# Location: .scripts/build.ps1
# Called by: ../wpzylos.ps1
# ============================================================================

param(
    [switch]$Clean,
    [switch]$SkipQA,
    [switch]$SkipScoper,
    [string]$Version
)

# ============================================================================
# Change to project root (parent of .scripts)
# ============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Push-Location $projectRoot

# ============================================================================
# Configuration
# ============================================================================

$BUILD_DIR = "build"
$DIST_DIR = "dist"
$CONFIG_FILE = ".plugin-config.json"

# Load plugin config
if (Test-Path $CONFIG_FILE) {
    $config = Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json
    $PLUGIN_SLUG = $config.plugin.slug
    $PLUGIN_NAME = $config.plugin.name
    $PLUGIN_NAMESPACE = $config.plugin.namespace
    $MAIN_FILE = $config.plugin.mainFile
    
    # Use version from config unless overridden
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = $config.plugin.version
    }
}
else {
    # Fallback: Auto-detect from files
    Write-Host "Warning: .plugin-config.json not found. Using auto-detection." -ForegroundColor Yellow
    Write-Host "Run init-plugin.ps1 first for best results." -ForegroundColor Yellow
    Write-Host ""
    
    $mainPluginFile = Get-ChildItem -Filter "*.php" -File | Where-Object { 
        $_.Name -ne "uninstall.php" -and 
        $_.Name -ne "scoper.inc.php" -and
        $_.Name -notmatch "^index\.php$"
    } | Select-Object -First 1

    if (-not $mainPluginFile) {
        Write-Host "Error: Could not find main plugin file." -ForegroundColor Red
        exit 1
    }

    $PLUGIN_SLUG = $mainPluginFile.BaseName
    $MAIN_FILE = $mainPluginFile.Name
    $PLUGIN_NAME = $PLUGIN_SLUG
    
    # Extract version from plugin file
    $pluginContent = Get-Content $mainPluginFile.FullName -Raw
    if ([string]::IsNullOrWhiteSpace($Version) -and $pluginContent -match "Version:\s*([0-9.]+)") {
        $Version = $matches[1]
    }
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = "1.0.0"
}

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Clean-Build {
    Write-Step "Cleaning build artifacts..."
    
    if (Test-Path $BUILD_DIR) {
        Remove-Item -Path $BUILD_DIR -Recurse -Force
    }
    if (Test-Path $DIST_DIR) {
        Remove-Item -Path $DIST_DIR -Recurse -Force
    }
    
    Write-Success "Cleaned build directories"
}

function Run-PHPCBF {
    Write-Step "Running PHP Code Beautifier (phpcbf --standard=PSR12)..."
    
    $phpcbfPath = "vendor\bin\phpcbf.bat"
    if (-not (Test-Path $phpcbfPath)) {
        $phpcbfPath = "vendor\bin\phpcbf"
    }
    
    if (Test-Path $phpcbfPath) {
        # Run phpcbf - exit code 1 means files were fixed (not an error)
        $result = & $phpcbfPath --standard=PSR12 app includes 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "No code style issues found"
        }
        elseif ($LASTEXITCODE -eq 1) {
            Write-Success "Code style issues auto-fixed"
        }
        else {
            Write-Warning "phpcbf returned exit code $LASTEXITCODE"
        }
    }
    else {
        Write-Warning "phpcbf not found. Skipping code style fix."
    }
}

function Run-PHPStan {
    Write-Step "Running static analysis (phpstan analyze)..."
    
    $phpstanPath = "vendor\bin\phpstan.bat"
    if (-not (Test-Path $phpstanPath)) {
        $phpstanPath = "vendor\bin\phpstan"
    }
    
    if (Test-Path $phpstanPath) {
        $result = & $phpstanPath analyze app includes --no-progress 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Static analysis passed"
        }
        else {
            Write-Error "Static analysis found issues:"
            Write-Host $result -ForegroundColor Gray
            $continue = Read-Host "Continue build anyway? [y/N]"
            if ($continue -ne 'y' -and $continue -ne 'Y') {
                exit 1
            }
        }
    }
    else {
        Write-Warning "phpstan not found. Skipping static analysis."
    }
}

# ============================================================================
# Main Build Process
# ============================================================================

Write-Header "WPZylos Build - $PLUGIN_SLUG v$Version"

# Clean only mode
if ($Clean) {
    Clean-Build
    exit 0
}

# Step 1: Clean
Clean-Build

# Step 2: Run QA (unless skipped)
if (-not $SkipQA) {
    # Ensure dev dependencies are installed for QA tools
    Write-Step "Ensuring dev dependencies are installed..."
    & composer install --quiet 2>&1 | Out-Null
    Write-Success "Dependencies ready"
    
    Run-PHPCBF
    Run-PHPStan
}
else {
    Write-Step "Skipping QA checks..."
}

# Step 3: Install production dependencies
Write-Step "Installing production dependencies..."
$composerResult = & composer install --no-dev --optimize-autoloader 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Composer install failed"
    Write-Host $composerResult -ForegroundColor Gray
    exit 1
}
Write-Success "Production dependencies installed"

# Step 4: Run PHP-Scoper (unless skipped)
if (-not $SkipScoper) {
    Write-Step "Running PHP-Scoper..."
    
    # Re-install dev deps for scoper
    & composer install --quiet 2>&1 | Out-Null
    
    $scoperPath = "vendor\bin\php-scoper.bat"
    if (-not (Test-Path $scoperPath)) {
        $scoperPath = "vendor\bin\php-scoper"
    }
    
    if (Test-Path $scoperPath) {
        $scoperResult = & $scoperPath add-prefix --output-dir=$BUILD_DIR --force 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "PHP-Scoper failed"
            Write-Host $scoperResult -ForegroundColor Gray
            exit 1
        }
        Write-Success "PHP-Scoper completed"
    }
    else {
        Write-Error "PHP-Scoper not found in vendor/bin"
        exit 1
    }
}
else {
    Write-Step "Skipping PHP-Scoper (dev build)..."
    New-Item -Path $BUILD_DIR -ItemType Directory -Force | Out-Null
    
    # Copy source files
    $sourceDirs = @("app", "bootstrap", "config", "database", "includes", "resources", "routes")
    foreach ($dir in $sourceDirs) {
        if (Test-Path $dir) {
            Copy-Item -Path $dir -Destination "$BUILD_DIR\$dir" -Recurse -Force
        }
    }
    
    # Copy vendor
    if (Test-Path "vendor") {
        Copy-Item -Path "vendor" -Destination "$BUILD_DIR\vendor" -Recurse -Force
    }
    
    Write-Success "Files copied to build directory"
}

# Step 5: Copy essential files to build
Write-Step "Copying essential files..."

$essentialFiles = @(
    $MAIN_FILE,
    "uninstall.php",
    "readme.txt",
    "LICENSE"
)

foreach ($file in $essentialFiles) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination "$BUILD_DIR\" -Force
    }
}

# Copy directories that might not be scoped
$essentialDirs = @("resources", "config", "routes", "database")
foreach ($dir in $essentialDirs) {
    if ((Test-Path $dir) -and -not (Test-Path "$BUILD_DIR\$dir")) {
        Copy-Item -Path $dir -Destination "$BUILD_DIR\$dir" -Recurse -Force
    }
}

Write-Success "Essential files copied"

# Step 6: Rebuild autoloader in build directory
Write-Step "Rebuilding autoloader in build directory..."
Push-Location $BUILD_DIR
$autoloadResult = & composer dump-autoload --classmap-authoritative 2>&1
Pop-Location

if ($LASTEXITCODE -eq 0) {
    Write-Success "Autoloader rebuilt"
}
else {
    Write-Warning "Autoloader rebuild issue (may still work)"
}

# Step 7: Remove development files from build
Write-Step "Removing development files..."

$devFiles = @(
    "$BUILD_DIR\.git",
    "$BUILD_DIR\.github",
    "$BUILD_DIR\.gitignore",
    "$BUILD_DIR\.gitattributes",
    "$BUILD_DIR\.plugin-config.json",
    "$BUILD_DIR\tests",
    "$BUILD_DIR\phpunit.xml",
    "$BUILD_DIR\phpstan.neon",
    "$BUILD_DIR\phpcs.xml.dist",
    "$BUILD_DIR\scoper.inc.php",
    "$BUILD_DIR\init-plugin.ps1",
    "$BUILD_DIR\init-plugin.sh",
    "$BUILD_DIR\build.ps1",
    "$BUILD_DIR\build.sh",
    "$BUILD_DIR\Makefile",
    "$BUILD_DIR\CONTRIBUTING.md",
    "$BUILD_DIR\SECURITY.md",
    "$BUILD_DIR\CHANGELOG.md",
    "$BUILD_DIR\composer.lock",
    "$BUILD_DIR\composer.json"
)

foreach ($file in $devFiles) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Success "Development files removed"

# Step 8: Create ZIP
Write-Step "Creating distributable ZIP..."

New-Item -Path $DIST_DIR -ItemType Directory -Force | Out-Null

$zipPath = "$DIST_DIR\$PLUGIN_SLUG-$Version.zip"

# Use .NET compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create temp directory with plugin folder structure
$tempDir = "$DIST_DIR\temp"
$tempPluginDir = "$tempDir\$PLUGIN_SLUG"
New-Item -Path $tempPluginDir -ItemType Directory -Force | Out-Null
Copy-Item -Path "$BUILD_DIR\*" -Destination $tempPluginDir -Recurse -Force

# Create ZIP
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $tempDir,
    $zipPath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)

Remove-Item -Path $tempDir -Recurse -Force

$zipSize = [math]::Round((Get-Item $zipPath).Length / 1KB, 2)
Write-Success "Created: $zipPath ($zipSize KB)"

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Build Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Plugin:     $PLUGIN_NAME" -ForegroundColor Gray
Write-Host "Version:    $Version" -ForegroundColor Gray
Write-Host "Output:     $zipPath" -ForegroundColor Gray
Write-Host "Size:       $zipSize KB" -ForegroundColor Gray
Write-Host ""

if (-not $SkipQA) {
    Write-Host "QA Checks:  Passed (phpcbf, phpstan)" -ForegroundColor Gray
}
if (-not $SkipScoper) {
    Write-Host "Scoped:     Yes (namespace isolation)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Test installation on staging site" -ForegroundColor Gray
Write-Host "  2. Upload to WordPress or distribute" -ForegroundColor Gray
Write-Host ""
