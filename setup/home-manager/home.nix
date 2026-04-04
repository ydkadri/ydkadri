{ config, pkgs, lib, ... }:

let
  # Import user-specific configuration
  # Copy user-config.nix.example to user-config.nix and edit with your values
  userConfig = import ./user-config.nix;
in
{
  # ============================================================================
  # Home Manager Configuration
  # ============================================================================
  #
  # This is your home-manager configuration file. Home Manager is a tool for
  # declarative management of your user environment.
  #
  # Quick Start:
  #   0. Copy user config: cp user-config.nix.example user-config.nix
  #      Then edit user-config.nix with your username, home directory, etc.
  #   1. Install Nix: sh <(curl -L https://nixos.org/nix/install)
  #   2. Install home-manager: nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  #   3. Update channel: nix-channel --update
  #   4. Install home-manager: nix-shell '<home-manager>' -A install
  #   5. Link this config: mkdir -p ~/.config/home-manager && ln -sf ~/Documents/ydkadri/setup/home-manager/home.nix ~/.config/home-manager/home.nix
  #   6. Apply config: home-manager switch
  #
  # See README.md in setup/ directory for detailed instructions.
  #
  # ============================================================================

  # Import all program configurations
  imports = [
    ./programs/shell.nix       # Zsh configuration with plugins and aliases
    ./programs/git.nix         # Git configuration and aliases
    ./programs/neovim.nix      # Neovim with LazyVim
    ./programs/tmux.nix        # Tmux configuration
    ./programs/cli-tools.nix   # CLI tools (fzf, zoxide, pass, atuin, etc.)
    ./packages.nix             # All packages to install
  ];

  # ============================================================================
  # Home Manager Settings
  # ============================================================================

  # Home Manager needs a bit of information about you and the paths it should manage
  # These values come from user-config.nix
  home.username = userConfig.username;
  home.homeDirectory = userConfig.homeDirectory;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Allow unfree packages (needed for terraform and other tools)
  nixpkgs.config.allowUnfree = true;

  # ============================================================================
  # Additional Home Configuration
  # ============================================================================

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    LESS = "-R -F -X";

    # Development
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";

    # Rust
    CARGO_HOME = "${config.home.homeDirectory}/.cargo";

    # Python (uv will manage Python versions)
    UV_PYTHON_PREFERENCE = "only-managed";  # Only use uv-managed Python versions
  };

  # Additional PATH entries
  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];

  # ============================================================================
  # Directory Creation
  # ============================================================================

  # Create standard directories for development
  # Using home.file with .keep ensures directories are created
  home.file."repos/.keep".text = "";  # ~/repos for code projects

  # ============================================================================
  # Managed Shell Scripts (~/.managed/)
  # ============================================================================
  #
  # Functions are organized by category in ~/.managed/
  # Aliases are managed in shell.nix shellAliases (better IDE support)

  # Common utility functions
  home.file.".managed/common/functions.sh".text = ''
    # Extract a field from a whitespace delimited string
    field() {
        awk -F "''${2:- }" "{print \$''${1:-1} }"
    }

    # Project context switching helper
    # Lists recent projects via zoxide and opens in new tmux session via sesh
    work() {
        local project=$(zoxide query -l | fzf --height 40% --reverse --preview 'ls -la {}')
        if [[ -n "$project" ]]; then
            sesh connect "$(basename "$project")"
        fi
    }

    # Quick Python venv activation helper
    venv() {
        if [[ -d .venv ]]; then
            source .venv/bin/activate
        elif [[ -d venv ]]; then
            source venv/bin/activate
        else
            echo "No venv found (.venv or venv)"
            return 1
        fi
    }
  '';

  # Common aliases (empty - all aliases in shell.nix shellAliases)
  home.file.".managed/common/aliases.sh".text = ''
    # Additional shell aliases go here
    # Currently all aliases are managed in shell.nix shellAliases for better IDE support
  '';

  # Claude Code helper functions
  home.file.".managed/claude/functions.sh".text = ''
    # List recent Claude conversations (named conversations only)
    claude-list() {
        local limit="''${1:-10}"

        if [[ ! -f ~/.claude/history.jsonl ]]; then
            echo "Error: Claude history file not found at ~/.claude/history.jsonl"
            return 1
        fi

        echo "Recent Claude conversations:"
        echo ""

        # Find entries with /rename command, extract conversation name, group by session
        cat ~/.claude/history.jsonl | \
            jq -r 'select(.display != null and (.display | startswith("/rename ")))' | \
            jq -s 'group_by(.sessionId) |
                   map({
                     sessionId: .[0].sessionId,
                     project: .[0].project,
                     timestamp: (map(.timestamp) | max),
                     display: (map(select(.display | startswith("/rename "))) |
                              sort_by(.timestamp) |
                              .[-1].display |
                              sub("^/rename "; ""))
                   }) |
                   sort_by(.timestamp) |
                   reverse |
                   .[:'"$limit"'] |
                   .[]' | \
            jq -r --arg home "$HOME" '
              "\(.timestamp / 1000 | strftime("%Y-%m-%d %H:%M")) - \(.display)
      Session: \(.sessionId)
      Project: \(.project)
      File: \($home)/.claude/projects/\((.project | gsub("[/.]"; "-")))/\(.sessionId).jsonl
    "'
    }
  '';

  # GitHub CLI helper functions
  home.file.".managed/github/functions.sh".text = ''
    # Create a gist from a file
    gist-create() {
        if [[ -z "$1" ]]; then
            echo "Usage: gist-create <file> [description]"
            return 1
        fi
        local desc="''${2:-Created from terminal}"
        gh gist create "$1" -d "$desc" -p
    }

    # List recent gists
    gist-list() {
        gh gist list --limit 20
    }

    # View a specific gist
    gist-view() {
        if [[ -z "$1" ]]; then
            echo "Usage: gist-view <gist-id>"
            return 1
        fi
        gh gist view "$1"
    }
  '';

  # Docker helper functions
  home.file.".managed/docker/functions.sh".text = ''
    # Clean up stopped containers and unused resources
    docker-clean() {
        echo "Removing stopped containers..."
        docker container prune -f
        echo "Removing unused images..."
        docker image prune -f
        echo "Removing unused volumes..."
        docker volume prune -f
        echo "Removing unused networks..."
        docker network prune -f
    }

    # Nuclear option - remove everything
    docker-nuke() {
        echo "⚠️  WARNING: This will remove ALL containers, images, volumes, and networks"
        echo "Press Ctrl+C to cancel, or Enter to continue..."
        read
        docker stop $(docker ps -aq) 2>/dev/null
        docker system prune -a --volumes -f
    }
  '';

  # Password manager helper functions
  home.file.".managed/pass/functions.sh".text = ''
    # Copy GitHub token from pass to clipboard
    pass-github() {
        pass show github/personal-token | head -n1 | pbcopy
        echo "GitHub token copied to clipboard"
    }
  '';

  # ============================================================================
  # XDG Base Directory Specification
  # ============================================================================

  xdg = {
    enable = true;

    # These set XDG environment variables for standard locations
    # Many tools respect these for config/cache/data storage
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  # ============================================================================
  # Additional Files
  # ============================================================================

  # Custom scripts or dotfiles that don't have home-manager modules
  # Example:
  # home.file.".ssh/config".text = ''
  #   Host github.com
  #     HostName github.com
  #     User git
  #     IdentityFile ~/.ssh/id_ed25519
  # '';

  # ============================================================================
  # Program Settings
  # ============================================================================

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # ============================================================================
  # Manual Steps After First Install
  # ============================================================================
  #
  # After running `home-manager switch` for the first time, you need to:
  #
  # 1. Setup GPG key for pass (password manager):
  #    $ gpg --gen-key
  #    Follow prompts to create a key
  #    $ pass init "your-email@example.com"
  #
  # 2. Setup GitHub CLI:
  #    $ gh auth login
  #    Follow prompts to authenticate
  #
  # 3. Setup Atuin sync (optional, if you want history sync):
  #    Edit ~/.config/home-manager/programs/cli-tools.nix
  #    Set auto_sync = true
  #    $ atuin register
  #    $ atuin login
  #    $ home-manager switch
  #
  # 4. Install sesh (tmux session manager):
  #    Run the manual install script:
  #    $ bash ~/Documents/ydkadri/setup/manual/install.sh
  #
  # 5. Setup Neovim LazyVim:
  #    First time you open nvim, LazyVim will install plugins
  #    $ nvim
  #    Wait for plugins to install, then restart nvim
  #
  # 6. Change default shell to zsh (if not already):
  #    $ chsh -s $(which zsh)
  #    Logout and login for changes to take effect
  #
  # ============================================================================
}
