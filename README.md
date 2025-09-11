# Linux Setup Scripts 🚀

A comprehensive collection of modular bash scripts for setting up and configuring Linux development environments.

## 📁 Project Structure

```
LinuxSetup/
├── src/                    # Source code
│   ├── modules/            # Individual setup modules
│   │   ├── backup.sh      # Backup module
│   │   ├── database.sh    # Database module
│   │   ├── devenv.sh      # Development environment
│   │   ├── dns.sh         # DNS server module
│   │   ├── firewall.sh    # Firewall module
│   │   ├── node.sh        # Node.js module
│   │   ├── ssl.sh         # SSL/TLS module
│   │   └── webserver.sh   # Web server module
│   ├── scripts/           # Main scripts
│   │   ├── setup.sh       # Main setup script
│   │   ├── check-setup.sh # Setup verification
│   │   └── update-all.sh  # Update script
│   └── utils/             # Utility functions
│       └── utils.sh       # Common utilities
├── config/                # Configuration files
│   ├── dev.env           # Development environment
│   └── prod.env          # Production environment
├── tests/                # Test suite
│   ├── test_helper.sh    # Testing utilities
│   └── *_test.sh        # Module tests
└── docs/                 # Documentation
    └── index.html        # Documentation website

## 🌟 Features

- **Modular Design**: Each component is a separate module for flexible installation
- **Multi-Distribution Support**: Works on Debian/Ubuntu, RHEL/Fedora, and Arch Linux
- **Comprehensive Testing**: Built-in testing for each module
- **Easy to Extend**: Simple structure for adding new modules

## 📦 Available Modules

- **Development Environment** (`devenv`): Complete development setup
  - Git & GitHub CLI
  - Node.js & Python
  - Docker & Docker Compose
  - Popular dev tools and package managers
  
- **Web Server** (`webserver`): Apache + Nginx + PHP
  - Multi-server setup
  - PHP-FPM configuration
  - Server testing and validation

- **Database** (`database`): MySQL/MariaDB + PostgreSQL
  - Automatic service configuration
  - Security best practices
  - Database testing tools

- **DNS Server** (`dns`): BIND9/dnsmasq
  - DNS server configuration
  - DNS utilities
  - Testing tools

- **SSL/TLS** (`ssl`): Certbot/Let's Encrypt
  - Automatic certificate management
  - Support for Apache and Nginx
  - SSL testing and validation

- **Firewall** (`firewall`): UFW/Firewalld
  - Basic security rules
  - Service-specific configurations
  - Firewall status monitoring

- **Backup** (`backup`): rsync + tar + rclone
  - Automated backup setup
  - Multiple backup strategies
  - Backup testing and verification

## 🚀 Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/anshulyadav32/LinuxSetup.git
   cd LinuxSetup
   ```

2. Make scripts executable:
   ```bash
   chmod +x setup.sh modules/*.sh utils.sh
   ```

3. Run the setup:
   ```bash
   # Install everything
   ./setup.sh all
   
   # Install specific module
   ./setup.sh [module-name]
   
   # Test installations
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
