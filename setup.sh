#!/usr/bin/env bash
#
# Dotfiles Setup Script
# Supports: Arch Linux and FreeBSD
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
detect_os() {
    if [[ -f /etc/arch-release ]]; then
        OS="arch"
        info "Detected Arch Linux"
    elif [[ "$(uname)" == "FreeBSD" ]]; then
        OS="freebsd"
        info "Detected FreeBSD"
    else
        error "Unsupported operating system"
        exit 1
    fi
}

# Check if command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Check if package is installed
pkg_installed() {
    local pkg="$1"
    case "$OS" in
        arch)
            pacman -Qi "$pkg" &>/dev/null
            ;;
        freebsd)
            pkg info "$pkg" &>/dev/null
            ;;
    esac
}

# Install packages
install_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            to_install+=("$pkg")
        else
            success "$pkg already installed"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing: ${to_install[*]}"
        case "$OS" in
            arch)
                sudo pacman -S --needed --noconfirm "${to_install[@]}"
                ;;
            freebsd)
                sudo pkg install -y "${to_install[@]}"
                ;;
        esac
    fi
}

# Install AUR packages (Arch only)
install_aur() {
    if [[ "$OS" != "arch" ]]; then
        return
    fi

    local packages=("$@")
    local to_install=()
    local aur_helper=""

    # Find AUR helper
    if cmd_exists yay; then
        aur_helper="yay"
    elif cmd_exists paru; then
        aur_helper="paru"
    else
        warn "No AUR helper found. Installing yay..."
        install_yay
        aur_helper="yay"
    fi

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            to_install+=("$pkg")
        else
            success "$pkg already installed (AUR)"
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing from AUR: ${to_install[*]}"
        $aur_helper -S --needed --noconfirm "${to_install[@]}"
    fi
}

# Install yay AUR helper
install_yay() {
    if cmd_exists yay; then
        return
    fi
    info "Installing yay AUR helper..."
    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd - >/dev/null
    rm -rf "$tmpdir"
    success "yay installed"
}

# Install rustup if not present
install_rustup() {
    if cmd_exists rustup; then
        success "rustup already installed"
        return
    fi

    info "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Source cargo env for current session
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi

    if cmd_exists rustup; then
        success "rustup installed"
    else
        warn "rustup installation may require shell restart"
    fi
}

# Setup Rust toolchain
setup_rust() {
    # Install rustup if needed
    install_rustup

    # Check if rustup exists
    if ! cmd_exists rustup; then
        warn "rustup not found, skipping Rust setup"
        return
    fi

    info "Setting up Rust toolchain..."

    # Check if stable toolchain is installed
    if ! rustup toolchain list | grep -q "stable"; then
        info "Installing stable Rust toolchain..."
        rustup default stable
    else
        success "Rust stable toolchain installed"
    fi

    # Ensure stable is default
    rustup default stable 2>/dev/null || true

    # Install rust-analyzer component
    if rustup component list | grep -q "rust-analyzer.*installed"; then
        success "rust-analyzer installed"
    else
        info "Installing rust-analyzer..."
        rustup component add rust-analyzer
    fi

    # Install common components
    local components=(
        clippy        # Linter
        rustfmt       # Formatter
    )

    for component in "${components[@]}"; do
        if rustup component list | grep -q "$component.*installed"; then
            success "$component installed"
        else
            info "Installing $component..."
            rustup component add "$component"
        fi
    done

    # Install cargo tools
    local cargo_tools=(
        cargo-watch      # File watcher
        cargo-edit       # Cargo add/rm/upgrade
        cargo-audit      # Security vulnerability scanner
        cargo-tarpaulin  # Code coverage
    )

    for tool in "${cargo_tools[@]}"; do
        if cargo install --list | grep -q "^$tool "; then
            success "$tool installed (cargo)"
        else
            info "Installing $tool via cargo..."
            cargo install "$tool"
        fi
    done
}

# NPM global packages for LSP servers
declare -a NPM_PACKAGES=(
    typescript
    typescript-language-server
    @tailwindcss/language-server
    vscode-langservers-extracted  # html, css, json, eslint
    yaml-language-server
)

# Setup npm global packages
setup_npm_packages() {
    if ! cmd_exists npm; then
        warn "npm not found, skipping LSP server installation"
        return
    fi

    info "Installing npm global packages (LSP servers)..."

    for pkg in "${NPM_PACKAGES[@]}"; do
        if npm list -g "$pkg" &>/dev/null; then
            success "$pkg already installed (npm)"
        else
            info "Installing $pkg..."
            sudo npm install -g "$pkg"
        fi
    done
}

# Detect or prompt for versioned FreeBSD package
# Usage: detect_versioned_pkg "php" "83 84 85"
detect_versioned_pkg() {
    local name="$1"
    local versions="$2"

    # Check if already installed
    for ver in $versions; do
        if pkg_installed "${name}${ver}"; then
            echo "${name}${ver}"
            return 0
        fi
    done

    # Not installed - prompt user
    warn "No ${name} version detected"
    echo "Available versions:"
    local i=1
    local opts=()
    for ver in $versions; do
        echo "  ${i}) ${name}${ver}"
        opts+=("${name}${ver}")
        ((i++))
    done
    echo "  s) Skip ${name} installation"

    local choice
    read -rp "Select ${name} version [1-${#opts[@]}/s]: " choice

    if [[ "$choice" == "s" ]]; then
        info "Skipping ${name}"
        return 1
    fi

    if [[ "$choice" -ge 1 && "$choice" -le ${#opts[@]} ]] 2>/dev/null; then
        echo "${opts[$((choice-1))]}"
        return 0
    else
        warn "Invalid choice, skipping ${name}"
        return 1
    fi
}

# Setup PHP and Python on FreeBSD (versioned packages)
setup_freebsd_versioned_pkgs() {
    echo ""
    info "Setting up PHP..."
    local php_pkg
    if php_pkg=$(detect_versioned_pkg "php" "84 85"); then
        local php_ver="${php_pkg#php}"
        install_packages "$php_pkg" "php${php_ver}-composer"
        success "Installed ${php_pkg} with composer"
    fi

    echo ""
    info "Setting up Python..."
    local py_pkg
    if py_pkg=$(detect_versioned_pkg "python" "311 312 313"); then
        local py_ver="${py_pkg#python}"
        install_packages "$py_pkg" "py${py_ver}-flake8"
        success "Installed ${py_pkg} with flake8"
    fi
}

# Main package lists
declare -a ARCH_PACMAN_PKGS=(
    # Terminal & Shell
    kitty
    ghostty
    bash
    starship

    # Editor
    neovim

    # Hyprland ecosystem
    hyprland
    hyprlock
    hyprpaper
    hyprpicker
    waybar
    wofi
    hypridle

    # Notifications
    dunst

    # CLI tools
    fzf
    fd
    ripgrep
    git
    git-delta
    github-cli
    git-lfs
    wl-clipboard
    copyq
    imagemagick
    brightnessctl
    grim
    slurp
    wf-recorder
    gromit-mpx

    # Audio
    pipewire
    wireplumber
    pamixer
    playerctl
    pavucontrol
    libcanberra

    # Network
    networkmanager
    nm-connection-editor

    # Development
    rustup
    nodejs
    npm
    php
    composer
    python
    python-flake8
    shellcheck
    shfmt
    lua-language-server

    # LazyVim requirements
    curl
    gcc
    make
    tree-sitter-cli
    lazygit

    # Go toolchain (gopls installed via go)
    go
    gopls

    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-iosevka-nerd
    ttf-font-awesome
    noto-fonts-cjk

    # System integration
    polkit-kde-agent
    qt5ct
    kvantum
    dbus
    xdg-utils
    xdg-desktop-portal-hyprland
)

declare -a ARCH_AUR_PKGS=(
    hyprshot
    wlogout
    stylua
    cliphist
)

declare -a FREEBSD_PKGS=(
    # Terminal & Shell
    kitty
    bash
    starship

    # Editor
    neovim

    # Wayland (limited hyprland support)
    waybar
    wofi
    hypridle
    dunst

    # CLI tools
    fzf
    fd-find
    ripgrep
    git
    git-delta
    gh
    git-lfs
    wl-clipboard
    copyq
    ImageMagick7
    brightnessctl
    grim
    slurp
    wf-recorder
    gromit-mpx

    # Audio
    pipewire
    wireplumber
    pamixer
    playerctl
    pavucontrol
    libcanberra

    # Development (rustup installed separately via curl)
    node
    npm
    hs-ShellCheck
    shfmt
    stylua
    lua-language-server

    # LazyVim requirements
    curl
    gcc
    gmake
    tree-sitter
    lazygit

    # LSP servers
    gopls
    go

    # Fonts
    nerd-fonts
    font-awesome
    noto-sans-cjk

    # System integration
    polkit-kde-agent
    qt5ct
    kvantum
    dbus
    xdg-utils
)

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    case "$OS" in
        arch)
            echo "Pacman packages: ${#ARCH_PACMAN_PKGS[@]}"
            echo "AUR packages: ${#ARCH_AUR_PKGS[@]}"
            ;;
        freebsd)
            echo "pkg packages: ${#FREEBSD_PKGS[@]}"
            warn "Hyprland is not available on FreeBSD"
            warn "Consider using Sway as an alternative"
            ;;
    esac
    echo ""
}

# Check what's missing
check_missing() {
    local packages=("$@")
    local missing=()

    for pkg in "${packages[@]}"; do
        if ! pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing packages: ${missing[*]}"
        return 1
    else
        success "All packages installed"
        return 0
    fi
}

# Config directories and files to deploy
DOTFILES_DIR="$(cd "$(dirname "$0")/.config" && pwd)"
CONFIG_DIRS=(hypr nvim waybar wlogout wofi ghostty)
CONFIG_FILES=(starship.toml)

# Deploy config files to ~/.config
deploy_configs() {
    echo ""
    info "Deploying config files to ~/.config/..."
    echo ""

    mkdir -p "$HOME/.config"

    for dir in "${CONFIG_DIRS[@]}"; do
        local src="$DOTFILES_DIR/$dir"
        local dest="$HOME/.config/$dir"

        if [[ ! -d "$src" ]]; then
            warn "Source not found: $src (skipping)"
            continue
        fi

        if [[ -d "$dest" ]]; then
            warn "$dest already exists"
            local choice
            read -rp "  Overwrite? [y/N/b(backup)] " choice
            case "$choice" in
                [Yy])
                    rm -rf "$dest"
                    ;;
                [Bb])
                    local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
                    mv "$dest" "$backup"
                    info "Backed up to $backup"
                    ;;
                *)
                    info "Skipping $dir"
                    continue
                    ;;
            esac
        fi

        cp -r "$src" "$dest"
        success "Copied $dir -> $dest"
    done

    # Deploy individual config files
    for file in "${CONFIG_FILES[@]}"; do
        local src="$DOTFILES_DIR/$file"
        local dest="$HOME/.config/$file"

        if [[ ! -f "$src" ]]; then
            warn "Source not found: $src (skipping)"
            continue
        fi

        if [[ -f "$dest" ]]; then
            warn "$dest already exists"
            local choice
            read -rp "  Overwrite? [y/N/b(backup)] " choice
            case "$choice" in
                [Yy])
                    rm -f "$dest"
                    ;;
                [Bb])
                    local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
                    mv "$dest" "$backup"
                    info "Backed up to $backup"
                    ;;
                *)
                    info "Skipping $file"
                    continue
                    ;;
            esac
        fi

        cp "$src" "$dest"
        success "Copied $file -> $dest"
    done

    # Offer to add starship init to .bashrc
    if ! grep -q 'eval "$(starship init bash)"' "$HOME/.bashrc" 2>/dev/null; then
        echo ""
        local choice
        read -rp "Add starship init to ~/.bashrc? [y/N] " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo '' >> "$HOME/.bashrc"
            echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
            success "Added starship init to ~/.bashrc"
        else
            info "Skipping starship .bashrc setup"
        fi
    fi

    echo ""
}

# Main installation
main() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Dotfiles Setup Script${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    detect_os
    print_summary

    read -rp "Proceed with installation? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Installation cancelled"
        exit 0
    fi

    echo ""
    info "Starting installation..."
    echo ""

    case "$OS" in
        arch)
            info "Updating package database..."
            sudo pacman -Sy

            info "Installing pacman packages..."
            install_packages "${ARCH_PACMAN_PKGS[@]}"

            echo ""
            info "Installing AUR packages..."
            install_aur "${ARCH_AUR_PKGS[@]}"
            ;;
        freebsd)
            info "Updating package database..."
            sudo pkg update

            info "Installing packages..."
            install_packages "${FREEBSD_PKGS[@]}"

            echo ""
            info "Setting up versioned packages (PHP/Python)..."
            setup_freebsd_versioned_pkgs
            ;;
    esac

    echo ""
    info "Setting up Rust toolchain..."
    setup_rust

    echo ""
    info "Installing LSP servers via npm..."
    setup_npm_packages

    echo ""
    deploy_configs

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    info "Post-install steps:"
    echo "  1. Open nvim and run :Lazy sync"
    echo "  2. Enable pipewire: systemctl enable --user pipewire wireplumber"
    echo "  3. Log out and select Hyprland session"
    echo ""
}

# Check mode - just report what's missing
check_mode() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Checking Installed Packages${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    detect_os

    case "$OS" in
        arch)
            echo ""
            info "Checking pacman packages..."
            check_missing "${ARCH_PACMAN_PKGS[@]}" || true

            echo ""
            info "Checking AUR packages..."
            check_missing "${ARCH_AUR_PKGS[@]}" || true
            ;;
        freebsd)
            echo ""
            info "Checking pkg packages..."
            check_missing "${FREEBSD_PKGS[@]}" || true
            ;;
    esac

    echo ""
    info "Checking Rust toolchain..."

    if cmd_exists rustup; then
        success "rustup installed"

        if rustup toolchain list 2>/dev/null | grep -q "stable"; then
            success "Rust stable toolchain installed"
        else
            warn "Rust stable not installed (run: rustup default stable)"
        fi

        local components=(rust-analyzer clippy rustfmt)
        for comp in "${components[@]}"; do
            if rustup component list 2>/dev/null | grep -q "$comp.*installed"; then
                success "$comp installed"
            else
                warn "$comp not installed"
            fi
        done

        local cargo_tools=(cargo-watch cargo-edit)
        for tool in "${cargo_tools[@]}"; do
            if cargo install --list 2>/dev/null | grep -q "^$tool "; then
                success "$tool installed (cargo)"
            else
                warn "$tool not installed (cargo)"
            fi
        done
    else
        warn "rustup not found (run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)"
    fi

    echo ""
    info "Checking npm LSP servers..."

    if cmd_exists npm; then
        for pkg in "${NPM_PACKAGES[@]}"; do
            if npm list -g "$pkg" &>/dev/null; then
                success "$pkg installed (npm)"
            else
                warn "$pkg not installed (npm)"
            fi
        done
    else
        warn "npm not found"
    fi

    echo ""
}

# Usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --check    Only check what's missing, don't install"
    echo "  --deploy   Only copy config files to ~/.config/"
    echo "  --help     Show this help message"
    echo ""
}

# Parse arguments
case "${1:-}" in
    --check)
        check_mode
        ;;
    --deploy)
        deploy_configs
        ;;
    --help|-h)
        usage
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
esac
