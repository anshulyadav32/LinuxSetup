#!/bin/bash
# =============================================================================
# Colors and Text Formatting Library
# =============================================================================

# Color definitions (only set if not already defined)
[[ -z "${RED:-}" ]] && readonly RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && readonly YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && readonly BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && readonly CYAN='\033[0;36m'
[[ -z "${PURPLE:-}" ]] && readonly PURPLE='\033[0;35m'
[[ -z "${WHITE:-}" ]] && readonly WHITE='\033[1;37m'
[[ -z "${NC:-}" ]] && readonly NC='\033[0m' # No Color

# Text formatting (only set if not already defined)
[[ -z "${BOLD:-}" ]] && readonly BOLD='\033[1m'
[[ -z "${DIM:-}" ]] && readonly DIM='\033[2m'
[[ -z "${UNDERLINE:-}" ]] && readonly UNDERLINE='\033[4m'
[[ -z "${BLINK:-}" ]] && readonly BLINK='\033[5m'
[[ -z "${REVERSE:-}" ]] && readonly REVERSE='\033[7m'
[[ -z "${STRIKETHROUGH:-}" ]] && readonly STRIKETHROUGH='\033[9m'
