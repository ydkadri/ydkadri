#!/usr/bin/env bash

# ============================================================================
# Install Nerd Fonts
# ============================================================================
#
# Installs Nerd Fonts for terminal icons used by lsd, neovim, and other tools.
#
# Usage:
#   bash install-fonts.sh [font-name]
#
# Examples:
#   bash install-fonts.sh                # Install Hack Nerd Font (recommended)
#   bash install-fonts.sh meslo          # Install Meslo Nerd Font
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default font if none specified
DEFAULT_FONT="hack"

# Popular Nerd Fonts
declare -A FONTS=(
    ["hack"]="Hack"
    ["meslo"]="MesloLGS NF"
    ["fira"]="FiraCode"
    ["jetbrains"]="JetBrainsMono"
    ["source-code-pro"]="SourceCodePro"
)

# ============================================================================
# Check if Font is Installed
# ============================================================================

is_font_installed() {
    local font_name=$1
    local os=$(detect_os)

    if [ "$os" = "macos" ]; then
        # Check in system and user font directories
        find ~/Library/Fonts /Library/Fonts -name "*${font_name}*" 2>/dev/null | grep -q "."
    else
        # Linux
        fc-list | grep -qi "$font_name"
    fi
}

# ============================================================================
# Installation
# ============================================================================

install_font() {
    local font_key=${1:-$DEFAULT_FONT}
    local font_name=${FONTS[$font_key]}

    if [ -z "$font_name" ]; then
        error "Unknown font: $font_key"
        info "Available fonts: ${!FONTS[@]}"
        mark_failure "fonts"
        return 1
    fi

    section "Installing $font_name Nerd Font"

    # Check if already installed
    if is_font_installed "$font_name"; then
        info "$font_name Nerd Font is already installed"
        mark_skipped "fonts"
        return 0
    fi

    local os=$(detect_os)

    if [ "$os" = "macos" ]; then
        install_font_macos "$font_key" "$font_name"
    elif [ "$os" = "linux" ]; then
        install_font_linux "$font_key" "$font_name"
    else
        error "Unsupported OS: $os"
        mark_failure "fonts"
        return 1
    fi
}

install_font_macos() {
    local font_key=$1
    local font_name=$2

    info "Installing $font_name via Homebrew..."

    if ! check_homebrew; then
        error "Homebrew is not installed"
        info "Install Homebrew first: https://brew.sh"
        mark_failure "fonts"
        return 1
    fi

    # Install font (homebrew/cask-fonts tap is no longer needed as of 2024)
    local cask_name="font-${font_key}-nerd-font"
    brew install --cask "$cask_name"

    if is_font_installed "$font_name"; then
        success "$font_name Nerd Font installed"
        mark_success "fonts"
        return 0
    else
        error "Font installation may have failed"
        info "Try installing manually or choose a different font"
        mark_failure "fonts"
        return 1
    fi
}

install_font_linux() {
    local font_key=$1
    local font_name=$2

    info "Installing $font_name..."

    # Create fonts directory
    local fonts_dir="$HOME/.local/share/fonts"
    ensure_dir "$fonts_dir"

    # Download font
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
    local tmp_dir=$(mktemp -d)
    local zip_file="${tmp_dir}/${font_name}.zip"

    info "Downloading from: $url"
    if ! download_file "$url" "$zip_file"; then
        error "Failed to download font"
        rm -rf "$tmp_dir"
        mark_failure "fonts"
        return 1
    fi

    # Extract to fonts directory
    info "Extracting fonts..."
    unzip -q "$zip_file" -d "$fonts_dir" "*.ttf" "*.otf" 2>/dev/null || true

    # Cleanup
    rm -rf "$tmp_dir"

    # Refresh font cache
    info "Refreshing font cache..."
    if check_command fc-cache; then
        fc-cache -f
    fi

    if is_font_installed "$font_name"; then
        success "$font_name Nerd Font installed"
        mark_success "fonts"
        return 0
    else
        error "Font installation may have failed"
        mark_failure "fonts"
        return 1
    fi
}

# ============================================================================
# Post-Install Information
# ============================================================================

show_post_install() {
    echo ""
    section "Font Configuration"

    cat <<EOF
Nerd Font is installed!

Next steps:
  1. Configure your terminal to use the font:
     - macOS Terminal: Terminal > Preferences > Profiles > Font
     - iTerm2: Preferences > Profiles > Text > Font
     - Alacritty: Edit ~/.config/alacritty/alacritty.yml
     - Kitty: Edit ~/.config/kitty/kitty.conf

  2. Recommended font names:
     - Hack Nerd Font Mono
     - MesloLGS NF
     - FiraCode Nerd Font Mono
     - JetBrainsMono Nerd Font Mono

  3. Font size: 12-14pt recommended

  4. Restart your terminal for changes to take effect

Why Nerd Fonts?
  - Icons in terminal (lsd, neovim, starship)
  - Better visual appearance
  - Programming ligatures (some fonts)

Available fonts:
  ${!FONTS[@]}

To install a different font:
  bash install-fonts.sh <font-name>

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    local font_key=${1:-$DEFAULT_FONT}

    if install_font "$font_key"; then
        show_post_install
        exit 0
    else
        exit 1
    fi
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
