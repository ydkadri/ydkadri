# Architecture decisions

Copy `template.md` to `NNNN-short-title.md`, using the next number. Number 0000 is reserved for the template.

## States

An ADR is in exactly one of five states, and each move has a date line in the header:

| State | Meaning | Moves to |
|---|---|---|
| `proposed` | Written, not yet agreed | `accepted`, `rejected` |
| `accepted` | Agreed in chat, not built | `implemented`, `superseded` |
| `implemented` | Built in its PR (marked in that PR, before merge) | `superseded` |
| `rejected` | Not adopted | (terminal) |
| `superseded` | Replaced by a later ADR | (terminal) |

"Accepted" means agreed, not built. Add a header line for each move (`**Accepted:** YYYY-MM-DD by Name`, `**Implemented:** YYYY-MM-DD (#PR)`). An ADR agreed in chat before it is written is created as `accepted`: set the status, and add both the `Proposed` and `Accepted` lines with the same date. A rejected ADR records why under `## Rejection`. A superseded ADR gets `**Superseded by:** NNNN`.

## Rules

- **One ADR, one PR.** An ADR describes only the work in its own PR. It is created there as `accepted` (it was agreed in chat before the stack was drafted) and marked `implemented` in that same PR, so a merged PR never leaves its decision open.
- **Decisions that outlive a PR** (a decision several PRs depend on) belong in the first PR that builds on it. Later PRs link to it and do not restate it.
- A PR that changes an earlier decision adds a new ADR and marks the old one `superseded`.
- A tool, `decider`, is being built to manage these states and check them in CI. Until it is published, edit the header by hand.

## Index

Each PR adds a row for the ADR it adds, and updates the status when it marks the ADR `implemented`.

| ADR | Title | Status |
|-----|-------|--------|
