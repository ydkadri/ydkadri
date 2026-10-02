---
name: project-init
description: Use this skill whenever asked to start, set up or initialise a new project or repository, e.g. "start a new Rust CLI" or "set up this repo". Runs a Q&A, then creates the project. Not for adding a feature to a project that already passes just check.
---

# project-init

Set up a new project through a short Q&A, then create it with the language's own tool and the templates in `${CLAUDE_PLUGIN_ROOT}/templates/`.

## Step 0: Existing project

If `CLAUDE.md` exists, read it and ask only what is missing. Otherwise continue. If the repo already has code, do not scaffold into it: compare it with the template by hand, show the user the differences, and let them decide what to fix first. Making `just check` pass is the first stack of work (`plan-stack`).

## Step 1: Q&A

Ask one question at a time, with a recommendation each time. Defaults are in brackets.

1. The user outcome: "a user can do X". Push back if it is framed as a feature.
2. Language [Python]. Python and Rust have templates. For any other language, say so and ask how to proceed.
3. Work or personal [personal]. Work uses CircleCI, personal uses GitHub Actions.
4. Application shape: script, CLI, library or service. Does it have real external boundaries? If so use ports and adapters (`conventions/full/project/architecture.md`), otherwise functional core and imperative shell. For Rust this picks the template: `templates/rust/` (single crate) or `templates/rust-workspace/` (core, adapters and app crates).
5. Infrastructure: database, Docker, external services.
6. Release: semver [yes], where published, who reviews.
7. Scope: MVP, what is out of scope, rough milestones. Each milestone becomes a version.

## Step 2: Create the project

Use the language's own tool for the skeleton and current versions, then overlay the templates. Create the project directory (or use an empty one) and work inside it. Never overwrite a file the user already has: append to a `.gitignore`, and keep a README that has content.

1. **Surroundings.** If `cargo locate-project --workspace` succeeds inside the target, a Cargo workspace contains it and the generators would edit its root manifest. Stop and ask the user to scaffold outside it. Names are lowercase letters, digits, hyphens and underscores, starting with a letter.
2. **Skeleton.**
   - Python: `uv init --lib --python 3.12 --no-workspace --name <name> .`, then `uv add attrs structlog` and `uv add --dev pytest pytest-cov pytest-mock mypy ruff import-linter pip-audit`.
   - Rust, single crate: `cargo init --lib --name <name>`, then `cargo add anyhow thiserror tracing tracing-subscriber --features tracing-subscriber/env-filter`.
   - Rust workspace: `cargo new --vcs none` for `crates/<name>-core` and `crates/<name>-adapters` (with `--lib`) and `crates/<name>-app`.
3. **Overlay.** Copy `templates/common/` and the language template over the skeleton. The template wins for any file the generator also wrote, except the root `pyproject.toml` or `Cargo.toml`: keep the generated `[project]` or `[package]` block and dependency versions, append the template's tool tables (Python: from `[tool.ruff]` on; Rust: `[workspace]`, `[lints]`, `[workspace.lints.*]`) without duplicating a table, and set `description` to the project's one-line purpose. For Python, copy the contents of `src/project_name/` into the generated `src/<package>/`, not the directory itself. Append the template's `.gitignore` on a new line. For a Rust workspace, copy each template crate's files, its `Cargo.toml` included, into the generated crate of the same role (`core`, `adapters`, `app`), and use the template's root files.
4. **Rename.** Replace `project-name` and `project_name` in contents and in file and directory names, run `just format`, and `grep -r` to prove none remain.
5. **Prove it.** Rust workspace: `cargo generate-lockfile` first. Then `git init` if needed, `git add -A`, and `just install && just check && just build`. Fix every failure before feature work. Commit `Cargo.lock` (Rust) or `uv.lock` (Python).

Then:

- Write `CLAUDE.md` with the project context, the answers above, and `just` targets. Keep it short. Point at the conventions, do not copy them.
- Write `ROADMAP.md` from the milestones.

## Step 3: Hand off

Commit on a branch and use `plan-stack` for the first milestone.
