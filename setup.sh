#!/bin/bash
# =============================================================================
# Master Setup Script
# =============================================================================
# Installs and tests: Webserver, Database, DNS, SSL, Firewall, Backup
# Usage:
#   ./setup.sh all       -> install everything
#   ./setup.sh webserver -> install webserver only
#   ./setup.sh test      -> run all module tests
# =============================================================================

set -euo pipefail

# Source utility functions and modules
source utils.sh
source modules/backup.sh
source modules/database.sh
source modules/dns.sh
source modules/firewall.sh
source modules/ssl.sh
source modules/webserver.sh

# --- Utilities ---
log_header() { echo -e "\n========== $1 ==========\n"; }
log_step() { echo "[Step $1/$2] $3"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ $1" >&2; }
log_warning() { echo "⚠️ $1"; }
log_info() { echo "ℹ️ $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

check_disk_space() {
    local required="$1"
    local available=$(df / | tail -1 | awk '{print $4 * 1024}')
    if [[ "$available" -lt "$required" ]]; then
        log_error "Not enough disk space (required: $required, available: $available)"
        return 1
    fi
    return 0
}

wait_for_service() {
    local svc="$1"
    for i in {1..10}; do
        if systemctl is-active --quiet "$svc"; then return 0; fi
        sleep 2
    done
    return 1
}

install_packages() {
    local pkg_mgr="$1"; shift
    case "$pkg_mgr" in
        apt) apt-get update -qq && apt-get install -y -qq "$@" ;;
        dnf|yum) $pkg_mgr install -y -q "$@" ;;
        pacman) pacman -Sy --noconfirm --quiet "$@" ;;
    esac
}

# --- Detect OS & Package Manager ---
detect_os_pkg_mgr() {
    if command_exists apt-get; then
        echo "debian apt"
    elif command_exists dnf; then
        echo "redhat dnf"
    elif command_exists yum; then
        echo "redhat yum"
    elif command_exists pacman; then
        echo "arch pacman"
    else
        log_error "Unsupported OS"
        exit 1
    fi
}

# --- Load Modules ---
MODULES=(webserver database dns ssl firewall backup)
for m in "${MODULES[@]}"; do
    if [[ -f "./${m}.sh" ]]; then
        source "./${m}.sh"
    else
        log_warning "Module $m.sh not found, skipping..."
    fi
done

# --- Master Installer ---
install_module() {
    local module="$1" os_type="$2" pkg_mgr="$3"
    case "$module" in
        webserver) install_webserver_module "$os_type" "$pkg_mgr" ;;
        database)  install_database_module "$os_type" "$pkg_mgr" ;;
        dns)       install_dns_module "$os_type" "$pkg_mgr" ;;
        ssl)       install_ssl_module "$os_type" "$pkg_mgr" ;;
        firewall)  install_firewall_module "$os_type" "$pkg_mgr" ;;
        backup)    install_backup_module "$os_type" "$pkg_mgr" ;;
        *)
            log_error "Unknown module: $module"
            ;;
    esac
}

test_module() {
    local module="$1"
    case "$module" in
        webserver) test_webserver_module ;;
        database)  test_database_module ;;
        dns)       test_dns_module ;;
        ssl)       test_ssl_module ;;
        firewall)  test_firewall_module ;;
        backup)    : ;; # already tested in its own install
    esac
}

# --- Main Execution ---
main() {
    read -r os_type pkg_mgr <<<"$(detect_os_pkg_mgr)"
    log_info "Detected OS: $os_type, Package Manager: $pkg_mgr"

    local action="${1:-all}"

    if [[ "$action" == "all" ]]; then
        log_header "Installing ALL modules"
        for module in "${MODULES[@]}"; do
            log_header "[$module] Installing..."
            if install_module "$module" "$os_type" "$pkg_mgr"; then
                log_success "$module installed"
                test_module "$module" || log_warning "$module test failed"
            else
                log_error "$module installation failed"
            fi
        done
    elif [[ "$action" == "test" ]]; then
        log_header "Running tests for all modules"
        for module in "${MODULES[@]}"; do
            test_module "$module"
        done
    else
        log_header "Installing module: $action"
        if install_module "$action" "$os_type" "$pkg_mgr"; then
            log_success "$action installed"
            test_module "$action" || log_warning "$action test failed"
        else
            log_error "$action installation failed"
        fi
    fi
}

main "$@"
