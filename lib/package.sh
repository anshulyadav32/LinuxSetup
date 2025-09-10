#!/bin/bash
# =============================================================================
# Package Management Functions Library
# =============================================================================

# System update function
update_system() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_step "1" "10" "Updating system packages"
    
    case "$pkg_mgr" in
        "apt")
            apt-get update -qq
            DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
            ;;
        "dnf"|"yum")
            $pkg_mgr update -y -q
            ;;
        "pacman")
            pacman -Syu --noconfirm --quiet
            ;;
        "zypper")
            zypper refresh
            zypper update -y
            ;;
        *)
            log_warning "Unknown package manager, skipping system update"
            return 1
            ;;
    esac
    
    log_success "System packages updated"
}

# Install common dependencies
install_common_dependencies() {
    local os_type="$1"
    local pkg_mgr="$2"
    
    log_step "2" "10" "Installing common dependencies"
    
    local common_packages=""
    
    case "$pkg_mgr" in
        "apt")
            common_packages="curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release build-essential"
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $common_packages
            ;;
        "dnf"|"yum")
            common_packages="curl wget gnupg2 ca-certificates gcc gcc-c++ make"
            $pkg_mgr install -y -q $common_packages
            ;;
        "pacman")
            common_packages="curl wget gnupg ca-certificates base-devel"
            pacman -S --noconfirm --quiet $common_packages
            ;;
        "zypper")
            common_packages="curl wget gpg2 ca-certificates gcc gcc-c++ make"
            zypper install -y $common_packages
            ;;
        *)
            log_warning "Unknown package manager, skipping common dependencies"
            return 1
            ;;
    esac
    
    log_success "Common dependencies installed"
}

# Install packages with error handling
install_packages() {
    local pkg_mgr="$1"
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warning "No packages specified for installation"
        return 1
    fi
    
    log_info "Installing packages: ${packages[*]}"
    
    case "$pkg_mgr" in
        "apt")
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}"
            ;;
        "dnf"|"yum")
            $pkg_mgr install -y -q "${packages[@]}"
            ;;
        "pacman")
            pacman -S --noconfirm --quiet "${packages[@]}"
            ;;
        "zypper")
            zypper install -y "${packages[@]}"
            ;;
        *)
            log_error "Unknown package manager: $pkg_mgr"
            return 1
            ;;
    esac
    
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log_success "Packages installed successfully"
    else
        log_error "Failed to install packages"
        return $exit_code
    fi
}

# Check if package is installed
is_package_installed() {
    local pkg_mgr="$1"
    local package="$2"
    
    case "$pkg_mgr" in
        "apt")
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        "dnf"|"yum")
            $pkg_mgr list installed "$package" >/dev/null 2>&1
            ;;
        "pacman")
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        "zypper")
            zypper search -i "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Add repository
add_repository() {
    local os_type="$1"
    local pkg_mgr="$2"
    local repo_info="$3"
    
    case "$pkg_mgr" in
        "apt")
            # repo_info should be like "ppa:ondrej/php" or a full repository line
            if [[ $repo_info =~ ^ppa: ]]; then
                add-apt-repository -y "$repo_info"
            else
                echo "$repo_info" >> /etc/apt/sources.list.d/custom.list
            fi
            apt-get update -qq
            ;;
        "dnf"|"yum")
            # repo_info should be a .repo file content or URL
            if [[ $repo_info =~ ^https?:// ]]; then
                $pkg_mgr config-manager --add-repo "$repo_info"
            else
                echo "$repo_info" > /etc/yum.repos.d/custom.repo
            fi
            ;;
        "pacman")
            log_warning "Manual repository addition required for Arch Linux"
            ;;
        *)
            log_error "Repository addition not supported for $pkg_mgr"
            return 1
            ;;
    esac
}

# Clean package cache
clean_package_cache() {
    local pkg_mgr="$1"
    
    log_info "Cleaning package cache..."
    
    case "$pkg_mgr" in
        "apt")
            apt-get autoremove -y -qq
            apt-get autoclean -qq
            ;;
        "dnf"|"yum")
            $pkg_mgr autoremove -y -q
            $pkg_mgr clean all -q
            ;;
        "pacman")
            pacman -Sc --noconfirm
            ;;
        "zypper")
            zypper clean
            ;;
        *)
            log_warning "Cache cleaning not supported for $pkg_mgr"
            return 1
            ;;
    esac
    
    log_success "Package cache cleaned"
}
