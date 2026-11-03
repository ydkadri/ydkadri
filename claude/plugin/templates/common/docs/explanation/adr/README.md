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

"Accepted" means agreed, not built. Write the header as a bullet list, one field per bullet, because consecutive lines of plain text render as one paragraph. Add a bullet for each move (`- **Accepted:** YYYY-MM-DD by Name`, `- **Implemented:** YYYY-MM-DD (#PR)`). A rejected ADR records why under `## Rejection`. A superseded ADR gets `- **Superseded by:** NNNN`.

## Rules

- **One ADR, one PR.** An ADR lands in the PR that completes the work it describes. For a decision that spans a stack, that is the last PR. It is committed there as `implemented`, so a merged PR never leaves its decision open and the history never holds an ADR for work that is not built. Earlier PRs in the stack state the design choices in their description, under "Design choices to review".
- **Draft it locally.** Write the ADR in `.claude/adrs/<slug>.md` while the work is built. The folder is untracked and in `.gitignore`. Add each date line when the move happens: `Proposed` when it is written, `Accepted` when it is agreed in chat, `Implemented` when the completing PR is ready. The dates are then true. Give it its number only when you commit it: the next free one at that moment, so two drafts cannot collide.
- A PR that changes an earlier decision adds a new ADR and marks the old one `superseded`.
- A tool, `decider`, is being built to manage these states and check them in CI. Until it is published, edit the header by hand.

## Index

Each PR adds a row for the ADR it adds, and updates the status when it marks the ADR `implemented`.

| ADR | Title | Status |
|-----|-------|--------|
