# 📥 Installation Guide

This guide provides detailed instructions for installing and setting up the Linux Server Setup Scripts on your system.

## 📋 Prerequisites

### System Requirements
- Operating System: Ubuntu 20.04+ / Debian 11+
- Minimum RAM: 1GB (2GB recommended)
- Minimum Disk Space: 10GB
- Root or sudo access
- Internet connectivity

### Required Packages
```bash
# Core utilities
apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    rsync \
    netcat \
    openssl \
    ca-certificates

# Optional but recommended
apt-get install -y \
    htop \
    tmux \
    screen \
    vim
```

## 🚀 Quick Installation

### 1. One-Line Installation
```bash
curl -sSL https://raw.githubusercontent.com/anshulyadav32/LS/main/src/scripts/setup.sh | sudo bash
```

### 2. Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/anshulyadav32/LS.git
cd LS
```

2. Make scripts executable:
```bash
chmod +x src/scripts/*.sh
chmod +x modular-cript/*.sh
```

3. Run the setup script:
```bash
sudo ./src/scripts/setup.sh
```

## 🛠️ Component-Specific Installation

### Web Server Setup
```bash
cd modular-cript
sudo ./deploy-web.sh
```

### Database Server Setup
```bash
cd modular-cript
sudo ./deploy-db.sh
```

### DNS Server Setup
```bash
cd modular-cript
sudo ./deploy-dns.sh
```

## ⚙️ Configuration

### 1. Environment Files
1. Copy the example environment file:
```bash
cp config/dev.env config/prod.env
```

2. Edit the production environment file:
```bash
vim config/prod.env
```

3. Set required variables:
```bash
DOMAIN=example.com
ADMIN_EMAIL=admin@example.com
DB_ROOT_PASSWORD=secure_password
ENABLE_SSL=true
```

### 2. Custom Configuration
- Web server configurations go in: `modular-cript/modules/web.sh`
- Database configurations go in: `modular-cript/modules/db.sh`
- DNS configurations go in: `modular-cript/modules/dns.sh`

## 🔒 Security Setup

### 1. SSL/TLS Configuration
```bash
# Install Let's Encrypt certificates
sudo ./src/scripts/setup.sh --ssl \
    --domain example.com \
    --email admin@example.com
```

### 2. Firewall Setup
```bash
# Configure basic firewall rules
sudo ./src/modules/firewall.sh
```

## 📊 Verification

### 1. Check Installation
```bash
# Verify system setup
sudo ./src/scripts/check-setup.sh
```

### 2. Test Services
```bash
# Test web server
curl -I https://example.com

# Test database connection
mysql -u root -p -e "SELECT VERSION();"

# Test DNS server
dig @localhost example.com
```

## 🔄 Updates

### Updating the Scripts
```bash
# Pull latest changes
git pull origin main

# Run update script
sudo ./src/scripts/update-all.sh
```

## 🐛 Troubleshooting

### Common Issues

1. Permission Denied
```bash
# Fix permissions
sudo chown -R root:root .
sudo chmod -R 755 src/scripts/
sudo chmod -R 755 modular-cript/
```

2. Service Won't Start
```bash
# Check service status
systemctl status nginx
systemctl status mysql
named -g # For DNS server
```

3. SSL Certificate Issues
```bash
# Check SSL configuration
certbot certificates
openssl s_client -connect example.com:443
```

### Log Files
- Web Server: `/var/log/nginx/error.log`
- Database: `/var/log/mysql/error.log`
- DNS Server: `/var/log/named/named.log`

## 📚 Additional Resources

- [Main Documentation](README.md)
- [Contribution Guidelines](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

## 🆘 Support

If you encounter any issues during installation:

1. Check the logs in `/var/log/`
2. Run the check-setup script: `sudo ./src/scripts/check-setup.sh`
3. Create an issue on GitHub with:
   - Error messages
   - System information
   - Steps to reproduce
