#!/bin/bash
set -euo pipefail

# Load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/common.sh"
require_root

# Load .env if present
ENV_FILE="${SCRIPT_DIR}/.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

# === User Input ===
read -rp "Enter domain name [${DOMAIN:-example.com}]: " INPUT_DOMAIN
DOMAIN="${INPUT_DOMAIN:-${DOMAIN:-example.com}}"

read -rp "Enter web root directory [${WEBROOT:-/var/www/$DOMAIN}]: " INPUT_WEBROOT
WEBROOT="${INPUT_WEBROOT:-${WEBROOT:-/var/www/$DOMAIN}}"

read -rp "Enter Node.js app port [${NODE_PORT:-3000}]: " INPUT_NODE_PORT
NODE_PORT="${INPUT_NODE_PORT:-${NODE_PORT:-3000}}"

PM2_APP="${PM2_APP:-${DOMAIN}-node}"
NGINX_SITE="${NGINX_SITE:-/etc/nginx/sites-available/${DOMAIN}}"

# Save configuration to .env
cat > "$ENV_FILE" << EOL
# Domain & paths
DOMAIN="${DOMAIN}"
WEBROOT="${WEBROOT}"

# Node
NODE_PORT=${NODE_PORT}
PM2_APP="${PM2_APP}"

# Nginx
NGINX_SITE="${NGINX_SITE}"
EOL

# Confirm config
echo
echo "========== Deployment Configuration =========="
echo "Domain      : $DOMAIN"
echo "Web Root    : $WEBROOT"
echo "Node Port   : $NODE_PORT"
echo "PM2 Process : $PM2_APP"
echo "Nginx Conf  : $NGINX_SITE"
echo "============================================="
echo
read -rp "Proceed with deployment? (yes/no) [yes]: " PROCEED
PROCEED="${PROCEED:-yes}"
[[ "$PROCEED" != "yes" ]] && exit 0

# Load modules
source "${SCRIPT_DIR}/modules/php.sh"
source "${SCRIPT_DIR}/modules/node.sh"
source "${SCRIPT_DIR}/modules/nginx.sh"
source "${SCRIPT_DIR}/modules/summary.sh"

# Run steps
php_install
php_prepare_app
php_socket_or_die

node_install
node_prepare_app

nginx_write_site
print_summary
