#!/bin/bash
# =============================================================================
# System Detection and Utility Functions Library
# =============================================================================

# System check functions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID,,}" in
            ubuntu|debian)
                echo "debian"
                ;;
            centos|rhel|rocky|almalinux|fedora)
                echo "rhel"
                ;;
            arch|manjaro)
                echo "arch"
                ;;
            opensuse*|sles)
                echo "opensuse"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

get_package_manager() {
    local os_type="$1"
    case "$os_type" in
        "debian")
            echo "apt"
            ;;
        "rhel")
            if command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        "arch")
            echo "pacman"
            ;;
        "opensuse")
            echo "zypper"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if service is active
service_is_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

# Check if service is enabled
service_is_enabled() {
    systemctl is-enabled --quiet "$1" 2>/dev/null
}

# Wait for service to start
wait_for_service() {
    local service="$1"
    local timeout="${2:-30}"
    local counter=0
    
    log_info "Waiting for $service to start..."
    
    while [[ $counter -lt $timeout ]]; do
        if service_is_active "$service"; then
            log_success "$service is now active"
            return 0
        fi
        sleep 1
        ((counter++))
    done
    
    log_warning "$service failed to start within ${timeout}s"
    return 1
}

# Get system information
get_system_info() {
    local os_type="$1"
    
    echo "OS Type: $os_type"
    echo "Architecture: $(uname -m)"
    echo "Kernel: $(uname -r)"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "Distribution: $NAME $VERSION"
    fi
    
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "CPU Cores: $(nproc)"
}

# Validate internet connection
check_internet() {
    local test_urls=("8.8.8.8" "1.1.1.1" "google.com")
    
    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 2 "$url" >/dev/null 2>&1; then
            return 0
        fi
    done
    
    log_error "No internet connection available"
    return 1
}

# Get available disk space in bytes
get_available_space() {
    local path="${1:-/}"
    df -B1 "$path" | awk 'NR==2 {print $4}'
}

# Convert bytes to human readable format
bytes_to_human() {
    local bytes="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $bytes -gt 1024 && $unit -lt $((${#units[@]} - 1)) ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[unit]}"
}

# Check minimum disk space requirement
check_disk_space() {
    local required_bytes="${1:-1073741824}"  # Default 1GB
    local path="${2:-/}"
    
    local available=$(get_available_space "$path")
    
    if [[ $available -lt $required_bytes ]]; then
        log_error "Insufficient disk space. Required: $(bytes_to_human $required_bytes), Available: $(bytes_to_human $available)"
        return 1
    fi
    
    log_info "Disk space check passed. Available: $(bytes_to_human $available)"
    return 0
}
