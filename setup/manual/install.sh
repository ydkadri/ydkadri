#!/usr/bin/env bash

# ============================================================================
# Personal Machine Setup - Manual Installation
# ============================================================================
#
# Orchestrates installation of tools that cannot be managed by home-manager.
#
# Usage:
#   bash install.sh --all              Install everything
#   bash install.sh --rustup           Install Rustup only
#   bash install.sh --sesh             Install Sesh only
#   bash install.sh --docker           Check Docker only
#   bash install.sh --fonts            Install fonts only
#   bash install.sh --rustup --sesh    Install multiple
#   bash install.sh --help             Show help
#
# ============================================================================

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Configuration
# ============================================================================

# What to install (flags)
INSTALL_RUSTUP=false
INSTALL_SESH=false
INSTALL_DOCKER=false
INSTALL_FONTS=false
INSTALL_ALL=false

# ============================================================================
# Help
# ============================================================================

show_help() {
    cat <<EOF
Personal Machine Setup - Manual Installation

Installs tools that cannot be managed by home-manager:
  - Rustup: Rust toolchain manager
  - Sesh: Tmux session manager
  - Docker Desktop: Container platform (macOS check)
  - Nerd Fonts: Terminal icons

Usage:
  bash install.sh [OPTIONS]

Options:
  --all        Install everything (recommended for first-time setup)
  --rustup     Install Rustup (Rust toolchain manager)
  --sesh       Install Sesh (tmux session manager)
  --docker     Check/install Docker Desktop
  --fonts      Install Nerd Fonts for terminal
  --help       Show this help message

Examples:
  bash install.sh --all              # Install everything
  bash install.sh --rustup --sesh    # Install specific tools
  bash install.sh --fonts            # Just install fonts

Individual scripts can also be run directly:
  bash install-rustup.sh
  bash install-sesh.sh
  bash install-docker.sh
  bash install-fonts.sh

EOF
}

# ============================================================================
# Parse Arguments
# ============================================================================

parse_args() {
    if [ $# -eq 0 ]; then
        error "No options specified"
        echo ""
        show_help
        exit 1
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            --all)
                INSTALL_ALL=true
                INSTALL_RUSTUP=true
                INSTALL_SESH=true
                INSTALL_DOCKER=true
                INSTALL_FONTS=true
                shift
                ;;
            --rustup)
                INSTALL_RUSTUP=true
                shift
                ;;
            --sesh)
                INSTALL_SESH=true
                shift
                ;;
            --docker)
                INSTALL_DOCKER=true
                shift
                ;;
            --fonts)
                INSTALL_FONTS=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Pre-Flight Checks
# ============================================================================

preflight_checks() {
    section "Pre-Flight Checks"

    # Check OS
    local os=$(detect_os)
    local arch=$(detect_arch)
    info "Operating System: $os ($arch)"

    # Check required commands
    local missing=()

    if ! check_command curl; then
        missing+=("curl")
    fi

    if [ "$os" = "macos" ] && [ ${#missing[@]} -gt 0 ]; then
        error "Missing required commands: ${missing[*]}"
        info "Install Xcode Command Line Tools: xcode-select --install"
        exit 1
    fi

    # Check home-manager
    if ! check_command home-manager; then
        warn "home-manager not found"
        info "This script installs tools not managed by home-manager"
        info "Make sure you've run 'home-manager switch' first"
        echo ""
        if ! ask_yes_no "Continue anyway?" "n"; then
            exit 0
        fi
    fi

    success "Pre-flight checks passed"
}

# ============================================================================
# Installation
# ============================================================================

run_installations() {
    section "Starting Installations"

    local failed=false

    # Rustup
    if [ "$INSTALL_RUSTUP" = true ]; then
        echo ""
        if ! bash "$SCRIPT_DIR/install-rustup.sh"; then
            failed=true
        fi
    fi

    # Sesh
    if [ "$INSTALL_SESH" = true ]; then
        echo ""
        if ! bash "$SCRIPT_DIR/install-sesh.sh"; then
            failed=true
        fi
    fi

    # Docker
    if [ "$INSTALL_DOCKER" = true ]; then
        echo ""
        if ! bash "$SCRIPT_DIR/install-docker.sh"; then
            # Docker check doesn't fail if not installed
            :
        fi
    fi

    # Fonts
    if [ "$INSTALL_FONTS" = true ]; then
        echo ""
        if ! bash "$SCRIPT_DIR/install-fonts.sh"; then
            failed=true
        fi
    fi

    if [ "$failed" = true ]; then
        return 1
    fi

    return 0
}

# ============================================================================
# Post-Install Summary
# ============================================================================

show_summary() {
    echo ""
    section "Installation Complete!"

    cat <<EOF

Next Steps:
  1. Setup GPG key for password manager:
       gpg --gen-key

  2. Initialize pass:
       pass init "your-email@example.com"

  3. Authenticate with GitHub:
       gh auth login

  4. Change default shell to zsh:
       chsh -s \$(which zsh)

  5. Restart your terminal for all changes to take effect

  6. Open neovim to let LazyVim install plugins:
       nvim

Optional Tools to Install:

  Rust development:
    cargo install cargo-watch        # Auto-rebuild on file changes
    cargo install cargo-edit         # Add/remove dependencies from CLI
    cargo install cargo-outdated     # Check for outdated dependencies
    cargo install cargo-audit        # Security vulnerability scanner

  Python development:
    # uv handles most Python needs, but you can install global tools:
    uv tool install ruff             # Linter/formatter (if not using project-local)
    uv tool install black            # Code formatter (alternative)

Documentation:
  See setup/README.md for complete setup instructions
  See setup/docs/ for workflow guides

EOF

    if [ "$INSTALL_ALL" = true ]; then
        info "You chose --all, so all tools have been processed"
    fi

    success "Setup complete! Enjoy your new development environment 🚀"
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse command line arguments
    parse_args "$@"

    # Show header
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Personal Machine Setup - Manual Installation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Pre-flight checks
    preflight_checks

    # Run installations
    if ! run_installations; then
        echo ""
        error "Some installations failed"
        info "Check error messages above for details"
        exit 1
    fi

    # Show summary
    show_summary

    exit 0
}

# Run main
main "$@"
