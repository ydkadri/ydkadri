{ config, pkgs, ... }:

{
  # Zsh configuration with modern plugins
  programs.zsh = {
    enable = true;

    # Use XDG config directory for zsh files (modern standard)
    # This puts .zshrc, .zshenv, etc. in ~/.config/zsh/ instead of ~/
    dotDir = "${config.xdg.configHome}/zsh";

    # Source Nix daemon setup first (must happen before anything else)
    initExtraFirst = ''
      # Source nix daemon setup for multi-user installations
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';

    # Enable completion system
    enableCompletion = true;

    # Auto-complete from command history (Fish-like suggestions)
    autosuggestion.enable = true;

    # Syntax highlighting as you type
    syntaxHighlighting.enable = true;

    # History configuration
    history = {
      size = 100000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;  # Don't save commands starting with space
      share = false;  # Don't share history between sessions (atuin handles this)
    };

    # Shell aliases
    shellAliases = {
      # Modern replacements
      ls = "lsd";
      ll = "lsd -l";
      # la is provided by lsd module (lsd -A)
      lr = "lsd -lrth";
      tree = "lsd --tree";

      # Git shortcut (use git aliases for operations: git st, git co, etc.)
      g = "git";

      # Docker shortcuts
      d = "docker";
      dps = "docker ps";
      dc = "docker compose";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";

      # Common operations
      mk = "mkdir -p";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };

    # Shell initialization (runs for all shells)
    initContent = ''
      # ========================================================================
      # Source managed shell scripts from ~/.managed/
      # ========================================================================
      # All functions are organised by category for better maintainability
      # Aliases are managed in shell.nix shellAliases above

      source ~/.managed/env.sh                        # Environment variables (GITHUB_TOKEN, KRAKEN_CLI_ROLE)
      source ~/.managed/common/functions.sh           # field(), work(), venv()
      source ~/.managed/common/aliases.sh             # (currently empty)
      source ~/.managed/claude/functions.sh           # claude-list()
      source ~/.managed/github/functions.sh           # gist-create(), gist-list(), gist-view()
      source ~/.managed/docker/functions.sh           # docker-clean(), docker-nuke()
      source ~/.managed/git/functions.sh              # install_hooks()
      source ~/.managed/pass/functions.sh             # pass-github()
      source ~/.managed/kubernetes/kubectl_aliases.sh # ctx alias

      # ========================================================================
      # Tool Integration Notes
      # ========================================================================
      # All tool integrations and environment variables are managed by home-manager
      #
      # fzf: Ctrl+R for history, Ctrl+T for files
      #   (enabled via programs.fzf.enableZshIntegration in cli-tools.nix)
      #
      # zoxide: Smart directory jumping with 'cd'
      #   (enabled via programs.zoxide.enableZshIntegration in cli-tools.nix)
      #
      # atuin: Enhanced shell history
      #   (enabled via programs.atuin.enableZshIntegration in cli-tools.nix)
      #
      # Python (uv): Version management without pyenv
      #   Usage: uv python install 3.12, uv python pin 3.12
      #
      # Environment variables: Managed via home.sessionVariables in home.nix
      #   EDITOR, VISUAL, DOCKER_BUILDKIT, LESS, etc.
      #
      # PATH: Managed via home.sessionPath in home.nix
      #   - ~/.cargo/bin (Rust)
      #   - ~/.local/bin (local binaries)
    '';
  };

  # Bash configuration (for compatibility)
  # Some systems/scripts still use bash, keep basic config
  programs.bash = {
    enable = true;
    shellAliases = config.programs.zsh.shellAliases;  # Reuse zsh aliases
  };
}
