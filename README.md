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

3. **Run the main setup:**
   ```bash
   sudo ./setup.sh
   ```

### Modular Setup

For a more customized installation, use the modular approach:

```bash
sudo ./setup-modular.sh
```

This allows you to select which components to install and configure.

### Demo Mode

To see the scripts in action without making system changes:

```bash
./demo.sh          # Basic demo
./demo-modular.sh  # Modular demo
```

## 📋 Available Modules

- **🗄️ Database**: MySQL, PostgreSQL, MongoDB setup and configuration
- **🌐 DNS**: DNS server configuration and management
- **🔥 Firewall**: UFW, iptables configuration and security rules
- **🔒 SSL**: Let's Encrypt, self-signed certificates, SSL configuration
- **🖥️ Web Server**: Apache, Nginx installation and virtual host setup

## 🔧 Configuration

Each module can be configured independently. Check the individual module files in the `modules/` directory for specific configuration options.

### Environment Variables

You can customize the installation by setting environment variables:

```bash
export INSTALL_WEBSERVER=true
export INSTALL_DATABASE=true
export INSTALL_SSL=false
./setup-modular.sh
```

## 📚 Documentation

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
