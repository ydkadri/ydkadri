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
5. **Targeted re-review.** Run the reviewer again with a brief. It reviews the fixups, not the whole PR. Save the brief next to the report. The brief has four parts:
   - **Previous report.** The path of the last report. The reviewer reads it first and answers each finding with `fixed`, `not fixed` or `fixed differently`.
   - **What changed.** The reviewed tip and the range `<reviewed tip>..HEAD`, all `fixup!` commits. History before the reviewed tip is not rewritten between rounds. For a stack, use `git range-diff <prev-base>..<prev-sha> <base>..HEAD`, which stays correct after a lower PR is restacked. Say so if anything was squashed or changed without review, so the reviewer checks it too.
   - **What I did not change, and why.** One line per finding that was declined or only partly done, so the reviewer does not raise it again unless the reason is wrong.
   - **Scope.** Findings must be caused by the fixups, but they may be anywhere. The reviewer reads whatever it needs to check that unchanged code is not broken (callers, tests that pass for the wrong reason, docs that are now false).

   Repeat until `CLEAR`. A third round on one PR is an escalation: stop and bring the user in (see `build-stack`). When the user is present, report the reviewer's findings to them before making the changes.
6. **Before the squash.** Check each commit still has a purpose. A fixup that restores code an earlier commit deleted leaves two commits that cancel out: drop or cut the earlier one, then check the final tree is identical (`git rev-parse HEAD^{tree}` before and after). Read the message of every commit that was fixed against the final code, because a squash keeps the first message and it may now be false. Reword it.
7. **Output check.** If the PR changes what a program writes, show the rest of the output is unchanged: generate it from the base and from the branch over the same input, and compare them. Each run must prove which version it ran, because an installed package, a virtualenv or a `PYTHONPATH` can make both runs import the same code and report "no difference". Assert it in the comparison script, for example `assert "/tmp/wt-base/" in inspect.getsourcefile(package)` for the base and the branch's own path for the branch. A result that shows no difference where you expected one is a reason to doubt the check.
8. PR description: follow the PR descriptions section of `conventions/full/writing.md`. Name the issues it closes.

## Review log

Run the reviewer through this skill, not by calling the agent directly, or nothing is logged and the `retro` has nothing to tally. Append to `.claude/review-log.md`, which is untracked: make sure it and `.claude/reviews/` are in `.gitignore`, and never commit it or quote it in a PR. The `retro` skill reads it.

- Per finding, real or not: `date | branch | round | ID | file:line | severity | outcome` (`fixed`, `false-positive`, `dissent` or `deferred #issue`).
- Per round: `date | branch | round | base sha | reviewed sha | reviewer start | reviewer end`. The next round's `git range-diff` and the retro's timings use it.
