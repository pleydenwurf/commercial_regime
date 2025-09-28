#!/bin/bash
# /usr/local/bin/nginx-acme-manager.sh

set -e

STEP_CA_URL="https://step-ca.internal:9000"
CONFIG_FILE="/etc/nginx-acme/config.json"
DOMAIN="$1"

if [[ -z "$DOMAIN" ]]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

# Request certificate from nginx-acme (which proxies to step-ca)
/opt/nginx-acme/bin/nginx-acme --config "$CONFIG_FILE" --domain "$DOMAIN" --issue

# The post-hook will handle nginx configuration updates
echo "Certificate request initiated for $DOMAIN"
echo "Check /var/log/nginx-acme.log for status"