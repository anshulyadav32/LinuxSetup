#!/bin/bash
# =============================================================================
# DNS Module - BIND9, dnsmasq DNS Server Setup
# =============================================================================
# Purpose: Install and configure DNS servers and utilities
# Components: BIND9 (authoritative DNS), dnsmasq (lightweight DNS/DHCP), DNS tools
# =============================================================================

# DNS module installation function
install_dns_module() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_header "Installing DNS Server Module"
    
    log_step "1" "8" "Installing DNS packages"
    
    # Define packages based on OS
    local packages=()
    
    case "$os_type" in
        ubuntu|debian)
            packages=(
                "bind9"             # BIND9 DNS server
                "bind9utils"        # BIND9 utilities
                "bind9-doc"         # BIND9 documentation
                "bind9-dnsutils"    # DNS utilities (dig, nslookup, etc.)
                "dnsmasq"           # Lightweight DNS/DHCP server
                "dnsutils"          # DNS utilities
                "resolvconf"        # DNS resolver configuration
                "systemd-resolved"  # systemd DNS resolver
                "ldnsutils"         # Modern DNS utilities
                "knot-dnsutils"     # Knot DNS utils
            )
            ;;
        centos|rhel|fedora)
            packages=(
                "bind"              # BIND DNS server
                "bind-utils"        # BIND utilities
                "bind-chroot"       # BIND chroot environment
                "dnsmasq"           # Lightweight DNS/DHCP server
                "systemd-resolved"  # systemd DNS resolver
                "ldns-utils"        # Modern DNS utilities
            )
            ;;
        arch)
            packages=(
                "bind"              # BIND DNS server
                "bind-tools"        # BIND utilities
                "dnsmasq"           # Lightweight DNS/DHCP server
                "systemd-resolvconf" # systemd DNS resolver
                "ldns"              # Modern DNS utilities
                "knot"              # Knot DNS server (alternative)
            )
            ;;
    esac
    
    install_packages "$os_type" "$pkg_mgr" "${packages[@]}"
    
    log_step "2" "8" "Configuring BIND9 DNS server"
    configure_bind9 "$os_type"
    
    log_step "3" "8" "Setting up dnsmasq"
    configure_dnsmasq "$os_type"
    
    log_step "4" "8" "Creating DNS zone files"
    create_dns_zones "$os_type"
    
    log_step "5" "8" "Configuring DNS security"
    configure_dns_security "$os_type"
    
    log_step "6" "8" "Creating DNS management scripts"
    create_dns_scripts
    
    log_step "7" "8" "Enabling and starting DNS services"
    enable_dns_services "$os_type"
    
    log_step "8" "8" "Verifying DNS configuration"
    verify_dns_setup "$os_type"
    
    log_success "DNS module installation completed successfully!"
}

# Configure BIND9 DNS server
configure_bind9() {
    local os_type="$1"
    
    log_info "Configuring BIND9 DNS server..."
    
    # Determine BIND configuration directory
    local bind_dir="/etc/bind"
    case "$os_type" in
        centos|rhel|fedora)
            bind_dir="/etc/named"
            ;;
    esac
    
    # Create directories
    mkdir -p "$bind_dir/zones"
    mkdir -p "/var/log/bind"
    
    # Configure named.conf
    case "$os_type" in
        ubuntu|debian)
            configure_bind9_debian
            ;;
        centos|rhel|fedora)
            configure_bind9_rhel
            ;;
        arch)
            configure_bind9_arch
            ;;
    esac
    
    # Set proper permissions
    chown -R bind:bind "$bind_dir" 2>/dev/null || chown -R named:named "$bind_dir" 2>/dev/null || true
    chown -R bind:bind "/var/log/bind" 2>/dev/null || chown -R named:named "/var/log/bind" 2>/dev/null || true
    
    log_success "BIND9 configured successfully"
}

# Configure BIND9 for Debian/Ubuntu
configure_bind9_debian() {
    # Main named.conf
    cat > /etc/bind/named.conf << 'EOF'
// BIND9 Configuration File
// This is the primary configuration file for the BIND DNS server named.

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
EOF

    # Options configuration
    cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";

    // Working directory
    managed-keys-directory "/var/cache/bind/dynamic";

    // Forwarders
    forwarders {
        8.8.8.8;        // Google DNS
        8.8.4.4;        // Google DNS
        1.1.1.1;        // Cloudflare DNS
        1.0.0.1;        // Cloudflare DNS
    };

    // Forward first
    forward first;

    // Listen on IPv4 and IPv6
    listen-on { any; };
    listen-on-v6 { any; };

    // Allow queries from local network
    allow-query { localhost; 192.168.0.0/16; 10.0.0.0/8; 172.16.0.0/12; };

    // Allow recursion for local network
    allow-recursion { localhost; 192.168.0.0/16; 10.0.0.0/8; 172.16.0.0/12; };

    // Allow cache for local network
    allow-query-cache { localhost; 192.168.0.0/16; 10.0.0.0/8; 172.16.0.0/12; };

    // Security settings
    auth-nxdomain no;    // conform to RFC1035
    dnssec-validation auto;
    
    // Rate limiting
    rate-limit {
        responses-per-second 10;
        window 5;
    };

    // Logging
    logging {
        channel default_debug {
            file "/var/log/bind/default.log" versions 3 size 5m;
            severity dynamic;
        };
        channel general_dns {
            file "/var/log/bind/general.log" versions 3 size 5m;
            severity info;
        };
        channel security_dns {
            file "/var/log/bind/security.log" versions 3 size 5m;
            severity info;
        };
        channel queries_dns {
            file "/var/log/bind/queries.log" versions 5 size 10m;
            severity info;
        };

        category default { default_debug; };
        category general { general_dns; };
        category security { security_dns; };
        category queries { queries_dns; };
    };
};
EOF

    # Local zones configuration
    cat > /etc/bind/named.conf.local << 'EOF'
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

// Example forward zone
//zone "example.local" {
//    type master;
//    file "/etc/bind/zones/example.local.zone";
//};

// Example reverse zone
//zone "1.168.192.in-addr.arpa" {
//    type master;
//    file "/etc/bind/zones/192.168.1.rev";
//};
EOF
}

# Configure BIND9 for RHEL/CentOS/Fedora
configure_bind9_rhel() {
    # Main named.conf
    cat > /etc/named.conf << 'EOF'
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//

options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file   "/var/named/data/named.secroots";
    recursing-file  "/var/named/data/named.recursing";
    allow-query     { localhost; 192.168.0.0/16; 10.0.0.0/8; 172.16.0.0/12; };
    allow-recursion { localhost; 192.168.0.0/16; 10.0.0.0/8; 172.16.0.0/12; };

    // Forwarders
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
        1.0.0.1;
    };
    forward first;

    dnssec-enable yes;
    dnssec-validation yes;

    managed-keys-directory "/var/named/dynamic";

    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";

    // Rate limiting
    rate-limit {
        responses-per-second 10;
        window 5;
    };
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
    channel general_dns {
        file "/var/log/named/general.log" versions 3 size 5m;
        severity info;
    };
    channel security_dns {
        file "/var/log/named/security.log" versions 3 size 5m;
        severity info;
    };
    channel queries_dns {
        file "/var/log/named/queries.log" versions 5 size 10m;
        severity info;
    };

    category default { default_debug; };
    category general { general_dns; };
    category security { security_dns; };
    category queries { queries_dns; };
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

// Include local zones
//include "/etc/named/zones.conf";
EOF

    # Create zones configuration file
    cat > /etc/named/zones.conf << 'EOF'
// Local zones configuration
// Add your custom zones here

// Example forward zone
//zone "example.local" {
//    type master;
//    file "/var/named/zones/example.local.zone";
//};

// Example reverse zone
//zone "1.168.192.in-addr.arpa" {
//    type master;
//    file "/var/named/zones/192.168.1.rev";
//};
EOF

    # Create log directory
    mkdir -p /var/log/named
    chown named:named /var/log/named
}

# Configure BIND9 for Arch Linux
configure_bind9_arch() {
    # Similar to Debian but with Arch-specific paths
    configure_bind9_debian
    
    # Adjust for Arch-specific paths if needed
    sed -i 's|/var/cache/bind|/var/named|g' /etc/bind/named.conf.options 2>/dev/null || true
}

# Configure dnsmasq
configure_dnsmasq() {
    local os_type="$1"
    
    log_info "Configuring dnsmasq..."
    
    # Backup original configuration
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null || true
    
    # Create new dnsmasq configuration
    cat > /etc/dnsmasq.conf << 'EOF'
# Configuration file for dnsmasq.

# Never forward plain names (without a dot or domain part)
domain-needed

# Never forward addresses in the non-routed address spaces.
bogus-priv

# Use the hosts file on this machine
expand-hosts

# Set the domain for dnsmasq. this is optional, but if it is set, it
# does the following things.
# 1) Allows DHCP hosts to have fully qualified domain names, as long
#    as the domain part matches this setting.
# 2) Sets the "domain" DHCP option thereby potentially setting the
#    domain of all systems configured by DHCP
# 3) Provides the domain part for "expand-hosts"
domain=local

# Listen on this specific port instead of the standard DNS port
# (53). Setting this to zero completely disables DNS function,
# leaving only DHCP and/or TFTP.
port=5353

# If you want dnsmasq to listen for DHCP and DNS requests only on
# specified interfaces (and the loopback) give the name of the
# interface (eg eth0) here.
interface=lo

# Or you can specify which interface _not_ to listen on
# except-interface=

# Set this (and domain: see below) if you want to have a domain
# automatically added to simple names in a hosts-file.
local=/local/

# Set the cachesize here.
cache-size=1000

# For debugging purposes, log each DNS query as it passes through
# dnsmasq.
#log-queries

# Log lots of extra information about DHCP transactions.
#log-dhcp

# Upstream DNS servers
server=8.8.8.8
server=8.8.4.4
server=1.1.1.1
server=1.0.0.1

# Add local-only domains here, queries in these domains are answered
# from /etc/hosts or DHCP only.
local=/local/
local=/lan/

# Add domains which you want to force to an IP address here.
# The example below send any host in double-click.net to a local
# web-server.
#address=/doubleclick.net/127.0.0.1

# If you want to fix up DNS results from upstream servers, use the
# alias option. This only works for IPv4.
# This alias makes a result of 1.2.3.4 appear as 5.6.7.8
#alias=1.2.3.4,5.6.7.8

# Return an MX record named "maildrop.example.com" with target
# servername.example.com and preference 50
#mx-host=example.com,servername.example.com,50

# Set the default target for MX records created using the localmx option.
#mx-target=servername.example.com

# Return an MX record pointing to the mx-target for all local
# machines.
#localmx

# Return an SRV record named "_sip._tcp.example.com" with target
# servername.example.com port 5060
#srv-host=_sip._tcp.example.com,servername.example.com,5060

# Set the DHCP server to authoritative mode.
#dhcp-authoritative

# Set the DHCP server to enable DHCPv4 Rapid Commit Option 80.
#dhcp-rapid-commit

# Run an executable when a DHCP lease is created or destroyed.
#dhcp-script=/bin/echo

# Set the limit on DHCP leases, the default is 150
#dhcp-lease-max=150

# The DHCP server needs somewhere on disk to keep its lease database.
#dhcp-leasefile=/var/lib/dnsmasq/dnsmasq.leases

# Set the DHCP server to strictly conform to the relevant RFCs.
#dhcp-rfc3442-classless-static-routes

# Override the default route supplied by dnsmasq, which assumes the
# router is the same machine as the one running dnsmasq.
#dhcp-option=3,1.2.3.4

# Do the same thing, but using the option name
#dhcp-option=option:router,1.2.3.4

# Set the NTP time server addresses to 192.168.0.4 and 10.10.0.5
#dhcp-option=option:ntp-server,192.168.0.4,10.10.0.5

# Set the NIS domain name to "welly"
#dhcp-option=40,welly

# Set the default time-to-live to 50
#dhcp-option=23,50

# Set the "all subnets are local" flag
#dhcp-option=27,1

# Send the etherboot magic cookie.
#dhcp-option=128,e4:45:74:68:00:00

# Specify an option which will only be sent to the "red" network
# (see dhcp-range for the declaration of the "red" network)
# Note that the net: part must precede the option: part.
#dhcp-option = net:red, option:ntp-server, 192.168.1.1

# Enable dnsmasq's built-in TFTP server
#enable-tftp

# Set the root directory for files available via FTP.
#tftp-root=/var/ftpd

# Make the TFTP server more secure: with this set, only files owned by
# the user dnsmasq is running as will be send over the net.
#tftp-secure

# This option stops dnsmasq from negotiating a larger blocksize for TFTP
# transfers. It will slow things down, but may rescue some broken TFTP
# clients.
#tftp-no-blocksize

# Set the boot file name only when the "red" tag is set.
#dhcp-boot=net:red,pxelinux.red-net

# An example of dhcp-boot with an external TFTP server: the name and IP
# address of the TFTP server are given after the filename.
#dhcp-boot=/var/ftpd/pxelinux.0,boothost,192.168.0.3

# If there are multiple external tftp servers having a same name
# (using /etc/hosts) then that name can be specified as the
# tftp_servername (the third option to dhcp-boot) and in that
# case dnsmasq resolves this name and returns the resultant IP
# addresses in round robin fasion. This facility can be used to
# load balance the tftp load among a set of servers.
#dhcp-boot=/var/ftpd/pxelinux.0,boothost,tftp_server_name

# Set the limit on DHCP leases, the default is 150
#dhcp-lease-max=150

# The DHCP server needs somewhere on disk to keep its lease database.
#dhcp-leasefile=/var/lib/dnsmasq/dnsmasq.leases

# Override the default route supplied by dnsmasq and send no default
# route at all. Note that this only works for the options sent by
# default (1, 3, 6, 12, 28) the same line will send a zero-length option
# for all other option numbers.
#dhcp-option=3

# Set the NTP time server address to be the same machine as
# is running dnsmasq
#dhcp-option=42,0.0.0.0

# Set the NIS domain name to "welly"
#dhcp-option=40,welly

# Set the default time-to-live to 50
#dhcp-option=23,50

# Set the "all subnets are local" flag
#dhcp-option=27,1

# Send the etherboot magic cookie.
#dhcp-option=128,e4:45:74:68:00:00

# Specify an option which will only be sent to the "red" network
#dhcp-option = net:red, option:ntp-server, 192.168.1.1

# The following DHCP options set up dnsmasq in the same way as is specified
# for the ISC dhcpcd in
# http://www.samba.org/samba/ftp/docs/textdocs/DHCP-Server-Configuration.txt
# adapted for a typical dnsmasq installation where the host running
# dnsmasq is also the host running samba.
# you may want to uncomment some or all of them if you use
# Windows clients and Samba.
#dhcp-option=19,0           # option ip-forwarding off
#dhcp-option=44,0.0.0.0     # set netbios-over-TCP/IP nameserver(s) aka WINS server(s)
#dhcp-option=45,0.0.0.0     # netbios datagram distribution server
#dhcp-option=46,8           # netbios node type

# Send RFC-3397 DNS domain search DHCP option. WARNING: Your DHCP client
# probably doesn't support this......
#dhcp-option=option:domain-search,eng.apple.com,marketing.apple.com

# Send RFC-3442 classless static routes (note the netmask encoding)
#dhcp-option=121,192.168.1.0/24,1.2.3.4,10.0.0.0/8,5.6.7.8

# Send vendor-class specific options encapsulated in DHCP option 43.
# The meaning of the options is defined by the vendor-class so
# options are sent only when the client supplied vendor class
# matches the class given here. (A substring match is OK, so "MSFT"
# matches "MSFT" and "MSFT 5.0"). This example sets the
# mtftp address to 0.0.0.0 for PXEClients.
#dhcp-option=vendor:PXEClient,1,0.0.0.0

# Send microsoft-specific option to tell windows to release the DHCP lease
# when it shuts down. Note the "i" flag, to tell dnsmasq to send the
# value as a four-byte integer - that's what microsoft wants. See
# http://technet2.microsoft.com/WindowsServer/en/library/a70f1bb7-d2d4-49f0-96d6-4b7414ecfaae1033.mspx
#dhcp-option=vendor:MSFT,2,1i

# Send the Encapsulated-vendor-class ID needed by some configurations of
# Etherboot to allow is to recognise the DHCP server.
#dhcp-option=vendor:Etherboot,60,"Etherboot"

# Send options to PXELinux. Note that we need to send the options even
# though they don't appear in the parameter request list, so we need
# to use dhcp-option-force here.
# See http://syslinux.zytor.com/pxe.php#special for details.
# Magic number - needed before anything else is recognized
#dhcp-option-force=208,f1:00:74:7e
# Configuration file name
#dhcp-option-force=209,configs/common
# Path prefix
#dhcp-option-force=210,/tftpboot/pxelinux/files/
# Reboot time. (Note 'i' to send 32-bit value)
#dhcp-option-force=211,30i

# Set the boot filename for netboot/PXE. You will only need
# this is you want to boot machines over the network and you will need
# a TFTP server; either dnsmasq's built in TFTP server or an
# external one. (See below for how to enable the TFTP server.)
#dhcp-boot=pxelinux.0

# The same as above, but use custom tftp-server instead machine running dnsmasq
#dhcp-boot=pxelinux.0,server.name,192.168.1.100

# Boot for Etherboot gPXE. The idea is to send two different
# filenames, the first loads gPXE, and the second tells gPXE what to
# load. The dhcp-match sets the gpxe tag for requests from gPXE.
#dhcp-match=set:gpxe,175 # gPXE sends a 175 option.
#dhcp-boot=tag:!gpxe,undionly.kpxe
#dhcp-boot=tag:gpxe,http://boot.ipxe.org/demo/boot.php

# Encapsulated options for Etherboot gPXE. All the options are
# encapsulated within option 175
#dhcp-option=encap:175, 1, 5b         # priority code
#dhcp-option=encap:175, 176, 1b       # no-proxydhcp
#dhcp-option=encap:175, 177, string   # bus-id
#dhcp-option=encap:175, 189, 1b       # BIOS drive code
#dhcp-option=encap:175, 190, user     # iSCSI username
#dhcp-option=encap:175, 191, pass     # iSCSI password

# Test for the architecture of a netboot client. PXE clients are
# supposed to send their architecture as option 93. (See RFC 4578)
#dhcp-match=peecees, option:client-arch, 0 #x86-32
#dhcp-match=itanics, option:client-arch, 2 #IA64
#dhcp-match=hammers, option:client-arch, 6 #x86-64
#dhcp-match=mactels, option:client-arch, 7 #EFI x86-64

# Do real PXE, rather than just booting a single file, this is an
# alternative to dhcp-boot.
#pxe-prompt="What system shall I netboot?"
# or with timeout before first available action is taken:
#pxe-prompt="Press F8 for menu.", 60

# Available boot services. for PXE.
#pxe-service=x86PC, "Boot from network", pxelinux
#pxe-service=x86PC, "Boot from local hard disk", 0

# If this line is uncommented, dnsmasq will read /etc/ethers and act
# on the ethernet-address/IP pairs found there.
#read-ethers

# Send options to hosts which ask for a DHCP lease.
# See RFC 2132 for details of available options.
# Common options can be given to dnsmasq by name:
# run "dnsmasq --help dhcp" to get a list.
# Note that all the common settings, such as netmask and
# broadcast address, DNS server and default route, are given
# sane defaults by dnsmasq. You very likely will not need
# any dhcp-options. If you use Windows clients and Samba, there
# are some options which are recommended, they are detailed at the
# end of this section.

# Override the default route supplied by dnsmasq, which assumes the
# router is the same machine as the one running dnsmasq.
#dhcp-option=3,1.2.3.4

# Do the same thing, but using the option name
#dhcp-option=option:router,1.2.3.4

# Override the default route supplied by dnsmasq and send no default
# route at all. Note that this only works for the options sent by
# default (1, 3, 6, 12, 28) the same line will send a zero-length option
# for all other option numbers.
#dhcp-option=3

# Set the NTP time server addresses to 192.168.0.4 and 10.10.0.5
#dhcp-option=option:ntp-server,192.168.0.4,10.10.0.5
EOF

    # Don't start dnsmasq automatically (it conflicts with systemd-resolved)
    systemctl disable dnsmasq 2>/dev/null || true
    
    log_success "dnsmasq configured successfully"
}

# Create DNS zones
create_dns_zones() {
    local os_type="$1"
    
    log_info "Creating example DNS zone files..."
    
    # Determine zone directory
    local zone_dir="/etc/bind/zones"
    case "$os_type" in
        centos|rhel|fedora)
            zone_dir="/var/named/zones"
            ;;
    esac
    
    mkdir -p "$zone_dir"
    
    # Create example forward zone
    cat > "$zone_dir/example.local.zone" << 'EOF'
; Example forward zone file for example.local
$TTL 86400
@       IN      SOA     ns1.example.local. admin.example.local. (
                        2024011501      ; Serial (YYYYMMDDNN)
                        3600           ; Refresh (1 hour)
                        1800           ; Retry (30 minutes)
                        604800         ; Expire (1 week)
                        86400          ; Minimum TTL (1 day)
                        )

; Name servers
                IN      NS      ns1.example.local.
                IN      NS      ns2.example.local.

; A records
ns1             IN      A       192.168.1.10
ns2             IN      A       192.168.1.11
www             IN      A       192.168.1.20
mail            IN      A       192.168.1.30
ftp             IN      A       192.168.1.40

; CNAME records
web             IN      CNAME   www
webmail         IN      CNAME   mail

; MX records
                IN      MX      10      mail.example.local.

; TXT records
                IN      TXT     "v=spf1 mx ~all"
_dmarc          IN      TXT     "v=DMARC1; p=none; rua=mailto:dmarc@example.local"

; SRV records
_http._tcp      IN      SRV     0 5 80 www.example.local.
_https._tcp     IN      SRV     0 5 443 www.example.local.
EOF

    # Create example reverse zone
    cat > "$zone_dir/192.168.1.rev" << 'EOF'
; Example reverse zone file for 192.168.1.0/24
$TTL 86400
@       IN      SOA     ns1.example.local. admin.example.local. (
                        2024011501      ; Serial
                        3600           ; Refresh
                        1800           ; Retry
                        604800         ; Expire
                        86400          ; Minimum TTL
                        )

; Name servers
                IN      NS      ns1.example.local.
                IN      NS      ns2.example.local.

; PTR records
10              IN      PTR     ns1.example.local.
11              IN      PTR     ns2.example.local.
20              IN      PTR     www.example.local.
30              IN      PTR     mail.example.local.
40              IN      PTR     ftp.example.local.
EOF

    # Set permissions
    case "$os_type" in
        ubuntu|debian)
            chown -R bind:bind "$zone_dir"
            ;;
        centos|rhel|fedora|arch)
            chown -R named:named "$zone_dir"
            ;;
    esac
    
    log_success "Example DNS zones created"
}

# Configure DNS security
configure_dns_security() {
    local os_type="$1"
    
    log_info "Configuring DNS security features..."
    
    # DNSSEC configuration is already included in the main configs
    # Additional security measures:
    
    # Create DNS security monitoring script
    cat > /usr/local/bin/dns-security-check.sh << 'EOF'
#!/bin/bash
# DNS Security Check Script

LOG_FILE="/var/log/dns-security.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] DNS security check started" >> "$LOG_FILE"

# Check for suspicious DNS queries
if [[ -f "/var/log/bind/queries.log" ]]; then
    SUSPICIOUS_QUERIES=$(grep -i -E "(malware|phishing|botnet)" /var/log/bind/queries.log 2>/dev/null | wc -l)
    if [[ $SUSPICIOUS_QUERIES -gt 0 ]]; then
        echo "[$DATE] WARNING: $SUSPICIOUS_QUERIES suspicious DNS queries detected" >> "$LOG_FILE"
    fi
fi

# Check DNS amplification attacks
if [[ -f "/var/log/bind/general.log" ]]; then
    AMPLIFICATION_ATTEMPTS=$(grep "responses dropped" /var/log/bind/general.log 2>/dev/null | wc -l)
    if [[ $AMPLIFICATION_ATTEMPTS -gt 5 ]]; then
        echo "[$DATE] WARNING: Possible DNS amplification attack - $AMPLIFICATION_ATTEMPTS responses dropped" >> "$LOG_FILE"
    fi
fi

# Check DNSSEC validation failures
if [[ -f "/var/log/bind/security.log" ]]; then
    DNSSEC_FAILURES=$(grep "DNSSEC validation failed" /var/log/bind/security.log 2>/dev/null | wc -l)
    if [[ $DNSSEC_FAILURES -gt 0 ]]; then
        echo "[$DATE] INFO: $DNSSEC_FAILURES DNSSEC validation failures" >> "$LOG_FILE"
    fi
fi

echo "[$DATE] DNS security check completed" >> "$LOG_FILE"
EOF
    
    chmod +x /usr/local/bin/dns-security-check.sh
    
    # Add to cron (every hour)
    (crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/dns-security-check.sh") | crontab -
    
    log_success "DNS security configured"
}

# Create DNS management scripts
create_dns_scripts() {
    log_info "Creating DNS management scripts..."
    
    # Create DNS manager script
    cat > /usr/local/bin/dns-manager << 'EOF'
#!/bin/bash
# DNS Management Script
# Usage: dns-manager [command] [options]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    cat << HELP

🌐 DNS Manager - Comprehensive DNS Management Tool

USAGE:
    dns-manager [command] [options]

COMMANDS:
    status          Show DNS server status
    test [domain]   Test DNS resolution
    reload          Reload DNS configuration
    restart         Restart DNS services
    zones           List configured zones
    add-zone        Add new DNS zone
    check-config    Check DNS configuration
    logs            Show DNS logs
    security        Show security status
    monitor         Real-time DNS monitoring
    flush-cache     Flush DNS cache
    help            Show this help

EXAMPLES:
    dns-manager status
    dns-manager test google.com
    dns-manager add-zone example.com
    dns-manager logs

HELP
}

show_status() {
    echo -e "${CYAN}=== DNS Server Status ===${NC}"
    
    # BIND9 status
    if systemctl is-active --quiet named 2>/dev/null || systemctl is-active --quiet bind9 2>/dev/null; then
        echo -e "${GREEN}✓${NC} BIND9 is running"
    else
        echo -e "${RED}✗${NC} BIND9 is not running"
    fi
    
    # dnsmasq status
    if systemctl is-active --quiet dnsmasq 2>/dev/null; then
        echo -e "${GREEN}✓${NC} dnsmasq is running"
    else
        echo -e "${YELLOW}○${NC} dnsmasq is not running (normal if using BIND9)"
    fi
    
    # systemd-resolved status
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo -e "${GREEN}✓${NC} systemd-resolved is running"
    else
        echo -e "${YELLOW}○${NC} systemd-resolved is not running"
    fi
    
    echo
    
    # Show listening ports
    echo -e "${BLUE}DNS Ports:${NC}"
    netstat -tuln | grep :53 || echo "No DNS ports found listening"
    echo
}

test_dns() {
    local domain="${1:-google.com}"
    
    echo -e "${CYAN}=== DNS Resolution Test ===${NC}"
    echo -e "${BLUE}Testing domain: $domain${NC}"
    echo
    
    # Test with dig
    if command -v dig >/dev/null; then
        echo -e "${YELLOW}Using dig:${NC}"
        dig +short "$domain"
        echo
        
        echo -e "${YELLOW}Detailed dig output:${NC}"
        dig "$domain"
        echo
    fi
    
    # Test with nslookup
    if command -v nslookup >/dev/null; then
        echo -e "${YELLOW}Using nslookup:${NC}"
        nslookup "$domain"
        echo
    fi
    
    # Test local resolution
    echo -e "${YELLOW}Testing localhost resolution:${NC}"
    dig @localhost "$domain" +short 2>/dev/null || echo "Localhost resolution failed"
}

reload_dns() {
    echo -e "${BLUE}Reloading DNS configuration...${NC}"
    
    # Reload BIND9
    if systemctl is-active --quiet named 2>/dev/null; then
        systemctl reload named
        echo -e "${GREEN}✓${NC} BIND9 (named) reloaded"
    elif systemctl is-active --quiet bind9 2>/dev/null; then
        systemctl reload bind9
        echo -e "${GREEN}✓${NC} BIND9 reloaded"
    fi
    
    # Reload dnsmasq
    if systemctl is-active --quiet dnsmasq 2>/dev/null; then
        systemctl reload dnsmasq
        echo -e "${GREEN}✓${NC} dnsmasq reloaded"
    fi
}

restart_dns() {
    echo -e "${BLUE}Restarting DNS services...${NC}"
    
    # Restart BIND9
    if systemctl list-unit-files | grep -q named.service; then
        systemctl restart named
        echo -e "${GREEN}✓${NC} BIND9 (named) restarted"
    elif systemctl list-unit-files | grep -q bind9.service; then
        systemctl restart bind9
        echo -e "${GREEN}✓${NC} BIND9 restarted"
    fi
}

list_zones() {
    echo -e "${CYAN}=== Configured DNS Zones ===${NC}"
    
    # Look for zone files
    local zone_dirs=("/etc/bind/zones" "/var/named/zones" "/etc/bind" "/var/named")
    
    for dir in "${zone_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "${BLUE}Zone files in $dir:${NC}"
            find "$dir" -name "*.zone" -o -name "*.rev" 2>/dev/null | while read -r file; do
                echo "  $(basename "$file")"
            done
            echo
        fi
    done
    
    # Show configured zones from named.conf
    if [[ -f "/etc/bind/named.conf.local" ]]; then
        echo -e "${BLUE}Zones from named.conf.local:${NC}"
        grep -E "^zone" /etc/bind/named.conf.local 2>/dev/null || echo "No zones found"
    elif [[ -f "/etc/named.conf" ]]; then
        echo -e "${BLUE}Zones from named.conf:${NC}"
        grep -E "^zone" /etc/named.conf 2>/dev/null || echo "No zones found"
    fi
}

check_config() {
    echo -e "${CYAN}=== DNS Configuration Check ===${NC}"
    
    # Check BIND9 configuration
    if command -v named-checkconf >/dev/null; then
        echo -e "${BLUE}Checking BIND9 configuration:${NC}"
        if named-checkconf; then
            echo -e "${GREEN}✓${NC} BIND9 configuration is valid"
        else
            echo -e "${RED}✗${NC} BIND9 configuration has errors"
        fi
        echo
    fi
    
    # Check zone files
    if command -v named-checkzone >/dev/null; then
        echo -e "${BLUE}Checking zone files:${NC}"
        local zone_dirs=("/etc/bind/zones" "/var/named/zones")
        
        for dir in "${zone_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -name "*.zone" 2>/dev/null | while read -r file; do
                    zone_name=$(basename "$file" .zone)
                    if named-checkzone "$zone_name" "$file" >/dev/null 2>&1; then
                        echo -e "  ${GREEN}✓${NC} $zone_name"
                    else
                        echo -e "  ${RED}✗${NC} $zone_name"
                    fi
                done
            fi
        done
        echo
    fi
}

show_logs() {
    echo -e "${CYAN}=== DNS Logs ===${NC}"
    
    # BIND9 logs
    local log_files=(
        "/var/log/bind/general.log"
        "/var/log/bind/queries.log"
        "/var/log/bind/security.log"
        "/var/log/named/general.log"
        "/var/log/syslog"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            echo -e "${BLUE}Recent entries from $log_file:${NC}"
            tail -10 "$log_file" 2>/dev/null
            echo
            break
        fi
    done
}

flush_cache() {
    echo -e "${BLUE}Flushing DNS cache...${NC}"
    
    # Flush systemd-resolved cache
    if command -v resolvectl >/dev/null; then
        resolvectl flush-caches
        echo -e "${GREEN}✓${NC} systemd-resolved cache flushed"
    fi
    
    # Restart dnsmasq to flush cache
    if systemctl is-active --quiet dnsmasq 2>/dev/null; then
        systemctl restart dnsmasq
        echo -e "${GREEN}✓${NC} dnsmasq cache flushed"
    fi
}

monitor_realtime() {
    echo -e "${CYAN}=== Real-time DNS Monitoring ===${NC}"
    echo "Press Ctrl+C to stop..."
    echo
    
    # Monitor DNS logs
    local log_files=(
        "/var/log/bind/queries.log"
        "/var/log/bind/general.log"
        "/var/log/named/general.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            tail -f "$log_file"
            break
        fi
    done
}

# Main command handler
case "${1:-help}" in
    status)
        show_status
        ;;
    test)
        test_dns "$2"
        ;;
    reload)
        reload_dns
        ;;
    restart)
        restart_dns
        ;;
    zones)
        list_zones
        ;;
    check-config)
        check_config
        ;;
    logs)
        show_logs
        ;;
    flush-cache)
        flush_cache
        ;;
    monitor)
        monitor_realtime
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/dns-manager
    
    # Create quick DNS status script
    cat > /usr/local/bin/dns-status << 'EOF'
#!/bin/bash
# Quick DNS status check
/usr/local/bin/dns-manager status
EOF
    
    chmod +x /usr/local/bin/dns-status
    
    log_success "DNS management scripts created successfully"
}

# Enable and start DNS services
enable_dns_services() {
    local os_type="$1"
    
    log_info "Enabling and starting DNS services..."
    
    case "$os_type" in
        ubuntu|debian)
            # BIND9
            systemctl enable bind9
            systemctl start bind9
            
            # Don't enable dnsmasq by default (conflicts with systemd-resolved)
            # systemctl enable dnsmasq
            # systemctl start dnsmasq
            ;;
        centos|rhel|fedora)
            # BIND9 (named)
            systemctl enable named
            systemctl start named
            
            # Don't enable dnsmasq by default
            # systemctl enable dnsmasq
            # systemctl start dnsmasq
            ;;
        arch)
            # BIND9 (named)
            systemctl enable named
            systemctl start named
            ;;
    esac
    
    log_success "DNS services enabled and started"
}

# Verify DNS setup
verify_dns_setup() {
    local os_type="$1"
    
    log_info "Verifying DNS configuration..."
    
    # Check BIND9 status
    local bind_service="bind9"
    case "$os_type" in
        centos|rhel|fedora|arch)
            bind_service="named"
            ;;
    esac
    
    if systemctl is-active --quiet "$bind_service"; then
        log_success "BIND9 ($bind_service) is running"
        
        # Test DNS resolution
        if command -v dig >/dev/null; then
            if dig @localhost google.com >/dev/null 2>&1; then
                log_success "DNS resolution test passed"
            else
                log_warning "DNS resolution test failed"
            fi
        fi
        
        # Check configuration
        if command -v named-checkconf >/dev/null; then
            if named-checkconf >/dev/null 2>&1; then
                log_success "BIND9 configuration is valid"
            else
                log_warning "BIND9 configuration has issues"
            fi
        fi
    else
        log_warning "BIND9 ($bind_service) is not running"
    fi
    
    # Check if management scripts are executable
    if [[ -x "/usr/local/bin/dns-manager" ]]; then
        log_success "DNS management script installed"
    fi
    
    # Show listening ports
    log_info "DNS server is listening on:"
    netstat -tuln | grep :53 || log_warning "No DNS ports found listening"
    
    log_success "DNS verification completed"
}

# Module-specific functions can be called individually
case "${1:-}" in
    configure_bind9)
        configure_bind9 "${2:-ubuntu}"
        ;;
    configure_dnsmasq)
        configure_dnsmasq "${2:-ubuntu}"
        ;;
    *)
        # Default: run full installation if sourced
        if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
            echo "DNS module - use install_dns_module function"
        fi
        ;;
esac
