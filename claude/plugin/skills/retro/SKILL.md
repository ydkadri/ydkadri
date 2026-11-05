---
name: retro
description: Use this skill when a feature or milestone is finished, or when asked for a retro or "what have we learned". Turns review feedback into convention and checklist changes. Not for planning the next feature.
---

# retro

Close each feature by improving the workflow. The output is edits to the plugin, not a report.

## Gather

- The review log, `.claude/review-log.md`, and the saved round reports in `.claude/reviews/`. If there is no log, tally the reports. Tally findings by checklist ID. An ID flagged in two or more PRs belongs in the executor digest, and in a lint rule if a tool can check it. An ID that is mostly `false-positive`, or never flagged, is a candidate to reword or drop.
- The tally of earlier features, `.claude/review-tally.md`. An ID in this feature's log that also appears in an earlier line is a repeat: flag it. Either the last change for it did not hold, or it was judged a one-off then and is worth another look.
- `dissent` lines in the log: where the main session or the builder disputed the reviewer. A line marked `decided by main session` was ruled without the user: check it first. Decide who was right and change the checklist or the behaviour.
- Round counts and reviewer timings per PR: which PRs needed more than two rounds, and why.
- The user's PR comments (`gh pr view --comments`, `gh api` for review threads). These are read, not replied to.
- Anything the user corrected in chat.
- Friction: what was slow, unclear or repeated. Note where the build waited on the user, on a decision, or on a sub-agent.

## Discuss

Group the feedback into themes. For each, ask one question at a time with a recommendation:

- Is this a new convention, a clarification, or a one-off?
- At what level should it be enforced: mechanical (lint, import-linter, hook), reviewer checklist, or prose?
- Can something already on the checklist now be made mechanical?

## Apply

Edit the plugin source in this repo, never the installed copy:

- `conventions/full/` for the rule, `conventions/digests/` only if the executor needs it, `conventions/checklist.md` for the reviewer.
- Template config when a rule became mechanical.
- Bump `version` in `.claude-plugin/plugin.json` (patch for fixes, minor for new rules or skills).
- Then `claude plugin update mine@ydkadri` on each machine.

Open a PR for the change through the normal workflow. Prefer a quick fix now, or a GitHub issue for later, over holding the retro open until everything is settled.

## Close the feature

A session holds at most one feature, and the user clears it after the retro. Anything that lives only in this session is lost, and review history does not carry over: only a one-line tally does. The retro PR belongs to the feature: build it with the `build-stack` loop, with no retro of its own. Its reviews and builder files are written to the plugin repo's `.claude/`, because that is where the retro PR lives. When the feature is in another repo, step 3 deletes them there too.

In this order:

1. **Pre-clear check.** Read the log (and, for a feature in another repo, the retro PR's lines in the plugin repo's log) and the session, and check nothing lives only here:
   - **Decisions.** Every architectural decision is in an ADR, and every other design choice is in its PR's description, not only in chat.
   - **Deferred work.** Every `deferred` and `proposed-deferral` outcome has a GitHub issue the user agreed to. Every finding still `open` is given an outcome, or an issue if the user wants one.
   - **Lessons.** Every correction the user made is in a convention, the checklist or memory.
   - **Facts.** Anything the next feature needs about the project or the user is in the docs, `CLAUDE.md` or memory.
   - **Work.** No branch or worktree has unpushed commits, and no PR of this feature, the retro PR included, is still open.

   Fix what is missing. Merge any open PR once the user says to, as in `build-stack` Finishing.
2. **Tally.** Append one line to `.claude/review-tally.md` (untracked): `<date> | <feature> | <PRs> | <rounds> | <ID>x<count>, ...`. Count only findings whose outcome is not `false-positive`, from both logs. For example `2026-11-04 | token efficiency | #70-#72 | 5 | COM-09x3, COM-16x1`.
3. **Delete, once the user agrees.** Deleted untracked files cannot be recovered, so ask first. Then delete the feature's reports, builder files and log (`.claude/reviews/`, `.claude/builds/` and `.claude/review-log.md`), in the feature's repo and, for the retro PR, in the plugin repo, and the drafts in `.claude/adrs/` that are now committed.
4. **Clear.** Tell the user the feature is closed and to run `/clear`, so the next feature starts in a fresh session.
