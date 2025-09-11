#!/bin/bash
# =============================================================================
# Check Setup Script - Verify All Modules Are Working
# =============================================================================

check_command() {
    command -v "$1" >/dev/null 2>&1
}

echo "🚀 Starting system check..."

# ----------------------
# 1. Check Webserver
# ----------------------
echo "🔹 Checking Webserver (Apache/Nginx/PHP)..."
if systemctl is-active --quiet apache2 2>/dev/null || systemctl is-active --quiet httpd 2>/dev/null; then
    echo "✅ Apache is running"
else
    echo "❌ Apache is not running"
fi

if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "✅ Nginx is running"
else
    echo "⚠️ Nginx not started (may be intentional)"
fi

if check_command php; then
    echo "✅ PHP installed: $(php -v | head -n1)"
else
    echo "❌ PHP not installed"
fi

# ----------------------
# 2. Check Database
# ----------------------
echo "🔹 Checking Database (MariaDB/MySQL + PostgreSQL)..."
if systemctl is-active --quiet mariadb 2>/dev/null || systemctl is-active --quiet mysql 2>/dev/null; then
    echo "✅ MariaDB/MySQL is running"
else
    echo "❌ MariaDB/MySQL is not running"
fi

if systemctl is-active --quiet postgresql 2>/dev/null; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL is not running"
fi

# ----------------------
# 3. Check DNS
# ----------------------
echo "🔹 Checking DNS (BIND / named)..."
if systemctl is-active --quiet named 2>/dev/null || systemctl is-active --quiet bind9 2>/dev/null; then
    echo "✅ DNS service is running"
else
    echo "⚠️ DNS service not running"
fi

# ----------------------
# 4. Check Firewall
# ----------------------
echo "🔹 Checking Firewall (UFW / Firewalld)..."
if systemctl is-active --quiet ufw 2>/dev/null || systemctl is-active --quiet firewalld 2>/dev/null; then
    echo "✅ Firewall is running"
else
    echo "❌ Firewall is not running"
fi

# ----------------------
# 5. Check SSL (Certbot)
# ----------------------
echo "🔹 Checking SSL (Certbot)..."
if check_command certbot; then
    echo "✅ Certbot available: $(certbot --version)"
else
    echo "❌ Certbot not installed"
fi

# ----------------------
# 6. Check Backup
# ----------------------
echo "🔹 Checking Backup Tools..."
if check_command rsync && check_command tar && check_command rclone; then
    echo "✅ Backup tools available"
else
    echo "❌ Backup tools missing"
fi

# ----------------------
# Summary
# ----------------------
echo "=============================="
echo "✅ System check completed"
echo "Review warnings or errors above to ensure all modules are working"
