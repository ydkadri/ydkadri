# Workflow: Shell History Management

How to search and manage shell history efficiently using Atuin and FZF.

## The Problem

Default shell history is limited:
```bash
# Traditional history search (Ctrl+R)
- Shows one result at a time
- No context (date, directory, duration)
- Not searchable across machines
- Limited to text matching
- No statistics
```

**Example frustration**:
```bash
# You remember running a docker command last week...
# Press Ctrl+R
# Type "docker"
# Scroll through 100 docker commands
# Still can't find the one you need
# Give up, google it again
```

## The Solution

**Atuin + FZF** = Enhanced shell history with context, search, and sync.

### What is Atuin?

**Atuin** - Shell history replacement that tracks:
- Command executed
- When it ran
- Where it ran (directory)
- How long it took
- Exit status (success/failure)

**Features**:
- Better search (fuzzy, contextual)
- Optional sync across machines
- Statistics (most-used commands)
- Filters (by directory, date, status)

## Setup

Already configured in `programs/cli-tools.nix`:
- Auto-sync: disabled (privacy)
- Search mode: fuzzy
- Secrets filter: enabled (filters out sensitive commands)
- History filter: Excludes `export` commands

## Daily Usage

### Basic Search (Ctrl+R)

**Press `Ctrl+R`** in terminal:

```
┌─ Command History ──────────────────────────────────────┐
│ >                                                       │
│                                                         │
│ docker compose up -d                                    │
│ │ 2h ago · ~/repos/api-service · ✓ 2s                  │
│                                                         │
│ docker compose logs -f app                              │
│ │ 5h ago · ~/repos/api-service · ✓ 0s                  │
│                                                         │
│ docker ps                                               │
│ │ 1d ago · ~/repos/frontend · ✓ 0s                     │
└─────────────────────────────────────────────────────────┘
  ↑↓ Navigate · Enter: Execute · Tab: Edit · Esc: Cancel
```

**Type to filter**:
```
┌─ Command History ──────────────────────────────────────┐
│ > docker compose                                        │
│                                                         │
│ docker compose up -d                                    │
│ │ 2h ago · ~/repos/api-service · ✓ 2s                  │
│                                                         │
│ docker compose logs -f app                              │
│ │ 5h ago · ~/repos/api-service · ✓ 0s                  │
│                                                         │
│ docker compose down                                     │
│ │ 1d ago · ~/repos/api-service · ✓ 1s                  │
└─────────────────────────────────────────────────────────┘
```

**What you see**:
- Command text
- How long ago it ran
- Which directory
- Success (✓) or failure (✗)
- How long it took

### Search by Context

**Filter by current directory**:
```bash
# In ~/repos/api-service
$ atuin search --filter-mode directory docker

# Shows only docker commands run in this directory
```

**Filter by session**:
```bash
$ atuin search --filter-mode session

# Shows only commands from current terminal session
```

### Statistics

```bash
# Show most-used commands
$ atuin stats

Top Commands:
  1. git status          (847 times)
  2. cd                  (692 times)
  3. ls                  (531 times)
  4. nvim                (423 times)
  5. docker compose up   (312 times)

Top Directories:
  1. ~/repos/api-service (1,234 commands)
  2. ~/repos/frontend    (892 commands)
  3. ~/Documents/ydkadri (456 commands)

Session Duration:
  Average: 45m
  Longest: 3h 22m
```

### Export History

```bash
# Export to JSON
$ atuin history list --format json > history.json

# Export specific time range
$ atuin history list --after "2026-04-01" --before "2026-04-02"
```

## Key Bindings

In Atuin search interface:

```
Ctrl+R          - Open search
↑ / ↓          - Navigate results
Enter           - Execute command
Tab             - Insert command for editing (don't execute)
Ctrl+C / Esc    - Cancel
Ctrl+A          - Select all filters
```

## Advanced Features

### Fuzzy Search

Atuin uses fuzzy matching:
```
Search: "dcu"
Matches:
  - docker compose up
  - docker compose up -d
  - dc up  (if you have that alias)
```

### Exclude Sensitive Commands

Already configured to filter:
```bash
# These are NOT saved in history:
export API_KEY=secret
export TOKEN=abc123
password=mypass

# Secrets filter catches:
- AWS keys
- GitHub tokens
- Slack tokens
- Stripe keys
```

### Multi-line Commands

Atuin handles multi-line commands:
```bash
# This complex command is saved as one entry
$ docker run \
    -e API_KEY=secret \
    -p 8080:8080 \
    my-app:latest
```

Search for "docker run" finds it, complete with line breaks.

## Sync Across Machines (Optional)

### Enable Sync

If you want history across machines:

**Edit `programs/cli-tools.nix`**:
```nix
settings = {
  auto_sync = true;  # Change from false
  # ...
};
```

**Register account**:
```bash
$ atuin register -u yourusername -e your@email.com
$ atuin login -u yourusername
```

**Apply changes**:
```bash
$ home-manager switch
```

Now history syncs automatically across all machines!

### Privacy Considerations

**Sync disabled by default** because history contains sensitive info:
- Paths (reveal project structure)
- Commands (may contain API calls)
- Context (when/where you work)

**Enable only if**:
- You trust Atuin's servers (or self-host)
- You're okay with encrypted sync
- You want unified history

## Comparison: Default History vs Atuin

### Before (Default History)

```bash
$ history | grep docker
  1234  docker ps
  1456  docker compose up
  1567  docker logs app
  1789  docker ps

# No context, just command text
# Can't filter by directory or date
# Manual grep through thousands of entries
```

### After (Atuin)

```bash
$ atuin search docker

# Interactive UI with:
# - When it ran
# - Where it ran
# - How long it took
# - Success/failure
# - Fuzzy search
# - Sort by time/directory
```

## Common Workflows

### Workflow 1: Find Recent Command

**Scenario**: "What was that command I ran earlier today?"

```bash
# Press Ctrl+R
# Type a few letters
# See results filtered by time (recent first)
# Select and execute
```

### Workflow 2: Find Command in Project

**Scenario**: "How did I run tests in this project?"

```bash
# cd to project directory
$ cd ~/repos/api-service

# Press Ctrl+R
# Type "test"
# Atuin filters to commands run in this directory
# Find the test command
# Execute it
```

### Workflow 3: Avoid Retyping Complex Commands

**Scenario**: Long docker/curl command used occasionally

```bash
# Press Ctrl+R
# Type "curl api"
# Find: curl -H "Authorization: Bearer ..." https://api.example.com/...
# Press Tab (insert for editing)
# Modify as needed
# Execute
```

### Workflow 4: See What Failed

**Scenario**: "Which commands failed recently?"

```bash
$ atuin search --filter-mode global | grep "✗"

# Shows failed commands (exit code != 0)
# Helpful for debugging
```

## Tips & Tricks

### 1. Search from Anywhere

Atuin searches all history, regardless of current directory:
```bash
# Even in ~/Downloads
$ atuin search "docker compose up"

# Shows ALL times you ran it, in ANY directory
```

### 2. Quick Command Repeat

**Don't type `!!` (repeat last)**, use Atuin:
```bash
# Press Ctrl+R
# Press Enter (first result is last command)
```

### 3. Learn Your Patterns

```bash
$ atuin stats

# See what you use most
# Create aliases for frequent commands
```

### 4. Share Commands with Team

Export specific commands:
```bash
# Find useful command
$ atuin search "docker setup"

# Export it
$ atuin history list --filter "docker setup" --format json > setup-commands.json

# Share with team
```

### 5. Clear Sensitive Commands

If you accidentally ran a command with secrets:
```bash
# Delete from history
$ atuin history delete --filter "export API_KEY"

# Or delete recent commands
$ atuin history delete --after "10m ago"
```

## Troubleshooting

### Ctrl+R doesn't open Atuin

Check integration:
```bash
$ echo $ATUIN_SESSION

# Should show session ID
# If empty:
$ exec zsh  # Reload shell
```

### History not saving

Check atuin daemon:
```bash
$ atuin status

# Should show running
# If not:
$ atuin daemon &
```

### Sync not working

```bash
# Check sync status
$ atuin sync

# Force sync
$ atuin sync -f

# Check account
$ atuin account status
```

### Too many results

Use more specific search:
```bash
# Instead of:
$ atuin search git

# Use:
$ atuin search "git commit -m"

# Or filter by directory:
$ atuin search --filter-mode directory git
```

## Integration with FZF

Atuin uses FZF for the UI. FZF keybindings also work:

```
Ctrl+T    - Find files (FZF)
Ctrl+R    - Search history (Atuin via FZF)
Alt+C     - cd to directory (FZF with zoxide)
```

All use the same fuzzy-finding interface!

## Summary

**The workflow**:
1. Press `Ctrl+R`
2. Type a few letters
3. See commands with full context
4. Execute or edit

**The benefits**:
- ✅ Find commands faster (fuzzy search)
- ✅ See context (when, where, success/failure)
- ✅ Filter by directory or time
- ✅ Statistics on command usage
- ✅ Optional sync across machines

**The result**:
- Stop googling the same commands
- Reuse complex commands easily
- Understand your workflow patterns
- Never lose a useful command

---

**Next**: See [WORKFLOW_GIT.md](WORKFLOW_GIT.md) for git workflow with lazygit and gh CLI.

**Last Updated**: 2026-04-01
