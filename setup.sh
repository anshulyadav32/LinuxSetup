#!/bin/bash
# =============================================================================
# Linux Setup - Single Module Complete Installation System
# =============================================================================
# Purpose: Comprehensive installation and setup of individual server modules
# Author: System Administrator
# Version: 2.0
# Usage: ./setup.sh [module_name] [options]
# =============================================================================

set -Eeuo pipefail

# ---------- Color Definitions ----------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# ---------- Global Variables ----------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="$(dirname "$SCRIPT_DIR")"
readonly MODULES_DIR="$BASE_DIR/modules"
readonly LOG_DIR="/var/log/linux-setup"
readonly LOG_FILE="$LOG_DIR/singlem-$(date +%Y%m%d_%H%M%S).log"

# Available modules
readonly AVAILABLE_MODULES=(
    "database"   # MySQL/MariaDB, PostgreSQL
    "webserver"  # Apache, Nginx, PHP
    "dns"        # BIND9, dnsmasq
    "firewall"   # UFW, Fail2Ban, iptables
    "ssl"        # Certbot, OpenSSL, Let's Encrypt
    "extra"      # Postfix, Dovecot, SpamAssassin, ClamAV
    "mail"       # Alias for extra (Mail server)
    "backup"     # Backup tools and automation
    "all"        # Install all modules
)

# ---------- Utility Functions ----------

# Logging functions
log_header() {
    echo -e "\n${CYAN}================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================${NC}\n"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [HEADER] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

log_step() {
    echo -e "\n${YELLOW}► Step $1/$2: $3${NC}"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [STEP] $1/$2: $3" >> "$LOG_FILE"
}

# System check functions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID,,}" in
            ubuntu|debian)
                echo "debian"
                ;;
            centos|rhel|rocky|almalinux|fedora)
                echo "rhel"
                ;;
            arch|manjaro)
                echo "arch"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

get_package_manager() {
    local os_type="$1"
    case "$os_type" in
        "debian")
            echo "apt"
            ;;
        "rhel")
            if command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        "arch")
            echo "pacman"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# System update function
update_system() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_step "1" "10" "Updating system packages"
    
    case "$pkg_mgr" in
        "apt")
            apt-get update -qq
            apt-get upgrade -y -qq
            ;;
        "dnf"|"yum")
            $pkg_mgr update -y -q
            ;;
        "pacman")
            pacman -Syu --noconfirm --quiet
            ;;
        *)
            log_warning "Unknown package manager, skipping system update"
            ;;
    esac
    
    log_success "System packages updated"
}

# Install common dependencies
install_common_dependencies() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_step "2" "10" "Installing common dependencies"
    
    local common_packages=""
    
    case "$pkg_mgr" in
        "apt")
            common_packages="curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release"
            apt-get install -y -qq $common_packages
            ;;
        "dnf"|"yum")
            common_packages="curl wget gnupg2 ca-certificates"
            $pkg_mgr install -y -q $common_packages
            ;;
        "pacman")
            common_packages="curl wget gnupg ca-certificates"
            pacman -S --noconfirm --quiet $common_packages
            ;;
        *)
            log_warning "Unknown package manager, skipping common dependencies"
            ;;
    esac
    
    log_success "Common dependencies installed"
}

# ---------- Module Installation Functions ----------

install_database_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Database Module (MySQL/MariaDB + PostgreSQL)"
    
    log_step "3" "10" "Installing MySQL/MariaDB"
    case "$pkg_mgr" in
        "apt")
            # Install MariaDB
            apt-get install -y -qq mariadb-server mariadb-client
            systemctl enable mariadb
            systemctl start mariadb
            
            # Secure MySQL installation (automated)
            mysql -e "DELETE FROM mysql.user WHERE User='';"
            mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
            mysql -e "DROP DATABASE IF EXISTS test;"
            mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
            mysql -e "FLUSH PRIVILEGES;"
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q mariadb-server mariadb
            systemctl enable mariadb
            systemctl start mariadb
            ;;
        "pacman")
            pacman -S --noconfirm --quiet mariadb
            mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            systemctl enable mariadb
            systemctl start mariadb
            ;;
    esac
    
    log_step "4" "10" "Installing PostgreSQL"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq postgresql postgresql-contrib postgresql-client
            systemctl enable postgresql
            systemctl start postgresql
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q postgresql-server postgresql-contrib
            postgresql-setup --initdb
            systemctl enable postgresql
            systemctl start postgresql
            ;;
        "pacman")
            pacman -S --noconfirm --quiet postgresql
            sudo -u postgres initdb -D /var/lib/postgres/data
            systemctl enable postgresql
            systemctl start postgresql
            ;;
    esac
    
    # Install additional database tools
    log_step "5" "10" "Installing database management tools"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq phpmyadmin pgadmin4 mysql-utilities
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q phpmyadmin pgadmin4
            ;;
        "pacman")
            pacman -S --noconfirm --quiet phpmyadmin
            ;;
    esac
    
    log_success "Database module installation completed"
    log_info "MariaDB and PostgreSQL are running and enabled"
    log_info "Default PostgreSQL user: postgres"
    log_info "Configure passwords with: sudo mysql_secure_installation"
}

install_webserver_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Webserver Module (Apache + Nginx + PHP)"
    
    log_step "3" "10" "Installing Apache HTTP Server"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq apache2 apache2-utils
            systemctl enable apache2
            systemctl start apache2
            
            # Enable common Apache modules
            a2enmod rewrite ssl headers expires deflate
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q httpd httpd-tools
            systemctl enable httpd
            systemctl start httpd
            ;;
        "pacman")
            pacman -S --noconfirm --quiet apache
            systemctl enable httpd
            systemctl start httpd
            ;;
    esac
    
    log_step "4" "10" "Installing Nginx"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq nginx nginx-extras
            systemctl enable nginx
            # Don't start nginx yet (port conflict with Apache)
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q nginx
            systemctl enable nginx
            ;;
        "pacman")
            pacman -S --noconfirm --quiet nginx
            systemctl enable nginx
            ;;
    esac
    
    log_step "5" "10" "Installing PHP and extensions"
    case "$pkg_mgr" in
        "apt")
            # Install PHP 8.3 with common extensions
            apt-get install -y -qq php8.3 php8.3-fpm php8.3-mysql php8.3-pgsql \
                php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip \
                php8.3-intl php8.3-bcmath php8.3-json php8.3-opcache \
                libapache2-mod-php8.3
            
            # Enable PHP-FPM
            systemctl enable php8.3-fpm
            systemctl start php8.3-fpm
            
            # Configure Apache for PHP
            a2enmod php8.3
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q php php-fpm php-mysqlnd php-pgsql php-curl \
                php-gd php-mbstring php-xml php-zip php-intl php-bcmath \
                php-json php-opcache
            
            systemctl enable php-fpm
            systemctl start php-fpm
            ;;
        "pacman")
            pacman -S --noconfirm --quiet php php-fpm php-apache php-gd \
                php-intl php-pgsql
            
            systemctl enable php-fpm
            systemctl start php-fpm
            ;;
    esac
    
    log_step "6" "10" "Configuring web servers"
    
    # Create default web root
    mkdir -p /var/www/html
    chown -R www-data:www-data /var/www/html 2>/dev/null || chown -R apache:apache /var/www/html
    
    # Create PHP info page
    cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF
    
    # Create simple index page
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Linux Setup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { color: #2c3e50; }
        .success { color: #27ae60; }
    </style>
</head>
<body>
    <h1 class="header">🚀 Linux Setup - Webserver Module</h1>
    <p class="success">✅ Apache and PHP are successfully installed!</p>
    <p>Server Information:</p>
    <ul>
        <li>Apache HTTP Server: Running</li>
        <li>PHP: Installed</li>
        <li>Document Root: /var/www/html</li>
    </ul>
    <p><a href="info.php">View PHP Information</a></p>
</body>
</html>
EOF
    
    log_success "Webserver module installation completed"
    log_info "Apache is running on port 80"
    log_info "Nginx is installed but not started (use port 8080 if needed)"
    log_info "PHP-FPM is running and configured"
    log_info "Test page: http://your-server-ip/"
}

install_dns_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing DNS Module (BIND9 + dnsmasq)"
    
    log_step "3" "10" "Installing BIND9 DNS Server"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq bind9 bind9utils bind9-doc dnsutils
            systemctl enable named
            systemctl start named
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q bind bind-utils
            systemctl enable named
            systemctl start named
            ;;
        "pacman")
            pacman -S --noconfirm --quiet bind bind-tools
            systemctl enable named
            systemctl start named
            ;;
    esac
    
    log_step "4" "10" "Installing dnsmasq"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq dnsmasq dnsmasq-utils
            systemctl enable dnsmasq
            # Don't start dnsmasq yet (port conflict with BIND9)
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q dnsmasq
            systemctl enable dnsmasq
            ;;
        "pacman")
            pacman -S --noconfirm --quiet dnsmasq
            systemctl enable dnsmasq
            ;;
    esac
    
    log_step "5" "10" "Configuring DNS services"
    
    # Basic BIND9 configuration
    if [[ -f /etc/bind/named.conf.local ]]; then
        # Debian/Ubuntu path
        BIND_DIR="/etc/bind"
    else
        # RHEL/CentOS path
        BIND_DIR="/etc/named"
    fi
    
    # Create a basic forward zone template
    mkdir -p "$BIND_DIR/zones"
    
    cat > "$BIND_DIR/zones/example.com.db" << 'EOF'
$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                  2024010101         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.example.com.
@       IN      A       192.168.1.100
ns1     IN      A       192.168.1.100
www     IN      A       192.168.1.100
EOF
    
    # Configure dnsmasq for local development
    cat > /etc/dnsmasq.d/local.conf << 'EOF'
# Local development DNS configuration
# Listen on localhost only
interface=lo
bind-interfaces

# Set upstream DNS servers
server=8.8.8.8
server=1.1.1.1

# Local domain resolution
local=/local/
domain=local
expand-hosts

# DHCP range for local network (commented out by default)
# dhcp-range=192.168.1.50,192.168.1.150,12h
EOF
    
    log_success "DNS module installation completed"
    log_info "BIND9 is running on port 53"
    log_info "dnsmasq is installed but not started (configure as needed)"
    log_info "Configuration files in $BIND_DIR"
}

install_firewall_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Firewall Module (UFW + Fail2Ban + iptables)"
    
    log_step "3" "10" "Installing UFW (Uncomplicated Firewall)"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq ufw
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q ufw || {
                # UFW might not be available in RHEL repos, use firewalld instead
                $pkg_mgr install -y -q firewalld
                systemctl enable firewalld
                systemctl start firewalld
                log_info "Installed firewalld instead of UFW (RHEL-based system)"
            }
            ;;
        "pacman")
            pacman -S --noconfirm --quiet ufw
            ;;
    esac
    
    log_step "4" "10" "Installing Fail2Ban"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq fail2ban
            systemctl enable fail2ban
            systemctl start fail2ban
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q fail2ban
            systemctl enable fail2ban
            systemctl start fail2ban
            ;;
        "pacman")
            pacman -S --noconfirm --quiet fail2ban
            systemctl enable fail2ban
            systemctl start fail2ban
            ;;
    esac
    
    log_step "5" "10" "Installing iptables utilities"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq iptables iptables-persistent netfilter-persistent
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q iptables iptables-services
            ;;
        "pacman")
            pacman -S --noconfirm --quiet iptables iptables-nft
            ;;
    esac
    
    log_step "6" "10" "Configuring firewall rules"
    
    if command -v ufw >/dev/null 2>&1; then
        # Configure UFW with basic rules
        ufw --force reset
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow essential services
        ufw allow ssh
        ufw allow 80/tcp    # HTTP
        ufw allow 443/tcp   # HTTPS
        ufw allow 53        # DNS
        
        # Enable UFW
        ufw --force enable
        log_success "UFW configured and enabled"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        # Configure firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-service=dns
        firewall-cmd --reload
        log_success "Firewalld configured"
    fi
    
    # Configure Fail2Ban
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = auto

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[apache-auth]
enabled = true
port = http,https
logpath = /var/log/apache2/error.log

[apache-badbots]
enabled = true
port = http,https
logpath = /var/log/apache2/access.log
bantime = 86400
maxretry = 1

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
EOF
    
    # Restart fail2ban to apply configuration
    systemctl restart fail2ban
    
    log_success "Firewall module installation completed"
    log_info "UFW/Firewalld: Active with basic rules"
    log_info "Fail2Ban: Running with SSH, Apache, and Nginx protection"
    log_info "Default ports open: 22 (SSH), 53 (DNS), 80 (HTTP), 443 (HTTPS)"
}

install_ssl_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing SSL Module (Certbot + OpenSSL)"
    
    log_step "3" "10" "Installing Certbot (Let's Encrypt client)"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq certbot python3-certbot-apache python3-certbot-nginx
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q certbot python3-certbot-apache python3-certbot-nginx
            ;;
        "pacman")
            pacman -S --noconfirm --quiet certbot certbot-apache certbot-nginx
            ;;
    esac
    
    log_step "4" "10" "Installing OpenSSL and tools"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq openssl ca-certificates ssl-cert
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q openssl ca-certificates
            ;;
        "pacman")
            pacman -S --noconfirm --quiet openssl ca-certificates
            ;;
    esac
    
    log_step "5" "10" "Setting up SSL directories"
    
    # Create SSL directories
    mkdir -p /etc/ssl/certs
    mkdir -p /etc/ssl/private
    mkdir -p /etc/ssl/dhparams
    
    # Set proper permissions
    chmod 755 /etc/ssl/certs
    chmod 710 /etc/ssl/private
    
    log_step "6" "10" "Generating DH parameters (this may take a while)"
    
    # Generate DH parameters for better security
    if [[ ! -f /etc/ssl/dhparams/dhparam.pem ]]; then
        openssl dhparam -out /etc/ssl/dhparams/dhparam.pem 2048
        chmod 644 /etc/ssl/dhparams/dhparam.pem
    fi
    
    log_step "7" "10" "Creating self-signed certificate for testing"
    
    # Create self-signed certificate for immediate testing
    if [[ ! -f /etc/ssl/certs/selfsigned.crt ]]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/selfsigned.key \
            -out /etc/ssl/certs/selfsigned.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"
        
        chmod 644 /etc/ssl/certs/selfsigned.crt
        chmod 600 /etc/ssl/private/selfsigned.key
    fi
    
    # Set up Certbot auto-renewal
    if command -v crontab >/dev/null 2>&1; then
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        log_info "Certbot auto-renewal scheduled"
    fi
    
    # Enable SSL module in Apache if available
    if command -v a2enmod >/dev/null 2>&1; then
        a2enmod ssl
        systemctl reload apache2
    fi
    
    log_success "SSL module installation completed"
    log_info "Certbot: Ready for Let's Encrypt certificates"
    log_info "OpenSSL: Installed with DH parameters generated"
    log_info "Self-signed certificate: /etc/ssl/certs/selfsigned.crt"
    log_info "Use 'certbot --apache' or 'certbot --nginx' to get real certificates"
}

install_extra_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Extra Module (Mail Server + Security Tools)"
    
    log_step "3" "10" "Installing Postfix (SMTP Server)"
    case "$pkg_mgr" in
        "apt")
            # Pre-configure Postfix for automatic installation
            echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
            echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
            
            apt-get install -y -qq postfix postfix-utils
            systemctl enable postfix
            systemctl start postfix
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q postfix
            systemctl enable postfix
            systemctl start postfix
            ;;
        "pacman")
            pacman -S --noconfirm --quiet postfix
            systemctl enable postfix
            systemctl start postfix
            ;;
    esac
    
    log_step "4" "10" "Installing Dovecot (IMAP/POP3 Server)"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd
            systemctl enable dovecot
            systemctl start dovecot
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q dovecot
            systemctl enable dovecot
            systemctl start dovecot
            ;;
        "pacman")
            pacman -S --noconfirm --quiet dovecot
            systemctl enable dovecot
            systemctl start dovecot
            ;;
    esac
    
    log_step "5" "10" "Installing SpamAssassin (Anti-spam)"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq spamassassin spamc spamass-milter
            systemctl enable spamassassin
            systemctl start spamassassin
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q spamassassin
            systemctl enable spamassassin
            systemctl start spamassassin
            ;;
        "pacman")
            pacman -S --noconfirm --quiet spamassassin
            systemctl enable spamassassin
            systemctl start spamassassin
            ;;
    esac
    
    log_step "6" "10" "Installing ClamAV (Antivirus)"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq clamav clamav-daemon clamav-freshclam clamav-milter
            systemctl enable clamav-daemon
            systemctl enable clamav-freshclam
            
            # Update virus definitions
            freshclam
            
            systemctl start clamav-daemon
            systemctl start clamav-freshclam
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q clamav clamav-update
            systemctl enable clamd@scan
            systemctl start clamd@scan
            freshclam
            ;;
        "pacman")
            pacman -S --noconfirm --quiet clamav
            freshclam
            systemctl enable clamav-daemon
            systemctl start clamav-daemon
            ;;
    esac
    
    log_step "7" "10" "Installing additional security tools"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq opendkim opendkim-tools opendmarc
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q opendkim opendmarc
            ;;
        "pacman")
            pacman -S --noconfirm --quiet opendkim opendmarc
            ;;
    esac
    
    log_step "8" "10" "Basic mail server configuration"
    
    # Basic Postfix configuration
    postconf -e "mydomain = $(hostname -d)"
    postconf -e "myhostname = $(hostname -f)"
    postconf -e "myorigin = \$mydomain"
    postconf -e "inet_interfaces = all"
    postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
    
    # Basic Dovecot configuration
    if [[ -f /etc/dovecot/dovecot.conf ]]; then
        sed -i 's/#listen = \*, ::/listen = */' /etc/dovecot/dovecot.conf
    fi
    
    # Restart services to apply configuration
    systemctl restart postfix
    systemctl restart dovecot
    
    log_success "Extra module installation completed"
    log_info "Postfix: SMTP server running on port 25"
    log_info "Dovecot: IMAP/POP3 server running"
    log_info "SpamAssassin: Anti-spam filtering active"
    log_info "ClamAV: Antivirus scanning active"
    log_warning "Mail server requires additional DNS configuration (MX records)"
}

install_backup_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Backup Module (Automated Backup System)"
    
    log_step "3" "10" "Installing backup utilities"
    case "$pkg_mgr" in
        "apt")
            apt-get install -y -qq rsync tar gzip bzip2 xz-utils pigz rclone
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q rsync tar gzip bzip2 xz pigz rclone
            ;;
        "pacman")
            pacman -S --noconfirm --quiet rsync tar gzip bzip2 xz pigz rclone
            ;;
    esac
    
    log_step "4" "10" "Installing cloud backup tools"
    
    # Install additional backup tools
    case "$pkg_mgr" in
        "apt")
            # Install Google Cloud SDK for gsutil
            if [[ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]]; then
                curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
                echo "deb https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
                apt-get update -qq
                apt-get install -y -qq google-cloud-sdk
            fi
            
            # Install AWS CLI
            if ! command -v aws >/dev/null 2>&1; then
                curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                ./aws/install
                rm -rf aws awscliv2.zip
            fi
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q awscli
            ;;
        "pacman")
            pacman -S --noconfirm --quiet aws-cli
            ;;
    esac
    
    log_step "5" "10" "Setting up backup directories"
    
    # Create backup directory structure
    mkdir -p /root/backups/{system,database,webserver,ssl,firewall,dns,extra}
    mkdir -p /var/log/backups
    
    # Set proper permissions
    chmod 700 /root/backups
    chmod 755 /var/log/backups
    
    log_step "6" "10" "Creating backup configuration"
    
    # Create backup configuration file
    cat > /etc/backup.conf << 'EOF'
# Linux Setup Backup Configuration
# Generated by singlem/setup.sh

# Backup Settings
BACKUP_ROOT="/root/backups"
LOG_FILE="/var/log/backups/backup.log"
RETENTION_DAYS=30
COMPRESS_BACKUPS=true
COMPRESSION_TYPE="gzip"  # gzip, bzip2, xz

# Database Backup Settings
MYSQL_BACKUP=true
MYSQL_USER="root"
MYSQL_PASSWORD=""
POSTGRESQL_BACKUP=true
POSTGRES_USER="postgres"

# System Backup Settings
BACKUP_SYSTEM_CONFIGS=true
BACKUP_WEB_FILES=true
BACKUP_SSL_CERTS=true

# Remote Backup Settings
REMOTE_BACKUP=false
REMOTE_TYPE="rclone"  # rclone, aws, gcp
REMOTE_DESTINATION=""

# Notification Settings
EMAIL_NOTIFICATIONS=false
EMAIL_TO=""
EMAIL_FROM="backup@$(hostname -f)"
EOF
    
    log_step "7" "10" "Creating backup scripts"
    
    # Create main backup script
    cat > /usr/local/bin/system-backup << 'EOF'
#!/bin/bash
# System Backup Script - Generated by Linux Setup
# Performs comprehensive system backup

set -e

# Load configuration
if [[ -f /etc/backup.conf ]]; then
    source /etc/backup.conf
else
    echo "Error: Backup configuration not found"
    exit 1
fi

# Logging function
log_backup() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# Start backup
log_backup "Starting system backup..."

# Create dated backup directory
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/full_$BACKUP_DATE"
mkdir -p "$BACKUP_DIR"

# Backup system configurations
if [[ "$BACKUP_SYSTEM_CONFIGS" == "true" ]]; then
    log_backup "Backing up system configurations..."
    tar czf "$BACKUP_DIR/system_configs.tar.gz" \
        /etc \
        /root/.ssh 2>/dev/null || true
fi

# Backup web files
if [[ "$BACKUP_WEB_FILES" == "true" ]] && [[ -d /var/www ]]; then
    log_backup "Backing up web files..."
    tar czf "$BACKUP_DIR/web_files.tar.gz" /var/www
fi

# Backup SSL certificates
if [[ "$BACKUP_SSL_CERTS" == "true" ]] && [[ -d /etc/ssl ]]; then
    log_backup "Backing up SSL certificates..."
    tar czf "$BACKUP_DIR/ssl_certs.tar.gz" /etc/ssl /etc/letsencrypt 2>/dev/null || true
fi

# Backup MySQL databases
if [[ "$MYSQL_BACKUP" == "true" ]] && command -v mysqldump >/dev/null 2>&1; then
    log_backup "Backing up MySQL databases..."
    mysqldump --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/mysql_all.sql"
    gzip "$BACKUP_DIR/mysql_all.sql"
fi

# Backup PostgreSQL databases
if [[ "$POSTGRESQL_BACKUP" == "true" ]] && command -v pg_dumpall >/dev/null 2>&1; then
    log_backup "Backing up PostgreSQL databases..."
    sudo -u postgres pg_dumpall > "$BACKUP_DIR/postgresql_all.sql"
    gzip "$BACKUP_DIR/postgresql_all.sql"
fi

# Clean up old backups
if [[ -n "$RETENTION_DAYS" ]] && [[ "$RETENTION_DAYS" -gt 0 ]]; then
    log_backup "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_ROOT" -name "full_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
fi

log_backup "Backup completed: $BACKUP_DIR"
EOF
    
    chmod +x /usr/local/bin/system-backup
    
    log_step "8" "10" "Setting up automated backup schedule"
    
    # Add backup to root's crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/system-backup") | crontab -
    
    log_success "Backup module installation completed"
    log_info "Backup tools: rsync, tar, gzip, rclone, AWS CLI installed"
    log_info "Backup directory: /root/backups"
    log_info "Configuration: /etc/backup.conf"
    log_info "Automated backup scheduled at 2:00 AM daily"
    log_info "Manual backup: /usr/local/bin/system-backup"
}

install_all_modules() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing ALL Modules (Complete Server Setup)"
    log_info "This will install: Database, Webserver, DNS, Firewall, SSL, Mail, and Backup modules"
    log_warning "This is a comprehensive installation that may take 15-30 minutes"
    
    # Confirm installation
    echo -e "\n${YELLOW}⚠️  WARNING: This will install ALL server modules!${NC}"
    echo -e "${CYAN}Modules to be installed:${NC}"
    echo -e "  • Database servers (MySQL, PostgreSQL)"
    echo -e "  • Web servers (Apache, Nginx, PHP)"
    echo -e "  • DNS servers (BIND9, dnsmasq)"
    echo -e "  • Security (UFW, Fail2Ban, iptables)"
    echo -e "  • SSL certificates (Certbot, OpenSSL)"
    echo -e "  • Mail server (Postfix, Dovecot, SpamAssassin, ClamAV)"
    echo -e "  • Backup system (automated backups)"
    echo
    echo -e "${WHITE}This will configure a complete production-ready server.${NC}"
    echo -e "${RED}Continue? [y/N]${NC}: \c"
    
    read -r response
    if [[ ! "$response" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    log_info "Starting complete server installation..."
    
    # Install modules in logical order
    local modules_order=("firewall" "database" "webserver" "dns" "ssl" "extra" "backup")
    local total_modules=${#modules_order[@]}
    local current_module=1
    
    for module in "${modules_order[@]}"; do
        log_header "Installing Module $current_module/$total_modules: $module"
        
        case "$module" in
            "database")
                install_database_module "$os_type" "$pkg_mgr"
                ;;
            "webserver")
                install_webserver_module "$os_type" "$pkg_mgr"
                ;;
            "dns")
                install_dns_module "$os_type" "$pkg_mgr"
                ;;
            "firewall")
                install_firewall_module "$os_type" "$pkg_mgr"
                ;;
            "ssl")
                install_ssl_module "$os_type" "$pkg_mgr"
                ;;
            "extra")
                install_extra_module "$os_type" "$pkg_mgr"
                ;;
            "backup")
                install_backup_module "$os_type" "$pkg_mgr"
                ;;
        esac
        
        log_success "Module '$module' completed ($current_module/$total_modules)"
        ((current_module++))
    done
    
    # Final configuration for integrated setup
    log_step "9" "10" "Configuring integrated services"
    
    # Configure firewall for all services
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 25/tcp    # SMTP
        ufw allow 143/tcp   # IMAP
        ufw allow 993/tcp   # IMAPS
        ufw allow 110/tcp   # POP3
        ufw allow 995/tcp   # POP3S
        ufw --force reload
    fi
    
    # Configure Apache virtual host with SSL
    if [[ -d /etc/apache2/sites-available ]]; then
        cat > /etc/apache2/sites-available/000-default-ssl.conf << 'EOF'
<IfModule mod_ssl.c>
    <VirtualHost *:443>
        DocumentRoot /var/www/html
        
        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/selfsigned.crt
        SSLCertificateKeyFile /etc/ssl/private/selfsigned.key
        
        # Modern SSL configuration
        SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
        SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
        SSLHonorCipherOrder off
        SSLSessionTickets off
        
        Header always set Strict-Transport-Security "max-age=63072000"
    </VirtualHost>
</IfModule>
EOF
        
        a2ensite 000-default-ssl
        systemctl reload apache2
    fi
    
    log_success "Complete server installation finished!"
    log_info "All modules have been installed and configured"
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
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Update system
    update_system "$os_type" "$pkg_mgr"
    
    # Install common dependencies
    install_common_dependencies "$os_type" "$pkg_mgr"
    
    # Install the specific module
    case "$module_name" in
        "database")
            install_database_module "$os_type" "$pkg_mgr"
            ;;
        "webserver")
            install_webserver_module "$os_type" "$pkg_mgr"
            ;;
        "dns")
            install_dns_module "$os_type" "$pkg_mgr"
            ;;
        "firewall")
            install_firewall_module "$os_type" "$pkg_mgr"
            ;;
        "ssl")
            install_ssl_module "$os_type" "$pkg_mgr"
            ;;
        "extra"|"mail")
            install_extra_module "$os_type" "$pkg_mgr"
            ;;
        "backup")
            install_backup_module "$os_type" "$pkg_mgr"
            ;;
        "all")
            install_all_modules "$os_type" "$pkg_mgr"
            ;;
    esac
    
    # Final steps
    log_step "9" "10" "Running post-installation checks"
    
    # Test the module if check script exists
    if [[ -f "$MODULES_DIR/$module_name/check_$module_name.sh" ]]; then
        log_info "Running module health check..."
        if bash "$MODULES_DIR/$module_name/check_$module_name.sh"; then
            log_success "Module health check passed"
        else
            log_warning "Module health check reported issues (check logs)"
        fi
    fi
    
    log_step "10" "10" "Installation completed"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_header "Installation Summary"
    log_success "Module '$module_name' installed successfully!"
    log_info "Duration: ${duration}s"
    log_info "Log file: $LOG_FILE"
    
    # Module-specific post-installation notes
    case "$module_name" in
        "database")
            log_info ""
            log_info "Next Steps for Database Module:"
            log_info "1. Run 'sudo mysql_secure_installation' to secure MySQL"
            log_info "2. Create databases: mysql -e 'CREATE DATABASE myapp;'"
            log_info "3. Configure PostgreSQL: sudo -u postgres createdb myapp"
            ;;
        "webserver")
            log_info ""
            log_info "Next Steps for Webserver Module:"
            log_info "1. Test Apache: http://$(curl -s ifconfig.me || echo 'your-server-ip')/"
            log_info "2. Configure virtual hosts in /etc/apache2/sites-available/"
            log_info "3. Upload website files to /var/www/html/"
            ;;
        "ssl")
            log_info ""
            log_info "Next Steps for SSL Module:"
            log_info "1. Get real certificate: certbot --apache -d yourdomain.com"
            log_info "2. Test renewal: certbot renew --dry-run"
            log_info "3. Configure HTTPS redirect in web server"
            ;;
        "firewall")
            log_info ""
            log_info "Next Steps for Firewall Module:"
            log_info "1. Check status: ufw status verbose"
            log_info "2. Allow custom services: ufw allow 8080"
            log_info "3. Monitor logs: tail -f /var/log/ufw.log"
            ;;
        "extra")
            log_info ""
            log_info "Next Steps for Mail Server:"
            log_info "1. Configure DNS MX record pointing to this server"
            log_info "2. Test mail: echo 'Test' | mail -s 'Subject' user@domain.com"
            log_info "3. Configure SPF/DKIM/DMARC for better deliverability"
            ;;
        "backup")
            log_info ""
            log_info "Next Steps for Backup Module:"
            log_info "1. Edit configuration: nano /etc/backup.conf"
            log_info "2. Test backup: /usr/local/bin/system-backup"
            log_info "3. Configure remote storage (rclone config)"
            ;;
        "all")
            log_info ""
            log_info "🎉 Complete Server Setup Finished!"
            log_info ""
            log_info "Your server now includes:"
            log_info "✅ Database: MySQL/MariaDB + PostgreSQL"
            log_info "✅ Webserver: Apache + Nginx + PHP"
            log_info "✅ DNS: BIND9 + dnsmasq"
            log_info "✅ Security: UFW + Fail2Ban + iptables"
            log_info "✅ SSL: Certbot + OpenSSL + self-signed certs"
            log_info "✅ Mail: Postfix + Dovecot + SpamAssassin + ClamAV"
            log_info "✅ Backup: Automated backup system"
            log_info ""
            log_info "🔧 Next Steps:"
            log_info "1. Test web server: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')/"
            log_info "2. Get SSL certificate: certbot --apache -d yourdomain.com"
            log_info "3. Configure DNS MX record for mail server"
            log_info "4. Run mysql_secure_installation for database security"
            log_info "5. Configure backup settings: nano /etc/backup.conf"
            log_info ""
            log_warning "Remember to configure your domain DNS records!"
            ;;
    esac
}

# ---------- Help and Usage ----------

show_help() {
    cat << EOF

🚀 Linux Setup - Single Module Installation System

USAGE:
    sudo ./setup.sh <module> [options]

AVAILABLE MODULES:
    database   - MySQL/MariaDB + PostgreSQL + management tools
    webserver  - Apache + Nginx + PHP + common extensions  
    dns        - BIND9 + dnsmasq DNS servers
    firewall   - UFW + Fail2Ban + iptables security
    ssl        - Certbot + OpenSSL + Let's Encrypt integration
    mail       - Postfix + Dovecot + SpamAssassin + ClamAV mail server
    extra      - Same as mail (alias for mail server)
    backup     - Automated backup system + cloud integration
    all        - Install ALL modules (complete server setup)

OPTIONS:
    -h, --help     Show this help message
    -v, --verbose  Enable verbose logging
    --dry-run      Show what would be installed (not implemented)

EXAMPLES:
    sudo ./setup.sh all          # Install ALL modules (complete server)
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
    
    echo -e "${GREEN}webserver${NC}  - Full web server stack"
    echo -e "             • Apache HTTP Server with modules"
    echo -e "             • Nginx web server"
    echo -e "             • PHP 8.3 with common extensions"
    echo -e "             • Web server configuration"
    
    echo -e "${GREEN}dns${NC}        - DNS server infrastructure"
    echo -e "             • BIND9 authoritative DNS server"
    echo -e "             • dnsmasq lightweight DNS/DHCP"
    echo -e "             • DNS utilities and tools"
    
    echo -e "${GREEN}firewall${NC}   - Comprehensive security setup"
    echo -e "             • UFW (Uncomplicated Firewall)"
    echo -e "             • Fail2Ban intrusion prevention"
    echo -e "             • iptables configuration"
    echo -e "             • Security monitoring"
    
    echo -e "${GREEN}ssl${NC}        - SSL/TLS certificate management"
    echo -e "             • Certbot (Let's Encrypt client)"
    echo -e "             • OpenSSL tools and utilities"
    echo -e "             • Automated certificate renewal"
    echo -e "             • Self-signed certificate generation"
    
    echo -e "${GREEN}extra${NC}      - Mail server and security tools"
    echo -e "             • Postfix SMTP server"
    echo -e "             • Dovecot IMAP/POP3 server"
    echo -e "             • SpamAssassin anti-spam"
    echo -e "             • ClamAV antivirus scanner"
    echo -e "             • OpenDKIM and OpenDMARC"
    
    echo -e "${GREEN}backup${NC}     - Automated backup system"
    echo -e "             • Local backup tools (rsync, tar)"
    echo -e "             • Cloud backup integration (rclone)"
    echo -e "             • AWS CLI and Google Cloud SDK"
    echo -e "             • Automated scheduling and cleanup"
    
    echo -e "${YELLOW}all${NC}        - ${WHITE}Complete server installation${NC}"
    echo -e "             ${CYAN}• Installs ALL modules above${NC}"
    echo -e "             ${CYAN}• Production-ready server setup${NC}"
    echo -e "             ${CYAN}• Integrated configuration${NC}"
    echo -e "             ${RED}• Warning: Comprehensive installation${NC}"
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
