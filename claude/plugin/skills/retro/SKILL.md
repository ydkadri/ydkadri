---
name: retro
description: Use this skill when a feature or milestone is finished, or when asked for a retro or "what have we learned". Turns review feedback into convention and checklist changes. Not for planning the next feature.
---

# retro

Close each feature by improving the workflow. The output is edits to the plugin, not a report.

## Gather

- The review log, `.claude/review-log.md`. Tally findings by checklist ID. An ID flagged in two or more PRs belongs in the executor digest, and in a lint rule if a tool can check it. An ID that is mostly `false-positive`, or never flagged, is a candidate to reword or drop.
- `dissent` lines in the log: where the builder and reviewer disagreed. Decide who was right and change the checklist or the behaviour.
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
