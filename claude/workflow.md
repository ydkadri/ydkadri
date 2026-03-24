# Development Workflow

How we work together effectively.

## Question-Asking Protocol (CRITICAL)

When clarification is needed, ask questions **one at a time**:

- **Ask ONE question** - Allow focused, detailed answers
- **Provide context** - Explain why the question matters
- **Offer suggestions** - Include your recommendation if you have one
- **Number questions** - Track progress through decision-making (e.g., "Question 3 of ?")

### Collaborative Problem-Solving

You are always allowed to question me. I may disagree with you and you're welcome to justify yourself or disagree with me. I would rather we had a few more questions that led to a better solution than rush to the wrong implementation.

## User Outcomes Over Code Specs

Work should be framed as **"a user can do X"** rather than "implement feature Y".

If a request is not framed this way, ask me to reframe it as a user outcome.

### User Journey Documentation

Always start with user-journey documentation for my review. This saves significant time:

1. Draft user journey document describing:
   - What the user wants to achieve
   - How they'll use the feature
   - What success looks like
2. Create a **draft PR** with this documentation
3. Wait for my review and feedback
4. Only then implement the code

**Principle**: Outcome achieved is good, we can refactor in review. Getting the user outcome right is more important than perfect code.

## API/Interface First

When writing code, always design the API or interface first, then implement. How something is used is more important than how it's built.

**Design workflow:**
1. Draft interface document describing:
   - The public API/interface (how it will be used)
   - Example usage code
2. Create a **draft PR** with the interface documentation
3. Wait for review and feedback
4. Only then implement internals

## PR Review Workflow

### Always Include PR Link

**When requesting review, always include the PR URL:**
- Include on initial review requests
- Include on re-review requests after addressing feedback
- Makes it easy to jump directly to the PR
- Example: "Ready for review: https://github.com/ydkadri/ydkadri/pull/4"

### Review Work Must Meet Quality Standards

**When addressing PR feedback, apply the same standards as original work:**

Before considering review work complete:
- ✅ Run linting - all checks pass
- ✅ Run tests - all tests pass
- ✅ Check test coverage hasn't dropped
- ✅ Run formatting - code formatted consistently
- ✅ Meet all quality standards

**Never consider review feedback "complete" without meeting these criteria.**

### Git Merge Strategy

**Prefer rebase merges for linear history:**
- Use rebase merge (not merge commits or squash merge)
- Maintains clean, linear commit history
- Each commit in feature branch appears in main history
- Makes git log easy to read and bisect work correctly

## Documentation Requirements

### When to Update Documentation

- **README.md**: Significant user-facing changes, setup changes, new features
- **Interface documentation**: All public APIs and interfaces. Must be kept up to date with code changes.
- **CHANGELOG.md**: Every PR must update the changelog
- **Code comments**: Complex logic, non-obvious decisions, "why" not "what"

### Documentation Validity

All documentation must be checked for validity before commit. This includes:
- Links work
- Code examples run
- Instructions are accurate
- Version numbers are current
- Interface documentation matches actual code (CLI commands, API signatures, function interfaces)

## Communication Style

### Be Direct and Concise

- Lead with the answer or action, not reasoning
- Skip filler words and preamble
- Don't restate what I said, just do it
- Include only what's necessary to understand

### When to Ask Permission

Ask before:
- Destructive operations (deleting files, force-pushing, dropping data)
- Hard-to-reverse operations (git reset --hard, overwriting changes)
- Actions visible to others (pushing code, creating PRs/issues, posting comments)
- Publishing content externally

### When to Just Proceed

Don't ask for permission to:
- Read files or explore code
- Run local, reversible operations
- Format or lint code
- Run tests

---

**Last Updated**: 2026-03-24
