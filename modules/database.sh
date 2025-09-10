#!/bin/bash
# =============================================================================
# Database Module Installation (MySQL/MariaDB + PostgreSQL)
# =============================================================================

install_database_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing Database Module (MySQL/MariaDB + PostgreSQL)"
    
    # Check disk space (2GB minimum for databases)
    check_disk_space 2147483648 || return 1
    
    log_step "3" "10" "Installing MySQL/MariaDB"
    
    local mysql_packages=""
    case "$pkg_mgr" in
        "apt")
            mysql_packages="mariadb-server mariadb-client mariadb-backup"
            install_packages "$pkg_mgr" $mysql_packages
            
            systemctl enable mariadb
            systemctl start mariadb
            wait_for_service mariadb
            
            # Secure MySQL installation (automated)
            log_info "Securing MariaDB installation..."
            mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
            mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
            mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
            mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null || true
            mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
            ;;
        "dnf"|"yum")
            mysql_packages="mariadb-server mariadb"
            install_packages "$pkg_mgr" $mysql_packages
            
            systemctl enable mariadb
            systemctl start mariadb
            wait_for_service mariadb
            ;;
        "pacman")
            mysql_packages="mariadb"
            install_packages "$pkg_mgr" $mysql_packages
            
            # Initialize MySQL data directory
            mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            systemctl enable mariadb
            systemctl start mariadb
            wait_for_service mariadb
            ;;
        *)
            log_error "Unsupported package manager for MySQL installation"
            return 1
            ;;
    esac
    
    log_step "4" "10" "Installing PostgreSQL"
    
    local postgres_packages=""
    case "$pkg_mgr" in
        "apt")
            postgres_packages="postgresql postgresql-contrib postgresql-client"
            install_packages "$pkg_mgr" $postgres_packages
            
            systemctl enable postgresql
            systemctl start postgresql
            wait_for_service postgresql
            ;;
        "dnf"|"yum")
            postgres_packages="postgresql-server postgresql-contrib"
            install_packages "$pkg_mgr" $postgres_packages
            
            # Initialize PostgreSQL database
            postgresql-setup --initdb 2>/dev/null || postgresql-setup initdb
            systemctl enable postgresql
            systemctl start postgresql
            wait_for_service postgresql
            ;;
        "pacman")
            postgres_packages="postgresql postgresql-libs"
            install_packages "$pkg_mgr" $postgres_packages
            
            # Initialize PostgreSQL database
            sudo -u postgres initdb -D /var/lib/postgres/data
            systemctl enable postgresql
            systemctl start postgresql
            wait_for_service postgresql
            ;;
        *)
            log_error "Unsupported package manager for PostgreSQL installation"
            return 1
            ;;
    esac
    
    log_step "5" "10" "Installing database management tools"
    
    case "$pkg_mgr" in
        "apt")
            # Install phpMyAdmin with non-interactive configuration
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/app-password-confirm password admin" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/admin-pass password" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/app-pass password admin" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
            
            install_packages "$pkg_mgr" phpmyadmin mysql-utilities
            ;;
        "dnf"|"yum")
            install_packages "$pkg_mgr" phpmyadmin || log_warning "phpMyAdmin not available in default repositories"
            ;;
        "pacman")
            install_packages "$pkg_mgr" phpmyadmin || log_warning "phpMyAdmin installation may require AUR"
            ;;
    esac
    
    log_step "6" "10" "Configuring database security"
    
    # Set up basic PostgreSQL security
    if command_exists psql; then
        log_info "Configuring PostgreSQL security..."
        
        # Create a basic database for testing
        sudo -u postgres createdb testdb 2>/dev/null || true
        
        # Update PostgreSQL configuration for better security
        local pg_version=$(sudo -u postgres psql -t -c "SELECT version();" | grep -oP '\d+\.\d+' | head -1)
        local pg_config_dir="/etc/postgresql/${pg_version}/main"
        
        if [[ -d "$pg_config_dir" ]]; then
            # Enable logging
            sed -i "s/#log_line_prefix = .*/log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '/" "$pg_config_dir/postgresql.conf" 2>/dev/null || true
            
            # Restart PostgreSQL to apply changes
            systemctl restart postgresql
        fi
    fi
    
    # Set up MySQL security enhancements
    if command_exists mysql; then
        log_info "Configuring MySQL security enhancements..."
        
        # Create MySQL configuration for better security
        cat > /etc/mysql/mysql.conf.d/security.cnf << 'EOF'
[mysqld]
# Security configurations
local-infile=0
skip-show-database
safe-user-create=1

# Performance and logging
slow_query_log=1
slow_query_log_file=/var/log/mysql/mysql-slow.log
long_query_time=2

# Connection limits
max_connections=100
max_user_connections=50
EOF
        
        # Restart MySQL to apply changes
        systemctl restart mariadb
    fi
    
    log_step "7" "10" "Creating database backup scripts"
    
    # Create MySQL backup script
    cat > /usr/local/bin/mysql-backup << 'EOF'
#!/bin/bash
# MySQL/MariaDB Backup Script
BACKUP_DIR="/root/backups/database"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_USER="root"
MYSQL_PASS=""

mkdir -p "$BACKUP_DIR"

# Backup all databases
mysqldump --user="$MYSQL_USER" --password="$MYSQL_PASS" \
    --all-databases --single-transaction --routines --triggers \
    --lock-tables=false > "$BACKUP_DIR/mysql_all_$DATE.sql"

# Compress backup
gzip "$BACKUP_DIR/mysql_all_$DATE.sql"

# Remove backups older than 7 days
find "$BACKUP_DIR" -name "mysql_all_*.sql.gz" -mtime +7 -delete

echo "MySQL backup completed: mysql_all_$DATE.sql.gz"
EOF
    
    chmod +x /usr/local/bin/mysql-backup
    
    # Create PostgreSQL backup script
    cat > /usr/local/bin/postgres-backup << 'EOF'
#!/bin/bash
# PostgreSQL Backup Script
BACKUP_DIR="/root/backups/database"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup all databases
sudo -u postgres pg_dumpall > "$BACKUP_DIR/postgres_all_$DATE.sql"

# Compress backup
gzip "$BACKUP_DIR/postgres_all_$DATE.sql"

# Remove backups older than 7 days
find "$BACKUP_DIR" -name "postgres_all_*.sql.gz" -mtime +7 -delete

echo "PostgreSQL backup completed: postgres_all_$DATE.sql.gz"
EOF
    
    chmod +x /usr/local/bin/postgres-backup
    
    log_success "Database module installation completed"
    log_info "MariaDB and PostgreSQL are running and enabled"
    log_info "Default PostgreSQL user: postgres"
    log_info "phpMyAdmin available at: http://your-server/phpmyadmin"
    log_info "Backup scripts: /usr/local/bin/mysql-backup, /usr/local/bin/postgres-backup"
    log_warning "Configure passwords with: sudo mysql_secure_installation"
}
