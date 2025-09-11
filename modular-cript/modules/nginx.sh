#!/bin/bash
set -euo pipefail

nginx_write_site(){
  info "Writing Nginx site to ${NGINX_SITE}"
  cat > "${NGINX_SITE}" <<NGINX
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    # PHP site at /
    root ${WEBROOT}/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }

    # Node app at /node
    location /node/ {
        proxy_pass http://127.0.0.1:${NODE_PORT}/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
}
NGINX

  ln -sf "${NGINX_SITE}" "/etc/nginx/sites-enabled/${DOMAIN}"
  [[ -e /etc/nginx/sites-enabled/default ]] && rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl reload nginx || systemctl restart nginx
}
