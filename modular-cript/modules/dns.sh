#!/bin/bash
set -euo pipefail

ZONES_DIR="/etc/bind/zones"
LOCAL_CONF="/etc/bind/named.conf.local"
OPTIONS_CONF="/etc/bind/named.conf.options"
LOG_DIR="/var/log/named"

dns_install_core() {
  info "Installing BIND9 and tools"
  apt_install bind9 bind9utils bind9-doc dnsutils
  mkdir -p "$ZONES_DIR" "$LOG_DIR"
  chown bind:bind "$LOG_DIR"
  chmod 750 "$LOG_DIR"
  systemctl enable bind9 >/dev/null
  systemctl start bind9
  ok "BIND9 installed and running"
}

dns_backup_configs() {
  info "Backing up existing configs"
  TS=$(date +%Y%m%d_%H%M%S)
  cp -a "$LOCAL_CONF" "${LOCAL_CONF}.${TS}.bak" || true
  cp -a "$OPTIONS_CONF" "${OPTIONS_CONF}.${TS}.bak" || true
  ok "Backups saved with suffix .${TS}.bak"
}

dns_config_options() {
  local REC_INTERNAL_ONLY="$1" DO_RRL="$2" DO_LOG="$3"

  info "Writing $OPTIONS_CONF"
  cat > "$OPTIONS_CONF" <<'CONF'
options {
    directory "/var/cache/bind";

    // Listen on IPv4/IPv6
    listen-on-v6 { any; };
    listen-on { any; };

    // Default recursion policy; views can override
    allow-recursion { any; };

    // Forwarders (optional) - comment or edit as needed
    // forwarders {
    //     1.1.1.1;
    //     8.8.8.8;
    // };

    dnssec-validation auto;
    auth-nxdomain no;    // conform to RFC1035
    recursion yes;       // may be restricted by views
    minimal-responses yes;

    // Response Rate Limiting (conditional include below)
    // rate-limit { responses-per-second 20; window 5; };
};
CONF

  # Tighten recursion if requested (will be overridden by views if enabled)
  if [[ "$REC_INTERNAL_ONLY" == "yes" ]]; then
    sed -i 's/allow-recursion { any; };/allow-recursion { localhost; localnets; };/' "$OPTIONS_CONF"
  fi

  # Enable RRL if requested (bind 9.10+)
  if [[ "$DO_RRL" == "yes" ]]; then
    sed -i 's#};$#    rate-limit { responses-per-second 20; window 5; slip 2; }; \n};#' "$OPTIONS_CONF"
  fi

  # Logging
  if [[ "$DO_LOG" == "yes" ]]; then
    cat >> "$OPTIONS_CONF" <<'LOG'
logging {
    channel default_log { file "/var/log/named/named.log" versions 7 size 10m; severity info; print-time yes; };
    channel queries_log { file "/var/log/named/queries.log" versions 7 size 20m; severity info; print-time yes; };
    category default { default_log; };
    category queries { queries_log; };
};
LOG
  fi
}

dns_zone_forward() {
  local DOMAIN="$1" NS1="$2" NS2="$3" AIP="$4" AAAAIP="$5" SOA_EMAIL="$6"
  local ZONE_FILE="${ZONES_DIR}/db.${DOMAIN}"

  info "Creating forward zone ${DOMAIN}"
  # zone file
  {
    echo '$TTL 604800'
    echo "@ IN SOA ${NS1}. ${SOA_EMAIL/. /\\\.}. ("
    echo "    $(date +%Y%m%d)01 ; Serial"
    echo "    604800            ; Refresh"
    echo "    86400             ; Retry"
    echo "    2419200           ; Expire"
    echo "    604800 )          ; Negative Cache TTL"
    echo ";"
    echo "@    IN NS ${NS1}."
    echo "@    IN NS ${NS2}."
    [[ -n "$AIP"   ]] && { echo "@    IN A      ${AIP}"; echo "www  IN A      ${AIP}"; }
    [[ -n "$AAAAIP" ]] && { echo "@    IN AAAA   ${AAAAIP}"; echo "www  IN AAAA   ${AAAAIP}"; }
    # Nameserver glue (host A/AAAA)
    echo "${NS1%%.${DOMAIN}} IN A ${AIP:-127.0.0.1}"
    [[ -n "$AAAAIP" ]] && echo "${NS1%%.${DOMAIN}} IN AAAA ${AAAAIP}"
    echo "${NS2%%.${DOMAIN}} IN A ${AIP:-127.0.0.1}"
    [[ -n "$AAAAIP" ]] && echo "${NS2%%.${DOMAIN}} IN AAAA ${AAAAIP}"
  } > "$ZONE_FILE"

  # named.conf.local entry (master)
  if ! grep -q "zone \"$DOMAIN\"" "$LOCAL_CONF"; then
    cat >> "$LOCAL_CONF" <<EOF
zone "${DOMAIN}" {
    type master;
    file "${ZONE_FILE}";
    inline-signing no;
    auto-dnssec off;
};
EOF
  fi
  ok "Forward zone created at $ZONE_FILE"
}

dns_add_mx() {
  local DOMAIN="$1" HOST="$2" PRIO="$3"
  local ZONE_FILE="${ZONES_DIR}/db.${DOMAIN}"
  info "Adding MX ${HOST} (prio ${PRIO})"
  echo "@ IN MX ${PRIO} ${HOST}." >> "$ZONE_FILE"
  # ensure A for MX host (maps to zone AIP by default)
  grep -q "^${HOST%%.${DOMAIN}}[[:space:]]\+IN[[:space:]]\+A" "$ZONE_FILE" || echo "${HOST%%.${DOMAIN}} IN A 127.0.0.1" >> "$ZONE_FILE"
}

dns_add_txt() {
  local DOMAIN="$1" VAL="$2"
  local ZONE_FILE="${ZONES_DIR}/db.${DOMAIN}"
  info "Adding TXT"
  echo "@ IN TXT \"${VAL}\"" >> "$ZONE_FILE"
}

dns_zone_reverse_v4() {
  local DOMAIN="$1" RV4_ZONE="$2" AIP="$3" PTR_LAST="${4:-}"
  local ZONE_FILE="${ZONES_DIR}/db.${RV4_ZONE}"
  local LAST_OCTET="${PTR_LAST:-${AIP##*.}}"

  info "Creating reverse v4 zone ${RV4_ZONE}"
  cat > "$ZONE_FILE" <<EOF
\$TTL 604800
@ IN SOA ns1.${DOMAIN}. admin.${DOMAIN}. (
   $(date +%Y%m%d)01 604800 86400 2419200 604800 )
@    IN NS ns1.${DOMAIN}.
@    IN NS ns2.${DOMAIN}.
${LAST_OCTET} IN PTR ${DOMAIN}.
EOF

  if ! grep -q "zone \"$RV4_ZONE\"" "$LOCAL_CONF"; then
    cat >> "$LOCAL_CONF" <<EOF
zone "${RV4_ZONE}" {
    type master;
    file "${ZONE_FILE}";
};
EOF
  fi
  ok "IPv4 reverse zone created"
}

dns_zone_reverse_v6() {
  local DOMAIN="$1" RV6_ZONE="$2" AAAAIP="$3" PTR_LABEL="${4:-}"
  local ZONE_FILE="${ZONES_DIR}/db.${RV6_ZONE}"

  info "Creating reverse v6 zone ${RV6_ZONE}"
  cat > "$ZONE_FILE" <<EOF
\$TTL 604800
@ IN SOA ns1.${DOMAIN}. admin.${DOMAIN}. (
   $(date +%Y%m%d)01 604800 86400 2419200 604800 )
@    IN NS ns1.${DOMAIN}.
@    IN NS ns2.${DOMAIN}.
${PTR_LABEL:-} IN PTR ${DOMAIN}.
EOF

  if ! grep -q "zone \"$RV6_ZONE\"" "$LOCAL_CONF"; then
    cat >> "$LOCAL_CONF" <<EOF
zone "${RV6_ZONE}" {
    type master;
    file "${ZONE_FILE}";
};
EOF
  fi
  ok "IPv6 reverse zone created"
}

dns_tsig_create() {
  local NAME="$1"
  info "Generating TSIG key ${NAME}"
  rndc-confgen -a -k "$NAME" -b 256 >/dev/null 2>&1 || true
  # Move to bind dir in a reusable way
  if [[ ! -f "/etc/bind/keys/${NAME}.key" ]]; then
    mkdir -p /etc/bind/keys
    tsig-keygen -a hmac-sha256 "$NAME" > "/etc/bind/keys/${NAME}.key"
    chown bind:bind /etc/bind/keys/${NAME}.key
    chmod 640 /etc/bind/keys/${NAME}.key
  fi
  ok "TSIG key created at /etc/bind/keys/${NAME}.key"
  info "Share the key secret with the secondary (securely)."
}

dns_allow_transfer_tsig() {
  local DOMAIN="$1" SEC_IP="$2" KEYNAME="$3"
  info "Configuring allow-transfer + also-notify (TSIG) for ${DOMAIN}"
  # include key & server clause in named.conf.local if missing
  if ! grep -q "key ${KEYNAME}" "$LOCAL_CONF"; then
    cat >> "$LOCAL_CONF" <<EOF

key "${KEYNAME}" {
    algorithm hmac-sha256;
    secret "$(grep secret /etc/bind/keys/${KEYNAME}.key | awk '{print $2}' | tr -d ';"')";
};

server ${SEC_IP} {
    keys { "${KEYNAME}"; };
};
EOF
  fi

  # Add transfer settings into zone
  awk -v domain="$DOMAIN" -v ip="$SEC_IP" -v key="$KEYNAME" '
    $0 ~ "zone \""domain"\"" { inzone=1 }
    inzone && /{/ { print; print "    allow-transfer { key \""key"\"; "ip"; };"; print "    also-notify { "ip"; };"; next }
    { print }
    inzone && /};/ { inzone=0 }
  ' "$LOCAL_CONF" > "${LOCAL_CONF}.tmp" && mv "${LOCAL_CONF}.tmp" "$LOCAL_CONF"
}

dns_allow_transfer_ip() {
  local DOMAIN="$1" SEC_IP="$2"
  info "Configuring IP-based allow-transfer for ${DOMAIN}"
  awk -v domain="$DOMAIN" -v ip="$SEC_IP" '
    $0 ~ "zone \""domain"\"" { inzone=1 }
    inzone && /{/ { print; print "    allow-transfer { "ip"; };"; print "    also-notify { "ip"; };"; next }
    { print }
    inzone && /};/ { inzone=0 }
  ' "$LOCAL_CONF" > "${LOCAL_CONF}.tmp" && mv "${LOCAL_CONF}.tmp" "$LOCAL_CONF"
}

dns_enable_dnssec() {
  local DOMAIN="$1"
  info "Enabling DNSSEC (inline-signing + auto keys) for ${DOMAIN}"
  # update zone stanza
  awk -v domain="$DOMAIN" '
    $0 ~ "zone \""domain"\"" { inzone=1 }
    inzone && /{/ { print; print "    inline-signing yes;"; print "    auto-dnssec maintain;"; next }
    { print }
    inzone && /};/ { inzone=0 }
  ' "$LOCAL_CONF" > "${LOCAL_CONF}.tmp" && mv "${LOCAL_CONF}.tmp" "$LOCAL_CONF"

  # generate keys (KSK/ZSK) if not present
  mkdir -p "/var/cache/bind/keys/${DOMAIN}"
  pushd "/var/cache/bind/keys/${DOMAIN}" >/dev/null
  if ! ls K${DOMAIN}*.key >/dev/null 2>&1; then
    info "Generating ZSK/KSK keys"
    dnssec-keygen -a ECDSAP256SHA256 -n ZONE "${DOMAIN}" >/dev/null
    dnssec-keygen -f KSK -a ECDSAP256SHA256 -n ZONE "${DOMAIN}" >/dev/null
  fi
  popd >/dev/null
  chown -R bind:bind "/var/cache/bind/keys/${DOMAIN}"

  info "After reload, signed zone will be created. To get DS record:"
  echo "  grep DS /var/cache/bind/*.signed  (or use dnssec-dsfromkey on KSK)"
}

dns_enable_views() {
  local DOMAIN="$1" NS1="$2" NS2="$3" AIP="$4" AAAAIP="$5" INTERNAL_CIDRS="$6"
  info "Enabling split-horizon views (internal/external) for ${DOMAIN}"

  # Build ACL from comma list
  local ACL="acl internal_nets { localhost; localnets;"
  IFS=',' read -ra CIDRS <<< "$INTERNAL_CIDRS"
  for c in "${CIDRS[@]}"; do
    ACL+=" ${c// /};"
  done
  ACL+=" };"

  # Prepare internal/external zone files
  cp -a "${ZONES_DIR}/db.${DOMAIN}" "${ZONES_DIR}/db.${DOMAIN}.internal"
  cp -a "${ZONES_DIR}/db.${DOMAIN}" "${ZONES_DIR}/db.${DOMAIN}.external"

  # Example: internal might point www to a private IP
  # (You can edit these two files later as needed.)
  sed -i "s/www  IN A.*/www  IN A  ${AIP}/" "${ZONES_DIR}/db.${DOMAIN}.external" || true

  # Rewrite named.conf.local to use views
  cat > "$LOCAL_CONF" <<EOF
${ACL}

view "internal" {
    match-clients { internal_nets; };
    recursion yes;
    zone "${DOMAIN}" {
        type master;
        file "${ZONES_DIR}/db.${DOMAIN}.internal";
        inline-signing no;
        auto-dnssec off;
    };
};

view "external" {
    match-clients { any; };
    recursion no;
    zone "${DOMAIN}" {
        type master;
        file "${ZONES_DIR}/db.${DOMAIN}.external";
        inline-signing no;
        auto-dnssec off;
    };
};
EOF
  ok "Views configured. You can now diverge internal/external data."
}

dns_validate_all() {
  info "Validating configuration & zones"
  named-checkconf
  for f in "$ZONES_DIR"/db.*; do
    [[ -f "$f" ]] || continue
    Z="$(basename "$f" | sed 's/^db\.//')"
    named-checkzone "$Z" "$f" >/dev/null
  done
  ok "Validation passed"
}

dns_reload() {
  info "Reloading BIND9"
  systemctl restart bind9
  sleep 1
  systemctl status bind9 --no-pager -l | sed -n '1,8p' || true
  ok "BIND9 reloaded"
}

dns_summary() {
  local DOMAIN="$1"
  local FORWARD="${ZONES_DIR}/db.${DOMAIN}"
  echo
  ok "DNS Summary"
  echo "========== Files =========="
  echo -e "  Local conf : ${GREEN}${LOCAL_CONF}${NC}"
  echo -e "  Options    : ${GREEN}${OPTIONS_CONF}${NC}"
  echo -e "  Forward    : ${GREEN}${FORWARD}${NC} ${BLUE}(and .internal/.external if views)${NC}"
  echo -e "  Reverse(s) : ${GREEN}${ZONES_DIR}/db.*in-addr.arpa, ${ZONES_DIR}/db.*ip6.arpa${NC}"
  echo -e "  Keys/TSIG  : ${GREEN}/etc/bind/keys/*${NC}"
  echo -e "  DNSSEC keys: ${GREEN}/var/cache/bind/keys/${DOMAIN}${NC}"
  echo
  echo "========== Logs =========="
  echo -e "  ${GREEN}/var/log/named/named.log${NC}"
  echo -e "  ${GREEN}/var/log/named/queries.log${NC}"
  echo -e "  ${GREEN}journalctl -u bind9${NC}"
  echo
  echo "========== Test =========="
  echo "  dig @127.0.0.1 ${DOMAIN} any +noall +answer"
  echo "  dig @127.0.0.1 www.${DOMAIN} A +noall +answer"
  echo "  dig @127.0.0.1 -x <your.IP.v4.here> +noall +answer"
  echo "  rndc reload"
  echo
  info "Dynamic updates (example with TSIG):"
  echo "  nsupdate -k /etc/bind/keys/<tsig>.key"
  echo "    server 127.0.0.1"
  echo "    update add test.${DOMAIN}. 300 A 10.0.0.10"
  echo "    send"
}
