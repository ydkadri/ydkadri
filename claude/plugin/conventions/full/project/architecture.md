# Application Architecture

How application code is structured internally - the layers within `src/`, as distinct from the project-level layout in [structure.md](structure.md).

## Default: Ports & Adapters (Hexagonal)

The default shape for anything with real external boundaries (storage, external services, more than one way to invoke the app) is hexagonal architecture / ports & adapters.

### When to Reach for This

- **Trivial script, one entrypoint, no swappable boundaries**: skip it. Simple is better than complex - a 200-line tool doesn't need a `core/`, `adapters/`, `composition/` split.
- **Minimum viable version, no directories needed**: apply the discipline without the structure - keep decision logic in pure functions (no I/O), push all I/O to the edges ("functional core, imperative shell"). Promote to full ports/adapters once a boundary is genuinely swappable (multiple storage backends) or worth faking explicitly in tests.
- **Full version**: once there's more than one real external system to talk to, or more than one way to drive the app (a CLI *and* an API, say), formalise it - see below.

### The Mental Model

- **Core** - your data (value objects) plus pure decision functions. No I/O, no third-party types.
- **Ports** - interfaces the core defines, named with verbs (`ExtractsData`, not `Extractor`), in the core's own language, describing either what it needs from outside (**driven ports** - the core calls *out* through these) or how something else invokes it (**driving ports** - something calls *in* through these). Ports live in core, not next to whichever adapter happens to implement them.
- **Adapters** - concrete implementations of ports. One per real external system (`S3Extractor`, `DeltaTableLoader`; the adapter names its system, the port names its behaviour), plus a trivial fake per port for tests - no mocking library required.
- **Composition root** - the only place allowed to import both core and adapters. Wires concrete adapters into orchestrators. This is also where an "API request -> which job" mapping belongs, if you have one.
- **Orchestrator** - sequences port calls and core calls. Contains no decisions itself: *fetch, decide, fetch, decide, act.*

**Rule of thumb**: if the orchestrator has an `if`/`elif` encoding a business rule, that logic leaked out of core. If a "pure" core function is doing a network or file call, it isn't pure - it needs to become a port.

### Driven vs Driving

Ports point in two directions:

- **Driven** - the core calls out (`ExtractsData`, `LoadsData`, `ProvidesSchema`). The adapter is called *by* the core.
- **Driving** - something calls in (`RunsJobs`). A CLI or HTTP router is the *driving adapter*; it calls the driving port to start a use case. Don't confuse a driving port's `RunsJobs.run(job, params)` with a *driven* adapter that happens to also be called `Runner` internally (e.g. an execution engine) - they operate at completely different levels.

## Worked Example: an ELT Tool

A tool built from three component families:

- **Extractors** (S3, Kafka, Postgres -> DataFrame) - **driven adapters**, implementing one `ExtractsData` port.
- **Loaders** (-> a table, -> object storage) - **driven adapters**, implementing one `LoadsData` port, symmetric to `ExtractsData`.
- **Transformers** (DataFrame -> DataFrame, atomic or business logic) - **core**, not adapters. They never leave the process, so they need no port of their own - unless a transformer itself calls out (e.g. an ML classifier API), in which case *that* becomes its own port one level down.

A named business process ("load CDC logs to a Delta table", "load Kafka JSON to a Delta table") is not a bespoke class - it's a **composition-root factory** that chooses a specific extractor, transformer chain, and loader, and hands them to one generic orchestrator:

```python
# core/pipeline.py
class Pipeline:
    def __init__(self, extractor: ExtractsData, transformers: list[TransformsData], loader: LoadsData):
        self._extractor, self._transformers, self._loader = extractor, transformers, loader

    def run(self) -> WriteResult:
        df = self._extractor.extract()             # fetch
        for transform in self._transformers:
            df = transform(df)                        # decide, one step at a time
        return self._loader.load(df)                  # fetch-as-a-write

# composition/applications.py - NOT core: references concrete adapters
def load_cdc_logs_to_delta(s3_path: str, table: str) -> Pipeline:
    return Pipeline(
        extractor=S3Extractor(path=s3_path),
        transformers=[add_input_filename, add_ingestion_timestamp, ensure_cdc_fields],
        loader=DeltaTableLoader(table=table),
    )

def load_kafka_json_to_delta(topic: str, table: str) -> Pipeline:
    return Pipeline(
        extractor=KafkaExtractor(topic=topic),
        transformers=[parse_json_payload, classify_user],
        loader=DeltaTableLoader(table=table),
    )

# composition/registry.py - the "API request -> job" mapping
REGISTRY = {
    "cdc_logs_to_delta": load_cdc_logs_to_delta,
    "kafka_json_to_delta": load_kafka_json_to_delta,
}
```

A driving adapter (HTTP router or CLI) never sees any of the above directly - it only calls the driving port:

```python
class JobRunner:  # implements the RunsJobs driving port
    def __init__(self, registry: dict[str, Callable[..., Pipeline]]):
        self._registry = registry

    def run(self, job_name: str, params: dict) -> Result:
        return self._registry[job_name](**params).run()
```

## Reference Directory Structure

```
src/
└── app/
    ├── exceptions.py
    ├── enums.py
    ├── settings.py                  # config; nothing below reads it directly - composition
    │                                 # passes concrete values into adapter constructors
    ├── core/
    │   ├── domain.py                # value objects - no dependencies
    │   ├── ports.py                 # driven ports (ExtractsData, LoadsData) + driving ports (RunsJobs)
    │   ├── transformers/
    │   │   ├── generic.py           # atomic, reusable
    │   │   └── business.py          # domain-specific
    │   └── pipeline.py              # orchestrator + driving port implementation
    ├── adapters/
    │   ├── extractors/
    │   │   ├── s3.py
    │   │   └── kafka.py
    │   └── loaders/
    │       └── delta.py
    ├── composition/                  # only place importing both adapters AND core
    │   ├── applications.py          # factory functions - reference concrete adapters
    │   └── registry.py              # name -> factory mapping
    └── interfaces/                   # driving adapters
        ├── http/router.py
        └── cli/main.py
```

## Enforcing Layers

### Python: `import-linter`

```ini
[importlinter]
root_package = app
include_external_packages = True

[importlinter::contract:top-level-layers]
name = Top level layers
type = layers
exhaustive = true
containers =
    app
layers =
    interfaces
    composition
    settings
    adapters
    core
    exceptions | enums

[importlinter::contract:core-layers]
name = Core layers
type = layers
exhaustive = true
containers =
    app.core
layers =
    pipeline
    transformers | ports
    domain

[importlinter::contract:adapters-layers]
name = Adapters layers
type = layers
exhaustive = true
containers =
    app.adapters
layers =
    extractors | loaders
```

Run it as part of `lint` (see [structure.md](structure.md#task-runner-justfile)) - a violation here (e.g. `core` importing `adapters`) is a structural regression, not a style nit, and should block the same way a failing type check does.

### Rust: workspace crates plus a dependency check

Use a Cargo workspace of three crates, each prefixed with the project name (an unprefixed crate called `domain` once collided with a real advisory in `cargo audit`):

```
crates/
├── <project>-core        # domain, ports, pure functions. No workspace dependencies.
├── <project>-adapters    # implements ports. Depends on core only.
└── <project>-app         # composition root and binaries. The only crate that depends on both.
```

Cargo on its own rejects only dependency cycles. A backward dependency that forms no cycle, or a third-party crate in core, builds without complaint. `scripts/check-deps.sh` closes the gap by reading `cargo metadata` and failing when:

- core depends on another workspace crate, or on a third-party crate missing from `scripts/core-allowed-deps.txt`
- adapters depend on a workspace crate other than core
- any crate other than app depends on both core and adapters, or anything depends on app

The script runs as part of `lint`. Changes to the allow-list need a reason in review. The workspace template implements it.

---

**Last Updated**: 2026-10-01
