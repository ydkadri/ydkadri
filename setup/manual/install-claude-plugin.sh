#!/usr/bin/env bash

# ============================================================================
# Install Claude Code Plugin (mine@ydkadri)
# ============================================================================
#
# Adds the ydkadri plugin marketplace and installs the `mine` plugin.
#
# Idempotent: each step runs only if it is missing, so it is safe to re-run.
# Re-run it after swapping ~/.claude/settings.json.bedrock in or out, which
# drops the plugin keys from settings.json.
#
# Never fails the wider setup: if claude or jq is missing, or if GitHub cannot
# be reached, it prints the manual commands and exits 0.
#
# Usage:
#   bash install-claude-plugin.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

MARKETPLACE_REPO="ydkadri/ydkadri"
MARKETPLACE_NAME="ydkadri"
PLUGIN_ID="mine@ydkadri"

# ============================================================================
# Helpers
# ============================================================================

print_manual_steps() {
    cat <<EOF

Install the plugin by hand:
  claude plugin marketplace add $MARKETPLACE_REPO
  claude plugin install $PLUGIN_ID

EOF
}

# True if the JSON array on stdin has an element whose .<field> equals <value>
json_has() {
    local field=$1
    local value=$2
    jq -e --arg f "$field" --arg v "$value" 'any(.[]; .[$f] == $v)' > /dev/null
}

# ============================================================================
# Installation
# ============================================================================

install_claude_plugin() {
    section "Installing Claude Code Plugin"

    if ! check_command claude; then
        warn "claude is not on PATH, skipping plugin install"
        info "Run 'bash install.sh --claude' first, then re-run this script"
        mark_skipped "claude-plugin"
        return 0
    fi

    if ! check_command jq; then
        warn "jq is not on PATH (it comes from home-manager), cannot check existing state"
        print_manual_steps
        mark_skipped "claude-plugin"
        return 0
    fi

    local marketplaces plugins
    if ! marketplaces=$(claude plugin marketplace list --json 2>/dev/null) ||
       ! plugins=$(claude plugin list --json 2>/dev/null); then
        warn "Could not read the current plugin state from claude"
        print_manual_steps
        mark_failure "claude-plugin"
        return 0
    fi

    local changed=false

    # Marketplace
    if printf '%s' "$marketplaces" | json_has name "$MARKETPLACE_NAME"; then
        info "Marketplace '$MARKETPLACE_NAME' is already added"
    else
        info "Adding marketplace $MARKETPLACE_REPO..."
        if ! claude plugin marketplace add "$MARKETPLACE_REPO"; then
            warn "Could not add the marketplace (no network or no GitHub access?)"
            print_manual_steps
            mark_failure "claude-plugin"
            return 0
        fi
        changed=true
    fi

    # Plugin
    if printf '%s' "$plugins" | json_has id "$PLUGIN_ID"; then
        info "Plugin '$PLUGIN_ID' is already installed"
    else
        info "Installing plugin $PLUGIN_ID..."
        if ! claude plugin install "$PLUGIN_ID"; then
            warn "Could not install the plugin"
            print_manual_steps
            mark_failure "claude-plugin"
            return 0
        fi
        changed=true
    fi

    if [ "$changed" = true ]; then
        success "Claude Code plugin $PLUGIN_ID is ready"
        mark_success "claude-plugin"
    else
        mark_skipped "claude-plugin"
    fi
    return 0
}

# ============================================================================
# Post-Install Information
# ============================================================================

show_post_install() {
    echo ""
    info "Restart Claude Code to load the plugin"
    info "Update later with: claude-plugin-update"
}

# ============================================================================
# Main
# ============================================================================

main() {
    install_claude_plugin
    if [ "$(get_status "claude-plugin")" = "success" ]; then
        show_post_install
    fi
    exit 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
