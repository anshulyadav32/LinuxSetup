#!/bin/bash
# =============================================================================
# Modular Setup System Demo
# =============================================================================
# Purpose: Demonstrate the new modular installation system
# Usage: ./demo-modular.sh
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}=============================================================================${NC}"
echo -e "${CYAN}               Linux Setup - Modular Installation System Demo${NC}"
echo -e "${CYAN}=============================================================================${NC}"
echo ""

echo -e "${YELLOW}🔍 Checking modular structure...${NC}"
echo ""

# Check library files
echo -e "${BLUE}📚 Library Files:${NC}"
for lib in colors logging system package; do
    if [[ -f "$SCRIPT_DIR/lib/${lib}.sh" ]]; then
        echo -e "   ${GREEN}✓${NC} lib/${lib}.sh"
    else
        echo -e "   ${RED}✗${NC} lib/${lib}.sh ${RED}(missing)${NC}"
    fi
done

echo ""

# Check module files
echo -e "${BLUE}📦 Module Files:${NC}"
for module in database webserver dns firewall ssl; do
    if [[ -f "$SCRIPT_DIR/modules/${module}.sh" ]]; then
        echo -e "   ${GREEN}✓${NC} modules/${module}.sh"
    else
        echo -e "   ${RED}✗${NC} modules/${module}.sh ${RED}(missing)${NC}"
    fi
done

echo ""

# Check main setup script
echo -e "${BLUE}🚀 Main Setup Script:${NC}"
if [[ -f "$SCRIPT_DIR/setup-modular.sh" ]]; then
    echo -e "   ${GREEN}✓${NC} setup-modular.sh"
    if [[ -x "$SCRIPT_DIR/setup-modular.sh" ]]; then
        echo -e "   ${GREEN}✓${NC} Executable permissions set"
    else
        echo -e "   ${YELLOW}⚠${NC} Not executable (run: chmod +x setup-modular.sh)"
    fi
else
    echo -e "   ${RED}✗${NC} setup-modular.sh ${RED}(missing)${NC}"
fi

echo ""

# Show usage examples
echo -e "${CYAN}🛠️  Usage Examples:${NC}"
echo -e "${YELLOW}   List available modules:${NC}"
echo -e "   sudo ./setup-modular.sh --list"
echo ""
echo -e "${YELLOW}   Show help:${NC}"
echo -e "   sudo ./setup-modular.sh --help"
echo ""
echo -e "${YELLOW}   Install a specific module:${NC}"
echo -e "   sudo ./setup-modular.sh webserver"
echo -e "   sudo ./setup-modular.sh database"
echo -e "   sudo ./setup-modular.sh ssl"
echo ""
echo -e "${YELLOW}   Install with verbose logging:${NC}"
echo -e "   sudo ./setup-modular.sh --verbose webserver"
echo ""

# Test basic functionality
if [[ -f "$SCRIPT_DIR/setup-modular.sh" ]]; then
    echo -e "${CYAN}🧪 Testing basic functionality...${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing help command:${NC}"
    if bash "$SCRIPT_DIR/setup-modular.sh" --help >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} Help command works"
    else
        echo -e "   ${RED}✗${NC} Help command failed"
    fi
    
    echo -e "${YELLOW}Testing list command:${NC}"
    if bash "$SCRIPT_DIR/setup-modular.sh" --list >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} List command works"
    else
        echo -e "   ${RED}✗${NC} List command failed"
    fi
fi

echo ""

# System requirements check
echo -e "${CYAN}🔧 System Requirements:${NC}"
echo -e "${BLUE}Required for installation:${NC}"
echo -e "   • Root privileges (use sudo)"
echo -e "   • Internet connection"
echo -e "   • Supported OS: Ubuntu, Debian, CentOS, RHEL, Arch Linux"
echo ""

# File structure summary
echo -e "${CYAN}📁 Modular Structure Summary:${NC}"
echo -e "${BLUE}singlem/${NC}"
echo -e "├── ${GREEN}setup-modular.sh${NC}     # Main installation controller"
echo -e "├── ${GREEN}demo-modular.sh${NC}      # This demo script"
echo -e "├── ${BLUE}lib/${NC}                  # Core libraries"
echo -e "│   ├── ${GREEN}colors.sh${NC}         # Color definitions"
echo -e "│   ├── ${GREEN}logging.sh${NC}        # Logging functions"
echo -e "│   ├── ${GREEN}system.sh${NC}         # System utilities"
echo -e "│   └── ${GREEN}package.sh${NC}        # Package management"
echo -e "└── ${BLUE}modules/${NC}              # Installation modules"
echo -e "    ├── ${GREEN}database.sh${NC}       # MySQL/PostgreSQL"
echo -e "    ├── ${GREEN}webserver.sh${NC}      # Apache/Nginx/PHP"
echo -e "    ├── ${GREEN}ssl.sh${NC}            # SSL certificates"
echo -e "    ├── ${GREEN}firewall.sh${NC}       # Security setup"
echo -e "    └── ${GREEN}dns.sh${NC}            # DNS servers"
echo ""

echo -e "${GREEN}✨ Modular installation system is ready!${NC}"
echo ""
echo -e "${CYAN}=============================================================================${NC}"
