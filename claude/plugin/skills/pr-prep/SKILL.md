---
name: pr-prep
description: Use this skill before marking ready any PR, or when a PR needs a major rework, e.g. "check this before I submit". Confirms the builder's checks, runs the adversarial reviewer and settles its findings. Not for responding to review comments.
---

# pr-prep

A PR is not marked ready until this passes. This is the main session's part. The `builder` agent runs the mechanical checks (`just check` at every commit, mutation checks, docs and version, output comparison, commit hygiene): see `agents/builder.md`. Run on its own, outside `build-stack`, start a `builder` with a check brief (the branch, its base, the PR and the language), so the checks still run.

1. **Builder checks.** The builder's latest summary says every check passed, and the commits match the plan's commit list or the PR description says why they differ. If not, send it back.
2. **First review.** Run the `adversarial-reviewer` agent on the branch against its base (the branch below it in the stack, or `main`). It saves its full report to `.claude/reviews/<branch>-<n>.md` and appends its log block to `.claude/review-log.md` (both untracked, see below), then returns a digest: the verdict, the report path and one line per finding. Work from the digest. Read a finding's evidence in the report only when you need it to rule on or dispute that finding.
3. **Fix.** Settle every `BLOCK` and `FIX` finding with the user, or on your own judgement in delegated mode (see `build-stack`). Send the fixes to the builder as a fix brief, and push the fixups. Then update each finding's `outcome` in the log: `fixed`, `false-positive`, `dissent`, `deferred #issue`, or `proposed-deferral` in delegated mode until the user rules on it. When they do, open the issue and set `deferred #issue`, or send a fix brief and set `fixed`. If you think a finding is wrong, say why with evidence and do not silently skip it. Dispute it once. If it still stands, the user decides, and only then do you log a `dissent` line saying who was right. In delegated mode, you decide, mark the line `decided by main session` so the retro checks it, and report it at the end.
4. **Targeted re-review.** Run the reviewer again with a brief. It reviews the fixups, not the whole PR, and records the brief at the top of its report. The brief has four parts:
   - **Previous report.** The path of the last report. The reviewer reads it first and answers each finding with `fixed`, `not fixed` or `fixed differently`.
   - **What changed.** The reviewed tip and the range `<reviewed tip>..HEAD`, all `fixup!` commits. History before the reviewed tip is not rewritten between rounds. For a stack, use `git range-diff <prev-base>..<prev-sha> <base>..HEAD`, which stays correct after a lower PR is restacked. Say so if anything was squashed or changed without review, so the reviewer checks it too.
   - **What I did not change, and why.** One line per finding that was declined or only partly done, so the reviewer does not raise it again unless the reason is wrong.
   - **Scope.** Findings must be caused by the fixups, but they may be anywhere. The reviewer reads whatever it needs to check that unchanged code is not broken (callers, tests that pass for the wrong reason, docs that are now false).

   Each round's report and log block are saved the same way. Repeat until `CLEAR`. Three rounds is a cap, not a target: if the third is not `CLEAR`, stop and bring the user in (see `build-stack`). When the user is present, report the reviewer's findings to them before sending the fix brief.
5. PR description: use the builder's draft. Check it against the plan and the findings settled, follow the PR descriptions section of `conventions/full/writing.md`, and name the issues it closes.

## Review log

The reviewer writes the log: it appends one block per round in the format below, with every outcome `open`. You set each finding's outcome once it is agreed, editing its line, and add a `dissent` line when one is ruled. Run the reviewer through this skill, not by calling the agent directly, or no outcome is set and the `retro` tallies open findings.

`.claude/review-log.md`, `.claude/reviews/` and `.claude/review-tally.md` are untracked. Make sure all three are in `.gitignore`, and never commit them or quote them in a PR. The `retro` skill reads them, then deletes the log and reports at the end of the feature. `.claude/adrs/` is untracked too: an ADR enters git only when it is copied to `docs/explanation/adr/NNNN-<slug>.md` in the PR that completes its work.

- Per finding, real or not: `date | branch | round | ID | file:line | severity | outcome` (`open`, then `fixed`, `false-positive`, `dissent`, `deferred #issue` or `proposed-deferral`).
- Per round: `date | branch | round | round | base sha | reviewed sha | verdict`. The next round's `git range-diff` uses the shas.
- Add the reviewer's start and end times to the round line if you want the retro to report timings.
