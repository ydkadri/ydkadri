# Git Workflow

Git branching, commits, and quality gates.

## Branch Strategy

### Default Branch

**The default branch is `main`** (or `master` in older repositories).

**All new branches should be based on the latest version of main** unless otherwise specified. Branches in a stacked PR series (`gh stack`) each build on the branch below:

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

### Atomic commits

**Each commit is one concern, complete, and passes the checks on its own.** A reviewer reads a PR commit by commit, and `git bisect` needs every commit to build and pass.

- One concern per commit: for example a module with its tests, a rule added to an existing module, a docs section, or an ADR status change. If the message needs "and" to describe two unrelated things, split it.
- Code and its tests can share a commit or the tests can follow it. A commit that changes behaviour must not leave the previous tests failing.
- Build a PR as several commits from the start. Autosquash only folds fixups into the commit they fix. It never splits, so a PR started as one commit stays one commit.
- Check every commit, not only the tip: run `just check` at each commit of the stack (for example `git rebase -x 'just check' main`, or check each commit out in a temporary worktree). A commit that passes only when a later one is applied is not atomic.
- Order commits so each one only needs the ones before it. A new package that a layer contract must know about brings its contract change in the same commit, and a shared export list grows with the modules it exports.
- Splitting history must not change content. Compare the tree before and after (`git rev-parse <branch>^{tree}`): it must be identical.

### During Draft PR Phase

**Fixup commits are ENCOURAGED** - makes incremental review easier:
- Use `git commit --fixup=<commit>` to mark commits for automatic squashing
- Reviewer can see what changed since last review without re-reading everything
- Allows milestone reviews during implementation

**During draft phase, use `--fixup` commits:**
```bash
# Initial work
git commit -m "Add query infrastructure"
git commit -m "Add find-dead-code query"

# Later: fix linting in first commit
git commit --fixup=HEAD~1
# Creates: "fixup! Add query infrastructure"

# Address review feedback on second commit
git commit --fixup=HEAD
# Creates: "fixup! Add find-dead-code query"
```

**Finding the commit to fixup:**
```bash
# Show recent commits
git log --oneline -10

# Fixup into specific commit
git commit --fixup=abc123

# Fixup into most recent commit
git commit --fixup=HEAD

# Fixup into previous commit
git commit --fixup=HEAD~1
```

**During draft phase, history looks like:**
```
1. Add query infrastructure
2. fixup! Add query infrastructure
3. Add find-dead-code query
4. fixup! Add find-dead-code query
5. Address feedback: simplify executor
...
[Then autosquash once every PR is approved]
```

### Before Merging

**Autosquash folds each fixup into the commit it fixes. It does not merge commits together, so the atomic commits stay separate:**
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
- Use `git commit --fixup=<commit>` to address feedback
- Push with context: "Addressed feedback on milestone X: [what changed]"
- Keeps incremental changes visible for next review

**Example addressing review feedback:**
```bash
# Review feedback: "Simplify the executor logic in first commit"

# Find which commit to fix
git log --oneline -5
# abc123 Add CLI integration
# def456 Add find-dead-code query
# ghi789 Add query infrastructure  <- This one needs fixing

# Make changes to executor, then commit
git add src/executor.rs
git commit --fixup=ghi789
# Creates: "fixup! Add query infrastructure"

# Push to show reviewer what changed
git push
```

**Before merging (once every PR is approved):**
- Rebase to incorporate all feedback into logical commits
- Use `git rebase -i --autosquash` to automatically squash fixup commits
- Verify tests pass after rebase
- Push cleaned history

**Autosquash example:**
```bash
# Before: messy history with fixups
git log --oneline
# abc123 fixup! Add query infrastructure
# def456 Add find-dead-code query  
# ghi789 fixup! Add query infrastructure
# jkl012 Add query infrastructure

# Rebase with autosquash
git rebase -i --autosquash main   # for a stacked branch, use the branch below it as the base
# Automatically reorders and marks fixups for squashing
# Just save and exit - no manual work needed

# After: clean history
git log --oneline
# mno345 Add find-dead-code query
# pqr678 Add query infrastructure
```

**Note:** If you have `rebase.autosquash = true` in your gitconfig (recommended), 
you can use `git rebase -i main` and autosquash happens automatically.

## Pre-Commit and Pre-Push Hooks

**Quality checks are determined during project setup** (see the `project-init` skill). The checks below are standard patterns used across projects - customize based on project needs.

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

1. Agree ADRs in chat, then open the stack as draft PRs, each holding only the ADRs it describes. The user approves the plan.
2. Build PR 1 as a draft. The adversarial reviewer reviews it until CLEAR, then it is marked ready.
3. Build PR 2 while the user reviews PR 1 and the reviewer reviews PR 2. Repeat up the stack.
4. Each PR has a clear title (under 70 characters), a terse summary and a test plan.
5. Review comments are discussed in the dialogue, never replied to on GitHub. Agreed changes are pushed as `--fixup` commits.
6. Once every PR is approved and the user says to merge, autosquash from the bottom up (`git rebase -i --autosquash --no-keep-empty --keep-base <base>`, then `gh stack rebase --no-trunk`, then the next branch), check each squash changed no content, and merge the stack with `gh stack merge --rebase`.

### Deferring work in a stack

A later PR in the stack may add scope that was never in an earlier PR. It must not carry the fix for a defect the review already found in an earlier PR's own diff — that fix belongs in the PR it was found in, as a `--fixup` commit, even if a later PR happens to touch the same code. Shipping a known-wrong design in PR N and fixing it in PR N+1 leaves a point in the merged history where the project was knowingly broken.

---

**Last Updated**: 2026-10-16
