#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/common.sh"
require_root
source "${SCRIPT_DIR}/modules/web.sh"

echo
echo "========== Web Server Deployment =========="

# === User input ===
read -rp "Choose web server (nginx/apache) [nginx]: " INPUT_SERVER
WS_SERVER="${INPUT_SERVER:-nginx}"

read -rp "Domain name (example.com): " WS_DOMAIN
[[ -z "$WS_DOMAIN" ]] && die "Domain is required."

read -rp "App type (php/node/html) [php]: " INPUT_TYPE
WS_TYPE="${INPUT_TYPE:-php}"

read -rp "Enable SSL with Let's Encrypt? (yes/no) [yes]: " INPUT_SSL
WS_SSL="${INPUT_SSL:-yes}"

# Node-specific
if [[ "$WS_TYPE" == "node" ]]; then
  read -rp "Node.js port [3000]: " INPUT_NODE_PORT
  WS_NODE_PORT="${INPUT_NODE_PORT:-3000}"
  WS_PM2_APP="${WS_DOMAIN}-node"
else
  WS_NODE_PORT=""
  WS_PM2_APP=""
fi

WS_WEBROOT="/var/www/${WS_DOMAIN}"
WS_CONF_DIR="/etc/${WS_SERVER}/sites-available"
WS_CONF="${WS_CONF_DIR}/${WS_DOMAIN}"

echo
echo "========== Web Config =========="
echo "Server      : $WS_SERVER"
echo "Domain      : $WS_DOMAIN"
echo "App type    : $WS_TYPE"
[[ "$WS_NODE_PORT" ]] && echo "Node Port   : $WS_NODE_PORT"
echo "Web Root    : $WS_WEBROOT"
echo "Conf File   : $WS_CONF"
echo "SSL Enabled : $WS_SSL"
echo "================================"
read -rp "Proceed? (yes/no) [yes]: " PROCEED
PROCEED="${PROCEED:-yes}"
[[ "$PROCEED" != "yes" ]] && exit 0

# === Run ===
web_install "$WS_SERVER"
web_prepare_app "$WS_TYPE" "$WS_WEBROOT" "$WS_DOMAIN"
web_config_site "$WS_SERVER" "$WS_TYPE" "$WS_DOMAIN" "$WS_WEBROOT" "$WS_CONF" "$WS_NODE_PORT"
[[ "$WS_SSL" == "yes" ]] && web_enable_ssl "$WS_SERVER" "$WS_DOMAIN"

web_summary "$WS_SERVER" "$WS_TYPE" "$WS_DOMAIN" "$WS_WEBROOT" "$WS_CONF" "$WS_NODE_PORT"
