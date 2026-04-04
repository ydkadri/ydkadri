# Git Workflow

Git branching, commits, and quality gates.

## Branch Strategy

### Default Branch

**The default branch is `main`** (or `master` in older repositories).

**All new branches should be based on the latest version of main** unless otherwise specified:

```bash
# Start new work - always from latest main
git checkout main
git pull
git checkout -b feature/new-feature

# Only branch from a feature branch if explicitly needed
# (e.g., building on unreleased work)
```

### Branch Naming

Branches should be descriptive and categorical:

- **`feature/description`** - New features or enhancements
- **`fix/description`** - Bug fixes
- **`patch/description`** - Small patches, typos, minor corrections
- **`docs/description`** - Documentation-only changes

Use descriptive names that explain what the branch does, not just ticket numbers.

## Commit History

**Goal**: Clean, logical commits that tell a story.

### During Draft PR Phase

**Fixup commits are ENCOURAGED** - makes incremental review easier:
- "Fix linting", "Address feedback", "Fix typo" commits are fine
- Reviewer can see what changed since last review without re-reading everything
- Allows milestone reviews during implementation

**During draft phase, commits like this are acceptable:**
```
1. Add query infrastructure
2. Fix linting in registry
3. Address feedback: simplify executor
4. Add find-dead-code query
5. Fix typo in query
...
[Then rebase before marking ready]
```

### Before Marking PR Ready (Phase 5)

**Rebase to squash fixups into logical feature units:**
- Each commit = complete, cohesive piece of functionality
- Related changes grouped together (feature + tests + docs)
- Commits tell a clear story
- Reviewers can understand each commit in isolation

**Final commit structure should be logical blocks of work:**
- Each commit is complete and isolated
- Tests pass for each commit
- Code is documented for each commit
- Commit can be understood in isolation
- A complex piece of work may have multiple commits

```
✅ GOOD - After rebase, logical units:
1. Add query infrastructure (registry, executor, formatters)
2. Add find-dead-code query with tests
3. Add remaining queries with tests
4. Add CLI integration
5. Update documentation
6. Bump version: 0.7.0 → 0.7.1
```

### After Code Review

**At milestones during draft PR:**
- Add fixup commits addressing feedback
- Push with context: "Addressed feedback on milestone X: [what changed]"
- Keeps incremental changes visible for next review

**Before marking ready (Phase 5):**
- Rebase to incorporate all feedback into logical commits
- Use `git rebase -i` to squash fixups
- Verify tests pass after rebase
- Push cleaned history

## Pre-Commit and Pre-Push Hooks

**Quality checks are determined during project setup** (see [README.md Step 4](README.md#step-4-pre-commit-and-pre-push-hooks)). The checks below are standard patterns used across projects - customize based on project needs.

### Standard Pre-Commit Checks

Typical checks before local commit:

1. **Format code** - Auto-format to correct style
2. **Linting** - All linting checks pass
3. **Type checking** - Python: mypy/pyright, Rust: type system
4. **Compilation** - Compiled languages must compile
5. **Unit tests** - All unit tests pass
6. **CHANGELOG** - CHANGELOG.md must be updated
7. **Documentation validity** - All docs checked (links work, examples run, instructions accurate)
8. **Secrets scanning** - No API keys, tokens, passwords, or credentials

### Never Commit

- `.env` files (use for Docker environments, but never commit)
- Credential files
- API keys or tokens
- Sensitive configuration
- Data files
- Personal information

### Standard Pre-Push Checks

Typical checks before pushing to remote:

1. **All pre-commit checks** - Everything from pre-commit must pass (implied, don't duplicate)
2. **Build verification** - Project builds successfully
3. **Unit tests + coverage** - 80% coverage preferred (unless explicitly specified otherwise)
4. **Integration tests** - All integration tests pass
5. **Version bump** - Version must be incremented appropriately

## Commit Messages

Keep commit messages clear and informative:

- First line: Brief summary (under 70 characters)
- Blank line
- Detailed explanation if needed (why this change, not what changed)
- Reference issues/PRs if relevant

```
Add JWT authentication for API endpoints

Implement token-based authentication to secure API access.
Users can obtain tokens via /auth/login and include them
in Authorization headers for subsequent requests.

Fixes #123
```

## PR Workflow

1. Create **draft PR** for user journey or interface documentation first
2. After approval, implement changes
3. Create PR with:
   - Clear title (under 70 characters)
   - Summary of changes
   - Test plan
4. Wait for review feedback
5. Rebase to incorporate feedback (don't add fixup commits) and provide concise summary of changes when feedback has been received
6. Mark PR as ready for review

---

**Last Updated**: 2026-03-23
