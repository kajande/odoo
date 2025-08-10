#!/bin/bash
set -e

echo "=== Starting Odoo Configuration Generation ==="

# Set defaults
DB_HOST=${DB_HOST:-"db"}
DB_PORT=${DB_PORT:-"5432"}
DB_USER=${DB_USER:-"odoo"}
DB_PASSWORD=${DB_PASSWORD:-"odoo"}
DB_NAME=${DB_NAME:-"odoo"}
ODOO_PASSWORD=${ODOO_PASSWORD:-"kajande"}

echo "Using DB_HOST=${DB_HOST}, DB_PORT=${DB_PORT}"

# Create config file
echo "[options]" > /etc/odoo/odoo.conf
echo "addons_path = /mnt/social_media,/mnt/oca-rest-framework,/mnt/oca-web-api,/mnt/setup_odoo,/mnt/oca-dms" >> /etc/odoo/odoo.conf
echo "data_dir = /var/lib/odoo" >> /etc/odoo/odoo.conf
echo "admin_passwd = ${ODOO_PASSWORD}" >> /etc/odoo/odoo.conf
echo "logfile = False" >> /etc/odoo/odoo.conf
echo "db_host = ${DB_HOST}" >> /etc/odoo/odoo.conf
echo "db_port = ${DB_PORT}" >> /etc/odoo/odoo.conf
echo "db_user = ${DB_USER}" >> /etc/odoo/odoo.conf
echo "db_password = ${DB_PASSWORD}" >> /etc/odoo/odoo.conf
echo "db_name = ${DB_NAME}" >> /etc/odoo/odoo.conf
echo "" >> /etc/odoo/odoo.conf
echo "; Time limits in seconds" >> /etc/odoo/odoo.conf
echo "limit_time_real = 3600" >> /etc/odoo/odoo.conf
echo "limit_time_cpu = 3600" >> /etc/odoo/odoo.conf

# Fix permissions
chown odoo:odoo /etc/odoo/odoo.conf
chmod 644 /etc/odoo/odoo.conf

echo "Generated config:"
cat /etc/odoo/odoo.conf

# Run Odoo
echo "Starting Odoo..."
exec gosu odoo "$@"
