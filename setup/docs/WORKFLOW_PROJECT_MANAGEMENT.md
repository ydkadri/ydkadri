# Workflow: Project & Terminal Management

How to efficiently manage multiple projects and terminal sessions using tmux, sesh, zoxide, and fzf.

## The Problem

As a developer, you:
- Work on multiple projects simultaneously
- Each project has its own directory, git repo, services
- Need to context switch frequently
- Want to resume where you left off
- Lose time navigating directories and opening terminals

**Traditional approach**:
```bash
# Switching to project1
cd ~/repos/project1
# Open multiple terminal tabs/windows
# Start services manually
# Repeat for project2, project3...
# Close terminal, lose everything, start over next day
```

## The Solution

**Tmux + Sesh + Zoxide + FZF** = Fast project switching with persistent sessions.

### The Stack

1. **Tmux** - Terminal multiplexer (persistent sessions, windows, panes)
2. **Sesh** - Tmux session manager (quick project switching)
3. **Zoxide** - Smart directory jumping (learns your patterns)
4. **FZF** - Fuzzy finder (quick selection from lists)

## How It Works Together

```
┌─────────────────────────────────────────────────────┐
│  You want to work on "api-service"                  │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Press Ctrl+B T  (tmux keybinding)                  │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Sesh shows list of:                                │
│  - Existing tmux sessions                           │
│  - Recent directories (from zoxide)                 │
│  - Project directories                              │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  FZF fuzzy search: type "api"                       │
│  Matches: ~/repos/api-service                       │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Select → Sesh creates/attaches tmux session        │
│  - Session named "api-service"                      │
│  - Working directory: ~/repos/api-service           │
│  - Ready to work!                                   │
└─────────────────────────────────────────────────────┘
```

## Daily Workflow

### Morning: Starting Work

```bash
# Open terminal
$ tmux

# Press Ctrl+B T (or use 'work' command)
# Type first few letters of project
# Hit Enter

# You're now in project directory with persistent session
```

### During Day: Switching Projects

**In tmux, press `Ctrl+B T`**:

```
┌─────────────────────────────────────────────────────┐
│ sesh                                                │
├─────────────────────────────────────────────────────┤
│ ⚡                                                   │
│ > api-service          (current session)            │
│   frontend-app         (existing session)           │
│   data-pipeline        (zoxide - recent dir)        │
│   ml-experiments       (zoxide - recent dir)        │
│   ~/repos/new-project  (directory search)           │
└─────────────────────────────────────────────────────┘
  ^a all  ^t tmux  ^x zoxide  ^d kill  ^f find
```

**Type a few letters** → select → instantly switch to that project.

### Evening: Ending Work

```bash
# Just close terminal
# All tmux sessions stay alive in background

# Next morning: reattach
$ tmux attach
# or
$ tmux

# Press Ctrl+B T to see all your sessions from yesterday
# Everything preserved: windows, panes, working directories
```

## Key Features Explained

### Tmux: Persistent Sessions

**What it does**: Keeps your terminal state alive even after closing terminal.

**Session = Project**:
```
Session "api-service":
  Window 1: editor (nvim)
  Window 2: server (running flask)
  Window 3: database (psql)
  Window 4: logs (tail -f)
```

Close terminal, come back later → everything still there.

**Basic tmux commands**:
```bash
# Start tmux
$ tmux

# Create new window
Ctrl+B c

# Switch windows
Ctrl+B 0-9  (window number)
Ctrl+B n    (next)
Ctrl+B p    (previous)

# Split panes
Ctrl+B |    (vertical split)
Ctrl+B -    (horizontal split)

# Navigate panes
Ctrl+B h/j/k/l  (vim-like navigation)

# Kill window
Ctrl+B &

# Detach from session
Ctrl+B d

# List sessions
$ tmux ls

# Attach to session
$ tmux attach -t api-service
```

### Sesh: Session Manager

**What it does**: Makes switching between projects instant.

**Three modes**:

1. **All mode** (`Ctrl+B` in sesh): Shows everything
   - Existing tmux sessions
   - Recent directories (zoxide)
   - New directories

2. **Tmux mode** (`Ctrl+T` in sesh): Only tmux sessions
   - Quick switch between active sessions

3. **Zoxide mode** (`Ctrl+X` in sesh): Only recent directories
   - Jump to recently-visited directories
   - Creates new session if needed

4. **Find mode** (`Ctrl+F` in sesh): Search filesystem
   - Find any directory
   - Create session for it

**Keybindings in sesh picker**:
```
Tab/Shift+Tab  - Navigate list
Enter          - Select
Ctrl+B         - Show all (tmux + zoxide + directories)
Ctrl+T         - Show only tmux sessions
Ctrl+X         - Show only zoxide directories
Ctrl+F         - Find directories
Ctrl+D         - Kill selected session
Esc            - Cancel
```

### Zoxide: Smart Directory Jumping

**What it does**: Remembers where you go, lets you jump with partial names.

**Learning phase**:
```bash
# First time, use full paths
$ cd ~/repos/api-service
$ cd ~/repos/frontend-app
$ cd ~/repos/data-pipeline
```

**After a few visits**:
```bash
# Just use short names
$ cd api       → jumps to ~/repos/api-service
$ cd front     → jumps to ~/repos/frontend-app
$ cd data      → jumps to ~/repos/data-pipeline

# Even works with typos/fuzzy matching
$ cd apiserv   → jumps to ~/repos/api-service
```

**Zoxide commands**:
```bash
# Jump to directory (replaces cd)
$ cd api-service

# Interactive selection if multiple matches
$ cd api
> api-service
  api-gateway
  api-docs

# Query without jumping
$ zoxide query api

# List all directories (sorted by frequency)
$ zoxide query -l

# Remove directory from database
$ zoxide remove ~/old-project
```

### FZF: Fuzzy Finder

**What it does**: Fast searching/filtering of lists.

**Built-in keybindings**:
```bash
# Search command history
Ctrl+R

# Find files in current directory
Ctrl+T

# cd to directory
Alt+C  (or Esc+C on macOS)
```

**In sesh/other tools**: Provides the fuzzy search interface.

**Fuzzy matching**:
```
Type: "apisvc"
Matches: "api-service", "api_service", "API-Service"
```

## Example Workflows

### Workflow 1: Daily Work on Multiple Projects

**Morning**:
```bash
# Start tmux
$ tmux

# Open API project (Ctrl+B T, type "api", Enter)
# Now in: ~/repos/api-service

# Create panes for different tasks
Ctrl+B |      # Split vertically
# Left pane: editor
$ nvim src/main.py

# Right pane: server
$ just run    # Start dev server

# Create new window for database
Ctrl+B c
$ psql mydb
```

**Mid-day - switch to frontend**:
```bash
# In tmux, press Ctrl+B T
# Type "front", Enter
# Now in: ~/repos/frontend-app

# API session still running in background!
```

**Return to API**:
```bash
# Ctrl+B T
# Select "api-service"
# Back to API session, server still running
```

**End of day**:
```bash
# Just close terminal
# All sessions preserved
```

**Next morning**:
```bash
$ tmux
# Press Ctrl+B T
# All yesterday's sessions listed
# Pick up exactly where you left off
```

### Workflow 2: Quick Investigation

**Scenario**: Need to check something in an old project.

```bash
# In any terminal/tmux session
Ctrl+B T

# Type "old-proj"
# Select it
# Instantly in that directory, new session created

# Do your work
$ git log
$ cat README.md

# Done, switch back
Ctrl+B T
# Select original session
```

### Workflow 3: New Project Setup

```bash
# Create project directory
$ mkdir -p ~/repos/new-project
$ cd ~/repos/new-project

# Initialize
$ git init
$ uv init

# Create tmux session for it
$ exit  # Exit to base shell
$ tmux

# Ctrl+B T
# Type "new-proj"
# Select ~/repos/new-project
# Session created, you're in the directory

# Set up project panes
Ctrl+B |   # Editor pane
Ctrl+B -   # Test runner pane
Ctrl+B c   # New window for server
```

From now on: `Ctrl+B T` → type "new" → instant access.

## Shell Function: `work`

Alternative to `Ctrl+B T` if not in tmux:

```bash
$ work

# Opens fzf with zoxide directories
# Select one
# Creates new tmux session and switches to it
```

Defined in `programs/shell.nix`:
```zsh
work() {
  local project=$(zoxide query -l | fzf --height 40% --reverse --preview 'ls -la {}')
  if [[ -n "$project" ]]; then
    sesh connect "$(basename "$project")"
  fi
}
```

## Tips & Tricks

### Naming Sessions

Sesh automatically names sessions based on directory:
```
~/repos/api-service     → session: "api-service"
~/Documents/notes       → session: "notes"
~/work/client/project   → session: "project"
```

Manual naming:
```bash
$ tmux new -s custom-name
```

### Organizing Projects

Keep consistent directory structure:
```
~/repos/           # All code projects
~/Documents/       # Documentation, notes
~/work/           # Work-specific projects
```

Zoxide learns these patterns, making jumps more accurate.

### Multiple Windows per Session

One session = one project, but multiple windows for different aspects:

```
Session "api-service":
  Window 0: editor
  Window 1: server
  Window 2: tests
  Window 3: database
  Window 4: logs
```

Quick navigation: `Ctrl+B 0-4`

### Detach and Background Work

```bash
# In tmux session, start long-running task
$ cargo build --release

# Detach (leave it running)
Ctrl+B d

# Come back later
$ tmux attach -t project-name

# Build still running or completed
```

### Kill Sessions You Don't Need

```bash
# Via sesh
Ctrl+B T
Ctrl+D  (on selected session)

# Via tmux
$ tmux kill-session -t session-name

# Kill all except current
$ tmux kill-session -a
```

### Copy Between Panes/Windows

```bash
# Enter copy mode
Ctrl+B [

# Navigate with vim keys (h/j/k/l)
# Start selection: v
# Copy: y

# Paste in another pane/window
Ctrl+B ]
```

## Comparison: Before vs After

### Before (Traditional)

```bash
# Morning routine:
cd ~/repos/api-service
code .
# New tab
cd ~/repos/api-service
python manage.py runserver
# New tab
cd ~/repos/api-service
psql mydb
# New tab
cd ~/repos/frontend-app
npm start

# Close laptop
# Everything gone
# Repeat tomorrow
```

**Problems**:
- Manual directory navigation
- Lose everything when terminal closes
- Hard to switch between projects
- No persistence

### After (This Workflow)

```bash
# Morning:
tmux
Ctrl+B T
# Type "api", Enter
# Everything from yesterday still there
# Or start fresh if needed

# Switch to frontend:
Ctrl+B T
# Type "front", Enter
# Done

# Close laptop
# Everything preserved

# Tomorrow:
tmux
# All sessions from yesterday ready
```

**Benefits**:
- ✅ Instant project switching (2-3 keystrokes)
- ✅ Sessions persist across terminal closes
- ✅ Smart directory jumping (zoxide learns)
- ✅ Multiple projects in background
- ✅ Resume exactly where you left off

## Troubleshooting

### Sesh picker doesn't show up

Check sesh is installed:
```bash
$ which sesh
$ sesh --version
```

If missing, run:
```bash
$ bash ~/Documents/ydkadri/setup/manual/install.sh
```

### Zoxide not learning directories

Make sure you're using `cd`, not direct paths:
```bash
# This teaches zoxide:
$ cd ~/repos/project

# This doesn't:
$ ~/repos/project/script.sh
```

### Tmux sessions lost on reboot

Tmux sessions are in-memory, not persistent across reboots.

For true persistence, see commented tmux plugins in `programs/tmux.nix`:
- `resurrect` - Save/restore sessions
- `continuum` - Auto-save sessions

### FZF keybindings not working

Restart shell:
```bash
$ exec zsh
```

Or check FZF is integrated:
```bash
$ echo $FZF_DEFAULT_OPTS
```

Should show options like `--height 40%`.

## Learning Path

### Week 1: Learn Tmux Basics
- Start tmux: `tmux`
- Create windows: `Ctrl+B c`
- Split panes: `Ctrl+B |` and `Ctrl+B -`
- Navigate: `Ctrl+B h/j/k/l`
- Detach/attach: `Ctrl+B d`, `tmux attach`

### Week 2: Add Zoxide
- Use `cd` for all directory navigation
- Let zoxide learn your patterns
- Start using short names: `cd api` instead of `cd ~/repos/api-service`

### Week 3: Add Sesh + Project Workflow
- `Ctrl+B T` to open sesh
- Create sessions for each project
- Practice switching between projects
- Keep sessions alive overnight

### Month 2: Advanced Usage
- Multiple windows per session
- Custom session layouts
- Background long-running tasks
- Copy/paste between panes

## Summary

**The workflow**:
1. Start tmux
2. Press `Ctrl+B T` (sesh)
3. Type a few letters
4. Hit Enter
5. You're in the project with full context

**The benefits**:
- Instant project switching
- Persistent sessions
- Smart directory jumping
- No mental overhead

**The result**:
- Spend less time navigating
- Spend more time coding
- Context preserved across days
- Multiple projects managed effortlessly

---

**Next**: See [WORKFLOW_TEXT_EDITING.md](WORKFLOW_TEXT_EDITING.md) for Neovim + LazyVim workflow.

**Last Updated**: 2026-04-01
