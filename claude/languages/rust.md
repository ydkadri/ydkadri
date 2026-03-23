# Rust Style Guide

Rust code style and patterns.

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

### Create Custom Error Types

```rust
#[derive(Debug, thiserror::Error)]
pub enum ParseError {
    #[error("Invalid syntax at line {0}")]
    InvalidSyntax(usize),

    #[error("Unexpected token: {0}")]
    UnexpectedToken(String),
}
```

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

## Documentation

Document public APIs:

```rust
/// Parses a configuration file and returns a Config struct.
///
/// # Arguments
/// * `path` - Path to the configuration file
///
/// # Errors
/// Returns an error if the file cannot be read or parsed.
///
/// # Examples
/// ```
/// let config = parse_config("config.toml")?;
/// ```
pub fn parse_config(path: &Path) -> Result<Config, ConfigError> {
    // ...
}
```

## Testing

Use Rust's built-in test framework:

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

## Error Handling

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
// Prefer explicit matching for error handling
match parse_config(path) {
    Ok(config) => process(config),
    Err(ConfigError::NotFound { path }) => {
        log::error!("config_not_found", path = path);
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

## Code Organization

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

### Enums for Domain Modeling

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
- **Documentation**: cargo doc

## Common Commands

```bash
cargo build            # Build project
cargo test             # Run tests
cargo clippy           # Linting
cargo fmt              # Formatting
cargo doc --open       # Generate and open docs
```

---

**Last Updated**: 2026-03-23
