# ============================================================================
# WPZylos Scaffold - Plugin Initializer (Intelligent)
# ============================================================================
# Handles all scenarios:
# - Fresh install (my-plugin.php exists)
# - Re-configuration (update existing config)
# - Config deleted (detect from renamed files)
# - Partial updates (only change specific values)
#
# Location: .scripts/init-plugin.ps1
# Called by: ../scaffold.ps1
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

try {

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

    function Write-Skip {
        Write-Host "Skipped" -ForegroundColor Gray
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
        $userInput = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            return $Default
        }
        return $userInput
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
            Where-Object { $_.FullName -notmatch '[\\/]vendor[\\/]' -and $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.FullName -notmatch '[\\/]\.scripts[\\/]' } |
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
        param([hashtable]$Config)
        $configPath = ".plugin-config.json"
        $Config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8
    }

    function Get-CurrentState {
        $state = @{
            IsFresh             = $false
            HasConfig           = $false
            CurrentName         = ""
            CurrentSlug         = ""
            CurrentNamespace    = ""
            CurrentScoperPrefix = ""
            CurrentDbPrefix     = ""
            CurrentAuthorName   = ""
            CurrentAuthorUri    = ""
            CurrentVendor       = ""
            MainPluginFile      = ""
        }
    
        # Check for config file
        if (Test-Path ".plugin-config.json") {
            $state.HasConfig = $true
            try {
                $config = Get-Content ".plugin-config.json" -Raw | ConvertFrom-Json
                $state.CurrentName = $config.plugin.name
                $state.CurrentSlug = $config.plugin.slug
                $state.CurrentNamespace = $config.plugin.namespace
                $state.CurrentScoperPrefix = $config.plugin.scoperPrefix
                $state.CurrentDbPrefix = $config.plugin.dbPrefix
                $state.CurrentAuthorName = $config.author.name
                $state.CurrentAuthorUri = $config.author.uri
                $state.CurrentVendor = $config.composer.vendor
                $state.MainPluginFile = $config.plugin.mainFile
            }
            catch {
                Write-Host "Warning: Could not parse .plugin-config.json" -ForegroundColor Yellow
            }
        }
    
        # Check for fresh install
        if (Test-Path "my-plugin.php") {
            $state.IsFresh = $true
            $state.MainPluginFile = "my-plugin.php"
        }
    
        # If no config but not fresh, try to detect from files
        if (-not $state.HasConfig -and -not $state.IsFresh) {
            $mainFiles = Get-ChildItem -Path . -Filter "*.php" -File | Where-Object {
                (Get-Content $_.FullName -Raw) -match "Plugin Name:"
            }
            if ($mainFiles.Count -gt 0) {
                $mainFile = $mainFiles[0]
                $state.MainPluginFile = $mainFile.Name
                $state.CurrentSlug = $mainFile.BaseName
                $content = Get-Content $mainFile.FullName -Raw
                if ($content -match "Plugin Name:\s*(.+)") {
                    $state.CurrentName = $Matches[1].Trim()
                }
                # Try to detect namespace from composer.json
                if (Test-Path "composer.json") {
                    $composer = Get-Content "composer.json" -Raw
                    if ($composer -match '"([^"]+)\\\\": "app/"') {
                        $state.CurrentNamespace = $Matches[1] -replace '\\\\', '\'
                    }
                }
            }
        }
    
        return $state
    }

    # ============================================================================
    # Main Script
    # ============================================================================

    Write-Header

    # Detect current state
    $state = Get-CurrentState

    # Show current status
    if ($state.IsFresh) {
        Write-Host "Fresh scaffold detected." -ForegroundColor Green
        Write-Host ""
    }
    elseif ($state.HasConfig) {
        Write-Host "Current Configuration:" -ForegroundColor Cyan
        Write-Host "  Plugin Name:  $($state.CurrentName)" -ForegroundColor Gray
        Write-Host "  Slug:         $($state.CurrentSlug)" -ForegroundColor Gray
        Write-Host "  Namespace:    $($state.CurrentNamespace)" -ForegroundColor Gray
        Write-Host "  DB Prefix:    $($state.CurrentDbPrefix)" -ForegroundColor Gray
        Write-Host "  Vendor:       $($state.CurrentVendor)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "You can update any value or press Enter to keep current." -ForegroundColor Yellow
        Write-Host ""
    }
    elseif ($state.CurrentSlug) {
        Write-Host "Config file missing but plugin detected: $($state.CurrentSlug)" -ForegroundColor Yellow
        Write-Host "Values will be auto-detected where possible." -ForegroundColor Gray
        Write-Host ""
    }
    else {
        Write-Host "Error: Cannot detect plugin state." -ForegroundColor Red
        Write-Host "Expected 'my-plugin.php' for fresh install or '.plugin-config.json' for existing." -ForegroundColor Red
        Pop-Location
        exit 1
    }

    # ============================================================================
    # Collect Information
    # ============================================================================

    # Set defaults based on state
    if ($state.IsFresh) {
        $defaultName = "My Plugin"
        $defaultSlug = "my-plugin"
        $defaultNamespace = "MyPlugin"
        $defaultScoperPrefix = "my_plugin"
        $defaultDbPrefix = "myplugin_"
        $defaultAuthorName = "Your Name"
        $defaultAuthorUri = "https://example.com"
        $defaultVendor = "yourname"
    }
    else {
        $defaultName = if ($state.CurrentName) { $state.CurrentName } else { "My Plugin" }
        $defaultSlug = if ($state.CurrentSlug) { $state.CurrentSlug } else { "my-plugin" }
        $defaultNamespace = if ($state.CurrentNamespace) { $state.CurrentNamespace } else { "MyPlugin" }
        $defaultScoperPrefix = if ($state.CurrentScoperPrefix) { $state.CurrentScoperPrefix } else { "my_plugin" }
        $defaultDbPrefix = if ($state.CurrentDbPrefix) { $state.CurrentDbPrefix } else { "myplugin_" }
        $defaultAuthorName = if ($state.CurrentAuthorName) { $state.CurrentAuthorName } else { "Your Name" }
        $defaultAuthorUri = if ($state.CurrentAuthorUri) { $state.CurrentAuthorUri } else { "https://example.com" }
        $defaultVendor = if ($state.CurrentVendor) { $state.CurrentVendor } else { "yourname" }
    }

    if (-not $NonInteractive) {
        Write-Host "Enter your plugin display name (or press Enter to keep current):" -ForegroundColor White
        $PluginName = Read-WithDefault "> Plugin Name" $defaultName
    
        # Only derive new values if name changed
        if ($PluginName -ne $defaultName) {
            $derivedSlug = ConvertTo-PluginSlug $PluginName
            $derivedNamespace = ConvertTo-Namespace $derivedSlug
            $derivedScoperPrefix = ConvertTo-ScoperPrefix $derivedSlug
            $derivedDbPrefix = ConvertTo-DbPrefix $derivedSlug
        }
        else {
            $derivedSlug = $defaultSlug
            $derivedNamespace = $defaultNamespace
            $derivedScoperPrefix = $defaultScoperPrefix
            $derivedDbPrefix = $defaultDbPrefix
        }
    
        Write-Host ""
        Write-Host "Derived/Current values (press Enter to accept, or type to override):" -ForegroundColor White
    
        $PluginSlug = Read-WithDefault "  Plugin Slug" $derivedSlug
        $Namespace = Read-WithDefault "  PHP Namespace" $derivedNamespace
        $ScoperPrefix = Read-WithDefault "  Scoper Prefix" $derivedScoperPrefix
        $DbPrefix = Read-WithDefault "  Database Prefix" $derivedDbPrefix
    
        Write-Host ""
        Write-Host "Author information (press Enter to keep current):" -ForegroundColor White
        $AuthorName = Read-WithDefault "  Author Name" $defaultAuthorName
        $AuthorUri = Read-WithDefault "  Author URI" $defaultAuthorUri
        $PluginUri = Read-WithDefault "  Plugin URI" "https://example.com/$PluginSlug"
    
        # Vendor name
        if ($AuthorName -ne $defaultAuthorName) {
            $newDefaultVendor = ConvertTo-VendorName $AuthorName
        }
        else {
            $newDefaultVendor = $defaultVendor
        }
        $VendorName = Read-WithDefault "  Vendor Name (for composer)" $newDefaultVendor
    
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
            Pop-Location
            exit 0
        }
    }
    else {
        # Non-interactive mode
        if ([string]::IsNullOrWhiteSpace($PluginName)) { $PluginName = $defaultName }
        if ([string]::IsNullOrWhiteSpace($PluginSlug)) { $PluginSlug = ConvertTo-PluginSlug $PluginName }
        if ([string]::IsNullOrWhiteSpace($Namespace)) { $Namespace = ConvertTo-Namespace $PluginSlug }
        if ([string]::IsNullOrWhiteSpace($ScoperPrefix)) { $ScoperPrefix = ConvertTo-ScoperPrefix $PluginSlug }
        if ([string]::IsNullOrWhiteSpace($DbPrefix)) { $DbPrefix = ConvertTo-DbPrefix $PluginSlug }
        if ([string]::IsNullOrWhiteSpace($AuthorName)) { $AuthorName = $defaultAuthorName }
        if ([string]::IsNullOrWhiteSpace($AuthorUri)) { $AuthorUri = $defaultAuthorUri }
        if ([string]::IsNullOrWhiteSpace($PluginUri)) { $PluginUri = "https://example.com/$PluginSlug" }
        if ([string]::IsNullOrWhiteSpace($VendorName)) { $VendorName = ConvertTo-VendorName $AuthorName }
    }

    Write-Host ""

    # ============================================================================
    # Determine what needs to change
    # ============================================================================

    if ($state.IsFresh) {
        $oldName = "My Plugin"
        $oldSlug = "my-plugin"
        $oldNamespace = "MyPlugin"
        $oldScoperPrefix = "my_plugin"
        $oldDbPrefix = "myplugin_"
        $oldVendor = "wpdiggerstudio"
        $mainPluginFile = "my-plugin.php"
    }
    else {
        $oldName = if ($state.CurrentName) { $state.CurrentName } else { "My Plugin" }
        $oldSlug = if ($state.CurrentSlug) { $state.CurrentSlug } else { "my-plugin" }
        $oldNamespace = if ($state.CurrentNamespace) { $state.CurrentNamespace } else { "MyPlugin" }
        $oldScoperPrefix = if ($state.CurrentScoperPrefix) { $state.CurrentScoperPrefix } else { "my_plugin" }
        $oldDbPrefix = if ($state.CurrentDbPrefix) { $state.CurrentDbPrefix } else { "myplugin_" }
        $oldVendor = if ($state.CurrentVendor) { $state.CurrentVendor } else { "wpdiggerstudio" }
        $mainPluginFile = if ($state.MainPluginFile) { $state.MainPluginFile } else { "$oldSlug.php" }
    }

    # ============================================================================
    # Perform Replacements (only if values changed)
    # ============================================================================

    $totalSteps = 10

    # Step 1: Replace display name
    Write-Step 1 $totalSteps "Replacing display name"
    if ($PluginName -ne $oldName) {
        Replace-InAllFiles -Find $oldName -Replace $PluginName
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 2: Replace plugin slug
    Write-Step 2 $totalSteps "Replacing plugin slug"
    if ($PluginSlug -ne $oldSlug) {
        Replace-InAllFiles -Find $oldSlug -Replace $PluginSlug
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 3: Replace namespace
    Write-Step 3 $totalSteps "Replacing namespace"
    if ($Namespace -ne $oldNamespace) {
        Replace-InAllFiles -Find $oldNamespace -Replace $Namespace
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 4: Replace scoper prefix
    Write-Step 4 $totalSteps "Replacing scoper prefix"
    if ($ScoperPrefix -ne $oldScoperPrefix) {
        Replace-InFile -FilePath "scoper.inc.php" -Find $oldScoperPrefix -Replace $ScoperPrefix
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 5: Replace database prefix
    Write-Step 5 $totalSteps "Replacing database prefix"
    if ($DbPrefix -ne $oldDbPrefix) {
        Replace-InAllFiles -Find $oldDbPrefix -Replace $DbPrefix
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 6: Replace global variable
    Write-Step 6 $totalSteps "Replacing global variable name"
    if ($PluginSlug -ne $oldSlug) {
        $oldGlobalVar = '$' + ($oldSlug -replace '-', '_') + '_context'
        $newGlobalVar = '$' + ($PluginSlug -replace '-', '_') + '_context'
        Replace-InFile -FilePath $mainPluginFile -Find $oldGlobalVar -Replace $newGlobalVar
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 7: Update composer.json package name
    Write-Step 7 $totalSteps "Updating composer.json package name"
    if ($VendorName -ne $oldVendor -or $PluginSlug -ne $oldSlug) {
        Replace-InFile -FilePath "composer.json" -Find "$oldVendor/$oldSlug" -Replace "$VendorName/$PluginSlug"
        # Also update if still has scaffold name
        Replace-InFile -FilePath "composer.json" -Find "wpdiggerstudio/wpzylos-scaffold" -Replace "$VendorName/$PluginSlug"
        Write-Done
    }
    else {
        Write-Skip
    }

    # Step 8: Update author information
    Write-Step 8 $totalSteps "Updating author information"
    Replace-InFile -FilePath $mainPluginFile -Find "Your Name" -Replace $AuthorName
    Replace-InFile -FilePath $mainPluginFile -Find "https://example.com/$oldSlug" -Replace $PluginUri
    Replace-InFile -FilePath $mainPluginFile -Find "https://example.com" -Replace $AuthorUri
    Replace-InFile -FilePath "readme.txt" -Find "your-username" -Replace (ConvertTo-VendorName $AuthorName)
    Write-Done

    # Step 9: Rename main plugin file
    Write-Step 9 $totalSteps "Renaming plugin file"
    if ((Test-Path $mainPluginFile) -and $PluginSlug -ne $oldSlug) {
        Replace-InFile -FilePath "scoper.inc.php" -Find $mainPluginFile -Replace "$PluginSlug.php"
        Replace-InFile -FilePath "uninstall.php" -Find $mainPluginFile -Replace "$PluginSlug.php"
        Rename-Item -Path $mainPluginFile -NewName "$PluginSlug.php"
        Write-Done
    }
    else {
        Write-Skip
    }

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
    Write-Host "  Plugin '$PluginName' configured!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration saved to: .plugin-config.json" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Run: composer install" -ForegroundColor Gray
    Write-Host "  2. Develop your plugin" -ForegroundColor Gray
    Write-Host "  3. Build: .\scaffold.ps1 build" -ForegroundColor Gray
    Write-Host ""

}
finally {
    Pop-Location
}
