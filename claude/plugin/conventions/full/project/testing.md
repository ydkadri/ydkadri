# Testing Strategy

Testing approach and requirements.

## When to Write Tests

**Write tests alongside implementation**, not strictly before or after.

### Approach

1. **Write interface/API first** - Design how code will be used
2. **Implement core logic** - Get basic functionality working
3. **Write tests** - Cover happy paths, edge cases, errors
4. **Refine** - Adjust implementation and tests together

Not strict TDD, but tests are expected for all new functionality.

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
- Tests in `tests/` directory
- Separate unit and integration tests

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
// Rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_case() {
        ...
    }
}
```

### Fixtures and Test Data

**Python - Use pytest fixtures:**

```python
# tests/conftest.py - Shared fixtures
import pytest

@pytest.fixture
def sample_user():
    """Provide sample user data."""
    return User(email="test@example.com", name="Test User")

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

**Rust - Use test helpers:**

```rust
// tests/common/mod.rs
use tempfile::TempDir;

pub fn create_test_dir() -> TempDir {
    TempDir::new().unwrap()
}

pub fn sample_config() -> Config {
    Config {
        host: "localhost".to_string(),
        port: 5432,
    }
}
```

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

### Rust Mocking

**Use traits for dependency injection:**

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
    struct MockClient;

    impl FetchesData for MockClient {
        fn fetch(&self, url: &str) -> Result<String, Error> {
            Ok("mocked response".to_string())
        }
    }

    #[test]
    fn test_with_mock() {
        let client = MockClient;
        let result = process_data(&client);
        assert!(result.is_ok());
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

- **Target**: 80% coverage (unless explicitly specified otherwise)
- Required in pre-push hooks
- CI enforces coverage requirements

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

**80% coverage target is a guideline, not absolute rule:**
- Cover happy paths
- Cover error cases
- Cover edge cases
- Don't write tests just to hit percentage

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

### Rust - criterion (always required)

See rust.md for detailed benchmark patterns. All Rust projects should include benchmarks.

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

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
# All tests
cargo test

# Specific test
cargo test test_parse

# Show output
cargo test -- --nocapture

# Run benchmarks
cargo bench
```

---

**Last Updated**: 2026-03-23
