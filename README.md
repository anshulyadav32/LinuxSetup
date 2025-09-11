# Linux Server Setup Scripts 🚀

A collection of modular scripts for setting up and managing Linux servers, with support for web applications, databases, SSL, and more.

## 📁 Project Structure

```bash
.
├── src/                    # Source code
│   ├── modules/           # Linux setup modules
│   │   ├── backup.sh     # Backup system setup
│   │   ├── database.sh   # Database server setup
│   │   ├── devenv.sh     # Development tools setup
│   │   ├── dns.sh        # DNS server setup
│   │   ├── firewall.sh   # Firewall configuration
│   │   ├── node.sh       # Node.js environment
│   │   ├── ssl.sh        # SSL/TLS management
│   │   └── webserver.sh  # Web server setup
│   ├── scripts/          # Main bash scripts
│   │   ├── setup.sh      # Main setup script
│   │   ├── check-setup.sh # Verification script
│   │   └── update-all.sh # System update script
│   └── utils/            # Bash utilities
│       └── utils.sh      # Common shell functions
├── config/               # Environment configs
│   ├── dev.env          # Development settings
│   └── prod.env         # Production settings
├── tests/               # Bash test suite
│   └── test_helper.sh   # Test utilities
└── modular-cript/       # Modular deployment scripts
    ├── .env             # Environment configuration
    ├── deploy.sh        # Main deployment script
    ├── deploy-db.sh     # Database deployment script
    └── modules/         # Modular components
        ├── common.sh    # Shared utilities
        ├── nginx.sh     # Nginx configuration
        ├── node.sh      # Node.js setup and PM2
        ├── php.sh       # PHP-FPM setup
        ├── db.sh        # Database functions
        ├── ssl.sh       # SSL/HTTPS setup
        └── summary.sh   # Deployment summary

## 🌟 Features

### General Features
- ✨ **Interactive Setup**: User-friendly prompts with smart defaults
- 🔄 **Persistent Configuration**: Save settings for reproducible deployments
- 📦 **Modular Design**: Each component is a separate module for flexible installation
- 🔧 **Easy to Extend**: Simple structure for adding new modules

### Web Application Deployment (`modular-cript/`)
- 🌐 **Web Server Support**:
  - Nginx configuration with virtual hosts
  - PHP-FPM integration
  - Node.js with PM2 process management
- 🔒 **SSL/HTTPS**:
  - Automatic certificate generation via Let's Encrypt
  - HTTPS redirection and HSTS
  - OCSP stapling for better performance
- 📊 **Database Management**:
  - MySQL/MariaDB support
  - PostgreSQL support
  - Automated backups
  - Remote access configuration
- 🛡️ **Security**:
  - Secure default configurations
  - Automatic password generation
  - Proper file permissions

### System Setup (`src/`)
- 🔧 **Development Environment**:
  - Git & GitHub CLI
  - Node.js & Python
  - Docker & Docker Compose
- 🌐 **Server Components**:
  - DNS server (BIND9/dnsmasq)
  - Firewall (UFW/Firewalld)
  - Backup system (rsync/tar)

## 🚀 Quick Start

### Web Application Deployment

1. Deploy a website with PHP and Node.js:
   ```bash
   cd modular-cript
   sudo bash deploy.sh
   ```
   This will:
   - Set up Nginx web server
   - Configure PHP-FPM
   - Install Node.js and PM2
   - Set up SSL certificates (optional)

2. Set up a database:
   ```bash
   cd modular-cript
   sudo bash deploy-db.sh
   ```
   This will:
   - Install chosen database (MySQL/MariaDB or PostgreSQL)
   - Create database and user
   - Configure remote access (optional)
   - Set up automated backups

### System Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/anshulyadav32/LinuxSetup.git
   cd LinuxSetup
   ```

2. Install specific components:
   ```bash
   cd src/scripts
   sudo bash setup.sh [component-name]
   ```
   Available components: devenv, webserver, database, dns, ssl, firewall, backup

## 📝 Configuration

### Web Application Environment

Create a `.env` file in the `modular-cript` directory:
```bash
# Domain & paths
DOMAIN="example.com"
WEBROOT="/var/www/${DOMAIN}"

# Node
NODE_PORT=3000
PM2_APP="${DOMAIN}-node"

# Nginx
NGINX_SITE="/etc/nginx/sites-available/${DOMAIN}"
```

All settings can be overridden during deployment via interactive prompts.

## 🔧 Maintenance

### Service Management
```bash
# Nginx
sudo systemctl status nginx
sudo systemctl restart nginx

# PHP-FPM
sudo systemctl status php*-fpm
sudo systemctl restart php*-fpm

# Database (MySQL/MariaDB)
sudo systemctl status mariadb
sudo systemctl restart mariadb

# Database (PostgreSQL)
sudo systemctl status postgresql
sudo systemctl restart postgresql
```

### PM2 Commands
```bash
# Check status
sudo -u www-data PM2_HOME="/var/www/example.com/nodeapp/.pm2" pm2 status

# View logs
sudo -u www-data PM2_HOME="/var/www/example.com/nodeapp/.pm2" pm2 logs
```

## 📝 License

MIT License. See [LICENSE](LICENSE) file for details.
   ./setup.sh test
   ```

## 📋 Requirements

- Bash shell
- Root/sudo access
- Internet connection for package installation
- One of the supported distributions:
  - Debian/Ubuntu
  - RHEL/Fedora
  - Arch Linux

## 🛠 Module Details

### Development Environment (devenv)
- Full development environment setup
- Installs and configures:
  - Git & GitHub CLI
  - Node.js (LTS) with npm/yarn
  - Python 3 with pip/virtualenv
  - Docker & Docker Compose
  - Build tools (gcc, g++, make)
  - Code editors and utilities

### Web Server
- Apache and Nginx setup
- PHP-FPM configuration
- Virtual host management
- HTTP/2 support
- Performance optimization

### Database
- MySQL/MariaDB setup
- PostgreSQL configuration
- Security hardening
- Backup configuration
- Performance tuning

### DNS Server
- BIND9/dnsmasq installation
- Zone configuration
- DNS security setup
- Testing tools

### SSL/TLS
- Let's Encrypt integration
- Auto-renewal setup
- Multi-domain support
- SSL testing tools

### Firewall
- UFW/Firewalld setup
- Basic security rules
- Service configurations
- Status monitoring

### Backup
- Automated backup setup
- Multiple backup strategies
- Backup verification
- Restore testing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📜 License

MIT License - feel free to use and modify for your needs

## 💬 Support

For issues and support:
- Create an issue in the GitHub repository
- Send a pull request with your improvements
- Contact the maintainer

---
Made with ❤️ by [Anshul Yadav](https://github.com/anshulyadav32)
