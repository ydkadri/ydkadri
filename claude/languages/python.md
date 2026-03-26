# Python Style Guide

Python code style and patterns.

## Import Style

**All imports follow this pattern:**
- Import the module, not individual classes/functions
- Use `import module` then `module.Thing`
- For packages: `from package import module` then `module.Thing`
- Do NOT use `from module import Thing`

**Principle**: Explicit is better than implicit. Always know where something comes from.

```python
# ✅ CORRECT - Application code
from myproject import parser
from myproject import graph

ast_tree = parser.parse_file(path)
connection = graph.Neo4jConnection(uri, auth)

# ✅ CORRECT - Standard library
import pathlib
import json
from collections import abc

path = pathlib.Path("file.txt")
data = json.loads(content)
mapping = abc.MutableMapping()

# ❌ INCORRECT
from myproject.parser import parse_file
from pathlib import Path
from json import loads
```

**Exceptions for typing and common third-party patterns:**
- `from typing import Protocol, Optional` - typing imports are fine
- Third-party frameworks may have idiomatic patterns (e.g., `from typer import Typer`)

## Protocol Naming

Protocols describe behaviors, not roles. Use verb-based naming:

```python
# ✅ CORRECT
class ParsesCode(Protocol):
    def parse(self, source: str) -> ast.Module: ...

class StoresGraph(Protocol):
    def store(self, node: GraphNode) -> None: ...

class ValidatesInput(Protocol):
    def validate(self, data: dict) -> bool: ...

# ❌ INCORRECT
class CodeParser(Protocol): ...
class GraphStore(Protocol): ...
class InputValidator(Protocol): ...
```

## Naming Conventions

Follow PEP8:
- **Classes**: `PascalCase`
- **Functions/variables**: `snake_case`
- **Constants**: `SCREAMING_SNAKE_CASE` (module level, at top)

### Public vs Private

**Explicit is better than implicit** - always clear about visibility:

- **Public**: `no_underscore` - part of public API, in `__all__`
- **Private**: `_single_underscore` - internal use
- **Very private**: `__double_underscore` - for class properties that need protection (getters/setters, read-only)

**Rule**: If something is not in `__all__`, it must be `_underscore` named or in a `_private.py` module. No implicitly private code.

## Package Structure

### Prefer Isolated Modules

Organize by purpose, not by type:
```
mypackage/
├── __init__.py
├── constants.py
├── queries.py
├── models.py
└── _internal.py
```

**NEVER use vague names** like `utils.py` or `helpers.py`. Be specific about purpose.

### Private Modules

Use `_private.py` modules when you have internal implementation details:
- Entire module is internal - everything in it can be accessed but not documented as public API
- Be specific about what the module does, even for private modules

### `__init__.py` Pattern

`__init__.py` should:
1. Import public items from modules
2. Define `__all__` explicitly

```python
# mypackage/__init__.py
from mypackage import models
from mypackage import queries
from mypackage.models import User, Account
from mypackage.queries import find_user

__all__ = ["models", "queries", "User", "Account", "find_user"]
```

### Class Design

Prefer public API with private methods.

**Method ordering**: Private methods first, then public methods.

```python
class DataProcessor:
    """Public API."""

    def _validate(self, data: str) -> None:
        """Private method - internal implementation."""
        ...

    def _transform(self, data: str) -> Result:
        """Private method - internal implementation."""
        ...

    def process(self, data: str) -> Result:
        """Public method - called by users."""
        self._validate(data)
        return self._transform(data)
```

**Benefit**: Parent classes can define public API with consistent logging/behavior, children implement private methods.

**Inheritance pattern**:
```python
class BaseProcessor:
    """Parent defines public API."""

    def _process_internal(self, data: str) -> Result:
        """Private method - override in children."""
        raise NotImplementedError

    def process(self, data: str) -> Result:
        """Public method - called by users."""
        log.info("processing_started", data_size=len(data))
        result = self._process_internal(data)
        log.info("processing_completed", status=result.status)
        return result

class JSONProcessor(BaseProcessor):
    """Child implements private methods."""

    def _process_internal(self, data: str) -> Result:
        """Specific implementation for JSON."""
        return parse_json(data)
```

This ensures consistent logging, error handling, and behavior across implementations while keeping the public API stable.

### Tests

- Mirror source structure
- Group related tests in classes (not flat functions)
- Separate unit tests from integration tests
- Organize by both type and module using package/subpackage structure

```
tests/
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

## Testing Style

Prefer test classes over flat functions:

```python
# ✅ CORRECT - Test classes group related tests
class TestAnalyzeCommand:
    """Tests for analyze command."""

    def test_basic_analysis(self):
        """Test basic analysis with required path."""
        ...

    def test_with_options(self):
        """Test with command options."""
        ...

# ❌ INCORRECT - Flat test functions
def test_analyze_basic():
    ...

def test_analyze_options():
    ...
```

**Benefits**: Better organization, easier setup/teardown, clearer test hierarchy

## Logging

### Use Structured Logging

Use `structlog` for all logging:
- Human-readable colorized stdout in development
- JSON format in file logs for production
- Bind context (request IDs, user IDs, etc.) that persists across calls

See [examples/structlog_config.py](examples/structlog_config.py) for full configuration.

### Log Levels

- **DEBUG**: Detailed flow - entry/exit of functions, if/else decisions, task/subtask start/stop, function timing
- **INFO**: High-level progress - job started/completed, milestones, aggregate metrics
- **WARNING**: Unexpected but handled - retries, slow operations, degraded mode
- **ERROR**: Task failed but process continues - single file failed, request error
- **CRITICAL**: System failure - database down, cannot continue

**Default levels:**
- Development: DEBUG
- Production: INFO

### What to Log

**Always log:**
- Job/process start and completion with aggregate metrics (INFO)
- Errors with full exception tracebacks (ERROR)
- Timestamps (UTC)
- Module and function name (automatic with structlog)
- Relevant context (IDs, operation types)

**Use DEBUG for:**
- Function entry/exit
- Conditional branches (if/else decisions)
- Task and subtask start/stop
- Function timing/duration

**Aggregate metrics** at job completion (INFO):
```python
log.info(
    "job_completed",
    total_records=1000,
    successful=950,
    failed=50,
    duration_seconds=45.3,
    status="success"
)
```

### Never Log Sensitive Data

Do NOT log:
- Passwords, tokens, API keys
- Credentials of any kind
- Personal identifiable information (PII)
- Credit card numbers, SSNs

Use automatic scrubbing for common field names (password, token, api_key, secret).

See also: [security.md](security.md) for sensitive data handling.

## Error Handling

### Fail Fast

Prefer raising exceptions over returning error values. Let errors propagate rather than hiding them.

### Custom Exception Types

Create custom exceptions for your domain. Explicit is better than implicit.

**Pattern**: Define exceptions in `exceptions.py` with inheritance hierarchy:

```python
# mypackage/exceptions.py
class MyPackageError(Exception):
    """Base exception for mypackage."""
    pass

class ValidationError(MyPackageError):
    """Validation failed."""
    pass

class ParseError(MyPackageError):
    """Parsing failed."""
    pass

class ConfigurationError(MyPackageError):
    """Configuration is invalid."""
    pass
```

### Error Messages and Logging

**Context is king**. Provide enough information to understand and debug the error.

With structured logging, the error is the event name, details are key-value pairs:

```python
try:
    result = parse_file(path)
except ParseError as e:
    log.exception(
        "file_parsing_failed",  # Event
        file=str(path),         # Context
        line=42,
        expected_header="id",
        found_headers=["name", "email"],
    )
    raise  # Re-raise after logging
```

**Use `log.exception()`** - automatically includes full stack trace.

### Exception Raising

Include context when raising exceptions:

```python
# ✅ GOOD - Context included
raise ParseError(
    f"Missing required header 'id' in file {path} at line {line_num}"
)

# ❌ BAD - No context
raise ParseError("Missing header")
```

### Catching Specific Exceptions

**Always catch specific exceptions, never use bare `except Exception`.**

Catching `Exception` is too broad and hides bugs by catching everything including `KeyboardInterrupt` and `SystemExit`.

```python
# ✅ CORRECT - Catch specific exceptions
try:
    data = parse_file(path)
except FileNotFoundError:
    log.error("file_not_found", path=str(path))
    raise
except ParseError as e:
    log.error("parsing_failed", path=str(path), error=str(e))
    raise
except PermissionError:
    log.error("permission_denied", path=str(path))
    raise

# ✅ CORRECT - Multiple specific exceptions
try:
    result = process_data(data)
except (ValidationError, ParseError) as e:
    log.error("data_processing_failed", error=str(e))
    raise

# ❌ INCORRECT - Too broad
try:
    result = process_data(data)
except Exception as e:  # Catches everything
    log.error("something_failed", error=str(e))
    raise
```

**When you must catch broadly** (e.g., top-level error handler), catch specific groups:

```python
# At application boundary only
try:
    run_application()
except MyPackageError as e:
    # Catch only our application errors
    log.exception("application_error")
    sys.exit(1)
except KeyboardInterrupt:
    # Handle Ctrl+C gracefully
    log.info("interrupted_by_user")
    sys.exit(130)
```

**Why this matters:**
- Specific exceptions document what can go wrong
- Forces you to think about error cases
- Prevents hiding bugs (typos, attribute errors, etc.)
- Makes debugging easier

## Type Hints

### Type Everything

Use type hints on all functions, including private ones:

```python
def parse_data(content: str, encoding: str = "utf-8") -> dict[str, Any]:
    """Parse data from string."""
    ...

def _validate(data: dict[str, Any]) -> None:
    """Validate parsed data."""
    ...
```

### Return Types Always

Always specify return types, even `-> None`:

```python
def process_file(path: pathlib.Path) -> None:
    """Process file."""
    ...
```

### Union Types with Pipe

Use `|` syntax for unions (PEP 604):

```python
def find_user(user_id: str) -> User | None:
    """Find user by ID, return None if not found."""
    ...

def parse_value(raw: str) -> int | float | str:
    """Parse value to appropriate type."""
    ...
```

### Protocols and ABCs

Use `Protocol` for structural typing and ABC for concrete base classes:

```python
from typing import Protocol
from abc import ABC, abstractmethod

# Protocol - structural typing (duck typing with types)
class SupportsRead(Protocol):
    def read(self, n: int) -> bytes: ...

# ABC - concrete base class with inheritance
class DataProcessor(ABC):
    @abstractmethod
    def process(self, data: str) -> Result:
        """Process data."""
        ...
```

### Generics

Use `TypeVar` and generics when needed, but don't overuse:

```python
from typing import TypeVar

T = TypeVar("T")

def first(items: list[T]) -> T | None:
    """Return first item or None."""
    return items[0] if items else None
```

### Type Checking

Run mypy in **strict mode**:

```bash
mypy --strict .
```

Configure structural rules in `pyproject.toml`:

```toml
[tool.mypy]
strict = true
warn_return_any = true
warn_unused_configs = true

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false  # Less strict in tests
```

Use `# type: ignore` for edge cases:

```python
result = untyped_library.function()  # type: ignore[no-untyped-call]
```

## Docstrings

### Google Style

Use Google-style docstrings for all public functions, classes, methods, and modules.

**Structure:**
1. One-line summary
2. Detailed explanation (purpose, decision points, behavior)
3. Args, Returns, Raises sections as needed

```python
def parse_data(content: str, validate: bool = True) -> dict[str, Any]:
    """Parse structured data from string content.

    Attempts to parse JSON first, falls back to YAML if JSON fails.
    If validation is enabled, checks for required fields.

    Args:
        content: Raw string data to parse
        validate: Whether to validate parsed data against schema

    Returns:
        Parsed data as dictionary with string keys

    Raises:
        ParseError: If content cannot be parsed as JSON or YAML
        ValidationError: If validation fails and validate=True
    """
    ...
```

### Required Docstrings

All public objects require docstrings:
- Modules (at top of file)
- Classes
- Public functions and methods
- Public constants (if not obvious)

Private functions should have docstrings if the logic is complex.

### No Usage Examples

Docstrings should explain purpose and behavior, not show usage examples. Examples belong in documentation or tests.

## Context Managers

### When to Use

Always use context managers for:
- Files and file-like objects
- Database connections and transactions
- Network connections
- Locks and synchronization primitives

Also useful for:
- Temporary state changes (working directory, environment variables)
- Timing and performance measurement
- Cleanup operations (temporary files, test fixtures)

### Implementation

Prefer `__enter__` and `__exit__` methods over `@contextmanager` decorator:

```python
class ResourceManager:
    def __init__(self, resource_id: str):
        self.resource_id = resource_id
        self.resource = None

    def __enter__(self):
        self.resource = acquire_resource(self.resource_id)
        return self.resource

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.resource:
            release_resource(self.resource)
        return False  # Don't suppress exceptions
```

### Common Patterns

**Transaction management:**
```python
class DatabaseTransaction:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        self.connection.begin()
        return self.connection

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None:
            self.connection.commit()
        else:
            self.connection.rollback()
        return False
```

**Temporary state:**
```python
class ChangeDirectory:
    def __init__(self, path: pathlib.Path):
        self.path = path
        self.original_path = None

    def __enter__(self):
        self.original_path = pathlib.Path.cwd()
        os.chdir(self.path)
        return self.path

    def __exit__(self, exc_type, exc_val, exc_tb):
        os.chdir(self.original_path)
        return False
```

**Timing:**
```python
class Timer:
    def __init__(self, name: str, logger):
        self.name = name
        self.logger = logger
        self.start_time = None

    def __enter__(self):
        self.start_time = time.time()
        self.logger.debug(f"{self.name}_started")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        self.logger.debug(
            f"{self.name}_completed",
            duration_seconds=duration
        )
        return False
```

## Decorators

### Minimal Use

Use decorators sparingly. Primary use cases:
- CLI argument definitions (Typer/Click)
- Property getters/setters
- Validation (e.g., attrs validators)

### Implementation

When creating custom decorators:
- **Prefer function decorators** over class-based decorators
- **Always use `@functools.wraps`** to preserve function metadata

```python
import functools

def my_decorator(func):
    @functools.wraps(func)  # Preserves __name__, __doc__, etc.
    def wrapper(*args, **kwargs):
        # Decorator logic
        return func(*args, **kwargs)
    return wrapper
```

### Validation Decorators

Use decorator-based validation with attrs:

```python
import attrs

@attrs.define
class Config:
    host: str
    port: int

    @port.validator
    def validate_port(self, attribute, value):
        if not 1 <= value <= 65535:
            raise ValueError(f"Port must be 1-65535, got {value}")
```

## Data Classes

### Use attrs

Use `attrs` for data classes (not stdlib dataclasses).

### Immutable by Default

Prefer frozen (immutable) dataclasses. If you need to change something, create a new object explicitly.

```python
import attrs

@attrs.define(frozen=True)
class User:
    id: str
    name: str
    email: str

# To "modify", create new instance
user = User(id="123", name="Alice", email="alice@example.com")
updated = attrs.evolve(user, email="newemail@example.com")
```

### Data Only

Use dataclasses only for data containers, not objects with behavior. If you need methods/logic, use regular classes.

## String Formatting

### Always Use f-strings

Use f-strings for all string formatting:

```python
# ✅ CORRECT
name = "Alice"
greeting = f"Hello, {name}!"
result = f"Processing {count} items in {duration:.2f}s"

# ❌ INCORRECT
greeting = "Hello, {}!".format(name)
greeting = "Hello, %s!" % name
```

## CLI Patterns

### Structure

Organize CLIs with Typer:
- Core commands on root app
- Related commands in command groups (subcommands)
- Separate module per command group

```python
# cli/__init__.py
import typer

app = typer.Typer(help="My CLI tool")

# Core commands
app.command(name="init")(setup.init)
app.command(name="version")(version.version)

# Command groups
app.add_typer(analyse.app, name="analyse")
app.add_typer(config.app, name="config")
```

### Output with Rich

Use Rich library for user-friendly output:
- Colored output for humans
- Progress bars with spinners for long operations
- Tables for structured data
- Status symbols (✓ ✗ ⚠)

```python
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, BarColumn
from rich.table import Table

console = Console()
console.print("[bold green]✓ Success[/bold green]")
```

### Output Modes

Support multiple output modes:
- Default: Rich formatted output
- `--quiet`: Minimal output
- `--verbose`: Detailed output
- `--json`: Machine-readable JSON output

### Error Handling

- Exit with code 1 on errors, 0 on success
- Display warnings separately from errors
- Provide contextual error messages
- Include "Next steps" guidance when helpful

### Configuration

Support configuration hierarchy:
- Config files (TOML)
- Environment variables
- CLI arguments
- Interactive prompts for setup

Precedence: global config < local config < env vars < CLI args

## Configuration Management

### File Format

Use TOML for configuration files.

### Loading

Load configuration at application startup:

```python
config = load_config()
app = MyApp(config)
app.run()
```

### Structure with attrs

Define configuration with attrs:

```python
import attrs
from attrs import field

def _validate_port(instance, attribute, value):
    if not 1 <= value <= 65535:
        raise ValueError(f"Port must be 1-65535, got {value}")

@attrs.define
class DatabaseConfig:
    host: str = "localhost"
    port: int = field(default=5432, validator=_validate_port)
    timeout: int = 30

@attrs.define
class Config:
    database: DatabaseConfig
    debug: bool = False
```

### Generated Config Files

Generated or shipped config files should include all options commented with defaults (self-documenting):

```toml
# Database connection
# host = "localhost"  # Default
# port = 5432         # Default
# timeout = 30        # Default

# Uncomment to override
host = "prod-db.example.com"
```

### Secrets

Never store secrets in config files. Always use environment variables. See [security.md](security.md).

### Hierarchy

Configuration precedence (lowest to highest):
1. Defaults in attrs class
2. Global config file
3. Local config file
4. Environment variables
5. CLI arguments or user input

## Testing with pytest

### Mocking

Use `pytest-mock` (fits pytest ecosystem):

```python
def test_api_call(mocker):
    mock_requests = mocker.patch("myapp.requests")
    mock_requests.get.return_value.json.return_value = {"status": "ok"}

    result = call_api()
    assert result["status"] == "ok"
```

### When to Mock

- **Unit tests**: Always mock external dependencies
- **Integration tests**: Use real dependencies (databases, services)

### Fixtures

Define fixtures in `conftest.py`:

```python
# conftest.py
import pytest

@pytest.fixture(scope="class")
def database():
    """Test database fixture."""
    db = create_test_db()
    yield db
    db.cleanup()
```

### Test Data

Define test data inline in tests for clarity:

```python
def test_parse_user():
    # Inline test data
    raw_data = {"id": "123", "name": "Alice"}

    user = parse_user(raw_data)
    assert user.id == "123"
```

### Fixture Scope

Scope fixtures minimally:
- **Class scope**: If needed by all tests in a class
- **Module/session scope**: If expensive to create and safe to share
- **Avoid function scope**: Define data inline in the function instead

## Async/Await

[TO BE DEFINED - async patterns used at work but no strong personal opinions yet]

## Code Quality Standards

### Before Every Commit

- Format code first (use ruff format or black)
- Linting must pass (use ruff)
- Type checking must pass (use mypy or pyright)
- Never commit code that fails linting or type checking

### Testing Requirements

- Write tests for all new functionality
- Aim for 80%+ test coverage
- Test happy paths, edge cases, and error handling

## Package Management

- Prefer `uv` for Python package management (fast, modern)
- Use `pyproject.toml` for project configuration
- Keep dependencies up to date

## Common Tools

- **Package Manager**: uv
- **Linting**: ruff (fast, comprehensive)
- **Type Checking**: mypy or pyright
- **Formatting**: ruff format or black
- **Testing**: pytest, pytest-asyncio, pytest-mock
- **Task Runner**: just (for complex commands)

## Common Commands

```bash
# Using uv
uv sync                 # Install dependencies
uv run pytest          # Run tests
uv run mypy .          # Type checking
uv run ruff check .    # Linting
uv run ruff format .   # Formatting

# Using just (if configured)
just install
just test
just lint
just format
```

---

**Last Updated**: 2026-03-23
