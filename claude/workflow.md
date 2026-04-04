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

## Feature Implementation Workflow

**Goal**: Small increments, fast feedback, fewer review rounds.

Work happens in phases with explicit checkpoints for early alignment.

### Phase 1: Align on Approach

1. Discuss user journey with questions (one at a time)
2. Write user journey document (`docs/user-journeys/NN-feature-name.md`)
   - Define user goals, workflow, and outcomes
   - Include prerequisites, steps, verification, troubleshooting
   - Update `docs/user-journeys/README.md` index

**CHECKPOINT 1**: Push draft PR with user journey doc
- **Request review**: "User journey complete - validating we're solving the right problem"
- User validates: Is this the right problem to solve?

### Phase 2: Design Interface

3. Write interface documentation (`docs/interface/feature-name.md`) if adding public APIs
   - Document public interface (CLI commands, API endpoints, function signatures)
   - Include usage examples showing how it will be used

**CHECKPOINT 2**: Push interface docs to same PR
- **Request review**: "Interface design complete - validating API ergonomics before implementation"
- User validates: Is the interface clear and well-designed?

### Phase 3: Plan Implementation

4. Create implementation plan in ROADMAP.md:
   ```markdown
   ## [Feature Name] - Implementation Plan
   
   **PR Strategy**: Single PR | Multiple smaller PRs
   
   **GitHub Issues**: #XX, #YY (list all issues this work will resolve)
   
   **Commit Structure**:
   1. [Self-contained unit 1] - what and why
   2. [Self-contained unit 2] - what and why
   ...
   
   **Review Milestones**:
   - After Commit X: Why review here? (e.g., "Validate foundation")
   - After Commit Y: Why review here? (e.g., "Before building on this")
   - Final: Ready for merge after version bump
   
   **Technical Approach**:
   - Key architectural decisions
   - Design patterns used
   - Integration points
   ```
   
   **IMPORTANT**: Check ROADMAP.md for any existing GitHub issues related to this feature. List them in the plan so they can be referenced in the PR and closed on merge.

**CHECKPOINT 3**: Push plan to ROADMAP.md
- **Request review**: "Implementation plan complete - agreeing on commit structure and milestones"
- User validates: Agree on granularity, PR strategy, and review points?

### Phase 4: Implement Incrementally

5. Implement according to plan:
   - Write tests first for each unit
   - Implement the functionality
   - Keep commits matching the plan structure
   - **Keep fixup commits during draft phase** - makes incremental review easier

**Push at planned milestones**:
- After completing each milestone from plan
- **Always include context**: "Milestone X complete: [what] - ready for review to [why]"
- Example: "Foundation complete: base classes and registry - ready for review to validate before building queries on top"

**When to push for milestone review:**

✅ Completed a planned commit/unit
✅ Foundation work that later work builds on
✅ Complete feature slice working end-to-end
✅ Before a major direction change needs validation
✅ After significant refactor affecting many files

❌ Not after every single commit (too granular)
❌ Not when stuck on implementation detail (try to solve first)

**PR stays in DRAFT** - Allows fixup commits without breaking review flow

### Phase 5: Finalize

6. Self-validate before asking for final review:
   - Run linting and fix all issues
   - Run tests with coverage and verify coverage passes
   - Check all changes against contributing style guides (if they exist)
   
7. Update documentation:
   - CHANGELOG.md with user-facing changes
   - README.md if features or commands changed
   - Technical docs if architecture changed
   - Review existing docs for accuracy

8. Version bump:
   - Propose version type (patch/minor/major) and get confirmation
   - Update version according to project's version management approach
   - Update "Current Version" in CLAUDE.md if it exists

9. **Rebase to clean commit history**:
   - Squash fixup commits into their parent commits
   - Ensure each commit is self-contained and logical
   - Verify all tests pass after rebase

10. **Verify GitHub issue references**:
    - Check ROADMAP.md implementation plan for listed GitHub issues
    - Add issue references to PR description (e.g., "Closes #33, Resolves #42")
    - Verify issue numbers are correct and still open

11. **Mark PR ready for final review**
    - **Request review**: "Ready for final review - all feedback addressed, tests passing, docs updated"
    - Wait for CI to pass
    - Include PR URL

### Key Principles

- **3 upfront checkpoints** catch issues when they're cheap to fix
- **Milestone reviews during implementation** prevent building on wrong foundation  
- **Draft PR + fixup commits** make incremental review easier
- **Clean history at the end** via rebase before marking ready
- **Explicit review requests** with context help reviewer understand what and why

## Architectural Decision Records (ADRs)

For significant architectural decisions, **create an ADR** to document:
- The context and problem
- Alternatives considered
- Decision made and rationale
- Consequences (both positive and negative)

### When to Create an ADR

Create an ADR for decisions that:
- Affect system architecture or structure
- Introduce new patterns or technologies
- Have long-term implications
- Are difficult or costly to reverse
- Need to be communicated to the team

Examples: choosing a database, defining module boundaries, selecting a framework, establishing error handling patterns.

### ADR Template

Store ADRs in `docs/adr/NNNN-title.md`:

```markdown
# NNNN. [Decision Title]

Date: YYYY-MM-DD

## Status

Accepted | Proposed | Deprecated | Superseded by [ADR-XXXX](XXXX-title.md)

## Context

What is the issue we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- Benefit 1
- Benefit 2

### Negative

- Trade-off 1
- Trade-off 2

## Alternatives Considered

What other options were considered?

### Option 1: [Name]
- Pros: ...
- Cons: ...
- Why rejected: ...
```

Number ADRs sequentially (0001, 0002, etc.) and maintain an index at `docs/adr/README.md`.

## GitHub Issues Integration

Track all work via GitHub issues and reference them throughout the workflow:

### Creating Issues

When work is deferred or new work is identified:
```bash
gh issue create --title "Feature: Export to CSV" \
  --body "User story: As a user, I want to export analysis results to CSV...\n\nAcceptance criteria:..."
```

### Planning with Issues

In Phase 3, list all GitHub issues that the implementation will resolve:
```markdown
## [Feature Name] - Implementation Plan

**GitHub Issues**: #33, #42, #47
```

### Closing Issues

In Phase 5, add issue references to PR description:
```markdown
## Summary
Implements CSV export functionality

## Closes
- Closes #33
- Resolves #42
- Fixes #47
```

GitHub will automatically close these issues when the PR is merged.

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

## Tracking Deferred Work

**When work is deferred, create a GitHub issue immediately.**

If during development or review we decide to defer something (optimizations, refactoring, additional features, tech debt), capture it in a GitHub issue:

```bash
# Create issue via gh CLI
gh issue create --title "Optimize graph traversal performance" \
  --body "Context: During PR #123 we identified that graph traversal could be optimized...\n\nProposed approach:..."
```

**What to include in deferred work issues:**
- Context explaining why it was deferred
- Link to relevant PR or code
- Proposed approach or next steps
- Appropriate labels (enhancement, tech-debt, performance, etc.)

**Why this matters:**
- Prevents work from being forgotten
- Creates discoverable record of technical decisions
- Allows prioritizing deferred work later
- Maintains focus on current PR without losing future improvements

### Maintaining ROADMAP.md

In addition to GitHub issues, maintain a `ROADMAP.md` file in the repository root that provides a high-level view of planned work.

**Structure**:
```markdown
# Roadmap

## In Progress
- Feature: Advanced search (#45, #47)
- Enhancement: Performance optimization (#52)

## Planned - Next Release
- Feature: Export functionality (#38, #41, #43)
- Tech debt: Refactor authentication (#50)

## Future
- Feature: Plugin system (#29)
- Enhancement: Real-time updates (#33)

## Completed
- v0.5.0: Graph storage (shipped 2026-03-26)
- v0.4.0: Status command (shipped 2026-03-23)
```

**Guidelines**:
- Group issues into logical features or themes
- Reference GitHub issue numbers for traceability
- Update as issues move between stages
- Move shipped work to Completed with version and date
- Keep it high-level - detailed discussions belong in issues
- Review and update during release planning

**Why this matters**:
- Provides at-a-glance project direction
- Groups related issues into coherent features
- Makes it easy to see what's coming next
- Helps with release planning and prioritization
- Creates a historical record of project evolution

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

### Language and Spelling

**Use British English spelling and conventions:**
- colour, honour, behaviour (not color, honor, behavior)
- organise, analyse, optimise (not organize, analyze, optimize)
- centre, metre, litre (not center, meter, liter)
- licence (noun), license (verb)
- practise (verb), practice (noun)

This applies to all documentation, code comments, commit messages, and PR descriptions.

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

**Last Updated**: 2026-03-27
