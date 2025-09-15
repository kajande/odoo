#!/bin/bash
# test_logging.sh

echo "Testing Odoo logging configuration..."

# Check directory permissions
echo "📁 Log directory status:"
docker exec odoo-odoo-1 ls -la /var/log/ | grep odoo
docker exec odoo-odoo-1 ls -la /var/log/odoo/

# Check directory ownership
echo "👤 Directory ownership:"
docker exec odoo-odoo-1 stat -c "%U:%G %a %n" /var/log/odoo/
docker exec odoo-odoo-1 stat -c "%U:%G %a %n" /var/log/odoo/odoo.log 2>/dev/null || echo "Log file doesn't exist yet"

# Test writing to log file
echo "🧪 Testing log file write access:"
docker exec odoo-odoo-1 bash -c "echo 'Test log entry - $(date)' >> /var/log/odoo/test.log && echo '✅ Write successful' || echo '❌ Write failed - check permissions'"

# Check config file
echo "📋 Config file content:"
docker exec odoo-odoo-1 grep -E "(logfile|log_handler)" /etc/odoo/odoo.conf

# Test Odoo help command to verify basic functionality
echo "🚀 Testing Odoo basic functionality:"
docker exec odoo-odoo-1 odoo --help | head -3

echo "✅ Logging test completed"
