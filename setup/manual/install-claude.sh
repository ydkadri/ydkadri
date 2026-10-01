#!/usr/bin/env bash

# ============================================================================
# Install Claude Code CLI
# ============================================================================
#
# Checks for the Claude Code CLI (native build, which updates itself).
#
# The native build is normally installed with Anthropic's own installer. The
# exact installer invocation has not been verified for this repo, so this
# script does NOT download or execute anything. If claude is missing it prints
# the manual step and exits 0 so that `install.sh --all` still finishes.
#
# Once claude is on PATH, `claude install [target]` manages the native build.
#
# Usage:
#   bash install-claude.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Installation
# ============================================================================

install_claude() {
    section "Installing Claude Code CLI"

    # Check if already installed
    if check_command claude; then
        local version
        version=$(claude --version 2>&1 | head -n1 || echo "unknown")
        info "Claude Code is already installed (version: $version)"
        mark_skipped "claude"
        return 0
    fi

    warn "Claude Code is not installed, and this script does not install it automatically"
    cat <<EOF

Install the native build by hand:
  1. Download and read the official installer: https://claude.ai/install.sh
  2. Run it with bash
  3. Make sure ~/.local/bin is on your PATH (home-manager already does this)
  4. Re-run: bash install.sh --claude

EOF
    mark_skipped "claude"
    return 0
}

# ============================================================================
# Post-Install Information
# ============================================================================

show_post_install() {
    echo ""
    if check_command claude; then
        info "Claude Code binary: $(command -v claude)"
        info "The native build updates itself; no further action needed"
    else
        info "Claude Code is still missing; follow the manual step above"
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    if install_claude; then
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
