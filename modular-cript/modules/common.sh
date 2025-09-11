#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
ok(){ echo -e "${GREEN}✔ $1${NC}"; }
info(){ echo -e "${BLUE}ℹ️ $1${NC}"; }
err(){ echo -e "${RED}✖ $1${NC}"; }
die(){ err "$1"; exit 1; }

require_root(){
  [[ $EUID -eq 0 ]] || die "Run as root (sudo)."
}

require_cmds(){
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "Missing command: $c"; done
}

apt_install(){
  DEBIAN_FRONTEND=noninteractive apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

ensure_nodesource_lts(){
  if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt_install nodejs
  fi
}

pm2_as_www(){
  sudo -u www-data env PM2_HOME="${WEBROOT}/nodeapp/.pm2" pm2 "$@"
}

find_php_fpm_sock(){
  local sock
  sock=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n1 || true)
  [[ -z "$sock" && -S "/var/run/php/php-fpm.sock" ]] && sock="/var/run/php/php-fpm.sock"
  echo "${sock:-}"
}
