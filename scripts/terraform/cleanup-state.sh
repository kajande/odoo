#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
DO_TOKEN=${2}

if [ -z "$DO_TOKEN" ]; then
    echo "❌ DigitalOcean token is required"
    exit 1
fi

echo "=== Checking for orphaned resources from state ==="

# Get all reserved IP resources from state
RESERVED_IP_RESOURCES=$(terraform state list | grep reserved_ip || echo "")

if [ -n "$RESERVED_IP_RESOURCES" ]; then
    echo "Found reserved IP resources in state:"
    echo "$RESERVED_IP_RESOURCES"
    
    # Check each one against DigitalOcean API
    echo "$RESERVED_IP_RESOURCES" | while read resource; do
        if [ -n "$resource" ]; then
            echo "Checking resource: $resource"
            
            # Get the IP from the state
            IP=$(terraform state show "$resource" 2>/dev/null | grep -E "ip_address.*=" | head -1 | sed 's/.*= "\([^"]*\)".*/\1/' || echo "")
            
            if [ -n "$IP" ]; then
                echo "Found IP $IP in resource $resource"
                
                # Check if it exists in DigitalOcean
                HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
                    -H "Authorization: Bearer $DO_TOKEN" \
                    "https://api.digitalocean.com/v2/reserved_ips/$IP")
                
                if [ "$HTTP_CODE" = "404" ]; then
                    echo "❌ IP $IP not found in DigitalOcean - removing from state"
                    terraform state rm "$resource" || echo "Failed to remove $resource"
                else
                    echo "✅ IP $IP exists in DigitalOcean"
                fi
            fi
        fi
    done
else
    echo "No reserved IP resources found in state"
fi