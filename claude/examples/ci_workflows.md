# CI/CD Workflow Patterns

Generic GitHub Actions patterns for pull requests and releases.

## Principles

**Consistency**: Use `just` commands in CI to match local development workflow.

**Separation**: Separate lint, test, and integration jobs for parallel execution and clear failure signals.

**Matrix Testing**: Test across multiple language versions when applicable.

## Pull Request Workflow

### Basic Structure

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Setup language environment (see language-specific sections)

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Install dependencies
        run: just install

      - name: Run linting
        run: just lint

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        # Python: ["3.10", "3.11", "3.12"]
        # Rust: ["stable", "beta"]
        # Node: ["18", "20", "22"]
        version: ["3.12"]

    steps:
      - uses: actions/checkout@v4

      # Setup with matrix version

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Install dependencies
        run: just install

      - name: Run unit tests
        run: just test-unit

      - name: Run tests with coverage
        run: just test-coverage

  integration:
    runs-on: ubuntu-latest

    # Service containers for integration tests
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      # Setup language environment

      - name: Install just
        uses: extractions/setup-just@v2

      - name: Install dependencies
        run: just install

      - name: Run integration tests
        env:
          DATABASE_URL: postgresql://test_user:test_password@localhost:5432/test_db
        run: just test-integration
```

## Language-Specific Setup

### Python with uv

```yaml
- name: Install uv
  uses: astral-sh/setup-uv@v5
  with:
    enable-cache: true

- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: ${{ matrix.python-version }}

- name: Install dependencies
  run: uv sync
```

### Rust

```yaml
- name: Install Rust toolchain
  uses: dtolnay/rust-toolchain@stable
  with:
    components: rustfmt, clippy

- name: Cache cargo registry
  uses: actions/cache@v4
  with:
    path: ~/.cargo/registry
    key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}

- name: Cache cargo build
  uses: actions/cache@v4
  with:
    path: target
    key: ${{ runner.os }}-cargo-build-${{ hashFiles('**/Cargo.lock') }}
```

### Node with pnpm

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: ${{ matrix.node-version }}

- name: Install pnpm
  uses: pnpm/action-setup@v2
  with:
    version: 8

- name: Get pnpm store directory
  id: pnpm-cache
  run: echo "STORE_PATH=$(pnpm store path)" >> $GITHUB_OUTPUT

- name: Setup pnpm cache
  uses: actions/cache@v4
  with:
    path: ${{ steps.pnpm-cache.outputs.STORE_PATH }}
    key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
```

## Release Workflows

### Version-Based Auto-Release (Merge to Main)

Extract version from project file and create release if version changed:

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for changelog

      - name: Extract version
        id: version
        run: |
          # Python: VERSION=$(uv run python -c "import tomllib; print(tomllib.load(open('pyproject.toml', 'rb'))['project']['version'])")
          # Rust: VERSION=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].version')
          # Node: VERSION=$(node -p "require('./package.json').version")
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "tag=v$VERSION" >> $GITHUB_OUTPUT

      - name: Check if tag exists
        id: check_tag
        run: |
          if git rev-parse "v${{ steps.version.outputs.version }}" >/dev/null 2>&1; then
            echo "exists=true" >> $GITHUB_OUTPUT
          else
            echo "exists=false" >> $GITHUB_OUTPUT
          fi

      - name: Create release
        if: steps.check_tag.outputs.exists == 'false'
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          # Create and push tag
          git tag -a "${{ steps.version.outputs.tag }}" -m "Release ${{ steps.version.outputs.tag }}"
          git push origin "${{ steps.version.outputs.tag }}"

          # Extract changelog section for this version
          VERSION="${{ steps.version.outputs.version }}"
          CHANGELOG_SECTION=$(sed -n "/## \[$VERSION\]/,/## \[/p" CHANGELOG.md | sed '$d')

          # Create GitHub release
          gh release create "${{ steps.version.outputs.tag }}" \
            --title "Release ${{ steps.version.outputs.tag }}" \
            --notes "$CHANGELOG_SECTION"
```

### Tag-Triggered Release

Triggered when a version tag is pushed:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Setup language environment

      - name: Run tests
        run: just test

      - name: Build release artifact
        run: just build

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: |
            # Include built artifacts
            # Python: dist/*.whl
            # Rust: target/release/binary-name
            # Node: dist/*
          draft: false
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  publish:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4

      # Setup language environment

      - name: Publish package
        run: |
          # Python: uv publish --token ${{ secrets.PYPI_TOKEN }}
          # Rust: cargo publish --token ${{ secrets.CARGO_TOKEN }}
          # Node: npm publish --access public
        env:
          # Set appropriate token
          PYPI_TOKEN: ${{ secrets.PYPI_TOKEN }}
```

## Service Containers

For integration tests requiring databases or external services:

### PostgreSQL

```yaml
services:
  postgres:
    image: postgres:16
    env:
      POSTGRES_USER: test_user
      POSTGRES_PASSWORD: test_password
      POSTGRES_DB: test_db
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### Redis

```yaml
services:
  redis:
    image: redis:7
    ports:
      - 6379:6379
    options: >-
      --health-cmd "redis-cli ping"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### Neo4j

```yaml
services:
  neo4j:
    image: neo4j:5-community
    env:
      NEO4J_AUTH: neo4j/test_password
    ports:
      - 7687:7687
    options: >-
      --health-cmd "wget --spider http://localhost:7474 || exit 1"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

## Caching Strategies

### Language-Agnostic Pattern

```yaml
- name: Cache dependencies
  uses: actions/cache@v4
  with:
    path: # path/to/cache/directory
    key: ${{ runner.os }}-deps-${{ hashFiles('**/lockfile') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

### Python (uv)

```yaml
- name: Install uv
  uses: astral-sh/setup-uv@v5
  with:
    enable-cache: true  # Automatic caching
```

### Rust (Cargo)

```yaml
- name: Cache cargo
  uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/registry
      ~/.cargo/git
      target
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
```

### Node (pnpm)

```yaml
- name: Get pnpm store directory
  id: pnpm-cache
  run: echo "STORE_PATH=$(pnpm store path)" >> $GITHUB_OUTPUT

- name: Setup pnpm cache
  uses: actions/cache@v4
  with:
    path: ${{ steps.pnpm-cache.outputs.STORE_PATH }}
    key: ${{ runner.os }}-pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
```

## Environment Variables

Pass secrets and configuration through environment variables:

```yaml
- name: Run tests
  env:
    DATABASE_URL: ${{ secrets.DATABASE_URL }}
    API_KEY: ${{ secrets.API_KEY }}
    CI: true
  run: just test
```

## Best Practices

**Use just commands**: Keeps CI and local development in sync.

**Separate jobs**: Lint, test, and integration as separate jobs for clarity and parallelism.

**Matrix strategy**: Test across multiple language versions.

**Service health checks**: Always configure health checks for service containers.

**Cache dependencies**: Use appropriate caching for faster CI runs.

**Fail fast**: Use `fail-fast: false` in matrix if you want to see all version failures.

**Permissions**: Specify minimum required permissions for release workflows.
