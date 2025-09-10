#!/bin/bash
# =============================================================================
# Webserver Module Installation (Apache + Nginx + PHP)
# =============================================================================

install_webserver_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Webserver Module (Apache + Nginx + PHP)"
    
    # Check disk space (1GB minimum for web server)
    check_disk_space 1073741824 || return 1
    
    log_step "3" "10" "Installing Apache HTTP Server"
    
    local apache_packages=""
    case "$pkg_mgr" in
        "apt")
            apache_packages="apache2 apache2-utils"
            install_packages "$pkg_mgr" $apache_packages
            
            systemctl enable apache2
            systemctl start apache2
            wait_for_service apache2
            
            # Enable common Apache modules
            a2enmod rewrite ssl headers expires deflate
            ;;
        "dnf"|"yum")
            apache_packages="httpd httpd-tools"
            install_packages "$pkg_mgr" $apache_packages
            
            systemctl enable httpd
            systemctl start httpd
            wait_for_service httpd
            ;;
        "pacman")
            apache_packages="apache"
            install_packages "$pkg_mgr" $apache_packages
            
            systemctl enable httpd
            systemctl start httpd
            wait_for_service httpd
            ;;
        *)
            log_error "Unsupported package manager for Apache installation"
            return 1
            ;;
    esac
    
    log_step "4" "10" "Installing Nginx"
    
    local nginx_packages=""
    case "$pkg_mgr" in
        "apt")
            nginx_packages="nginx nginx-extras"
            install_packages "$pkg_mgr" $nginx_packages
            
            systemctl enable nginx
            # Don't start nginx yet (port conflict with Apache)
            log_info "Nginx installed but not started (port conflict with Apache)"
            ;;
        "dnf"|"yum")
            nginx_packages="nginx"
            install_packages "$pkg_mgr" $nginx_packages
            
            systemctl enable nginx
            ;;
        "pacman")
            nginx_packages="nginx"
            install_packages "$pkg_mgr" $nginx_packages
            
            systemctl enable nginx
            ;;
        *)
            log_error "Unsupported package manager for Nginx installation"
            return 1
            ;;
    esac
    
    log_step "5" "10" "Installing PHP and extensions"
    
    local php_packages=""
    case "$pkg_mgr" in
        "apt")
            # Install PHP 8.3 with common extensions
            php_packages="php8.3 php8.3-fpm php8.3-mysql php8.3-pgsql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip php8.3-intl php8.3-bcmath php8.3-json php8.3-opcache php8.3-cli php8.3-common libapache2-mod-php8.3"
            
            # Add PHP repository if needed
            if ! is_package_installed "$pkg_mgr" "php8.3"; then
                add_repository "$os_type" "$pkg_mgr" "ppa:ondrej/php"
            fi
            
            install_packages "$pkg_mgr" $php_packages
            
            # Enable PHP-FPM
            systemctl enable php8.3-fpm
            systemctl start php8.3-fpm
            wait_for_service php8.3-fpm
            
            # Configure Apache for PHP
            a2enmod php8.3
            ;;
        "dnf"|"yum")
            php_packages="php php-fpm php-mysqlnd php-pgsql php-curl php-gd php-mbstring php-xml php-zip php-intl php-bcmath php-json php-opcache php-cli"
            install_packages "$pkg_mgr" $php_packages
            
            systemctl enable php-fpm
            systemctl start php-fpm
            wait_for_service php-fpm
            ;;
        "pacman")
            php_packages="php php-fpm php-apache php-gd php-intl php-pgsql"
            install_packages "$pkg_mgr" $php_packages
            
            systemctl enable php-fpm
            systemctl start php-fpm
            wait_for_service php-fpm
            ;;
        *)
            log_error "Unsupported package manager for PHP installation"
            return 1
            ;;
    esac
    
    log_step "6" "10" "Configuring web servers"
    
    # Create web root directory
    mkdir -p /var/www/html
    
    # Set proper ownership
    if id "www-data" >/dev/null 2>&1; then
        chown -R www-data:www-data /var/www/html
    elif id "apache" >/dev/null 2>&1; then
        chown -R apache:apache /var/www/html
    elif id "http" >/dev/null 2>&1; then
        chown -R http:http /var/www/html
    fi
    
    # Set proper permissions
    chmod -R 755 /var/www/html
    
    log_step "7" "10" "Creating sample web pages"
    
    # Create PHP info page
    cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF
    
    # Create simple index page
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Linux Setup</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        .header { 
            color: #2c3e50; 
            text-align: center;
            margin-bottom: 30px;
        }
        .success { 
            color: #27ae60; 
            font-size: 1.2em;
            text-align: center;
            margin: 20px 0;
        }
        .info-box {
            background: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .links {
            display: flex;
            gap: 20px;
            justify-content: center;
            flex-wrap: wrap;
            margin-top: 30px;
        }
        .link-button {
            background: #007bff;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .link-button:hover {
            background: #0056b3;
        }
        ul { 
            list-style-type: none;
            padding: 0;
        }
        li {
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        li:last-child {
            border-bottom: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🚀 Linux Setup - Webserver Module</h1>
        <p class="success">✅ Apache and PHP are successfully installed!</p>
        
        <div class="info-box">
            <h3>Server Information:</h3>
            <ul>
                <li><strong>Apache HTTP Server:</strong> Running</li>
                <li><strong>PHP:</strong> Installed and configured</li>
                <li><strong>Document Root:</strong> /var/www/html</li>
                <li><strong>Server Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></li>
            </ul>
        </div>
        
        <div class="links">
            <a href="info.php" class="link-button">View PHP Information</a>
            <a href="#" class="link-button" onclick="alert('Upload your website files to /var/www/html/')">Upload Files</a>
        </div>
        
        <div class="info-box">
            <h3>Next Steps:</h3>
            <ul>
                <li>Upload your website files to <code>/var/www/html/</code></li>
                <li>Configure virtual hosts in Apache</li>
                <li>Install SSL certificates for HTTPS</li>
                <li>Set up database connections</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF
    
    log_step "8" "10" "Configuring Apache virtual host"
    
    # Create a basic virtual host configuration
    local apache_sites_dir="/etc/apache2/sites-available"
    if [[ ! -d "$apache_sites_dir" ]]; then
        apache_sites_dir="/etc/httpd/conf.d"
    fi
    
    if [[ -d "$apache_sites_dir" ]]; then
        cat > "$apache_sites_dir/000-default.conf" << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
        
        # Enable the site (Debian/Ubuntu)
        if command_exists a2ensite; then
            a2ensite 000-default
        fi
    fi
    
    log_step "9" "10" "Configuring PHP settings"
    
    # Find PHP configuration file
    local php_ini=""
    for version in 8.3 8.2 8.1 8.0; do
        if [[ -f "/etc/php/${version}/apache2/php.ini" ]]; then
            php_ini="/etc/php/${version}/apache2/php.ini"
            break
        elif [[ -f "/etc/php/${version}/fpm/php.ini" ]]; then
            php_ini="/etc/php/${version}/fpm/php.ini"
            break
        fi
    done
    
    # Fallback to common locations
    if [[ -z "$php_ini" ]]; then
        for ini in /etc/php.ini /etc/php/php.ini /usr/local/etc/php/php.ini; do
            if [[ -f "$ini" ]]; then
                php_ini="$ini"
                break
            fi
        done
    fi
    
    if [[ -n "$php_ini" ]]; then
        log_info "Configuring PHP settings in $php_ini"
        
        # Create backup
        cp "$php_ini" "${php_ini}.backup"
        
        # Update PHP settings for better performance and security
        sed -i 's/upload_max_filesize = .*/upload_max_filesize = 100M/' "$php_ini"
        sed -i 's/post_max_size = .*/post_max_size = 100M/' "$php_ini"
        sed -i 's/memory_limit = .*/memory_limit = 256M/' "$php_ini"
        sed -i 's/max_execution_time = .*/max_execution_time = 300/' "$php_ini"
        sed -i 's/expose_php = .*/expose_php = Off/' "$php_ini"
        
        # Enable OPcache for better performance
        if ! grep -q "opcache.enable=1" "$php_ini"; then
            cat >> "$php_ini" << 'EOF'

; OPcache configuration
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=4000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF
        fi
    fi
    
    # Restart services to apply configurations
    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null
    systemctl restart php8.3-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null
    
    log_success "Webserver module installation completed"
    log_info "Apache is running on port 80"
    log_info "Nginx is installed but not started (use port 8080 if needed)"
    log_info "PHP-FPM is running and configured"
    log_info "Test page: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')/"
    log_info "PHP info: http://$(curl -s ifconfig.me 2>/dev/null || echo 'your-server-ip')/info.php"
}
