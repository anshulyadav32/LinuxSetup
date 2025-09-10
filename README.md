# LinuxSetup

A modular collection of shell scripts for automated Linux system setup and configuration. This repository provides a flexible and organized approach to installing and configuring various services and components on Linux systems.

## 🚀 Features

- **Modular Architecture**: Organized into reusable modules for different services
- **Comprehensive Logging**: Built-in logging system with color-coded output
- **Package Management**: Automatic package installation and dependency handling
- **Service Configuration**: Automated setup for web servers, databases, DNS, SSL, and more
- **Demo Scripts**: Ready-to-use demonstration setups

## 📁 Project Structure

```
├── setup.sh              # Main setup script
├── setup-modular.sh      # Modular setup script
├── demo.sh               # Basic demo script
├── demo-modular.sh       # Modular demo script
├── lib/                  # Core library functions
│   ├── colors.sh         # Color definitions for output
│   ├── logging.sh        # Logging utilities
│   ├── package.sh        # Package management functions
│   └── system.sh         # System utilities
├── modules/              # Service-specific modules
│   ├── database.sh       # Database setup (MySQL, PostgreSQL, etc.)
│   ├── dns.sh            # DNS configuration
│   ├── firewall.sh       # Firewall setup and rules
│   ├── ssl.sh            # SSL certificate management
│   └── webserver.sh      # Web server configuration (Apache, Nginx)
└── website/              # Documentation website
```

## 🛠️ Usage

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/anshulyadav32/LinuxSetup.git
   cd LinuxSetup
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   chmod +x modules/*.sh
   ```

3. **Install everything (complete server):**
   ```bash
   sudo ./setup.sh all
   ```

4. **Or install specific modules:**
   ```bash
   sudo ./setup.sh webserver    # Web server only
   sudo ./setup.sh database     # Database only
   ```

### Quick Module Access

Use the master.sh script for easy module management:

```bash
./master.sh --module ssl        # Install SSL module
./master.sh --module extra      # Install mail server
./master.sh --status            # Show system status
./master.sh --list              # List available modules
```

### Demo Mode

To see the scripts in action without making system changes:

```bash
./demo.sh          # Basic demo
./demo-modular.sh  # Modular demo
```

## 📋 Available Modules

- **🗄️ Database**: MySQL, PostgreSQL setup and configuration
- **🖥️ Web Server**: Apache, Nginx, PHP installation and configuration
- **🌐 DNS**: BIND9, dnsmasq DNS server configuration
- **🔥 Firewall**: UFW, Fail2Ban, iptables security setup
- **🔒 SSL**: Certbot, OpenSSL, Let's Encrypt integration
- **📧 Extra**: Mail server (Postfix, Dovecot, SpamAssassin, ClamAV)
- **💾 Backup**: Automated backup system with cloud integration
- **� All**: Complete server setup (installs ALL modules)

## 🔧 Configuration

Each module can be configured independently. Check the individual module files in the `modules/` directory for specific configuration options.

### Available Commands

```bash
# Complete server installation
sudo ./setup.sh all

# Individual modules
sudo ./setup.sh database
sudo ./setup.sh webserver
sudo ./setup.sh dns
sudo ./setup.sh firewall
sudo ./setup.sh ssl
sudo ./setup.sh extra        # Mail server
sudo ./setup.sh backup

# Quick access with master.sh
./master.sh --module <module>
./master.sh --status
./master.sh --list
./master.sh --help

# Help and information
./setup.sh --help
./setup.sh --list
```

## � System Monitoring

Monitor your server status with the built-in status command:

```bash
./master.sh --status
```

This provides:
- **Service Status**: Apache, Nginx, MySQL, PostgreSQL, DNS, Mail services
- **SSL Certificate Info**: Installed certificates and expiration
- **System Resources**: Disk space, memory usage
- **Security Status**: Firewall and security service status

## �📚 Documentation

- [Module Documentation](website/docs/)
- [Configuration Guide](website/docs/)  
- [Troubleshooting](website/docs/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

These scripts make system-level changes. Always test in a virtual machine or non-production environment first. Review the code before running on production systems.

## 🐛 Issues

If you encounter any issues or have suggestions for improvements, please [open an issue](https://github.com/anshulyadav32/LinuxSetup/issues).

## 📞 Support

For support and questions:
- Open an issue on GitHub
- Check the documentation in the `website/docs/` directory

---

**Happy configuring! 🐧✨**
