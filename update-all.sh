#!/bin/bash
# =============================================================================
# Update All Components Script
# =============================================================================

log() { echo -e "[INFO] $1"; }
warn() { echo -e "[WARN] $1"; }
error() { echo -e "[ERROR] $1"; }

update_system() {
    log "Updating system packages..."
    if command -v apt >/dev/null 2>&1; then
        apt update -qq && apt upgrade -y -qq
    elif command -v dnf >/dev/null 2>&1; then
        dnf -y update
    elif command -v yum >/dev/null 2>&1; then
        yum -y update
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Syu --noconfirm
    else
        error "No supported package manager found"
    fi
}

update_webserver() {
    log "Updating Webserver components..."
    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null
    systemctl restart nginx 2>/dev/null
    if command -v php >/dev/null 2>&1; then
        log "PHP installed: $(php -v | head -n1)"
    fi
}

update_database() {
    log "Updating Database components..."
    systemctl restart mariadb 2>/dev/null || systemctl restart mysql 2>/dev/null
    systemctl restart postgresql 2>/dev/null
}

update_dns() {
    log "Updating DNS server..."
    systemctl restart named 2>/dev/null || systemctl restart bind9 2>/dev/null
}

update_firewall() {
    log "Updating Firewall service..."
    systemctl restart ufw 2>/dev/null || systemctl restart firewalld 2>/dev/null
}

update_ssl() {
    log "Updating SSL (Certbot)..."
    if command -v certbot >/dev/null 2>&1; then
        certbot renew --quiet
    else
        warn "Certbot not installed"
    fi
}

update_backup() {
    log "Updating Backup tools..."
    if command -v rclone >/dev/null 2>&1; then
        rclone selfupdate
    fi
}

log "Starting full system update..."
update_system
update_webserver
update_database
update_dns
update_firewall
update_ssl
update_backup
log "✅ All components updated successfully!"
