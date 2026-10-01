# Rust digest

For the executor. Lints, rustfmt, rustdoc, coverage and `scripts/check-deps.sh` are enforced by `just check`, so run it before every commit and do not restate them here. Full rules: `conventions/full/languages/rust.md`. The reviewer checks the items below.

- Traits are third person verbs: `Parses`, `WritesData`. Std-style traits are exempt. Ports live in core.
- Import types by name, functions through their module (`fs::read_to_string`). No globs.
- `impl` order: private helpers, constructors, public methods. Define before use.
- Module names say purpose. No `utils`, `helpers` or `_internal`. Private by default, `pub(crate)` before `pub`.
- Enums, not strings, for states, formats and kinds.
- Libraries and core use typed `thiserror` errors. `anyhow` only in binaries. Always add context.
- Core has no I/O and no third-party types beyond the allow-list. Orchestrators hold no business `if`. Only the app crate depends on both core and adapters.
- Logging is `tracing` with key-value fields, once per event. Use `#[instrument(skip_all, fields(...))]`. DEBUG flow, INFO milestones, WARN handled, ERROR task failed. Never log secrets.
- Tests: unit inline, integration in `tests/integration/`. Data inline. Fakes implement the real trait, with no mocking crates. Table tests only when the logic is identical. Cover error paths. No `test_` prefix.
- Write `# Errors`, `# Panics` and `# Safety` sections. Examples must compile.
- Each `unsafe` block carries a `// SAFETY:` reason.
- Any interface change updates reference and tutorial docs. Decisions get an ADR.
- Deferred work gets a GitHub issue.
