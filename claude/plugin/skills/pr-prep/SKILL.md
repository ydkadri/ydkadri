---
name: pr-prep
description: Use this skill before marking ready any PR, or when a PR needs a major rework, e.g. "check this before I submit". Runs just check, the docs check and the adversarial reviewer. Not for responding to review comments.
---

# pr-prep

A PR is not marked ready until this passes.

1. Run `just check`. Fix failures.
2. Docs check. If the diff changes an interface, the reference and tutorial docs change in the same PR. If it records a decision, its ADR is in this PR, marked `implemented`. The changelog has an entry and the version is bumped (patch by default, minor when the PR adds a capability, major if it breaks compatibility).
3. **First review.** Run the `adversarial-reviewer` agent on the branch against its base (the branch below it in the stack, or `main`). Save its full report to `.claude/reviews/<branch>-<n>.md` (untracked).
4. **Fix.** Fix every `BLOCK` and `FIX` finding as `--fixup` commits. If you think a finding is wrong, say why with evidence and do not silently skip it. Dispute it once. If it still stands, the user decides, and only then do you log a `dissent` line saying who was right.
5. **Targeted re-review.** Run the reviewer again, telling it: the previous base and reviewed commit (from the review log), the path of its earlier report, the findings that should now be fixed, and any the user has ruled on. It compares only this PR's own commits with `git range-diff <prev-base>..<prev-sha> <base>..HEAD`, which stays correct after a lower PR is restacked, checks those findings are fixed, and checks the new changes introduced no problems. It does not re-review the whole PR. Repeat until `CLEAR`. A third round on one PR is an escalation: stop and bring the user in (see `build-stack`).
6. PR description: two or three sentences per section, a bullet list of changes, the issues it closes. No caveats section.

## Review log

Append to `.claude/review-log.md`, which is untracked: make sure it and `.claude/reviews/` are in `.gitignore`, and never commit it or quote it in a PR. The `retro` skill reads it.

- Per finding, real or not: `date | branch | round | ID | file:line | severity | outcome` (`fixed`, `false-positive`, `dissent` or `deferred #issue`).
- Per round: `date | branch | round | base sha | reviewed sha | reviewer start | reviewer end`. The next round's `git range-diff` and the retro's timings use it.
