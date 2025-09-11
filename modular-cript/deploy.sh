#!/bin/bash
set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/common.sh"
require_root

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  source "${SCRIPT_DIR}/.env"
else
  die "Missing .env. Create it first."
fi

if [[ -z "${DOMAIN:-}" ]]; then
  read -rp "Enter domain name (e.g., example.com): " DOMAIN
  [[ -z "$DOMAIN" ]] && die "Domain is required."
  export DOMAIN
fi

WEBROOT="${WEBROOT:-/var/www/${DOMAIN}}"
NODE_PORT="${NODE_PORT:-3000}"
PM2_APP="${PM2_APP:-${DOMAIN}-node}"
NGINX_SITE="${NGINX_SITE:-/etc/nginx/sites-available/${DOMAIN}}"

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
