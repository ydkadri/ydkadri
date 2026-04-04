#!/usr/bin/env bash

# ============================================================================
# Common Utilities for Install Scripts
# ============================================================================
#
# Shared functions for logging, checking commands, detecting OS, etc.
# Source this file from other install scripts.
#
# Usage:
#   source "$(dirname "$0")/common.sh"
#
# ============================================================================

# Exit on error
set -e
set -u
set -o pipefail

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# ============================================================================
# Logging Functions
# ============================================================================

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

section() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Check if command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get version of a command
get_version() {
    local cmd=$1
    local version_flag=${2:---version}

    if check_command "$cmd"; then
        $cmd $version_flag 2>&1 | head -n1
    else
        echo "not installed"
    fi
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if script is run with sudo
is_sudo() {
    [ "$EUID" -eq 0 ]
}

# Ask yes/no question
ask_yes_no() {
    local question=$1
    local default=${2:-n}

    if [ "$default" = "y" ]; then
        local prompt="[Y/n]"
    else
        local prompt="[y/N]"
    fi

    while true; do
        read -p "$question $prompt " answer
        answer=${answer:-$default}

        case "${answer,,}" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# Download file with progress
download_file() {
    local url=$1
    local output=$2

    if check_command curl; then
        curl -L -o "$output" "$url" --progress-bar
    elif check_command wget; then
        wget -O "$output" "$url"
    else
        error "Neither curl nor wget found"
        return 1
    fi
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Check if Homebrew is installed (macOS)
check_homebrew() {
    if [ "$(detect_os)" != "macos" ]; then
        return 1
    fi

    check_command brew
}

# ============================================================================
# Status Tracking
# ============================================================================

declare -A INSTALL_STATUS

mark_success() {
    local name=$1
    INSTALL_STATUS[$name]="success"
}

mark_failure() {
    local name=$1
    INSTALL_STATUS[$name]="failure"
}

mark_skipped() {
    local name=$1
    INSTALL_STATUS[$name]="skipped"
}

get_status() {
    local name=$1
    echo "${INSTALL_STATUS[$name]:-unknown}"
}

# Print summary of installations
print_summary() {
    section "Installation Summary"

    local success_count=0
    local failure_count=0
    local skipped_count=0

    for name in "${!INSTALL_STATUS[@]}"; do
        local status="${INSTALL_STATUS[$name]}"
        case "$status" in
            success)
                echo -e "${GREEN}✓${NC} $name"
                ((success_count++))
                ;;
            failure)
                echo -e "${RED}✗${NC} $name"
                ((failure_count++))
                ;;
            skipped)
                echo -e "${YELLOW}⊘${NC} $name (skipped)"
                ((skipped_count++))
                ;;
        esac
    done

    echo ""
    echo "Total: $success_count succeeded, $failure_count failed, $skipped_count skipped"

    if [ $failure_count -gt 0 ]; then
        return 1
    fi
    return 0
}

# ============================================================================
# Cleanup
# ============================================================================

# Trap to cleanup on exit
cleanup() {
    # Add any cleanup logic here
    :
}

trap cleanup EXIT
