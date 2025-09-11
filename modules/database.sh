#!/bin/bash
# =============================================================================
# Database Module Installation (MySQL/MariaDB + PostgreSQL)
# =============================================================================
source ../utils.sh

database_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing Database module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt)
            install_packages apt mariadb-server mariadb-client postgresql postgresql-contrib
            systemctl enable mariadb postgresql
            systemctl start mariadb postgresql
            ;;
        dnf|yum)
            install_packages "$pkg_mgr" mariadb-server mariadb postgresql-server postgresql-contrib
            systemctl enable mariadb postgresql
            systemctl start mariadb postgresql
            ;;
        pacman)
            install_packages pacman mariadb postgresql
            systemctl enable mariadb postgresql
            systemctl start mariadb postgresql
            ;;
    esac
    
    log_success "Database module installed"
}

database_test() {
    log_header "Testing Database module..."
    if command_exists mysql && command_exists psql; then
        log_success "MySQL/MariaDB and PostgreSQL available"
        return 0
    else
        log_error "Database test failed"
        return 1
    fi
}

# Export module functions
export -f database_install
export -f database_test
