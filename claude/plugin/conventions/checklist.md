# Reviewer checklist

Read by the `adversarial-reviewer` agent. Each item has an enforcement level: **M** mechanical (a tool should catch it; flag it if the tool is missing or bypassed), **R** reviewer (judgement, you are the only check), **P** prose (guideline, report only if clearly violated).

Every item has a stable ID (for example `PY-03`). Report each finding with that ID, the file and line, and the convention it breaks. Full conventions are in `conventions/full/`. Work through **Common**, then the section for each language the diff touches.

## Common

### Conventions are enforced

- [ ] **COM-01** **M** `just check` passes. No lint suppression without a reason, and no weakened lint rule, coverage threshold or dependency contract.
- [ ] **COM-02** **R** Every rule in `conventions/full/` that no tool checks is followed in the diff. Check the language sections below.

### Architecture

- [ ] **COM-03** **R** Core has no I/O and no third-party types beyond the allow-list. Ports live in core.
- [ ] **COM-04** **R** Orchestrators contain no business rules (an `if` encoding a decision belongs in core).
- [ ] **COM-05** **R** Only the composition root depends on both core and adapters.
- [ ] **COM-06** **R** Simple stays simple: no layers, indirection or abstraction that the current code does not need.

### Docs and release

- [ ] **COM-07** **R** Any interface change updates the reference and tutorial docs. Decisions have an ADR.
- [ ] **COM-08** **M** CHANGELOG has an entry for the change. The version is bumped as semver in line with the project's version rule.
- [ ] **COM-09** **R** README and docs still match the behaviour. Examples run.

### PR hygiene

- [ ] **COM-10** **R** The PR is one reviewable unit. Commits are logical. No unrelated changes.
- [ ] **COM-11** **R** Deferred work has a GitHub issue. The PR description links the issues it closes.
- [ ] **COM-12** **R** British English in docs, comments and messages.

### Security

- [ ] **COM-13** **M** No secrets, no `.env` committed, no sensitive data in logs.
- [ ] **COM-14** **R** External input is validated at boundaries. Queries are parameterised. No shell command built from input.

## Python

- [ ] **PY-01** **R** Imports are modules, not names (`import abc; abc.ABC`). Idiomatic exceptions allowed: `typing`, `typer`, `__init__.py` re-exports, and well-known framework patterns.
- [ ] **PY-02** **R** Protocols are named with verbs (`ExtractsData`, not `Extractor`).
- [ ] **PY-03** **R** Class members ordered: private helpers, property builders, `__init__`, public methods. Functions defined before use.
- [ ] **PY-04** **R** Data classes are frozen `attrs`, data only. Behaviour lives in regular classes.
- [ ] **PY-05** **R** Enums, not string literals, for states, types and formats.
- [ ] **PY-06** **R** Errors fail fast. Specific exceptions, raised with context. Logged once, as `event_name` plus key-value pairs.
- [ ] **PY-07** **R** Log levels match the convention (DEBUG flow, INFO milestones, WARNING handled, ERROR task failed).
- [ ] **PY-08** **R** Decorators are rare, use `functools.wraps`, and are function-based.
- [ ] **PY-09** **R** Docstrings explain purpose and behaviour, with no usage examples.
- [ ] **PY-10** **R** No `utils.py` or `helpers.py`. Names say what the module does.
- [ ] **PY-11** **R** Tests are grouped in classes, mirror the `src` tree, and separate unit from integration.
- [ ] **PY-12** **R** Test data is inline. Fixtures are for resources, with the narrowest scope that works.
- [ ] **PY-13** **R** Parametrize only where the logic is identical. Test names say what is tested and the expected result.
- [ ] **PY-14** **R** New behaviour, error paths and edge cases are covered, not only the happy path.

## Growing this list

The `retro` skill adds items from the user's PR feedback. Promote an item from R to M when a tool can check it. Add a new language section only when that language has a template.
