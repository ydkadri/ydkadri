# Python digest

For the executor. Mechanical rules are enforced by `just check`, so run it before every commit and do not restate them here. Full rules: `conventions/full/languages/python.md`. The reviewer checks the items below.

- Import modules, not names: `import abc; abc.ABC`. Exceptions: `typing`, `typer`, `__init__` re-exports, idiomatic framework imports.
- Protocols are verbs: `ExtractsData`, `LoadsData`. Ports live in core.
- Member order in a class: private helpers, property builders, `__init__`, public methods. Define before use.
- Data classes: frozen `attrs`, data only. Change with `attrs.evolve`.
- Enums, not string literals, for states, types and formats. Use `match` with `typing.assert_never`.
- Test an enum by pinning each name to its value (`{m.name: m.value for m in E} == {...}`), not the set of values. A set passes when two values are swapped.
- Fail fast. Specific exceptions from the package's `exceptions.py`, with context. Log `event_name` plus key-value pairs once, then re-raise.
- Log levels: DEBUG flow, INFO milestones, WARNING handled, ERROR task failed, CRITICAL cannot continue.
- Orchestrators sequence calls and contain no business `if`. Decisions live in core.
- Only the composition root imports both core and adapters.
- Tests: classes, mirror `src`, unit and integration apart. Data inline. Fixtures only for resources, narrowest scope. Parametrize only when logic is identical.
- Before committing a new rule, break it once and see a test fail, then check the break applied. Assert an error's key or whole message, not a prefix.
- No `utils.py` or `helpers.py`. Docstrings explain purpose, with no usage examples.
- Any interface change updates reference and tutorial docs. They describe the code at this commit: every default, refusal and name they state has a code path and a test, and after a rename or a rule change the old wording is searched for and removed. Decisions get an ADR.
- Deferred work gets a tracked item (an issue, or a task link), small enough for one PR to close. Work across repos gets one item per repo. Record no follow-up the user has not agreed to.
