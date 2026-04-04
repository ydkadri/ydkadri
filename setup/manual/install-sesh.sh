#!/usr/bin/env bash

# ============================================================================
# Install Sesh - Tmux Session Manager
# ============================================================================
#
# Installs sesh, a smart tmux session manager that integrates with zoxide.
#
# Usage:
#   bash install-sesh.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Installation
# ============================================================================

install_sesh() {
    section "Installing Sesh"

    # Check if already installed
    if check_command sesh; then
        local version=$(sesh --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        info "Sesh is already installed (version: $version)"
        mark_skipped "sesh"
        return 0
    fi

    info "Installing sesh..."

    # Detect OS and architecture
    local os=$(detect_os)
    local arch=$(detect_arch)

    if [ "$os" = "macos" ]; then
        os="Darwin"
    elif [ "$os" = "linux" ]; then
        os="Linux"
    else
        error "Unsupported OS: $os"
        mark_failure "sesh"
        return 1
    fi

    if [ "$arch" = "unknown" ]; then
        error "Unsupported architecture: $(uname -m)"
        mark_failure "sesh"
        return 1
    fi

    # Get latest release
    info "Fetching latest release..."
    local latest_url="https://api.github.com/repos/joshmedeski/sesh/releases/latest"
    local download_url=$(curl -s "$latest_url" | grep "browser_download_url.*${os}_${arch}" | cut -d '"' -f 4)

    if [ -z "$download_url" ]; then
        error "Could not find download URL for ${os}_${arch}"
        mark_failure "sesh"
        return 1
    fi

    # Download and extract
    local tmp_dir=$(mktemp -d)
    local tmp_file="${tmp_dir}/sesh.tar.gz"

    info "Downloading from: $download_url"
    if ! download_file "$download_url" "$tmp_file"; then
        error "Failed to download sesh"
        rm -rf "$tmp_dir"
        mark_failure "sesh"
        return 1
    fi

    # Extract
    tar -xzf "$tmp_file" -C "$tmp_dir"

    # Install to ~/.local/bin
    local install_dir="$HOME/.local/bin"
    ensure_dir "$install_dir"

    if [ -f "${tmp_dir}/sesh" ]; then
        mv "${tmp_dir}/sesh" "$install_dir/sesh"
        chmod +x "$install_dir/sesh"
        success "Sesh installed to $install_dir/sesh"
    else
        error "Could not find sesh binary in extracted archive"
        rm -rf "$tmp_dir"
        mark_failure "sesh"
        return 1
    fi

    # Cleanup
    rm -rf "$tmp_dir"

    # Verify installation
    if check_command sesh; then
        local version=$(sesh --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        success "Sesh successfully installed (version: $version)"
        mark_success "sesh"
        return 0
    else
        error "Sesh installation failed"
        mark_failure "sesh"
        return 1
    fi
}

# ============================================================================
# Post-Install Information
# ============================================================================

show_post_install() {
    echo ""
    section "Sesh Configuration"

    cat <<EOF
Sesh is installed! It integrates with tmux for smart session management.

Keybinding (already configured in tmux):
  Ctrl+B T    Open sesh project switcher

Within sesh picker:
  Tab/↓       Navigate down
  Shift+Tab/↑ Navigate up
  Enter       Select session
  Ctrl+B      Show all (tmux + zoxide + dirs)
  Ctrl+T      Show only tmux sessions
  Ctrl+X      Show only zoxide directories
  Ctrl+F      Find directories
  Ctrl+D      Kill selected session
  Esc         Cancel

Shell function (already configured in zsh):
  work        Open sesh from command line

Learn more:
  https://github.com/joshmedeski/sesh

EOF

    info "Sesh binary: ~/.local/bin/sesh"
    info "Integration with tmux is already configured"
}

# ============================================================================
# Main
# ============================================================================

main() {
    if install_sesh; then
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
