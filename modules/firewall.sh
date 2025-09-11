#!/bin/bash
# =============================================================================
# Firewall Module Installation (UFW / Firewalld)
# =============================================================================
source ../utils.sh

firewall_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing Firewall module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt) install_packages apt ufw ;;
        dnf|yum) install_packages "$pkg_mgr" firewalld ;;
        pacman) install_packages pacman ufw ;;
    esac
    
    systemctl enable ufw 2>/dev/null || systemctl enable firewalld
    systemctl start ufw 2>/dev/null || systemctl start firewalld
    log_success "Firewall module installed"
}

firewall_test() {
    log_header "Testing Firewall module..."
    if systemctl is-active --quiet ufw 2>/dev/null || systemctl is-active --quiet firewalld; then
        log_success "Firewall is running"
        return 0
    else
        log_error "Firewall test failed"
        return 1
    fi
}

# Export module functions
export -f firewall_install
export -f firewall_test
