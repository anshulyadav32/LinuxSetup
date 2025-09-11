#!/bin/bash
# =============================================================================
# DNS Module Installation (BIND9 / dnsmasq)
# =============================================================================
source ../utils.sh

dns_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing DNS module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt) install_packages apt bind9 bind9utils dnsutils ;;
        dnf|yum) install_packages "$pkg_mgr" bind bind-utils ;;
        pacman) install_packages pacman bind ;;
    esac
    
    systemctl enable named 2>/dev/null || systemctl enable bind9 2>/dev/null
    systemctl start named 2>/dev/null || systemctl start bind9 2>/dev/null
    log_success "DNS module installed"
}

dns_test() {
    log_header "Testing DNS module..."
    if command_exists dig || command_exists nslookup; then
        log_success "DNS tools available"
        return 0
    else
        log_error "DNS test failed"
        return 1
    fi
}

# Export module functions
export -f dns_install
export -f dns_test
