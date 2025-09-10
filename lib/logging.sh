#!/bin/bash
# =============================================================================
# Logging Functions Library
# =============================================================================

# Source colors if available
[[ -f "${SCRIPT_DIR:-}/lib/colors.sh" ]] && source "${SCRIPT_DIR:-}/lib/colors.sh"

# Global logging variables
LOG_DIR="${LOG_DIR:-/var/log/linux-setup}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/singlem-$(date +%Y%m%d_%H%M%S).log}"

# Ensure log directory exists
ensure_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || true
    fi
}

# Logging functions
log_header() {
    echo -e "\n${CYAN}================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================${NC}\n"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [HEADER] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

log_step() {
    echo -e "\n${YELLOW}► Step $1/$2: $3${NC}"
    [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [STEP] $1/$2: $3" >> "$LOG_FILE"
}

log_debug() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        echo -e "${DIM}[DEBUG]${NC} $1"
        [[ -f "$LOG_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" >> "$LOG_FILE"
    fi
}

# Initialize logging
init_logging() {
    ensure_log_dir
    if [[ -w "$LOG_DIR" ]]; then
        touch "$LOG_FILE" 2>/dev/null || {
            LOG_FILE="/tmp/singlem-$(date +%Y%m%d_%H%M%S).log"
            log_warning "Cannot write to $LOG_DIR, using $LOG_FILE"
        }
    else
        LOG_FILE="/tmp/singlem-$(date +%Y%m%d_%H%M%S).log"
    fi
}
