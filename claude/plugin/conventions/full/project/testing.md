# Testing Strategy

Testing approach and requirements.

## When to Write Tests

Tests ship with the feature. A feature arrives for review complete, with tests covering happy paths, edge cases and errors. There is no required order (tests first or alongside), but design the interface before the internals.

## Test Types

### Unit Tests

**Scope:** Test individual functions, classes, or modules in isolation.

**What to test:**
- Pure functions with various inputs
- Class methods with different states
- Error handling and edge cases
- Business logic and algorithms

**Isolation:**
- Mock external dependencies (databases, APIs, file system)
- Fast execution (milliseconds)
- No network calls
- No file I/O unless testing file operations

**Example:**
```python
class TestParser:
    """Unit tests for parser module."""

    def test_parse_valid_input(self):
        """Parse valid input returns expected output."""
        result = parser.parse("valid input")
        assert result.is_valid
        assert result.value == "expected"

    def test_parse_invalid_input(self):
        """Parse invalid input raises ParseError."""
        with pytest.raises(parser.ParseError):
            parser.parse("invalid")
```

### Integration Tests

**Scope:** Test multiple components working together.

**What to test:**
- Database interactions (real database or container)
- API endpoints (full request/response cycle)
- File system operations
- External service integrations

**Characteristics:**
- Slower than unit tests (seconds)
- May use real dependencies
- Test realistic workflows

**Example:**
```python
class TestDatabaseIntegration:
    """Integration tests with database."""

    @pytest.fixture
    def db_connection(self):
        """Provide test database connection."""
        conn = create_connection("test_db")
        yield conn
        conn.close()

    def test_save_and_retrieve(self, db_connection):
        """Save data and retrieve it successfully."""
        user = User(email="test@example.com")
        user_id = save_user(db_connection, user)

        retrieved = get_user(db_connection, user_id)
        assert retrieved.email == "test@example.com"
```

### End-to-End Tests

**Scope:** Test complete user workflows from start to finish.

**When needed:**
- Critical user paths
- CLI tools (test full command execution)
- Web applications (test UI interactions)

**Characteristics:**
- Slowest tests (seconds to minutes)
- Test from user's perspective
- May use real systems

**Prefer integration tests over E2E when possible** - faster and easier to maintain.

## Test Organization

### File Structure

- Mirror source structure
- Separate unit and integration tests
- **Python**: `tests/unit/` and `tests/integration/`, mirroring `src/`
- **Rust**: unit tests inline in `#[cfg(test)] mod tests`; integration tests in one binary at `tests/integration/main.rs`. Cargo only discovers top-level files in `tests/`, so nested unit test directories never run.

### Test Classes vs Functions

**Prefer test classes** for better organization:

```python
# Python
class TestFeature:
    """Tests for feature X."""

    def test_basic_case(self):
        ...

    def test_edge_case(self):
        ...
```

```rust
// Rust: unit tests are inline; name tests for what they check, with no `test_` prefix
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_case_returns_expected_value() {
        ...
    }
}
```

### Fixtures and Test Data

Data goes inline in the test. Fixtures are for resources that need setup or teardown (database connections, temp directories, mocked clients). Use the narrowest scope that works: function scope by default, class, module or session scope only for something expensive to build and safe to share.

**Python - Use pytest fixtures for resources:**

```python
# tests/conftest.py - Shared fixtures
import pytest

@pytest.fixture
def temp_file(tmp_path):
    """Provide temporary file for testing."""
    file_path = tmp_path / "test.txt"
    file_path.write_text("test content")
    return file_path

@pytest.fixture
def mock_api_client(mocker):
    """Provide mocked API client."""
    client = mocker.Mock()
    client.get.return_value = {"status": "ok"}
    return client
```

**Rust - helpers are for resources only:**

```rust
// tests/integration/support.rs
#![expect(clippy::unwrap_used, reason = "test support code")]

use tempfile::TempDir;

pub fn create_test_dir() -> TempDir {
    TempDir::new().unwrap()
}
```

Sample values (a config, a user) are built inline in the test. Helper files under `tests/` are not covered by the clippy test exemption, so they carry their own reasoned `#![expect(...)]`.

**Inline test data for simple cases:**

```python
def test_parse():
    """Parse simple input."""
    input_data = "test data"
    expected = ParsedData(value="test")
    assert parse(input_data) == expected
```

## Mocking and Test Doubles

### When to Mock

**Mock external dependencies in unit tests:**
- HTTP APIs and external services
- Databases
- File system operations
- Time/date functions
- Random number generators

**Use real dependencies in integration tests:**
- Database interactions (use test database)
- File operations (use temp directories)
- Service integrations (use test instances)

### Python Mocking with pytest-mock

```python
def test_api_call(mocker):
    """Test function that calls external API."""
    # Mock the HTTP client
    mock_client = mocker.patch("myproject.api.httpx.Client")
    mock_client.return_value.get.return_value.json.return_value = {
        "status": "success"
    }

    result = fetch_data("https://api.example.com/data")
    assert result["status"] == "success"
    mock_client.return_value.get.assert_called_once_with(
        "https://api.example.com/data"
    )
```

### Rust Fakes

**Depend on a trait and write a hand-made fake. No mocking crate:**

```rust
// Production code
trait FetchesData {
    fn fetch(&self, url: &str) -> Result<String, Error>;
}

struct ApiClient;

impl FetchesData for ApiClient {
    fn fetch(&self, url: &str) -> Result<String, Error> {
        // Real HTTP call
    }
}

// Test code
#[cfg(test)]
mod tests {
    struct FakeClient;

    impl FetchesData for FakeClient {
        fn fetch(&self, _url: &str) -> Result<String, Error> {
            Ok("canned response".to_owned())
        }
    }

    #[test]
    fn process_data_succeeds_with_canned_response() {
        let client = FakeClient;
        assert!(process_data(&client).is_ok(), "processing should succeed");
    }
}
```

## Database Testing

### Use Real Databases

**Prefer real database instances over mocks or in-memory.**

**Why:**
- Tests actual SQL queries and behavior
- Catches database-specific issues
- Tests migrations and schema changes

### Approaches

**Option 1: Docker container (preferred)**
```python
# tests/conftest.py
import pytest
import psycopg2
import subprocess

@pytest.fixture(scope="session")
def postgres_container():
    """Start PostgreSQL container for tests."""
    subprocess.run([
        "docker", "run", "-d",
        "--name", "test-postgres",
        "-e", "POSTGRES_PASSWORD=test",
        "-p", "5432:5432",
        "postgres:16-alpine"
    ])
    yield
    subprocess.run(["docker", "rm", "-f", "test-postgres"])

@pytest.fixture
def db_connection(postgres_container):
    """Provide clean database for each test."""
    conn = psycopg2.connect(
        host="localhost",
        user="postgres",
        password="test",
        dbname="postgres"
    )
    # Run migrations
    run_migrations(conn)
    yield conn
    # Rollback after test
    conn.rollback()
    conn.close()
```

**Option 2: Test database instance**
```python
@pytest.fixture
def db_connection():
    """Use dedicated test database."""
    conn = create_connection("test_db")
    with conn:
        with conn.cursor() as cursor:
            cursor.execute("BEGIN")
            yield conn
            cursor.execute("ROLLBACK")
```

**Option 3: SQLite for simple cases**
```python
@pytest.fixture
def db_connection():
    """Use in-memory SQLite for simple tests."""
    conn = sqlite3.connect(":memory:")
    create_tables(conn)
    yield conn
    conn.close()
```

## Coverage Requirements

- **Gate**: 80% coverage, enforced (`--cov-fail-under=80`). A project may set a different threshold in its CLAUDE.md, and that threshold is enforced too.
- Required in pre-push hooks
- CI enforces the same gate

### What to Exclude

**Exclude from coverage:**
- Test files themselves
- Generated code
- Type stubs
- `if __name__ == "__main__":` blocks
- Unreachable defensive code (explicit `pragma: no cover`)

**Python example:**
```python
# pyproject.toml
[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if TYPE_CHECKING:",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
]
```

### Focus on Meaningful Coverage

The gate is a floor, not the goal:
- Cover happy paths
- Cover error cases
- Cover edge cases
- Don't write tests just to hit the percentage

## Property-Based Testing

### When to Use

**Use for testing invariants and properties:**
- Parsers (parse then serialize should be identity)
- Encoders/decoders
- Data transformations
- Algorithms with mathematical properties

### Python - Hypothesis

```python
from hypothesis import given
from hypothesis import strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    """Addition is commutative."""
    assert a + b == b + a

@given(st.text())
def test_encode_decode_identity(text):
    """Encoding then decoding returns original."""
    encoded = encode(text)
    decoded = decode(encoded)
    assert decoded == text
```

### Rust - proptest

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_parse_serialize_identity(s in "\\PC*") {
        let parsed = parse(&s)?;
        let serialized = serialize(&parsed);
        prop_assert_eq!(&s, &serialized);
    }
}
```

## Performance/Benchmark Tests

### When to Add

**Add benchmarks for:**
- Performance-critical code paths
- Algorithm implementations
- Data processing operations
- Hot loops

### Python - pytest-benchmark

```python
def test_parse_performance(benchmark):
    """Benchmark parsing operation."""
    input_data = "test data" * 1000
    result = benchmark(parse, input_data)
    assert result is not None
```

### Rust - criterion (performance-critical paths only)

See rust.md for benchmark patterns. Benchmarks are not a template default and do not run on every PR.

```rust
use std::hint::black_box;

use criterion::{criterion_group, criterion_main, Criterion};

fn bench_parse(c: &mut Criterion) {
    let input = "test data".repeat(1000);
    c.bench_function("parse", |b| {
        b.iter(|| parse(black_box(&input)))
    });
}

criterion_group!(benches, bench_parse);
criterion_main!(benches);
```

## Test Naming and Documentation

### Clear Test Names

**Use descriptive names that explain what's being tested:**

```python
# ✅ GOOD - Clear intent
def test_parse_valid_json_returns_parsed_data():
    ...

def test_parse_invalid_json_raises_parse_error():
    ...

# ❌ BAD - Unclear
def test_parse():
    ...

def test_error():
    ...
```

### Document Complex Tests

```python
def test_complex_workflow():
    """Test complete data processing workflow.

    This test verifies:
    1. Data is loaded from source
    2. Transformations are applied correctly
    3. Results are saved to destination
    4. Errors are logged appropriately
    """
    # Test implementation
```

## Test Execution

### Running Tests

**Python:**
```bash
# All tests
pytest

# Specific file
pytest tests/unit/test_parser.py

# Specific test
pytest tests/unit/test_parser.py::TestParser::test_basic

# With coverage
pytest --cov=myproject --cov-report=html

# Verbose output
pytest -v

# Stop on first failure
pytest -x
```

**Rust:**
```bash
# Unit and doc tests, then integration tests
cargo test --workspace --lib --bins
cargo test --workspace --doc
cargo test --workspace --test '*'

# Coverage with the 80% gate
cargo llvm-cov --workspace --fail-under-lines 80

# Specific test
cargo test parse_valid_input

# Show output
cargo test -- --nocapture

# Run benchmarks
cargo bench
```

---

**Last Updated**: 2026-10-01
