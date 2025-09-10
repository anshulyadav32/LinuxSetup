#!/bin/bash
# =============================================================================
# Firewall Module - UFW, Fail2Ban, iptables Security Setup
# =============================================================================
# Purpose: Install and configure comprehensive firewall and security tools
# Components: UFW (Uncomplicated Firewall), Fail2Ban, iptables, security monitoring
# =============================================================================

# Firewall module installation function
install_firewall_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Firewall Security Module"
    
    log_step "1" "8" "Installing firewall packages"
    
    # Define packages based on OS
    local packages=()
    
    case "$os_type" in
        ubuntu|debian)
            packages=(
                "ufw"               # Uncomplicated Firewall
                "fail2ban"          # Intrusion prevention system
                "iptables"          # Netfilter administration tool
                "iptables-persistent" # Save iptables rules
                "netfilter-persistent" # Netfilter rules persistence
                "rsyslog"           # System logging daemon
                "logrotate"         # Log rotation utility
                "nftables"          # Modern netfilter framework
                "conntrack"         # Connection tracking userspace tools
                "tcpdump"           # Network packet analyzer
                "nmap"              # Network exploration tool
                "psad"              # Port Scan Attack Detector
                "chkrootkit"        # Rootkit detector
                "rkhunter"          # Rootkit hunter
            )
            ;;
        centos|rhel|fedora)
            packages=(
                "firewalld"         # Dynamic firewall manager
                "fail2ban"          # Intrusion prevention system
                "iptables"          # Netfilter administration tool
                "iptables-services" # iptables service scripts
                "rsyslog"           # System logging daemon
                "logrotate"         # Log rotation utility
                "nftables"          # Modern netfilter framework
                "conntrack-tools"   # Connection tracking tools
                "tcpdump"           # Network packet analyzer
                "nmap"              # Network exploration tool
                "psad"              # Port Scan Attack Detector (EPEL)
                "chkrootkit"        # Rootkit detector
                "rkhunter"          # Rootkit hunter
            )
            ;;
        arch)
            packages=(
                "ufw"               # Uncomplicated Firewall
                "fail2ban"          # Intrusion prevention system
                "iptables"          # Netfilter administration tool
                "iptables-nft"      # iptables using nftables backend
                "rsyslog"           # System logging daemon
                "logrotate"         # Log rotation utility
                "nftables"          # Modern netfilter framework
                "conntrack-tools"   # Connection tracking tools
                "tcpdump"           # Network packet analyzer
                "nmap"              # Network exploration tool
                "psad"              # Port Scan Attack Detector (AUR)
                "chkrootkit"        # Rootkit detector
                "rkhunter"          # Rootkit hunter
            )
            ;;
    esac
    
    install_packages "$os_type" "$pkg_mgr" "${packages[@]}"
    
    log_step "2" "8" "Configuring UFW firewall"
    configure_ufw "$os_type"
    
    log_step "3" "8" "Setting up Fail2Ban"
    configure_fail2ban "$os_type"
    
    log_step "4" "8" "Configuring iptables rules"
    configure_iptables "$os_type"
    
    log_step "5" "8" "Setting up security monitoring"
    configure_security_monitoring "$os_type"
    
    log_step "6" "8" "Creating firewall management scripts"
    create_firewall_scripts
    
    log_step "7" "8" "Enabling and starting services"
    enable_firewall_services "$os_type"
    
    log_step "8" "8" "Verifying firewall configuration"
    verify_firewall_setup "$os_type"
    
    log_success "Firewall module installation completed successfully!"
}

# Configure UFW (Uncomplicated Firewall)
configure_ufw() {
    local os_type="$1"
    
    log_info "Configuring UFW firewall..."
    
    # Reset UFW to defaults
    ufw --force reset >/dev/null 2>&1
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    ufw default deny forward
    
    # Allow essential services
    ufw allow ssh comment 'SSH access'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 53 comment 'DNS'
    ufw allow 123/udp comment 'NTP'
    
    # Allow local network (common private ranges)
    ufw allow from 192.168.0.0/16
    ufw allow from 10.0.0.0/8
    ufw allow from 172.16.0.0/12
    
    # Enable UFW logging
    ufw logging on
    
    # Create UFW application profiles
    cat > /etc/ufw/applications.d/custom << 'EOF'
[Nginx HTTP]
title=Web Server (Nginx, HTTP)
description=Small, but very powerful and efficient web server
ports=80/tcp

[Nginx HTTPS]
title=Web Server (Nginx, HTTPS)
description=Small, but very powerful and efficient web server
ports=443/tcp

[Nginx Full]
title=Web Server (Nginx, HTTP + HTTPS)
description=Small, but very powerful and efficient web server
ports=80,443/tcp

[Apache]
title=Web Server (Apache)
description=Apache v2 web server
ports=80/tcp

[Apache Secure]
title=Web Server (Apache, HTTPS)
description=Apache v2 web server (HTTPS)
ports=443/tcp

[Apache Full]
title=Web Server (Apache, HTTP + HTTPS)
description=Apache v2 web server
ports=80,443/tcp

[MySQL]
title=MySQL
description=MySQL database
ports=3306/tcp

[PostgreSQL]
title=PostgreSQL
description=PostgreSQL database
ports=5432/tcp

[Mail]
title=Mail server
description=Internet mail server
ports=25,110,143,993,995/tcp
EOF
    
    # Enable UFW
    ufw --force enable
    
    log_success "UFW configured successfully"
}

# Configure Fail2Ban
configure_fail2ban() {
    local os_type="$1"
    
    log_info "Configuring Fail2Ban intrusion prevention..."
    
    # Create local jail configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban time (seconds)
bantime = 3600

# Find time window (seconds)
findtime = 600

# Max retry attempts
maxretry = 5

# Backend to use for log monitoring
backend = auto

# Email configuration
destemail = root@localhost
sender = root@localhost
mta = sendmail
action = %(action_)s

# Ignore IP list (whitelist)
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[apache-auth]
enabled = true
filter = apache-auth
logpath = /var/log/apache*/*error.log
maxretry = 6

[apache-badbots]
enabled = true
filter = apache-badbots
logpath = /var/log/apache*/*access.log
maxretry = 2

[apache-noscript]
enabled = true
filter = apache-noscript
logpath = /var/log/apache*/*access.log
maxretry = 6

[apache-overflows]
enabled = true
filter = apache-overflows
logpath = /var/log/apache*/*access.log
maxretry = 2

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 6

[nginx-noscript]
enabled = true
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6

[nginx-badbots]
enabled = true
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-botsearch]
enabled = true
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2

[postfix]
enabled = true
filter = postfix
logpath = /var/log/mail.log
maxretry = 3

[dovecot]
enabled = true
filter = dovecot
logpath = /var/log/mail.log
maxretry = 3

[mysql-auth]
enabled = true
filter = mysql-auth
logpath = /var/log/mysql/error.log
maxretry = 5

[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
action = %(banaction)s[name=%(__name__)s-%(protocol)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
protocol = tcp
chain = INPUT
bantime = 86400
findtime = 86400
maxretry = 5
EOF
    
    # Create custom filters if they don't exist
    if [[ ! -f "/etc/fail2ban/filter.d/nginx-badbots.conf" ]]; then
        cat > /etc/fail2ban/filter.d/nginx-badbots.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*"(?:200|302|400|403|404|444|499|500|502|503).*"[^"]*(?:bot|crawler|spider|scanner|scraper)"
ignoreregex =
EOF
    fi
    
    if [[ ! -f "/etc/fail2ban/filter.d/nginx-botsearch.conf" ]]; then
        cat > /etc/fail2ban/filter.d/nginx-botsearch.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*(search|admin|wp-|xmlrpc).*HTTP.*".*$
ignoreregex =
EOF
    fi
    
    # Restart and enable fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    log_success "Fail2Ban configured successfully"
}

# Configure iptables rules
configure_iptables() {
    local os_type="$1"
    
    log_info "Configuring iptables rules..."
    
    # Create iptables rules script
    cat > /usr/local/bin/setup-iptables.sh << 'EOF'
#!/bin/bash
# Basic iptables configuration

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback interface
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (adjust port if needed)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP and HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Allow DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# Allow NTP
iptables -A INPUT -p udp --dport 123 -j ACCEPT

# Allow ping (ICMP)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log dropped packets (optional, uncomment if needed)
# iptables -A INPUT -j LOG --log-prefix "iptables-dropped: " --log-level 4

# Drop everything else
iptables -A INPUT -j DROP

echo "iptables rules applied successfully"
EOF
    
    chmod +x /usr/local/bin/setup-iptables.sh
    
    # Apply the rules
    /usr/local/bin/setup-iptables.sh
    
    # Save rules based on OS
    case "$os_type" in
        ubuntu|debian)
            if command -v iptables-save >/dev/null; then
                iptables-save > /etc/iptables/rules.v4
                if command -v ip6tables-save >/dev/null; then
                    ip6tables-save > /etc/iptables/rules.v6
                fi
            fi
            ;;
        centos|rhel|fedora)
            if command -v iptables-save >/dev/null; then
                iptables-save > /etc/sysconfig/iptables
            fi
            ;;
    esac
    
    log_success "iptables configured successfully"
}

# Configure security monitoring
configure_security_monitoring() {
    local os_type="$1"
    
    log_info "Setting up security monitoring..."
    
    # Configure PSAD (Port Scan Attack Detector) if available
    if command -v psad >/dev/null; then
        # Configure PSAD
        sed -i 's/^EMAIL_ADDRESSES.*/EMAIL_ADDRESSES root@localhost;/' /etc/psad/psad.conf 2>/dev/null || true
        sed -i 's/^HOSTNAME.*/HOSTNAME localhost;/' /etc/psad/psad.conf 2>/dev/null || true
        
        # Enable PSAD
        systemctl enable psad 2>/dev/null || true
        systemctl start psad 2>/dev/null || true
    fi
    
    # Configure rkhunter (Rootkit Hunter)
    if command -v rkhunter >/dev/null; then
        # Update rkhunter database
        rkhunter --update >/dev/null 2>&1 || true
        rkhunter --propupd >/dev/null 2>&1 || true
        
        # Configure rkhunter
        if [[ -f "/etc/rkhunter.conf" ]]; then
            sed -i 's/^#MAIL-ON-WARNING=.*/MAIL-ON-WARNING=root@localhost/' /etc/rkhunter.conf
            sed -i 's/^#WEB_CMD=.*/WEB_CMD=""/' /etc/rkhunter.conf
        fi
    fi
    
    # Configure chkrootkit
    if command -v chkrootkit >/dev/null; then
        # Create chkrootkit cron job
        cat > /etc/cron.daily/chkrootkit << 'EOF'
#!/bin/bash
# Daily chkrootkit scan
/usr/sbin/chkrootkit > /var/log/chkrootkit.log 2>&1
if [ $? -ne 0 ]; then
    echo "chkrootkit found potential rootkits - check /var/log/chkrootkit.log" | mail -s "chkrootkit Alert" root
fi
EOF
        chmod +x /etc/cron.daily/chkrootkit
    fi
    
    # Setup log monitoring
    mkdir -p /var/log/security-monitor
    
    # Create security log monitoring script
    cat > /usr/local/bin/security-monitor.sh << 'EOF'
#!/bin/bash
# Security monitoring script

LOG_FILE="/var/log/security-monitor/security-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Security monitoring check started" >> "$LOG_FILE"

# Check for failed SSH logins
FAILED_SSH=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
if [[ $FAILED_SSH -gt 10 ]]; then
    echo "[$DATE] WARNING: $FAILED_SSH failed SSH attempts detected" >> "$LOG_FILE"
fi

# Check for multiple connection attempts from same IP
SUSPICIOUS_IPS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | awk '{print $(NF-3)}' | sort | uniq -c | awk '$1 > 5 {print $2}' | wc -l)
if [[ $SUSPICIOUS_IPS -gt 0 ]]; then
    echo "[$DATE] WARNING: $SUSPICIOUS_IPS suspicious IPs detected" >> "$LOG_FILE"
fi

# Check system load
LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | sed 's/^[ \t]*//')
if (( $(echo "$LOAD > 5" | bc -l) )); then
    echo "[$DATE] WARNING: High system load: $LOAD" >> "$LOG_FILE"
fi

echo "[$DATE] Security monitoring check completed" >> "$LOG_FILE"
EOF
    
    chmod +x /usr/local/bin/security-monitor.sh
    
    # Add to cron (every 30 minutes)
    (crontab -l 2>/dev/null; echo "*/30 * * * * /usr/local/bin/security-monitor.sh") | crontab -
    
    log_success "Security monitoring configured successfully"
}

# Create firewall management scripts
create_firewall_scripts() {
    log_info "Creating firewall management scripts..."
    
    # Create firewall manager script
    cat > /usr/local/bin/firewall-manager << 'EOF'
#!/bin/bash
# Firewall Management Script
# Usage: firewall-manager [command] [options]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    cat << HELP

🔥 Firewall Manager - Comprehensive Firewall Management Tool

USAGE:
    firewall-manager [command] [options]

COMMANDS:
    status          Show firewall status
    enable          Enable firewall
    disable         Disable firewall
    reset           Reset firewall to defaults
    allow [port]    Allow specific port/service
    deny [port]     Deny specific port/service
    list            List all rules
    logs            Show firewall logs
    fail2ban        Manage Fail2Ban
    monitor         Real-time monitoring
    backup          Backup firewall rules
    restore         Restore firewall rules
    security-scan   Run security scan
    help            Show this help

EXAMPLES:
    firewall-manager status
    firewall-manager allow 8080
    firewall-manager deny 23
    firewall-manager logs
    firewall-manager fail2ban status

HELP
}

show_status() {
    echo -e "${CYAN}=== Firewall Status ===${NC}"
    
    # UFW status
    if command -v ufw >/dev/null; then
        echo -e "${BLUE}UFW Status:${NC}"
        ufw status verbose
        echo
    fi
    
    # Fail2Ban status
    if command -v fail2ban-client >/dev/null; then
        echo -e "${BLUE}Fail2Ban Status:${NC}"
        fail2ban-client status
        echo
    fi
    
    # iptables rules count
    if command -v iptables >/dev/null; then
        echo -e "${BLUE}iptables Rules:${NC}"
        RULES_COUNT=$(iptables -L | wc -l)
        echo "Total rules: $RULES_COUNT"
        echo
    fi
}

manage_port() {
    local action="$1"
    local port="$2"
    
    if [[ -z "$port" ]]; then
        echo -e "${RED}Error: Port/service required${NC}"
        exit 1
    fi
    
    case "$action" in
        allow)
            ufw allow "$port"
            echo -e "${GREEN}Port $port allowed${NC}"
            ;;
        deny)
            ufw deny "$port"
            echo -e "${YELLOW}Port $port denied${NC}"
            ;;
    esac
}

show_logs() {
    echo -e "${CYAN}=== Firewall Logs ===${NC}"
    
    # UFW logs
    if [[ -f "/var/log/ufw.log" ]]; then
        echo -e "${BLUE}Recent UFW logs:${NC}"
        tail -20 /var/log/ufw.log
        echo
    fi
    
    # Fail2Ban logs
    if [[ -f "/var/log/fail2ban.log" ]]; then
        echo -e "${BLUE}Recent Fail2Ban logs:${NC}"
        tail -20 /var/log/fail2ban.log
        echo
    fi
}

manage_fail2ban() {
    local command="$2"
    
    case "$command" in
        status)
            fail2ban-client status
            ;;
        start)
            systemctl start fail2ban
            echo -e "${GREEN}Fail2Ban started${NC}"
            ;;
        stop)
            systemctl stop fail2ban
            echo -e "${YELLOW}Fail2Ban stopped${NC}"
            ;;
        restart)
            systemctl restart fail2ban
            echo -e "${GREEN}Fail2Ban restarted${NC}"
            ;;
        banned)
            fail2ban-client status | grep "Jail list:" | sed -E 's/^[^:]+:(.*)$/\1/' | tr ',' '\n' | while read -r jail; do
                jail=$(echo "$jail" | xargs)
                if [[ -n "$jail" ]]; then
                    echo -e "${BLUE}$jail:${NC}"
                    fail2ban-client status "$jail"
                    echo
                fi
            done
            ;;
        unban)
            local ip="$3"
            if [[ -n "$ip" ]]; then
                fail2ban-client set sshd unbanip "$ip"
                echo -e "${GREEN}IP $ip unbanned${NC}"
            else
                echo -e "${RED}Error: IP address required${NC}"
            fi
            ;;
        *)
            echo "Usage: firewall-manager fail2ban [status|start|stop|restart|banned|unban IP]"
            ;;
    esac
}

monitor_realtime() {
    echo -e "${CYAN}=== Real-time Firewall Monitoring ===${NC}"
    echo "Press Ctrl+C to stop..."
    echo
    
    # Monitor various logs
    tail -f /var/log/ufw.log /var/log/fail2ban.log /var/log/auth.log 2>/dev/null | while read -r line; do
        if echo "$line" | grep -q "BLOCK"; then
            echo -e "${RED}[BLOCKED] $line${NC}"
        elif echo "$line" | grep -q "Ban"; then
            echo -e "${YELLOW}[BANNED] $line${NC}"
        elif echo "$line" | grep -q "Found"; then
            echo -e "${BLUE}[DETECTED] $line${NC}"
        else
            echo "$line"
        fi
    done
}

backup_rules() {
    local backup_dir="/etc/firewall-backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    echo -e "${BLUE}Backing up firewall rules...${NC}"
    
    # Backup UFW rules
    if command -v ufw >/dev/null; then
        cp -r /etc/ufw "$backup_dir/ufw_$timestamp"
    fi
    
    # Backup iptables rules
    if command -v iptables-save >/dev/null; then
        iptables-save > "$backup_dir/iptables_$timestamp.rules"
    fi
    
    # Backup Fail2Ban config
    if [[ -d "/etc/fail2ban" ]]; then
        cp -r /etc/fail2ban "$backup_dir/fail2ban_$timestamp"
    fi
    
    echo -e "${GREEN}Firewall rules backed up to: $backup_dir${NC}"
    echo "Timestamp: $timestamp"
}

security_scan() {
    echo -e "${CYAN}=== Security Scan ===${NC}"
    
    # Check open ports
    echo -e "${BLUE}Open ports:${NC}"
    netstat -tuln | grep LISTEN
    echo
    
    # Check for suspicious connections
    echo -e "${BLUE}Current connections:${NC}"
    netstat -an | grep ESTABLISHED | wc -l
    echo "Active connections count"
    echo
    
    # Check recent failed logins
    echo -e "${BLUE}Recent failed SSH attempts:${NC}"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5
    echo
    
    # Check system load
    echo -e "${BLUE}System load:${NC}"
    uptime
    echo
}

# Main command handler
case "${1:-help}" in
    status)
        show_status
        ;;
    enable)
        ufw --force enable
        echo -e "${GREEN}Firewall enabled${NC}"
        ;;
    disable)
        ufw --force disable
        echo -e "${YELLOW}Firewall disabled${NC}"
        ;;
    reset)
        ufw --force reset
        echo -e "${YELLOW}Firewall reset to defaults${NC}"
        ;;
    allow)
        manage_port "allow" "$2"
        ;;
    deny)
        manage_port "deny" "$2"
        ;;
    list)
        ufw status numbered
        ;;
    logs)
        show_logs
        ;;
    fail2ban)
        manage_fail2ban "$@"
        ;;
    monitor)
        monitor_realtime
        ;;
    backup)
        backup_rules
        ;;
    security-scan)
        security_scan
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/firewall-manager
    
    # Create quick firewall status script
    cat > /usr/local/bin/fw-status << 'EOF'
#!/bin/bash
# Quick firewall status check
/usr/local/bin/firewall-manager status
EOF
    
    chmod +x /usr/local/bin/fw-status
    
    log_success "Firewall management scripts created successfully"
}

# Enable and start firewall services
enable_firewall_services() {
    local os_type="$1"
    
    log_info "Enabling and starting firewall services..."
    
    # Enable and start services based on OS
    case "$os_type" in
        ubuntu|debian)
            # UFW
            systemctl enable ufw
            ufw --force enable
            
            # Fail2Ban
            systemctl enable fail2ban
            systemctl start fail2ban
            
            # rsyslog
            systemctl enable rsyslog
            systemctl start rsyslog
            ;;
        centos|rhel|fedora)
            # firewalld instead of UFW on RHEL-based systems
            systemctl enable firewalld
            systemctl start firewalld
            
            # Fail2Ban
            systemctl enable fail2ban
            systemctl start fail2ban
            
            # rsyslog
            systemctl enable rsyslog
            systemctl start rsyslog
            ;;
        arch)
            # UFW
            systemctl enable ufw
            ufw --force enable
            
            # Fail2Ban
            systemctl enable fail2ban
            systemctl start fail2ban
            
            # rsyslog
            systemctl enable rsyslog
            systemctl start rsyslog
            ;;
    esac
    
    log_success "Firewall services enabled and started"
}

# Verify firewall setup
verify_firewall_setup() {
    local os_type="$1"
    
    log_info "Verifying firewall configuration..."
    
    # Check UFW status
    if command -v ufw >/dev/null; then
        local ufw_status=$(ufw status | grep -c "Status: active")
        if [[ $ufw_status -gt 0 ]]; then
            log_success "UFW is active and configured"
        else
            log_warning "UFW is not active"
        fi
    fi
    
    # Check Fail2Ban status
    if command -v fail2ban-client >/dev/null; then
        if systemctl is-active --quiet fail2ban; then
            log_success "Fail2Ban is running"
            local jail_count=$(fail2ban-client status 2>/dev/null | grep -c "Jail list" || echo "0")
            if [[ $jail_count -gt 0 ]]; then
                log_success "Fail2Ban jails are configured"
            fi
        else
            log_warning "Fail2Ban is not running"
        fi
    fi
    
    # Check iptables rules
    if command -v iptables >/dev/null; then
        local rules_count=$(iptables -L | wc -l)
        if [[ $rules_count -gt 10 ]]; then
            log_success "iptables rules are configured ($rules_count rules)"
        else
            log_warning "iptables has minimal rules"
        fi
    fi
    
    # Check if management scripts are executable
    if [[ -x "/usr/local/bin/firewall-manager" ]]; then
        log_success "Firewall management script installed"
    fi
    
    # Display final status
    log_info "Firewall Setup Summary:"
    if command -v ufw >/dev/null; then
        ufw status
    fi
    
    log_success "Firewall verification completed"
}

# Module-specific functions can be called individually
case "${1:-}" in
    configure_ufw)
        configure_ufw "${2:-ubuntu}"
        ;;
    configure_fail2ban)
        configure_fail2ban "${2:-ubuntu}"
        ;;
    configure_iptables)
        configure_iptables "${2:-ubuntu}"
        ;;
    *)
        # Default: run full installation if sourced
        if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
            echo "Firewall module - use install_firewall_module function"
        fi
        ;;
esac
