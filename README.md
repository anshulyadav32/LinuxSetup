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
```

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