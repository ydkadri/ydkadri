---
name: build-stack
description: Use this skill whenever asked to build an approved stack of PRs or implement a planned milestone. Builds one PR at a time, agent-reviewed, overlapping human review. Not for planning or for reviewing a single existing PR.
---

# build-stack

Build the approved stack one PR at a time. The user has approved the plan, so do not stop to ask between PRs. Stop only for an escalation (below).

## Before starting

Read `${CLAUDE_PLUGIN_ROOT}/conventions/digests/<language>.md` for the project language (`python` or `rust`). Load the full conventions only when a digest line is unclear.

## The loop

The stack starts as draft PRs. For each PR, bottom to top:

1. Switch to its branch (`gh stack switch`). Write the tests, the code and the docs for its unit, mark its ADRs `implemented` (and its index row), add the changelog entry and bump the version one step from the PR below it.
2. Run `just check` until it passes.
3. Run `pr-prep`. The reviewer reviews the draft until it returns `CLEAR`.
4. Mark the PR ready (`gh pr ready`). Ready means the agent has cleared it and the user may review. A ready PR is never returned to draft.
5. Start the next PR straight away. While the user reviews PR N, you build PR N+1 and the reviewer reviews it. Do not wait on the user.
6. Repeat until every PR is ready, reviewed and approved.

Fixes and rebases: use `git commit --fixup=<sha>` for changes to an earlier commit, push the fixups as they are (do not autosquash yet), and run `gh stack rebase` so upper branches carry lower changes.

## Human review

Comments arrive in the dialogue, not as PR replies. Never reply to, resolve or react to PR comments or reviews. Discuss each with the user, then push the agreed fixups. If a comment needs a major rework of the PR, run `pr-prep` again. Otherwise there is no further agent review.

## Finishing

Once every PR is approved and the user says to merge, autosquash from the bottom up, restacking after each branch:

```bash
git switch <lowest-branch>
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash --no-keep-empty --keep-base <trunk>
gh stack rebase --no-trunk
# then the next branch, using the branch below it as the base
```

Check each squash changed no content (`git diff <sha-before> <sha-after>` is empty), then `gh stack push` and `gh stack merge --rebase`. Run the `retro` skill after the last merge.

## When to stop and ask

Bring the user in, with the options and a recommendation, when:

- **A decision is irreversible or outward-facing**: pushing, opening or merging PRs, deleting, publishing. Ask first, unless the plan already authorised it.
- **The builder disagrees with the reviewer**: dispute it once, with evidence (run something where you can). If the reviewer still holds, the user decides. Once they have ruled, log a `dissent` line saying who was right.
- **The plan or an ADR no longer holds**: stop that PR and bring the options. Do not quietly change the design.
- **Conventions conflict** with each other, or with the tooling.
- **Spiral**: the same failure after three attempts, or a third review round on one PR.
- **User-visible behaviour is ambiguous** and the plan does not say.

Do not stop for anything the checklist already settles. When blocked on one PR, stop it, note it, and carry on with work that does not depend on it. Speed to the retro matters more than a perfect stack: defer non-blocking problems as GitHub issues and raise them there.
