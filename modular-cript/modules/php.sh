#!/bin/bash
set -euo pipefail

php_install(){
  info "Installing Nginx + PHP-FPM"
  apt_install nginx php-fpm php-cli curl git ca-certificates
  systemctl enable nginx >/dev/null
}

php_prepare_app(){
  info "Preparing PHP app at ${WEBROOT}/public"
  mkdir -p "${WEBROOT}/public"
  cat > "${WEBROOT}/public/index.php" <<'PHP'
<?php
header('Content-Type: text/plain; charset=utf-8');
echo "Hello from PHP! ✅\n";
echo "Time: " . date('c') . "\n";
PHP
  chown -R www-data:www-data "${WEBROOT}"
  chmod -R 755 "${WEBROOT}"
}

php_socket_or_die(){
  PHP_SOCK="$(find_php_fpm_sock)"
  [[ -n "$PHP_SOCK" ]] || die "PHP-FPM socket not found. Is php-fpm running?"
  info "Using PHP-FPM socket: ${PHP_SOCK}"
}
