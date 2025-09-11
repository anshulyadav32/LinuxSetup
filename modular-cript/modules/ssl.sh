#!/bin/bash
set -euo pipefail

ssl_install() {
  info "Installing Certbot"
  apt_install certbot python3-certbot-nginx
}

ssl_setup() {
  info "Setting up SSL for ${DOMAIN}"
  
  # Check if certificates already exist
  if [[ -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
    info "SSL certificates already exist for ${DOMAIN}"
    return 0
  }

  # Get and install certificate
  certbot --nginx \
    -d "${DOMAIN}" \
    -d "www.${DOMAIN}" \
    --non-interactive \
    --agree-tos \
    --email "webmaster@${DOMAIN}" \
    --redirect \
    --hsts \
    --staple-ocsp \
    --must-staple

  ok "SSL certificates installed for ${DOMAIN}"
  
  # Add SSL-specific headers to Nginx config
  sed -i '/add_header X-Content-Type-Options nosniff;/a\    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;' "${NGINX_SITE}"
  
  # Reload Nginx to apply changes
  systemctl reload nginx

  # Set up auto-renewal
  systemctl enable certbot.timer
  systemctl start certbot.timer
}

ssl_check() {
  if [[ -d "/etc/letsencrypt/live/${DOMAIN}" ]]; then
    info "SSL Status for ${DOMAIN}:"
    certbot certificates | grep -A 2 "${DOMAIN}"
  else
    err "No SSL certificates found for ${DOMAIN}"
  fi
}
