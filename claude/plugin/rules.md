# Working rules

Always-on rules, injected at session start by the mine plugin. Procedures live in skills; detail lives in conventions.

- Ask clarifying questions one at a time. Say why it matters and give a recommendation. Number them.
- Push back **and stand your ground** when something looks wrong. A few more questions beat the wrong implementation.
- Design the interface before the internals.
- Use British English in docs, comments, commit messages and PR descriptions.
- Write for a reader who knows nothing: what and why, in bullets, examples and short statements. Take a position and cut detail they do not need. See `conventions/full/writing.md`.
- Ask before destructive, hard-to-reverse or outward-facing actions. Proceed on local, reversible ones.
- A check against a real resource (a bucket, a cluster, an account) is a throwaway script outside the repo, and you ask before running it.
- Run `just check` before every commit. It enforces the mechanical conventions.
- Deliver features complete: code, tests, docs for any interface change, a changelog entry and a version bump.
- Make each commit atomic: one concern, complete, and passing `just check` on its own. Build a PR as several commits, not one.
- Work in small stacked PRs (`gh stack`). Build each PR as a draft, run the `adversarial-reviewer` agent until it is CLEAR, then mark it ready. The human reviews only ready PRs, while you build the next one.
- Never reply to, resolve or react to PR comments or reviews. Discuss them with the user in the dialogue, then push the agreed fixups.
- Draft each ADR locally in `.claude/adrs/` (untracked). Commit it, marked `implemented`, in the PR that completes its work.
- Stop and ask for irreversible or outward-facing actions, after one dispute with the reviewer, when the plan or an ADR no longer holds, and on a third failure or a third review round that is not CLEAR. The full list is in `build-stack`. Otherwise keep moving.
- Record architectural decisions as ADRs.
- Defer nothing silently. Open a GitHub issue for deferred work.
- Work on at most one feature per session. At a feature's end, run the `retro` skill: it checks nothing lives only in the session, then the user runs `/clear`.

Skills: `project-init`, `plan-stack`, `build-stack`, `pr-prep`, `retro`.
