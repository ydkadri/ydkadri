# Dotfiles Recommendations

**Status**: Actionable recommendations based on current workflow analysis

Recommendations for improving development environment setup, organized by priority and impact.

---

## 🔥 High Priority - Immediate Impact

### 1. Shell Startup Optimization

**Problem**: Shell startup is slow (~300-500ms) due to pyenv and nvm eager loading.

**Solution**: Lazy-load pyenv and nvm since you don't actively switch versions.

**Implementation**:
```zsh
# Replace in .zshrc (or add to Ansible common role)

# Lazy-load pyenv (only initialize when 'pyenv' command is called)
pyenv() {
  unset -f pyenv
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(command pyenv init - zsh)"
  pyenv "$@"
}

# Lazy-load nvm (or remove entirely if never used)
nvm() {
  unset -f nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}

# Keep atuin as-is (fast and necessary)
eval "$(atuin init zsh)"
```

**Expected improvement**: Shell startup from ~300-500ms → ~100ms

**Ansible integration**: Add to `roles/common/templates/zshrc.j2` or create new `roles/performance/` role

---

### 2. Password Management with Pass

**Problem**: GitHub token exposed in plaintext in `.zshrc`, security risk if ever committed.

**Solution**: Use `pass` (password-store) for secure credential management.

**Installation**:
```bash
brew install pass
brew install gnupg  # Dependency
```

**Setup**:
```bash
# 1. Create GPG key (one-time, if you don't have one)
gpg --gen-key
# Follow prompts: name, email, passphrase

# 2. Initialize password store
pass init "your-email@example.com"

# 3. Optional: Setup git sync for backup
pass git init
pass git remote add origin git@github.com:yourusername/password-store.git

# 4. Store GitHub token
pass insert github/personal-token
# Paste: ghp_YOUR_TOKEN_HERE

# 5. Sync to git
pass git push
```

**Shell integration** (replace exposed token in `.zshrc`):
```zsh
# Remove this line:
# export GITHUB_TOKEN=ghp_YOUR_ACTUAL_TOKEN

# Add this instead:
export GITHUB_TOKEN=$(pass github/personal-token 2>/dev/null || echo "")
```

**GPG agent configuration** (`~/.gnupg/gpg-agent.conf`):
```
default-cache-ttl 3600     # Cache for 1 hour
max-cache-ttl 7200         # Max 2 hours
```

**Usage**:
```bash
# Add new secret
pass insert work/aws-key

# Retrieve secret
pass github/personal-token

# Edit existing secret
pass edit github/personal-token

# List all secrets
pass

# Search secrets
pass grep token

# Sync to git
pass git push
```

**Benefits**:
- ✅ No plaintext secrets in shell config
- ✅ GPG encrypted at rest
- ✅ Git-based backup and sync
- ✅ CLI-first workflow
- ✅ Integrates seamlessly with existing tools

**Ansible integration**: Create `roles/secrets/` role for pass setup and GPG configuration

---

## 🚀 High Value - Workflow Enhancement

### 3. Project Context Switching: sesh + zoxide

**Problem**: Frequent context switching between repos, manual `cd ~/repos/project` and tmux session management is tedious.

**Solution**: Combine `sesh` (tmux session manager) and `zoxide` (smart directory jumping).

#### Install zoxide

```bash
brew install zoxide

# Add to .zshrc
eval "$(zoxide init zsh)"
```

**Usage**:
```bash
# After a few days of use, zoxide learns your patterns
z mapper          # Jumps to ~/repos/mapper
z dotfiles        # Jumps to ~/repos/data-dotfiles
z ydkadri         # Jumps to ~/Documents/ydkadri

# Interactive selection when ambiguous
zi map            # Shows all matches with 'map'
```

#### Install sesh

```bash
# Via Homebrew
brew install joshmedeski/sesh/sesh

# Or via cargo
cargo install sesh
```

**Tmux integration** (`~/.tmux.conf`):
```bash
# Bind Ctrl+A T for sesh (adjust binding to preference)
bind-key "T" run-shell "sesh connect \"$(
  sesh list | fzf-tmux -p 55%,60% \
    --no-sort --border-label ' sesh ' --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^x zoxide ^d tmux kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
    --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
)\""
```

**Usage**:
```bash
# From shell (creates/attaches to tmux session)
sesh connect mapper

# From within tmux (press Ctrl+A T)
# - Shows list of: existing sessions + zoxide directories + repos
# - Fuzzy search: type "map" → matches "mapper" session or ~/repos/mapper
# - Press enter → switches to session or creates new one

# List sessions and directories
sesh list

# List only tmux sessions
sesh list -t

# List only zoxide directories
sesh list -z
```

**Workflow**:
1. Press `Ctrl+A T` in any tmux session (or from shell)
2. Type partial project name: `map`
3. See: existing "mapper" tmux session OR ~/repos/mapper directory
4. Press enter → switch/create session, auto-cd to directory

**Benefits**:
- ✅ One keybind for all project switching
- ✅ Integrates with zoxide (frecency-based suggestions)
- ✅ No config files needed (unlike tmuxp/tmuxinator)
- ✅ Rust-based (fast)
- ✅ Works with existing manual session workflow

**Ansible integration**:
- Add to `roles/extras/defaults/main.yml`: `rust_tools: [sesh, ...]`
- Add to `roles/common/tasks/install-homebrew.yml`: `homebrew_apps: [zoxide, ...]`
- Create tmux.conf template in `roles/common/templates/`

---

### 4. Streamlined Gists and CLI Notes

**Problem**: No easy workflow for capturing quick notes, snippets, or gists from CLI.

#### Option A: GitHub Gists (gh CLI)

You already have `gh` CLI installed (via 1password-cli homebrew cask). Enable gist commands:

```bash
# Check if already configured
gh auth status

# If needed, authenticate
gh auth login

# Create gist from file
gh gist create mysnippet.sh -d "Useful shell snippet"

# Create gist from stdin
echo "alias l='lsd -lrth'" | gh gist create -d "My aliases" -

# Create from clipboard
pbpaste | gh gist create -d "Quick note" -

# List your gists
gh gist list

# View gist
gh gist view <gist-id>

# Edit gist (opens in $EDITOR)
gh gist edit <gist-id>

# Clone gist for local editing
gh gist clone <gist-id>
```

**Create shell functions** for common workflows (`~/.managed/common/functions.sh`):
```bash
# Quick gist from clipboard
gist-clip() {
  local desc="${1:-Quick note}"
  pbpaste | gh gist create -d "$desc" -
}

# Quick gist from file
gist-file() {
  if [[ -z "$1" ]]; then
    echo "Usage: gist-file <file> [description]"
    return 1
  fi
  local desc="${2:-$(basename $1)}"
  gh gist create "$1" -d "$desc"
}

# Search my gists
gist-search() {
  gh gist list --limit 50 | grep -i "$1"
}
```

**Usage**:
```bash
# Copy code to clipboard, then
gist-clip "Ansible lazy-load pattern"

# From file
gist-file ~/.zshrc "My zsh config"

# Search your gists
gist-search "ansible"
```

#### Option B: LogSeq CLI Notes

Create simple shell function to add notes to LogSeq from CLI (`~/.managed/common/functions.sh`):

```bash
# Add quick note to today's LogSeq page
lnote() {
  if [[ -z "$1" ]]; then
    echo "Usage: lnote <note text>"
    return 1
  fi
  
  local date=$(date +%Y-%m-%d)
  local logseq_dir="$HOME/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents/LogSeq"
  local file="${logseq_dir}/pages/${date}.md"
  
  # Create file if it doesn't exist
  if [[ ! -f "$file" ]]; then
    echo "---" > "$file"
    echo "title: ${date}" >> "$file"
    echo "---" >> "$file"
    echo "" >> "$file"
  fi
  
  # Append note with timestamp
  echo "- $(date +%H:%M) - $*" >> "$file"
  echo "✓ Added to LogSeq: $*"
}

# Add note with tag
lnote-tag() {
  if [[ -z "$2" ]]; then
    echo "Usage: lnote-tag <tag> <note text>"
    return 1
  fi
  
  local tag="$1"
  shift
  lnote "#${tag} $*"
}

# Search LogSeq notes
lnote-search() {
  local logseq_dir="$HOME/Library/Mobile Documents/iCloud~com~logseq~logseq/Documents/LogSeq"
  grep -r "$1" "${logseq_dir}/pages/" --color=always
}
```

**Usage**:
```bash
# Quick note
lnote "Remember to lazy-load pyenv for faster shell startup"

# Note with tag
lnote-tag ansible "Use lazy-loading pattern for slow init scripts"

# Search notes
lnote-search "pyenv"
```

**Benefits**:
- ✅ Gists: Public/private code sharing, GitHub integration
- ✅ LogSeq: Personal notes, synced across devices
- ✅ Both work from CLI without leaving terminal
- ✅ No new tools to learn (gh CLI already installed, LogSeq already used)

**Ansible integration**: Add functions to `roles/common/files/functions.sh`

---

## 💡 Nice to Have - Quality of Life

### 5. Better Tmux Configuration

Create `~/.tmux.conf` with modern defaults:

```bash
# True color support
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

# Mouse support
set -g mouse on

# Vim-like pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer
set -g history-limit 50000

# Status bar
set -g status-position top
set -g status-bg colour235
set -g status-fg colour255

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes with current directory
bind '"' split-window -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
```

**Ansible integration**: Create `roles/common/templates/tmux.conf.j2`

---

### 6. AWS CLI Enhancements

Since AWS is your primary cloud, consider these improvements:

**Install aws-vault** (secure credential management):
```bash
brew install aws-vault

# Store credentials
aws-vault add personal

# Execute with temporary credentials
aws-vault exec personal -- aws s3 ls

# Shell with temp credentials
aws-vault exec personal -- zsh
```

**Or install awsume** (profile switching):
```bash
pipx install awsume

# Switch profiles
awsume personal
awsume work-admin
```

**Add shell functions** for common AWS operations:
```bash
# Quick profile switching
aws-profile() {
  export AWS_PROFILE="$1"
  echo "✓ AWS profile set to: $1"
}

# List available profiles
aws-profiles() {
  cat ~/.aws/config | grep '\[profile' | sed 's/\[profile //' | sed 's/\]//'
}

# Get current caller identity
aws-whoami() {
  aws sts get-caller-identity
}
```

---

### 7. Enhanced Git Workflow

**Install git-delta** for better diffs (alternative to difftastic):
```bash
brew install git-delta
```

**Or stick with difftastic but add git aliases**:
```gitconfig
[alias]
    # Quick diff views
    df = difftool
    dfs = difftool --staged
    dfc = difftool HEAD^
    
    # Interactive staging with difftastic
    ap = add -p
    
    # Show files changed
    changed = diff --name-only
    
    # Show commits not yet pushed
    unpushed = log @{u}..
```

---

### 8. Modern Unix Tools (Rust alternatives)

You already have some Rust tools (`lsd`, `atuin`). Consider adding:

```bash
# bat - Better cat with syntax highlighting
brew install bat
alias cat='bat --style=plain'

# ripgrep - Better grep (you might already have this)
brew install ripgrep
alias grep='rg'

# fd - Better find
brew install fd
alias find='fd'

# bottom - Better top/htop
brew install bottom
alias top='btm'

# dust - Better du
brew install dust
alias du='dust'

# procs - Better ps
brew install procs
alias ps='procs'
```

**Or add selectively** based on what you actually use. Start with `bat` and `ripgrep` (most universally useful).

**Ansible integration**: Add to `roles/extras/defaults/main.yml` rust_tools list

---

## 📋 Summary: Recommended Action Plan

### Phase 1: Security & Performance (Do First)
1. ✅ **Set up Pass** for password management
2. ✅ **Optimize shell startup** with lazy-loading
3. ✅ **Remove plaintext token** from .zshrc

### Phase 2: Workflow Enhancement (High Value)
4. ✅ **Install zoxide** for smart directory jumping
5. ✅ **Install sesh** for tmux session management
6. ✅ **Configure tmux.conf** with sesh binding

### Phase 3: CLI Tools (Quality of Life)
7. ✅ **Add gh gist functions** for quick snippets
8. ✅ **Add LogSeq CLI functions** for notes
9. ✅ **Improve tmux config** with modern defaults

### Phase 4: Optional Enhancements
10. ⚪ AWS CLI improvements (aws-vault or awsume)
11. ⚪ Additional Rust tools (bat, ripgrep, fd)
12. ⚪ Enhanced git aliases

---

## 🔧 Ansible Role Updates (For Later)

When you're ready to update the Ansible repository, here's the structure:

```
roles/
├── common/
│   ├── files/
│   │   └── functions.sh          # Add gist-*, lnote-* functions
│   ├── templates/
│   │   ├── tmux.conf.j2          # Tmux configuration
│   │   └── zshrc-lazy-load.j2    # Lazy-loading snippets
│   └── tasks/
│       └── optimize-shell.yml     # Shell optimization tasks
├── secrets/
│   ├── tasks/
│   │   └── main.yml              # Pass installation and GPG setup
│   └── templates/
│       └── gpg-agent.conf.j2     # GPG agent configuration
└── extras/
    └── defaults/
        └── main.yml              # Add: sesh, zoxide to rust_tools/homebrew_apps
```

---

## 📚 Additional Resources

**Pass (password-store)**:
- Official site: https://www.passwordstore.org/
- Tutorial: https://git.zx2c4.com/password-store/about/

**sesh**:
- GitHub: https://github.com/joshmedeski/sesh
- Video demo: https://www.youtube.com/watch?v=GH3kpsbbERo

**zoxide**:
- GitHub: https://github.com/ajeetdsouza/zoxide
- Comparison to alternatives: https://github.com/ajeetdsouza/zoxide#comparison

**Shell startup optimization**:
- zsh-bench: https://github.com/romkatv/zsh-bench (measure your shell)
- General guide: https://htr3n.github.io/2018/07/faster-zsh/

---

**Last Updated**: 2026-04-01
**Maintained By**: Youcef Kadri
