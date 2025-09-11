#!/bin/bash
# DNS Server Setup (Primary or Secondary)
log() { echo "[DNS SERVER] $1"; }

ROLE="${1:-primary}"  # default primary

log "Installing BIND9 DNS server for role: $ROLE"

if command -v apt >/dev/null 2>&1; then
    apt update && apt install -y bind9 bind9utils bind9-doc
elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    yum install -y bind bind-utils
fi

systemctl enable bind9 || systemctl enable named
systemctl start bind9 || systemctl start named

if [[ "$ROLE" == "primary" ]]; then
    log "Configuring as primary DNS server..."
    # Setup /etc/bind/named.conf.local or /etc/named.conf zones here
elif [[ "$ROLE" == "secondary" ]]; then
    log "Configuring as secondary DNS server..."
    # Setup /etc/bind/named.conf.local with masters directive
fi

log "✅ DNS server ($ROLE) installed and running"
