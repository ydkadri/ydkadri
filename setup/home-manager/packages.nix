{ config, pkgs, ... }:

{
  # All packages to install via home-manager
  home.packages = with pkgs; [
    # === Container & Orchestration ===
    docker                      # Container runtime
    docker-compose              # Multi-container orchestration
    # Note: On macOS, Docker Desktop is typically used
    # These provide CLI tools that work with Docker Desktop

    # === Databases ===
    postgresql                  # PostgreSQL database
    # This provides psql and other PostgreSQL client tools
    # For running a local server, you might use Docker instead

    # === Infrastructure as Code ===
    terraform                   # Infrastructure provisioning
    terraform-ls                # Terraform language server (for neovim)

    # === Programming Language Toolchains ===

    # Python
    uv                          # Fast Python package manager
    # uv replaces pip, virtualenv, pyenv, and more
    # Usage: uv python install 3.12, uv venv, uv pip install, etc.

    # Rust - USE RUSTUP INSTEAD
    # Rustup provides better version management and is the standard in Rust community
    # Install via: bash ~/Documents/ydkadri/setup/manual/install-rustup.sh
    # Or directly: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    #
    # If you prefer home-manager (not recommended), uncomment these:
    # rustc                       # Rust compiler
    # cargo                       # Rust package manager
    # rustfmt                     # Rust formatter
    # clippy                      # Rust linter

    # === Build Tools & Task Runners ===
    just                        # Modern make alternative (for personal projects)
    gnumake                     # GNU Make (for work projects with Makefiles)

    # === Version Control ===
    git                         # Git (configured in git.nix)
    gh                          # GitHub CLI (configured in cli-tools.nix)

    # === Cloud CLIs ===
    # Uncomment if needed for your projects
    # awscli2                   # AWS CLI
    # google-cloud-sdk          # Google Cloud CLI
    # azure-cli                 # Azure CLI

    # === API Testing & Development ===
    # Uncomment if needed
    # postman                   # API testing
    # insomnia                  # API testing

    # === Documentation ===
    # Uncomment if needed
    # pandoc                    # Document converter
    # graphviz                  # Graph visualization

    # === System Utilities ===
    coreutils                   # GNU core utilities
    findutils                   # GNU find, xargs, locate
    diffutils                   # GNU diff, cmp, diff3

    # === Shell & Terminal ===
    zsh                         # Z shell (configured in shell.nix)
    tmux                        # Terminal multiplexer (configured in tmux.nix)

    # === Monitoring & Debugging ===
    # Uncomment if needed
    # strace                    # System call tracer (Linux only)
    # lsof                      # List open files
    # netcat                    # Network utility

    # === Network Tools ===
    nmap                        # Network scanner
    # Uncomment if needed
    # wireshark                 # Network protocol analyzer

    # === Compression & Archives ===
    gzip
    bzip2
    xz
    zstd                        # Fast compression

    # === Data Processing ===
    sqlite                      # SQLite database
    # Uncomment if needed
    # redis                     # Redis client
    # mongodb-tools             # MongoDB tools

    # === Performance & Profiling ===
    # Uncomment if needed for Rust/Python profiling
    # valgrind                  # Memory debugger (Linux only)
    # hyperfine                 # Benchmarking tool

    # === Documentation Viewers ===
    man-db                      # Man pages
    man-pages                   # POSIX man pages

    # === File Transfer ===
    rsync                       # File synchronization
    rclone                      # Cloud storage sync

    # === Modern Unix Replacements ===
    # Most are already included in cli-tools.nix
    # These are duplicates for reference:
    # ripgrep                   # rg - better grep
    # fd                        # better find
    # bat                       # better cat
    # lsd                       # better ls
    # eza                       # alternative better ls
    # delta                     # better diff
    # zoxide                    # better cd
    # fzf                       # fuzzy finder

    # === Nix Utilities ===
    nixpkgs-fmt                 # Nix code formatter
    nix-tree                    # Nix package tree viewer
    # Uncomment if you want to explore Nix packages
    # nix-index                 # File database for nix packages
  ];

  # === Language-specific environment setup ===

  # Python with uv
  # No need for pyenv - uv handles Python version management
  # Usage:
  #   uv python install 3.12
  #   uv python pin 3.12
  #   uv venv
  #   source .venv/bin/activate
  #   uv pip install <package>

  # Rust with cargo
  # If you prefer rustup for Rust version management:
  #   1. Remove rustc/cargo/rustfmt/clippy from packages above
  #   2. Install rustup separately: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  #   3. Rustup will manage Rust versions for you

  # === Docker setup notes ===
  # On macOS, you typically use Docker Desktop
  # The docker and docker-compose packages provide CLI tools
  # Make sure Docker Desktop is installed and running

  # === PostgreSQL setup notes ===
  # This installs psql and other client tools
  # For local development, consider:
  #   1. Docker: docker run -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres
  #   2. Or use Postgres.app on macOS
  #   3. Or enable PostgreSQL service (see commented section below)

  # Uncomment to enable PostgreSQL service (Linux/NixOS only, not macOS)
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql;
  # };
}
