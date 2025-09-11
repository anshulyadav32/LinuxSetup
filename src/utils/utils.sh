#!/bin/bash
# =============================================================================
# Common Utility Functions for All Modules
# =============================================================================
log_header() { echo -e "\n========== $1 ==========\n"; }
log_step() { echo "[Step $1/$2] $3"; }
log_success() { echo "[32m[1m✔ $1[0m"; }
log_error() { echo "[31m[1m✖ $1[0m" >&2; }
log_warning() { echo "[33m[1m⚠️ $1[0m"; }
log_info() { echo "[36m[1mℹ️ $1[0m"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

install_packages() {
    local pkg_mgr="$1"; shift
    case "$pkg_mgr" in
        apt) apt-get update -qq && apt-get install -y -qq "$@" ;;
        dnf|yum) $pkg_mgr install -y -q "$@" ;;
        pacman) pacman -Sy --noconfirm --quiet "$@" ;;
    esac
}
