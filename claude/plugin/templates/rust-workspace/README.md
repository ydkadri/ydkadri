# project-name

One-line description.

## Layout

Ports and adapters, one crate per layer:

| Crate | Role | May depend on |
| --- | --- | --- |
| `project-name-core` | Domain logic and driven ports (traits named with a verb). No I/O. | allow-listed third-party crates only (`scripts/core-allowed-deps.txt`) |
| `project-name-adapters` | Implementations of the core ports. | core |
| `project-name-app` | Composition root and the `project-name` binary. | core, adapters |

`scripts/check-deps.sh` enforces this and runs as part of `just lint`.

## Install

```bash
just install
```

## Usage

```bash
cargo run -p project-name-app -- "My note"
```

Logging is controlled with `RUST_LOG` (default `info`), see `.env.example`.

## Development

```bash
just check
```

Run `just --list` for every task. Unit tests live inline (`#[cfg(test)]`),
integration tests in each crate's `tests/integration/`. Coverage must stay at
or above 80% lines across the workspace.
