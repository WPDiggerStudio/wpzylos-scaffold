#!/bin/bash
# ============================================================================
# WPZylos Scaffold - Plugin Initializer (Intelligent)
# ============================================================================
# Handles all scenarios:
# - Fresh install (my-plugin.php exists)
# - Re-configuration (update existing config)
# - Config deleted (detect from renamed files)
# - Partial updates (only change specific values)
#
# Location: .scripts/init-plugin.sh
# Called by: ../scaffold.sh
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
WHITE='\033[1;37m'
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

print_skip() {
    echo -e "${GRAY}Skipped${NC}"
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

# Read with default value, showing current if exists
# Uses -r to preserve backslashes, -e for readline support
read_with_default() {
    local prompt="$1"
    local default="$2"
    local input
    # -r: don't interpret backslashes
    # -e: use readline for editing (handles arrow keys properly)
    read -r -e -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Normalize namespace: convert any number of consecutive backslashes to single
# Handles: \ , \\ , \\\ all become single \
normalize_namespace() {
    local ns="$1"
    # Replace 3+ backslashes with single, then 2 with single
    # This handles \\\ -> \ and \\ -> \ while preserving single \
    printf '%s' "$ns" | sed -e 's/\\\\\\\\/\\/g' -e 's/\\\\/\\/g'
}

# Escape string for use in sed replacement
# Escapes: backslash, ampersand, and the delimiter (|)
escape_for_sed() {
    local str="$1"
    # First escape backslashes, then ampersand, then pipe (our delimiter)
    printf '%s' "$str" | sed -e 's/\\/\\\\/g' -e 's/[&|]/\\&/g'
}

# Replace in file (handles backslashes properly)
replace_in_file() {
    local file="$1"
    local find="$2"
    local replace="$3"
    if [[ -f "$file" ]]; then
        local escaped_find
        local escaped_replace
        escaped_find=$(escape_for_sed "$find")
        escaped_replace=$(escape_for_sed "$replace")
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|${escaped_find}|${escaped_replace}|g" "$file"
        else
            sed -i "s|${escaped_find}|${escaped_replace}|g" "$file"
        fi
    fi
}

# Replace in all files (excluding vendor and .git)
replace_in_all_files() {
    local find="$1"
    local replace="$2"
    local escaped_find
    local escaped_replace
    escaped_find=$(escape_for_sed "$find")
    escaped_replace=$(escape_for_sed "$replace")
    find . -type f \( -name "*.php" -o -name "*.json" -o -name "*.txt" -o -name "*.md" \) \
        -not -path "./vendor/*" -not -path "./.git/*" -not -path "./.scripts/*" | while read -r file; do
        if grep -qF "$find" "$file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|${escaped_find}|${escaped_replace}|g" "$file"
            else
                sed -i "s|${escaped_find}|${escaped_replace}|g" "$file"
            fi
        fi
    done
}

# Save plugin config to JSON
save_plugin_config() {
    # Escape backslashes for JSON (single backslash becomes double)
    local json_namespace
    json_namespace=$(printf '%s' "$NAMESPACE" | sed 's/\\/\\\\/g')
    
    cat > .plugin-config.json << EOF
{
  "initialized": true,
  "timestamp": "$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)",
  "plugin": {
    "name": "$PLUGIN_NAME",
    "slug": "$PLUGIN_SLUG",
    "namespace": "$json_namespace",
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

# Detect current state
detect_state() {
    IS_FRESH=false
    HAS_CONFIG=false
    CURRENT_SLUG=""
    CURRENT_NAME=""
    CURRENT_NAMESPACE=""
    CURRENT_SCOPER_PREFIX=""
    CURRENT_DB_PREFIX=""
    CURRENT_AUTHOR_NAME=""
    CURRENT_AUTHOR_URI=""
    CURRENT_VENDOR=""
    
    # Check for config file
    if [[ -f ".plugin-config.json" ]]; then
        HAS_CONFIG=true
        CURRENT_NAME=$(grep -o '"name": "[^"]*"' .plugin-config.json | head -1 | cut -d'"' -f4)
        CURRENT_SLUG=$(grep -o '"slug": "[^"]*"' .plugin-config.json | cut -d'"' -f4)
        # Namespace: read from JSON and normalize (handles \\ or \\\\)
        local raw_ns
        raw_ns=$(grep -o '"namespace": "[^"]*"' .plugin-config.json | cut -d'"' -f4)
        CURRENT_NAMESPACE=$(normalize_namespace "$raw_ns")
        CURRENT_SCOPER_PREFIX=$(grep -o '"scoperPrefix": "[^"]*"' .plugin-config.json | cut -d'"' -f4)
        CURRENT_DB_PREFIX=$(grep -o '"dbPrefix": "[^"]*"' .plugin-config.json | cut -d'"' -f4)
        CURRENT_AUTHOR_NAME=$(grep -o '"name": "[^"]*"' .plugin-config.json | tail -1 | cut -d'"' -f4)
        CURRENT_AUTHOR_URI=$(grep -o '"uri": "[^"]*"' .plugin-config.json | head -1 | cut -d'"' -f4)
        CURRENT_VENDOR=$(grep -o '"vendor": "[^"]*"' .plugin-config.json | cut -d'"' -f4)
    fi
    
    # Check for fresh install
    if [[ -f "my-plugin.php" ]]; then
        IS_FRESH=true
    fi
    
    # If no config but not fresh, try to detect from files
    if [[ "$HAS_CONFIG" == "false" && "$IS_FRESH" == "false" ]]; then
        # Find the main plugin file (*.php with Plugin Name header in root)
        MAIN_FILE=$(grep -l "Plugin Name:" *.php 2>/dev/null | head -1)
        if [[ -n "$MAIN_FILE" ]]; then
            CURRENT_SLUG="${MAIN_FILE%.php}"
            CURRENT_NAME=$(grep -oP "Plugin Name:\s*\K.*" "$MAIN_FILE" | head -1 | xargs)
            # Try to detect namespace from composer.json
            if [[ -f "composer.json" ]]; then
                local raw_ns_composer
                raw_ns_composer=$(grep -oP '"[^"]+\\\\\\\\": "app/"' composer.json 2>/dev/null | head -1 | cut -d'"' -f2)
                CURRENT_NAMESPACE=$(normalize_namespace "$raw_ns_composer")
            fi
        fi
    fi
}

# ============================================================================
# Main Script
# ============================================================================

print_header

# Detect current state
detect_state

# Show current status
if [[ "$IS_FRESH" == "true" ]]; then
    echo -e "${GREEN}Fresh scaffold detected.${NC}"
    echo ""
elif [[ "$HAS_CONFIG" == "true" ]]; then
    echo -e "${CYAN}Current Configuration:${NC}"
    echo -e "  ${GRAY}Plugin Name:${NC}  $CURRENT_NAME"
    echo -e "  ${GRAY}Slug:${NC}         $CURRENT_SLUG"
    echo -e "  ${GRAY}Namespace:${NC}    $CURRENT_NAMESPACE"
    echo -e "  ${GRAY}DB Prefix:${NC}    $CURRENT_DB_PREFIX"
    echo -e "  ${GRAY}Vendor:${NC}       $CURRENT_VENDOR"
    echo ""
    echo -e "${YELLOW}You can update any value or press Enter to keep current.${NC}"
    echo ""
elif [[ -n "$CURRENT_SLUG" ]]; then
    echo -e "${YELLOW}Config file missing but plugin detected: $CURRENT_SLUG${NC}"
    echo -e "${GRAY}Values will be auto-detected where possible.${NC}"
    echo ""
else
    echo -e "${RED}Error: Cannot detect plugin state.${NC}"
    echo -e "${RED}Expected 'my-plugin.php' for fresh install or '.plugin-config.json' for existing.${NC}"
    exit 1
fi

# ============================================================================
# Collect Information
# ============================================================================

# Set defaults based on state
if [[ "$IS_FRESH" == "true" ]]; then
    DEFAULT_NAME="My Plugin"
    DEFAULT_SLUG="my-plugin"
    DEFAULT_NAMESPACE="MyPlugin"
    DEFAULT_SCOPER_PREFIX="my_plugin"
    DEFAULT_DB_PREFIX="myplugin_"
    DEFAULT_AUTHOR_NAME="Your Name"
    DEFAULT_AUTHOR_URI="https://example.com"
    DEFAULT_VENDOR="yourname"
else
    DEFAULT_NAME="${CURRENT_NAME:-My Plugin}"
    DEFAULT_SLUG="${CURRENT_SLUG:-my-plugin}"
    DEFAULT_NAMESPACE="${CURRENT_NAMESPACE:-MyPlugin}"
    DEFAULT_SCOPER_PREFIX="${CURRENT_SCOPER_PREFIX:-my_plugin}"
    DEFAULT_DB_PREFIX="${CURRENT_DB_PREFIX:-myplugin_}"
    DEFAULT_AUTHOR_NAME="${CURRENT_AUTHOR_NAME:-Your Name}"
    DEFAULT_AUTHOR_URI="${CURRENT_AUTHOR_URI:-https://example.com}"
    DEFAULT_VENDOR="${CURRENT_VENDOR:-yourname}"
fi

echo "Enter your plugin display name (or press Enter to keep current):"
PLUGIN_NAME=$(read_with_default "> Plugin Name" "$DEFAULT_NAME")

# Only derive new values if name changed
if [[ "$PLUGIN_NAME" != "$DEFAULT_NAME" ]]; then
    DERIVED_SLUG=$(to_slug "$PLUGIN_NAME")
    DERIVED_NAMESPACE=$(to_namespace "$DERIVED_SLUG")
    DERIVED_SCOPER_PREFIX=$(to_scoper_prefix "$DERIVED_SLUG")
    DERIVED_DB_PREFIX=$(to_db_prefix "$DERIVED_SLUG")
else
    DERIVED_SLUG="$DEFAULT_SLUG"
    DERIVED_NAMESPACE="$DEFAULT_NAMESPACE"
    DERIVED_SCOPER_PREFIX="$DEFAULT_SCOPER_PREFIX"
    DERIVED_DB_PREFIX="$DEFAULT_DB_PREFIX"
fi

echo ""
echo "Derived/Current values (press Enter to accept, or type to override):"

PLUGIN_SLUG=$(read_with_default "  Plugin Slug" "$DERIVED_SLUG")
NAMESPACE=$(read_with_default "  PHP Namespace" "$DERIVED_NAMESPACE")
# Normalize namespace: convert \\ or \\\ to single \
NAMESPACE=$(normalize_namespace "$NAMESPACE")
SCOPER_PREFIX=$(read_with_default "  Scoper Prefix" "$DERIVED_SCOPER_PREFIX")
DB_PREFIX=$(read_with_default "  Database Prefix" "$DERIVED_DB_PREFIX")

echo ""
echo "Author information (press Enter to keep current):"
AUTHOR_NAME=$(read_with_default "  Author Name" "$DEFAULT_AUTHOR_NAME")
AUTHOR_URI=$(read_with_default "  Author URI" "$DEFAULT_AUTHOR_URI")
PLUGIN_URI=$(read_with_default "  Plugin URI" "https://example.com/$PLUGIN_SLUG")

# Vendor name
if [[ "$AUTHOR_NAME" != "$DEFAULT_AUTHOR_NAME" ]]; then
    NEW_DEFAULT_VENDOR=$(to_vendor "$AUTHOR_NAME")
else
    NEW_DEFAULT_VENDOR="$DEFAULT_VENDOR"
fi
VENDOR_NAME=$(read_with_default "  Vendor Name (for composer)" "$NEW_DEFAULT_VENDOR")

VERSION="${CURRENT_VERSION:-1.0.0}"

# Determine what needs to change
OLD_NAME="${CURRENT_NAME:-My Plugin}"
OLD_SLUG="${CURRENT_SLUG:-my-plugin}"
OLD_NAMESPACE="${CURRENT_NAMESPACE:-MyPlugin}"
OLD_SCOPER_PREFIX="${CURRENT_SCOPER_PREFIX:-my_plugin}"
OLD_DB_PREFIX="${CURRENT_DB_PREFIX:-myplugin_}"
OLD_VENDOR="${CURRENT_VENDOR:-wpdiggerstudio}"

# For fresh install, use scaffold defaults
if [[ "$IS_FRESH" == "true" ]]; then
    OLD_NAME="My Plugin"
    OLD_SLUG="my-plugin"
    OLD_NAMESPACE="MyPlugin"
    OLD_SCOPER_PREFIX="my_plugin"
    OLD_DB_PREFIX="myplugin_"
    OLD_VENDOR="wpdiggerstudio"
fi

echo ""
echo -e "${WHITE}Summary:${NC}"
echo -e "  ${GRAY}Plugin Name:${NC}    $PLUGIN_NAME"
echo -e "  ${GRAY}Plugin Slug:${NC}    $PLUGIN_SLUG"
echo -e "  ${GRAY}Namespace:${NC}      $NAMESPACE"
echo -e "  ${GRAY}Scoper Prefix:${NC}  $SCOPER_PREFIX"
echo -e "  ${GRAY}DB Prefix:${NC}      $DB_PREFIX"
echo -e "  ${GRAY}Vendor:${NC}         $VENDOR_NAME"
echo -e "  ${GRAY}Composer Name:${NC}  $VENDOR_NAME/$PLUGIN_SLUG"
echo ""

read -r -p "Proceed with initialization? [Y/n]: " CONFIRM
if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo ""

# ============================================================================
# Perform Replacements (only if values changed)
# ============================================================================

TOTAL_STEPS=10
MAIN_PLUGIN_FILE="${OLD_SLUG}.php"
if [[ "$IS_FRESH" == "true" ]]; then
    MAIN_PLUGIN_FILE="my-plugin.php"
fi

# Step 1: Replace display name
print_step 1 $TOTAL_STEPS "Replacing display name"
if [[ "$PLUGIN_NAME" != "$OLD_NAME" ]]; then
    replace_in_all_files "$OLD_NAME" "$PLUGIN_NAME"
    print_done
else
    print_skip
fi

# Step 2: Replace plugin slug
print_step 2 $TOTAL_STEPS "Replacing plugin slug"
if [[ "$PLUGIN_SLUG" != "$OLD_SLUG" ]]; then
    replace_in_all_files "$OLD_SLUG" "$PLUGIN_SLUG"
    print_done
else
    print_skip
fi

# Step 3: Replace namespace
print_step 3 $TOTAL_STEPS "Replacing namespace"
if [[ "$NAMESPACE" != "$OLD_NAMESPACE" ]]; then
    replace_in_all_files "$OLD_NAMESPACE" "$NAMESPACE"
    print_done
else
    print_skip
fi

# Step 4: Replace scoper prefix
print_step 4 $TOTAL_STEPS "Replacing scoper prefix"
if [[ "$SCOPER_PREFIX" != "$OLD_SCOPER_PREFIX" ]]; then
    replace_in_file "scoper.inc.php" "$OLD_SCOPER_PREFIX" "$SCOPER_PREFIX"
    print_done
else
    print_skip
fi

# Step 5: Replace database prefix
print_step 5 $TOTAL_STEPS "Replacing database prefix"
if [[ "$DB_PREFIX" != "$OLD_DB_PREFIX" ]]; then
    replace_in_all_files "$OLD_DB_PREFIX" "$DB_PREFIX"
    print_done
else
    print_skip
fi

# Step 6: Replace global variable
print_step 6 $TOTAL_STEPS "Replacing global variable name"
if [[ "$PLUGIN_SLUG" != "$OLD_SLUG" ]]; then
    OLD_GLOBAL_VAR="\$$(echo "$OLD_SLUG" | tr '-' '_')_context"
    NEW_GLOBAL_VAR="\$$(echo "$PLUGIN_SLUG" | tr '-' '_')_context"
    replace_in_file "$MAIN_PLUGIN_FILE" "$OLD_GLOBAL_VAR" "$NEW_GLOBAL_VAR"
    print_done
else
    print_skip
fi

# Step 7: Update composer.json package name
print_step 7 $TOTAL_STEPS "Updating composer.json package name"
if [[ "$VENDOR_NAME" != "$OLD_VENDOR" || "$PLUGIN_SLUG" != "$OLD_SLUG" ]]; then
    replace_in_file "composer.json" "$OLD_VENDOR/$OLD_SLUG" "$VENDOR_NAME/$PLUGIN_SLUG"
    # Also update if still has scaffold name
    replace_in_file "composer.json" "wpdiggerstudio/wpzylos-scaffold" "$VENDOR_NAME/$PLUGIN_SLUG"
    print_done
else
    print_skip
fi

# Step 8: Update author information
print_step 8 $TOTAL_STEPS "Updating author information"
replace_in_file "$MAIN_PLUGIN_FILE" "Your Name" "$AUTHOR_NAME"
replace_in_file "$MAIN_PLUGIN_FILE" "https://example.com/$OLD_SLUG" "$PLUGIN_URI"
replace_in_file "$MAIN_PLUGIN_FILE" "https://example.com" "$AUTHOR_URI"
AUTHOR_USERNAME=$(to_vendor "$AUTHOR_NAME")
replace_in_file "readme.txt" "your-username" "$AUTHOR_USERNAME"
print_done

# Step 9: Rename main plugin file
print_step 9 $TOTAL_STEPS "Renaming plugin file"
if [[ -f "$MAIN_PLUGIN_FILE" && "$PLUGIN_SLUG" != "$OLD_SLUG" ]]; then
    replace_in_file "scoper.inc.php" "$MAIN_PLUGIN_FILE" "$PLUGIN_SLUG.php"
    replace_in_file "uninstall.php" "$MAIN_PLUGIN_FILE" "$PLUGIN_SLUG.php"
    mv "$MAIN_PLUGIN_FILE" "$PLUGIN_SLUG.php"
    print_done
else
    print_skip
fi

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
echo -e "${GREEN}  Plugin '$PLUGIN_NAME' configured!${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Configuration saved to: .plugin-config.json"
echo ""
echo "Next steps:"
echo -e "${GRAY}  1. Run: composer install${NC}"
echo -e "${GRAY}  2. Develop your plugin${NC}"
echo -e "${GRAY}  3. Build: ./scaffold.sh build${NC}"
echo ""
