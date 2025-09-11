#!/bin/bash
set -euo pipefail

# Load helpers (colors, apt helpers, etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/common.sh"
require_root

# ===== User input =====
echo
echo "========== Database Deployment =========="
echo

read -rp "Choose database engine (mysql/postgres) [mysql]: " INPUT_ENGINE
DB_ENGINE="${INPUT_ENGINE:-mysql}"
if [[ "$DB_ENGINE" != "mysql" && "$DB_ENGINE" != "postgres" ]]; then
  die "Invalid engine. Choose 'mysql' or 'postgres'."
fi

read -rp "Enter database name [appdb]: " INPUT_DB
DB_NAME="${INPUT_DB:-appdb}"

read -rp "Enter database user [appuser]: " INPUT_USER
DB_USER="${INPUT_USER:-appuser}"

# Prompt for password (empty -> auto-generate)
read -rsp "Enter password for user (leave blank to auto-generate): " INPUT_PASS
echo
if [[ -z "${INPUT_PASS:-}" ]]; then
  DB_PASS="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)"
else
  DB_PASS="$INPUT_PASS"
fi

read -rp "Allow remote connections? (yes/no) [no]: " INPUT_REMOTE
ALLOW_REMOTE="${INPUT_REMOTE:-no}"

# Optional: set custom ports
if [[ "$DB_ENGINE" == "mysql" ]]; then
  read -rp "MySQL/MariaDB port [3306]: " INPUT_PORT
  DB_PORT="${INPUT_PORT:-3306}"
else
  read -rp "PostgreSQL port [5432]: " INPUT_PORT
  DB_PORT="${INPUT_PORT:-5432}"
fi

# Backup dir
read -rp "Backup directory [/var/backups/db]: " INPUT_BK
DB_BACKUP_DIR="${INPUT_BK:-/var/backups/db}"

# Confirm
echo
echo "========== DB Configuration =========="
echo "Engine        : $DB_ENGINE"
echo "DB Name       : $DB_NAME"
echo "DB User       : $DB_USER"
echo "DB Password   : (hidden)"
echo "Allow Remote  : $ALLOW_REMOTE"
echo "Port          : $DB_PORT"
echo "Backup Dir    : $DB_BACKUP_DIR"
echo "======================================"
echo
read -rp "Proceed? (yes/no) [yes]: " PROCEED
PROCEED="${PROCEED:-yes}"
[[ "$PROCEED" != "yes" ]] && exit 0

# Load DB module and run
source "${SCRIPT_DIR}/modules/db.sh"

case "$DB_ENGINE" in
  mysql)
    db_install_mysql
    db_config_mysql "$DB_PORT" "$ALLOW_REMOTE"
    db_create_mysql_user_db "$DB_NAME" "$DB_USER" "$DB_PASS"
    db_backup_mysql  "$DB_BACKUP_DIR" "$DB_NAME" "$DB_USER"
    db_summary_mysql "$DB_NAME" "$DB_USER" "$DB_PORT" "$DB_BACKUP_DIR"
    ;;
  postgres)
    db_install_postgres
    db_config_postgres "$DB_PORT" "$ALLOW_REMOTE"
    db_create_pg_user_db "$DB_NAME" "$DB_USER" "$DB_PASS"
    db_backup_postgres  "$DB_BACKUP_DIR" "$DB_NAME" "$DB_USER"
    db_summary_postgres "$DB_NAME" "$DB_USER" "$DB_PORT" "$DB_BACKUP_DIR"
    ;;
esac

echo
ok "Database deployment finished."

# Save configuration for backup script
cat > "${SCRIPT_DIR}/.dbenv" << EOL
DB_ENGINE="${DB_ENGINE}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
DB_PORT="${DB_PORT}"
DB_BACKUP_DIR="${DB_BACKUP_DIR}"
EOL
chmod 600 "${SCRIPT_DIR}/.dbenv"
