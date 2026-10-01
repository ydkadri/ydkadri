# Rust Style Guide

Rust code style and patterns.

## Naming Conventions

Follow Rust conventions:

- **Structs/Enums**: `PascalCase` nouns (e.g., `DataParser`, `ConnectionState`)
- **Traits**: `PascalCase` 3rd person present tense verbs (e.g., `Parses`, `Writes`, not `Parser` or `Parse`)
- **Functions/variables**: `snake_case` describing their outcome
  - Prefer common descriptive verbs by context: `get_thing`, `post_data` (HTTP); `read_file`, `write_data` (files)
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Lifetimes**: `'short_lowercase`

```rust
// ✅ CORRECT
struct DataParser;              // Noun
trait Parses { ... }            // 3rd person present tense verb
const MAX_BUFFER_SIZE: usize = 1024;
fn parse_input(data: &str) -> Result<ParsedData, Error> { ... }  // Describes outcome
fn get_user(id: u64) -> Option<User> { ... }                      // Common verb
fn read_config(path: &Path) -> Result<Config, Error> { ... }      // Context-specific verb

// ❌ INCORRECT
struct dataParser;              // Wrong case
trait Parser { ... }            // Noun, not verb
trait Parse { ... }             // Not 3rd person present tense
const maxBufferSize: usize = 1024;
fn ParseInput(data: &str) -> Result<ParsedData, Error> { ... }   // Wrong case
```

## Code Organization

### Project Structure

```
src/
├── lib.rs or main.rs
├── module_name/
│   ├── mod.rs
│   └── submodule.rs
└── another_module.rs
```

### Module Organization

- Use `mod.rs` or module files for logical grouping
- Keep related functionality together
- Separate public API from internal implementation

### Split by Functionality

Organize modules by purpose, not by type:

```rust
// lib.rs
pub mod config;      // Configuration management
pub mod parser;      // Parsing logic
pub mod storage;     // Data storage
mod _internal;       // Private implementation details
```

### Minimal Public API

Everything is private by default. Only expose what's needed:

```rust
pub struct Config {
    pub host: String,     // Public field - part of API
    timeout: u32,         // Private field
}

impl Config {
    // Private helper
    fn validate(&self) -> Result<(), ConfigError> {
        // ...
    }

    // Public API
    pub fn new(host: String) -> Self {
        // ...
    }
}
```

### Builder Pattern

Use builder pattern for complex initialization:

```rust
pub struct ConfigBuilder {
    host: String,
    port: u16,
    timeout: Option<u32>,
    retries: Option<u32>,
}

impl ConfigBuilder {
    pub fn new(host: String, port: u16) -> Self {
        Self {
            host,
            port,
            timeout: None,
            retries: None,
        }
    }

    pub fn timeout(mut self, timeout: u32) -> Self {
        self.timeout = Some(timeout);
        self
    }

    pub fn retries(mut self, retries: u32) -> Self {
        self.retries = Some(retries);
        self
    }

    pub fn build(self) -> Result<Config, ConfigError> {
        // Validate before building
        if self.timeout == Some(0) {
            return Err(ConfigError::Invalid("timeout cannot be 0".into()));
        }

        Ok(Config {
            host: self.host,
            port: self.port,
            timeout: self.timeout.unwrap_or(30),
            retries: self.retries.unwrap_or(3),
        })
    }
}

// Usage
let config = ConfigBuilder::new("localhost".to_string(), 5432)
    .timeout(60)
    .retries(5)
    .build()?;
```

### Binary Entrypoints

Cargo automatically discovers binaries in `src/bin/`:

```
src/
├── lib.rs              # Library code
├── main.rs             # Default binary (optional)
└── bin/
    ├── finder.rs       # cargo run --bin finder
    ├── processor.rs    # cargo run --bin processor
    └── analyzer.rs     # cargo run --bin analyzer
```

**Each binary can use the library**:
```rust
// src/bin/finder.rs
use myproject::config::Config;
use myproject::search::Searcher;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::load()?;
    let searcher = Searcher::new(config);
    searcher.run()?;
    Ok(())
}
```

**In `Cargo.toml`**, binaries are auto-discovered:
```toml
[package]
name = "myproject"

# Optional: explicit binary configuration
[[bin]]
name = "finder"
path = "src/bin/finder.rs"
```

**Running binaries**:
```bash
# Run specific binary
cargo run --bin finder

# Build all binaries
cargo build --bins

# Install binary globally
cargo install --path . --bin finder
```

### Workspace Structure

For projects with multiple related crates, use a workspace:

```
my_workspace/
├── Cargo.toml          # Workspace root
├── crates/
│   ├── mylib/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── lib.rs
│   ├── mylib_cli/
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── main.rs
│   │       └── bin/
│   │           └── mycli.rs
│   └── mylib_extras/
│       ├── Cargo.toml
│       └── src/
│           └── lib.rs
```

**Workspace `Cargo.toml`**:
```toml
[workspace]
members = [
    "crates/mylib",
    "crates/mylib_cli",
    "crates/mylib_extras",
]
resolver = "2"

# Shared dependencies across workspace
[workspace.dependencies]
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
anyhow = "1.0"
```

**Member crate using workspace dependencies**:
```toml
# crates/mylib/Cargo.toml
[package]
name = "mylib"
version = "0.1.0"

[dependencies]
tokio = { workspace = true }
serde = { workspace = true }
```

**Workspace member relationships**:
```toml
# crates/mylib_cli/Cargo.toml
[package]
name = "mylib-cli"
version = "0.1.0"

[dependencies]
mylib = { path = "../mylib" }          # Local dependency
mylib_extras = { path = "../mylib_extras", optional = true }
tokio = { workspace = true }
anyhow = { workspace = true }
```

**Building workspace members**:
```bash
# Build all members
cargo build --workspace

# Build specific member
cargo build -p mylib

# Run binary from member
cargo run -p mylib-cli --bin mycli

# Test all members
cargo test --workspace
```

### Features and Optional Dependencies

Use features for optional functionality:

**Defining features**:
```toml
[package]
name = "mylib"

[dependencies]
# Always included
serde = "1.0"

# Optional dependencies
tokio = { version = "1.0", optional = true }
tracing = { version = "0.1", optional = true }

[features]
default = ["std"]

# Feature flags
std = []
async = ["tokio"]           # Enables tokio when async feature is used
logging = ["tracing"]       # Enables tracing when logging feature is used
full = ["async", "logging"] # Enables multiple features
```

**Using features in code**:
```rust
// Conditionally compile based on features
#[cfg(feature = "async")]
pub async fn fetch_data() -> Result<Data, Error> {
    // Async implementation using tokio
}

#[cfg(not(feature = "async"))]
pub fn fetch_data() -> Result<Data, Error> {
    // Sync implementation
}
```

**Building with features**:
```bash
# Build with specific features
cargo build --features async,logging

# Build with all features
cargo build --all-features

# Build with no default features
cargo build --no-default-features

# Run with features
cargo run --features s3 --bin mytool
```

**Installing binaries with features**:

Features are **compile-time** - they're baked into the binary at install time.

```bash
# Install core functionality only
cargo install my-io-tool

# Install with S3 support (compiles S3 code into binary)
cargo install my-io-tool --features s3

# Install with multiple features
cargo install my-io-tool --features s3,postgres

# Install with all features
cargo install my-io-tool --all-features

# Change features (must reinstall with --force)
cargo install my-io-tool --features s3,postgres --force
```

**Core + Plugin pattern example**:

```toml
# File I/O tool with optional backend support
[package]
name = "my-io-tool"

[dependencies]
# Core dependencies (always included)
anyhow = "1.0"
clap = "4.0"

# Optional backend dependencies (plugins)
aws-sdk-s3 = { version = "1.0", optional = true }
sqlx = { version = "0.7", features = ["postgres"], optional = true }

[features]
default = []  # No plugins by default
s3 = ["aws-sdk-s3"]           # S3 plugin
postgres = ["sqlx"]           # Postgres plugin
all = ["s3", "postgres"]      # All plugins
```

```rust
// src/backends/s3.rs - Only compiled if 's3' feature enabled
#[cfg(feature = "s3")]
pub struct S3Backend {
    client: aws_sdk_s3::Client,
}

#[cfg(feature = "s3")]
impl S3Backend {
    pub fn new() -> Self {
        // S3 client setup
    }
}
```

**Installing the tool**:
```bash
# Core only (local filesystem)
cargo install my-io-tool

# With S3 support compiled in
cargo install my-io-tool --features s3

# With all plugins compiled in
cargo install my-io-tool --all-features

# From local workspace during development
cargo install --path . --features s3
```

**Key difference from Python**:
- **Rust**: Features compiled into binary at install time. To change features, reinstall with `--force`.
- **Python**: Plugins discovered at runtime. Add/remove plugins anytime without reinstalling core.
- **Both**: Support `install mytool[extras]` pattern for library and CLI usage.

**Depending on crates with features**:
```toml
[dependencies]
mylib = { version = "0.1", features = ["async", "logging"] }

# Or from workspace
mylib = { path = "../mylib", features = ["full"] }
```

**Feature best practices**:
- Keep `default` minimal - only include widely-needed features
- Use descriptive feature names: `async`, `s3`, `postgres`, `compression`
- Document feature requirements in crate README
- Document feature installation in README: "Install with S3: `cargo install mytool --features s3`"
- Avoid feature explosion - combine related functionality
- Test with `--no-default-features` to catch missing feature gates
- Version optional dependencies carefully - breaking changes affect all users of that feature

## Trait Design

Keep traits focused and cohesive:

```rust
// ✅ CORRECT - Focused traits with verb names
trait Parses {
    fn parse(&self, input: &str) -> Result<Self::Output, ParseError>;
    type Output;
}

trait Validates {
    fn validate(&self) -> Result<(), ValidationError>;
}

// ❌ AVOID - Kitchen sink traits
trait DoesEverything {
    fn parse(&self) -> Result<Data, Error>;
    fn validate(&self) -> bool;
    fn serialize(&self) -> String;
    fn save(&self) -> Result<(), Error>;
}
```

## Function and Method Ordering

**Define functions and methods before they are called. Read top-to-bottom.**

Code should be readable from top to bottom. Define functions before anything references them.

### Module Level

```rust
// ✅ CORRECT - Helper defined before use
fn format_timestamp(ts: SystemTime) -> String {
    // Format timestamp for display
    format!("{:?}", ts)
}

fn process_log_entry(entry: &LogEntry) -> String {
    let timestamp = format_timestamp(entry.timestamp);
    format!("{}: {}", timestamp, entry.message)
}

// ❌ INCORRECT - Helper used before definition
fn process_log_entry(entry: &LogEntry) -> String {
    let timestamp = format_timestamp(entry.timestamp); // Not yet defined!
    format!("{}: {}", timestamp, entry.message)
}

fn format_timestamp(ts: SystemTime) -> String {
    format!("{:?}", ts)
}
```

### Method Organization

Order methods: private first, then public.

```rust
impl DataProcessor {
    // Private methods first
    fn validate(&self, data: &str) -> Result<(), Error> {
        // ...
    }

    fn transform(&self, data: &str) -> Result<Output, Error> {
        // ...
    }

    // Public methods after
    pub fn new(config: Config) -> Self {
        // ...
    }

    pub fn process(&self, data: &str) -> Result<Output, Error> {
        self.validate(data)?;
        self.transform(data)
    }
}
```

### Struct with Helper Methods

```rust
// ✅ CORRECT - Helper before new()
pub struct Configuration {
    db_url: String,
}

impl Configuration {
    // Private helper before it's used
    fn build_database_url(host: &str, port: u16, db: &str) -> String {
        format!("postgresql://{}:{}/{}", host, port, db)
    }

    // new() uses the helper
    pub fn new(host: &str, port: u16, db: &str) -> Self {
        Self {
            db_url: Self::build_database_url(host, port, db),
        }
    }

    pub fn connect(&self) -> Result<Connection, Error> {
        create_connection(&self.db_url)
    }
}

// ❌ INCORRECT - Helper after it's used
impl Configuration {
    pub fn new(host: &str, port: u16, db: &str) -> Self {
        Self {
            db_url: Self::build_database_url(host, port, db), // Not yet defined!
        }
    }

    fn build_database_url(host: &str, port: u16, db: &str) -> String {
        format!("postgresql://{}:{}/{}", host, port, db)
    }
}
```

**Ordering within an impl block:**
1. Private helper methods
2. `new()` / constructors
3. Public methods

**Why this matters:**
- Read code naturally from top to bottom
- Understand helpers before seeing them used
- Easier to follow logic flow
- Consistent with how most code is read

## Testing

### Test Organization

Use separate `tests/` directory:

```
tests/
├── common/
│   └── mod.rs           # Shared test utilities
├── unit/
│   ├── test_parser.rs
│   └── test_config.rs
└── integration/
    └── test_workflows.rs
```

### Basic Test Structure

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_parsing() {
        let input = "test data";
        let result = parse(input);
        assert!(result.is_ok());
    }

    #[test]
    fn test_error_handling() {
        let input = "invalid";
        let result = parse(input);
        assert!(result.is_err());
    }
}
```

### Table-Driven Tests

Use table-driven tests for testing the same functionality with multiple inputs:

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // ✅ CORRECT - Table-driven test for clear test cases
    #[test]
    fn test_port_validation() {
        let test_cases = [
            (0, false, "zero"),
            (1, true, "min valid"),
            (65535, true, "max valid"),
            (65536, false, "too large"),
        ];

        for (port, should_pass, description) in test_cases {
            let result = validate_port(port);
            if should_pass {
                assert!(result.is_ok(), "Failed for case: {}", description);
            } else {
                assert!(result.is_err(), "Should have failed for case: {}", description);
            }
        }
    }

    // ✅ CORRECT - Table-driven for transformation tests
    #[test]
    fn test_uppercase_conversion() {
        let test_cases = [
            ("hello", "HELLO"),
            ("world", "WORLD"),
            ("", ""),
            ("MiXeD", "MIXED"),
        ];

        for (input, expected) in test_cases {
            assert_eq!(
                to_uppercase(input),
                expected,
                "Failed to convert: {}",
                input
            );
        }
    }

    // ❌ AVOID - Different behaviors in same table
    #[test]
    fn test_file_operations_mixed() {
        let test_cases = [
            ("valid.txt", Ok(vec![1, 2, 3])),
            ("empty.txt", Ok(vec![])),
            ("nonexistent.txt", Err("not found")),  // Different behavior!
        ];

        for (file, expected) in test_cases {
            // Complex branching logic makes this hard to read
            match expected {
                Ok(data) => assert_eq!(read_file(file).unwrap(), data),
                Err(_) => assert!(read_file(file).is_err()),
            }
        }
    }

    // ✅ BETTER - Separate tests for different behaviors
    #[test]
    fn test_read_valid_file() {
        assert_eq!(read_file("valid.txt").unwrap(), vec![1, 2, 3]);
    }

    #[test]
    fn test_read_empty_file() {
        assert_eq!(read_file("empty.txt").unwrap(), vec![]);
    }

    #[test]
    fn test_read_nonexistent_file() {
        assert!(read_file("nonexistent.txt").is_err());
    }
}
```

**When to use table-driven tests:**
- Testing the same function with multiple inputs/outputs
- Edge cases and boundary conditions
- Test logic is identical, only inputs differ
- Makes it easy to add more test cases

**When NOT to use:**
- Test logic differs between cases
- Testing fundamentally different behaviors
- Complex scenarios where readability suffers

### Trait-Based Testing

Use traits for dependency injection rather than mocking:

```rust
// ✅ CORRECT - Trait-based testing
pub trait DataStore {
    fn save(&mut self, data: &Data) -> Result<(), Error>;
    fn load(&self, id: &str) -> Result<Data, Error>;
}

pub struct DataProcessor<S: DataStore> {
    store: S,
}

impl<S: DataStore> DataProcessor<S> {
    pub fn new(store: S) -> Self {
        Self { store }
    }

    pub fn process(&mut self, data: Data) -> Result<(), Error> {
        // Process and save
        self.store.save(&data)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Test implementation of the trait
    struct MockStore {
        saved_data: Vec<Data>,
    }

    impl DataStore for MockStore {
        fn save(&mut self, data: &Data) -> Result<(), Error> {
            self.saved_data.push(data.clone());
            Ok(())
        }

        fn load(&self, id: &str) -> Result<Data, Error> {
            self.saved_data
                .iter()
                .find(|d| d.id == id)
                .cloned()
                .ok_or(Error::NotFound)
        }
    }

    #[test]
    fn test_processor_saves_data() {
        let mock_store = MockStore { saved_data: vec![] };
        let mut processor = DataProcessor::new(mock_store);

        let data = Data { id: "123".to_string(), value: 42 };
        processor.process(data.clone()).unwrap();

        assert_eq!(processor.store.saved_data.len(), 1);
        assert_eq!(processor.store.saved_data[0].id, "123");
    }
}

// ❌ AVOID - Tight coupling without trait
pub struct DataProcessor {
    database: Database,  // Concrete type - hard to test
}

impl DataProcessor {
    pub fn process(&mut self, data: Data) -> Result<(), Error> {
        self.database.save(&data)  // Must use real database in tests
    }
}
```

**Benefits of trait-based testing:**
- No mocking libraries needed
- Type-safe test implementations
- Documents dependencies clearly
- Easy to test different scenarios
- Idiomatic Rust

**When to use traits:**
- Testing code with external dependencies (databases, APIs, file systems)
- Testing different implementations of same behavior
- Making code testable without mocking frameworks

### Test Helpers

Put shared utilities in `tests/common/mod.rs`:

```rust
// tests/common/mod.rs
use std::path::PathBuf;

pub fn setup_test_config() -> Config {
    Config::new("localhost".to_string(), 5432)
        .timeout(30)
}

pub fn create_temp_file(content: &str) -> PathBuf {
    // Helper to create temp test file
    // ...
}
```

Use in tests:

```rust
// tests/unit/test_parser.rs
mod common;

#[test]
fn test_parse_with_config() {
    let config = common::setup_test_config();
    // ...
}
```

### Test Data

Define test data inline:

```rust
#[test]
fn test_parse() {
    let input = "test data";
    let expected = ParsedData {
        value: "test".to_string(),
    };

    assert_eq!(parse(input), expected, "Failed to parse test data");
}
```

### Custom Assertion Messages

Always include context in assertions:

```rust
#[test]
fn test_config_validation() {
    let config = Config::new("localhost".to_string(), 0);

    assert!(
        config.port > 0,
        "Port must be positive, got {}",
        config.port
    );
}
```

## Logging

### Use Structured Logging

Use `tracing` for structured, contextual logging with spans:
- Structured logging with key-value pairs (like structlog in Python)
- Spans track operations/requests across function calls
- Better for async code
- Automatic context propagation

### Dependencies

```toml
[dependencies]
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
```

### Basic Setup

```rust
use tracing_subscriber::{fmt, EnvFilter};

fn main() {
    // Development: human-readable with colors
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env().add_directive("debug".parse().unwrap()))
        .with_target(true)
        .with_line_number(true)
        .init();

    run_app();
}
```

### Environment-Specific Configuration

```rust
use tracing_subscriber::{fmt, layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

fn init_tracing() {
    let env = std::env::var("ENVIRONMENT").unwrap_or_else(|_| "development".to_string());

    if env == "production" {
        // Production: JSON format for structured logging
        tracing_subscriber::registry()
            .with(EnvFilter::from_default_env().add_directive("info".parse().unwrap()))
            .with(fmt::layer().json())
            .init();
    } else {
        // Development: human-readable with colors
        tracing_subscriber::fmt()
            .with_env_filter(EnvFilter::from_default_env().add_directive("debug".parse().unwrap()))
            .with_target(true)
            .with_line_number(true)
            .pretty()
            .init();
    }
}

fn main() {
    init_tracing();
    run_app();
}
```

### Log Levels

- **TRACE**: Very detailed, function-level detail
- **DEBUG**: Detailed flow - entry/exit of functions, conditionals, timing
- **INFO**: High-level progress - job started/completed, milestones, metrics
- **WARN**: Unexpected but handled - retries, slow operations, degraded mode
- **ERROR**: Task failed but process continues - single file failed, request error

**Default levels:**
- Development: DEBUG
- Production: INFO

### Simple Logging with Structured Fields

Like Python's structured logging, use key-value pairs:

```rust
use tracing::{info, warn, error};

// Simple logging with structured fields
info!(user_id = user.id, action = "login", "User logged in");

warn!(
    duration_ms = elapsed.as_millis(),
    threshold_ms = 5000,
    "Slow operation detected"
);

error!(
    error = %e,
    file = %path.display(),
    "Failed to read file"
);
```

### Aggregate Metrics at Job Completion

Like Python's job completion logging:

```rust
use tracing::info;
use std::time::Instant;

fn process_batch(items: &[Item]) -> Result<(), Error> {
    let start = Instant::now();
    let mut successful = 0;
    let mut failed = 0;

    for item in items {
        match process_item(item) {
            Ok(_) => successful += 1,
            Err(_) => failed += 1,
        }
    }

    info!(
        total_records = items.len(),
        successful,
        failed,
        duration_seconds = start.elapsed().as_secs_f64(),
        status = if failed == 0 { "success" } else { "partial_success" },
        "Job completed"
    );

    Ok(())
}
```

### Spans - Tracking Context

Spans track operations across function calls, automatically adding context to all logs within:

```rust
use tracing::{info, span, Level};

fn process_order(order_id: &str) {
    // Create span for this operation
    let span = span!(Level::INFO, "process_order", order_id);
    let _enter = span.enter();

    info!("Processing started");  // Automatically includes order_id
    validate_order();
    fulfill_order();
    info!("Processing completed");  // Automatically includes order_id
}
```

### Function Instrumentation with `#[instrument]`

Automatic span creation - similar to Python's decorator pattern:

```rust
use tracing::{info, instrument};

// Automatic span with function arguments
#[instrument]
fn process_data(user_id: u64, data: &str) -> Result<Output, Error> {
    info!("Starting processing");  // Automatically includes user_id, data
    
    let result = transform(data)?;
    
    info!(result_size = result.len(), "Processing complete");
    Ok(result)
}

// Skip large arguments
#[instrument(skip(data))]
fn process_large_data(id: u64, data: &[u8]) -> Result<(), Error> {
    info!(data_size = data.len(), "Processing");
    // data not logged, but id is
    Ok(())
}

// Custom span name
#[instrument(name = "db_query")]
fn fetch_user(id: u64) -> Result<User, Error> {
    // Span named "db_query" instead of "fetch_user"
    Ok(User { id })
}
```

### Manual Span Creation

For more control:

```rust
use tracing::{info, span, Level};

fn handle_request(request_id: &str, user_id: u64) {
    let span = span!(
        Level::INFO,
        "handle_request",
        request_id,
        user_id
    );
    let _enter = span.enter();

    info!("Request received");
    process_request();
    info!("Request completed");
    // All logs automatically include request_id and user_id
}
```

### Nested Spans

Context propagates through function calls:

```rust
use tracing::{info, instrument};

#[instrument]
fn batch_process(items: &[Item]) {
    info!("Batch started");
    
    for item in items {
        process_item(item);  // Creates child span
    }
    
    info!("Batch completed");
}

#[instrument(skip(item), fields(item_id = item.id))]
fn process_item(item: &Item) {
    info!("Item processing started");
    // Logs include both batch span context AND item_id
    validate(item);
    transform(item);
    info!("Item processing completed");
}
```

### Error Logging with Context

Like Python's `log.exception()`, but with span context:

```rust
use tracing::{error, warn, instrument};
use std::path::Path;

#[instrument(skip(path), fields(file = %path.display()))]
fn parse_file(path: &Path) -> Result<Data, Error> {
    match std::fs::read_to_string(path) {
        Ok(contents) => parse_contents(&contents),
        Err(e) => {
            error!(
                error = %e,
                line = 42,
                expected = "header",
                "Failed to read file"
            );
            Err(Error::Io(e))
        }
    }
}
```

### Tracking Errors Through Spans

Spans automatically add context to error logs:

```rust
use tracing::{error, instrument};

#[instrument]
fn process_pipeline(user_id: u64) -> Result<(), Error> {
    fetch_data(user_id)?;  // If error, includes user_id in logs
    transform_data()?;     // If error, includes user_id in logs
    save_results()?;       // If error, includes user_id in logs
    Ok(())
}

#[instrument]
fn fetch_data(user_id: u64) -> Result<Data, Error> {
    database_query(user_id).map_err(|e| {
        error!(error = %e, "Database query failed");
        // Error log automatically includes user_id from parent span
        e
    })
}
```

### Timing with Spans

Spans automatically track duration:

```rust
use tracing::{info, instrument};
use std::time::Instant;

#[instrument]
fn expensive_operation(id: u64) -> Result<(), Error> {
    // Span automatically tracks duration
    perform_work()?;
    Ok(())
    // Duration logged when span ends
}

// Manual timing for specific sections
#[instrument]
fn process_with_timing() {
    let start = Instant::now();
    
    perform_work();
    
    info!(
        duration_ms = start.elapsed().as_millis(),
        "Work completed"
    );
}
```

### Conditional Logging

Use DEBUG for if/else branches:

```rust
use tracing::{debug, info, instrument};

#[instrument]
fn process_request(cached: bool, request: &Request) -> Response {
    if cached {
        debug!("Using cached response");
        return get_cached_response();
    }
    
    debug!("Cache miss, generating response");
    let response = generate_response(request);
    
    info!("Response generated");
    response
}
```

### Never Log Sensitive Data

Do NOT log:
- Passwords, tokens, API keys
- Credentials of any kind
- Personal identifiable information (PII)
- Credit card numbers, SSNs

```rust
use tracing::info;

// ✅ CORRECT - Log user ID, not sensitive data
#[instrument(skip(password))]
fn authenticate(username: &str, password: &str) -> Result<Session, Error> {
    info!(username, "Authentication attempt");
    // password is skipped
    Ok(Session::new())
}

// ❌ INCORRECT - Logs password
#[instrument]
fn authenticate_bad(username: &str, password: &str) -> Result<Session, Error> {
    // password would be logged!
    Ok(Session::new())
}
```

### What to Log

**Always log:**
- Job/process start and completion with aggregate metrics (INFO)
- Errors with full context (ERROR)
- Operation spans for tracking (INFO/DEBUG)

**Use DEBUG for:**
- Function entry/exit (via `#[instrument]`)
- Conditional branches (if/else decisions)
- Detailed operation steps

**Use INFO for:**
- Milestones and completion
- Aggregate metrics

## Error Handling

### Use Result and Option Appropriately

```rust
// ✅ CORRECT - Use Result for operations that can fail
fn read_file(path: &Path) -> Result<String, io::Error> {
    fs::read_to_string(path)
}

// ✅ CORRECT - Use Option for optional values
fn find_user(id: u64) -> Option<User> {
    database.get(id)
}
```

### Use thiserror and anyhow

- **thiserror** for library code and custom error types
- **anyhow** for application code where you propagate errors

### Custom Errors with thiserror

Define domain-specific errors:

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("Config file not found at {path}")]
    NotFound { path: String },

    #[error("Invalid config: {0}")]
    Invalid(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),  // Auto-convert from io::Error
}
```

### Application Errors with anyhow

Add context to errors:

```rust
use anyhow::{Context, Result};

fn load_config(path: &Path) -> Result<Config> {
    let contents = std::fs::read_to_string(path)
        .context(format!("Failed to read config from {}", path.display()))?;

    parse_config(&contents)
        .context("Failed to parse config file")?
}
```

**Context is king** - provide enough information to understand and debug errors.

### Prefer Explicit Matching

Use pattern matching over `?` when you need control:

```rust
use tracing::error;

// Prefer explicit matching for error handling
match parse_config(path) {
    Ok(config) => process(config),
    Err(ConfigError::NotFound { path }) => {
        error!(path, "Config not found");
        return Err(AppError::Setup);
    }
    Err(e) => return Err(e.into()),
}
```

### Panics

Follow ERROR vs CRITICAL logging logic:
- **ERROR**: Task failed, process can continue - return `Err()`
- **CRITICAL**: System failure, cannot continue - `panic!()` is acceptable

**Avoid `unwrap()` and `expect()`** except:
- In tests
- When logically impossible to fail
- Use `expect()` with clear message if unavoidable

```rust
// Only in truly impossible cases
let value = map.get("key").expect("Key must exist - initialized above");
```

## Documentation

### Function Documentation

Document all public functions:

```rust
/// Parses configuration from TOML file.
///
/// Reads the file, parses TOML format, and validates required fields.
/// Falls back to defaults for optional fields.
///
/// # Arguments
/// * `path` - Path to configuration file
///
/// # Returns
/// Parsed and validated configuration object
///
/// # Errors
/// Returns `ConfigError::NotFound` if file doesn't exist.
/// Returns `ConfigError::Invalid` if TOML is malformed.
///
/// # Examples
/// ```
/// use myapp::config::parse_config;
/// use std::path::Path;
///
/// let config = parse_config(Path::new("config.toml"))?;
/// assert_eq!(config.host, "localhost");
/// ```
pub fn parse_config(path: &Path) -> Result<Config, ConfigError> {
    // ...
}
```

### Unsafe Documentation

Always document unsafe blocks:

```rust
/// # Safety
/// Caller must ensure pointer is valid and properly aligned.
/// Buffer must be at least `len` bytes.
pub unsafe fn read_buffer(ptr: *const u8, len: usize) -> Vec<u8> {
    // SAFETY: We trust the caller to provide valid pointer and length
    std::slice::from_raw_parts(ptr, len).to_vec()
}
```

### Module Documentation

Use `//!` for module-level documentation:

```rust
//! Configuration management.
//!
//! This module handles loading, parsing, and validating application
//! configuration from TOML files. Supports global and local config
//! with environment variable overrides.

use std::path::Path;
```

## Ownership and Idioms

### Prefer Borrowing

Use references for reading, mutable references for modifying:

```rust
// Read - use reference
fn read_config(config: &Config) -> String {
    format!("{}:{}", config.host, config.port)
}

// Modify - use mutable reference
fn update_timeout(config: &mut Config, timeout: u32) {
    config.timeout = timeout;
}

// Own - take ownership when consuming
fn serialize_config(config: Config) -> String {
    // config is consumed here
    serde_json::to_string(&config).unwrap()
}
```

Only clone when you truly need independent copies:

```rust
// Clone only when necessary
fn backup_config(config: &Config) -> Config {
    config.clone() // Need independent copy
}
```

### Lifetimes

Let the compiler infer lifetimes. Only add explicit lifetimes when the compiler requires them.

### Iterators vs Loops

Prefer iterator chains when clear:

```rust
// ✅ Idiomatic - clear intent
let sum: i32 = numbers
    .iter()
    .filter(|x| **x % 2 == 0)
    .map(|x| x * 2)
    .sum();
```

Use loops when complex logic makes iterators unclear:

```rust
// ✅ Also fine - complex logic
let mut results = Vec::new();
for item in items {
    if let Some(processed) = complex_processing(item)? {
        if processed.is_valid() {
            results.push(processed);
        }
    }
}
```

### Pattern Matching

Use `if let` for single pattern matches:

```rust
// ✅ Prefer if let for single patterns
if let Some(value) = optional {
    process(value);
}

if let Err(e) = result {
    handle_error(e);
}
```

Use `match` for multiple patterns:

```rust
// ✅ Use match for multiple patterns
match config_result {
    Ok(config) => process(config),
    Err(ConfigError::NotFound { .. }) => use_defaults(),
    Err(e) => return Err(e),
}
```

## Enums for Domain Modeling

Use enums liberally to model domain concepts:

```rust
#[derive(Debug, Clone)]
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Connected { since: SystemTime },
    Failed { error: String, retries: u32 },
}

pub enum OutputFormat {
    Json,
    Yaml,
    Toml,
}
```

**Benefits:**
- Type-safe state representation
- Compiler ensures exhaustive matching
- Can include associated data
- Self-documenting

## CLI Patterns

### Structure with clap

```rust
use clap::{Parser, Subcommand, ValueEnum};

#[derive(Parser)]
#[command(name = "myapp")]
#[command(about = "My CLI application", long_about = None)]
struct Cli {
    /// Verbosity level (can be used multiple times)
    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,

    /// Suppress output
    #[arg(short, long)]
    quiet: bool,

    /// Output format
    #[arg(short, long, value_enum, default_value_t = OutputFormat::Text)]
    output: OutputFormat,

    #[command(subcommand)]
    command: Commands,
}

#[derive(ValueEnum, Clone)]
enum OutputFormat {
    Text,
    Json,
}

#[derive(Subcommand)]
enum Commands {
    /// Process data
    Process {
        /// Input file path
        #[arg(short, long)]
        input: PathBuf,
    },
    /// Validate configuration
    Validate {
        /// Config file path
        #[arg(short, long)]
        config: PathBuf,
    },
}
```

### Output Modes

Support multiple output modes:

```rust
use serde::Serialize;

#[derive(Serialize)]
struct Result {
    status: String,
    items_processed: usize,
}

fn output_result(result: &Result, format: &OutputFormat, quiet: bool) {
    if quiet {
        return;
    }

    match format {
        OutputFormat::Text => {
            println!("Status: {}", result.status);
            println!("Items processed: {}", result.items_processed);
        }
        OutputFormat::Json => {
            println!("{}", serde_json::to_string_pretty(result).unwrap());
        }
    }
}
```

### Error Handling with anyhow

Use anyhow for CLI error handling with exit codes:

```rust
use anyhow::{Context, Result};

fn main() {
    if let Err(err) = run() {
        eprintln!("Error: {err:?}");  // Pretty-print error chain
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Process { input } => {
            let data = std::fs::read_to_string(&input)
                .context(format!("Failed to read input file: {}", input.display()))?;
            
            process_data(&data)
                .context("Data processing failed")?;
            
            Ok(())
        }
        Commands::Validate { config } => {
            validate_config(&config)
                .context(format!("Config validation failed: {}", config.display()))?;
            
            Ok(())
        }
    }
}
```

### Contextual Error Messages

Provide helpful error messages with next steps:

```rust
use anyhow::{bail, Context, Result};

fn validate_config(path: &Path) -> Result<()> {
    if !path.exists() {
        bail!(
            "Config file not found: {}\n\n\
             To create a default config, run:\n  \
             myapp init --config {}",
            path.display(),
            path.display()
        );
    }

    let config = load_config(path)
        .context("Failed to parse config file")?;

    if !config.is_valid() {
        bail!(
            "Invalid configuration\n\n\
             Check the following:\n  \
             - Host must not be empty\n  \
             - Port must be between 1 and 65535"
        );
    }

    Ok(())
}
```

## Configuration Management

### File Format

Use TOML for configuration files.

### Dependencies

```toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
toml = "0.8"
```

### Basic Setup

```rust
use serde::Deserialize;
use std::fs;
use std::path::Path;

#[derive(Deserialize)]
pub struct Config {
    pub database: DatabaseConfig,
    pub server: ServerConfig,
}

#[derive(Deserialize)]
pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub timeout: u32,
}

#[derive(Deserialize)]
pub struct ServerConfig {
    pub port: u16,
    pub workers: usize,
}

pub fn load_config(path: &Path) -> Result<Config, Box<dyn std::error::Error>> {
    let contents = fs::read_to_string(path)?;
    let config: Config = toml::from_str(&contents)?;
    Ok(config)
}
```

### Configuration with Validation

Validate in constructor:

```rust
use serde::Deserialize;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("Invalid port: {0} (must be 1-65535)")]
    InvalidPort(u16),
    
    #[error("Invalid host: cannot be empty")]
    EmptyHost,
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Parse error: {0}")]
    Parse(#[from] toml::de::Error),
}

#[derive(Deserialize)]
pub struct DatabaseConfig {
    host: String,
    port: u16,
    #[serde(default = "default_timeout")]
    timeout: u32,
}

fn default_timeout() -> u32 {
    30
}

impl DatabaseConfig {
    pub fn validate(&self) -> Result<(), ConfigError> {
        if self.host.is_empty() {
            return Err(ConfigError::EmptyHost);
        }
        
        if self.port == 0 {
            return Err(ConfigError::InvalidPort(self.port));
        }
        
        Ok(())
    }
    
    pub fn host(&self) -> &str {
        &self.host
    }
    
    pub fn port(&self) -> u16 {
        self.port
    }
    
    pub fn timeout(&self) -> u32 {
        self.timeout
    }
}

pub fn load_config(path: &Path) -> Result<Config, ConfigError> {
    let contents = fs::read_to_string(path)?;
    let config: Config = toml::from_str(&contents)?;
    
    // Validate all sections
    config.database.validate()?;
    config.server.validate()?;
    
    Ok(config)
}
```

### Configuration Hierarchy

Load from multiple sources:

```rust
use std::env;
use std::path::PathBuf;

pub struct ConfigLoader {
    config: Config,
}

impl ConfigLoader {
    pub fn new() -> Result<Self, ConfigError> {
        // 1. Start with defaults (via serde defaults)
        let mut config = Config::default();
        
        // 2. Load global config if exists
        if let Some(global_path) = Self::global_config_path() {
            if global_path.exists() {
                let global = load_config(&global_path)?;
                config = config.merge(global);
            }
        }
        
        // 3. Load local config if exists
        let local_path = PathBuf::from("config.toml");
        if local_path.exists() {
            let local = load_config(&local_path)?;
            config = config.merge(local);
        }
        
        // 4. Override with environment variables
        config.apply_env_overrides();
        
        // 5. CLI arguments would be applied by caller
        
        Ok(Self { config })
    }
    
    fn global_config_path() -> Option<PathBuf> {
        dirs::config_dir().map(|dir| dir.join("myapp").join("config.toml"))
    }
}

impl Config {
    fn apply_env_overrides(&mut self) {
        if let Ok(host) = env::var("DATABASE_HOST") {
            self.database.host = host;
        }
        if let Ok(port) = env::var("DATABASE_PORT") {
            if let Ok(port) = port.parse() {
                self.database.port = port;
            }
        }
    }
    
    fn merge(self, other: Config) -> Config {
        // Merge logic - other's values override self's
        Config {
            database: other.database,
            server: other.server,
        }
    }
}
```

**Configuration precedence (lowest to highest):**
1. Defaults (in struct definitions)
2. Global config file (`~/.config/myapp/config.toml`)
3. Local config file (`./config.toml`)
4. Environment variables
5. CLI arguments

### Generated Config Files

Self-documenting config files with all options:

```toml
# Database connection settings
[database]
# Database host
# Default: localhost
host = "localhost"

# Database port
# Default: 5432
port = 5432

# Connection timeout in seconds
# Default: 30
timeout = 30

# Server settings
[server]
# Server port
# Default: 8080
port = 8080

# Number of worker threads
# Default: 4
workers = 4
```

### Secrets

Never store secrets in config files. Always use environment variables:

```rust
use std::env;

pub struct Config {
    pub database_url: String,  // From DATABASE_URL env var
    pub api_key: String,       // From API_KEY env var
    // Non-secret config from TOML
    pub timeout: u32,
}

impl Config {
    pub fn from_env_and_file(config_path: &Path) -> Result<Self, ConfigError> {
        // Load non-secret config from file
        let file_config = load_config(config_path)?;
        
        // Load secrets from environment
        let database_url = env::var("DATABASE_URL")
            .map_err(|_| ConfigError::MissingEnvVar("DATABASE_URL"))?;
        let api_key = env::var("API_KEY")
            .map_err(|_| ConfigError::MissingEnvVar("API_KEY"))?;
        
        Ok(Config {
            database_url,
            api_key,
            timeout: file_config.timeout,
        })
    }
}
```

## Benchmarking

### Always Provide Benchmarks

All Rust projects should include performance benchmarks.

### Organization

Use `benches/` directory with criterion:

```
project/
├── benches/
│   └── performance_benchmarks.rs
└── Cargo.toml
```

```toml
# Cargo.toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "performance_benchmarks"
harness = false
```

### What to Benchmark

Focus on performance-critical code:
- Core algorithms
- Hot paths in workflows
- Operations that might be bottlenecks

### Benchmark Groups

Group related benchmarks:

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_parser(c: &mut Criterion) {
    let mut group = c.benchmark_group("parser");

    group.bench_function("parse_json", |b| {
        b.iter(|| parse_json(black_box(JSON_DATA)))
    });

    group.bench_function("parse_yaml", |b| {
        b.iter(|| parse_yaml(black_box(YAML_DATA)))
    });

    group.finish();
}

criterion_group!(benches, bench_parser);
criterion_main!(benches);
```

## Dependencies

### Minimal Dependencies

Only add dependencies when necessary. Prefer standard library when sufficient.

### Version Pinning

Pin major and minor versions, allow patch updates:

```toml
[dependencies]
serde = "1.0"          # Allows 1.0.x patches
thiserror = "1.0"      # Allows 1.0.x patches
anyhow = "1.0"         # Allows 1.0.x patches
```

### Prefer Stability

Update dependencies when needed, not for recency. Stability over latest versions.

### Common Crates

No strong preferences, but clap is good for CLI applications.

## Code Quality

### Before Every Commit

- Code must compile: `cargo build`
- Clippy must pass: `cargo clippy -- -D warnings`
- Code must be formatted: `cargo fmt`
- Tests must pass: `cargo test`

### Best Practices

- Use clippy for lint suggestions
- Enable strict linting in CI
- Use cargo fmt for consistent formatting
- Write idiomatic Rust (prefer iterators over loops when clear)

## Common Tools

- **Build**: cargo
- **Linting**: clippy
- **Formatting**: rustfmt
- **Testing**: cargo test
- **Benchmarking**: criterion
- **Documentation**: cargo doc

## Common Commands

```bash
cargo build            # Build project
cargo build --release  # Build optimized release
cargo test             # Run tests
cargo clippy           # Linting
cargo fmt              # Formatting
cargo doc --open       # Generate and open docs
cargo bench            # Run benchmarks
```

---

**Last Updated**: 2026-04-01
