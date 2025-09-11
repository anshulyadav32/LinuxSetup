#!/bin/bash
# =============================================================================
# Development Environment Setup Module
# Node.js, Git, GitHub CLI, Python, Package Managers, and Dev Tools
# =============================================================================
source ../utils.sh

dev_install() {
    local os_type="$1"
    local pkg_mgr="$2"
    log_header "Installing Development Environment ($os_type / $pkg_mgr)..."
    
    # Install basic development tools
    case "$pkg_mgr" in
        apt)
            # Add necessary repositories
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            
            # Update package lists
            apt-get update
            
            # Install development tools
            install_packages apt \
                git \
                gh \
                nodejs \
                npm \
                python3 \
                python3-pip \
                python3-venv \
                build-essential \
                gcc \
                g++ \
                make \
                curl \
                wget \
                unzip \
                vim \
                docker.io \
                docker-compose
            ;;
            
        dnf|yum)
            # Add repositories
            curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo | tee /etc/yum.repos.d/gh-cli.repo
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            
            # Install development tools
            install_packages "$pkg_mgr" \
                git \
                gh \
                nodejs \
                npm \
                python3 \
                python3-pip \
                gcc \
                gcc-c++ \
                make \
                curl \
                wget \
                unzip \
                vim \
                docker \
                docker-compose
            ;;
            
        pacman)
            # Update package database
            pacman -Sy
            
            # Install development tools
            install_packages pacman \
                git \
                github-cli \
                nodejs \
                npm \
                python \
                python-pip \
                base-devel \
                gcc \
                curl \
                wget \
                unzip \
                vim \
                docker \
                docker-compose
            ;;
    esac
    
    # Enable and start Docker service
    systemctl enable docker
    systemctl start docker
    
    # Install global Node.js packages
    log_info "Installing global Node.js packages..."
    npm install -g \
        yarn \
        pm2 \
        typescript \
        ts-node \
        nodemon \
        @angular/cli \
        @vue/cli \
        create-react-app \
        eslint \
        prettier
    
    # Install Python packages
    log_info "Installing Python packages..."
    pip3 install --upgrade \
        pip \
        virtualenv \
        pipenv \
        poetry \
        pylint \
        black \
        pytest
    
    # Configure Git
    log_info "Configuring Git..."
    git config --global init.defaultBranch main
    git config --global core.editor "vim"
    git config --global pull.rebase false
    
    # Add current user to docker group
    usermod -aG docker "$(whoami)" 2>/dev/null || true
    
    log_success "Development environment setup complete"
}

dev_test() {
    log_header "Testing Development Environment..."
    local status=0
    
    # Test Git and GitHub CLI
    if command_exists git; then
        log_success "Git $(git --version) is available"
    else
        log_error "Git is not available"
        status=1
    fi
    
    if command_exists gh; then
        log_success "GitHub CLI $(gh --version) is available"
    else
        log_error "GitHub CLI is not available"
        status=1
    fi
    
    # Test Node.js and package managers
    if command_exists node; then
        log_success "Node.js $(node --version) is available"
    else
        log_error "Node.js is not available"
        status=1
    fi
    
    if command_exists npm; then
        log_success "npm $(npm --version) is available"
    else
        log_error "npm is not available"
        status=1
    fi
    
    if command_exists yarn; then
        log_success "yarn $(yarn --version) is available"
    else
        log_error "yarn is not available"
        status=1
    fi
    
    # Test Python and package managers
    if command_exists python3; then
        log_success "Python $(python3 --version) is available"
    else
        log_error "Python3 is not available"
        status=1
    fi
    
    if command_exists pip3; then
        log_success "pip3 $(pip3 --version) is available"
    else
        log_error "pip3 is not available"
        status=1
    fi
    
    # Test Docker
    if command_exists docker; then
        log_success "Docker $(docker --version) is available"
        if systemctl is-active --quiet docker; then
            log_success "Docker service is running"
        else
            log_error "Docker service is not running"
            status=1
        fi
    else
        log_error "Docker is not available"
        status=1
    fi
    
    # Test global tools
    local tools=(typescript ts-node nodemon ng vue create-react-app eslint prettier pylint black pytest)
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            log_success "$tool is available"
        else
            log_error "$tool is not available"
            status=1
        fi
    done
    
    # Test development user setup
    if groups "$(whoami)" | grep -q docker; then
        log_success "User is in docker group"
    else
        log_warning "User is not in docker group - you may need to log out and back in"
    fi
    
    return $status
}

# Export module functions
export -f dev_install
export -f dev_test
