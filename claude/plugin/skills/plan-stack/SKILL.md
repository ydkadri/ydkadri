---
name: plan-stack
description: Use this skill whenever asked to plan a feature or milestone, e.g. "plan the next version" or "break this into PRs". Agrees ADRs in chat, then opens a stack of draft PRs. Not for building the stack once it is approved.
---

# plan-stack

Turn a user outcome into a stack of draft PRs the user can approve before any code is written.

## Step 1: Outcome and ADRs in chat

Ask one question at a time until the outcome is clear ("a user can do X"). Raise each real architectural decision as a short ADR discussion: context, options, recommendation. Write agreed decisions to `docs/explanation/adr/NNNN-title.md` using `${CLAUDE_PLUGIN_ROOT}/templates/python/docs/explanation/adr/template.md`.

## Step 2: Stack plan

Split the work into small PRs, each one reviewable unit that passes `just check` by itself. For each give a title, what it adds, and its semver bump (patch by default, minor for a new capability, major for breaking changes). The first PR that changes an interface also carries the reference and tutorial docs. Check `ROADMAP.md` and open issues, and list those each PR closes.

## Step 3: Draft stack

Create the branches with `gh stack init` and `gh stack add`. Each contains only its ADRs and a PR description stating the plan. Submit with `gh stack submit` as drafts. Give the user the stack link and wait for approval.

Asking first is required: submitting pushes code and opens PRs.
