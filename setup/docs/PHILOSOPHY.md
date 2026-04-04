# Setup Philosophy & Design Decisions

This document explains the "why" behind tool choices and configuration decisions, plus foundational concepts.

---

## What is X? - Core Concepts

Understanding the technologies that power this setup.

### What is Nix?

**Nix** is a package manager and build system with a unique approach:

**Traditional package managers** (apt, brew, pip):
```
Install package → Modifies system state → Hope it doesn't conflict
```

**Nix**:
```
Define package → Build in isolation → Install to /nix/store/<hash>
Multiple versions coexist peacefully
```

**Key features**:
- **Reproducible** - Same input = same output, always
- **Declarative** - Describe what you want, not how to get it
- **Atomic** - Upgrades/rollbacks are instant and safe
- **Multi-version** - Different projects can use different versions
- **Cross-platform** - Works on macOS and Linux

**How it works**:
- Packages installed to `/nix/store/abc123.../`
- Each package has unique hash based on inputs
- Your environment points to specific hashes
- Changes create new generation, old one stays

**Why use it**:
- Never breaks your system with updates
- Easy rollback if something goes wrong
- Reproduce exact environment on another machine
- Perfect for development environments

### What is Home-Manager?

**Home-manager** is a tool built on Nix for managing your user environment (~/).

**Without home-manager**:
```
# Install tools manually
brew install nvim tmux git

# Configure manually
cp .vimrc ~/
cp .tmux.conf ~/
cp .gitconfig ~/

# Repeat on every machine
# Hope you didn't forget anything
```

**With home-manager**:
```nix
# File: home.nix
programs.neovim.enable = true;
programs.tmux.enable = true;
programs.git = {
  enable = true;
  userName = "Your Name";
};
```

Run `home-manager switch` → everything configured!

**What it manages**:
- Package installation (nvim, tmux, git, etc.)
- Dotfiles (~/.config/nvim/, ~/.tmux.conf, etc.)
- Environment variables
- Shell configuration
- User services

**Why use it**:
- **Declarative** - Configuration as code
- **Idempotent** - Safe to run repeatedly
- **Reproducible** - Same config = same setup
- **Rollback** - Undo with one command
- **Version control** - Track changes in git

**The relationship**:
```
Nix (package manager)
  ↓
Home-Manager (user environment manager)
  ↓
Your dotfiles, tools, configurations
```

### What is LSP (Language Server Protocol)?

**LSP** is a protocol that separates language intelligence from editors.

**The old way** (pre-2016):
```
Each editor implements support for each language:
VSCode → Python, Rust, Go, Java...
Vim    → Python, Rust, Go, Java...
Emacs  → Python, Rust, Go, Java...

= N editors × M languages = Massive duplication
```

**The LSP way**:
```
Editors speak LSP protocol
  ↓
Language servers provide intelligence
  ↓
One server, all editors benefit
```

**Architecture**:
```
┌──────────┐              ┌─────────────┐
│  Editor  │ ←───LSP────→ │ Language    │
│ (Neovim) │              │ Server      │
│          │              │ (pyright)   │
└──────────┘              └─────────────┘
     ↓                           ↓
  Show UI              Analyze code:
  - Autocomplete       - Parse syntax
  - Errors             - Check types
  - Definitions        - Find references
```

**What LSP provides**:
1. **Autocomplete** - Intelligent suggestions as you type
2. **Go to definition** - Jump to where something is defined
3. **Find references** - See all uses of a symbol
4. **Hover** - Documentation popups
5. **Diagnostics** - Real-time errors/warnings
6. **Code actions** - Quick fixes, refactorings
7. **Rename** - Rename across entire codebase

**Language servers we use**:
- **pyright** - Python
- **rust-analyzer** - Rust
- **lua-language-server** - Lua
- **bash-language-server** - Bash
- **terraform-ls** - Terraform

**Why it matters**:
- Get IDE features in any editor
- Consistent experience across languages
- One server, maintained by language experts
- Works in terminal, over SSH, anywhere

### What is Vim? Neovim? LazyVim?

**The evolution of text editors**:

#### Vim (1991)

**What**: Improved version of Vi text editor

**Key concepts**:
- **Modal editing** - Different modes for different tasks:
  - Normal mode: Navigate and manipulate
  - Insert mode: Type text
  - Visual mode: Select text
  - Command mode: Run commands
- **Keyboard-driven** - No mouse needed
- **Composable commands** - `d` (delete) + `w` (word) = delete word

**Philosophy**: Efficiency through keyboard mastery

**Problem**: Configuration in Vimscript (awkward language), limited extensibility

#### Neovim (2014)

**What**: Modern rewrite of Vim

**Improvements**:
- **Lua configuration** - Modern, fast programming language
- **Built-in LSP** - Code intelligence native
- **Better plugin API** - Async, faster plugins
- **Maintained actively** - Regular releases, bug fixes
- **Backward compatible** - Vim plugins/configs work

**Still the problem**: Starting from scratch requires weeks of config

#### LazyVim (2023)

**What**: Preconfigured Neovim distribution

**Includes out-of-box**:
- Plugin manager (lazy.nvim)
- LSP configuration for 20+ languages
- Syntax highlighting (Treesitter)
- Fuzzy finder (Telescope)
- File explorer
- Git integration
- Autocomplete
- Beautiful UI
- Sensible keybindings

**Philosophy**: Neovim with batteries included, still customizable

**Think of it as**:
- Neovim = Car engine
- LazyVim = Pre-built car, ready to drive
- You can still modify everything

### What is Tmux?

**Tmux** = Terminal multiplexer

**What it does**:
- Run multiple terminal sessions in one window
- Keep sessions alive after disconnecting
- Split terminal into panes
- Create multiple windows
- Attach/detach from sessions

**Without tmux**:
```
Terminal window = One process
Close terminal = Lose everything
Multiple tasks = Multiple terminal windows
```

**With tmux**:
```
One terminal window:
  Session "project" (persists):
    Window 1: editor (split into 2 panes)
    Window 2: server logs
    Window 3: database client

Close terminal → sessions stay alive
Reopen terminal → tmux attach → back where you left off
```

**Key concepts**:
1. **Session** - Independent workspace (one per project)
2. **Window** - Like tabs (one for editor, one for server, etc.)
3. **Pane** - Split window (side-by-side terminals)

**Why use it**:
- Persistent sessions (survive disconnects)
- Organize work by project
- Split screen easily
- Works over SSH
- Integrates with sesh for project switching

### What is GPG?

**GPG** (GNU Privacy Guard) = Encryption tool based on PGP (Pretty Good Privacy)

**What it does**:
- **Encrypt** - Make data unreadable without key
- **Decrypt** - Recover original data with key
- **Sign** - Prove something came from you
- **Verify** - Confirm signature is authentic

**How it works**:
```
1. Generate key pair:
   - Private key (keep secret!)
   - Public key (share freely)

2. Encrypt data:
   Data + Public key → Encrypted data
   Only private key can decrypt

3. Decrypt data:
   Encrypted data + Private key → Original data
```

**Uses in our setup**:
- **Pass** - Encrypts passwords with your GPG key
- **Git signing** - Sign commits to prove authorship
- **Email** - Encrypt/decrypt emails (if needed)

**Key concepts**:
- **Passphrase** - Protects your private key
- **Key ID** - Unique identifier for your key
- **Trust** - How much you trust others' keys

**Why it matters**:
- Industry-standard encryption
- Battle-tested (30+ years)
- Open source, auditable
- Used everywhere (git, email, passwords)

### What is Pass?

**Pass** (password-store) = Unix philosophy password manager

**Philosophy**: Passwords are just encrypted files in a directory.

**Structure**:
```
~/.password-store/
├── github/
│   ├── personal-token.gpg    (encrypted file)
│   └── work-token.gpg
├── aws/
│   ├── access-key.gpg
│   └── secret-key.gpg
└── .gpg-id                   (your GPG key ID)
```

**How it works**:
1. Store password: `pass insert github/token`
   - Prompts for password
   - Encrypts with your GPG key
   - Saves to ~/.password-store/github/token.gpg
   - Commits to git (if enabled)

2. Retrieve password: `pass show github/token`
   - Prompts for GPG passphrase (once per session)
   - Decrypts file
   - Shows password

**Why use it**:
- **Simple** - Just files and directories
- **Secure** - GPG encryption (industry standard)
- **Git-backed** - Version control, sync
- **Command-line** - Scriptable, integrates with shell
- **Transparent** - You can see/backup files directly
- **No vendor lock-in** - It's just encrypted files

**vs 1Password/Bitwarden**: Less polished UI, but more control and simpler

---

## Core Principles

### 1. Declarative over Imperative

**Principle**: Define desired state, not steps to get there.

**Why**: 
- Reproducible - Same config = same result
- Idempotent - Safe to run multiple times
- Self-documenting - Config is documentation

**Implementation**:
- Using home-manager (declarative) instead of shell scripts (imperative)
- All configuration in version-controlled .nix files
- Can recreate entire environment from scratch

### 2. Minimal over Maximal

**Principle**: Start small, add only what you need.

**Why**:
- Easier to understand and maintain
- Faster shell startup
- Less to break

**Implementation**:
- Plain zsh instead of oh-my-zsh (faster, more control)
- Individual plugins (autosuggestions, syntax-highlighting) instead of plugin frameworks
- LazyVim (curated defaults) instead of building from scratch
- No plugins/tools "just in case" - only what's actively used

### 3. Modern over Traditional

**Principle**: Use modern tools when they're genuinely better.

**Why**:
- Performance improvements (Rust-based tools)
- Better UX (colored output, intuitive flags)
- Active development and support

**Examples**:
- `lsd` over `ls` - icons, colors, better formatting
- `ripgrep` over `grep` - 10x faster, better defaults
- `fd` over `find` - simpler syntax, faster
- `bat` over `cat` - syntax highlighting, line numbers
- `delta` over plain diff - side-by-side, syntax highlighting
- `zoxide` over `cd` - learns your patterns
- `atuin` over plain history - sync, search, context

**When NOT to replace**:
- Don't replace for replacement's sake
- Traditional tools when they work fine (git, make, etc.)

### 4. Rust-based Tools Preference

**Principle**: Prefer Rust implementations when available and mature.

**Why**:
- Performance - Often 2-10x faster than alternatives
- Safety - Memory-safe, fewer crashes
- Single binary - Easy distribution
- Modern defaults - Sensible out-of-the-box behavior

**Examples**:
- `ripgrep` (grep), `fd` (find), `bat` (cat), `lsd` (ls)
- `delta` (diff), `zoxide` (cd), `atuin` (history)
- `difftastic` (structural diff)
- `tokei` (code statistics)
- `sesh` (tmux session manager)

## Tool-Specific Decisions

### Shell: Zsh (not Bash, not Oh-My-Zsh)

**Why Zsh over Bash**:
- Better completion system
- Globbing features (recursive globs, extended patterns)
- Spelling correction
- Theme and plugin ecosystem
- Still POSIX-compatible for scripts

**Why NOT Oh-My-Zsh**:
- Heavy - loads 100+ plugins even if unused
- Slow startup - 300-500ms typical
- Black box - hard to understand what's loaded
- Over-featured - most features unused

**Our approach**:
- Plain zsh with 2-3 essential plugins
- Explicit configuration - know exactly what's loaded
- Fast startup - ~100ms
- Easy to customize

**Essential plugins**:
- `zsh-autosuggestions` - Fish-like suggestions from history
- `zsh-syntax-highlighting` - Colors for commands as you type
- That's it. Everything else is bloat.

### Editor: Neovim + LazyVim (not Vim, not VSCode)

**Why Neovim over Vim**:
- Modern Lua configuration (better than Vimscript)
- Built-in LSP support
- Better plugin ecosystem
- Faster and more actively developed
- Backward compatible with Vim configs

**Why LazyVim**:
- Sensible defaults out of the box
- Modern IDE features (LSP, Treesitter, Telescope)
- Well-documented
- Easy to customize
- Active community

**Why NOT VSCode**:
- VSCode is excellent and was considered
- Terminal-first workflow preference
- Neovim integrates better with tmux/terminal
- Lighter weight
- Full keyboard control

**Note**: Not dogmatic - use what works for you. LazyVim provides IDE features in terminal.

### Password Manager: Pass (not 1Password, not Bitwarden)

**Why Pass**:
- Open source, auditable
- GPG encryption - industry standard
- Git-backed - version control for passwords
- Simple - just encrypted files in a directory
- CLI-first - integrates with scripts
- No subscription or vendor lock-in
- Works offline

**Tradeoffs**:
- No browser extension (use CLI + clipboard)
- Manual setup (GPG keys, git)
- Less user-friendly than GUI tools

**Why NOT 1Password/Bitwarden**:
- Both are excellent tools
- Bitwarden is open source, was close second
- Pass chosen for:
  - Simpler architecture (files + GPG)
  - No server dependency
  - Terminal-native workflow
  - Free

**Note**: If you prefer GUI/browser integration, Bitwarden is a great alternative.

### Terminal Multiplexer: Tmux (not Screen, not native tabs)

**Why Tmux**:
- Persistent sessions - survive disconnects
- Multiple windows and panes
- Split screen
- Session sharing
- Scriptable
- Active development

**Why NOT Screen**:
- Tmux is more modern
- Better pane management
- More active development

**Why NOT native terminal tabs**:
- Tmux sessions persist across terminal closes
- Works over SSH
- More powerful splitting
- Session management (sesh integration)

### Python: uv (not pyenv, not pip)

**Why uv**:
- Fast - 10-100x faster than pip (Rust-based)
- Replaces multiple tools:
  - pip (package installer)
  - virtualenv (environment creation)
  - pyenv (Python version management)
- One tool to learn instead of three
- Modern, actively developed (by Astral, creators of ruff)

**Why NOT pyenv**:
- uv now handles Python version management
- One less tool to install and configure
- Faster
- Simpler workflow

**Migration path**:
```bash
# Old way:
pyenv install 3.12
pyenv local 3.12
python -m venv .venv
source .venv/bin/activate
pip install package

# New way:
uv python install 3.12
uv venv
source .venv/bin/activate
uv pip install package

# Or even simpler:
uv python pin 3.12
uv venv --python 3.12
uv pip install package
```

### Package Management: Home-manager (not Homebrew, not Ansible)

**Why Home-manager**:
- Declarative - define desired state
- Idempotent - safe to run repeatedly
- Atomic - all-or-nothing updates
- Rollback - can undo changes
- Reproducible - same config = same result
- Cross-platform - works on macOS and Linux
- Version controlled - track changes in git

**Why NOT Homebrew**:
- Homebrew is great, still useful for macOS-specific apps
- Home-manager provides:
  - Declarative config (Homebrew is imperative)
  - Dotfile management built-in
  - Atomic updates and rollback
  - Better reproducibility

**Why NOT Ansible**:
- Ansible is powerful, considered seriously
- Home-manager chosen for:
  - Simpler for single-user setups
  - Built-in dotfile management
  - Better package version management
  - Easier rollback
  - Less YAML

**Hybrid approach**:
- Home-manager for most things
- Homebrew for macOS-specific apps (Docker Desktop, etc.)
- Manual script for edge cases (sesh)

## Configuration Patterns

### Modular Configuration

**Pattern**: Split config into logical modules.

**Implementation**:
```
home-manager/
├── home.nix              # Main file, imports others
├── programs/
│   ├── shell.nix        # Shell config
│   ├── git.nix          # Git config
│   ├── neovim.nix       # Editor config
│   ├── tmux.nix         # Multiplexer config
│   └── cli-tools.nix    # CLI tools
└── packages.nix          # Package list
```

**Why**:
- Easy to find config for specific tool
- Can share modules between machines
- Clear separation of concerns
- Easier to understand

### Comments Explain Why, Not What

**Pattern**: Code shows what, comments explain why.

**Example**:
```nix
# Bad:
conflictstyle = "zdiff3";  # Set conflict style to zdiff3

# Good:
# zdiff3 shows common ancestor in conflicts, making them easier to resolve
conflictstyle = "zdiff3";
```

### Lazy Loading for Startup Performance

**Pattern**: Defer initialization until first use.

**Implementation**:
```zsh
# Instead of loading pyenv at startup:
eval "$(pyenv init - zsh)"  # 200ms startup cost

# Lazy-load when first used:
pyenv() {
  unset -f pyenv
  eval "$(command pyenv init - zsh)"
  pyenv "$@"
}  # 0ms startup cost, 200ms on first use
```

**Why**:
- Fast shell startup (~100ms vs ~500ms)
- Pay cost only when tool is used
- Most tools aren't used in most sessions

**Note**: With uv, we don't need pyenv anymore, making this pattern less necessary.

### Sensible Defaults with Escape Hatches

**Pattern**: Good defaults, easy to override.

**Implementation**:
- Most config provides good defaults
- Commented examples show how to customize
- Optional features commented out, easy to enable

**Example**:
```nix
# Working defaults:
auto_sync = false;

# Easy to change:
# To enable sync across machines:
# auto_sync = true;
```

## Security Considerations

### Password Management

**Principles**:
1. Never store secrets in plaintext
2. Never commit secrets to git
3. Use established encryption (GPG)
4. Keep secrets out of shell history

**Implementation**:
- Pass uses GPG encryption
- Atuin filters out `export` commands
- Shell functions for common secret operations
- Clipboard timeout (45 seconds)

### Git Configuration

**Principles**:
1. Prevent accidental secret commits
2. Use SSH over HTTPS
3. Verify commit authors

**Implementation**:
```nix
# Use SSH for GitHub (can use SSH keys with passphrase)
"url \"git@github.com:\"" = {
  insteadOf = "https://github.com/";
};

# Global gitignore prevents accidental commits
ignores = [
  ".env"
  ".env.local"
  # ... other secret files
];
```

### GPG Agent

**Configuration**:
```nix
defaultCacheTtl = 3600;     # 1 hour (not forever)
maxCacheTtl = 7200;         # 2 hours max
```

**Why**: Balance between security and convenience.

## Performance Optimizations

### Shell Startup

**Target**: <100ms startup time

**Techniques**:
1. Lazy-loading rarely used tools
2. Minimal plugins (just 2)
3. No oh-my-zsh overhead
4. Fast tools (Rust-based when possible)

**Measurement**:
```bash
# Measure startup time:
time zsh -i -c exit
```

### Tool Selection

**Performance-critical choices**:
- `ripgrep` over `grep` - 10x faster on large codebases
- `fd` over `find` - 5-10x faster
- `uv` over `pip` - 10-100x faster
- `lsd` uses caching for large directories

### LSP and Language Servers

**Balance**: Useful features vs resource usage

**Approach**:
- Install LSPs for languages you actually use
- Neovim lazy-loads plugins
- LSP starts only when needed

## Maintenance Strategy

### Updates

**Principle**: Regular updates, test before applying.

**Process**:
1. Update channels: `nix-channel --update`
2. Review changes (if any)
3. Apply: `home-manager switch`
4. Test essential workflows
5. Rollback if issues: `home-manager switch --rollback`

**Frequency**: Monthly, or when needed for specific tool.

### Rollback Strategy

**Principle**: Always have an escape hatch.

**Home-manager provides**:
- Generations - every `switch` creates new generation
- Rollback - can return to any previous generation
- Atomic - updates succeed or fail completely

**Usage**:
```bash
home-manager generations    # List generations
home-manager switch --rollback  # Go back one generation
```

### Configuration Changes

**Workflow**:
1. Edit config in `~/Documents/ydkadri/setup/`
2. Test: `home-manager switch`
3. Verify it works
4. Commit: `git commit -m "Add XYZ feature"`
5. If broken: `home-manager switch --rollback`

## Evolution and Future

### This Setup Will Change

**Expectation**: Tools evolve, needs change.

**Principles for changes**:
1. **Evaluate, don't chase trends** - New tool must be meaningfully better
2. **Document why** - Explain reasoning for future self
3. **Keep it simple** - Complexity is technical debt
4. **Test before committing** - Rollback is easy, but prevention is better

### When to Replace a Tool

**Good reasons**:
- Current tool is unmaintained
- New tool is significantly faster/better
- New tool solves real pain point
- Multiple tools can be replaced by one

**Bad reasons**:
- "Everyone is using it"
- Slightly nicer UI
- Has more features (that you don't need)

### Periodic Review

**Schedule**: Every 6-12 months

**Review questions**:
1. What tools did I not use at all?
2. What manual tasks could be automated?
3. What frustrated me repeatedly?
4. What new tools solve real problems?
5. Is the config still simple enough to understand?

---

**Last Updated**: 2026-04-01
