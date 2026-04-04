# Workflow: Text Editing & Code Development

How to edit code efficiently using Neovim + LazyVim + LSP for a modern IDE experience in the terminal.

## The Problem

Traditional text editors require you to choose:
- **Simple editors** (vi/vim/nano): Fast but no code intelligence
- **Heavy IDEs** (VSCode/IntelliJ): Feature-rich but slow startup, resource-heavy

You want:
- Fast startup and response
- Code intelligence (autocomplete, go-to-definition, errors)
- Terminal-native (works over SSH, integrates with tmux)
- Keyboard-driven (minimal mouse usage)
- Customizable

## The Solution

**Neovim + LazyVim + LSP** = Modern IDE experience in the terminal.

### The Stack

1. **Neovim** - Modern, extensible text editor (Vim reimagined)
2. **LazyVim** - Preconfigured Neovim distribution (IDE features out-of-the-box)
3. **LSP (Language Server Protocol)** - Code intelligence (autocomplete, errors, definitions)
4. **Treesitter** - Advanced syntax highlighting
5. **Telescope** - Fuzzy finder for files/text
6. **Lazygit** - Git interface

## How It Works Together

```
┌─────────────────────────────────────────────────────┐
│  You open a Python file                             │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Neovim loads the file                              │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  LazyVim detects Python file                        │
│  - Loads Python-specific plugins                    │
│  - Starts pyright (Python LSP server)               │
│  - Activates Python-specific keybindings            │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│  Treesitter provides syntax highlighting            │
│  LSP provides code intelligence                     │
│  You get IDE-like experience                        │
└─────────────────────────────────────────────────────┘
```

## What You See

### Opening Neovim

```bash
$ nvim
```

**Dashboard appears**:
```
╔═══════════════════════════════════════════════════╗
║                  LazyVim                          ║
║                                                   ║
║  Recent Files:                                    ║
║    src/main.py                                    ║
║    config/settings.toml                           ║
║    README.md                                      ║
║                                                   ║
║  Commands:                                        ║
║    [n] New File                                   ║
║    [f] Find File                                  ║
║    [g] Find Text                                  ║
║    [r] Recent Files                               ║
║    [q] Quit                                       ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
```

### Editing a File

```bash
$ nvim src/api.py
```

**What you see**:
```
┌─ src/api.py ─────────────────────────────────── main ─┐
│ 1  import requests                                     │  ← Line numbers
│ 2  from typing import Dict, Optional                  │
│ 3                                                      │
│ 4  def fetch_data(url: str) -> Dict:                  │  ← Type hints colored
│ 5  │   """Fetch data from API."""                     │  ← Indent guides
│ 6  │   response = requests.get(url)                   │
│ 7  │   return response.json()                         │
│~8                                                      │  ← Error indicator
│ 9  def process(data: Dict) -> None:                   │
│10  │   for key in data.keys():                        │
│11  │   │   print(key)                                 │
│                                                        │
│ [i] pyright: Missing return type annotation (line 8) │  ← LSP diagnostic
├────────────────────────────────────────────────────────┤
│ NORMAL  main  api.py  Python  100%  1:1          │  ← Status line
└────────────────────────────────────────────────────────┘
```

**Features visible**:
- ✅ Syntax highlighting (colors)
- ✅ Line numbers
- ✅ Git changes in gutter (added/modified/deleted)
- ✅ LSP errors/warnings
- ✅ Indent guides
- ✅ Status line with file info

### Autocomplete in Action

**You type**:
```python
import req|  ← cursor here
```

**Autocomplete popup**:
```
┌──────────────────────┐
│ ● requests          │ ← Suggested (from LSP)
│   requote           │
│   require           │
│   urllib.request    │
└──────────────────────┘
  Module · LSP
```

**You press Tab or Enter** → completes to `import requests`

**You continue typing**:
```python
response = requests.g|  ← cursor here
```

**Autocomplete shows**:
```
┌───────────────────────────────────┐
│ ● get(url, **kwargs) → Response  │ ← Function signature
│   post(url, **kwargs) → Response │
│   put(url, **kwargs) → Response  │
│   delete(url, **kwargs)          │
└───────────────────────────────────┘
  Method · LSP
```

## Modes in Vim/Neovim

Neovim is **modal** - different modes for different tasks:

### Normal Mode (Default)
**Purpose**: Navigate and manipulate text

**Common commands**:
```
Movement:
  h j k l    - Left, down, up, right
  w / b      - Forward/backward by word
  0 / $      - Start/end of line
  gg / G     - Top/bottom of file
  Ctrl+d/u   - Page down/up

Editing:
  x          - Delete character
  dd         - Delete line
  yy         - Copy line
  p          - Paste
  u          - Undo
  Ctrl+r     - Redo

Entering other modes:
  i          - Insert mode (before cursor)
  a          - Insert mode (after cursor)
  v          - Visual mode (select text)
  :          - Command mode
```

### Insert Mode
**Purpose**: Type text (like normal editors)

**Enter**: Press `i` in Normal mode  
**Exit**: Press `Esc` to return to Normal mode

**You type normally in this mode**.

### Visual Mode
**Purpose**: Select text

**Enter**: Press `v` in Normal mode  
**Actions**: `y` (copy), `d` (delete), `c` (change)

### Command Mode
**Purpose**: Run commands

**Enter**: Press `:` in Normal mode  
**Examples**:
```vim
:w          - Save file
:q          - Quit
:wq         - Save and quit
:q!         - Quit without saving
:help       - Open help
```

## Essential Keybindings

### Leader Key = Space

LazyVim uses `Space` as the "leader" key for most commands.

### File Operations

```
Space f f   - Find file (fuzzy search)
Space f r   - Recent files
Space f g   - Find text in files (grep)
Space f b   - Find open buffers
Space f n   - New file
Space /     - Search in current file

Space e     - Toggle file explorer
Space q q   - Quit
```

### Code Navigation

```
g d         - Go to definition
g r         - Go to references
g I         - Go to implementation
g D         - Go to declaration

K           - Show hover documentation
[d          - Previous diagnostic (error/warning)
]d          - Next diagnostic

Ctrl+o      - Go back (jump history)
Ctrl+i      - Go forward (jump history)
```

### Code Actions

```
Space c a   - Code actions (quick fixes, refactorings)
Space c r   - Rename symbol
Space c f   - Format file
Space c d   - Show diagnostics

Space c l   - LSP info
```

### Search & Replace

```
/pattern    - Search forward
?pattern    - Search backward
n / N       - Next/previous match

:%s/old/new/g     - Replace all in file
:s/old/new/g      - Replace in current line
```

### Window Management

```
Space w s   - Split horizontally
Space w v   - Split vertically
Space w c   - Close window
Space w o   - Close other windows

Ctrl+h/j/k/l  - Navigate between windows
```

### Git Operations

```
Space g g   - Open Lazygit
Space g s   - Git status
Space g b   - Git blame
Space g d   - Git diff
Space g h   - Git hunk (preview changes)

] h         - Next git hunk
[ h         - Previous git hunk
```

### Terminal

```
Space t t   - Toggle terminal
Space t f   - Open floating terminal

Ctrl+\      - Toggle terminal (from terminal)
```

### Tabs & Buffers

```
Space b b   - List buffers
Space b d   - Delete buffer
Space b n   - Next buffer
Space b p   - Previous buffer

Tab         - Next tab
Shift+Tab   - Previous tab
Space Tab   - New tab
```

## Daily Workflows

### Workflow 1: Editing a Single File

```bash
# Open file
$ nvim src/main.py

# Enter insert mode
i

# Type code
# (autocomplete appears as you type)

# Exit insert mode
Esc

# Save
:w

# Or save and quit
:wq
```

### Workflow 2: Working on a Feature

```bash
# Open Neovim
$ nvim

# Find file
Space f f
# Type "main", hit Enter

# Start editing
i
# Type code...
Esc

# Jump to function definition
# Cursor on function name
g d  ← jumps to definition

# Go back
Ctrl+o

# Find all uses of this function
g r  ← shows all references

# Rename function
Space c r
# Type new name, Enter
# All references updated!

# See what changed
Space g g  ← opens Lazygit
# Review changes
# Stage, commit, push
```

### Workflow 3: Fixing Errors

```bash
# Open file with errors
$ nvim src/api.py

# See error highlights (red squiggles)
# Jump to first error
]d

# See error details
K  ← hover shows full error message

# See quick fixes
Space c a
# Select fix from list
# Error fixed automatically!

# Jump to next error
]d

# Repeat
```

### Workflow 4: Exploring a Codebase

```bash
# Open project
$ cd ~/repos/project
$ nvim

# Find file by name
Space f f
# Type partial name
# Select file

# Search for text across project
Space f g
# Type search term (e.g., "TODO")
# See all matches with context
# Select to jump

# Open file explorer
Space e
# Navigate with j/k
# Press Enter to open file

# Split view for comparison
Space w v
# Opens split
# Navigate between splits: Ctrl+h, Ctrl+l
```

### Workflow 5: Refactoring

```bash
# Open file
$ nvim src/models.py

# Find function to rename
/old_function_name
# Press Enter, cursor on first match

# Rename everywhere
Space c r
# Type new name: new_function_name
# Press Enter
# All references renamed across project!

# Extract to function (visual selection)
v  ← enter visual mode
# Select lines with j/k
Space c a  ← code actions
# Select "Extract to function"
# Name it, done!
```

## LSP Features in Detail

### What is LSP?

**Language Server Protocol** - A standard for editors to get code intelligence.

**How it works**:
```
┌──────────┐              ┌────────────────┐
│  Neovim  │ ←── LSP ───→ │  pyright       │
│          │              │  (Python LSP)  │
└──────────┘              └────────────────┘
     ↓                            ↓
  Edit code            Analyzes code, provides:
                       - Autocomplete
                       - Errors
                       - Definitions
                       - References
                       - Refactorings
```

### Autocomplete

**What you see**:
```python
def process_data(items: list[str]) -> dict:
    result = {}
    for it|  ← cursor here
```

**Popup shows**:
```
┌────────────────────────┐
│ ● item    Variable    │ ← From context
│   items   Parameter   │ ← Function parameter
│   iter    Builtin     │ ← Python builtin
└────────────────────────┘
```

**Sources**:
- Function parameters
- Local variables
- Imports
- Builtins
- Snippets

### Go to Definition (gd)

**Before**:
```python
# File: src/main.py
result = process_data(items)  ← cursor here, press gd
```

**After**:
```python
# File: src/utils.py (automatically opened)
def process_data(items: list) -> dict:  ← cursor jumps here
    """Process items and return dict."""
    ...
```

Works across files, even in dependencies!

### Find References (gr)

**Scenario**: Where is this function used?

**Press `gr` on function name**:
```
┌─ References to process_data ─────────────────┐
│ src/main.py:42                               │
│ │   result = process_data(items)             │
│                                              │
│ src/api.py:18                                │
│ │   data = process_data(request.items)       │
│                                              │
│ tests/test_utils.py:10                       │
│ │   assert process_data([]) == {}            │
└──────────────────────────────────────────────┘
```

Select any line to jump to it.

### Hover Documentation (K)

**Cursor on function**:
```python
response = requests.get(url)  ← cursor here, press K
```

**Popup shows**:
```
┌─ requests.get ────────────────────────────────┐
│ get(url, params=None, **kwargs) -> Response  │
│                                               │
│ Sends a GET request.                          │
│                                               │
│ Parameters:                                   │
│   url – URL for the new Request object       │
│   params – Dictionary to send in query       │
│   **kwargs – Optional arguments              │
│                                               │
│ Returns:                                      │
│   Response object                             │
└───────────────────────────────────────────────┘
```

### Diagnostics (Errors/Warnings)

**Real-time error checking**:
```python
def calculate(x):  ← Warning: Missing type hints
    result = x + y  ← Error: 'y' is not defined
    return result

calculate("5", 10)  ← Warning: Type mismatch
```

**Error indicators**:
- Red squiggles under errors
- Yellow for warnings
- Icons in gutter
- Status line shows count

**Navigate errors**:
```
]d  - Next diagnostic
[d  - Previous diagnostic
Space c d  - Show all diagnostics in project
```

### Code Actions (Space c a)

**Smart fixes for common issues**:

**Example 1 - Missing import**:
```python
response = requests.get(url)  ← Error: 'requests' not imported
```

**Press `Space c a`**:
```
┌─ Code Actions ────────────┐
│ ● Add import: requests    │ ← Select this
│   Disable rule            │
└───────────────────────────┘
```

**Result**:
```python
import requests  ← Automatically added

response = requests.get(url)  ← Error fixed!
```

**Example 2 - Type hints**:
```python
def process(data):  ← Warning: Missing type hints
```

**Press `Space c a`**:
```
┌─ Code Actions ──────────────────┐
│ ● Add type hint                 │
│   Add return type annotation    │
└─────────────────────────────────┘
```

### Rename (Space c r)

**Rename symbol across entire project**:

**Before**:
```python
# src/utils.py
def old_name(x):  ← cursor here, Space c r
    return x * 2

# src/main.py
result = old_name(5)

# tests/test_utils.py
assert old_name(3) == 6
```

**Enter new name: `calculate_double`**

**After**:
```python
# src/utils.py
def calculate_double(x):  ← renamed
    return x * 2

# src/main.py
result = calculate_double(5)  ← updated

# tests/test_utils.py
assert calculate_double(3) == 6  ← updated
```

All references updated automatically!

## Telescope: Fuzzy Finder

### Find File (Space f f)

```
┌─ Find Files ──────────────────────────────────┐
│ > api                                         │
│                                               │
│   src/api/routes.py                           │
│   src/api/models.py                           │
│   tests/test_api.py                           │
│   config/api_settings.py                      │
└───────────────────────────────────────────────┘
```

**Type partial name** → matches anywhere in path  
**Select** → opens file

### Find Text (Space f g)

**Grep through all files**:
```
┌─ Find Text ───────────────────────────────────┐
│ > TODO                                        │
│                                               │
│ src/main.py:42                                │
│ │ # TODO: Add error handling                  │
│                                               │
│ src/api.py:18                                 │
│ │ # TODO: Implement caching                   │
│                                               │
│ README.md:100                                 │
│ │ ## TODO: Add deployment docs                │
└───────────────────────────────────────────────┘
```

### Recent Files (Space f r)

**Quick access to recently edited files**:
```
┌─ Recent Files ────────────────────────────────┐
│   src/main.py                    (2 mins ago) │
│   src/api.py                     (5 mins ago) │
│   tests/test_main.py            (10 mins ago) │
│   README.md                     (1 hour ago)  │
└───────────────────────────────────────────────┘
```

## File Explorer (Space e)

**Tree view of project**:
```
┌─ Explorer ───────────────────────────┐
│ 📁 project/                          │
│ ├─📁 src/                            │
│ │ ├─📄 main.py                       │
│ │ ├─📄 api.py                        │
│ │ └─📁 models/                       │
│ │   ├─📄 user.py                     │
│ │   └─📄 post.py                     │
│ ├─📁 tests/                          │
│ │ └─📄 test_main.py                  │
│ ├─📄 README.md                       │
│ └─📄 pyproject.toml                  │
└──────────────────────────────────────┘
```

**Navigation**:
```
j/k       - Move down/up
Enter     - Open file/expand folder
o         - Open file in split
a         - Add file
d         - Delete file
r         - Rename file
y         - Copy file
p         - Paste file
Space e   - Close explorer
```

## Git Integration: Lazygit

### Opening Lazygit (Space g g)

**Full-screen git interface in Neovim**:
```
┌─ Status ─────────────────────────────────────────────┐
│ Files:                                                │
│ ● src/main.py                      Modified          │
│ ● src/api.py                       Added             │
│ ● README.md                        Modified          │
│                                                       │
│ [Space] Stage | [c] Commit | [p] Push | [q] Quit    │
├─ Diff ──────────────────────────────────────────────┤
│ @@ -10,3 +10,5 @@                                    │
│   def process_data(items):                           │
│ +     if not items:                                  │
│ +         return {}                                  │
│       result = {}                                    │
└──────────────────────────────────────────────────────┘
```

**Workflow**:
1. Select file (j/k)
2. Press Space to stage
3. Press `c` to commit
4. Write message
5. Press `p` to push

All without leaving Neovim!

### Git Signs in Editor

**See changes inline**:
```
│ 1  import requests                               │
│~2  from typing import Dict                       │  ← Modified (yellow ~)
│+3  import logging                                │  ← Added (green +)
│ 4                                                │
│ 5  def fetch_data(url: str) -> Dict:            │
│-6      response = requests.get(url)             │  ← Deleted (red -)
│+7      logger.info(f"Fetching {url}")           │  ← Added (green +)
│+8      response = requests.get(url, timeout=10) │  ← Added (green +)
```

## Learning Path

### Day 1: Basic Vim Motions
**Goal**: Navigate without arrow keys

Practice:
```
h j k l    - Move around
i          - Insert mode
Esc        - Normal mode
:w         - Save
:q         - Quit
```

Open any file, try navigating with h/j/k/l only.

### Day 2-3: Essential Movements
**Goal**: Faster navigation

Learn:
```
w / b      - Forward/backward by word
0 / $      - Start/end of line
gg / G     - Top/bottom of file
```

Practice: Open a file, try jumping around without holding keys.

### Week 1: Editing Commands
**Goal**: Edit text efficiently

Learn:
```
dd         - Delete line
yy         - Copy line
p          - Paste
u          - Undo
x          - Delete character
```

Practice: Copy, delete, move lines around.

### Week 2: File Navigation
**Goal**: Open/switch files quickly

Learn:
```
Space f f  - Find file
Space f g  - Find text
Space e    - File explorer
gd         - Go to definition
```

Practice: Navigate a real project, find files, jump to definitions.

### Week 3: LSP Features
**Goal**: Use code intelligence

Learn:
```
K          - Hover docs
Space c a  - Code actions
Space c r  - Rename
]d / [d    - Next/prev error
```

Practice: Fix errors, rename variables, read docs.

### Month 2: Advanced Features
**Goal**: Master the workflow

Learn:
```
Space g g  - Lazygit
Space w v  - Splits
Visual mode selections
Macros (record/replay)
```

Practice: Full workflow - edit, commit, push without leaving Neovim.

## Tips & Tricks

### Muscle Memory

**First 2 weeks feel slow** - This is normal!

You're building muscle memory. After ~2 weeks, you'll be faster than before.

**Practice daily** - Even 10 minutes of deliberate practice helps.

### Start Simple

Don't try to learn everything at once:
1. Week 1: Just navigation (h/j/k/l)
2. Week 2: Add editing (i/Esc/dd/yy/p)
3. Week 3: Add file navigation (Space f f)
4. Week 4: Add LSP features (gd/K)

### Keep a Cheatsheet

Write down commands you use often. Review daily.

### Use :help

Neovim has excellent built-in help:
```vim
:help gd
:help telescope
:help lsp
```

### LazyVim Keybindings Explorer

**Press `Space ?`** → shows all keybindings

Filter by typing, e.g., "file" shows all file operations.

## Comparison: VSCode vs Neovim+LazyVim

| Feature | VSCode | Neovim+LazyVim |
|---------|--------|----------------|
| Startup time | 2-5 seconds | <1 second |
| Memory usage | 300-500 MB | 50-100 MB |
| Works over SSH | No | Yes |
| Tmux integration | Poor | Excellent |
| Keyboard-driven | Partial | Complete |
| Mouse required | Often | Never |
| Customization | Limited | Unlimited |
| Extensions | GUI marketplace | Config files |
| Learning curve | Low | High |

**When to use VSCode**:
- Team uses it (standardization)
- Need specific GUI features
- Don't want to learn Vim motions

**When to use Neovim+LazyVim**:
- Terminal-first workflow
- Work over SSH frequently
- Want keyboard-only efficiency
- Willing to invest learning time

## Troubleshooting

### LSP not working

Check LSP status:
```vim
:LspInfo
```

Should show active language servers. If not:
```bash
# Check if LSP server is installed
which pyright
which rust-analyzer

# If missing, re-run home-manager
home-manager switch
```

### Autocomplete not appearing

Press `Ctrl+Space` to manually trigger.

If still not working:
```vim
:checkhealth
```

Look for errors in completion section.

### Keybindings not working

Check if in correct mode (Normal vs Insert).

Press `Esc` to ensure you're in Normal mode.

### Plugins not loading

Update plugins:
```vim
:Lazy sync
```

Or reinstall:
```bash
rm -rf ~/.local/share/nvim
nvim  # Will reinstall everything
```

### Performance issues

Large files can be slow. Disable some features:
```vim
:set syntax=off       " Disable syntax highlighting
:TSBufDisable highlight  " Disable Treesitter
```

## Summary

**The workflow**:
1. Open Neovim (`nvim`)
2. Find file (`Space f f`)
3. Edit with code intelligence (autocomplete, errors, definitions)
4. Navigate efficiently (motions, go-to-definition)
5. Commit changes (`Space g g`)

**The benefits**:
- Fast and lightweight
- Full IDE features in terminal
- Keyboard-driven efficiency
- Works anywhere (local, SSH, tmux)
- Infinitely customizable

**The investment**:
- 2 weeks to get comfortable
- 1 month to be proficient
- 3 months to be faster than before
- Worth it for terminal-based workflow

---

**Next**: See [WORKFLOW_GIT.md](WORKFLOW_GIT.md) for Git workflow with lazygit and gh.

**Last Updated**: 2026-04-01
