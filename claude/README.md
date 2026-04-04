# Claude Code Guidelines

These guidelines help Claude Code work effectively with my projects and preferences. They reflect my development philosophy and the patterns I've found work best.

## Philosophy

These principles guide how Claude should work with me:

**Experiment and iterate**: Try things, see what works, throw away what doesn't quickly. "If it doesn't agree with experiment, it's wrong." - Feynman

**Question everything**: Always question me. Push back if something seems wrong. A few more questions leading to a better solution is preferred over rushing to the wrong implementation.

**Context is king**: Provide enough context to understand and debug. Error messages, logs, documentation - always include relevant context.

**Simple is better than complex**: Choose simple solutions over complex ones. Don't over-engineer.

**User interface and user outcomes are paramount**: Everything else can be changed later, but getting the user experience right is critical.

## Starting a New Project

**When beginning work on a new repository, follow this structured setup process to establish standards and alignment.**

### Step 1: Check for Existing CLAUDE.md

Before starting setup questions, check if the repository already has a `CLAUDE.md` file:

```bash
# Check if CLAUDE.md exists
ls CLAUDE.md
```

**If CLAUDE.md exists:**
- Read it to understand existing conventions
- Ask if any standards should be updated
- Skip to Step 8 (Roadmap Q&A)

**If CLAUDE.md does not exist:**
- Continue with Step 2

### Step 2: Project Type

Ask: **Is this a work or personal project?**

**Work projects:**
- Use CircleCI for CI/CD
- Follow work-specific conventions
- May have stricter quality requirements
- Consider security and compliance needs

**Personal projects:**
- Use GitHub Actions for CI/CD
- May have different release patterns
- More flexibility in tooling choices

### Step 3: Version and Release Management

Ask: **How will versions and releases be managed?**

Questions to clarify:
- What versioning scheme? (Semantic versioning, CalVer, other?)
- How are versions bumped? (Manual edits, automated script, tool like `cargo-release`)
- Where is version stored? (Single source of truth: Cargo.toml, pyproject.toml, package.json?)
- Are git tags created? (Locally, by CI, not at all?)
- When are tags created? (On merge to main, manual trigger, other?)
- What triggers a release? (Every merge, manual, milestone-based?)
- Where are releases published? (GitHub Releases, crates.io, PyPI, npm, none?)
- What goes in releases? (Binaries, source, changelog, all?)

**Document the answers** and configure accordingly.

### Step 4: Pre-Commit and Pre-Push Hooks

Ask: **What quality checks are required before commit and push?**

**Standard pre-commit checks** (customize based on project):
1. Format code (language-specific formatter)
2. Linting (language-specific linter)
3. Type checking (if applicable: mypy, TypeScript, etc.)
4. Compilation (if compiled language)
5. Unit tests (fast tests only)
6. CHANGELOG updated
7. Documentation validity (links work, examples run)
8. Secrets scanning (no API keys, credentials)

**Standard pre-push checks** (customize based on project):
1. All pre-commit checks
2. Build verification (full build succeeds)
3. Unit tests with coverage (define threshold)
4. Integration tests (if applicable)
5. Version bump (if releasing)

**Document which checks are required** and set up git hooks or use a tool like `pre-commit` or justfile targets.

### Step 5: Testing Standards

Ask: **What testing approach should this project use?**

Questions to clarify:
- **Testing framework?** (pytest, cargo test, jest, other?)
- **Coverage requirements?** (80% preferred, different threshold, none?)
- **Coverage tool?** (pytest-cov, cargo-tarpaulin, nyc, other?)
- **Unit tests?** (Required for all public APIs?)
- **Integration tests?** (Required? How are they organized?)
- **Test organization?** (Mirror source structure, by type, other?)
- **Mocking strategy?** (When to mock vs real implementations?)
- **Benchmarking?** (Required for performance-critical code?)

**Document the testing standards** in CLAUDE.md or contributing docs.

### Step 6: Code Quality Tools

Ask: **What code quality tools should be used?**

Questions to clarify:
- **Linter:** (ruff, clippy, eslint, other?) Configuration preferences?
- **Formatter:** (black/ruff, rustfmt, prettier, other?) Configuration preferences?
- **Type checker:** (mypy, pyright, TypeScript, other?) Strictness level?
- **Additional tools:** (cargo-audit, bandit, other security tools?)

**Document tool choices** and configure them (e.g., `ruff.toml`, `.rustfmt.toml`, `.eslintrc`).

### Step 7: Infrastructure and Dependencies

Ask: **What infrastructure does this project need?**

Questions to clarify:
- **Docker?** (Development environment, production deployment, both?)
- **Database?** (PostgreSQL, Neo4j, SQLite, none?) How managed? (Docker, external service?)
- **External services?** (Redis, message queue, S3, APIs?)
- **Development tools?** (Task runner like just/make, language-specific tools?)
- **Package manager?** (uv, cargo, npm, other?)

**Document infrastructure requirements** and create setup scripts or Docker Compose files.

### Step 8: Documentation Requirements

Ask: **What documentation does this project need?**

Questions to clarify:
- **Architecture Decision Records (ADRs)?** (Required for significant decisions?)
- **API documentation?** (Required? Format: OpenAPI, rustdoc, Sphinx?)
- **User guides?** (README only, or separate docs/?)
- **User journey documentation?** (Required for features?)
- **Interface documentation?** (Required for public APIs?)
- **Contributing guide?** (Needed if open source or team project?)

**Document documentation requirements** and create initial structure (e.g., `docs/adr/`, `docs/user-journeys/`).

### Step 9: Repository Settings

Ask: **What are the repository settings?**

Questions to clarify:
- **Visibility:** Public or private?
- **License:** (MIT, Apache-2.0, GPL, proprietary?)
- **Contributing:** Open to external contributions?
- **Code of conduct:** Required?
- **Issue templates:** Needed?
- **PR templates:** Needed?

**Configure repository settings** on GitHub and add relevant files (LICENSE, CONTRIBUTING.md, etc.).

### Step 10: Establish Project Roadmap

**Conduct a Q&A session to understand project goals and scope.**

This helps align on priorities before writing code:

1. **What problem are we solving?**
   - What's the core user need?
   - What outcomes do users want to achieve?
   - What are we explicitly NOT solving (out of scope)?

2. **What are the key features or capabilities?**
   - What's the MVP (minimum viable product)?
   - What comes after MVP?
   - What's nice-to-have vs essential?

3. **How should we sequence the work?**
   - What needs to be built first (dependencies)?
   - What provides the most value early?
   - What can be deferred?

4. **What are the milestones?**
   - How do we break this into releases?
   - What defines each release (v0.1, v0.2, etc.)?
   - What's the rough timeline?

**After the Q&A, create `ROADMAP.md`** in the repository root with:
- Clear project goals and out-of-scope items
- Grouped features by release/milestone
- Placeholder for GitHub issues (add as they're created)
- Rough sequencing of work

**This establishes shared understanding early and provides a reference point throughout development.** See [workflow.md](workflow.md#maintaining-roadmapmd) for ongoing maintenance guidelines.

### Step 11: Create CLAUDE.md

**Create a `CLAUDE.md` file in the repository root** to document project-specific guidelines.

Include:
- Project context (type, purpose, tech stack)
- Critical rules specific to this project
- Version and release management approach (from Step 3)
- Pre-commit/pre-push requirements (from Step 4)
- Testing standards (from Step 5)
- Code quality tools (from Step 6)
- Quick reference for common commands (justfile targets)
- Links to contributing guides (if they exist)
- Current version number

**This becomes the single source of truth for project-specific conventions.**

### Step 12: Initialize Directory Structure

**Create the project directory structure** based on language and project type:

**Python projects:**
```bash
mkdir -p src/project_name tests/unit tests/integration docs/user-journeys docs/interface
```

**Rust projects:**
```bash
mkdir -p src tests docs/user-journeys docs/interface
```

If ADRs are required:
```bash
mkdir -p docs/adr
```

See [project/structure.md](project/structure.md) for detailed patterns.

### Step 13: Initialize Core Files

**Create initial files:**

1. **CHANGELOG.md:**
   ```markdown
   # Changelog
   
   All notable changes to this project will be documented in this file.
   
   The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
   and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
   
   ## [Unreleased]
   
   ### Added
   - Initial project setup
   ```

2. **justfile** (if using just):
   See [project/structure.md](project/structure.md#justfile-standards) for required targets.

3. **README.md** (if it doesn't exist):
   Basic project description, setup instructions, usage examples.

4. **.gitignore**:
   Language-specific patterns, IDE files, environment files.

5. **ADR template** (if ADRs required):
   Create `docs/adr/template.md` with the ADR structure from [workflow.md](workflow.md#adr-template).

### Setup Complete

**After completing these steps:**
- Project has clear conventions documented
- Development environment is configured
- Quality gates are established
- Work can begin following the [Feature Implementation Workflow](workflow.md#feature-implementation-workflow)

**All setup decisions are now documented** in CLAUDE.md and can be referenced throughout development.

---

## User Outcomes First

Work should be framed as "a user can do X" rather than "implement feature Y".

**IMPORTANT**: If it's not framed this way, ask me to reframe it.

Always start with user-journey documentation for review - that will save significant time writing code. Outcome achieved is good, we can refactor in review.

## Interface First

When writing code, always design the interface first, then implement. How something is used should inform how it is built.

## Files Overview

### Core Workflow
- **[workflow.md](workflow.md)** - How we work together: question-asking protocol, documentation requirements, collaboration style
- **[git.md](git.md)** - Git workflow: branching, commits, PRs, pre-commit/pre-push hooks

### Language Style Guides (`languages/`)
- **[python.md](languages/python.md)** - Python code style: imports, protocols, organization, quality standards
- **[rust.md](languages/rust.md)** - Rust code style: naming, error handling, traits, idioms, benchmarks
- **[sql.md](languages/sql.md)** - SQL code style: queries, naming, formatting

### Project Organization (`project/`)
- **[structure.md](project/structure.md)** - Project layout: justfiles, directory structure, package managers
- **[docker.md](project/docker.md)** - Docker patterns: multi-stage builds, compose, development workflows
- **[ci.md](project/ci.md)** - CI/CD: GitHub Actions, CircleCI, release pipelines

---

**Last Updated**: 2026-04-01
