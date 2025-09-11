#!/bin/bash
set -euo pipefail

print_summary(){
  echo
  ok "Deployment Complete!"
  echo
  echo "========== Access =========="
  echo -e "  PHP Website : ${BLUE}http://${DOMAIN}/${NC}"
  echo -e "  Node Website: ${BLUE}http://${DOMAIN}/node/${NC}"
  echo -e "  Node Port   : ${GREEN}${NODE_PORT}${NC}"
  echo
  echo "========== File Locations =========="
  echo -e "  PHP Root   : ${GREEN}${WEBROOT}/public${NC}"
  echo -e "  PHP Index  : ${GREEN}${WEBROOT}/public/index.php${NC}"
  echo -e "  Node Root  : ${GREEN}${WEBROOT}/nodeapp${NC}"
  echo -e "  Node Entry : ${GREEN}${WEBROOT}/nodeapp/app.js${NC}"
  echo -e "  Nginx Conf : ${GREEN}${NGINX_SITE}${NC}"
  echo
  echo "========== Logs & Process =========="
  echo -e "  Nginx Error Log : ${GREEN}/var/log/nginx/error.log${NC}"
  echo -e "  Nginx Access Log: ${GREEN}/var/log/nginx/access.log${NC}"
  echo -e "  PM2 Process     : ${GREEN}${PM2_APP}${NC}"
  echo -e "  PM2 Logs        : ${GREEN}sudo -u www-data env PM2_HOME=\"${WEBROOT}/nodeapp/.pm2\" pm2 logs ${PM2_APP}${NC}"
  echo
  info "Test locally without DNS:"
  echo "  curl -H 'Host: ${DOMAIN}' http://127.0.0.1/        # PHP"
  echo "  curl -H 'Host: ${DOMAIN}' http://127.0.0.1/node/   # Node"
}
