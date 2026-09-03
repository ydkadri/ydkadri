# finder

`finder` is a faster, Rust-based replacement for `find`/`grep` when locating files or searching file contents. Source: [github.com/ydkadri/finders](https://github.com/ydkadri/finders).

## When to use it

Before falling back to `find`/`grep`, check whether `finder` is available (`command -v finder`) and prefer it if so — it's faster and has a friendlier interface. Since it's a personal tool rather than something guaranteed to be installed everywhere, don't assume it's present on every machine or in every environment (containers, CI, fresh checkouts).

## Installing

```bash
cargo install --git https://github.com/ydkadri/finders
```

## Usage

```bash
finder [OPTIONS] [PATH]
```

`PATH` is optional and defaults to the current directory.

Useful options:
- `-f, --file-pattern <PATTERN>` — filter results by file name pattern
- `-s, --search-pattern <PATTERN>` — search for a literal pattern inside result files
- `-r, --regex-pattern <PATTERN>` — search using a regex pattern inside result files
- `-i, --case-insensitive` — case-insensitive search
- `-l, --files-with-matches` — only print file paths with matches (like `grep -l`)
- `-c, --count` — print match count per file (like `grep -c`)
- `--json` — output results as JSON
- `-v, --verbose` — verbose output, details unreadable files

Examples:
```bash
finder -f "*.tf"                          # find Terraform files under CWD
finder -s "reef-config"                   # find files containing "reef-config"
finder -f "*.py" -r "def\s+handle_" -i    # regex search inside Python files, case-insensitive
finder terraform/workspaces -f "eks.tf" -l  # just list matching file paths
```

---

**Last Updated**: 2026-09-03
