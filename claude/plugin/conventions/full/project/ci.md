# CI/CD Requirements

Continuous integration and deployment guidelines.

## CI Platform Selection

**Ask at project start: Is this a work or personal project?**

- **Work projects**: Use CircleCI
- **Personal projects**: Use GitHub Actions

## CI Checks on Every PR

Required checks for all pull requests:

1. **Linting** - Code style checks pass
2. **Type checking** - No type errors (Python: mypy/pyright, Rust: compile checks)
3. **Compilation** - Code builds successfully (compiled languages)
4. **Tests** - All tests pass (unit + integration)
5. **Coverage** - Meet coverage threshold (80% default)
6. **Vulnerability scanning** - No known vulnerabilities
7. **Security checks** - No secrets, insecure patterns
8. **Build verification** - Artifacts build correctly

**CI should match pre-push hooks** - same checks, same requirements. CI is the enforcement mechanism.

## Continuous Deployment

### Semantic Versioning

Use semantic versioning for releases:
- **Patch** (x.y.Z): Bug fixes, documentation
- **Minor** (x.Y.0): New features, backwards compatible
- **Major** (X.0.0): Breaking changes

### Release Pipeline

Automated release on merge to main:

1. **Detect version bump** in `pyproject.toml` or `Cargo.toml`
2. **Create git tag** with version number
3. **Build artifacts** (packages, binaries, Docker images)
4. **Publish** to appropriate registry
5. **Generate release notes** from CHANGELOG.md
6. **Create GitHub release** with artifacts

### Project-Specific Deployment

**Rust CLI tools:**
- Build for multiple targets (Linux, macOS, Windows)
- Publish to cargo with `cargo publish`
- Attach binaries to GitHub release

**Python packages:**
- Build wheel and sdist with `uv build` or `hatch build`
- Publish to PyPI with `uv publish` or `twine`
- Verify package installation

**Docker images:**
- Build multi-platform images (amd64, arm64)
- Tag with version and `latest`
- Push to Docker Hub or GitHub Container Registry

**Documentation:**
- Generate with `cargo doc` or `mkdocs`
- Deploy to GitHub Pages
- Update on every release

## CI Configuration

### GitHub Actions (Personal Projects)

**Standard workflow structure:**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Python example
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh

      - name: Install dependencies
        run: uv sync

      - name: Lint
        run: uv run ruff check .

      - name: Type check
        run: uv run mypy .

      - name: Test
        run: uv run pytest --cov --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  # Rust example
  rust-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable

      - name: Format check
        run: cargo fmt -- --check

      - name: Lint
        run: cargo clippy -- -D warnings

      - name: Test
        run: cargo test

      - name: Build
        run: cargo build --release
```

### Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    if: contains(github.event.head_commit.message, 'bump version')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract version
        id: version
        run: |
          VERSION=$(grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Create tag
        run: |
          git tag v${{ steps.version.outputs.version }}
          git push origin v${{ steps.version.outputs.version }}

      - name: Build and publish
        run: |
          uv build
          uv publish --token ${{ secrets.PYPI_TOKEN }}

      - name: Create GitHub release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${{ steps.version.outputs.version }}
          generate_release_notes: true
```

### CircleCI (Work Projects)

**Standard config structure:**

```yaml
# .circleci/config.yml
version: 2.1

orbs:
  python: circleci/python@2.1
  rust: circleci/rust@1.6

jobs:
  test-python:
    docker:
      - image: cimg/python:3.11
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: |
            curl -LsSf https://astral.sh/uv/install.sh | sh
            uv sync
      - run:
          name: Lint
          command: uv run ruff check .
      - run:
          name: Type check
          command: uv run mypy .
      - run:
          name: Test
          command: uv run pytest --cov --junitxml=test-results/junit.xml
      - store_test_results:
          path: test-results

  test-rust:
    docker:
      - image: cimg/rust:1.75
    steps:
      - checkout
      - run:
          name: Format check
          command: cargo fmt -- --check
      - run:
          name: Lint
          command: cargo clippy -- -D warnings
      - run:
          name: Test
          command: cargo test

workflows:
  version: 2
  test:
    jobs:
      - test-python
      - test-rust
```

## Merge Requirements

Before merging to main:
- All CI checks pass
- Code review approved
- Coverage threshold met
- Version bumped appropriately

## On Merge to Main

Actions after merge:

1. **Run full test suite** (already passed in PR)
2. **Check for version bump** in project config
3. **Create git tag** if version changed
4. **Build and publish** artifacts to registry
5. **Generate documentation** and deploy
6. **Create GitHub release** with notes

### Tagging Strategy

**Automatic tagging on version bump:**
- Detect version change in `pyproject.toml` or `Cargo.toml`
- Create tag `vX.Y.Z` (e.g., `v1.2.3`)
- Push tag to repository
- Trigger release workflow

**Manual tagging for pre-releases:**
- `v1.2.3-rc.1` - Release candidate
- `v1.2.3-beta.1` - Beta release
- `v1.2.3-alpha.1` - Alpha release

## Security in CI

### Secrets Management

**Store secrets in CI platform:**
- PyPI tokens: `PYPI_TOKEN`
- Cargo tokens: `CARGO_TOKEN`
- Docker Hub: `DOCKER_USERNAME`, `DOCKER_PASSWORD`
- AWS credentials: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

**Never:**
- Commit secrets to repository
- Print secrets in logs
- Use secrets in PR from forks

### Dependency Scanning

Run on every PR and weekly:
- Python: `pip-audit` or `safety`
- Rust: `cargo audit`
- Docker: `trivy` or `grype`

```yaml
# Example security check
- name: Security audit
  run: |
    pip install pip-audit
    pip-audit
```

## Performance Testing

### Benchmarks in CI

**Python:**
- Run with `pytest-benchmark`
- Compare against baseline
- Fail if regression > 10%

**Rust:**
- Run with `cargo bench`
- Store results as artifacts
- Compare across commits

```yaml
- name: Benchmark
  run: cargo bench --no-fail-fast

- name: Archive benchmark results
  uses: actions/upload-artifact@v3
  with:
    name: benchmark-results
    path: target/criterion/
```

## Caching

Cache dependencies for faster builds:

```yaml
- uses: actions/cache@v3
  with:
    path: |
      ~/.cargo/bin/
      ~/.cargo/registry/index/
      ~/.cargo/registry/cache/
      ~/.cargo/git/db/
      target/
    key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
```

---

**Last Updated**: 2026-03-23
