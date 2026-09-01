# Claude Code Skills, Plugins, and Evals

Complete guide to authoring Claude Code plugins/skills and building an eval suite (via `inspect_ai`/`inspect_swe`) to shrink them safely. Learned from building the `kds` plugin (`share-change-data-feed`, `add-voice-file-shares`) in `kraken-claude-plugins`.

## What is a Plugin/Skill?

A **plugin** is a directory (`plugins/<namespace>/<plugin-name>/`) containing one or more **skills** — reusable, on-demand procedures Claude Code can invoke mid-conversation via the `Skill` tool. Each skill is a single `SKILL.md` file with YAML frontmatter plus optional bundled `scripts/` and `templates/`.

```
plugins/<namespace>/<plugin-name>/
├── plugin.json               # name, version, description
├── .claude-plugin -> .       # symlink so Claude Code discovers it
├── .cursor-plugin -> .       # symlink so Cursor discovers it
└── skills/
    └── <skill-name>/
        ├── SKILL.md
        ├── scripts/           # bundled Python helpers (optional)
        └── templates/         # bundled config/code snippets (optional)
```

Plugins are registered in the repo-root `marketplace.json`. Bump `plugin.json`'s version (patch for fixes, minor for new skills/features) and keep it in sync with `marketplace.json` — a version-mismatch check runs in CI.

## SKILL.md Anatomy

```markdown
---
name: my-skill
description: Use this skill whenever asked to do X, however that's phrased — e.g. "do X for <thing>" or "set up X". Not for Y (out of scope).
---

# my-skill

One-paragraph summary of what this wires up and why it's non-trivial.

## Arguments
...

## Step 0: ...
## Step 1: ...
```

**The description is the trigger.** It's the only thing the model sees when deciding whether to invoke the skill — get it wrong and the skill either never fires or fires on the wrong prompts. Conventions that measurably improved trigger reliability:
- Lead with **"Use this skill when/whenever asked to..."**, not just a bare description of what the skill does — an imperative "use this when" phrasing reads more like a dispatch rule to the model.
- Give 1-2 concrete example phrasings ("e.g. ...").
- End with an explicit **"Not for..."** exclusion clause for the closest look-alike task (a sibling skill, a troubleshooting variant, a read-only query) — this measurably cuts false-positive triggers.
- **Never use a bare, unescaped colon inside the unquoted YAML scalar.** It silently breaks frontmatter parsing. Rephrase around it or quote the whole description.
- Must be 25-350 chars (enforced by `scripts/lint_skill_descriptions.py`).

Reference bundled files with the full `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/scripts/<file>` path every time — never a bare relative path or an invented shorthand; `${CLAUDE_PLUGIN_ROOT}` is substituted by Claude Code at mount time.

## Bundled Scripts and Templates

Extract every **mechanical, deterministic** step (path resolution, API calls, git plumbing, boilerplate config edits) into a bundled Python script or a template file. This is the single biggest lever for shrinking `SKILL.md` — prose describing *how* to do something can become one line saying *"run this script"*.

- No shebang, not executable — invoked explicitly as `python3 ${CLAUDE_PLUGIN_ROOT}/skills/<skill>/scripts/<script>.py <args>`.
- Print a single-line JSON object on success; raise a custom exception with an actionable message and exit non-zero on failure (Claude Code surfaces the traceback/message directly, so make it self-explanatory rather than leaving `SKILL.md` to explain the failure mode).
- **No cross-skill script-sharing convention exists.** Each skill gets its own copy of even fully-generic helpers (e.g. a "branch, commit, push, open PR" script reused verbatim across skills). This is deliberate, not an oversight — skills are meant to be self-contained.
- **Naming collision trap**: if two skills' `scripts/` directories both contain a same-named file (e.g. two `open_pr.py`), whole-repo `mypy .` — which is exactly how CI invokes it — fails with `Duplicate module named "..."`. Skill directories are kebab-case, which aren't valid Python identifiers, so the usual `__init__.py`/`--explicit-package-bases` namespace-package fixes don't work here. Cheapest real fix: give each skill's copy a distinct filename.
- Templates hold config/code blocks that need to be filled in with per-invocation values (HCL blocks, YAML batches) — bake every "gotcha" comment (naming formulas, ordering requirements, known platform bugs) directly into the template file as a comment, so it survives even if `SKILL.md` around it gets trimmed further later.

## Testing Bundled Scripts

Mirror `tests/plugins/<namespace>/<plugin>/<skill_underscored>/test_<script>.py`:

```python
import importlib.util
from pathlib import Path

_SCRIPT = Path(__file__).resolve().parents[N] / "plugins/.../scripts/my_script.py"
_spec = importlib.util.spec_from_file_location("my_script", _SCRIPT)
assert _spec is not None
assert _spec.loader is not None
my_script = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(my_script)
```

Load the script module directly by path (it's never imported as a real package). Mock the subprocess-calling boundary (`monkeypatch.setattr(my_script, "run_thing", fake)`) for pure orchestration/decision-logic tests. For git-plumbing scripts (branch/commit/push/PR), build a real throwaway local repo + bare remote in `tmp_path` and only monkeypatch the final `gh pr create` call — exercising the real git commands catches more than mocking git entirely.

## Evals: Triggers, Execution, Outcomes

Built with `inspect_ai`/`inspect_swe`, living in `evals/<namespace>/<plugin>/<skill_underscored>/{triggers,execution,outcomes}/`. Three categories, each targeting a different failure mode:

| Category | What it tests | How | Determinism |
|---|---|---|---|
| **Triggers** | Does the skill fire on the right prompts and stay dormant on look-alikes? | Real Claude Code CLI in a Docker sandbox (`inspect_swe.claude_code()`), skill mounted via `mountable_skill_dir()`. Scorer checks structured `tool_calls` for a `Skill` call, not string-matching. | Noisy — see below. |
| **Execution** | Do the documented guardrails hold (ask-don't-guess, pause-and-confirm, flag-don't-fabricate)? | Same sandbox, synthetic git-repo fixture built via `Sample.setup`, deterministic scorer inspecting tool calls + final text. | Mostly deterministic, but not immune to model-behavior noise (see below). |
| **Outcomes** | Is a given final report faithful to what actually happened? | **Replay solver** — inject a canned final message, no model call, no sandbox. | Fully deterministic. |

### Triggers eval gotcha: the "Explore" subagent

Claude Code has a built-in read-only "Explore" subagent. When `Bash` is disallowed in the eval (standard practice, to keep triggers evals fast — the trigger decision happens on turn one, before any real work), the model sometimes delegates ambiguous business-phrased prompts to Explore instead of invoking `Skill` directly. This reads as a trigger failure but is actually a routing quirk, not a bad description. Diagnose by comparing failure patterns against a skill with a known-reliable trigger — if the pattern (Explore invoked instead of Skill, correlated with all failures) doesn't show up there, it confirms this specific skill's description phrasing, not generic sandbox flakiness. Fix via description rewording (see above), not by allowing `Bash` in the eval.

### Noise is real — establish a baseline before judging any trim

Both `triggers`-positives and, less obviously, `execution` guardrail checks are **inherently noisy even with zero content changes** — a live model doesn't behave identically run to run. Before trimming anything:

1. Run the *existing, unchanged* eval suite several times (`--epochs N` or repeated `--limit` runs) to establish an empirical noise band.
2. Set thresholds accordingly:
   - **Hard gates (must be 100%, no exceptions)**: `outcomes`, `triggers`-negatives, and — once you've confirmed the fixture is actually well-formed — most `execution` guardrails.
   - **Noise-band judgment**: `triggers`-positives typically settle around ~50-85% depending on prompt ambiguity; some `execution` guardrails can be similarly noisy for reasons unrelated to skill content (see cwd-exploration example below). Only treat a drop as a regression if it's sustained and outside the established band — always inspect the actual transcript, don't trust an aggregate percentage alone.
3. After every `SKILL.md` edit, re-run and compare against the *baseline*, not against a naive 100% expectation.

### Before trusting a scorer's verdict, read the transcript

A scorer failure is not automatically a skill regression. Two real examples from this work:
- A scorer required a literal `"?"` in the final message to count as "asked for missing info" — a correctly-behaved agent phrased its ask imperatively ("Please share the table list") with no question mark and got marked wrong. The skill was fine; the scorer's string-matching was too brittle. Fix the scorer, add a regression test, don't touch the skill.
- An execution fixture was missing a directory the bundled script hard-stops on — the agent correctly stopped, but on the *wrong* documented hard-stop (a coincidental error unrelated to the guardrail the sample was meant to exercise). The fixture was silently not testing what its own docstring claimed. Fix the fixture.

`inspect_ai.log.read_eval_log(path)` and iterating `log.samples[i].messages` is the fastest way to inspect exactly what tool calls and final text a sample produced.

## Running Evals

```bash
# Local credentials: add a .env with a LiteLLM key for live model-backed runs
uv run --env-file .env inspect eval evals/.../eval.py                      # full run
uv run --env-file .env inspect eval evals/.../eval.py --limit 5            # first N samples
uv run --env-file .env inspect eval "path/eval.py@task_name" --epochs 6    # repeat for noise band
uv run --env-file .env inspect eval evals/.../outcomes/eval.py             # cheap: no Docker/model needed
```

Docker must be running for `triggers`/`execution` (they use the `aisiuk/inspect-tool-support` sandbox image — first pull is slow, subsequent runs are fast). `outcomes` needs neither Docker nor a model.

## The Trim Loop

Once scripts/templates extraction has done the bulk of the size reduction, loop:

1. **Update skill** — cut one piece of now-redundant or verbose prose (often: detail already covered by a bundled script's own error message, or a parenthetical aside that repeats what's stated elsewhere).
2. **Run evals** — outcomes + execution + a modest triggers sample.
3. **Compare against baseline/hard gates.** If a hard gate drops, or a noise-band metric drops *and stays down* across a re-run, revert that specific change — it's the final version. Otherwise keep going.
4. Full repo quality gate before considering it done: `ruff check`, `ruff format --check`, `mypy .` (whole-repo, matches CI — not the Makefile's git-diff-scoped shortcut, which can miss cross-file issues like the `mypy` duplicate-module collision above), `pytest`, plus `scripts/lint_plugin_structure.py` and the description linter.

In practice this converges fast — two trim iterations after the scripts/templates extraction is usually the practical floor; further cuts start eating into load-bearing gotchas/gates rather than genuine fluff.

## Known Gotchas Reference

| Symptom | Cause | Fix |
|---|---|---|
| YAML frontmatter fails to parse | Unescaped colon in an unquoted scalar description | Rephrase around the colon, or quote the whole string |
| `ruff format` turns `except (A, B):` into invalid `except A, B:` | Real bug in ruff 0.16.1 | Name the exception tuple as a module-level constant, `except CONST_NAME:` |
| `mypy .` fails with `Duplicate module named "..."` | Two skills' `scripts/` dirs both have a same-named file, no packaging exists, and skill dirs are kebab-case (not valid Python identifiers, so `__init__.py`/namespace-package fixes can't disambiguate) | Rename one copy to a distinct filename |
| Triggers eval flips a previously-reliable trigger to "Explore" tool calls instead of `Skill` | Claude Code's built-in Explore subagent intercepting ambiguous prompts when `Bash` is disallowed in the eval | Reword the description (explicit "not for..." clause); confirm via transcript inspection, not just the aggregate score |
| Execution/outcomes scorer fails on an apparently-correct transcript | Scorer logic too brittle (e.g. string-matching on `"?"`) or fixture missing a setup file, masking the intended guardrail | Read the transcript before reverting anything; fix the scorer/fixture, not the skill |

## Reference

### Quick Commands

| Command | Purpose |
|---|---|
| `python3 scripts/lint_plugin_structure.py` | Validate plugin.json/marketplace.json/symlinks, version sync |
| `echo "<path/to/SKILL.md>" \| python3 scripts/lint_skill_descriptions.py` | Validate one or more skill descriptions (reads paths from stdin or args) |
| `uv run ruff check . && uv run ruff format --check .` | Lint + format check, whole repo |
| `uv run mypy .` | Whole-repo type check — matches CI exactly |
| `uv run pytest` | Full test suite |
| `uv run --env-file .env inspect eval <path>` | Run an eval task/suite |

### New Skill Checklist

1. `plugin.json` + symlinks (if new plugin) + `marketplace.json` entry.
2. `SKILL.md` with a trigger-tuned description and step-by-step body.
3. Extract mechanical steps into `scripts/` + `templates/`, referenced via full `${CLAUDE_PLUGIN_ROOT}` paths.
4. Unit tests for every bundled script.
5. `evals/.../{triggers,execution,outcomes}/` — build execution/outcomes fixtures against the *scripts*, not prose.
6. Establish a noise baseline (repeat runs of the as-written skill) before trimming further.
7. Trim loop against the baseline; full quality gate; commit.

---

**Last Updated**: 2026-09-01
