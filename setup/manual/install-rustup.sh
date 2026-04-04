#!/usr/bin/env bash

# ============================================================================
# Install Rustup - Rust Toolchain Installer
# ============================================================================
#
# Installs rustup for managing Rust versions and toolchains.
#
# Usage:
#   bash install-rustup.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Installation
# ============================================================================

install_rustup() {
    section "Installing Rustup"

    # Check if already installed
    if check_command rustup; then
        local version=$(rustup --version | head -n1)
        info "Rustup is already installed: $version"

        # Update to latest stable
        info "Updating Rust toolchain to latest stable..."
        rustup update

        info "Current toolchain:"
        rustup show

        mark_skipped "rustup"
        return 0
    fi

    info "Installing rustup..."

    # Download and run rustup installer
    if check_command curl; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    else
        error "curl is required to install rustup"
        mark_failure "rustup"
        return 1
    fi

    # Source cargo env for current shell
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    # Verify installation
    if check_command rustup; then
        local version=$(rustup --version | head -n1)
        success "Rustup installed: $version"

        # Show installed toolchain
        info "Default toolchain:"
        rustup show

        mark_success "rustup"
        return 0
    else
        error "Rustup installation failed"
        mark_failure "rustup"
        return 1
    fi
}

# ============================================================================
# Post-Install Information
# ============================================================================

show_post_install() {
    echo ""
    section "Rustup Configuration"

    cat <<EOF
Rustup is installed! The stable toolchain is active by default.

Common rustup commands:
  rustup update              Update all toolchains
  rustup default stable      Set stable as default
  rustup default nightly     Set nightly as default
  rustup toolchain list      List installed toolchains
  rustup show                Show active toolchain

Add components:
  rustup component add clippy      Linter
  rustup component add rustfmt     Formatter
  rustup component add rust-src    Source code (for IDE)

IMPORTANT: Before installing cargo tools, always update rustup first:
  rustup update

Then install common cargo tools:
  cargo install cargo-watch --locked        Auto-rebuild on file changes
  cargo install cargo-edit --locked         Add/remove dependencies from CLI
  cargo install cargo-outdated --locked     Check for outdated dependencies
  cargo install cargo-audit --locked        Security vulnerability scanner

The --locked flag ensures exact dependency versions are used.

EOF

    info "Cargo bin directory: ~/.cargo/bin"
    info "This is already in your PATH via home-manager shell config"
}

# ============================================================================
# Main
# ============================================================================

main() {
    if install_rustup; then
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
