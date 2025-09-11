#!/bin/bash
set -euo pipefail

# Requires common.sh already sourced by orchestrator

# =========================
# MySQL / MariaDB
# =========================
db_install_mysql() {
  info "Installing MariaDB server (MySQL-compatible)"
  apt_install mariadb-server mariadb-client
  systemctl enable mariadb >/dev/null
  systemctl start mariadb
  ok "MariaDB installed and started"
}

db_config_mysql() {
  local PORT="$1"         # e.g., 3306
  local ALLOW_REMOTE="$2" # yes/no
  info "Configuring MariaDB (port $PORT, remote=$ALLOW_REMOTE)"

  # Secure-ish defaults (skip interactive mysql_secure_installation)
  #  - Ensure root uses unix_socket; remove test DB/anon users
  mysql --protocol=socket -uroot <<'SQL' || true
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL

  # my.cnf tuning: bind-address & port
  local CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
  if [[ -f "$CONF" ]]; then
    sed -i "s/^\s*port\s*=.*/port = ${PORT}/" "$CONF" || true
    if [[ "$ALLOW_REMOTE" == "yes" ]]; then
      sed -i "s/^\s*bind-address\s*=.*/bind-address = 0.0.0.0/" "$CONF" || \
      grep -q 'bind-address' "$CONF" || echo "bind-address = 0.0.0.0" >> "$CONF"
    else
      sed -i "s/^\s*bind-address\s*=.*/bind-address = 127.0.0.1/" "$CONF" || \
      grep -q 'bind-address' "$CONF" || echo "bind-address = 127.0.0.1" >> "$CONF"
    fi
  fi

  systemctl restart mariadb
  ok "MariaDB configured"
}

db_create_mysql_user_db() {
  local DB_NAME="$1" DB_USER="$2" DB_PASS="$3"

  info "Creating database '$DB_NAME' and user '$DB_USER' (MySQL/MariaDB)"
  mysql --protocol=socket -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQL
  ok "User and DB created (MySQL/MariaDB)"
}

db_backup_mysql() {
  local BACKUP_DIR="$1" DB_NAME="$2" DB_USER="$3"
  mkdir -p "$BACKUP_DIR"
  local TS; TS="$(date +%Y%m%d_%H%M%S)"
  local OUT="${BACKUP_DIR}/${DB_NAME}_${TS}.sql.gz"
  info "Creating MySQL/MariaDB dump: $OUT"
  mysqldump -u"$DB_USER" -p --databases "$DB_NAME" 2>/dev/null | gzip -9 > "$OUT" || true
  ok "Backup (best-effort) saved to $OUT"
}

db_summary_mysql() {
  local DB_NAME="$1" DB_USER="$2" DB_PORT="$3" BACKUP_DIR="$4"
  echo
  ok "MySQL/MariaDB Summary"
  echo "========== Access =========="
  echo -e "  Host/Port   : ${BLUE}127.0.0.1:${DB_PORT}${NC}"
  echo -e "  Database    : ${GREEN}${DB_NAME}${NC}"
  echo -e "  Username    : ${GREEN}${DB_USER}${NC}"
  echo
  echo "========== File Locations =========="
  echo -e "  Conf        : ${GREEN}/etc/mysql/mariadb.conf.d/50-server.cnf${NC}"
  echo -e "  Data Dir    : ${GREEN}/var/lib/mysql${NC}"
  echo -e "  Logs        : ${GREEN}/var/log/mysql/*${NC}"
  echo -e "  Backup Dir  : ${GREEN}${BACKUP_DIR}${NC}"
  echo
  echo "========== Service =========="
  echo -e "  Service     : ${GREEN}mariadb${NC}"
  echo "  Commands    : systemctl status mariadb | systemctl restart mariadb"
}

# =========================
# PostgreSQL
# =========================
db_install_postgres() {
  info "Installing PostgreSQL"
  apt_install postgresql postgresql-contrib
  systemctl enable postgresql >/dev/null
  systemctl start postgresql
  ok "PostgreSQL installed and started"
}

db_config_postgres() {
  local PORT="$1"         # e.g., 5432
  local ALLOW_REMOTE="$2" # yes/no
  info "Configuring PostgreSQL (port $PORT, remote=$ALLOW_REMOTE)"

  # Find versioned dirs
  local PG_VER PG_CONF_DIR PG_HBA
  PG_VER="$(psql -V | awk '{print $3}' | cut -d'.' -f1)"
  # Fallback: list /etc/postgresql/* if version detect fails
  if [[ -z "${PG_VER}" || ! -d "/etc/postgresql/${PG_VER}" ]]; then
    PG_VER="$(ls /etc/postgresql | sort -nr | head -n1)"
  fi
  PG_CONF_DIR="/etc/postgresql/${PG_VER}/main"
  PG_HBA="${PG_CONF_DIR}/pg_hba.conf"

  # postgresql.conf: port & listen_addresses
  sed -i "s/^\s*#\?\s*port\s*=.*/port = ${PORT}/" "${PG_CONF_DIR}/postgresql.conf"
  if [[ "$ALLOW_REMOTE" == "yes" ]]; then
    sed -i "s/^\s*#\?\s*listen_addresses\s*=.*/listen_addresses = '*'/" "${PG_CONF_DIR}/postgresql.conf"
    # pg_hba: allow md5 from anywhere; tighten in production
    if ! grep -q "^host\s\+all\s\+all\s\+0\.0\.0\.0\/0\s\+md5" "$PG_HBA"; then
      echo "host all all 0.0.0.0/0 md5" >> "$PG_HBA"
    fi
    if ! grep -q "^host\s\+all\s\+all\s\+::\/0\s\+md5" "$PG_HBA"; then
      echo "host all all ::/0 md5" >> "$PG_HBA"
    fi
  else
    sed -i "s/^\s*#\?\s*listen_addresses\s*=.*/listen_addresses = 'localhost'/" "${PG_CONF_DIR}/postgresql.conf"
  fi

  systemctl restart postgresql
  ok "PostgreSQL configured"
}

db_create_pg_user_db() {
  local DB_NAME="$1" DB_USER="$2" DB_PASS="$3"
  info "Creating database '$DB_NAME' and role '$DB_USER' (PostgreSQL)"
  sudo -u postgres psql <<SQL
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASS}';
   END IF;
END
\$do\$;
CREATE DATABASE "${DB_NAME}" OWNER "${DB_USER}";
GRANT ALL PRIVILEGES ON DATABASE "${DB_NAME}" TO "${DB_USER}";
SQL
  ok "User and DB created (PostgreSQL)"
}

db_backup_postgres() {
  local BACKUP_DIR="$1" DB_NAME="$2" DB_USER="$3"
  mkdir -p "$BACKUP_DIR"
  local TS; TS="$(date +%Y%m%d_%H%M%S)"
  local OUT="${BACKUP_DIR}/${DB_NAME}_${TS}.sql.gz"
  info "Creating PostgreSQL dump: $OUT"
  PGPASSWORD="" sudo -u postgres pg_dump "${DB_NAME}" | gzip -9 > "$OUT" || true
  ok "Backup (best-effort) saved to $OUT"
}

db_summary_postgres() {
  local DB_NAME="$1" DB_USER="$2" DB_PORT="$3" BACKUP_DIR="$4"
  # Detect version as above
  local PG_VER PG_CONF_DIR
  PG_VER="$(psql -V | awk '{print $3}' | cut -d'.' -f1)"
  [[ -z "${PG_VER}" || ! -d "/etc/postgresql/${PG_VER}" ]] && PG_VER="$(ls /etc/postgresql | sort -nr | head -n1)"
  PG_CONF_DIR="/etc/postgresql/${PG_VER}/main"

  echo
  ok "PostgreSQL Summary"
  echo "========== Access =========="
  echo -e "  Host/Port   : ${BLUE}127.0.0.1:${DB_PORT}${NC}"
  echo -e "  Database    : ${GREEN}${DB_NAME}${NC}"
  echo -e "  Username    : ${GREEN}${DB_USER}${NC}"
  echo
  echo "========== File Locations =========="
  echo -e "  Conf Dir    : ${GREEN}${PG_CONF_DIR}${NC}"
  echo -e "  Data Dir    : ${GREEN}/var/lib/postgresql/${PG_VER}/main${NC}"
  echo -e "  Logs        : ${GREEN}/var/log/postgresql/*${NC}"
  echo -e "  Backup Dir  : ${GREEN}${BACKUP_DIR}${NC}"
  echo
  echo "========== Service =========="
  echo -e "  Service     : ${GREEN}postgresql${NC}"
  echo "  Commands    : systemctl status postgresql | systemctl restart postgresql"
}
