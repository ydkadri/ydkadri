# Project Structure

Project layout and organization preferences.

## Directory Layout

### Python Projects

```
project-name/
├── src/
│   └── project_name/
│       ├── __init__.py
│       └── module/
├── tests/
│   ├── unit/
│   │   └── module/
│   └── integration/
│       └── module/
├── docker/
│   ├── docker-compose.yml
│   └── Dockerfile
├── docs/
├── pyproject.toml
├── justfile
├── README.md
├── CHANGELOG.md
└── .env.example
```

Prefer `src/<app_name>/` layout over flat structure.

### Rust Projects

```
project-name/
├── src/
│   ├── main.rs or lib.rs
│   └── module/
├── tests/
├── docker/
├── Cargo.toml
├── justfile
├── README.md
├── CHANGELOG.md
└── .env.example
```

## Package Managers

### Python

- **Prefer `uv`** for package management (fast, modern)
- Use `pyproject.toml` for configuration
- Keep dependencies up to date

### Rust

- Use `cargo` (standard)
- Keep dependencies updated

## Task Runner: justfile

All projects should have a `justfile` with standard commands.

### Required Commands

**Development:**
- `install` - Install dependencies
- `build` - Build project
- `clean` - Clean build artifacts

**Testing:**
- `test` - Run unit tests
- `test-integration` - Run integration tests
- `test-coverage` - Run tests with coverage report

**Quality:**
- `lint` - Run linting checks
- `format` - Auto-format code
- `typecheck` - Run type checking (Python) or compile checks (Rust)
- `check` - Run all quality checks (lint + typecheck + test)

**Git Hooks:**
- `git-pre-commit` - Runs format, lint, typecheck, test
- `git-pre-push` - Runs all checks including integration tests and coverage

**Docker (if applicable):**
- `docker-build` - Build Docker images
- `docker-up` - Start services
- `docker-down` - Stop services
- `docker-reset` - Complete rebuild (stop, remove volumes, rebuild, start)
- `docker-logs` - View logs
- `docker-shell` - Open shell in service

### Command Organization

Use recipe groups for clarity. **Format**: comment/description, then group attribute, then command:

```makefile
# Run Python tests
[group('python')]
py-test:
    uv run pytest

# Run Rust tests
[group('rust')]
rs-test:
    cargo test

# Start Docker services
[group('docker')]
docker-up:
    docker compose up -d
```

**Required format**:
- Line 1: Comment describing what the command does
- Line 2: Group attribute
- Line 3: Command definition

### Example Patterns

**Python Project:**
```makefile
default:
    @just --list

# Install project dependencies
[group('development')]
install:
    uv sync

# Run unit tests
[group('testing')]
test:
    uv run pytest

# Run all lints
[group('quality')]
lint:
    uv run ruff check .

# Auto-format code
[group('quality')]
format:
    uv run ruff format .

# Run all quality checks
[group('quality')]
check: lint test
    @echo "All checks passed!"
```

**Rust Project:**
```makefile
default:
    @just --list

# Build project
[group('development')]
build:
    cargo build

# Run unit tests
[group('testing')]
test:
    cargo test

# Run all lints
[group('quality')]
lint:
    cargo clippy -- -D warnings

# Auto-format code
[group('quality')]
format:
    cargo fmt

# Run all quality checks
[group('quality')]
check: lint test
    @echo "All checks passed!"
```

## Configuration Files

### Python

- `pyproject.toml` for project configuration
- `.env` files for environment variables (never committed)
- `.env.example` for template

### Rust

- `Cargo.toml` for project configuration
- `.env` files for environment variables (never committed)
- `.env.example` for template

## Documentation Structure

### Required Files

**Root Level:**
- `README.md` - Project overview, setup, usage
- `CHANGELOG.md` - Version history and changes
- `.env.example` - Environment variable template

**docs/ Directory:**
```
docs/
├── user-journey/       # User journey documentation (CRITICAL)
│   ├── feature-name.md
│   └── workflow-name.md
├── interface/          # Interface documentation (CRITICAL)
│   ├── api.md
│   └── cli.md
├── architecture/       # System design
│   ├── overview.md
│   └── decisions.md
└── development/        # Developer guides
    ├── setup.md
    └── contributing.md
```

User-journey and interface documentation are the most important - always start here before implementing.

### README Structure

1. **Project Name and Description**
2. **Installation** - How to install dependencies
3. **Usage** - Quick start guide
4. **Development** - How to set up dev environment
5. **Testing** - How to run tests
6. **Documentation** - Links to detailed docs

### CHANGELOG Format

Follow semantic versioning and keep a changelog:

```markdown
# Changelog

## [Unreleased]

### Added
- New feature

### Changed
- Modified behavior

### Fixed
- Bug fix

## [1.0.0] - 2024-01-01

### Added
- Initial release
```

## Environment Configuration

### .env Files

**Never commit `.env` files.** Always provide `.env.example`:

```bash
# .env.example
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
REDIS_URL=redis://localhost:6379/0
LOG_LEVEL=INFO
API_KEY=your_api_key_here
```

### Configuration Hierarchy

1. **Defaults** - In code
2. **Global config** - `/etc/app/config.toml`
3. **Local config** - `~/.config/app/config.toml`
4. **Environment variables** - `.env` file
5. **CLI arguments** - Command line flags

Higher levels override lower levels.

## Docker Structure

All Docker-related files live in `docker/` directory at project root:

```
docker/
├── docker-compose.yml       # Service orchestration
├── docker-compose.dev.yml   # Development overrides
├── Dockerfile               # Application image
└── postgres/
    └── init.sql             # Database initialization
```

### Key Principles

- **Multi-stage builds** - Separate builder and runtime stages for minimal images
- **Environment variables** - Use `.env` files, never commit them
- **Volumes** - Persist data and enable live reload during development
- **Minimal images** - Use slim base images appropriate for the language

**See [docker.md](docker.md) for detailed Docker patterns, multi-stage build examples, and justfile integration.**

## CI/CD

All projects use continuous integration with required checks on every PR:

- ✅ Linting and formatting
- ✅ Type checking
- ✅ Tests (unit + integration)
- ✅ Coverage threshold (80% default)
- ✅ Security scanning

### Platform Selection

- **Work projects**: Use CircleCI
- **Personal projects**: Use GitHub Actions

**CI should match pre-push hooks** - same checks, same requirements.

**See [ci.md](ci.md) for detailed CI/CD workflows, release pipelines, and platform-specific configurations.**

## Testing Structure

**Organize tests by both type AND module:**

### Python

```
tests/
├── conftest.py                      # Shared fixtures
├── unit/
│   ├── parser/
│   │   ├── test_parse.py
│   │   └── test_tokenize.py
│   └── analyzer/
│       ├── test_analyze.py
│       └── test_extract.py
└── integration/
    ├── parser/
    │   └── test_end_to_end.py
    └── analyzer/
        └── test_workflows.py
```

### Rust

```
tests/
├── common/
│   └── mod.rs                       # Shared test utilities
├── unit/
│   ├── parser/
│   │   ├── mod.rs
│   │   └── test_parse.rs
│   └── analyzer/
│       ├── mod.rs
│       └── test_analyze.rs
└── integration/
    ├── parser/
    │   └── test_workflows.rs
    └── analyzer/
        └── test_workflows.rs

benches/
└── performance_benchmarks.rs
```

This structure:
- Groups tests by type (unit vs integration)
- Then groups by module being tested
- Makes it easy to find all tests for a specific module
- Scales well as projects grow

---

**Last Updated**: 2026-03-23
