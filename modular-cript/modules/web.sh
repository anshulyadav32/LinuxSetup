#!/bin/bash
set -euo pipefail

web_install() {
  local SERVER="$1"
  if [[ "$SERVER" == "nginx" ]]; then
    info "Installing Nginx + PHP-FPM + Node.js/PM2"
    apt_install nginx php-fpm php-cli curl git ca-certificates
    ensure_nodesource_lts
    npm install -g pm2 >/dev/null 2>&1 || true
    systemctl enable nginx
    systemctl start nginx
  else
    info "Installing Apache + PHP + Node.js/PM2"
    apt_install apache2 libapache2-mod-php php-cli curl git ca-certificates
    ensure_nodesource_lts
    npm install -g pm2 >/dev/null 2>&1 || true
    a2enmod proxy proxy_http rewrite headers ssl >/dev/null 2>&1 || true
    systemctl enable apache2
    systemctl start apache2
  fi
  ok "$SERVER installed"
}

web_prepare_app() {
  local TYPE="$1" WEBROOT="$2" DOMAIN="$3"
  mkdir -p "$WEBROOT"
  case "$TYPE" in
    php)
      info "Creating PHP index"
      cat > "$WEBROOT/index.php" <<PHP
<?php
echo "Hello from $DOMAIN (PHP)! ✅<br>";
echo "Time: " . date('c');
PHP
      ;;
    node)
      info "Creating Node.js Express app"
      mkdir -p "$WEBROOT/nodeapp"
      cat > "$WEBROOT/nodeapp/package.json" <<NODE
{
  "name": "$DOMAIN-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": { "express": "^4.18.2" }
}
NODE
      cat > "$WEBROOT/nodeapp/app.js" <<JS
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
app.get('/', (_req,res)=>res.send("Hello from $DOMAIN (Node)! ✅"));
app.listen(port, ()=>console.log("Node app on port "+port));
JS
      pushd "$WEBROOT/nodeapp" >/dev/null
      npm install --silent
      pm2_as_www start app.js --name "${DOMAIN}-node" -- 3000
      pm2_as_www save
      popd >/dev/null
      ;;
    html)
      info "Creating static HTML"
      cat > "$WEBROOT/index.html" <<HTML
<!DOCTYPE html><html><body><h1>Hello from $DOMAIN (HTML)! ✅</h1></body></html>
HTML
      ;;
  esac
  chown -R www-data:www-data "$WEBROOT"
  chmod -R 755 "$WEBROOT"
}

web_config_site() {
  local SERVER="$1" TYPE="$2" DOMAIN="$3" WEBROOT="$4" CONF="$5" NODE_PORT="${6:-}"

  if [[ "$SERVER" == "nginx" ]]; then
    info "Writing Nginx site config"
    cat > "$CONF" <<NGINX
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $WEBROOT;

    index index.php index.html;

    location / {
        $( [[ "$TYPE" == "php" ]] && echo "try_files \$uri \$uri/ /index.php?\$query_string;" || echo "try_files \$uri \$uri/ =404;" )
    }

    $( if [[ "$TYPE" == "php" ]]; then
      echo "location ~ \.php\$ {"
      echo "    include snippets/fastcgi-php.conf;"
      echo "    fastcgi_pass unix:$(find_php_fpm_sock);"
      echo "}"
    fi )

    $( if [[ "$TYPE" == "node" ]]; then
      echo "location / {"
      echo "    proxy_pass http://127.0.0.1:${NODE_PORT};"
      echo "    proxy_http_version 1.1;"
      echo "    proxy_set_header Upgrade \$http_upgrade;"
      echo "    proxy_set_header Connection 'upgrade';"
      echo "    proxy_set_header Host \$host;"
      echo "    proxy_cache_bypass \$http_upgrade;"
      echo "}"
    fi )
}
NGINX
    ln -sf "$CONF" "/etc/nginx/sites-enabled/$DOMAIN"
    [[ -e /etc/nginx/sites-enabled/default ]] && rm -f /etc/nginx/sites-enabled/default
    nginx -t
    systemctl reload nginx
  else
    info "Writing Apache vhost config"
    cat > "$CONF" <<APACHE
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    $( if [[ "$TYPE" == "php" ]]; then
      echo "# PHP handled by mod_php automatically"
    fi )

    $( if [[ "$TYPE" == "node" ]]; then
      echo "ProxyPass / http://127.0.0.1:${NODE_PORT}/"
      echo "ProxyPassReverse / http://127.0.0.1:${NODE_PORT}/"
    fi )
</VirtualHost>
APACHE
    ln -sf "$CONF" "/etc/apache2/sites-enabled/$DOMAIN.conf"
    apache2ctl configtest
    systemctl reload apache2
  fi
  ok "Site $DOMAIN configured"
}

web_enable_ssl() {
  local SERVER="$1" DOMAIN="$2"
  info "Enabling SSL for $DOMAIN"
  apt_install certbot python3-certbot-"$SERVER"
  certbot --"$SERVER" -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN" || true
}

web_summary() {
  local SERVER="$1" TYPE="$2" DOMAIN="$3" WEBROOT="$4" CONF="$5" NODE_PORT="${6:-}"
  echo
  ok "Web Summary"
  echo "========== Access =========="
  echo -e "  Domain    : ${GREEN}$DOMAIN${NC}"
  echo -e "  Server    : ${GREEN}$SERVER${NC}"
  echo -e "  Type      : ${GREEN}$TYPE${NC}"
  [[ "$NODE_PORT" ]] && echo -e "  Node Port : ${GREEN}$NODE_PORT${NC}"
  echo
  echo "========== Files =========="
  echo -e "  Web Root  : ${GREEN}$WEBROOT${NC}"
  echo -e "  Conf File : ${GREEN}$CONF${NC}"
  echo
  echo "========== Logs =========="
  if [[ "$SERVER" == "nginx" ]]; then
    echo -e "  Error Log : ${GREEN}/var/log/nginx/error.log${NC}"
    echo -e "  Access Log: ${GREEN}/var/log/nginx/access.log${NC}"
  else
    echo -e "  Error Log : ${GREEN}/var/log/apache2/error.log${NC}"
    echo -e "  Access Log: ${GREEN}/var/log/apache2/access.log${NC}"
  fi
  echo
  echo "========== Test =========="
  echo "  curl -I http://$DOMAIN/"
  [[ "$TYPE" == "node" ]] && echo "  pm2 logs ${DOMAIN}-node"
}
