# Dotfiles and Environment Setup

This directory contains documentation and reference configurations for development environment setup.

## Ansible Dotfiles Repository

The primary dotfiles management is handled via Ansible in a separate repository:

**Location**: `/Users/youcef.kadri/repos/data-dotfiles`

The Ansible setup manages configurations in `$HOME/.managed/` and sources them from shell rc files.

### Managed Configurations

The Ansible playbook configures:

- **Shell environment** (zsh)
- **Git configuration**
- **Vim configuration**
- **Rust toolchain and tools** (atuin, lsd, etc.)
- **Python environment** (pyenv)
- **Node environment** (nvm)
- **Kubernetes tools**

## Shell Configuration

### Current .zshrc Structure

```zsh
# Ansible-managed common utilities
source $HOME/.managed/common/aliases.sh
source $HOME/.managed/common/functions.sh

# Development tools
export EDITOR=$(which vim)

# Homebrew
export PATH=/opt/homebrew/bin:/opt/homebrew/**/bin:$PATH

# Rust toolchain
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
eval "$(atuin init zsh)"
alias l='lsd -lrth'

# Python (pyenv)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Node (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Local binaries (pipx)
export PATH="$PATH:/Users/youcef.kadri/.local/bin"

# Kubernetes
source $HOME/.managed/kubernetes/kubectl_aliases.sh
```

### Common Aliases

```bash
# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Directory listing
alias lr="ls -lrth"
alias ll="ls -alFh"
alias l="lsd -lrth"  # Using lsd (Rust tool)

# Git
alias lg="lazygit"
```

### Common Functions

```bash
# Field extraction
field() {
    # Extract a field from whitespace delimited string
    awk -F "${2:- }" "{print \$${1:-1} }"
}

# Tmux session management
tn() { tmux new-session -s $1 }
ta() { tmux attach-session -t $1 }
tl() { tmux list-sessions }

# Git hooks installation
install_hooks() {
  repo_root=$(git rev-parse --show-toplevel)
  if [ -d "$repo_root/.git" ]; then
    cp $HOME/.managed/git/pre-push $repo_root/.git/hooks/pre-push
    chmod +x $repo_root/.git/hooks/pre-push
  fi
}
```

## Git Configuration

### Global Git Config

```gitconfig
[user]
    name = Youcef Kadri
    email = youcef.kadri@kraken.tech

[commit]
    template = ~/.managed/git/git-commit-message.txt

[core]
    editor = vim

[init]
    defaultBranch = main

[push]
    default = current

[pull]
    rebase = true

[rebase]
    autosquash = true

[fetch]
    prune = true

[url "git@github.com:"]
    insteadOf = https://github.com/

[diff]
    tool = difftastic

[difftool "difftastic"]
    cmd = difft "$LOCAL" "$REMOTE"
```

### Git Aliases

```gitconfig
br = branch
brv = branch -v
cl = clone
co = checkout
cob = checkout -b
ct = commit
ctm = commit -m
ctam = commit -am
dft = difftool
dno = diff --name-only
lg = log --graph --oneline --abbrev-commit --decorate --color --all
pl = pull
ps = push
psf = push -f
psh = push -u origin HEAD
rb = rebase
rbi = rebase --interactive
st = status
```

### Commit Message Template

```
# If applied, this commit will...

# Why is this change needed?
Prior to this change,

# How does it address the issue?
This change

# Provide links to any relevant tickets, articles or other resources
```

## Vim Configuration

```vim
" Syntax highlighting
syntax on

" Line Numbers
set nu

" 4 space tabs
filetype plugin indent on
set expandtab
set tabstop=4
set shiftwidth=4

" Memory settings
set maxmem=6753250
set maxmemtot=6753250
set maxmempattern=6691516
```

## Development Tools

### Python Environment

- **Package Manager**: pyenv for version management
- **Package Tools**: pip, pipx, uv
- **Virtual Environments**: Managed by pyenv or venv

### Rust Toolchain

- **Installed Tools**:
  - `atuin` - Shell history sync
  - `lsd` - Modern ls replacement
  - `difftastic` - Structural diff tool

### Node Environment

- **Version Manager**: nvm
- **Location**: `$HOME/.nvm`

### Kubernetes Tools

- kubectl with custom aliases (managed in `$HOME/.managed/kubernetes/`)

## Package Managers

### System Package Manager

- **macOS**: Homebrew (`/opt/homebrew`)

### Language-Specific

- **Python**: uv (preferred), pip
- **Rust**: cargo
- **Node**: npm, yarn

## Quick Setup Guide

### Initial Setup

1. Clone Ansible dotfiles repository:
   ```bash
   cd ~/repos
   git clone <ansible-dotfiles-repo> data-dotfiles
   ```

2. Run Ansible playbook:
   ```bash
   cd data-dotfiles
   ansible-playbook -i hosts playbook.yml
   ```

### Installing New Tools

#### Python Tool
```bash
pipx install <tool-name>
# or
uv tool install <tool-name>
```

#### Rust Tool
```bash
cargo install <tool-name>
```

#### System Tool
```bash
brew install <tool-name>
```

## Directory Structure

```
$HOME/
├── .zshrc                          # Main shell config (Ansible managed)
├── .gitconfig                      # Global git config
├── .vimrc                          # Vim configuration
├── .managed/                       # Ansible-managed configs
│   ├── common/
│   │   ├── aliases.sh
│   │   └── functions.sh
│   ├── git/
│   │   ├── git-commit-message.txt
│   │   └── pre-push
│   └── kubernetes/
│       └── kubectl_aliases.sh
├── .cargo/                         # Rust toolchain
├── .pyenv/                         # Python versions
├── .nvm/                           # Node versions
└── repos/
    └── data-dotfiles/              # Ansible configuration
```

## Maintenance

### Updating Configurations

1. Edit files in the Ansible repository
2. Re-run the playbook
3. Source updated shell config: `source ~/.zshrc`

### Backing Up Configurations

The Ansible playbook automatically creates timestamped backups (e.g., `.zshrc-YYYYMMDDTHHMMSS.bak`) when updating managed files.

## Documentation

### Core Documents

- **[RECOMMENDATIONS.md](RECOMMENDATIONS.md)** - Actionable improvements for development environment
  - Shell startup optimization (lazy-loading)
  - Password management with Pass
  - Project switching with sesh + zoxide
  - CLI tools for notes and gists
  - Tmux configuration enhancements
  - AWS and Git workflow improvements

- **[TOOLS_INVENTORY.md](TOOLS_INVENTORY.md)** - Complete inventory of installed development tools
  - Core development tools (fzf, lazygit, gh, docker, psql)
  - Shell enhancements (atuin, lsd, tmux)
  - Language tools (pyenv, uv, cargo)
  - Utilities (jq, tree, terraform)
  - Quick reference by use case

### Reference Files

Located in `reference/` directory:

**Current Configurations**:
- `aliases.sh` - Current shell aliases
- `functions.sh` - Current shell functions
- `gitconfig` - Current git configuration
- `vimrc` - Current vim configuration
- `git-commit-template.txt` - Current commit template
- `atuin-config.toml` - Current atuin shell history config
- `lsd-config.yml` - Current lsd (modern ls) config

**Improved Templates** (recommended to adopt):
- `gitconfig-improved` - Enhanced git config with useful aliases and settings
- `vimrc-improved` - Enhanced vim config with quality-of-life improvements
- `tmux.conf` - **New**: Recommended tmux configuration (you currently have none)

Each improved template includes comments explaining what's new and why.

## Notes

- All Ansible-managed blocks are clearly marked in config files
- Manual additions should be added outside managed blocks
- The Ansible setup preserves manual customizations
- Git hooks can be installed per-repository using the `install_hooks` function

---

**Last Updated**: 2026-04-01
**Maintained By**: Youcef Kadri
