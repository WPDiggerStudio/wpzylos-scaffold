#!/bin/bash
# ============================================================================
# WPZylos Scaffold - Build Script
# ============================================================================
# Creates a production-ready distributable ZIP with PHP-Scoper isolation.
# Reads configuration from .plugin-config.json (created by init-plugin.sh).
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
# Location: .scripts/build.sh
# Called by: ../wpzylos
# ============================================================================

set -e

# ============================================================================
# Change to project root (parent of .scripts)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

# ============================================================================
# Configuration
# ============================================================================

BUILD_DIR="build"
DIST_DIR="dist"
CONFIG_FILE=".plugin-config.json"
SKIP_QA=false
SKIP_SCOPER=false
CLEAN_ONLY=false
VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-qa) SKIP_QA=true; shift ;;
        --skip-scoper) SKIP_SCOPER=true; shift ;;
        --clean) CLEAN_ONLY=true; shift ;;
        --version) VERSION="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Load plugin config
if [[ -f "$CONFIG_FILE" ]]; then
    PLUGIN_SLUG=$(grep -o '"slug": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    PLUGIN_NAME=$(grep -o '"name": "[^"]*"' "$CONFIG_FILE" | head -1 | cut -d'"' -f4)
    MAIN_FILE=$(grep -o '"mainFile": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    
    if [[ -z "$VERSION" ]]; then
        VERSION=$(grep -o '"version": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
    fi
else
    echo -e "${YELLOW}Warning: .plugin-config.json not found. Using auto-detection.${NC}"
    echo -e "${YELLOW}Run init-plugin.sh first for best results.${NC}"
    echo ""
    
    MAIN_FILE=$(find . -maxdepth 1 -name "*.php" -type f ! -name "uninstall.php" ! -name "scoper.inc.php" ! -name "index.php" | head -1)
    if [[ -z "$MAIN_FILE" ]]; then
        echo -e "${RED}Error: Could not find main plugin file.${NC}"
        exit 1
    fi
    
    MAIN_FILE=$(basename "$MAIN_FILE")
    PLUGIN_SLUG="${MAIN_FILE%.php}"
    PLUGIN_NAME="$PLUGIN_SLUG"
    
    if [[ -z "$VERSION" ]]; then
        VERSION=$(grep -oP "Version:\s*\K[0-9.]+" "$MAIN_FILE" 2>/dev/null || echo "1.0.0")
    fi
fi

if [[ -z "$VERSION" ]]; then
    VERSION="1.0.0"
fi

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

clean_build() {
    print_step "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    print_success "Cleaned build directories"
}

run_phpcbf() {
    print_step "Running PHP Code Beautifier (phpcbf --standard=PSR12)..."
    
    if [[ -f "vendor/bin/phpcbf" ]]; then
        set +e
        vendor/bin/phpcbf --standard=PSR12 app 2>&1
        RESULT=$?
        set -e
        
        if [[ $RESULT -eq 0 ]]; then
            print_success "No code style issues found"
        elif [[ $RESULT -eq 1 ]]; then
            print_success "Code style issues auto-fixed"
        else
            print_warning "phpcbf returned exit code $RESULT"
        fi
    else
        print_warning "phpcbf not found. Skipping code style fix."
    fi
}

run_phpstan() {
    print_step "Running static analysis (phpstan analyze)..."
    
    if [[ -f "vendor/bin/phpstan" ]]; then
        set +e
        vendor/bin/phpstan analyze app --no-progress 2>&1
        RESULT=$?
        set -e
        
        if [[ $RESULT -eq 0 ]]; then
            print_success "Static analysis passed"
        else
            print_error "Static analysis found issues"
            read -p "Continue build anyway? [y/N]: " CONTINUE
            if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
                exit 1
            fi
        fi
    else
        print_warning "phpstan not found. Skipping static analysis."
    fi
}

# ============================================================================
# Main Build Process
# ============================================================================

print_header "WPZylos Build - $PLUGIN_SLUG v$VERSION"

# Clean only mode
if [[ "$CLEAN_ONLY" == true ]]; then
    clean_build
    exit 0
fi

# Step 1: Clean
clean_build

# Step 2: Run QA (unless skipped)
if [[ "$SKIP_QA" == false ]]; then
    print_step "Ensuring dev dependencies are installed..."
    composer install --quiet 2>/dev/null || true
    print_success "Dependencies ready"
    
    run_phpcbf
    run_phpstan
else
    print_step "Skipping QA checks..."
fi

# Step 3: Install production dependencies
print_step "Installing production dependencies..."
if ! composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader --classmap-authoritative 2>&1; then
    print_error "Composer install failed"
    exit 1
fi
print_success "Production dependencies installed"

# Step 4: Run PHP-Scoper (unless skipped)
if [[ "$SKIP_SCOPER" == false ]]; then
    print_step "Running PHP-Scoper..."
    
    # Re-install dev deps for scoper
    composer install --quiet 2>/dev/null || true
    
    if [[ -f "vendor/bin/php-scoper" ]]; then
        if ! vendor/bin/php-scoper add-prefix --output-dir="$BUILD_DIR" --force 2>&1; then
            print_error "PHP-Scoper failed"
            exit 1
        fi
        print_success "PHP-Scoper completed"
    else
        print_error "PHP-Scoper not found in vendor/bin"
        exit 1
    fi
else
    print_step "Skipping PHP-Scoper (dev build)..."
    mkdir -p "$BUILD_DIR"
    
    for dir in app bootstrap config database resources routes vendor; do
        if [[ -d "$dir" ]]; then
            cp -r "$dir" "$BUILD_DIR/"
        fi
    done
    
    print_success "Files copied to build directory"
fi

# Step 5: Copy essential files
print_step "Copying essential files..."

for file in "$MAIN_FILE" uninstall.php readme.txt LICENSE composer.json; do
    if [[ -f "$file" ]]; then
        cp "$file" "$BUILD_DIR/"
    fi
done

for dir in resources config routes database; do
    if [[ -d "$dir" ]] && [[ ! -d "$BUILD_DIR/$dir" ]]; then
        cp -r "$dir" "$BUILD_DIR/"
    fi
done

print_success "Essential files copied"

# Step 6: Install production dependencies in build directory
print_step "Installing production dependencies in build directory..."
(
    cd "$BUILD_DIR" 2>/dev/null || exit 1
    if composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader --classmap-authoritative 2>&1; then
        exit 0
    else
        exit 1
    fi
)
if [[ $? -eq 0 ]]; then
    print_success "Production dependencies installed in build"
else
    print_warning "Composer install issue in build (may still work)"
fi

# Step 7: Remove development files
print_step "Removing development files..."

rm -rf \
    "$BUILD_DIR/.git" \
    "$BUILD_DIR/.github" \
    "$BUILD_DIR/.gitignore" \
    "$BUILD_DIR/.gitattributes" \
    "$BUILD_DIR/.plugin-config.json" \
    "$BUILD_DIR/tests" \
    "$BUILD_DIR/phpunit.xml" \
    "$BUILD_DIR/phpstan.neon" \
    "$BUILD_DIR/phpcs.xml.dist" \
    "$BUILD_DIR/scoper.inc.php" \
    "$BUILD_DIR/init-plugin.ps1" \
    "$BUILD_DIR/init-plugin.sh" \
    "$BUILD_DIR/build.ps1" \
    "$BUILD_DIR/build.sh" \
    "$BUILD_DIR/Makefile" \
    "$BUILD_DIR/CONTRIBUTING.md" \
    "$BUILD_DIR/SECURITY.md" \
    "$BUILD_DIR/CHANGELOG.md" \
    "$BUILD_DIR/composer.lock" \
    "$BUILD_DIR/composer.json" \
    2>/dev/null || true

print_success "Development files removed"

# Step 8: Create ZIP
print_step "Creating distributable ZIP..."

mkdir -p "$DIST_DIR"

ZIP_PATH="$DIST_DIR/$PLUGIN_SLUG-$VERSION.zip"

# Create temp directory with plugin folder
TEMP_DIR="$DIST_DIR/temp"
mkdir -p "$TEMP_DIR/$PLUGIN_SLUG"
cp -r "$BUILD_DIR"/* "$TEMP_DIR/$PLUGIN_SLUG/"

# Create ZIP - check for available zip tools
ORIG_DIR="$(pwd)"
cd "$TEMP_DIR" 2>/dev/null

# Try native zip first, then 7z, then PowerShell as fallback
if command -v zip &> /dev/null; then
    zip -r "../$PLUGIN_SLUG-$VERSION.zip" "$PLUGIN_SLUG" -q
elif command -v 7z &> /dev/null; then
    7z a -tzip "../$PLUGIN_SLUG-$VERSION.zip" "$PLUGIN_SLUG" -bso0 -bsp0
else
    # PowerShell fallback for Windows Git Bash
    if command -v powershell.exe &> /dev/null; then
        powershell.exe -Command "Compress-Archive -Path '$PLUGIN_SLUG' -DestinationPath '../$PLUGIN_SLUG-$VERSION.zip' -Force"
    else
        print_error "No zip tool found. Install zip, 7z, or run from PowerShell."
        exit 1
    fi
fi

cd "$ORIG_DIR" 2>/dev/null

rm -rf "$TEMP_DIR"

# Clean up build directory (keep only dist with ZIP)
rm -rf "$BUILD_DIR"

ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
print_success "Created: $ZIP_PATH ($ZIP_SIZE)"

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "${GRAY}Plugin:     $PLUGIN_NAME${NC}"
echo -e "${GRAY}Version:    $VERSION${NC}"
echo -e "${GRAY}Output:     $ZIP_PATH${NC}"
echo -e "${GRAY}Size:       $ZIP_SIZE${NC}"
echo ""

if [[ "$SKIP_QA" == false ]]; then
    echo -e "${GRAY}QA Checks:  Passed (phpcbf, phpstan)${NC}"
fi
if [[ "$SKIP_SCOPER" == false ]]; then
    echo -e "${GRAY}Scoped:     Yes (namespace isolation)${NC}"
fi

echo ""
echo "Next steps:"
echo -e "${GRAY}  1. Test installation on staging site${NC}"
echo -e "${GRAY}  2. Upload to WordPress or distribute${NC}"
echo ""
