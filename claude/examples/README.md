# Code Examples and Patterns

Language-specific and project-specific examples focusing on non-obvious implementation details.

## Structure

- **python/** - Python project examples and patterns
- **rust/** - Rust project examples and patterns
- **docker/** - Docker configuration files
- **justfile** - Task automation recipes (outcome-focused, generic)
- **ci_workflows.md** - GitHub Actions CI/CD patterns

## Python Examples

- **structlog_config.py** - Complete structured logging configuration with contextvars, scrubbing, and environment-specific output
- **project_setup.md** - Snippets for ruff, mypy, pytest configuration in `pyproject.toml`
- **otel_setup.md** - OpenTelemetry SDK initialization and auto-instrumentation
- **otel_custom.md** - Custom spans, metrics, decorators, and context propagation
- **django_structlog.md** - Structlog integration with Django (middleware, views, signals, Celery)
- **dbt_logging.md** - dbt logging patterns with limitations and workarounds

## Rust Examples

- **project_setup.md** - Snippets for Clippy linting, profiles, features in `Cargo.toml`
- **otel_setup.md** - OpenTelemetry tracer and metrics initialization with Tokio
- **otel_custom.md** - Custom tracing spans, metrics, and Axum integration

## Common Tools

- **justfile** - Task automation with outcome-focused recipes (lint, test, docker, git workflow)
- **ci_workflows.md** - GitHub Actions patterns for PR checks and releases

## Docker

- **docker-compose.yml** - Multi-service configuration using .env files
- **Dockerfile** - Multi-stage build example

## Philosophy

These examples focus on:
- Non-obvious implementation details
- Generic patterns that apply across projects
- Configuration snippets rather than full files (except where helpful)
- Real-world integration challenges (e.g., Django/dbt structured logging)
- Consistency between local development and CI (via `just` commands)
