#!/bin/bash

# LinuxSetup Master Control Script
# Quick module access and system management

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/colors.sh" 2>/dev/null || echo "Warning: colors.sh not found"
source "$SCRIPT_DIR/lib/logging.sh" 2>/dev/null || echo "Warning: logging.sh not found"

# Initialize logging if available
if command -v log_info >/dev/null 2>&1; then
    setup_logging "master"
else
    # Fallback logging functions
    log_info() { echo -e "\033[32m[INFO]\033[0m $*"; }
    log_warn() { echo -e "\033[33m[WARN]\033[0m $*"; }
    log_error() { echo -e "\033[31m[ERROR]\033[0m $*"; }
fi

# Available modules
declare -A MODULES=(
    ["database"]="Database servers (MySQL, PostgreSQL, MongoDB)"
    ["webserver"]="Web servers (Apache, Nginx, PHP)"
    ["dns"]="DNS servers (BIND9, dnsmasq)"
    ["firewall"]="Security (UFW, Fail2Ban, iptables)"
    ["ssl"]="SSL/TLS certificates (Let's Encrypt, OpenSSL)"
    ["mail"]="Mail server (Postfix, Dovecot, SpamAssassin)"
    ["all"]="Complete server setup (ALL modules)"
)

# Function to show usage
show_usage() {
    cat << EOF
🚀 LinuxSetup Master Control

USAGE:
    ./master.sh [COMMAND] [OPTIONS]

COMMANDS:
    --module <name>     Install specific module
    --status            Show system status and installed components
    --list              List all available modules
    --help              Show this help message

AVAILABLE MODULES:
EOF
    for module in "${!MODULES[@]}"; do
        printf "    %-12s - %s\n" "$module" "${MODULES[$module]}"
    done
    cat << EOF

EXAMPLES:
    ./master.sh --module ssl       # Install SSL module
    ./master.sh --module mail      # Install mail server
    ./master.sh --status           # Show system status
    ./master.sh --list             # List modules

REQUIREMENTS:
    - Root privileges (use sudo)
    - Internet connection
    - Supported OS: Ubuntu, Debian, CentOS, RHEL

For more information: https://github.com/anshulyadav32/LinuxSetup
EOF
}

# Function to list modules
list_modules() {
    log_info "Available modules in LinuxSetup:"
    echo
    for module in "${!MODULES[@]}"; do
        if [ -f "$SCRIPT_DIR/modules/${module}.sh" ]; then
            status="✅ Available"
        else
            status="❌ Missing"
        fi
        printf "  %-12s - %s [%s]\n" "$module" "${MODULES[$module]}" "$status"
    done
    echo
}

# Function to show system status
show_status() {
    log_info "System Status Report"
    echo "=================================="
    echo "📊 LinuxSetup System Status"
    echo "=================================="
    echo
    
    # System information
    echo "🖥️  System Information:"
    echo "   OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Unknown")"
    echo "   Kernel: $(uname -r)"
    echo "   Architecture: $(uname -m)"
    echo "   Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo
    
    # Check installed services
    echo "🔧 Service Status:"
    
    # Web servers
    if systemctl is-active --quiet apache2 2>/dev/null; then
        echo "   ✅ Apache2: Active"
    elif systemctl is-active --quiet httpd 2>/dev/null; then
        echo "   ✅ Apache (httpd): Active"
    else
        echo "   ❌ Apache: Not running"
    fi
    
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo "   ✅ Nginx: Active"
    else
        echo "   ❌ Nginx: Not running"
    fi
    
    # Databases
    if systemctl is-active --quiet mysql 2>/dev/null; then
        echo "   ✅ MySQL: Active"
    elif systemctl is-active --quiet mariadb 2>/dev/null; then
        echo "   ✅ MariaDB: Active"
    else
        echo "   ❌ MySQL/MariaDB: Not running"
    fi
    
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        echo "   ✅ PostgreSQL: Active"
    else
        echo "   ❌ PostgreSQL: Not running"
    fi
    
    # DNS
    if systemctl is-active --quiet bind9 2>/dev/null; then
        echo "   ✅ BIND9: Active"
    elif systemctl is-active --quiet named 2>/dev/null; then
        echo "   ✅ BIND (named): Active"
    else
        echo "   ❌ DNS Server: Not running"
    fi
    
    # Mail
    if systemctl is-active --quiet postfix 2>/dev/null; then
        echo "   ✅ Postfix: Active"
    else
        echo "   ❌ Postfix: Not running"
    fi
    
    # Firewall
    if systemctl is-active --quiet ufw 2>/dev/null; then
        echo "   ✅ UFW: Active"
    else
        echo "   ❌ UFW: Not active"
    fi
    
    echo
    
    # Check SSL certificates
    echo "🔒 SSL Status:"
    if command -v certbot >/dev/null 2>&1; then
        echo "   ✅ Certbot installed"
        cert_count=$(certbot certificates 2>/dev/null | grep -c "Certificate Name:" || echo "0")
        echo "   📜 Certificates: $cert_count"
    else
        echo "   ❌ Certbot not installed"
    fi
    
    echo
    
    # Disk space
    echo "💾 Disk Usage:"
    df -h / | tail -1 | awk '{print "   Root: " $3 " used, " $4 " available (" $5 " used)"}'
    
    echo
    
    # Memory usage
    echo "🧠 Memory Usage:"
    free -h | grep "Mem:" | awk '{print "   RAM: " $3 " used, " $7 " available"}'
    
    echo
    echo "=================================="
}

# Function to install module
install_module() {
    local module="$1"
    
    if [ -z "$module" ]; then
        log_error "No module specified"
        show_usage
        exit 1
    fi
    
    # Check if module exists
    if [ ! -f "$SCRIPT_DIR/modules/${module}.sh" ]; then
        log_error "Module '${module}' not found"
        log_info "Available modules:"
        list_modules
        exit 1
    fi
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    log_info "Installing module: ${module}"
    log_info "Description: ${MODULES[$module]}"
    
    # Execute the setup script with the module
    if [ -f "$SCRIPT_DIR/setup.sh" ]; then
        "$SCRIPT_DIR/setup.sh" "$module"
    else
        log_error "setup.sh not found in $SCRIPT_DIR"
        exit 1
    fi
}

# Main script logic
main() {
    case "$1" in
        --module)
            if [ -z "$2" ]; then
                log_error "Module name required"
                show_usage
                exit 1
            fi
            install_module "$2"
            ;;
        --status)
            show_status
            ;;
        --list)
            list_modules
            ;;
        --help|-h|"")
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
