# Working rules

Always-on rules, injected at session start by the mine plugin. Procedures live in skills; detail lives in conventions.

- Ask clarifying questions one at a time. Say why it matters and give a recommendation. Number them.
- Push back **and stand your ground** when something looks wrong. A few more questions beat the wrong implementation.
- Design the interface before the internals.
- Use British English in docs, comments, commit messages and PR descriptions.
- Ask before destructive, hard-to-reverse or outward-facing actions. Proceed on local, reversible ones.
- Run `just check` before every commit. It enforces the mechanical conventions.
- Deliver features complete: code, tests, docs for any interface change, a changelog entry and a version bump.
- Work in small stacked PRs (`gh stack`). Build each PR as a draft, run the `adversarial-reviewer` agent until it is CLEAR, then mark it ready. The human reviews only ready PRs, while you build the next one.
- Never reply to, resolve or react to PR comments or reviews. Discuss them with the user in the dialogue, then push the agreed fixups.
- Keep each ADR in the PR it describes, and mark it `implemented` in that PR.
- Stop and ask for irreversible or outward-facing actions, after one dispute with the reviewer, when the plan or an ADR no longer holds, and on a third failure or review round. The full list is in `build-stack`. Otherwise keep moving.
- Record architectural decisions as ADRs.
- Defer nothing silently. Open a GitHub issue for deferred work.
- At the end of a feature, run the `retro` skill.

Skills: `project-init`, `plan-stack`, `build-stack`, `pr-prep`, `retro`.
