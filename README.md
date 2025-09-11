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

## 📋 Configuration

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