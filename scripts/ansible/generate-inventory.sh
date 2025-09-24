#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
DROPLET_IP=${2}
SSH_KEY_FILE=${3:-/tmp/ssh_key}

if [ -z "$DROPLET_IP" ]; then
    echo "❌ Droplet IP is required"
    exit 1
fi

INVENTORY_DIR="ansible/inventories/$ENVIRONMENT"
mkdir -p "$INVENTORY_DIR"

cat > "$INVENTORY_DIR/hosts" << EOF
[odoo]
odoo-$ENVIRONMENT ansible_host=$DROPLET_IP

[odoo:vars]
ansible_user=root
ansible_ssh_private_key_file=$SSH_KEY_FILE
env=$ENVIRONMENT
EOF

echo "✅ Inventory generated for $ENVIRONMENT at $INVENTORY_DIR/hosts"