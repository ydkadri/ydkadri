---
name: project-init
description: Use this skill whenever asked to start, set up or initialise a new project or repository, e.g. "start a new Python tool" or "set up this repo". Runs a Q&A, then builds from the template. Not for adding features to an existing project.
---

# project-init

Set up a new project through a short Q&A, then generate it from `${CLAUDE_PLUGIN_ROOT}/templates/`.

## Step 0: Existing project

If `CLAUDE.md` exists, read it and ask only what is missing. Otherwise continue.

## Step 1: Q&A

Ask one question at a time, with a recommendation each time. Defaults are in brackets.

1. The user outcome: "a user can do X". Push back if it is framed as a feature.
2. Language [Python]. Only Python has a template so far. For other languages, say so and ask how to proceed.
3. Work or personal [personal]. Work uses CircleCI, personal uses GitHub Actions.
4. Application shape: script, CLI, library or service. Does it have real external boundaries? If so use ports and adapters (`conventions/full/project/architecture.md`), otherwise functional core and imperative shell.
5. Infrastructure: database, Docker, external services.
6. Release: semver [yes], where published, who reviews.
7. Scope: MVP, what is out of scope, rough milestones. Each milestone becomes a version.

## Step 2: Generate

Copy `templates/python/` into the repo and fill in names. Then:

- Write `CLAUDE.md` with the project context, the answers above, and `just` targets. Keep it short. Point at the conventions, do not copy them.
- Write `ROADMAP.md` from the milestones.
- Run `just install` and `just check`. The empty project must pass before any feature work starts.

## Step 3: Hand off

Commit on a branch and use `plan-stack` for the first milestone.
