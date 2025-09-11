#!/bin/bash
# =============================================================================
# Backup Module Installation (rsync, tar, rclone)
# =============================================================================
source ../utils.sh

backup_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing Backup module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt) install_packages apt rsync tar gzip bzip2 rclone ;;
        dnf|yum) install_packages "$pkg_mgr" rsync tar gzip bzip2 rclone ;;
        pacman) install_packages pacman rsync tar gzip bzip2 rclone ;;
    esac
    
    mkdir -p /root/backups
    log_success "Backup module installed"
}

backup_test() {
    log_header "Testing Backup module..."
    if command_exists rsync && command_exists tar; then
        log_success "Backup tools available"
        return 0
    else
        log_error "Backup test failed"
        return 1
    fi
}

# Export module functions
export -f backup_install
export -f backup_test
