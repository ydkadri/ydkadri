# Personal Machine Setup

Declarative configuration for personal development environment using home-manager.

## Philosophy

This setup uses **home-manager** for declarative, idempotent configuration management. Everything is defined as code, making it:
- **Reproducible** - Same config produces same environment
- **Idempotent** - Safe to run multiple times
- **Version controlled** - Track changes, rollback if needed
- **Portable** - Easy to apply to new machines

## What's Included

### Shell Environment
- **Zsh** with modern plugins (autosuggestions, syntax-highlighting)
- **Optimized startup** - Lazy-loading for fast shell initialization
- **Smart aliases** - Modern replacements (lsd, bat, delta)
- **Custom functions** - Project switching, docker helpers, password management

### Development Tools
- **Neovim** with LazyVim (modern IDE experience)
- **Tmux** with vim-like navigation and sesh integration
- **Git** with extensive aliases and better defaults
- **Docker** & **Docker Compose** for containerization
- **PostgreSQL** client tools (psql)
- **Terraform** for infrastructure as code

### Language Toolchains
- **Python**: uv (replaces pip, virtualenv, pyenv)
- **Rust**: rustup (manages Rust toolchain versions)

### CLI Tools
- **fzf** - Fuzzy finder (Ctrl+R history, Ctrl+T files)
- **zoxide** - Smart directory jumping (replaces cd)
- **pass** - Password manager (GPG-encrypted, git-backed)
- **atuin** - Enhanced shell history
- **lsd** - Modern ls with icons
- **lazygit** - Terminal UI for git
- **gh** - GitHub CLI
- **ripgrep** - Fast grep (rg)
- **fd** - Fast find
- **bat** - Better cat
- **delta** - Better git diff
- **jq** - JSON processor
- **sesh** - Tmux session manager

## Pre-Installation Check

**Before installing**, run the pre-installation check script to:
- Identify files that will be overwritten
- Check for conflicting tool installations
- Back up your current configuration
- Assess installation risk level

```bash
# Run the pre-installation check
bash ~/Documents/ydkadri/setup/check-before-install.sh
```

This will create a timestamped backup in `~/backups/home-manager-pre-install-<timestamp>/` containing:
- All dotfiles that will be replaced (.zshrc, .gitconfig, etc.)
- Current PATH configuration
- Installed tools list
- Shell aliases and functions

**Review the output carefully** before proceeding with installation. If you see HIGH RISK warnings, consider:
- Testing in a VM first
- Manually merging configs instead of full home-manager
- Reviewing the backup thoroughly

## Installation

### 1. Install Nix

```bash
# Single-user installation (recommended for personal machines)
sh <(curl -L https://nixos.org/nix/install)

# Follow prompts and restart shell after installation
```

### 2. Add home-manager Channel

```bash
# Add home-manager channel
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

# Update channels
nix-channel --update
```

### 3. Install home-manager

```bash
# Install home-manager
nix-shell '<home-manager>' -A install
```

### 4. Configure User Settings

```bash
# Copy user config template
cd ~/Documents/ydkadri/setup/home-manager
cp user-config.nix.example user-config.nix

# Edit with your values
# Update: username, homeDirectory, gitName, gitEmail
nvim user-config.nix  # or use any editor
```

**Important**: This step is required! The config will fail without `user-config.nix`.

### 5. Link Configuration

```bash
# Create home-manager config directory
mkdir -p ~/.config/home-manager

# Link your home.nix (adjust path if needed)
ln -sf ~/Documents/ydkadri/setup/home-manager/home.nix ~/.config/home-manager/home.nix
```

### 6. Apply Configuration

```bash
# Apply home-manager configuration
home-manager switch
```

This will:
- Install all packages
- Configure all programs
- Set up dotfiles
- Create necessary directories

**Note**: First run takes 10-15 minutes as it downloads and builds everything.

### 7. Run Manual Setup

Install tools not managed by home-manager:

```bash
# Install all manual tools (rustup, sesh, fonts)
bash ~/Documents/ydkadri/setup/manual/install.sh --all

# Or install specific tools only
bash ~/Documents/ydkadri/setup/manual/install.sh --rustup    # Rust toolchain
bash ~/Documents/ydkadri/setup/manual/install.sh --sesh      # Tmux session manager
bash ~/Documents/ydkadri/setup/manual/install.sh --fonts     # Nerd Fonts for terminal icons
bash ~/Documents/ydkadri/setup/manual/install.sh --docker    # Check Docker Desktop (macOS)

# Or run individual scripts
bash ~/Documents/ydkadri/setup/manual/install-rustup.sh
bash ~/Documents/ydkadri/setup/manual/install-sesh.sh
bash ~/Documents/ydkadri/setup/manual/install-fonts.sh
bash ~/Documents/ydkadri/setup/manual/install-docker.sh
```

**Why these are separate:**
- **Rustup** - Rust community standard for version management (better than Nix for Rust)
- **Sesh** - Not in nixpkgs, installed from GitHub releases
- **Fonts** - System-level installation required for terminal icons
- **Docker** - Docker Desktop required on macOS (provides daemon)

### 8. Post-Install Configuration

#### a. Setup GPG for Pass (Password Manager)

```bash
# Generate GPG key
gpg --gen-key
# Follow prompts: enter name, email, passphrase

# Initialize password store (use same email as GPG key)
pass init "your-email@example.com"

# Optional: Setup git sync for passwords
cd ~/.password-store
git init
git remote add origin git@github.com:yourusername/password-store.git
```

Store a test password:
```bash
# Store GitHub token
pass insert github/personal-token
# Paste token, press Ctrl+D

# Retrieve it
pass show github/personal-token

# Copy to clipboard
pass show -c github/personal-token
```

#### b. Setup GitHub CLI

```bash
# Authenticate with GitHub
gh auth login

# Follow prompts:
# - Choose GitHub.com
# - Choose SSH
# - Authenticate via browser
```

#### c. Setup Atuin (Optional - for history sync)

If you want to sync shell history across machines:

```bash
# Register account
atuin register -u yourusername -e your-email@example.com

# Login
atuin login -u yourusername

# Enable auto-sync (edit config)
vim ~/.config/home-manager/programs/cli-tools.nix
# Change auto_sync = false to auto_sync = true

# Re-apply config
home-manager switch
```

#### d. Change Default Shell to Zsh

```bash
# Change shell
chsh -s $(which zsh)

# Logout and login for change to take effect
```

#### e. Setup Neovim

```bash
# First time opening nvim, LazyVim will install plugins
nvim

# Wait for installation to complete (~2-3 minutes)
# You'll see progress in the bottom right

# After installation, quit and reopen
:qa
nvim

# Everything should be working now!
```

#### f. Setup Local Environment Overrides (Optional)

For machine-specific configuration or secrets that shouldn't be tracked in git:

```bash
# Create ~/.zshrc.local for local overrides
cat > ~/.zshrc.local <<'EOF'
# Machine-specific environment variables and secrets
# This file is not managed by home-manager and not tracked in git

# GitHub personal access token
export GITHUB_TOKEN="ghp_your_token_here"

# Override work-specific variables if needed
# export KRAKEN_CLI_ROLE="custom_role_for_this_machine"

# Machine-specific aliases
# alias custom-alias="some command"

# Or export from pass instead of hardcoding
# export GITHUB_TOKEN=$(pass show github/personal-token)
EOF

# Restart shell to load
exec zsh

# Verify
echo $GITHUB_TOKEN
```

**When to use `~/.zshrc.local`:**
- Sensitive values (tokens, API keys, passwords)
- Machine-specific configuration that differs per machine
- Temporary overrides for testing

**Note:** Add `~/.zshrc.local` to `.gitignore` if you track your home directory in git.

## Usage

### Making Changes

Edit the configuration files in `~/Documents/ydkadri/setup/home-manager/`:

- `home.nix` - Main configuration, imports everything
- `programs/shell.nix` - Zsh config, aliases, functions
- `programs/git.nix` - Git config and aliases
- `programs/neovim.nix` - Neovim and LSP setup
- `programs/tmux.nix` - Tmux configuration
- `programs/cli-tools.nix` - CLI tools (fzf, zoxide, pass, etc.)
- `packages.nix` - All packages to install

After making changes:

```bash
# Apply changes
home-manager switch
```

### Updating Packages

```bash
# Update nix channels
nix-channel --update

# Update home-manager and all packages
home-manager switch
```

### Rollback Changes

If something breaks after an update:

```bash
# List previous generations
home-manager generations

# Rollback to previous generation
home-manager switch --rollback

# Or rollback to specific generation
/nix/store/...-home-manager-generation/activate
```

## Key Features Explained

### Shell Startup Optimization

Shell starts in ~100ms (vs ~300-500ms before) thanks to:
- Lazy-loading of rarely-used commands
- Optimized plugin loading
- No oh-my-zsh overhead

### Password Management with Pass

GPG-encrypted passwords stored in `~/.password-store`:
```bash
pass insert service/username     # Store password
pass show service/username       # Show password
pass show -c service/username    # Copy to clipboard
pass generate service/user 20    # Generate 20-char password
pass git push                    # Sync to git repo
```

Helper function in shell:
```bash
pass-github  # Copy GitHub token to clipboard
```

### Project Context Switching

Quickly switch between projects with `work` command:
```bash
work  # Opens fzf list of recent projects
      # Select one to open in new tmux session via sesh
```

Or in tmux, press `Ctrl+A T` for sesh project switcher.

### Smart Directory Jumping with Zoxide

```bash
cd ~/Documents/project1   # First time, use full path
cd ~/repos/project2       # Visit another project
cd project1               # Jump back with just name!
cd proj2                  # Partial match works too
```

Zoxide learns your patterns and jumps to the right place.

### Tmux Session Management

```bash
# In tmux, press Ctrl+A T
# Opens sesh fuzzy finder for:
# - Recent tmux sessions
# - Zoxide directories
# - Project directories
```

Keybindings:
- `Ctrl+A` - Prefix (instead of default Ctrl+B)
- `Ctrl+A |` - Split vertically
- `Ctrl+A -` - Split horizontally
- `Ctrl+A h/j/k/l` - Navigate panes (vim-like)
- `Ctrl+A H/J/K/L` - Resize panes

### Neovim with LazyVim

LazyVim provides:
- **LSP** - Autocomplete, go-to-definition, errors
- **Treesitter** - Better syntax highlighting
- **Telescope** - Fuzzy finder for files/text
- **File tree** - Project explorer
- **Git integration** - In-editor git operations

Key mappings (Space is leader):
- `Space e` - Toggle file tree
- `Space f f` - Find files
- `Space f g` - Grep text
- `g d` - Go to definition
- `K` - Show documentation
- `Space c a` - Code actions
- `Space g g` - Open lazygit

Full docs: https://www.lazyvim.org/

## Troubleshooting

### "command not found" after installation

Restart your shell:
```bash
exec zsh
```

Or source the environment:
```bash
source ~/.zshrc
```

### Nix installation issues on macOS

If you get permission errors, make sure:
1. Your user has admin privileges
2. Run with `sudo` if needed
3. Follow macOS-specific Nix installation instructions

### Home Manager won't switch

Check for errors:
```bash
home-manager switch --show-trace
```

Common issues:
- Syntax error in .nix files
- Missing dependencies
- Version conflicts

### GPG/Pass issues

If pass can't find your GPG key:
```bash
# List keys
gpg --list-keys

# Re-initialize pass with correct email
pass init "correct-email@example.com"
```

## Directory Structure

```
setup/
├── README.md                            # This file
├── check-before-install.sh              # Pre-installation check & backup
├── home-manager/
│   ├── home.nix                        # Main home-manager config
│   ├── user-config.nix.example         # Template for user-specific values
│   ├── .gitignore                      # Excludes user-config.nix
│   ├── programs/                       # Per-program configs
│   │   ├── shell.nix                  # Zsh, aliases, functions
│   │   ├── git.nix                    # Git config
│   │   ├── neovim.nix                 # Neovim + LazyVim
│   │   ├── tmux.nix                   # Tmux config
│   │   └── cli-tools.nix              # CLI tools (fzf, zoxide, etc.)
│   └── packages.nix                    # All packages
├── manual/
│   ├── common.sh                       # Shared utilities for install scripts
│   ├── install.sh                      # Main orchestrator (supports --all, --rustup, etc.)
│   ├── install-rustup.sh               # Install Rust via rustup
│   ├── install-sesh.sh                 # Install sesh (tmux session manager)
│   ├── install-fonts.sh                # Install Nerd Fonts
│   └── install-docker.sh               # Check/install Docker Desktop
└── docs/
    ├── TOOLS_INVENTORY.md              # Detailed tool descriptions
    ├── PHILOSOPHY.md                   # Design decisions & concepts
    ├── WORKFLOW_PROJECT_MANAGEMENT.md  # Tmux + sesh + zoxide workflow
    ├── WORKFLOW_TEXT_EDITING.md        # Neovim + LazyVim + LSP workflow
    ├── WORKFLOW_PASSWORD_MANAGEMENT.md # Pass + GPG workflow
    ├── WORKFLOW_SHELL_HISTORY.md       # Atuin + fzf workflow
    └── WORKFLOW_GIT.md                 # Lazygit + gh workflow
```

## Documentation & Workflows

Complete guides for understanding and using each tool:

### Core Concepts
**[PHILOSOPHY.md](docs/PHILOSOPHY.md)** - Start here for fundamentals:
- What is Nix? Home-manager? LSP?
- What is Vim vs Neovim vs LazyVim?
- What is Tmux? GPG? Pass?
- Why these tools? Design decisions

### Workflow Guides
Detailed workflow documentation for daily use:

**[Project Management](docs/WORKFLOW_PROJECT_MANAGEMENT.md)** - Tmux + Sesh + Zoxide + FZF
- Managing multiple projects
- Fast project switching
- Persistent terminal sessions
- Visual examples and keybindings

**[Text Editing](docs/WORKFLOW_TEXT_EDITING.md)** - Neovim + LazyVim + LSP
- Modern IDE features in terminal
- Code intelligence (autocomplete, go-to-definition)
- Vim motions and keybindings
- Learning path from beginner to advanced

**[Password Management](docs/WORKFLOW_PASSWORD_MANAGEMENT.md)** - Pass + GPG
- Secure password storage
- Git-backed sync
- Command-line password access
- Integration with shell

**[Shell History](docs/WORKFLOW_SHELL_HISTORY.md)** - Atuin + FZF
- Enhanced history search
- Context-aware commands
- Statistics and filtering
- Optional cross-machine sync

**[Git Operations](docs/WORKFLOW_GIT.md)** - Lazygit + gh + Delta
- Visual git interface
- GitHub from terminal
- Better diffs and conflict resolution
- PR creation and review

### Tool Reference
**[TOOLS_INVENTORY.md](docs/TOOLS_INVENTORY.md)** - Complete tool inventory
- What each tool does
- Common commands
- Quick reference by use case

## Learning Resources

### Nix & Home Manager
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix internals

### Tools
- [LazyVim Docs](https://www.lazyvim.org/)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Atuin Docs](https://atuin.sh/)
- [Pass Manual](https://www.passwordstore.org/)

## Contributing to This Setup

When adding new tools or configurations:

1. Determine if home-manager has a module:
   - Search: https://nix-community.github.io/home-manager/options.html
   - If yes: Add to appropriate `programs/*.nix` file
   - If no: Add to `packages.nix` or `manual/install.sh`

2. Add configuration:
   - Keep related config together
   - Comment why you chose specific settings
   - Reference documentation

3. Test changes:
   ```bash
   home-manager switch
   ```

4. Update this README if needed

5. Commit changes:
   ```bash
   git add setup/
   git commit -m "Add configuration for XYZ tool"
   ```

## TODO / Future Improvements

- [ ] Add macOS system preferences script (dock, keyboard, etc.)
- [ ] Document backup/restore strategy
- [ ] Add Rust version management via rustup integration
- [ ] Explore nix-darwin for macOS system-level management
- [ ] Add SSH key management
- [ ] Document multi-machine setup (work vs personal)

---

**Last Updated**: 2026-04-01
