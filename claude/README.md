# claude

My Claude Code workflow, shipped as the `mine` plugin from the `ydkadri` marketplace.

## Install

```bash
claude plugin marketplace add ydkadri/ydkadri
claude plugin install mine@ydkadri
```

See [plugin/README.md](plugin/README.md) for updating and changing it.

## What is in it

| Part | Where |
|---|---|
| Always-on rules, injected at session start | `plugin/rules.md`, `plugin/hooks/` |
| Lifecycle skills | `plugin/skills/`: `project-init`, `plan-stack`, `build-stack`, `pr-prep`, `retro` |
| Adversarial reviewer | `plugin/agents/adversarial-reviewer.md` |
| Conventions (full, executor digests, reviewer checklist) | `plugin/conventions/` |
| Python project template | `plugin/templates/python/` |

Guides that are not part of the plugin: [tools/password-manager.md](tools/password-manager.md), [tools/claude-code-skills-and-evals.md](tools/claude-code-skills-and-evals.md).
