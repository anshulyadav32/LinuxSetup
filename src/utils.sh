#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Require root access
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Package management
apt_update() {
    info "Updating package lists..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
}

apt_install() {
    local packages="$*"
    info "Installing packages: $packages"
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $packages >/dev/null
    ok "Packages installed"
}

# Node.js setup
ensure_nodesource_lts() {
    info "Setting up Node.js LTS repository"
    if ! grep -q "nodesource" /etc/apt/sources.list.d/* 2>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - >/dev/null 2>&1
        apt_update
    fi
    apt_install nodejs
    ok "Node.js LTS installed"
}

# Process management
pm2_as_www() {
    sudo -u www-data pm2 "$@"
}

# File operations
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.$(date +%Y%m%d_%H%M%S).bak"
        cp -a "$file" "$backup"
        ok "Backed up $file to $backup"
    fi
}

# Service management
restart_service() {
    local service="$1"
    info "Restarting $service..."
    systemctl restart "$service"
    systemctl is-active --quiet "$service" || error "$service failed to start"
    ok "$service restarted"
}

enable_service() {
    local service="$1"
    info "Enabling $service..."
    systemctl enable "$service" >/dev/null 2>&1
    ok "$service enabled"
}

# SSL/TLS
check_ssl_cert() {
    local domain="$1"
    if [[ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]]; then
        local expiry
        expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${domain}/fullchain.pem")
        ok "SSL certificate found for $domain ($expiry)"
        return 0
    else
        return 1
    fi
}

# Networking
get_public_ip() {
    curl -s https://api.ipify.org
}

check_port() {
    local port="$1"
    if netstat -tuln | grep -q ":${port}"; then
        warn "Port $port is already in use"
        return 1
    fi
    return 0
}

# User management
create_user_if_not_exists() {
    local username="$1"
    if ! id -u "$username" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$username"
        ok "User $username created"
    fi
}

# Database utilities
find_mysql_sock() {
    local sock
    for sock in /var/run/mysqld/mysqld.sock /var/lib/mysql/mysql.sock; do
        [[ -S "$sock" ]] && echo "$sock" && return 0
    done
    error "MySQL socket not found"
}

find_php_fpm_sock() {
    local sock
    for sock in /run/php/php*-fpm.sock; do
        [[ -S "$sock" ]] && echo "$sock" && return 0
    done
    error "PHP-FPM socket not found"
}

# Configuration validation
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        error "Invalid domain name: $domain"
    fi
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error "Invalid email address: $email"
    fi
}

# Interactive input
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-yes}"
    local response
    
    read -rp "$prompt [${default}]: " response
    response="${response:-$default}"
    [[ "${response,,}" =~ ^(yes|y)$ ]]
}

get_password() {
    local prompt="$1"
    local password
    
    while true; do
        read -rsp "$prompt: " password
        echo
        read -rsp "Confirm password: " password2
        echo
        
        if [[ "$password" == "$password2" ]]; then
            echo "$password"
            return 0
        else
            error "Passwords do not match. Please try again."
        fi
    done
}

# System checks
check_memory() {
    local min_mb="$1"
    local available
    available=$(free -m | awk '/^Mem:/ {print $7}')
    if (( available < min_mb )); then
        warn "Low memory: ${available}MB available, ${min_mb}MB recommended"
        return 1
    fi
    return 0
}

check_disk_space() {
    local path="$1"
    local min_gb="$2"
    local available
    available=$(df -BG "$path" | awk 'NR==2 {print $4}' | tr -d 'G')
    if (( available < min_gb )); then
        warn "Low disk space on $path: ${available}GB available, ${min_gb}GB recommended"
        return 1
    fi
    return 0
}

# Cleanup functions
cleanup_logs() {
    local days="${1:-7}"
    find /var/log -type f -name "*.log" -mtime +"$days" -delete
    find /var/log -type f -name "*.gz" -mtime +"$days" -delete
    ok "Cleaned up logs older than $days days"
}

cleanup_temp() {
    rm -rf /tmp/* /var/tmp/*
    ok "Cleaned up temporary files"
}

# Progress indicator
show_progress() {
    local message="$1"
    local pid="$2"
    local spin='-\|/'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r${BLUE}[%c]${NC} %s..." "${spin:$i:1}" "$message"
        sleep .1
    done
    printf "\r${GREEN}[✓]${NC} %s...done\n" "$message"
}

# Deployment utilities
wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local count=0
    
    info "Waiting for port $port to be available..."
    while ! nc -z localhost "$port"; do
        sleep 1
        count=$((count + 1))
        if [ "$count" -ge "$timeout" ]; then
            error "Timeout waiting for port $port"
        fi
    done
    ok "Port $port is available"
}

deploy_env_file() {
    local env_file="$1"
    local target="$2"
    
    if [[ ! -f "$env_file" ]]; then
        error "Environment file $env_file not found"
    fi
    
    info "Deploying environment file to $target"
    cp -f "$env_file" "$target"
    chmod 600 "$target"
    ok "Environment file deployed"
}

check_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
    fi
}

run_as_user() {
    local user="$1"
    shift
    sudo -u "$user" "$@"
}

deploy_systemd_service() {
    local service_name="$1"
    local service_file="$2"
    
    info "Deploying systemd service $service_name"
    cp -f "$service_file" "/etc/systemd/system/${service_name}.service"
    systemctl daemon-reload
    enable_service "$service_name"
    restart_service "$service_name"
    ok "Service $service_name deployed"
}

deploy_nginx_config() {
    local site_name="$1"
    local config_file="$2"
    
    info "Deploying Nginx configuration for $site_name"
    cp -f "$config_file" "/etc/nginx/sites-available/$site_name"
    ln -sf "/etc/nginx/sites-available/$site_name" "/etc/nginx/sites-enabled/"
    nginx -t || error "Nginx configuration test failed"
    restart_service nginx
    ok "Nginx configuration deployed"
}

setup_ssl() {
    local domain="$1"
    local email="$2"
    
    validate_domain "$domain"
    validate_email "$email"
    
    info "Setting up SSL for $domain"
    certbot certonly --nginx -n --agree-tos -m "$email" -d "$domain" || error "SSL setup failed"
    ok "SSL certificate obtained for $domain"
}

create_db_user() {
    local db_user="$1"
    local db_pass="$2"
    local db_host="${3:-localhost}"
    
    info "Creating database user $db_user"
    mysql -e "CREATE USER IF NOT EXISTS '$db_user'@'$db_host' IDENTIFIED BY '$db_pass';"
    ok "Database user created"
}

grant_db_privileges() {
    local db_name="$1"
    local db_user="$2"
    local db_host="${3:-localhost}"
    
    info "Granting privileges on $db_name to $db_user"
    mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'$db_host';"
    mysql -e "FLUSH PRIVILEGES;"
    ok "Database privileges granted"
}

create_db() {
    local db_name="$1"
    local charset="${2:-utf8mb4}"
    local collation="${3:-utf8mb4_unicode_ci}"
    
    info "Creating database $db_name"
    mysql -e "CREATE DATABASE IF NOT EXISTS $db_name CHARACTER SET $charset COLLATE $collation;"
    ok "Database created"
}

deploy_app() {
    local src_dir="$1"
    local dest_dir="$2"
    local owner="${3:-www-data}"
    
    info "Deploying application from $src_dir to $dest_dir"
    mkdir -p "$dest_dir"
    rsync -a --delete "$src_dir/" "$dest_dir/"
    chown -R "$owner:$owner" "$dest_dir"
    ok "Application deployed"
}

run_migrations() {
    local command="$1"
    shift
    
    info "Running database migrations"
    if $command "$@"; then
        ok "Migrations completed"
    else
        error "Migration failed"
    fi
}

deploy_cron_job() {
    local name="$1"
    local schedule="$2"
    local command="$3"
    
    info "Deploying cron job: $name"
    echo "$schedule $command" > "/etc/cron.d/$name"
    chmod 644 "/etc/cron.d/$name"
    ok "Cron job deployed"
}

# Configuration management
merge_config() {
    local base_config="$1"
    local overlay_config="$2"
    local output_config="$3"
    
    info "Merging configurations"
    jq -s '.[0] * .[1]' "$base_config" "$overlay_config" > "$output_config"
    ok "Configuration merged"
}

generate_secure_key() {
    local length="${1:-32}"
    openssl rand -base64 "$length"
}

load_env() {
    local env_file="$1"
    if [[ -f "$env_file" ]]; then
        set -o allexport
        # shellcheck source=/dev/null
        source "$env_file"
        set +o allexport
        ok "Environment loaded from $env_file"
    else
        error "Environment file $env_file not found"
    fi
}
# =============================================================================
# Common Utility Functions for All Modules
# =============================================================================
log_header() { echo -e "\n========== $1 ==========\n"; }
log_step() { echo "[Step $1/$2] $3"; }
log_success() { echo "[32m[1m✔ $1[0m"; }
log_error() { echo "[31m[1m✖ $1[0m" >&2; }
log_warning() { echo "[33m[1m⚠️ $1[0m"; }
log_info() { echo "[36m[1mℹ️ $1[0m"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

install_packages() {
    local pkg_mgr="$1"; shift
    case "$pkg_mgr" in
        apt) apt-get update -qq && apt-get install -y -qq "$@" ;;
        dnf|yum) $pkg_mgr install -y -q "$@" ;;
        pacman) pacman -Sy --noconfirm --quiet "$@" ;;
    esac
}
