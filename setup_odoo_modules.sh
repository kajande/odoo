#!/bin/bash
# setup_odoo_modules.sh - External installation script for Docker environment

set -e  # Exit on any error

# Configuration from environment variables
DB_NAME="${ODOO_DB:-odoo}"
DB_HOST="${DB_HOST:-db}"
DB_USER="${DB_USER:-odoo}"
DB_PASSWORD="${DB_PASSWORD}"
ODOO_CONFIG="/etc/odoo/odoo.conf"

# Core modules to install (in dependency order)
CORE_MODULES=(
    "contacts"
    "product"
    "account"
)

# Optional custom modules  
CUSTOM_MODULES=(
    "social_api"
    "fast_service"
)

echo "🚀 Starting Odoo module setup..."
echo "📋 Database: $DB_NAME"
echo "📋 Config: $ODOO_CONFIG"

# Function to wait for database
wait_for_db() {
    echo "⏳ Waiting for database connection..."
    local max_tries=30
    local count=0
    
    until pg_isready -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
        count=$((count + 1))
        if [ $count -gt $max_tries ]; then
            echo "❌ Database connection timeout after $max_tries attempts"
            exit 1
        fi
        echo "⏳ Attempt $count/$max_tries - waiting for database..."
        sleep 2
    done
    echo "✅ Database connection established"
}

# Function to check if module exists in filesystem
module_exists() {
    local module=$1
    
    # Check in standard Odoo addons path
    if [ -d "/usr/lib/python3/dist-packages/odoo/addons/$module" ]; then
        return 0
    fi
    
    # Check in custom mount locations
    local paths=(
        "/mnt/setup_odoo"
        "/mnt/social_media" 
        "/mnt/oca-rest-framework"
        "/mnt/oca-web-api"
        "/mnt/oca-dms"
        "/mnt/extra-addons"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path/$module" ]; then
            return 0
        fi
    done
    
    return 1
}

# Function to install module safely
install_module() {
    local module=$1
    echo "📦 Installing module: $module"
    
    # Check if module exists first
    if ! module_exists "$module"; then
        echo "❌ Module $module not found in any addons path!"
        return 1
    fi
    
    # Try to install with proper error handling
    if timeout 300 odoo \
        --database="$DB_NAME" \
        --init="$module" \
        --stop-after-init \
        --config="$ODOO_CONFIG" \
        --without-demo=all \
        --log-level=info \
        --no-http \
        --addons-path="/usr/lib/python3/dist-packages/odoo/addons,/mnt/setup_odoo,/mnt/social_media,/mnt/oca-rest-framework,/mnt/oca-web-api,/mnt/oca-dms"; then
        echo "✅ Successfully installed: $module"
        return 0
    else
        echo "❌ Failed to install: $module"
        return 1
    fi
}

# Function to install module with retry
install_module_with_retry() {
    local module=$1
    local max_retries=3
    local count=0
    
    while [ $count -lt $max_retries ]; do
        if install_module "$module"; then
            return 0
        fi
        count=$((count + 1))
        echo "🔄 Retrying $module installation (attempt $count/$max_retries)..."
        sleep 5
    done
    
    echo "❌ Failed to install $module after $max_retries attempts"
    return 1
}

# Function to check if database exists and has been initialized
check_database() {
    echo "🔍 Checking database status..."
    
    # Check if database exists
    if ! psql -h "$DB_HOST" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        echo "📊 Database $DB_NAME does not exist - will be created by Odoo"
        return 1
    fi
    
    # Check if database has been initialized (has ir_module_module table)
    if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1 FROM information_schema.tables WHERE table_name='ir_module_module';" | grep -q "1 row"; then
        echo "✅ Database $DB_NAME is initialized"
        return 0
    else
        echo "📊 Database $DB_NAME exists but is not initialized"
        return 1
    fi
}

# Function to verify module installation status
verify_module_installation() {
    echo "🔍 Verifying module installation status..."
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT 
    name, 
    state,
    CASE 
        WHEN state = 'installed' THEN '✅'
        WHEN state = 'uninstalled' THEN '❌'
        WHEN state = 'to install' THEN '⏳'
        WHEN state = 'to upgrade' THEN '🔄'
        ELSE '❓'
    END as status
FROM ir_module_module 
WHERE name IN ('contacts', 'account', 'social_api', 'fast_service', 'setup_odoo', 'cleanup_assets', 'cleanup_modules', 'setup_admin')
ORDER BY name;
EOF
}

# Pre-flight check for modules
check_modules_available() {
    echo "🔍 Checking if all modules are available..."
    
    local all_modules=("${CORE_MODULES[@]}" "${CUSTOM_MODULES[@]}" "setup_odoo")
    local missing_modules=()
    
    for module in "${all_modules[@]}"; do
        if ! module_exists "$module"; then
            missing_modules+=("$module")
            echo "❌ Module $module not found in any addons path!"
        else
            echo "✅ Module $module found"
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        echo "❌ Missing modules: ${missing_modules[*]}"
        echo "💡 Available paths: /usr/lib/python3/dist-packages/odoo/addons, /mnt/setup_odoo, /mnt/social_media, /mnt/oca-rest-framework, /mnt/oca-web-api, /mnt/oca-dms"
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    # Wait for database to be ready
    wait_for_db
    
    # Pre-flight check
    if ! check_modules_available; then
        echo "❌ Aborting due to missing modules"
        exit 1
    fi
    
    # Check if we need to initialize the database
    if ! check_database; then
        echo "🔧 Initializing database with base module..."
        timeout 300 odoo \
            --database="$DB_NAME" \
            --init=base \
            --stop-after-init \
            --config="$ODOO_CONFIG" \
            --without-demo=all \
            --log-level=warn \
            --logfile=/dev/stdout \
            --no-http \
            --addons-path="/usr/lib/python3/dist-packages/odoo/addons,/mnt/setup_odoo,/mnt/social_media,/mnt/oca-rest-framework,/mnt/oca-web-api,/mnt/oca-dms"
        
        echo "✅ Database initialized"
    fi
    
    # Install setup modules first (cleanup, admin setup, etc.)
    echo "🔧 Installing setup modules..."
    install_module_with_retry "setup_odoo" || echo "⚠️  setup_odoo installation failed - continuing..."
    
    # Install core modules
    echo "📋 Installing core modules..."
    for module in "${CORE_MODULES[@]}"; do
        install_module_with_retry "$module" || echo "⚠️  Continuing with remaining modules..."
    done
    
    # Install custom modules
    echo "📋 Installing custom modules..."
    for module in "${CUSTOM_MODULES[@]}"; do
        install_module_with_retry "$module" || echo "⚠️  Continuing with remaining modules..."
    done
    
    # Final update to ensure everything is properly installed
    echo "🔄 Running final update..."
    timeout 300 odoo \
        --database="$DB_NAME" \
        --update=all \
        --stop-after-init \
        --config="$ODOO_CONFIG" \
        --without-demo=all \
        --log-level=warn \
        --logfile=/dev/stdout \
        --no-http \
        --addons-path="/usr/lib/python3/dist-packages/odoo/addons,/mnt/setup_odoo,/mnt/social_media,/mnt/oca-rest-framework,/mnt/oca-web-api,/mnt/oca-dms" || echo "⚠️  Final update had issues - but continuing..."
    
    # Verify installation
    verify_module_installation
    
    echo "✨ Module setup complete!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help|--check-only|--core-only|--verify]"
        echo "  --help: Show this help"
        echo "  --check-only: Only check database and module status"
        echo "  --core-only: Install only core modules"
        echo "  --verify: Only verify installation status"
        exit 0
        ;;
    --check-only)
        wait_for_db
        check_database
        check_modules_available
        exit $?
        ;;
    --core-only)
        # Only install core modules
        CUSTOM_MODULES=()
        main
        ;;
    --verify)
        wait_for_db
        verify_module_installation
        ;;
    *)
        main
        ;;
esac
