#!/bin/bash
# Demo script to showcase the setup.sh functionality
# This demonstrates the comprehensive installation system

echo "🚀 Linux Setup - Single Module Installation System Demo"
echo "======================================================="
echo
echo "This script provides complete installation functions for all server modules:"
echo

echo "1. AVAILABLE MODULES:"
echo "   • database   - MySQL/MariaDB + PostgreSQL + management tools"
echo "   • webserver  - Apache + Nginx + PHP + extensions"
echo "   • dns        - BIND9 + dnsmasq DNS servers" 
echo "   • firewall   - UFW + Fail2Ban + iptables security"
echo "   • ssl        - Certbot + OpenSSL + Let's Encrypt"
echo "   • extra      - Mail server (Postfix + Dovecot + SpamAssassin + ClamAV)"
echo "   • backup     - Automated backup system + cloud integration"
echo

echo "2. KEY FEATURES:"
echo "   ✅ Multi-OS Support: Ubuntu, Debian, CentOS, RHEL, Arch Linux"
echo "   ✅ Automatic OS Detection and Package Manager Selection"
echo "   ✅ Complete Component Installation with Dependencies"
echo "   ✅ Service Configuration and Auto-start Setup"
echo "   ✅ Security Best Practices Implementation"
echo "   ✅ Comprehensive Logging and Error Handling"
echo "   ✅ Post-installation Health Checks"
echo "   ✅ Detailed Setup Instructions and Next Steps"
echo

echo "3. USAGE EXAMPLES:"
echo "   sudo ./setup.sh webserver    # Complete LAMP/LEMP stack"
echo "   sudo ./setup.sh database     # MySQL + PostgreSQL servers"
echo "   sudo ./setup.sh ssl          # SSL certificates with auto-renewal"
echo "   sudo ./setup.sh firewall     # Security hardening with monitoring"
echo "   sudo ./setup.sh extra        # Full mail server with anti-spam/virus"
echo "   sudo ./setup.sh backup       # Automated backup with cloud sync"
echo

echo "4. WHAT EACH MODULE INSTALLS:"
echo

echo "📊 DATABASE MODULE:"
echo "   • MySQL/MariaDB server with security configuration"
echo "   • PostgreSQL server with contrib modules"
echo "   • phpMyAdmin and pgAdmin4 web interfaces"
echo "   • Database backup utilities and scripts"
echo "   • Automated security hardening"
echo

echo "🌐 WEBSERVER MODULE:"
echo "   • Apache HTTP Server with SSL, rewrite, headers modules"
echo "   • Nginx web server (configured but not started)"
echo "   • PHP 8.3 with 15+ essential extensions"
echo "   • PHP-FPM for optimal performance"
echo "   • Sample pages and configuration templates"
echo

echo "🔍 DNS MODULE:"
echo "   • BIND9 authoritative DNS server"
echo "   • dnsmasq lightweight DNS/DHCP server"
echo "   • DNS utilities (dig, nslookup, host)"
echo "   • Example zone configuration files"
echo "   • DNS resolution testing tools"
echo

echo "🔥 FIREWALL MODULE:"
echo "   • UFW (Uncomplicated Firewall) with basic rules"
echo "   • Fail2Ban with SSH, Apache, Nginx protection"
echo "   • iptables utilities and persistent rules"
echo "   • Security monitoring and logging"
echo "   • Automated intrusion prevention"
echo

echo "🔒 SSL MODULE:"
echo "   • Certbot (Let's Encrypt client) with Apache/Nginx plugins"
echo "   • OpenSSL tools and certificate utilities"
echo "   • DH parameters generation for enhanced security"
echo "   • Self-signed certificate for immediate testing"
echo "   • Automated certificate renewal via cron"
echo

echo "📧 EXTRA MODULE (Mail Server):"
echo "   • Postfix SMTP server with security configuration"
echo "   • Dovecot IMAP/POP3 server"
echo "   • SpamAssassin anti-spam filtering"
echo "   • ClamAV antivirus scanning with auto-updates"
echo "   • OpenDKIM and OpenDMARC for email authentication"
echo

echo "💾 BACKUP MODULE:"
echo "   • Local backup tools (rsync, tar, compression utilities)"
echo "   • Cloud integration (rclone, AWS CLI, Google Cloud SDK)"
echo "   • Automated backup scheduling with cron"
echo "   • Configurable retention policies"
echo "   • Database-aware backup scripts"
echo "   • Remote storage synchronization"
echo

echo "5. TECHNICAL HIGHLIGHTS:"
echo "   🔧 Intelligent OS detection and package manager selection"
echo "   🔧 Graceful error handling with detailed logging"
echo "   🔧 Service dependency management and startup ordering"
echo "   🔧 Security-first configuration with best practices"
echo "   🔧 Modular design allowing individual component installation"
echo "   🔧 Post-installation validation and health checks"
echo

echo "6. LOGS AND MONITORING:"
echo "   📝 Installation logs: /var/log/linux-setup/"
echo "   📝 Service logs: systemctl status <service>"
echo "   📝 Module health checks: Available via s3.sh system"
echo "   📝 Backup logs: /var/log/backups/"
echo

echo "Ready to install any module with: sudo ./setup.sh <module_name>"
echo "Use './setup.sh --help' for detailed usage information"
echo "Use './setup.sh --list' for detailed module descriptions"
