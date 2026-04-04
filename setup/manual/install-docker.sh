#!/usr/bin/env bash

# ============================================================================
# Check/Install Docker Desktop
# ============================================================================
#
# Checks if Docker Desktop is installed and provides installation instructions.
# On macOS, Docker Desktop is the recommended way to run Docker.
#
# Usage:
#   bash install-docker.sh
#
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================================
# Check Docker
# ============================================================================

check_docker() {
    section "Checking Docker Installation"

    local os=$(detect_os)

    if [ "$os" != "macos" ]; then
        info "Docker check is primarily for macOS (Docker Desktop)"
        info "On Linux, install Docker via your package manager"
        mark_skipped "docker"
        return 0
    fi

    # Check if Docker Desktop is installed
    if [ -d "/Applications/Docker.app" ]; then
        success "Docker Desktop is installed"

        # Check if Docker daemon is running
        if check_command docker && docker info &> /dev/null; then
            local version=$(docker --version)
            success "Docker is running: $version"
            mark_success "docker"
            return 0
        else
            warn "Docker Desktop is installed but not running"
            info "Please start Docker Desktop from Applications"
            mark_success "docker"
            return 0
        fi
    else
        warn "Docker Desktop is not installed"
        show_install_instructions
        mark_skipped "docker"
        return 1
    fi
}

# ============================================================================
# Installation Instructions
# ============================================================================

show_install_instructions() {
    echo ""
    section "Docker Desktop Installation"

    cat <<EOF
Docker Desktop provides Docker Engine, Docker CLI, and Docker Compose on macOS.

Installation options:

Option 1: Homebrew (recommended)
  brew install --cask docker

Option 2: Manual Download
  1. Visit: https://www.docker.com/products/docker-desktop
  2. Download Docker Desktop for Mac
  3. Open the .dmg file
  4. Drag Docker to Applications
  5. Launch Docker from Applications

After installation:
  1. Start Docker Desktop
  2. Wait for it to fully start (whale icon in menu bar)
  3. Run: docker --version
  4. Test: docker run hello-world

EOF

    if ask_yes_no "Would you like to install Docker Desktop via Homebrew now?" "n"; then
        install_docker_desktop
    fi
}

install_docker_desktop() {
    info "Installing Docker Desktop via Homebrew..."

    if ! check_homebrew; then
        error "Homebrew is not installed"
        info "Install Homebrew first: https://brew.sh"
        return 1
    fi

    brew install --cask docker

    if [ -d "/Applications/Docker.app" ]; then
        success "Docker Desktop installed"
        info "Please launch Docker Desktop from Applications"
        info "Wait for it to start, then run: docker --version"
        mark_success "docker"
        return 0
    else
        error "Docker Desktop installation failed"
        mark_failure "docker"
        return 1
    fi
}

# ============================================================================
# Post-Check Information
# ============================================================================

show_post_check() {
    if [ -d "/Applications/Docker.app" ]; then
        echo ""
        section "Docker Desktop Usage"

        cat <<EOF
Docker Desktop is installed!

Common docker commands:
  docker ps                List running containers
  docker images            List images
  docker compose up -d     Start services in background
  docker compose down      Stop services
  docker compose logs -f   Follow logs

Useful shell aliases (already configured):
  d       docker
  dps     docker ps
  dc      docker compose
  dcu     docker compose up -d
  dcd     docker compose down
  dcl     docker compose logs -f

EOF
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    check_docker
    show_post_check
    exit 0
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
