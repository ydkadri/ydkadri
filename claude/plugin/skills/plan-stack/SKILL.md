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

Ask one question at a time until the outcome is clear ("a user can do X"). Raise each real architectural decision as a short ADR discussion: context, options, recommendation. Agree them in chat. Nothing is written to a file yet.

## Step 4: Stack plan

Split the work into small PRs, each one reviewable unit that passes `just check` by itself. For each give a title, what it adds, its ADRs, and its semver bump (patch by default, minor for a new capability, major for breaking changes). Assign every ADR to the one PR it describes. A decision several PRs depend on goes in the first PR that builds on it. An ADR never sits in a plan PR of its own. The first PR that changes an interface also carries the reference and tutorial docs. List the issues each PR closes.

## Step 5: Draft stack

Create the branches with `gh stack init` and `gh stack add`. Each branch holds the ADRs assigned to it (written from `${CLAUDE_PLUGIN_ROOT}/templates/common/docs/explanation/adr/template.md`, status `accepted`, with a row added to the ADR index) and a PR description stating its part of the plan. A branch with no ADR starts from an empty commit, `git commit --allow-empty -m "Start: <title>"`, so it can be opened as a PR. Autosquash drops these later. Submit with `gh stack submit --auto`, which opens the PRs as drafts. Give the user the stack link and wait for approval.

Asking first is required: submitting pushes code and opens PRs. Approval authorises `build-stack` to push the stack's branches and mark PRs ready. It does not authorise merging: wait until the user says to merge.
