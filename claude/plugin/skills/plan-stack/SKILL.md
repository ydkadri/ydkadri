---
name: plan-stack
description: Use this skill whenever asked to plan a feature or milestone, including in an existing project, e.g. "plan the next version" or "add CSV export". Orients, triages, agrees ADRs in chat, then opens a stack of draft PRs. Not for building an approved stack.
---

# plan-stack

Turn a user outcome into a stack of draft PRs the user can approve before any code is written.

## Step 1: Orient

Before asking anything, read what exists: `CLAUDE.md`, `ROADMAP.md`, the ADR index and open issues. Check `main` passes `just check`. If there is no justfile, or `just check` fails on `main`, stop and say so: the first stack is bringing the project up to standard by hand against the template in `${CLAUDE_PLUGIN_ROOT}/templates/`, or a fix for `main`. Automated adoption is not available yet.

## Step 2: Triage

Size the work before planning it:

- **Small** (a bug fix, a one-file change, no decision to record): one PR, no ADR, no plan stack. Open one draft PR (Step 5) and hand to `build-stack`.
- **Feature** (a new capability, several files or an interface change): continue.
- **Large or unclear** (a new subsystem, or the outcome is still vague): agree the outcome and the cut lines first, and plan only the first milestone.

## Step 3: Outcome and ADRs in chat

Ask one question at a time until the outcome is clear ("a user can do X"). Raise each real architectural decision as a short ADR discussion: context, options, recommendation. Take a position: bring one recommendation, not a menu. Agree them in chat. Write each as a draft in `.claude/adrs/<slug>.md` (untracked, in `.gitignore`), from `${CLAUDE_PLUGIN_ROOT}/templates/common/docs/explanation/adr/template.md` following `conventions/full/writing.md`, with `Proposed` dated when you write it and `Accepted` when the user agrees. A draft does not enter git history until its work is built.

## Step 4: Stack plan

Split the work into small PRs, each one reviewable unit that passes `just check` by itself. For each give a title, what it adds, its ADRs, and its semver bump (patch by default, minor for a new capability, major for breaking changes). For each PR, list the new public names (classes, functions, modules) with a one-line purpose, and say which layer each belongs in. Assign every ADR to the PR that completes the work it describes: the last PR, for a decision that spans several. An ADR never sits in a plan PR of its own. The first PR that changes an interface also carries the reference and tutorial docs. List the issues each PR closes.

## Step 5: Draft stack

Create the branches with `gh stack init` and `gh stack add`. Each PR description states its part of the plan, and the design choices to review. The ADR drafts stay local until `build-stack` commits each one in the PR that completes its work. A branch with no ADR starts from an empty commit, `git commit --allow-empty -m "Start: <title>"`, so it can be opened as a PR. Autosquash drops these later. Submit with `gh stack submit --auto`, which opens the PRs as drafts. Give the user the stack link and wait for approval.

Asking first is required: submitting pushes code and opens PRs. Approval authorises `build-stack` to push the stack's branches and mark PRs ready. It does not authorise merging: wait until the user says to merge.
