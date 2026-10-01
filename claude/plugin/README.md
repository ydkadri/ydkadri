# mine

Personal build workflow as a Claude Code plugin: Q&A project setup, stacked PRs via `gh stack`, an adversarial reviewer before every PR, and a retro that feeds back into the conventions.

## Install

```bash
claude plugin marketplace add ydkadri/ydkadri
claude plugin install mine@ydkadri
```

Third-party marketplaces do not auto-update. Pull updates with `claude plugin update mine@ydkadri`. Updates only arrive when `version` in `.claude-plugin/plugin.json` changes. Every PR bumps it.

## Changing it

Edit the source in this repo, never the installed copy under `~/.claude/plugins/cache`. Bump the version in `plugin.json` only. Patch by default, minor when a PR adds a capability (a skill, agent or template), major for breaking changes.
