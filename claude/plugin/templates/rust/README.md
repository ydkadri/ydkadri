# project-name

One-line description.

## Install

```bash
just install
```

## Usage

```bash
cargo run -- Ada
```

Logging is controlled with `RUST_LOG` (default `info`), see `.env.example`.

## Development

```bash
just check
```

Run `just --list` for every task. Unit tests live inline (`#[cfg(test)]`),
integration tests in `tests/integration/`. Coverage must stay at or above 80%
lines.
