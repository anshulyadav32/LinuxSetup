#!/bin/bash
# =============================================================================
# SSL Module Installation (Certbot / Let's Encrypt)
# =============================================================================
source ../utils.sh

ssl_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing SSL module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt) install_packages apt certbot python3-certbot-apache python3-certbot-nginx ;;
        dnf|yum) install_packages "$pkg_mgr" certbot python3-certbot-apache python3-certbot-nginx ;;
        pacman) install_packages pacman certbot python-certbot-apache python-certbot-nginx ;;
    esac
    
    log_success "SSL module installed"
}

ssl_test() {
    log_header "Testing SSL module..."
    if command_exists certbot; then
        log_success "Certbot available"
        return 0
    else
        log_error "SSL test failed"
        return 1
    fi
}

# Export module functions
export -f ssl_install
export -f ssl_test
