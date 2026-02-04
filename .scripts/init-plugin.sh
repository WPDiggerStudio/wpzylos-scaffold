#!/bin/bash
# ============================================================================
# WPZylos Scaffold - Plugin Initializer
# ============================================================================
# This script automates the customization of wpzylos-scaffold for new plugins.
# After initialization, configuration is saved to .plugin-config.json for
# the build script to use.
#
# Location: .scripts/init-plugin.sh
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
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}  WPZylos Scaffold - Plugin Initializer${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_step() {
    echo -ne "${YELLOW}[$1/$2] $3... ${NC}"
}

print_done() {
    echo -e "${GREEN}Done${NC}"
}

# Convert "My Awesome Plugin" to "my-awesome-plugin"
to_slug() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'
}

# Convert "my-awesome-plugin" to "MyAwesomePlugin"
to_namespace() {
    echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | tr -d ' '
}

# Convert "my-awesome-plugin" to "my_awesome_plugin"
to_scoper_prefix() {
    echo "$1" | tr '-' '_'
}

# Convert "my-awesome-plugin" to "myawesomeplugin_"
to_db_prefix() {
    echo "$1" | tr -d '-' | sed 's/$/_/'
}

# Convert "Your Name" to "yourname"
to_vendor() {
    echo "$1" | tr -d ' ' | tr '[:upper:]' '[:lower:]'
}

# Read with default value
read_with_default() {
    local prompt="$1"
    local default="$2"
    local input
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Replace in file
replace_in_file() {
    local file="$1"
    local find="$2"
    local replace="$3"
    if [[ -f "$file" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|${find}|${replace}|g" "$file"
        else
            sed -i "s|${find}|${replace}|g" "$file"
        fi
    fi
}

# Replace in all files (excluding vendor and .git)
replace_in_all_files() {
    local find="$1"
    local replace="$2"
    find . -type f \( -name "*.php" -o -name "*.json" -o -name "*.txt" -o -name "*.md" \) \
        -not -path "./vendor/*" -not -path "./.git/*" | while read -r file; do
        if grep -q "$find" "$file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|${find}|${replace}|g" "$file"
            else
                sed -i "s|${find}|${replace}|g" "$file"
            fi
        fi
    done
}

# Save plugin config to JSON
save_plugin_config() {
    cat > .plugin-config.json << EOF
{
  "initialized": true,
  "timestamp": "$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)",
  "plugin": {
    "name": "$PLUGIN_NAME",
    "slug": "$PLUGIN_SLUG",
    "namespace": "$NAMESPACE",
    "scoperPrefix": "$SCOPER_PREFIX",
    "dbPrefix": "$DB_PREFIX",
    "version": "$VERSION",
    "mainFile": "$PLUGIN_SLUG.php"
  },
  "author": {
    "name": "$AUTHOR_NAME",
    "uri": "$AUTHOR_URI"
  },
  "composer": {
    "vendor": "$VENDOR_NAME",
    "name": "$VENDOR_NAME/$PLUGIN_SLUG"
  }
}
EOF
}

# ============================================================================
# Main Script
# ============================================================================

print_header

# Check if we're in the scaffold directory
if [[ ! -f "my-plugin.php" ]]; then
    echo -e "${RED}Error: 'my-plugin.php' not found.${NC}"
    echo -e "${RED}Please run this script from the wpzylos-scaffold root directory.${NC}"
    exit 1
fi

# Check if already initialized
if [[ -f ".plugin-config.json" ]]; then
    echo -e "${YELLOW}Warning: Plugin already initialized.${NC}"
    EXISTING_NAME=$(grep -o '"name": "[^"]*"' .plugin-config.json | head -1 | cut -d'"' -f4)
    echo -e "${GRAY}  Current plugin: $EXISTING_NAME${NC}"
    read -p "Re-initialize? [y/N]: " CONTINUE
    if [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]]; then
        exit 0
    fi
fi

# ============================================================================
# Collect Information
# ============================================================================

echo "Enter your plugin display name (e.g., 'WP BRA Calculator'):"
read -p "> " PLUGIN_NAME

if [[ -z "$PLUGIN_NAME" ]]; then
    echo -e "${RED}Error: Plugin name is required.${NC}"
    exit 1
fi

# Derive defaults
DEFAULT_SLUG=$(to_slug "$PLUGIN_NAME")
DEFAULT_NAMESPACE=$(to_namespace "$DEFAULT_SLUG")
DEFAULT_SCOPER_PREFIX=$(to_scoper_prefix "$DEFAULT_SLUG")
DEFAULT_DB_PREFIX=$(to_db_prefix "$DEFAULT_SLUG")

echo ""
echo "Derived values (press Enter to accept, or type to override):"

PLUGIN_SLUG=$(read_with_default "  Plugin Slug" "$DEFAULT_SLUG")
NAMESPACE=$(read_with_default "  PHP Namespace" "$DEFAULT_NAMESPACE")
SCOPER_PREFIX=$(read_with_default "  Scoper Prefix" "$DEFAULT_SCOPER_PREFIX")
DB_PREFIX=$(read_with_default "  Database Prefix" "$DEFAULT_DB_PREFIX")

echo ""
echo "Author information (press Enter to skip):"
AUTHOR_NAME=$(read_with_default "  Author Name" "Your Name")
AUTHOR_URI=$(read_with_default "  Author URI" "https://example.com")
PLUGIN_URI=$(read_with_default "  Plugin URI" "https://example.com/$PLUGIN_SLUG")

# Vendor name
DEFAULT_VENDOR=$(to_vendor "$AUTHOR_NAME")
VENDOR_NAME=$(read_with_default "  Vendor Name (for composer)" "$DEFAULT_VENDOR")

VERSION="1.0.0"

echo ""
echo "Summary:"
echo -e "${GRAY}  Plugin Name:    $PLUGIN_NAME${NC}"
echo -e "${GRAY}  Plugin Slug:    $PLUGIN_SLUG${NC}"
echo -e "${GRAY}  Namespace:      $NAMESPACE${NC}"
echo -e "${GRAY}  Scoper Prefix:  $SCOPER_PREFIX${NC}"
echo -e "${GRAY}  DB Prefix:      $DB_PREFIX${NC}"
echo -e "${GRAY}  Vendor:         $VENDOR_NAME${NC}"
echo -e "${GRAY}  Composer Name:  $VENDOR_NAME/$PLUGIN_SLUG${NC}"
echo ""

read -p "Proceed with initialization? [Y/n]: " CONFIRM
if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo ""

# ============================================================================
# Perform Replacements
# ============================================================================

TOTAL_STEPS=10

# Step 1: Replace display name
print_step 1 $TOTAL_STEPS "Replacing display name 'My Plugin'"
replace_in_all_files "My Plugin" "$PLUGIN_NAME"
print_done

# Step 2: Replace plugin slug (hyphenated)
print_step 2 $TOTAL_STEPS "Replacing plugin slug 'my-plugin'"
replace_in_all_files "my-plugin" "$PLUGIN_SLUG"
print_done

# Step 3: Replace namespace
print_step 3 $TOTAL_STEPS "Replacing namespace 'MyPlugin'"
replace_in_all_files "MyPlugin" "$NAMESPACE"
print_done

# Step 4: Replace scoper prefix (underscored)
print_step 4 $TOTAL_STEPS "Replacing scoper prefix 'my_plugin'"
replace_in_file "scoper.inc.php" "my_plugin" "$SCOPER_PREFIX"
print_done

# Step 5: Replace database prefix
print_step 5 $TOTAL_STEPS "Replacing database prefix 'myplugin_'"
replace_in_all_files "myplugin_" "$DB_PREFIX"
print_done

# Step 6: Replace global variable
print_step 6 $TOTAL_STEPS "Replacing global variable name"
GLOBAL_VAR_OLD='\$my_plugin_context'
GLOBAL_VAR_NEW='\$'"$(echo "$PLUGIN_SLUG" | tr '-' '_')"'_context'
replace_in_file "my-plugin.php" "$GLOBAL_VAR_OLD" "$GLOBAL_VAR_NEW"
print_done

# Step 7: Update composer.json package name
print_step 7 $TOTAL_STEPS "Updating composer.json package name"
replace_in_file "composer.json" "wpdiggerstudio/wpzylos-scaffold" "$VENDOR_NAME/$PLUGIN_SLUG"
print_done

# Step 8: Update author information
print_step 8 $TOTAL_STEPS "Updating author information"
replace_in_file "my-plugin.php" "Your Name" "$AUTHOR_NAME"
replace_in_file "my-plugin.php" "https://example.com/my-plugin" "$PLUGIN_URI"
replace_in_file "my-plugin.php" "https://example.com" "$AUTHOR_URI"
AUTHOR_USERNAME=$(to_vendor "$AUTHOR_NAME")
replace_in_file "readme.txt" "your-username" "$AUTHOR_USERNAME"
print_done

# Step 9: Rename main plugin file
print_step 9 $TOTAL_STEPS "Renaming my-plugin.php to $PLUGIN_SLUG.php"
if [[ -f "my-plugin.php" ]]; then
    replace_in_file "Makefile" "my-plugin.php" "$PLUGIN_SLUG.php"
    replace_in_file "scoper.inc.php" "my-plugin.php" "$PLUGIN_SLUG.php"
    replace_in_file "uninstall.php" "my-plugin.php" "$PLUGIN_SLUG.php"
    mv "my-plugin.php" "$PLUGIN_SLUG.php"
fi
print_done

# Step 10: Save configuration
print_step 10 $TOTAL_STEPS "Saving plugin configuration"
save_plugin_config
print_done

# ============================================================================
# Post-Processing
# ============================================================================

echo ""
echo -e "${YELLOW}Running composer dump-autoload...${NC}"

if composer dump-autoload 2>/dev/null; then
    print_success "Composer autoload updated"
else
    echo -e "${YELLOW}Warning: composer dump-autoload failed. Run it manually.${NC}"
fi

# ============================================================================
# Success Message
# ============================================================================

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  Plugin '$PLUGIN_NAME' initialized!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Configuration saved to: .plugin-config.json"
echo ""
echo "Files modified:"
echo -e "${GRAY}  - $PLUGIN_SLUG.php (main plugin file)${NC}"
echo -e "${GRAY}  - composer.json (package: $VENDOR_NAME/$PLUGIN_SLUG)${NC}"
echo -e "${GRAY}  - scoper.inc.php${NC}"
echo -e "${GRAY}  - Makefile${NC}"
echo -e "${GRAY}  - uninstall.php${NC}"
echo -e "${GRAY}  - readme.txt${NC}"
echo ""
echo "Next steps:"
echo -e "${GRAY}  1. Run: composer install${NC}"
echo -e "${GRAY}  2. Develop your plugin${NC}"
echo -e "${GRAY}  3. Build: ./build.sh${NC}"
echo ""
