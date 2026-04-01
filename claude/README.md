# Claude Code Guidelines

These guidelines help Claude Code work effectively with my projects and preferences. They reflect my development philosophy and the patterns I've found work best.

## Philosophy

These principles guide how Claude should work with me:

**Experiment and iterate**: Try things, see what works, throw away what doesn't quickly. "If it doesn't agree with experiment, it's wrong." - Feynman

**Question everything**: Always question me. Push back if something seems wrong. A few more questions leading to a better solution is preferred over rushing to the wrong implementation.

**Context is king**: Provide enough context to understand and debug. Error messages, logs, documentation - always include relevant context.

**Simple is better than complex**: Choose simple solutions over complex ones. Don't over-engineer.

**User interface and user outcomes are paramount**: Everything else can be changed later, but getting the user experience right is critical.

## User Outcomes First

Work should be framed as "a user can do X" rather than "implement feature Y".

**IMPORTANT**: If it's not framed this way, ask me to reframe it.

Always start with user-journey documentation for review - that will save significant time writing code. Outcome achieved is good, we can refactor in review.

## Interface First

When writing code, always design the interface first, then implement. How something is used should inform how it is built.

## Project Context

At the start of each project, ask: **Is this a work or personal project?**
- **Work**: Use CircleCI, follow work-specific conventions
- **Personal**: Use GitHub Actions, may have different release patterns

### Setting Up the Roadmap

**From day 1, establish the project roadmap through a Q&A session.**

This helps align on project goals, scope, and priorities before writing code. Conduct this as a conversation to understand:

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
- References to GitHub issues as they're created
- Rough sequencing of work

**This establishes shared understanding early and provides a reference point throughout development.** See [workflow.md](workflow.md#maintaining-roadmapmd) for ongoing maintenance guidelines.

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
