# Pre-Commit Hooks

Generic patterns for setting up pre-commit hooks using the `pre-commit` framework.

**Recommendation**: Leverage project `just` commands for consistency between local and CI environments.

## Installation

```bash
pip install pre-commit
pre-commit install
```

## Using Project Just Commands

The most consistent approach is to delegate to your project's `justfile`:

```yaml
repos:
  - repo: local
    hooks:
      - id: lint
        name: lint
        entry: just lint
        language: system
        pass_filenames: false

      - id: format
        name: format
        entry: just format
        language: system
        pass_filenames: false

      - id: test-unit
        name: test-unit
        entry: just test-unit
        language: system
        pass_filenames: false
```

This ensures pre-commit, local development, and CI all use the same commands.

## Language-Specific Hooks

If not using `just`, configure hooks directly:

### Python with Ruff

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.2.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
```

### Rust

```yaml
repos:
  - repo: local
    hooks:
      - id: cargo-fmt
        name: cargo fmt
        entry: cargo fmt
        language: system
        types: [rust]
        pass_filenames: false

      - id: cargo-clippy
        name: cargo clippy
        entry: cargo clippy -- -D warnings
        language: system
        types: [rust]
        pass_filenames: false
```

## General File Checks

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-json
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: detect-private-key
```

## Secrets Detection

```yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## Running Hooks

```bash
# Run on staged files
pre-commit run

# Run on all files
pre-commit run --all-files

# Update hook versions
pre-commit autoupdate
```
