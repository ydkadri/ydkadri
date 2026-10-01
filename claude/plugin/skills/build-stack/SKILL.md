---
name: build-stack
description: Use this skill whenever asked to build an approved stack of PRs or implement a planned milestone. Builds every PR to ready-for-review with no other checkpoints. Not for planning or for reviewing a single existing PR.
---

# build-stack

Build the approved stack to ready-for-review. The user has approved the plan, so do not stop to ask between PRs. Stop only for a genuine conflict with the plan, and say what it is.

## Before starting

Read `${CLAUDE_PLUGIN_ROOT}/conventions/digests/<language>.md` for the project language (`python` or `rust`). Load the full conventions only when a digest line is unclear.

## For each PR, bottom to top

1. Switch to its branch (`gh stack switch`).
2. Write the tests and the code. Deliver the whole unit: code, tests, docs for any interface change, changelog entry, version bump.
3. Run `just check` until it passes.
4. Run the `pr-prep` skill.
5. Commit. Use `git commit --fixup=<sha>` for later changes to earlier commits.

Then `gh stack rebase` so upper branches carry changes from lower ones.

## Submitting

Submit the whole stack with `gh stack submit` once every PR has passed `pr-prep`. Mark PRs ready. While the user reviews PR 1, keep working upward. When feedback arrives, fix it on that branch with `--fixup` commits and run `gh stack rebase`.

Once a PR is accepted, autosquash each branch (`git rebase -i --autosquash`), then merge with `gh stack merge`.

After the last PR merges, run the `retro` skill.
