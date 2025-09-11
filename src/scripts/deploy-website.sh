#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to display success message
success() {
    echo -e "${GREEN}✔ $1${NC}"
}

# Function to display info message
info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

echo
echo "========== Website Deployment Configuration =========="
echo

# Get configuration from user
read -p "Enter domain name (e.g., example.com): " DOMAIN
read -p "Select application type (php/node): " APP_TYPE
while [[ "$APP_TYPE" != "php" && "$APP_TYPE" != "node" ]]; do
    echo "Invalid application type. Please enter 'php' or 'node'"
    read -p "Select application type (php/node): " APP_TYPE
done

read -p "Enter Git repository URL (optional): " GIT_REPO
read -p "Enable SSL/HTTPS? (yes/no) [yes]: " SSL_ENABLED
SSL_ENABLED=${SSL_ENABLED:-yes}

NODE_VERSION=""
if [[ "$APP_TYPE" == "node" ]]; then
    read -p "Enter Node.js version [16]: " NODE_VERSION
    NODE_VERSION=${NODE_VERSION:-16}
fi

# Configuration summary
echo
echo "========== Deployment Configuration Summary =========="
echo
info "Domain: $DOMAIN"
info "Application Type: $APP_TYPE"
info "Web Root: /var/www/$DOMAIN"
info "SSL Enabled: $SSL_ENABLED"
[[ -n "$NODE_VERSION" ]] && info "Node.js Version: $NODE_VERSION"

read -p "Proceed with deployment? (yes/no) [yes]: " PROCEED
PROCEED=${PROCEED:-yes}
[[ "$PROCEED" != "yes" ]] && exit 0

echo
echo "========== Setting up DNS =========="
echo

# Create zone file
info "Creating zone file: /etc/bind/zones/db.$DOMAIN"
sudo mkdir -p /etc/bind/zones
sudo bash -c "cat > /etc/bind/zones/db.$DOMAIN << EOL
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN.
@       IN      A       127.0.0.1
www     IN      A       127.0.0.1
ns1     IN      A       127.0.0.1
EOL"

# Update named configuration
info "Updating named configuration"
sudo bash -c "cat >> /etc/bind/named.conf.local << EOL
zone \"$DOMAIN\" {
    type master;
    file \"/etc/bind/zones/db.$DOMAIN\";
};
EOL"

# Restart DNS service
sudo systemctl restart named || true
success "DNS setup completed"

echo
echo "========== Setting up web server =========="
echo

# Install required packages
info "Installing pre-requisites"
sudo apt-get update
sudo apt-get install -y nginx curl

# Install Node.js and PM2 if needed
if [[ "$APP_TYPE" == "node" ]]; then
    info "Installing Node.js v$NODE_VERSION"
    curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    info "Installing PM2"
    sudo npm install -g pm2
fi

# Create Nginx configuration
sudo bash -c "cat > /etc/nginx/sites-available/$DOMAIN << EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root /var/www/$DOMAIN;

    location / {
        $(if [[ "$APP_TYPE" == "node" ]]; then
            echo 'proxy_pass http://localhost:3000;'
            echo 'proxy_http_version 1.1;'
            echo 'proxy_set_header Upgrade \$http_upgrade;'
            echo 'proxy_set_header Connection "upgrade";'
            echo 'proxy_set_header Host \$host;'
            echo 'proxy_cache_bypass \$http_upgrade;'
        else
            echo 'try_files \$uri \$uri/ /index.php?\$query_string;'
            echo 'index index.php index.html;'
        fi)
    }

    $(if [[ "$APP_TYPE" == "php" ]]; then
        echo 'location ~ \.php$ {'
        echo '    include snippets/fastcgi-php.conf;'
        echo '    fastcgi_pass unix:/var/run/php/php-fpm.sock;'
        echo '}'
    fi)
}
EOL"

# Enable site
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo systemctl restart nginx

success "Web server setup completed"

echo
echo "========== Deploying application =========="
echo

# Create web root
sudo mkdir -p /var/www/$DOMAIN

# Clone repository if provided
if [[ -n "$GIT_REPO" ]]; then
    info "Cloning repository"
    sudo git clone $GIT_REPO /var/www/$DOMAIN
else
    # Create default application files
    if [[ "$APP_TYPE" == "node" ]]; then
        sudo bash -c "cat > /var/www/$DOMAIN/package.json << EOL
{
  \"name\": \"$DOMAIN\",
  \"version\": \"1.0.0\",
  \"main\": \"app.js\",
  \"scripts\": {
    \"start\": \"node app.js\"
  },
  \"dependencies\": {
    \"express\": \"^4.18.2\"
  }
}
EOL"

        sudo bash -c "cat > /var/www/$DOMAIN/app.js << EOL
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send('Hello from $DOMAIN! Node.js application is running.');
});

app.listen(port, () => {
    console.log(\`Server is running on port \${port}\`);
});
EOL"
    else
        sudo bash -c "cat > /var/www/$DOMAIN/index.php << EOL
<?php
echo 'Hello from $DOMAIN! PHP application is running.';
EOL"
    fi
fi

# Set up Node.js application
if [[ "$APP_TYPE" == "node" ]]; then
    cd /var/www/$DOMAIN
    sudo npm install

    # Start application with PM2
    sudo -u www-data PM2_HOME="/var/www/$DOMAIN/.pm2" pm2 start app.js --name "$DOMAIN"
    
    # Save PM2 process list
    sudo -u www-data PM2_HOME="/var/www/$DOMAIN/.pm2" pm2 save
    
    # Generate PM2 startup script
    sudo pm2 startup
    
    # Set proper ownership and permissions
    sudo chown -R www-data:www-data /var/www/$DOMAIN
    sudo chmod -R 755 /var/www/$DOMAIN
fi

success "Application deployed successfully"

if [[ "$SSL_ENABLED" == "yes" ]]; then
    echo
    echo "========== Setting up SSL =========="
    echo

    # Install certbot
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx

    # Obtain and install certificate
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email webmaster@$DOMAIN

    success "SSL setup completed"
fi

echo
echo "========== Deployment Complete! =========="
echo

success "Website deployed successfully at https://$DOMAIN"
if [[ "$APP_TYPE" == "node" ]]; then
    info "Node.js application is running with PM2"
    info "Check status with: pm2 status"
    info "View logs with: pm2 logs $DOMAIN"
fi
