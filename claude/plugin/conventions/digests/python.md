# Python digest

For the executor. Mechanical rules are enforced by `just check`, so run it before every commit and do not restate them here. Full rules: `conventions/full/languages/python.md`. The reviewer checks the items below.

- Import modules, not names: `import abc; abc.ABC`. Exceptions: `typing`, `typer`, `__init__` re-exports, idiomatic framework imports.
- Protocols are verbs: `ExtractsData`, `LoadsData`. Ports live in core.
- Member order in a class: private helpers, property builders, `__init__`, public methods. Define before use.
- Data classes: frozen `attrs`, data only. Change with `attrs.evolve`.
- Enums, not string literals, for states, types and formats.
- Dispatch on an enum or a union of types with `match`, not an `isinstance` chain, and end it with `case _: assert_never(x)`. Without it a new member is silently unhandled, and a variable the arms assign can be left unbound. An input guard stays an `if`.
- Test an enum by pinning each name to its value (`{m.name: m.value for m in E} == {...}`), not the set of values. A set passes when two values are swapped.
- Fail fast. Never catch `Exception` or `BaseException`, or use a bare `except:`. Name the classes (see the `Raises:` of what the `try` calls), so an unexpected error fails the run. A handler that always re-raises is fine, and so is `raise NewError(...) from e`. Specific exceptions from the package's `exceptions.py`, with context. Log `event_name` plus key-value pairs once, then re-raise.
- Log levels: DEBUG flow, INFO milestones, WARNING handled, ERROR task failed, CRITICAL cannot continue.
- Orchestrators sequence calls and contain no business `if`. Decisions live in core.
- Only the composition root imports both core and adapters.
- Tests: classes, mirror `src`, unit and integration apart. Data inline. Fixtures only for resources, narrowest scope. Parametrize only when logic is identical.
- Before committing a new rule, break it once and see a test fail, then check the break applied. Assert an error's key or whole message, not a prefix.
- Give options and flags values that differ from each other and from the defaults, so a swapped or hard-coded argument fails a test (two booleans: one case with each set alone). Test an input that can fail two ways with both faults at once. When tests move down a layer, keep one in the upper layer that proves an error from below is not swallowed.
- No `utils.py` or `helpers.py`. Docstrings explain purpose, with no usage examples.
- Any interface change updates reference and tutorial docs. They describe the code at this commit: every default, refusal and name they state has a code path and a test, and after a rename or a rule change the old wording is searched for and removed. Decisions get an ADR.
- Deferred work gets a tracked item (an issue, or a task link), small enough for one PR to close. Work across repos gets one item per repo. Record no follow-up the user has not agreed to.
