# Working rules

Always-on rules, injected at session start by the mine plugin. Procedures live in skills; detail lives in conventions.

- Ask clarifying questions one at a time. Say why it matters and give a recommendation. Number them.
- Push back **and stand your ground** when something looks wrong. A few more questions beat the wrong implementation.
- Design the interface before the internals.
- Use British English in docs, comments, commit messages and PR descriptions.
- Ask before destructive, hard-to-reverse or outward-facing actions. Proceed on local, reversible ones.
- Run `just check` before every commit. It enforces the mechanical conventions.
- Deliver features complete: code, tests, docs for any interface change, a changelog entry and a version bump.
- Work in small stacked PRs (`gh stack`). Run the `adversarial-reviewer` agent before submitting any PR.
- Record architectural decisions as ADRs.
- Defer nothing silently. Open a GitHub issue for deferred work.
- At the end of a feature, run the `retro` skill.

Skills: `project-init`, `plan-stack`, `build-stack`, `pr-prep`, `retro`.
