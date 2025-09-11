#!/bin/bash
# Add new DNS zone or nameserver for a website
log() { echo "[DNS ZONE] $1"; }

ZONE_NAME="$1"
IP_ADDR="$2"

if [[ -z "$ZONE_NAME" || -z "$IP_ADDR" ]]; then
    echo "Usage: $0 <zone_name> <ip_address>"
    exit 1
fi

log "Creating DNS zone: $ZONE_NAME -> $IP_ADDR"

ZONE_FILE="/etc/bind/zones/db.$ZONE_NAME"

mkdir -p /etc/bind/zones

cat > "$ZONE_FILE" << EOF
\$TTL    604800
@       IN      SOA     ns1.$ZONE_NAME. admin.$ZONE_NAME. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$ZONE_NAME.
@       IN      A       $IP_ADDR
ns1     IN      A       $IP_ADDR
www     IN      A       $IP_ADDR
