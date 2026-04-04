# Workflow: Git Operations

How to work with git efficiently using lazygit, gh CLI, and enhanced git configuration.

## The Problem

Git command-line can be verbose and error-prone:
```bash
# Traditional git workflow
$ git status
$ git add file1.py file2.py
$ git commit -m "Fix bug"
$ git push

# Viewing diffs
$ git diff  # Plain text, hard to read

# Interactive rebase
$ git rebase -i HEAD~5  # Opens editor, manual editing

# Managing branches
$ git branch -a  # Lists branches
$ git branch -d old-branch
$ git push origin --delete old-branch  # Two commands to delete remote

# GitHub operations
$ open https://github.com/user/repo/pulls  # Switch to browser
# Click through UI to create PR
```

## The Solution

**Lazygit + gh CLI + Enhanced Git Config** = Efficient git operations in terminal.

### The Stack

1. **Git** - Version control (with better configuration)
2. **Lazygit** - Terminal UI for git operations
3. **gh CLI** - GitHub command-line tool
4. **Delta** - Better diff viewer

## Lazygit: Terminal UI

### Opening Lazygit

```bash
# From command line
$ lazygit

# From Neovim
Space g g
```

### What You See

```
┌─ Status ─────────────────────────────────────────────────┐
│ Files                                                     │
│ ● src/main.py                      Modified              │
│ ● src/api.py                       Added                 │
│ ● README.md                        Modified              │
│                                                           │
│ [space] stage │ [c] commit │ [P] push │ [p] pull │ [q] quit
├─ Branches ──────────────────────────────────────────────┤
│ ● feature/new-endpoint                                   │
│   main                                                   │
│   fix/bug-123                                            │
├─ Commits ───────────────────────────────────────────────┤
│ abc1234 Add new API endpoint               (2h ago)      │
│ def5678 Fix authentication bug              (5h ago)      │
│ ghi9012 Update README                       (1d ago)      │
├─ Diff ──────────────────────────────────────────────────┤
│ @@ -10,3 +10,7 @@                                        │
│   def process_data(items):                               │
│ +     if not items:                                      │
│ +         return {}                                      │
│       result = {}                                        │
└──────────────────────────────────────────────────────────┘
```

**Panels**:
1. **Status** - Unstaged/staged files
2. **Branches** - Local and remote branches
3. **Commits** - Commit history
4. **Diff** - Changes in selected file
5. **Stash** - Stashed changes

### Basic Workflow

**1. Stage files**:
```
j/k          - Move up/down files
space        - Stage/unstage file
a            - Stage all files
d            - Discard changes
e            - Edit file (opens in $EDITOR)
```

**2. Commit**:
```
c            - Commit staged changes
# Type message in editor, save and close
```

**3. Push/Pull**:
```
P            - Push to remote
p            - Pull from remote
```

That's it! Visual, intuitive, fast.

### Advanced Operations

**Branching**:
```
# In Branches panel
n            - New branch
space        - Checkout branch
d            - Delete branch
r            - Rename branch
M            - Merge into current branch
R            - Rebase current branch
```

**Stashing**:
```
# In Files panel
s            - Stash changes
# In Stash panel
space        - Apply stash
g            - Pop stash
d            - Drop stash
```

**Interactive Rebase**:
```
# In Commits panel
e            - Edit commit
s            - Squash commits
r            - Reword commit message
d            - Drop commit
p            - Pick commit (undo squash/drop)
```

**Cherry-pick**:
```
# In Commits panel
c            - Copy commit SHA
# Switch to target branch
v            - Cherry-pick commit
```

**Resolving Conflicts**:
```
# During merge/rebase with conflicts
# In Files panel
space        - Stage resolved file
e            - Edit file manually
# After resolving all
continue     - Continue merge/rebase
abort        - Abort operation
```

### Panels & Navigation

```
1 - Status panel
2 - Files panel
3 - Branches panel
4 - Commits panel
5 - Stash panel

Tab          - Switch between panels
j/k          - Navigate within panel
h/l          - Switch tabs in panel
?            - Help (show all keybindings)
q            - Quit
```

## gh CLI: GitHub Operations

### Authentication

```bash
# Login (first time)
$ gh auth login

# Follow prompts:
# - GitHub.com
# - SSH protocol
# - Authenticate via browser
```

### Pull Requests

**Create PR**:
```bash
# From feature branch
$ gh pr create --title "Add new feature" --body "Description here"

# Interactive (fills in details automatically)
$ gh pr create
# Prompts for title, body, reviewers, etc.

# With template
$ gh pr create --template bug_fix.md
```

**List PRs**:
```bash
# List your PRs
$ gh pr list

# List all open PRs
$ gh pr list --state open

# Filter by author
$ gh pr list --author @me
```

**View PR**:
```bash
# View in terminal
$ gh pr view 123

# View in browser
$ gh pr view 123 --web

# View diff
$ gh pr diff 123
```

**Checkout PR**:
```bash
# Checkout PR locally
$ gh pr checkout 123

# Creates local branch tracking PR
```

**Merge PR**:
```bash
# Merge PR
$ gh pr merge 123

# Options
$ gh pr merge 123 --merge     # Regular merge
$ gh pr merge 123 --squash    # Squash merge
$ gh pr merge 123 --rebase    # Rebase merge
```

**Review PR**:
```bash
# Approve
$ gh pr review 123 --approve

# Request changes
$ gh pr review 123 --request-changes --body "Please fix..."

# Comment
$ gh pr review 123 --comment --body "Looks good!"
```

### Issues

```bash
# Create issue
$ gh issue create --title "Bug: API endpoint broken" --body "Details..."

# List issues
$ gh issue list

# View issue
$ gh issue view 456

# Close issue
$ gh issue close 456

# Reopen issue
$ gh issue reopen 456
```

### Repositories

```bash
# View repo
$ gh repo view

# Clone repo
$ gh repo clone user/repo

# Create repo
$ gh repo create my-new-repo --public

# Fork repo
$ gh repo fork user/repo
```

### Workflows (GitHub Actions)

```bash
# List workflows
$ gh workflow list

# View workflow runs
$ gh run list

# View specific run
$ gh run view 123456

# Watch run (live)
$ gh run watch

# Rerun failed jobs
$ gh run rerun 123456
```

### Gists

```bash
# Create gist
$ gh gist create file.py --desc "Python script"

# List your gists
$ gh gist list

# View gist
$ gh gist view abc123

# Edit gist
$ gh gist edit abc123
```

**Helper functions** (in `programs/shell.nix`):
```bash
# Create gist from file
$ gist-create file.py "Description"

# List gists
$ gist-list

# View gist
$ gist-view abc123
```

## Enhanced Git Configuration

### Useful Aliases (Already Configured)

```bash
# Status and logs
$ git st         # git status
$ git lg         # Pretty log graph
$ git lg1        # Even prettier log

# Branching
$ git co main    # git checkout main
$ git cob feat   # git checkout -b feat

# Committing
$ git ct         # git commit
$ git ctm "msg"  # git commit -m "msg"
$ git amend      # git commit --amend --no-edit

# Pushing
$ git ps         # git push
$ git psfl       # git push --force-with-lease (safer force push)
$ git psh        # git push -u origin HEAD

# Rebasing
$ git rb         # git rebase
$ git rbi        # git rebase --interactive

# History
$ git recent     # Show recent branches
$ git last       # Files changed in last commit
$ git outgoing   # What would be pushed

# Cleanup
$ git tidy       # Delete merged branches
$ git undo       # Undo last commit (keep changes staged)
```

### Better Diff: Delta

**Automatic** - Delta is configured as default difftool:
```bash
$ git diff

# Shows side-by-side color diff with syntax highlighting
# Much better than plain git diff!
```

### Conflict Resolution

**zdiff3** conflict style (already configured):

**Traditional conflicts**:
```
<<<<<<< HEAD
our_code()
=======
their_code()
>>>>>>> branch
```

**With zdiff3**:
```
<<<<<<< HEAD
our_code()
||||||| common ancestor
original_code()
=======
their_code()
>>>>>>> branch
```

Shows original code, making it clearer what changed!

### Rerere: Remember Conflict Resolutions

**Already enabled** - Git remembers how you resolved conflicts:

```bash
# First time: resolve conflict manually
$ git merge feature
# Conflict in file.py
# Resolve manually
$ git add file.py
$ git commit

# Later: rebase with same conflict
$ git rebase main
# Git auto-resolves using remembered solution!
```

## Daily Workflows

### Workflow 1: Feature Development

```bash
# Create feature branch
$ git cob feature/new-endpoint

# Write code...

# Open lazygit
$ lazygit

# Stage files (space)
# Commit (c)
# Push (P)

# Create PR
$ gh pr create
# Fill in title/description
# Done!
```

### Workflow 2: Code Review

```bash
# List open PRs
$ gh pr list

# Checkout PR to test
$ gh pr checkout 123

# Test changes locally
$ just test

# Approve or request changes
$ gh pr review 123 --approve -b "LGTM!"

# Merge
$ gh pr merge 123 --squash
```

### Workflow 3: Fixing Bugs

```bash
# Create bug fix branch
$ git cob fix/auth-bug

# Fix bug...

# Lazygit: stage, commit, push

# Create PR with bug template
$ gh pr create --template bug_fix.md

# Link issue
# (In PR description: "Fixes #456")
```

### Workflow 4: Interactive Rebase

```bash
# Open lazygit
$ lazygit

# Go to Commits panel (4)
# Select commits to squash
# Press 's' to squash
# Commits combined!

# Push with force-with-lease
$ git psfl
```

### Workflow 5: Sync with Main

```bash
# Pull latest main
$ git co main
$ git pull

# Rebase feature branch
$ git co feature/new-endpoint
$ git rb main

# If conflicts, lazygit helps resolve
$ lazygit
# Resolve in editor (e)
# Stage resolved (space)
# Continue rebase
```

## Comparison: Before vs After

### Before (Manual Git)

```bash
# Creating PR:
$ git push
$ open https://github.com/user/repo
# Click "New PR"
# Fill in form
# Click "Create"
# ~10 clicks, 30 seconds

# Rebasing:
$ git rebase -i HEAD~5
# Edit TODO file manually
# Save and close
# Resolve conflicts manually
# git rebase --continue
# Repeat if more conflicts
# ~5 minutes, error-prone
```

### After (Lazygit + gh)

```bash
# Creating PR:
$ gh pr create
# Type title/description
# Done!
# ~10 seconds

# Rebasing:
$ lazygit
# Visual UI
# Press 's' to squash
# Resolve conflicts in editor
# Automatic continue
# ~1 minute, visual feedback
```

## Tips & Tricks

### 1. Lazygit Custom Commands

Add to `~/.config/lazygit/config.yml`:
```yaml
customCommands:
  - key: 'P'
    command: 'git push --force-with-lease'
    context: 'global'
    description: 'Force push (safely)'
```

### 2. gh Aliases

```bash
# Create gh aliases
$ gh alias set prc 'pr create'
$ gh alias set prv 'pr view'

# Now use
$ gh prc  # Instead of gh pr create
```

### 3. Git Hooks

Use `just git-pre-commit` for pre-commit checks (defined in justfile).

### 4. Quick Status

In any git repo:
```bash
$ git st  # Alias for status
```

Shows:
- Staged files
- Unstaged files
- Untracked files
- Branch info

### 5. Find Large Files

```bash
$ git ls-files | xargs du -h | sort -h | tail -20

# See largest files in repo
```

## Troubleshooting

### Lazygit won't open

```bash
# Check lazygit installed
$ which lazygit

# If missing
$ home-manager switch
```

### gh auth issues

```bash
# Re-authenticate
$ gh auth logout
$ gh auth login
```

### Merge conflicts

**In lazygit**:
1. Files panel shows conflicts
2. Press `e` to edit file
3. Resolve conflicts manually
4. Save and close
5. Press `space` to stage
6. All conflicts resolved → continue

**Manual**:
```bash
$ git status  # See conflicted files
$ nvim file.py  # Edit manually
$ git add file.py
$ git rebase --continue  # or git merge --continue
```

### Force push rejected

```bash
# Someone else pushed
$ git psfl  # Force-with-lease fails (good!)

# Pull and rebase
$ git pull --rebase

# Now push
$ git psfl
```

## Summary

**The tools**:
- **Lazygit** - Visual git operations
- **gh CLI** - GitHub from terminal
- **Enhanced config** - Better aliases and diff

**The workflow**:
1. Code changes
2. Lazygit → stage, commit, push
3. gh → create PR, review, merge
4. All in terminal, fast

**The benefits**:
- ✅ Visual feedback (lazygit)
- ✅ Faster operations (aliases, gh)
- ✅ Better diffs (delta)
- ✅ Safer force push (--force-with-lease)
- ✅ No context switching (stay in terminal)

---

**See also**: Other workflow documents for complete terminal-based development setup.

**Last Updated**: 2026-04-01
