#!/bin/bash
# =============================================================================
# SSL Module Installation (Certbot + OpenSSL)
# =============================================================================

install_ssl_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing SSL Module (Certbot + OpenSSL)"
    
    log_step "3" "10" "Installing Certbot (Let's Encrypt client)"
    
    local certbot_packages=""
    case "$pkg_mgr" in
        "apt")
            certbot_packages="certbot python3-certbot-apache python3-certbot-nginx"
            install_packages "$pkg_mgr" $certbot_packages
            ;;
        "dnf"|"yum")
            certbot_packages="certbot python3-certbot-apache python3-certbot-nginx"
            install_packages "$pkg_mgr" $certbot_packages
            ;;
        "pacman")
            certbot_packages="certbot certbot-apache certbot-nginx"
            install_packages "$pkg_mgr" $certbot_packages
            ;;
        *)
            log_error "Unsupported package manager for Certbot installation"
            return 1
            ;;
    esac
    
    log_step "4" "10" "Installing OpenSSL and tools"
    
    local openssl_packages=""
    case "$pkg_mgr" in
        "apt")
            openssl_packages="openssl ca-certificates ssl-cert"
            install_packages "$pkg_mgr" $openssl_packages
            ;;
        "dnf"|"yum")
            openssl_packages="openssl ca-certificates"
            install_packages "$pkg_mgr" $openssl_packages
            ;;
        "pacman")
            openssl_packages="openssl ca-certificates"
            install_packages "$pkg_mgr" $openssl_packages
            ;;
        *)
            log_error "Unsupported package manager for OpenSSL installation"
            return 1
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
    chmod 755 /etc/ssl/dhparams
    
    log_step "6" "10" "Generating DH parameters (this may take a while)"
    
    # Generate DH parameters for better security
    if [[ ! -f /etc/ssl/dhparams/dhparam.pem ]]; then
        log_info "Generating 2048-bit DH parameters..."
        openssl dhparam -out /etc/ssl/dhparams/dhparam.pem 2048
        chmod 644 /etc/ssl/dhparams/dhparam.pem
        log_success "DH parameters generated"
    else
        log_info "DH parameters already exist"
    fi
    
    log_step "7" "10" "Creating self-signed certificate for testing"
    
    # Create self-signed certificate for immediate testing
    if [[ ! -f /etc/ssl/certs/selfsigned.crt ]]; then
        log_info "Creating self-signed certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/selfsigned.key \
            -out /etc/ssl/certs/selfsigned.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/OU=IT Department/CN=localhost"
        
        chmod 644 /etc/ssl/certs/selfsigned.crt
        chmod 600 /etc/ssl/private/selfsigned.key
        log_success "Self-signed certificate created"
    else
        log_info "Self-signed certificate already exists"
    fi
    
    log_step "8" "10" "Setting up Certbot auto-renewal"
    
    # Set up Certbot auto-renewal
    if command_exists crontab; then
        # Check if renewal job already exists
        if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
            (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
            log_success "Certbot auto-renewal scheduled (daily at noon)"
        else
            log_info "Certbot auto-renewal already scheduled"
        fi
    fi
    
    # Create systemd timer for auto-renewal (modern approach)
    if command_exists systemctl; then
        cat > /etc/systemd/system/certbot-renew.service << 'EOF'
[Unit]
Description=Certbot Renewal
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet
EOF
        
        cat > /etc/systemd/system/certbot-renew.timer << 'EOF'
[Unit]
Description=Run certbot renewal twice daily
Requires=certbot-renew.service

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF
        
        systemctl daemon-reload
        systemctl enable certbot-renew.timer
        systemctl start certbot-renew.timer
        log_success "Certbot systemd timer configured"
    fi
    
    log_step "9" "10" "Configuring Apache SSL"
    
    # Enable SSL module in Apache if available
    if command_exists a2enmod; then
        a2enmod ssl
        a2enmod headers
        
        # Create SSL virtual host
        cat > /etc/apache2/sites-available/default-ssl.conf << 'EOF'
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        
        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/selfsigned.crt
        SSLCertificateKeyFile /etc/ssl/private/selfsigned.key
        
        # Modern SSL configuration
        SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
        SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
        SSLHonorCipherOrder off
        SSLSessionTickets off
        
        # Security headers
        Header always set X-Content-Type-Options nosniff
        Header always set X-Frame-Options DENY
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
        
        # DH parameters
        SSLOpenSSLConfCmd DHParameters "/etc/ssl/dhparams/dhparam.pem"
        
        <FilesMatch "\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>
    </VirtualHost>
</IfModule>
EOF
        
        # Enable SSL site
        a2ensite default-ssl
        systemctl reload apache2
        log_success "Apache SSL configuration created"
    fi
    
    log_step "10" "10" "Creating SSL management scripts"
    
    # Create SSL certificate management script
    cat > /usr/local/bin/ssl-manager << 'EOF'
#!/bin/bash
# SSL Certificate Management Script

case "$1" in
    "get")
        if [[ -z "$2" ]]; then
            echo "Usage: ssl-manager get <domain>"
            exit 1
        fi
        
        domain="$2"
        echo "Getting SSL certificate for $domain..."
        
        # Detect web server
        if systemctl is-active --quiet apache2; then
            certbot --apache -d "$domain"
        elif systemctl is-active --quiet nginx; then
            certbot --nginx -d "$domain"
        else
            certbot certonly --standalone -d "$domain"
        fi
        ;;
    "renew")
        echo "Renewing SSL certificates..."
        certbot renew
        ;;
    "list")
        echo "SSL certificates:"
        certbot certificates
        ;;
    "test")
        echo "Testing SSL certificate renewal..."
        certbot renew --dry-run
        ;;
    *)
        echo "SSL Certificate Manager"
        echo "Usage: ssl-manager {get|renew|list|test}"
        echo ""
        echo "Commands:"
        echo "  get <domain>  - Get SSL certificate for domain"
        echo "  renew         - Renew all certificates"
        echo "  list          - List all certificates"
        echo "  test          - Test renewal process"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/ssl-manager
    
    log_success "SSL module installation completed"
    log_info "Certbot: Ready for Let's Encrypt certificates"
    log_info "OpenSSL: Installed with DH parameters generated"
    log_info "Self-signed certificate: /etc/ssl/certs/selfsigned.crt"
    log_info "SSL management: /usr/local/bin/ssl-manager"
    log_info "Get real certificate: ssl-manager get yourdomain.com"
    log_info "Test renewal: ssl-manager test"
}
