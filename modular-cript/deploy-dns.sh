#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/modules/common.sh"
require_root
source "${SCRIPT_DIR}/modules/dns.sh"

echo
echo "========== DNS Deployment =========="

# Core inputs
read -rp "Zone (example.com): " DNS_DOMAIN
[[ -z "$DNS_DOMAIN" ]] && die "Zone is required."

read -rp "Primary NS hostname [ns1.${DNS_DOMAIN}]: " IN_NS1
DNS_NS1="${IN_NS1:-ns1.${DNS_DOMAIN}}"

read -rp "Secondary NS hostname [ns2.${DNS_DOMAIN}]: " IN_NS2
DNS_NS2="${IN_NS2:-ns2.${DNS_DOMAIN}}"

read -rp "IPv4 for records (A) [127.0.0.1]: " IN_A
DNS_A="${IN_A:-127.0.0.1}"

read -rp "IPv6 for records (AAAA) (optional): " IN_AAAA
DNS_AAAA="${IN_AAAA:-}"

read -rp "SOA admin email (admin.${DNS_DOMAIN}) [admin@${DNS_DOMAIN}]: " IN_SOA
DNS_SOA_EMAIL="${IN_SOA:-admin@${DNS_DOMAIN}}"

# Reverse zones (optional)
read -rp "Create reverse zone for IPv4? (yes/no) [no]: " IN_RV4
DO_REV4="${IN_RV4:-no}"
if [[ "$DO_REV4" == "yes" ]]; then
  read -rp "Reverse zone (e.g., 1.168.192.in-addr.arpa): " RV4_ZONE
  read -rp "Last octet PTR host for ${DNS_A} (e.g., 10 for ...0.10) [auto]: " RV4_PTR
fi

read -rp "Create reverse zone for IPv6? (yes/no) [no]: " IN_RV6
DO_REV6="${IN_RV6:-no}"
if [[ "$DO_REV6" == "yes" ]]; then
  read -rp "Reverse zone (e.g., 8.b.d.0.1.0.0.2.ip6.arpa): " RV6_ZONE
  read -rp "Full nibble PTR label for AAAA (optional): " RV6_PTR
fi

# Zone transfer + TSIG
read -rp "Allow zone transfers to a secondary? (yes/no) [no]: " IN_XFR
DO_XFR="${IN_XFR:-no}"
if [[ "$DO_XFR" == "yes" ]]; then
  read -rp "Secondary server IP (for allow-transfer & also-notify): " SECONDARY_IP
  read -rp "Use TSIG for transfers/updates? (yes/no) [yes]: " IN_TSIG
  DO_TSIG="${IN_TSIG:-yes}"
  [[ "$DO_TSIG" == "yes" ]] && read -rp "TSIG key name [${DNS_DOMAIN}-xfr-key]: " TSIG_NAME && TSIG_NAME="${TSIG_NAME:-${DNS_DOMAIN}-xfr-key}"
fi

# DNSSEC
read -rp "Enable DNSSEC (inline signing, auto keys)? (yes/no) [yes]: " IN_DNSSEC
DO_DNSSEC="${IN_DNSSEC:-yes}"

# Views / recursion / RRL / logging
read -rp "Enable split-horizon (internal/external views)? (yes/no) [no]: " IN_VIEWS
DO_VIEWS="${IN_VIEWS:-no}"
if [[ "$DO_VIEWS" == "yes" ]]; then
  read -rp "Internal CIDR(s) comma-separated (e.g., 10.0.0.0/8,192.168.0.0/16): " INTERNAL_CIDRS
fi

read -rp "Allow recursion for internal only? (yes/no) [yes]: " IN_REC
REC_INTERNAL_ONLY="${IN_REC:-yes}"

read -rp "Enable Response Rate Limiting (RRL)? (yes/no) [no]: " IN_RRL
DO_RRL="${IN_RRL:-no}"

read -rp "Enable verbose logging to /var/log/named? (yes/no) [yes]: " IN_LOG
DO_LOG="${IN_LOG:-yes}"

# Extra records
read -rp "Add MX record? (yes/no) [no]: " IN_MX
DO_MX="${IN_MX:-no}"
if [[ "$DO_MX" == "yes" ]]; then
  read -rp "MX host (mail.${DNS_DOMAIN}): " MX_HOST
  MX_HOST="${MX_HOST:-mail.${DNS_DOMAIN}}"
  read -rp "MX priority [10]: " MX_PRIO
  MX_PRIO="${MX_PRIO:-10}"
fi

read -rp "Add TXT/SPF? (yes/no) [no]: " IN_TXT
DO_TXT="${IN_TXT:-no}"
if [[ "$DO_TXT" == "yes" ]]; then
  read -rp "TXT value (e.g., v=spf1 a mx ~all): " TXT_VALUE
fi

echo
echo "========== DNS Plan =========="
echo "Zone         : $DNS_DOMAIN"
echo "NS           : $DNS_NS1, $DNS_NS2"
echo "A/AAAA       : $DNS_A ${DNS_AAAA:+, $DNS_AAAA}"
echo "Reverse v4   : $DO_REV4 ${RV4_ZONE:+($RV4_ZONE)}"
echo "Reverse v6   : $DO_REV6 ${RV6_ZONE:+($RV6_ZONE)}"
echo "XFR/TSIG     : $DO_XFR ${SECONDARY_IP:+to $SECONDARY_IP} ${DO_TSIG:+(tsig=$TSIG_NAME)}"
echo "DNSSEC       : $DO_DNSSEC"
echo "Views        : $DO_VIEWS ${INTERNAL_CIDRS:+($INTERNAL_CIDRS)}"
echo "Recursion    : $REC_INTERNAL_ONLY"
echo "RRL          : $DO_RRL"
echo "Logging      : $DO_LOG"
echo "MX/TXT       : ${DO_MX:+MX=$MX_HOST prio=$MX_PRIO} ${DO_TXT:+TXT}"
echo "================================"
read -rp "Proceed? (yes/no) [yes]: " PROCEED
PROCEED="${PROCEED:-yes}"
[[ "$PROCEED" != "yes" ]] && exit 0

# Run
dns_install_core
dns_backup_configs
dns_config_options "$REC_INTERNAL_ONLY" "$DO_RRL" "$DO_LOG"
dns_zone_forward "$DNS_DOMAIN" "$DNS_NS1" "$DNS_NS2" "$DNS_A" "$DNS_AAAA" "$DNS_SOA_EMAIL"

[[ "$DO_MX" == "yes" ]] && dns_add_mx "$DNS_DOMAIN" "$MX_HOST" "$MX_PRIO"
[[ "$DO_TXT" == "yes" ]] && dns_add_txt "$DNS_DOMAIN" "$TXT_VALUE"

if [[ "$DO_REV4" == "yes" ]]; then
  dns_zone_reverse_v4 "$DNS_DOMAIN" "$RV4_ZONE" "$DNS_A" "${RV4_PTR:-}"
fi
if [[ "$DO_REV6" == "yes" ]]; then
  dns_zone_reverse_v6 "$DNS_DOMAIN" "$RV6_ZONE" "$DNS_AAAA" "${RV6_PTR:-}"
fi

if [[ "$DO_XFR" == "yes" ]]; then
  if [[ "${DO_TSIG:-no}" == "yes" ]]; then
    dns_tsig_create "$TSIG_NAME"
    dns_allow_transfer_tsig "$DNS_DOMAIN" "$SECONDARY_IP" "$TSIG_NAME"
  else
    dns_allow_transfer_ip "$DNS_DOMAIN" "$SECONDARY_IP"
  fi
fi

if [[ "$DO_DNSSEC" == "yes" ]]; then
  dns_enable_dnssec "$DNS_DOMAIN"
fi

if [[ "$DO_VIEWS" == "yes" ]]; then
  dns_enable_views "$DNS_DOMAIN" "$DNS_NS1" "$DNS_NS2" "$DNS_A" "$DNS_AAAA" "$INTERNAL_CIDRS"
fi

dns_validate_all
dns_reload

dns_summary "$DNS_DOMAIN"
