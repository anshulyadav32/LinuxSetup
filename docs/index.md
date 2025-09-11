---
layout: default
---

# Linux Server Setup Scripts 🚀

Comprehensive automation for deploying and configuring Linux servers with:

- **Web servers** (Nginx/Apache)
- **Databases** (MySQL/PostgreSQL)
- **DNS servers** (BIND9)

## Features

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

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/anshulyadav32/LS.git
cd LS
```

2. Run the master deployment script:
```bash
sudo bash deploy-master.sh
```

[View on GitHub](https://github.com/anshulyadav32/LS)