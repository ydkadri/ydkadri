# Git Workflow

Git branching, commits, and quality gates.

## Branch Strategy

Branches should be descriptive and categorical:

- **`feature/description`** - New features or enhancements
- **`fix/description`** - Bug fixes
- **`patch/description`** - Small patches, typos, minor corrections
- **`docs/description`** - Documentation-only changes

Use descriptive names that explain what the branch does, not just ticket numbers.

## Commit History

### Logical Blocks

Commits should be **logical blocks of work**:

- Each commit is complete and isolated
- Tests pass for each commit
- Code is documented for each commit
- Commit can be understood in isolation
- A complex piece of work may have multiple commits

**Not allowed**: "Fix linting", "Format code", "Fix typo" commits. Use `git rebase -i` to squash fixups into logical units.

### Good vs Bad Commits

```
✅ GOOD - Logical feature units:
1. Add user authentication with JWT tokens
2. Add password reset flow and email templates
3. Update documentation for authentication system

❌ BAD - Scattered, fixup commits:
1. Add auth
2. Fix linting
3. Add tests
4. Fix typo
5. Format code
6. Actually fix auth
```

### After Code Review

After receiving review feedback:
- Rebase to incorporate changes into logical commits
- Don't add "address feedback" commits
- Squash fixups appropriately
- Push includes rebase after code review

## Pre-Commit Hooks

Required checks before local commit:

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

## Pre-Push Hooks

Required checks before pushing to remote:

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
