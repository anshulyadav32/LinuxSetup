#!/bin/bash
set -euo pipefail

node_install(){
  info "Installing Node (LTS) + PM2"
  ensure_nodesource_lts
  npm install -g pm2 >/dev/null 2>&1 || npm install -g pm2
}

node_prepare_app(){
  info "Preparing Node app at ${WEBROOT}/nodeapp (port ${NODE_PORT})"
  mkdir -p "${WEBROOT}/nodeapp"
  cat > "${WEBROOT}/nodeapp/package.json" <<NODE
{
  "name": "${DOMAIN}-nodeapp",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": { "express": "^4.18.2" }
}
NODE

  cat > "${WEBROOT}/nodeapp/app.js" <<'JS'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
app.get('/', (_req, res) => res.type('text').send('Hello from Node! ✅\nPath: /node\n'));
app.get('/health', (_req, res) => res.json({ ok: true }));
app.listen(port, () => console.log(`Node app listening on ${port}`));
JS

  chown -R www-data:www-data "${WEBROOT}"
  chmod -R 755 "${WEBROOT}"

  pushd "${WEBROOT}/nodeapp" >/dev/null
  sudo -u www-data npm install --silent
  pm2_as_www start app.js --name "${PM2_APP}" -- "${NODE_PORT}" >/dev/null
  pm2_as_www save >/dev/null
  pm2 startup -u www-data --hp "${WEBROOT}/nodeapp" >/dev/null || true
  popd >/dev/null
}
