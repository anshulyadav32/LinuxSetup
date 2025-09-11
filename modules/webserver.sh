#!/bin/bash
# =============================================================================
# Webserver Module Installation (Apache + Nginx + PHP)
# =============================================================================
source ../utils.sh

webserver_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing Webserver module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt)
            install_packages apt apache2 apache2-utils nginx php php-fpm libapache2-mod-php
            systemctl enable apache2 nginx php8.3-fpm 2>/dev/null || true
            systemctl start apache2 2>/dev/null || true
            ;;
        dnf|yum)
            install_packages "$pkg_mgr" httpd httpd-tools nginx php php-fpm
            systemctl enable httpd nginx php-fpm
            systemctl start httpd nginx php-fpm
            ;;
        pacman)
            install_packages pacman apache nginx php php-fpm
            systemctl enable httpd nginx php-fpm
            systemctl start httpd nginx php-fpm
            ;;
    esac
    
    log_success "Webserver module installed"
}

webserver_test() {
    log_header "Testing Webserver module..."
    local status=0
    
    if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet httpd 2>/dev/null; then
        log_success "Apache is running"
    else
        log_error "Apache is not running"
        status=1
    fi
    
    if systemctl is-active --quiet nginx 2>/dev/null; then
        log_success "Nginx is running"
    else
        log_error "Nginx is not running"
        status=1
    fi
    
    return $status
}

# Export module functions
export -f webserver_install
export -f webserver_test
