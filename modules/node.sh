#!/bin/bash
# =============================================================================
# Node.js Module Installation
# =============================================================================
source ../utils.sh

node_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing Node.js module ($os_type / $pkg_mgr)..."
    
    case "$pkg_mgr" in
        apt)
            # Add NodeSource repository
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            install_packages apt nodejs npm
            ;;
        dnf|yum)
            # Add NodeSource repository
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            install_packages "$pkg_mgr" nodejs npm
            ;;
        pacman)
            install_packages pacman nodejs npm
            ;;
    esac
    
    # Install common global packages
    npm install -g pm2 yarn
    
    log_success "Node.js module installed"
}

node_test() {
    log_header "Testing Node.js module..."
    local status=0
    
    if command_exists node; then
        log_success "Node.js $(node --version) is available"
    else
        log_error "Node.js is not available"
        status=1
    fi
    
    if command_exists npm; then
        log_success "npm $(npm --version) is available"
    else
        log_error "npm is not available"
        status=1
    fi
    
    if command_exists yarn; then
        log_success "yarn $(yarn --version) is available"
    else
        log_error "yarn is not available"
        status=1
    fi
    
    if command_exists pm2; then
        log_success "pm2 $(pm2 --version) is available"
    else
        log_error "pm2 is not available"
        status=1
    fi
    
    return $status
}

# Export module functions
export -f node_install
export -f node_test
