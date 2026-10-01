# Rust Style Guide

Rust code style and patterns. The project template configures the lints named here.

## Enforcement

| Rule | Enforced by |
|---|---|
| Case conventions | rustc `non_snake_case`, `non_camel_case_types`, `non_upper_case_globals` |
| Formatting | `cargo fmt --all -- --check` |
| No `unwrap`, `expect`, `panic!`, `todo!`, `unimplemented!`, `dbg!` outside tests | clippy `unwrap_used`, `expect_used`, `panic`, `todo`, `unimplemented`, `dbg_macro` (denied) |
| No `println!` or `eprintln!` outside the output module | clippy `print_stdout`, `print_stderr` (denied) |
| No `unsafe` unless a crate opts in with a reason | rustc `unsafe_code = "forbid"`; clippy `undocumented_unsafe_blocks` |
| No `mod.rs` | clippy `mod_module_files` (denied) |
| No glob imports | clippy `wildcard_imports`, `enum_glob_use` (denied) |
| Suppressions carry a reason | clippy `allow_attributes_without_reason` |
| Public API kept minimal | rustc `unreachable_pub` (warn) |
| Public items documented, doc links valid | rustc `missing_docs`; rustdoc `broken_intra_doc_links` under `RUSTDOCFLAGS="-D warnings"` |
| Doc examples compile | `cargo test --doc` |
| Coverage at least 80% | `cargo llvm-cov --workspace --fail-under-lines 80` |
| Crate layering | `scripts/check-deps.sh` (workspace template) |
| Trait naming, import style, impl order, logging content, error layering, enums over strings | Reviewer only |

Warn-level lints fail the build because `lint` runs clippy with `-D warnings`.

## Naming Conventions

- **Structs and enums**: `PascalCase` nouns (`DataParser`, `ConnectionState`)
- **Traits**: `PascalCase` third person present tense verbs (`Parses`, `WritesData`), never `Parser` or `Parse`. Std-style traits (`Display`, `From`, `Iterator`) are exempt.
- **Functions and variables**: `snake_case` describing their outcome. Use common verbs by context: `get_thing`, `read_file`.
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Lifetimes**: `'short_lowercase`

```rust
struct DataParser;                       // noun
trait Parses { fn parse(&self, input: &str) -> Result<Self::Output, ParseError>; type Output; }
const MAX_BUFFER_SIZE: usize = 1024;
fn read_config(path: &Path) -> Result<Config, ConfigError> { /* ... */ }
```

Keep traits focused. A trait with `parse`, `validate`, `serialize` and `save` is four traits.

## Imports

- Import types by name: `use std::path::PathBuf;`
- Call functions through their module: `fs::read_to_string(path)`, not `read_to_string(path)`
- No glob imports, except `use super::*;` in `#[cfg(test)] mod tests`.

## Code Organisation

### Modules

- Module files, never `mod.rs`: `config.rs` plus `config/parse.rs`.
- Organise by purpose, not type. Names say what the module does. No `utils`, `helpers` or `_internal`.
- Private by default. Prefer `pub(crate)` to `pub`. Only expose what the API needs.

```rust
// lib.rs
pub mod config;   // configuration management
pub mod parser;   // parsing logic
mod storage;      // internal
```

### Definition order

Define things before they are used. Order within an `impl` block: private helpers, constructors, public methods.

```rust
impl Configuration {
    fn build_database_url(host: &str, port: u16, db: &str) -> String {
        format!("postgresql://{host}:{port}/{db}")
    }

    pub fn new(host: &str, port: u16, db: &str) -> Self {
        Self { db_url: Self::build_database_url(host, port, db) }
    }

    pub fn connect(&self) -> Result<Connection, ConnectionError> {
        create_connection(&self.db_url)
    }
}
```

### Builder pattern

Use a builder for complex initialisation. `build()` validates and returns `Result`.

```rust
let config = ConfigBuilder::new("localhost".to_owned(), 5432)
    .timeout(60)
    .retries(5)
    .build()?;
```

### Binaries

Keep a library crate and a thin `main.rs` (or `src/bin/<name>.rs`) that parses arguments and calls the library. Several binaries live in `src/bin/`.

### Workspaces

Use a workspace when the application has real boundaries. The layout for ports and adapters is in [architecture.md](../project/architecture.md): `<project>-core`, `<project>-adapters` and `<project>-app`. Share lints and dependency versions through `[workspace.lints]` and `[workspace.dependencies]`, and opt each crate in with `[lints] workspace = true`.

### Features

Features are compile-time and additive. Keep `default` minimal, name features for what they enable (`s3`, `postgres`), avoid feature explosion, and test with `--no-default-features`. Document how to install with a feature (`cargo install mytool --features s3`). Changing features of an installed binary needs `cargo install --force`.

```toml
[dependencies]
aws-sdk-s3 = { version = "1", optional = true }

[features]
default = []
s3 = ["dep:aws-sdk-s3"]
```

```rust
#[cfg(feature = "s3")]
pub mod s3;
```

## Testing

Unit tests are inline. Integration tests are one test binary under `tests/integration/`. Cargo only discovers top-level files in `tests/`, so files nested in `tests/unit/` would never run.

```
src/
├── lib.rs            # #[cfg(test)] mod tests at the bottom of each module
└── parser.rs
tests/
└── integration/
    ├── main.rs       # mod workflows; mod cli;
    └── workflows.rs
```

`just test` runs `--lib --bins` and `--doc`. `just test-integration` runs `--test '*'`. The template ships at least one integration test, because `--test '*'` errors with none.

### Structure

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_valid_input_returns_value() {
        let result = parse("valid input");
        assert_eq!(result.unwrap().value, "expected", "unexpected value");
    }

    #[test]
    fn parse_invalid_input_returns_error() {
        assert!(parse("invalid").is_err(), "invalid input should fail");
    }
}
```

Name tests for what is tested and the expected result, without a `test_` prefix. Include a message in assertions. `unwrap` and `expect` are allowed in tests.

### Table-driven tests

Use a table only when the logic is identical and only the inputs differ.

```rust
#[test]
fn port_validation() {
    let cases = [(0, false, "zero"), (1, true, "min"), (65535, true, "max"), (65536, false, "too large")];
    for (port, valid, name) in cases {
        assert_eq!(validate_port(port).is_ok(), valid, "case: {name}");
    }
}
```

Do not mix behaviours (success, empty, missing file) in one table. Write separate tests.

### Fakes, not mocks

Depend on a trait and give the test a hand-written fake that implements it. No mocking crate.

```rust
pub trait StoresData {
    fn save(&mut self, data: &Data) -> Result<(), StoreError>;
}

pub struct Processor<S: StoresData> { store: S }

#[cfg(test)]
mod tests {
    use super::*;

    struct FakeStore { saved: Vec<Data> }

    impl StoresData for FakeStore {
        fn save(&mut self, data: &Data) -> Result<(), StoreError> {
            self.saved.push(data.clone());
            Ok(())
        }
    }
}
```

### Test data

Data goes inline in the test. Shared helpers are for resources that need setup or teardown (temp directories, databases), not for building sample values.

## Logging

Use `tracing` for structured, contextual logging with key-value fields. Do not use the `log` crate or `println!`.

```toml
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }
```

### Setup

`RUST_LOG` must override the default. Build the filter with a default directive, not `add_directive`, which wins over the environment.

```rust
use tracing_subscriber::{EnvFilter, filter::LevelFilter, fmt::format::FmtSpan};

pub fn init_tracing(json: bool) {
    let filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .from_env_lossy();
    let builder = tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_span_events(FmtSpan::CLOSE) // logs span duration when it closes
        .with_writer(std::io::stderr);    // keep stdout for program output
    if json { builder.json().init() } else { builder.init() }
}
```

Use human-readable output in development and JSON in production. The default level is INFO. Set `RUST_LOG=debug` for development.

### Levels

- **TRACE**: very detailed, function level
- **DEBUG**: detailed flow, branches, timing
- **INFO**: milestones, job start and completion, aggregate metrics
- **WARN**: unexpected but handled (retries, slow operations, degraded mode)
- **ERROR**: a task failed but the process continues

There is no CRITICAL level. An unrecoverable failure is an ERROR followed by a non-zero exit.

### Events and spans

```rust
info!(user_id = user.id, action = "login", "user logged in");
error!(error = %e, file = %path.display(), "failed to read file");
```

Log an event once, where it is handled, with the context needed to debug it. Report aggregates at job completion:

```rust
info!(total_records = items.len(), successful, failed,
      duration_seconds = start.elapsed().as_secs_f64(), "job completed");
```

Use `#[instrument]` to create spans. It records every argument by default, so always use `skip_all` and name the fields you want. Its default level is INFO, so set `level = "debug"` for function-level spans.

```rust
#[instrument(skip_all, level = "debug", fields(order_id = %order.id))]
fn process_order(order: &Order, payment_token: &str) -> Result<(), OrderError> {
    debug!("starting");
    // logs inside carry order_id; the token is never logged
    Ok(())
}
```

Spans add context to nested events automatically. Span durations are logged only when `FmtSpan::CLOSE` is enabled, as above.

### Never log sensitive data

No passwords, tokens, API keys, credentials, PII or payment data. `skip_all` on `#[instrument]` is the default protection.

## Error Handling

- Use `Result` for operations that can fail and `Option` for optional values.
- **Libraries and core**: typed errors with `thiserror`.
- **Binaries**: `anyhow` to propagate and add context.
- Provide enough context to debug: which file, which value, what was expected.

```rust
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("config file not found at {path}")]
    NotFound { path: String },
    #[error("invalid config: {0}")]
    Parse(#[from] toml::de::Error),
    #[error("missing environment variable {0}")]
    MissingEnvVar(&'static str),
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
}

pub fn load_for_app(path: &Path) -> anyhow::Result<Settings> {
    let settings = load_settings(path)
        .with_context(|| format!("failed to load config from {}", path.display()))?;
    Ok(settings)
}
```

Match explicitly when a branch needs different handling, and use `?` to propagate the rest.

### Panics

Return `Err` for a failed task. `panic!`, `unwrap` and `expect` are denied outside tests. For a case that is logically impossible, use `#[expect(clippy::expect_used, reason = "key is set above")]` with a clear message.

## Documentation

Document every public item. Use `//!` for module docs. Include `# Errors`, `# Panics` and `# Safety` sections where they apply. Doc examples are allowed and expected because they compile as doctests.

```rust
/// Loads settings from a TOML file.
///
/// # Errors
///
/// Returns [`ConfigError::NotFound`] if the file does not exist and
/// [`ConfigError::Parse`] if the TOML is malformed.
///
/// # Examples
///
/// ```
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// # let dir = std::env::temp_dir().join("example-doc");
/// # std::fs::create_dir_all(&dir)?;
/// # let path = dir.join("config.toml");
/// # std::fs::write(&path, "host = \"localhost\"")?;
/// let settings = mycrate::load_settings(&path)?;
/// assert_eq!(settings.host, "localhost");
/// # Ok(())
/// # }
/// ```
pub fn load_settings(path: &Path) -> Result<Settings, ConfigError> { /* ... */ }
```

### Unsafe

`unsafe_code` is forbidden by default. A crate that needs it relaxes the lint with a reason, and every `unsafe` block carries a `// SAFETY:` comment. An `unsafe fn` documents its contract under `# Safety`, and its body still needs an `unsafe {}` block in edition 2024.

```rust
/// # Safety
///
/// `ptr` must be valid for reads and properly aligned.
pub unsafe fn read_byte(ptr: *const u8) -> u8 {
    // SAFETY: the caller guarantees `ptr` is valid and aligned.
    unsafe { *ptr }
}
```

## Ownership and Idioms

- Borrow to read (`&T`), borrow mutably to modify (`&mut T`), take ownership to consume. Clone only for a genuinely independent copy.
- Let the compiler infer lifetimes.
- Prefer iterator chains when clear. Use a loop when the logic makes an iterator unclear.
- `if let` for a single pattern, `match` for several.

## Enums for Domain Modelling

Use enums, not strings, for states, formats and kinds. Variants can carry data, and the compiler checks matches are exhaustive.

```rust
pub enum ConnectionState {
    Disconnected,
    Connecting,
    Connected { since: SystemTime },
    Failed { error: String, retries: u32 },
}
```

## CLI Patterns

Use `clap` with derive. Core commands sit on the root, related commands in subcommands. Support `--quiet`, `--verbose` and a `--output json` mode. Exit with code 1 on error and 0 on success, and print errors with their chain (`{err:?}`). Give next steps in error messages when helpful.

`println!` is denied everywhere except one output module, which allows it with a reason:

```rust
// output.rs
#![expect(clippy::print_stdout, reason = "this module is the CLI's output boundary")]

pub fn print_result(result: &Report, format: OutputFormat) { /* println! here */ }
```

## Configuration Management

Use TOML, loaded once at startup into typed structs with `serde`. Validate on load and return `ConfigError`.

Precedence from lowest to highest: defaults in the struct, global config (`~/.config/<app>/config.toml`), local config (`./config.toml`), environment variables, CLI arguments.

Generated config files list every option commented out with its default. Never store secrets in config files. Read them from the environment and return `ConfigError::MissingEnvVar` if unset.

## Benchmarking

Add `criterion` benchmarks in `benches/` for performance-critical paths such as core algorithms and hot loops. Benchmarks are not a template default and do not run on every PR.

```toml
[dev-dependencies]
criterion = "0.8"

[[bench]]
name = "performance_benchmarks"
harness = false
```

## Dependencies

- Add a dependency only when the standard library is not enough.
- A requirement such as `serde = "1.0"` means `^1.0`: any compatible 1.x release. Cargo resolves to the newest allowed, so `clap = "4.0"` resolves to 4.6.x. Commit `Cargo.lock` so builds are reproducible, and build with `--locked` in CI.
- Update dependencies when needed, not for recency. Run `cargo audit` on every PR.
- No strong crate preferences. `clap` for CLIs, `thiserror` and `anyhow` for errors, `tracing` for logging.

## Toolchain

- Edition 2024.
- Pin the toolchain in `rust-toolchain.toml` (stable, with `clippy`, `rustfmt` and `llvm-tools-preview`).
- State a minimum supported Rust version in `Cargo.toml` (`rust-version`) for libraries.

## Code Quality

Run `just check` before every commit. It runs formatting, clippy with `-D warnings` on all targets, rustdoc with warnings denied, the layering script, the type check and tests with the coverage gate. See [structure.md](../project/structure.md) for the recipes.

---

**Last Updated**: 2026-10-01
