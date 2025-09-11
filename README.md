# Linux Server Setup Scripts 🚀

Comprehensive automation for deploying and configuring Linux servers with:

- **Web servers** (Nginx/Apache)
- **Databases** (MySQL/PostgreSQL)
- **DNS servers** (BIND9)

## 🌟 Features

### 🌐 Web Server (Nginx/Apache)
- PHP, Node.js (Express), and static HTML support
- Let's Encrypt SSL integration
- Multiple sites (vhosts) with subdomains
- PM2 process management for Node.js
- Reverse proxy configuration
- Full validation and testing

### 🗄️ Database Server
- MySQL/MariaDB and PostgreSQL support
- Secure installation and configuration
- Database and user management
- Automated backups
- Replication support
- Performance optimization

### 🔀 DNS Server (BIND9)
- Forward & reverse zones (IPv4/IPv6)
- DNSSEC with inline-signing
- Zone transfers with TSIG
- Split-horizon (views) with ACLs
- Response Rate Limiting (RRL)
- Dynamic updates support

## 📦 Installation

1. Clone the repository:
```bash
git clone https://github.com/anshulyadav32/LS.git
cd LS
```

2. Run the master deployment script:
```bash
sudo bash deploy-master.sh
```

## 🚀 Quick Start

### Web Server Deployment
```bash
cd modular-cript
sudo bash deploy-web.sh
```

### Database Deployment
```bash
cd modular-cript
sudo bash deploy-db.sh
```

### DNS Server Deployment
```bash
cd modular-cript
sudo bash deploy-dns.sh
```

## 📁 Project Structure

```
modular-cript/
├── deploy-master.sh    # Main deployment menu
├── deploy-web.sh      # Web server deployment
├── deploy-db.sh       # Database deployment
├── deploy-dns.sh      # DNS server deployment
└── modules/           # Core functionality
    ├── common.sh     # Shared utilities
    ├── web.sh        # Web server module
    ├── db.sh         # Database module
    └── dns.sh        # DNS server module

src/
├── modules/          # Core modules
│   ├── backup.sh    # Backup operations
│   ├── database.sh  # Database operations
│   ├── dns.sh       # DNS configuration
│   ├── firewall.sh  # Firewall management
│   ├── node.sh      # Node.js setup
│   ├── ssl.sh       # SSL/TLS management
│   └── webserver.sh # Web server config
├── scripts/         # Main scripts
│   ├── setup.sh     # Initial setup
│   └── update.sh    # System updates
└── utils/          # Utility functions
    └── utils.sh    # Core utilities
```

## 🛠️ Core Utilities

Our `utils.sh` provides comprehensive utility functions for all deployment needs:

### 📝 Logging & Output
- Color-coded logging functions (`info`, `ok`, `warn`, `error`)
- Progress indicators for long-running tasks
- Step-by-step operation tracking

### 🔧 System Management
- Package management helpers (`apt_update`, `apt_install`)
- Service management (`restart_service`, `enable_service`)
- System monitoring (`check_memory`, `check_disk_space`)
- Process management with user context support

### 🚀 Deployment Tools
- Environment file management (`deploy_env_file`, `load_env`)
- Service deployment (`deploy_systemd_service`, `deploy_nginx_config`)
- Application deployment (`deploy_app`, `wait_for_port`)
- Database operations (`create_db`, `create_db_user`, `grant_db_privileges`)

### 🔒 Security
- SSL/TLS setup (`setup_ssl`, `check_ssl_cert`)
- Secure key generation (`generate_secure_key`)
- File permission management
- Backup utilities (`backup_file`)

### ⚙️ Configuration
- Configuration merging (`merge_config`)
- Environment validation
- Domain and email validation
- Interactive prompts (`prompt_yes_no`, `get_password`)

### 📊 Monitoring
- Port availability checking
- Service health monitoring
- Resource usage tracking
- Log management

## � Usage Examples

### Logging and Progress Tracking
```bash
# Import utilities
source ./src/utils/utils.sh

# Use logging functions
info "Starting deployment..."
warn "Low disk space detected"
error "Failed to connect to database"
ok "Deployment completed successfully"

# Show progress for long operations
(long_running_command) & show_progress "Installing packages" $!
```

### System Management
```bash
# Package installation
apt_update
apt_install nginx mysql-server nodejs

# Service management
restart_service nginx
enable_service mysql

# System checks
check_memory 1024  # Ensure at least 1GB RAM available
check_disk_space /var/www 10  # Ensure 10GB free space
```

### Deployment Operations
```bash
# Deploy a Node.js application
deploy_app ./app /var/www/myapp www-data
deploy_env_file .env.prod /var/www/myapp/.env

# Configure web server
deploy_nginx_config myapp /path/to/nginx.conf
setup_ssl example.com admin@example.com

# Database setup
create_db myapp_db
create_db_user myapp_user "secure_password"
grant_db_privileges myapp_db myapp_user
```

### Configuration Management
```bash
# Load environment variables
load_env .env.production

# Merge configurations
merge_config base.json prod.json output.json

# Validate inputs
validate_domain "example.com"
validate_email "admin@example.com"

# Interactive configuration
if prompt_yes_no "Configure SSL?"; then
    setup_ssl "example.com" "admin@example.com"
fi
```

## 🌟 Best Practices

### Security
1. Always use `backup_file` before modifying critical files
2. Use `generate_secure_key` for creating secure tokens/keys
3. Set proper file permissions with deployment functions
4. Enable SSL/TLS by default for web services

### Deployment
1. Check system resources before deployment
2. Use proper service accounts for running applications
3. Implement proper logging for all operations
4. Always validate configuration before applying

### Monitoring
1. Regularly check system resources
2. Monitor service health
3. Implement proper logging
4. Set up automated backups

### Development
1. Use the provided logging functions consistently
2. Implement proper error handling
3. Follow the modular structure
4. Document new functions and modules

## �📋 Configuration

Each deployment script is interactive and will guide you through the setup process with sensible defaults and comprehensive options.

## 📝 License

MIT License - feel free to use and modify as needed!

## 🤝 Contributing

Pull requests are welcome! Feel free to contribute by:
1. Forking the repository
2. Creating a feature branch
3. Making your changes
4. Opening a pull request

## 📬 Support

- Create an issue for bug reports
- Start a discussion for feature requests
- Check the wiki for detailed documentation

## 🔐 Security

- All passwords are generated securely
- SSL/TLS enabled by default
- Regular security updates
- Best practices followed

## 🔄 Updates

Subscribe to releases to get notified about:
- New features
- Security updates
- Bug fixes
- Performance improvements