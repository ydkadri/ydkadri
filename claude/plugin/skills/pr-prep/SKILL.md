---
name: pr-prep
description: Use this skill before submitting or marking ready any PR, e.g. "check this before I submit". Runs just check, the docs check and the adversarial reviewer. Not for responding to review comments.
---

# pr-prep

Nothing is submitted until this passes.

1. Run `just check`. Fix failures.
2. Docs check. If the diff changes an interface, the reference and tutorial docs must change in the same PR. If it records a decision, there must be an ADR. The changelog must have an entry and the version must be bumped (patch by default, minor when the PR adds a capability, major if it breaks compatibility).
3. Run the `adversarial-reviewer` agent on the branch against its base (the branch below it in the stack).
4. Fix every `BLOCK` and `FIX` finding, then run the reviewer again. Repeat until `CLEAR`.
5. PR description: two or three sentences per section, a bullet list of changes, the issues it closes. No caveats section.

Record every finding, real or not, in `.claude/review-log.md` in the project. The file is untracked: make sure `.claude/review-log.md` is in `.gitignore`, and add it if not. Append one line per finding: `date | branch | ID | file:line | severity | outcome`, where outcome is `fixed`, `false-positive` or `deferred #issue`. Never commit the log or quote it in a PR. The `retro` skill reads it.
