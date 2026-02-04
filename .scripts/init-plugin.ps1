# ============================================================================
# WPZylos Scaffold - Plugin Initializer
# ============================================================================
# This script automates the customization of wpzylos-scaffold for new plugins.
# After initialization, configuration is saved to .plugin-config.json for
# the build script to use.
#
# Location: .scripts/init-plugin.ps1
# Called by: ../wpzylos.ps1
# ============================================================================

param(
    [switch]$NonInteractive,
    [string]$PluginName,
    [string]$PluginSlug,
    [string]$Namespace,
    [string]$ScoperPrefix,
    [string]$DbPrefix,
    [string]$AuthorName,
    [string]$AuthorUri,
    [string]$PluginUri,
    [string]$VendorName,
    [string]$Version = "1.0.0"
)

# ============================================================================
# Change to project root (parent of .scripts)
# ============================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Push-Location $projectRoot

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "  WPZylos Scaffold - Plugin Initializer" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    Write-Host "[$Step/$Total] $Message... " -NoNewline -ForegroundColor Yellow
}

function Write-Done {
    Write-Host "Done" -ForegroundColor Green
}

function ConvertTo-PluginSlug {
    param([string]$Name)
    $slug = $Name.ToLower() -replace '[^a-z0-9\s]', '' -replace '\s+', '-'
    return $slug.Trim('-')
}

function ConvertTo-Namespace {
    param([string]$Slug)
    $parts = $Slug -split '-'
    $namespace = ($parts | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ''
    return $namespace
}

function ConvertTo-ScoperPrefix {
    param([string]$Slug)
    return $Slug -replace '-', '_'
}

function ConvertTo-DbPrefix {
    param([string]$Slug)
    return ($Slug -replace '-', '') + '_'
}

function ConvertTo-VendorName {
    param([string]$AuthorName)
    return ($AuthorName -replace '\s+', '').ToLower()
}

function Read-WithDefault {
    param([string]$Prompt, [string]$Default)
    $input = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $Default
    }
    return $input
}

function Replace-InFile {
    param(
        [string]$FilePath,
        [string]$Find,
        [string]$Replace
    )
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $content = $content -replace [regex]::Escape($Find), $Replace
        Set-Content $FilePath -Value $content -Encoding UTF8 -NoNewline
    }
}

function Replace-InAllFiles {
    param(
        [string]$Find,
        [string]$Replace,
        [string[]]$Extensions = @('*.php', '*.json', '*.txt', '*.md')
    )
    
    foreach ($ext in $Extensions) {
        Get-ChildItem -Path . -Recurse -Filter $ext -File | 
        Where-Object { $_.FullName -notmatch '[\\/]vendor[\\/]' -and $_.FullName -notmatch '[\\/]\.git[\\/]' } |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw -Encoding UTF8
            if ($content -match [regex]::Escape($Find)) {
                $content = $content -replace [regex]::Escape($Find), $Replace
                Set-Content $_.FullName -Value $content -Encoding UTF8 -NoNewline
            }
        }
    }
}

function Save-PluginConfig {
    param(
        [hashtable]$Config
    )
    
    $configPath = ".plugin-config.json"
    $Config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8
}

# ============================================================================
# Main Script
# ============================================================================

Write-Header

# Check if we're in the scaffold directory
if (-not (Test-Path "my-plugin.php")) {
    Write-Host "Error: 'my-plugin.php' not found." -ForegroundColor Red
    Write-Host "Please run this script from the wpzylos-scaffold root directory." -ForegroundColor Red
    exit 1
}

# Check if already initialized
if (Test-Path ".plugin-config.json") {
    Write-Host "Warning: Plugin already initialized." -ForegroundColor Yellow
    $existingConfig = Get-Content ".plugin-config.json" -Raw | ConvertFrom-Json
    Write-Host "  Current plugin: $($existingConfig.plugin.name)" -ForegroundColor Gray
    $continue = Read-Host "Re-initialize? [y/N]"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        exit 0
    }
}

# ============================================================================
# Collect Information
# ============================================================================

if (-not $NonInteractive) {
    Write-Host "Enter your plugin display name (e.g., 'My Awesome Plugin'):" -ForegroundColor White
    $PluginName = Read-Host ">"
    
    if ([string]::IsNullOrWhiteSpace($PluginName)) {
        Write-Host "Error: Plugin name is required." -ForegroundColor Red
        exit 1
    }
    
    # Derive defaults
    $defaultSlug = ConvertTo-PluginSlug $PluginName
    $defaultNamespace = ConvertTo-Namespace $defaultSlug
    $defaultScoperPrefix = ConvertTo-ScoperPrefix $defaultSlug
    $defaultDbPrefix = ConvertTo-DbPrefix $defaultSlug
    
    Write-Host ""
    Write-Host "Derived values (press Enter to accept, or type to override):" -ForegroundColor White
    
    $PluginSlug = Read-WithDefault "  Plugin Slug" $defaultSlug
    $Namespace = Read-WithDefault "  PHP Namespace" $defaultNamespace
    $ScoperPrefix = Read-WithDefault "  Scoper Prefix" $defaultScoperPrefix
    $DbPrefix = Read-WithDefault "  Database Prefix" $defaultDbPrefix
    
    Write-Host ""
    Write-Host "Author information (press Enter to skip):" -ForegroundColor White
    $AuthorName = Read-WithDefault "  Author Name" "Your Name"
    $AuthorUri = Read-WithDefault "  Author URI" "https://example.com"
    $PluginUri = Read-WithDefault "  Plugin URI" "https://example.com/$PluginSlug"
    
    # Vendor name for composer
    $defaultVendor = ConvertTo-VendorName $AuthorName
    $VendorName = Read-WithDefault "  Vendor Name (for composer)" $defaultVendor
    
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor White
    Write-Host "  Plugin Name:    $PluginName" -ForegroundColor Gray
    Write-Host "  Plugin Slug:    $PluginSlug" -ForegroundColor Gray
    Write-Host "  Namespace:      $Namespace" -ForegroundColor Gray
    Write-Host "  Scoper Prefix:  $ScoperPrefix" -ForegroundColor Gray
    Write-Host "  DB Prefix:      $DbPrefix" -ForegroundColor Gray
    Write-Host "  Vendor:         $VendorName" -ForegroundColor Gray
    Write-Host "  Composer Name:  $VendorName/$PluginSlug" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "Proceed with initialization? [Y/n]"
    if ($confirm -eq 'n' -or $confirm -eq 'N') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}
else {
    # Non-interactive mode - derive defaults if not provided
    if ([string]::IsNullOrWhiteSpace($PluginName)) {
        Write-Host "Error: -PluginName is required in non-interactive mode." -ForegroundColor Red
        exit 1
    }
    
    if ([string]::IsNullOrWhiteSpace($PluginSlug)) { $PluginSlug = ConvertTo-PluginSlug $PluginName }
    if ([string]::IsNullOrWhiteSpace($Namespace)) { $Namespace = ConvertTo-Namespace $PluginSlug }
    if ([string]::IsNullOrWhiteSpace($ScoperPrefix)) { $ScoperPrefix = ConvertTo-ScoperPrefix $PluginSlug }
    if ([string]::IsNullOrWhiteSpace($DbPrefix)) { $DbPrefix = ConvertTo-DbPrefix $PluginSlug }
    if ([string]::IsNullOrWhiteSpace($AuthorName)) { $AuthorName = "Your Name" }
    if ([string]::IsNullOrWhiteSpace($AuthorUri)) { $AuthorUri = "https://example.com" }
    if ([string]::IsNullOrWhiteSpace($PluginUri)) { $PluginUri = "https://example.com/$PluginSlug" }
    if ([string]::IsNullOrWhiteSpace($VendorName)) { $VendorName = ConvertTo-VendorName $AuthorName }
}

Write-Host ""

# ============================================================================
# Perform Replacements
# ============================================================================

$totalSteps = 10

# Step 1: Replace display name
Write-Step 1 $totalSteps "Replacing display name 'My Plugin'"
Replace-InAllFiles -Find "My Plugin" -Replace $PluginName
Write-Done

# Step 2: Replace plugin slug (hyphenated)
Write-Step 2 $totalSteps "Replacing plugin slug 'my-plugin'"
Replace-InAllFiles -Find "my-plugin" -Replace $PluginSlug
Write-Done

# Step 3: Replace namespace
Write-Step 3 $totalSteps "Replacing namespace 'MyPlugin'"
Replace-InAllFiles -Find "MyPlugin" -Replace $Namespace
Write-Done

# Step 4: Replace scoper prefix (underscored)
Write-Step 4 $totalSteps "Replacing scoper prefix 'my_plugin'"
Replace-InFile -FilePath "scoper.inc.php" -Find "my_plugin" -Replace $ScoperPrefix
Write-Done

# Step 5: Replace database prefix
Write-Step 5 $totalSteps "Replacing database prefix 'myplugin_'"
Replace-InAllFiles -Find "myplugin_" -Replace $DbPrefix
Write-Done

# Step 6: Replace global variable (context storage)
Write-Step 6 $totalSteps "Replacing global variable name"
$globalVarOld = '$my_plugin_context'
$globalVarNew = '$' + ($PluginSlug -replace '-', '_') + '_context'
Replace-InFile -FilePath "my-plugin.php" -Find $globalVarOld -Replace $globalVarNew
Write-Done

# Step 7: Update composer.json package name
Write-Step 7 $totalSteps "Updating composer.json package name"
Replace-InFile -FilePath "composer.json" -Find "wpdiggerstudio/wpzylos-scaffold" -Replace "$VendorName/$PluginSlug"
Write-Done

# Step 8: Update author information
Write-Step 8 $totalSteps "Updating author information"
Replace-InFile -FilePath "my-plugin.php" -Find "Your Name" -Replace $AuthorName
Replace-InFile -FilePath "my-plugin.php" -Find "https://example.com/my-plugin" -Replace $PluginUri
Replace-InFile -FilePath "my-plugin.php" -Find "https://example.com" -Replace $AuthorUri
Replace-InFile -FilePath "readme.txt" -Find "your-username" -Replace ($AuthorName -replace '\s+', '').ToLower()
Write-Done

# Step 9: Rename main plugin file
Write-Step 9 $totalSteps "Renaming my-plugin.php to $PluginSlug.php"
if (Test-Path "my-plugin.php") {
    # Update references in other files first
    Replace-InFile -FilePath "Makefile" -Find "my-plugin.php" -Replace "$PluginSlug.php"
    Replace-InFile -FilePath "scoper.inc.php" -Find "my-plugin.php" -Replace "$PluginSlug.php"
    Replace-InFile -FilePath "uninstall.php" -Find "my-plugin.php" -Replace "$PluginSlug.php"
    
    # Rename the file
    Rename-Item -Path "my-plugin.php" -NewName "$PluginSlug.php"
}
Write-Done

# Step 10: Save configuration
Write-Step 10 $totalSteps "Saving plugin configuration"
$config = @{
    initialized = $true
    timestamp   = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    plugin      = @{
        name         = $PluginName
        slug         = $PluginSlug
        namespace    = $Namespace
        scoperPrefix = $ScoperPrefix
        dbPrefix     = $DbPrefix
        version      = $Version
        mainFile     = "$PluginSlug.php"
    }
    author      = @{
        name = $AuthorName
        uri  = $AuthorUri
    }
    composer    = @{
        vendor = $VendorName
        name   = "$VendorName/$PluginSlug"
    }
}
Save-PluginConfig -Config $config
Write-Done

# ============================================================================
# Post-Processing
# ============================================================================

Write-Host ""
Write-Host "Running composer dump-autoload..." -ForegroundColor Yellow

$composerResult = & composer dump-autoload 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Composer autoload updated"
}
else {
    Write-Host "Warning: composer dump-autoload failed. Run it manually." -ForegroundColor Yellow
}

# ============================================================================
# Success Message
# ============================================================================

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Plugin '$PluginName' initialized!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration saved to: .plugin-config.json" -ForegroundColor White
Write-Host ""
Write-Host "Files modified:" -ForegroundColor White
Write-Host "  - $PluginSlug.php (main plugin file)" -ForegroundColor Gray
Write-Host "  - composer.json (package: $VendorName/$PluginSlug)" -ForegroundColor Gray
Write-Host "  - scoper.inc.php" -ForegroundColor Gray
Write-Host "  - Makefile" -ForegroundColor Gray
Write-Host "  - uninstall.php" -ForegroundColor Gray
Write-Host "  - readme.txt" -ForegroundColor Gray
Write-Host "  - app/Core/PluginContext.php" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run: composer install" -ForegroundColor Gray
Write-Host "  2. Develop your plugin" -ForegroundColor Gray
Write-Host "  3. Build: .\build.ps1" -ForegroundColor Gray
Write-Host ""
