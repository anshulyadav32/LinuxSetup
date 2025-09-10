#!/bin/bash
# =============================================================================
# Linux Setup - Single Module Complete Installation System (Modular)
# =============================================================================
# Purpose: Comprehensive installation and setup of individual server modules
# Author: System Administrator
# Version: 2.0 (Modular)
# Usage: ./setup.sh [module_name] [options]
# =============================================================================

set -Eeuo pipefail

# ---------- Directory Structure ----------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="$(dirname "$SCRIPT_DIR")"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly MODULES_DIR="$SCRIPT_DIR/modules"

# ---------- Load Libraries ----------
for lib in colors logging system package; do
    if [[ -f "$LIB_DIR/${lib}.sh" ]]; then
        # shellcheck disable=SC1090
        source "$LIB_DIR/${lib}.sh"
    else
        echo "Error: Required library ${lib}.sh not found"
        exit 1
    fi
done

# ---------- Global Variables ----------
readonly LOG_DIR="/var/log/linux-setup"
readonly LOG_FILE="$LOG_DIR/singlem-$(date +%Y%m%d_%H%M%S).log"

# Available modules
readonly AVAILABLE_MODULES=(
    "database"   # MySQL/MariaDB, PostgreSQL
    "webserver"  # Apache, Nginx, PHP
    "dns"        # BIND9, dnsmasq
    "firewall"   # UFW, Fail2Ban, iptables
    "ssl"        # Certbot, OpenSSL, Let's Encrypt
)

# ---------- Load Module Functions ----------
load_module() {
    local module_name="$1"
    local module_file="$MODULES_DIR/${module_name}.sh"
    
    if [[ -f "$module_file" ]]; then
        # shellcheck disable=SC1090
        source "$module_file"
        log_debug "Loaded module: $module_name"
    else
        log_error "Module file not found: $module_file"
        return 1
    fi
}

# ---------- Main Installation Function ----------
install_module() {
    local module_name="$1"
    local start_time=$(date +%s)
    
    # Validate module
    if [[ ! " ${AVAILABLE_MODULES[*]} " =~ " $module_name " ]]; then
        log_error "Unknown module: $module_name"
        log_info "Available modules: ${AVAILABLE_MODULES[*]}"
        exit 1
    fi
    
    # Initialize logging
    init_logging
    
    log_header "Linux Setup - Single Module Installation"
    log_info "Module: $module_name"
    log_info "Started: $(date)"
    log_info "Log file: $LOG_FILE"
    
    # System checks
    check_root
    
    local os_type=$(detect_os)
    local pkg_mgr=$(get_package_manager "$os_type")
    
    log_info "Detected OS: $os_type"
    log_info "Package Manager: $pkg_mgr"
    
    if [[ "$os_type" == "unknown" ]] || [[ "$pkg_mgr" == "unknown" ]]; then
        log_error "Unsupported operating system or package manager"
        exit 1
    fi
    
    # Check internet connection
    check_internet || {
        log_error "Internet connection required for installation"
        exit 1
    }
    
    # Display system information
    log_info "System Information:"
    get_system_info "$os_type"
    
    # Update system
    update_system "$os_type" "$pkg_mgr"
    
    # Install common dependencies
    install_common_dependencies "$os_type" "$pkg_mgr"
    
    # Load and install the specific module
    load_module "$module_name" || {
        log_error "Failed to load module: $module_name"
        exit 1
    }
    
    # Call the module installation function
    local install_function="install_${module_name}_module"
    if declare -f "$install_function" >/dev/null; then
        "$install_function" "$os_type" "$pkg_mgr"
    else
        log_error "Installation function not found: $install_function"
        exit 1
    fi
    
    # Final steps
    log_step "9" "10" "Running post-installation checks"
    
    # Test the module if check script exists
    local check_script="$BASE_DIR/modules/$module_name/check_$module_name.sh"
    if [[ -f "$check_script" ]]; then
        log_info "Running module health check..."
        if bash "$check_script"; then
            log_success "Module health check passed"
        else
            log_warning "Module health check reported issues (check logs)"
        fi
    else
        log_info "No health check script found for $module_name"
    fi
    
    log_step "10" "10" "Installation completed"
    
    # Clean up package cache
    clean_package_cache "$pkg_mgr"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_header "Installation Summary"
    log_success "Module '$module_name' installed successfully!"
    log_info "Duration: ${duration}s"
    log_info "Log file: $LOG_FILE"
    
    # Module-specific post-installation notes
    show_post_install_notes "$module_name"
}

# ---------- Post-installation Notes ----------
show_post_install_notes() {
    local module_name="$1"
    
    case "$module_name" in
        "database")
            log_info ""
            log_info "Next Steps for Database Module:"
            log_info "1. Run 'sudo mysql_secure_installation' to secure MySQL"
            log_info "2. Create databases: mysql -e 'CREATE DATABASE myapp;'"
            log_info "3. Configure PostgreSQL: sudo -u postgres createdb myapp"
            log_info "4. Backup scripts: /usr/local/bin/mysql-backup, /usr/local/bin/postgres-backup"
            ;;
        "webserver")
            log_info ""
            log_info "Next Steps for Webserver Module:"
            log_info "1. Test Apache: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')/"
            log_info "2. Configure virtual hosts in /etc/apache2/sites-available/"
            log_info "3. Upload website files to /var/www/html/"
            log_info "4. PHP info: http://your-server/info.php"
            ;;
        "ssl")
            log_info ""
            log_info "Next Steps for SSL Module:"
            log_info "1. Get real certificate: ssl-manager get yourdomain.com"
            log_info "2. Test renewal: ssl-manager test"
            log_info "3. List certificates: ssl-manager list"
            log_info "4. Configure HTTPS redirect in web server"
            ;;
        "firewall")
            log_info ""
            log_info "Next Steps for Firewall Module:"
            log_info "1. Check status: ufw status verbose"
            log_info "2. Allow custom services: ufw allow 8080"
            log_info "3. Monitor logs: tail -f /var/log/ufw.log"
            log_info "4. Configure fail2ban: edit /etc/fail2ban/jail.local"
            ;;
        "dns")
            log_info ""
            log_info "Next Steps for DNS Module:"
            log_info "1. Configure zones in /etc/bind/zones/"
            log_info "2. Test DNS: dig @localhost yourdomain.com"
            log_info "3. Configure forwarders in named.conf"
            ;;
    esac
}

# ---------- Help and Usage ----------
show_help() {
    cat << EOF

🚀 Linux Setup - Single Module Installation System (Modular)

USAGE:
    sudo ./setup.sh <module> [options]

AVAILABLE MODULES:
    database   - MySQL/MariaDB + PostgreSQL + management tools
    webserver  - Apache + Nginx + PHP + common extensions  
    dns        - BIND9 + dnsmasq DNS servers
    firewall   - UFW + Fail2Ban + iptables security
    ssl        - Certbot + OpenSSL + Let's Encrypt integration

OPTIONS:
    -h, --help     Show this help message
    -v, --verbose  Enable verbose logging
    --debug        Enable debug mode
    --dry-run      Show what would be installed (not implemented)

EXAMPLES:
    sudo ./setup.sh webserver    # Install complete web server stack
    sudo ./setup.sh database     # Install MySQL and PostgreSQL
    sudo ./setup.sh ssl          # Install SSL/TLS certificates system

REQUIREMENTS:
    - Root privileges (use sudo)
    - Internet connection
    - Supported OS: Ubuntu, Debian, CentOS, RHEL, Arch Linux

LOGS:
    Installation logs: /var/log/linux-setup/
    Module logs: Check individual module directories

MODULAR STRUCTURE:
    lib/          - Core libraries (colors, logging, system, package)
    modules/      - Individual module installation scripts
    setup.sh      - Main installation controller

For more information, visit: https://github.com/anshulyadav32/linux-server

EOF
}

list_modules() {
    echo -e "\n${CYAN}Available Modules:${NC}"
    echo -e "${CYAN}==================${NC}"
    
    echo -e "${GREEN}database${NC}   - Complete database server setup"
    echo -e "             • MySQL/MariaDB server and client"
    echo -e "             • PostgreSQL server and contrib"
    echo -e "             • phpMyAdmin and pgAdmin4"
    echo -e "             • Database security configuration"
    echo -e "             • Automated backup scripts"
    
    echo -e "${GREEN}webserver${NC}  - Full web server stack"
    echo -e "             • Apache HTTP Server with modules"
    echo -e "             • Nginx web server"
    echo -e "             • PHP 8.3 with common extensions"
    echo -e "             • Web server configuration and sample pages"
    
    echo -e "${GREEN}dns${NC}        - DNS server infrastructure"
    echo -e "             • BIND9 authoritative DNS server"
    echo -e "             • dnsmasq lightweight DNS/DHCP"
    echo -e "             • DNS utilities and tools"
    echo -e "             • Example zone configuration files"
    
    echo -e "${GREEN}firewall${NC}   - Comprehensive security setup"
    echo -e "             • UFW (Uncomplicated Firewall)"
    echo -e "             • Fail2Ban intrusion prevention"
    echo -e "             • iptables configuration"
    echo -e "             • Security monitoring and logging"
    
    echo -e "${GREEN}ssl${NC}        - SSL/TLS certificate management"
    echo -e "             • Certbot (Let's Encrypt client)"
    echo -e "             • OpenSSL tools and utilities"
    echo -e "             • Automated certificate renewal"
    echo -e "             • Self-signed certificate generation"
    echo -e "             • SSL management scripts"
    echo ""
}

# ---------- Main Script Logic ----------
main() {
    # Parse command line arguments
    case "${1:-}" in
        -h|--help|help)
            show_help
            exit 0
            ;;
        --list|list)
            list_modules
            exit 0
            ;;
        -v|--verbose)
            export VERBOSE=true
            if [[ -n "${2:-}" ]]; then
                install_module "$2"
            else
                echo -e "${RED}Error: No module specified with --verbose${NC}"
                exit 1
            fi
            ;;
        --debug)
            export DEBUG=true
            if [[ -n "${2:-}" ]]; then
                install_module "$2"
            else
                echo -e "${RED}Error: No module specified with --debug${NC}"
                exit 1
            fi
            ;;
        "")
            echo -e "${RED}Error: No module specified${NC}"
            echo -e "Use './setup.sh --help' for usage information"
            exit 1
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            exit 1
            ;;
        *)
            # Install the specified module
            install_module "$1"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
