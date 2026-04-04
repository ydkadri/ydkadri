# Tools Inventory

Reference guide for all development tools in this home-manager setup.

This documents what each tool does, how to use it, and where its config lives.

---

## Core Development Tools

### fzf - Fuzzy Finder

**What it is**: Command-line fuzzy finder for files, commands, history, etc.

**Installation**: `brew install fzf`

**Key keybindings** (default):
```bash
Ctrl+R  # Fuzzy search command history (integrates with atuin)
Ctrl+T  # Fuzzy find files in current directory
Alt+C   # Fuzzy cd into directory
```

**Usage with other tools**:
- Used by sesh for project switching
- Used by tmux-sessionizer
- Can pipe any list to fzf for selection

**Common patterns**:
```bash
# Find and open file in vim
vim $(fzf)

# Kill process
ps aux | fzf | awk '{print $2}' | xargs kill

# Git checkout branch
git branch | fzf | xargs git checkout

# Search and cd
cd $(find ~/repos -type d -maxdepth 2 | fzf)
```

**Config location**: `~/.fzf.zsh` (if using shell integration)

---

### lazygit - Git TUI

**What it is**: Terminal UI for git with vim-like keybindings

**Installation**: `brew install lazygit`

**How to use**: 
```bash
# From any git repo
lg  # Your alias

# Or
lazygit
```

**Key features**:
- Stage/unstage files with space
- Commit with 'c'
- Push/pull with 'p'/'P'
- View diffs, logs, stashes
- Interactive rebase
- Cherry-pick commits
- Resolve merge conflicts visually

**Common workflow**:
```bash
# After making changes
lg
# Space to stage files
# c to commit (opens editor)
# p to push
```

**Config location**: `~/.config/lazygit/config.yml` (if customized)

**Why use it**: Faster than individual git commands, visual overview of repo state

---

### difftastic - Structural Diff Tool

**What it is**: Shows diffs based on syntax tree, not just lines

**Installation**: `brew install difftastic`

**Already configured** in your gitconfig as default difftool

**Usage**:
```bash
# Via git alias
git dft                    # Diff with difftastic
git dft --staged          # Diff staged changes

# Direct command
difft file1.py file2.py
```

**Benefits over regular diff**:
- Understands language syntax
- Shows structural changes
- Handles refactors better
- Ignores whitespace-only changes

---

### gh - GitHub CLI

**What it is**: Official GitHub CLI for issues, PRs, gists, releases

**Installation**: `brew install gh`

**Authentication**: 
```bash
gh auth status    # Check if authenticated
gh auth login     # Login if needed
```

**Common commands**:
```bash
# PRs
gh pr list
gh pr create
gh pr view 123
gh pr checkout 123

# Issues
gh issue list
gh issue create
gh issue view 45

# Gists (see RECOMMENDATIONS.md for shell functions)
gh gist list
gh gist create file.sh
gh gist view <id>

# Repos
gh repo view
gh repo clone owner/repo
```

**Shell functions** (recommended in RECOMMENDATIONS.md):
- `gist-clip` - Create gist from clipboard
- `gist-file` - Create gist from file
- `gist-search` - Search your gists

---

### docker + docker-compose

**What it is**: Container runtime and orchestration

**Installation**: System install or `brew install docker docker-compose`

**Common commands**:
```bash
# Images
docker images
docker pull <image>
docker rmi <image>

# Containers
docker ps              # Running containers
docker ps -a           # All containers
docker run <image>
docker stop <id>
docker rm <id>

# Docker Compose
docker-compose up -d        # Start services
docker-compose down         # Stop services
docker-compose logs -f      # View logs
docker-compose ps           # List services
docker-compose restart      # Restart services
```

**Recommended aliases** (add to shell):
```bash
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dclogs='docker-compose logs -f'
```

**justfile patterns**: See `claude/project/docker.md`

---

### psql - PostgreSQL Client

**What it is**: Command-line client for PostgreSQL databases

**Installation**: `brew install postgresql@14` (already installed)

**Usage**:
```bash
# Connect to database
psql -h host -U user -d database

# With connection string
psql postgresql://user:pass@host:5432/database
```

**Common commands** (inside psql):
```
\l              List databases
\c dbname       Connect to database
\dt             List tables
\d table_name   Describe table
\du             List users
\q              Quit

# Execute SQL
SELECT * FROM users;
```

**Shell alias recommendations**:
```bash
# Add to .zshrc
alias psql-local='psql -U postgres -d mydatabase'
alias psql-prod='psql postgresql://...'  # From pass/env
```

---

## Shell Enhancement Tools

### atuin - Shell History

**What it is**: Enhanced shell history with sync, search, and stats

**Installation**: Installed via home-manager

**Config**: `~/.config/atuin/config.toml`

**Current settings**:
- `auto_sync = false` - Not syncing to cloud (privacy)
- Default search mode: fuzzy
- Integrated with zsh via `eval "$(atuin init zsh)"`

**Usage**:
```bash
Ctrl+R          # Search history with atuin (replaces default)
atuin history   # View history
atuin stats     # Show statistics
atuin search    # Manual search
```

**Why use it**: Better search than default shell history, remembers directory context

---

### lsd - Modern ls

**What it is**: ls replacement with colors, icons, tree view

**Installation**: Installed via home-manager

**Config**: `~/.config/lsd/config.yml`

**Your current alias**: `alias l='lsd -lrth'`

**Common usage**:
```bash
l               # Your alias: long, reverse time, human-readable
lsd             # Basic list
lsd -la         # All files, long format
lsd --tree      # Tree view
```

**Features**:
- Icons for file types
- Git integration (shows status)
- Better colors than default ls
- Human-readable sizes

---

### tmux - Terminal Multiplexer

**What it is**: Split terminal into panes/windows, persistent sessions

**Installation**: Installed via home-manager

**Config**: Managed by home-manager at `~/.config/home-manager/programs/tmux.nix`

**Key features** (from home-manager config):
- Prefix: `Ctrl+B` (default)
- Mouse support (click to switch panes, scroll)
- Vim-like navigation (`Ctrl+B h/j/k/l`)
- Sesh integration (`Ctrl+B T` for project switcher)
- Vi mode for copy/paste
- Persistent sessions across disconnects

**Common keybindings**:
```bash
Ctrl+B T        # Open sesh (project/session switcher)
Ctrl+B |        # Split vertically
Ctrl+B -        # Split horizontally
Ctrl+B h/j/k/l  # Navigate panes (vim-like)
Ctrl+B [        # Enter copy mode (vim keys)
Ctrl+B c        # Create new window
Ctrl+B n/p      # Next/previous window
```

**Workflow with sesh**:
- Press `Ctrl+B T` to open sesh
- Select from recent sessions or zoxide directories
- Sesh creates/attaches sessions automatically

---

## Language Tools

### uv - Python Package & Version Manager

**Installation**: Installed via home-manager

**What it is**: Modern all-in-one Python tool that replaces pip, virtualenv, pyenv, and more. Written in Rust for speed.

**Usage**:
```bash
# Python version management (replaces pyenv)
uv python install 3.12          # Install Python 3.12
uv python list                  # List installed versions
uv python pin 3.12              # Pin project to Python 3.12

# Virtual environments (replaces virtualenv)
uv venv                         # Create venv in current directory
source .venv/bin/activate       # Activate venv

# Package management (replaces pip)
uv pip install package          # Install package
uv pip list                     # List packages
uv pip freeze                   # Freeze dependencies

# Project management (like poetry)
uv sync                         # Install from pyproject.toml
uv add package                  # Add dependency
uv remove package               # Remove dependency
uv lock                         # Generate lockfile

# Tool installation (replaces pipx)
uv tool install ruff            # Install CLI tool globally
uv tool list                    # List installed tools
```

**Environment variable**: `UV_PYTHON_PREFERENCE=only-managed` (set in home.nix) means uv will only use Python versions it manages, not system Python.

**Why use it**: 10-100x faster than pip, simpler than juggling pip + virtualenv + pyenv, better dependency resolution

---

## Rust Tools

### rustup - Rust Toolchain Manager

**Installation**: Installed via manual script (`bash ~/Documents/ydkadri/setup/manual/install-rustup.sh`)

**What it is**: Standard Rust toolchain installer and version manager

**Usage**:
```bash
# Check current version
rustc --version
cargo --version

# Update Rust
rustup update

# Install nightly/beta
rustup install nightly
rustup default nightly  # or stable

# Show installed toolchains
rustup show
```

**Why rustup instead of home-manager**: Rustup is the standard tool in the Rust community and provides better version management.

### cargo - Rust Package Manager

**Installation**: Comes with rustup

**Usage**:
```bash
# Install CLI tools
cargo install <tool-name>

# Common Rust tools to install
cargo install cargo-watch    # Watch for changes
cargo install cargo-edit     # Manage dependencies
```

**Note**: Most Rust-based CLI tools (like atuin, lsd, ripgrep) are installed via home-manager as pre-built binaries, not via cargo install.

---

## Utilities

### jq - JSON Processor

**Installation**: `brew install jq` (already installed)

**Usage**:
```bash
# Pretty-print JSON
echo '{"name":"John"}' | jq .

# Extract field
cat data.json | jq '.users[0].name'

# Filter
cat data.json | jq '.[] | select(.age > 30)'

# Transform
cat data.json | jq 'map({name, email})'
```

**Common patterns**:
```bash
# Parse API response
curl https://api.example.com/data | jq '.results'

# Extract from command output
kubectl get pods -o json | jq '.items[].metadata.name'
```

---

### tree - Directory Tree Viewer

**Installation**: `brew install tree` (already installed)

**Usage**:
```bash
tree                # Show tree of current directory
tree -L 2           # Limit to 2 levels
tree -d             # Directories only
tree -I 'node_modules|.git'  # Ignore patterns
```

**Or use lsd**:
```bash
lsd --tree          # Same functionality with lsd
```

---

### terraform - Infrastructure as Code

**Installation**: `brew install terraform` (already installed)

**Basic commands**:
```bash
terraform init      # Initialize working directory
terraform plan      # Show what would change
terraform apply     # Apply changes
terraform destroy   # Destroy infrastructure
terraform fmt       # Format files
terraform validate  # Validate configuration
```

---

## Summary by Use Case

### Quick Reference

**Working with Git**:
- `lg` - Visual git interface (lazygit)
- `git dft` - Better diffs (difftastic)
- `gh pr create` - Create PR from CLI

**Finding Things**:
- `Ctrl+R` - Search command history (atuin + fzf)
- `Ctrl+T` - Find files (fzf)
- `l` - List files with colors/icons (lsd)

**Project Switching** (recommended):
- `z <project>` - Jump to directory (zoxide)
- `sesh connect <project>` - Switch tmux session

**Python Development**:
- `uv` for package management (faster than pip)
- `pyenv` for version management

**Database Work**:
- `psql` for PostgreSQL

**Container Work**:
- `docker` + `docker-compose` for containers

---

## Next Steps

1. **Add missing configs**:
   - Copy `dotfiles/reference/tmux.conf` to `~/.tmux.conf`
   - Review improved gitconfig and vimrc
   
2. **Install recommended tools** (from RECOMMENDATIONS.md):
   - `zoxide` for smart directory jumping
   - `sesh` for tmux session management
   - `pass` for password management

3. **Add useful aliases**:
   - Docker shortcuts
   - psql connection aliases
   - Custom workflows

4. **Optimize shell**:
   - Lazy-load pyenv/nvm (see RECOMMENDATIONS.md)
   - Remove unused tools

---

**Last Updated**: 2026-04-01
**Maintained By**: Youcef Kadri
