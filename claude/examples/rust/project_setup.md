# Rust Project Configuration

Non-obvious configuration snippets for Rust projects using `Cargo.toml`.

## Feature Flags

```toml
[features]
default = []
experimental = ["dep:some-experimental-crate"]

# Example feature that enables multiple dependencies
database = ["sqlx", "tokio/rt-multi-thread"]
```

## Optimization Profiles

```toml
[profile.dev]
opt-level = 0
debug = true

[profile.release]
opt-level = 3
debug = false
lto = true              # Link-time optimization
codegen-units = 1       # Single codegen unit for better optimization
strip = true            # Strip symbols for smaller binary

[profile.bench]
inherits = "release"
```

## Clippy Linting Configuration

```toml
[lints.rust]
unsafe_code = "forbid"
missing_docs = "warn"

[lints.clippy]
all = "warn"
pedantic = "warn"
cargo = "warn"

# Allow some pedantic lints that are too noisy
module_name_repetitions = "allow"
missing_errors_doc = "allow"
```

## Workspace Dependencies

For multi-crate projects, define shared dependencies in the workspace:

```toml
# Workspace Cargo.toml
[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }
anyhow = "1.0"

# Member Cargo.toml
[dependencies]
serde = { workspace = true }
tokio = { workspace = true, features = ["rt-multi-thread"] }
anyhow = { workspace = true }
```

## Benchmark Configuration

```toml
[[bench]]
name = "performance_benchmarks"
harness = false  # Use criterion instead of built-in bencher

[dev-dependencies]
criterion = "0.5"
```
