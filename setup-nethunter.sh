
#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# ROOTLESS KALI NETHUNTER COMPLETE SETUP
# ==========================================

# Colors must be defined BEFORE first use
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================
# Logging Functions
# ==========================================

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ==========================================
# Error Handling
# ==========================================

trap 'error "Setup failed at line $LINENO. Command: $BASH_COMMAND"' ERR

# ==========================================
# Root Detection
# ==========================================

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} ROOTLESS KALI NETHUNTER COMPLETE SETUP${NC}"
echo -e "${BLUE}==========================================${NC}"

if [ "$EUID" -eq 0 ]; then
    SUDO=()
    KALI_HOME="${SUDO_HOME:-/root}"
else
    if ! command -v sudo >/dev/null 2>&1; then
        error "Root or sudo access required."
        exit 1
    fi

    SUDO=(sudo)
    KALI_HOME="$HOME"
fi

# ==========================================
# 1. Update and Upgrade
# ==========================================

echo -e "\n${BLUE}1. Update and Upgrade${NC}"

info "Updating Kali repositories..."
"${SUDO[@]}" apt update

info "Upgrading Kali packages..."
"${SUDO[@]}" apt upgrade -y

success "System update completed."

# ==========================================
# 2. Install Metasploit Framework
# ==========================================

echo -e "\n${BLUE}2. Install Metasploit Framework${NC}"

info "Installing Metasploit Framework..."
"${SUDO[@]}" apt install -y metasploit-framework

success "Metasploit Framework installed."

# ==========================================
# 3. Initialize Metasploit Database
# ==========================================

echo -e "\n${BLUE}3. Initialize Metasploit Database${NC}"

info "Initializing Metasploit database..."

"${SUDO[@]}" msfdb init

success "Metasploit database initialized."

# ==========================================
# 4. Install BeEF Dependencies
# ==========================================

echo -e "\n${BLUE}4. Install BeEF Dependencies${NC}"

PACKAGES=(
    ruby-msgpack
    ruby-dev
    build-essential
    libsqlite3-dev
    bundler
    pkg-config
    libyaml-dev
    libssl-dev
    git
)

info "Installing required packages..."

"${SUDO[@]}" apt install -y "${PACKAGES[@]}"

success "Dependencies installed."

# ==========================================
# 5. Install Ruby Gems
# ==========================================

echo -e "\n${BLUE}5. Install Ruby Gems${NC}"

info "Installing eventmachine..."
"${SUDO[@]}" gem install eventmachine

success "eventmachine installed."

info "Installing test-unit-full..."
"${SUDO[@]}" gem install test-unit-full -v 0.0.5

success "test-unit-full installed."

# ==========================================
# 6. Install BeEF-XSS
# ==========================================

echo -e "\n${BLUE}6. Install BeEF-XSS${NC}"

info "Installing BeEF-XSS..."

"${SUDO[@]}" apt install -y beef-xss

success "BeEF-XSS installed."

# ==========================================
# 7. Configure BeEF Bundler
# ==========================================

echo -e "\n${BLUE}7. Configure BeEF Bundler${NC}"

BEEF_DIR="/usr/share/beef-xss"

if [ -d "$BEEF_DIR" ]; then

    cd "$BEEF_DIR"

    info "Checking Bundler frozen configuration..."

    if "${SUDO[@]}" bundle config get frozen 2>/dev/null |
        grep -qi 'true'; then

        "${SUDO[@]}" bundle config unset frozen
        success "Bundler frozen mode disabled."
    else
        success "Bundler frozen mode is not enabled."
    fi

    info "Installing BeEF dependencies..."

    "${SUDO[@]}" bundle install

    success "BeEF dependencies installed."

else
    warning "BeEF directory not found. Skipping Bundler configuration."
fi

# ==========================================
# 8. Download Repository Sources
# ==========================================

echo -e "\n${BLUE}8. Download Repository Sources${NC}"

info "Creating /opt directory..."

"${SUDO[@]}" mkdir -p /opt

# The Backdoor Factory source inspection only
if [ -d "/opt/the-backdoor-factory/.git" ]; then

    info "The Backdoor Factory already exists."

else

    if [ -e "/opt/the-backdoor-factory" ]; then
        error "Existing non-Git directory found at /opt/the-backdoor-factory."
        exit 1
    fi

    info "Downloading The Backdoor Factory source..."

    "${SUDO[@]}" git clone --depth 1 \
        https://github.com/secretsquirrel/the-backdoor-factory.git \
        /opt/the-backdoor-factory

    success "The Backdoor Factory source downloaded."

fi

# ==========================================
# 9. Final Status
# ==========================================

cd "$KALI_HOME"

echo
echo -e "${GREEN}==========================================${NC}"
success "NetHunter Setup Completed!"
echo -e "${GREEN}==========================================${NC}"
echo

