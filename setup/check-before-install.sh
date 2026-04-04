#!/usr/bin/env bash

# ============================================================================
# Pre-Installation Check & Backup Script
# ============================================================================
#
# Checks your current environment for potential conflicts with home-manager
# and backs up files that would be overwritten.
#
# Usage:
#   bash check-before-install.sh
#
# ============================================================================

set -e
set -u
set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/backups/home-manager-pre-install-$TIMESTAMP"

# Track findings
declare -a CONFLICTS=()
declare -a WARNINGS=()
declare -a BACKUPS=()

# ============================================================================
# Helper Functions
# ============================================================================

section() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS+=("$1")
}

conflict() {
    echo -e "${RED}[CONFLICT]${NC} $1"
    CONFLICTS+=("$1")
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

check_command() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# 1. Check Files That Will Be Overwritten
# ============================================================================

check_files() {
    section "1. Checking Files"

    local files_to_check=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig"
        "$HOME/.config/tmux/tmux.conf"
        "$HOME/.config/nvim/init.lua"
        "$HOME/.config/nvim/init.vim"
        "$HOME/.vimrc"
    )

    info "Checking for files that would be overwritten..."
    echo ""

    local found_files=false
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            found_files=true
            warn "EXISTS: $file"
            echo "  → Will be REPLACED by home-manager"
        fi
    done

    if [ "$found_files" = false ]; then
        success "No conflicting files found"
    fi
}

# ============================================================================
# 2. Check Installed Tools (Version Conflicts)
# ============================================================================

check_tools() {
    section "2. Checking Installed Tools"

    info "Looking for tools that might conflict with Nix versions..."
    echo ""

    local tools=(
        "git"
        "tmux"
        "nvim"
        "vim"
        "docker"
        "psql"
        "terraform"
        "fzf"
        "ripgrep"
        "fd"
    )

    for tool in "${tools[@]}"; do
        if check_command "$tool"; then
            local locations=$(which -a "$tool" 2>/dev/null | head -5)
            local version=$($tool --version 2>&1 | head -1 || echo "unknown")

            echo -e "${YELLOW}$tool${NC} (currently installed):"
            echo "  Locations:"
            echo "$locations" | sed 's/^/    /'
            echo "  Version: $version"
            echo ""

            # Check if it's from Homebrew
            if echo "$locations" | grep -q "/opt/homebrew"; then
                info "  → Installed via Homebrew (will be shadowed by Nix)"
            fi
        fi
    done
}

# ============================================================================
# 3. Check PATH Configuration
# ============================================================================

check_path() {
    section "3. Checking PATH Configuration"

    info "Current PATH order:"
    echo ""
    echo "$PATH" | tr ':' '\n' | nl
    echo ""

    # Check for work-specific paths
    if echo "$PATH" | grep -q -E "(work|corp|company|enterprise)"; then
        warn "Work-specific paths detected in PATH"
        echo "  → Make sure work tools are accessible after home-manager"
    fi

    # Check .zshrc for PATH modifications
    if [ -f "$HOME/.zshrc" ]; then
        local path_mods=$(grep -c "PATH" "$HOME/.zshrc" 2>/dev/null || echo "0")
        if [ "$path_mods" -gt 0 ]; then
            warn "Found $path_mods PATH modifications in .zshrc"
            echo "  → These will be lost when .zshrc is replaced"
            echo "  → Review them in the backup"
        fi
    fi
}

# ============================================================================
# 4. Check Shell Configuration
# ============================================================================

check_shell() {
    section "4. Checking Shell Configuration"

    info "Current shell: $SHELL"

    if [ -f "$HOME/.zshrc" ]; then
        local lines=$(wc -l < "$HOME/.zshrc")
        info "Current .zshrc: $lines lines"

        # Check for common work-specific patterns
        local work_patterns=("vpn" "proxy" "corp" "aws-vault" "kubectl" "gcloud")
        for pattern in "${work_patterns[@]}"; do
            if grep -qi "$pattern" "$HOME/.zshrc" 2>/dev/null; then
                warn "Found '$pattern' in .zshrc (might be work-related)"
            fi
        done
    else
        success "No .zshrc file (clean slate)"
    fi
}

# ============================================================================
# 5. Check Git Configuration
# ============================================================================

check_git() {
    section "5. Checking Git Configuration"

    if [ -f "$HOME/.gitconfig" ]; then
        info "Current .gitconfig exists"

        # Show current user config
        local git_name=$(git config --global user.name 2>/dev/null || echo "not set")
        local git_email=$(git config --global user.email 2>/dev/null || echo "not set")

        echo ""
        echo "  Current git identity:"
        echo "    Name:  $git_name"
        echo "    Email: $git_email"
        echo ""

        # Check for work email
        if echo "$git_email" | grep -qv "@gmail.com\|@personal"; then
            warn "Work email detected: $git_email"
            echo "  → Make sure to update user-config.nix with correct email"
        fi

        # Check for includes (work configs)
        if grep -q "^\[include\]" "$HOME/.gitconfig" 2>/dev/null; then
            warn "Git includes detected (might be work-specific)"
            echo "  → Review these in the backup"
        fi

        # Count aliases
        local alias_count=$(git config --global --get-regexp alias 2>/dev/null | wc -l || echo "0")
        if [ "$alias_count" -gt 0 ]; then
            info "Found $alias_count git aliases (will be replaced)"
        fi
    else
        success "No .gitconfig file (clean slate)"
    fi
}

# ============================================================================
# 6. Check Docker
# ============================================================================

check_docker() {
    section "6. Checking Docker"

    if [ -d "/Applications/Docker.app" ]; then
        success "Docker Desktop is installed"

        if check_command docker; then
            local docker_version=$(docker --version 2>&1)
            local docker_path=$(which docker)
            echo "  Version: $docker_version"
            echo "  Path: $docker_path"
            echo ""
            info "Nix will install Docker CLI (will talk to same Docker Desktop daemon)"
        fi
    else
        info "Docker Desktop not installed"
        echo "  → Run: bash setup/manual/install-docker.sh"
    fi
}

# ============================================================================
# 7. Backup Files
# ============================================================================

backup_files() {
    section "7. Backing Up Files"

    info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zsh_history"
        "$HOME/.gitconfig"
        "$HOME/.config/tmux/tmux.conf"
        "$HOME/.config/nvim/init.lua"
        "$HOME/.config/nvim/init.vim"
        "$HOME/.vimrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
    )

    echo ""
    local backed_up=false
    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            backed_up=true
            local rel_path="${file#$HOME/}"
            local backup_path="$BACKUP_DIR/$rel_path"
            local backup_dir=$(dirname "$backup_path")

            mkdir -p "$backup_dir"
            cp "$file" "$backup_path"
            success "Backed up: $rel_path"
            BACKUPS+=("$rel_path")
        fi
    done

    if [ "$backed_up" = false ]; then
        info "No files to backup"
    fi

    # Save current environment state
    echo ""
    info "Saving environment state..."

    # Save PATH
    echo "$PATH" > "$BACKUP_DIR/path.txt"

    # Save installed tools
    {
        echo "# Installed Tools - $TIMESTAMP"
        echo ""
        for tool in git tmux nvim docker psql terraform; do
            if check_command "$tool"; then
                echo "## $tool"
                which -a "$tool" 2>/dev/null || true
                $tool --version 2>&1 | head -1 || true
                echo ""
            fi
        done
    } > "$BACKUP_DIR/tools.txt"

    # Save shell aliases and functions
    if [ -f "$HOME/.zshrc" ]; then
        {
            echo "# Aliases from .zshrc"
            grep "^alias" "$HOME/.zshrc" 2>/dev/null || true
            echo ""
            echo "# Functions from .zshrc"
            grep -A 3 "^function\|^[a-z_]*() {" "$HOME/.zshrc" 2>/dev/null || true
        } > "$BACKUP_DIR/aliases-and-functions.txt"
    fi

    success "Backup complete: $BACKUP_DIR"
}

# ============================================================================
# 8. Summary & Recommendations
# ============================================================================

show_summary() {
    section "8. Summary & Recommendations"

    echo ""

    # Show conflicts
    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        echo -e "${RED}${BOLD}⚠️  CONFLICTS FOUND (${#CONFLICTS[@]})${NC}"
        echo ""
        for item in "${CONFLICTS[@]}"; do
            echo -e "  ${RED}✗${NC} $item"
        done
        echo ""
    fi

    # Show warnings
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo -e "${YELLOW}${BOLD}⚠️  WARNINGS (${#WARNINGS[@]})${NC}"
        echo ""
        for item in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}⚠${NC} $item"
        done
        echo ""
    fi

    # Show backups
    if [ ${#BACKUPS[@]} -gt 0 ]; then
        echo -e "${GREEN}${BOLD}✓ BACKED UP (${#BACKUPS[@]} files)${NC}"
        echo ""
        for item in "${BACKUPS[@]}"; do
            echo -e "  ${GREEN}✓${NC} $item"
        done
        echo ""
        echo "Backup location: ${BOLD}$BACKUP_DIR${NC}"
        echo ""
    fi

    # Recommendations
    echo -e "${BOLD}Recommendations:${NC}"
    echo ""

    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        echo "🔴 HIGH RISK - Significant conflicts detected"
        echo "   → Consider testing in a VM first"
        echo "   → Or manually merge configs instead of full home-manager"
        echo ""
    elif [ ${#WARNINGS[@]} -gt 5 ]; then
        echo "🟡 MEDIUM RISK - Multiple warnings"
        echo "   → Review warnings above carefully"
        echo "   → Proceed with caution"
        echo ""
    else
        echo "🟢 LOW RISK - Looks safe to proceed"
        echo ""
    fi

    echo "Next steps if proceeding:"
    echo "  1. Review backups: cd $BACKUP_DIR"
    echo "  2. Setup user-config.nix:"
    echo "       cd ~/Documents/ydkadri/setup/home-manager"
    echo "       cp user-config.nix.example user-config.nix"
    echo "       vim user-config.nix"
    echo "  3. Run home-manager switch"
    echo "  4. Test your work tools immediately"
    echo ""
    echo "To restore if things break:"
    echo "  home-manager switch --rollback"
    echo "  cp $BACKUP_DIR/.zshrc ~/"
    echo "  cp $BACKUP_DIR/.gitconfig ~/"
    echo "  exec zsh"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Home Manager Pre-Installation Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    check_files
    check_tools
    check_path
    check_shell
    check_git
    check_docker
    backup_files
    show_summary

    echo -e "${GREEN}${BOLD}Check complete!${NC}"
    echo ""
}

main "$@"
