{ config, pkgs, ... }:

{
  # === fzf - Fuzzy finder ===
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Default fzf options
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
    ];

    # Key bindings
    # Ctrl+R: command history
    # Ctrl+T: find files
    # Alt+C: cd to directory
  };

  # === Zoxide - Smart directory jumping ===
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;

    # Options
    options = [
      "--cmd cd"  # Use 'cd' instead of 'z' for muscle memory
    ];
  };

  # === Pass - Password manager ===
  programs.password-store = {
    enable = true;
    package = pkgs.pass;

    # Settings
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      PASSWORD_STORE_CLIP_TIME = "45";  # Clipboard timeout in seconds
    };
  };

  # GPG for pass (password encryption)
  programs.gpg = {
    enable = true;

    # Settings
    settings = {
      # Use agent for key management
      use-agent = true;
      # Default key (set this after creating your GPG key)
      # default-key = "your-key-id";
    };
  };

  # GPG agent configuration
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 3600;        # Cache for 1 hour
    maxCacheTtl = 7200;            # Max cache 2 hours
    pinentry.package = pkgs.pinentry_mac;  # macOS pinentry
    enableSshSupport = false;      # Set to true if using GPG for SSH
  };

  # === Atuin - Enhanced shell history ===
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    # Settings
    settings = {
      # Sync disabled for privacy (enable if you want sync across machines)
      auto_sync = false;

      # Search settings
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "auto";
      inline_height = 0;  # Full screen
      show_preview = false;

      # UI settings
      enter_accept = true;  # Enter executes immediately, Tab to edit
      keymap_mode = "auto";

      # History filtering
      history_filter = [
        "^export .*"  # Don't save export commands (may contain secrets)
      ];
      secrets_filter = true;  # Filter out secrets automatically

      # Stats settings
      stats = {
        common_subcommands = [
          "docker"
          "git"
          "kubectl"
          "cargo"
          "npm"
          "tmux"
        ];
      };
    };
  };

  # === LSD - Modern ls replacement ===
  programs.lsd = {
    enable = true;
    # Disable automatic alias integration - we define custom aliases in shell.nix
    enableZshIntegration = false;
    enableBashIntegration = false;

    # Settings
    settings = {
      classic = false;
      blocks = [ "permission" "user" "group" "size" "date" "name" ];
      color = {
        when = "auto";
        theme = "default";
      };
      date = "date";
      dereference = false;
      icons = {
        when = "auto";
        theme = "fancy";
        separator = " ";
      };
      indicators = false;
      layout = "grid";
      size = "default";
      sorting = {
        column = "name";
        reverse = false;
        dir-grouping = "none";
      };
      no-symlink = false;
      total-size = false;
    };
  };

  # === Lazygit - Terminal UI for git ===
  programs.lazygit = {
    enable = true;

    # Settings
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          activeBorderColor = [ "white" "bold" ];
          inactiveBorderColor = [ "white" ];
          selectedLineBgColor = [ "blue" ];
        };
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };

  # === GitHub CLI ===
  programs.gh = {
    enable = true;

    # Git credential helper
    gitCredentialHelper = {
      enable = true;
    };

    # Settings
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";

      # Aliases
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        rv = "repo view";
      };
    };
  };

  # === Direnv - Per-directory environment variables ===
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;  # Better nix-shell integration
  };

  # === Starship - Cross-shell prompt (optional alternative to pure zsh) ===
  # Uncomment to enable starship prompt
  # programs.starship = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   settings = {
  #     add_newline = true;
  #     character = {
  #       success_symbol = "[➜](bold green)";
  #       error_symbol = "[➜](bold red)";
  #     };
  #   };
  # };

  # === Additional CLI tools (no config needed, just installed) ===
  home.packages = with pkgs; [
    # Search and find
    ripgrep               # Fast grep (rg)
    fd                    # Fast find (fd)

    # Text processing
    jq                    # JSON processor
    yq                    # YAML processor

    # File operations
    tree                  # Directory tree viewer
    bat                   # Better cat with syntax highlighting
    eza                   # Modern ls (alternative to lsd)

    # Network tools
    curl                  # HTTP client
    wget                  # File downloader
    httpie                # User-friendly HTTP client

    # Monitoring
    htop                  # Process viewer
    btop                  # Modern process viewer

    # Archive tools
    unzip
    zip

    # Git tools
    gh                    # GitHub CLI (already configured above)
    git-lfs               # Git Large File Storage (configured in git.nix)
    delta                 # Better git diff viewer

    # Misc utilities
    watch                 # Execute command periodically
    tldr                  # Simplified man pages
    tokei                 # Code statistics (Rust-based)

    # Password management helpers
    gnupg                 # GPG for pass
    pinentry_mac          # macOS GPG pinentry
  ];
}
