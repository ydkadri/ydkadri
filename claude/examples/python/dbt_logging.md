# dbt Logging Patterns

**Note**: dbt controls its own logging framework, making full structured logging integration challenging. These patterns work around dbt's constraints.

## dbt Log Configuration

dbt uses its own logging system. Configure via `profiles.yml`:

```yaml
config:
  log_path: "logs"
  log_format: json  # or "text"
  log_level: info
```

## Custom Macros with Logging

```sql
-- macros/log_context.sql
{% macro log_execution(model_name, action) %}
  {{ log(
      "Model: " ~ model_name ~
      " | Action: " ~ action ~
      " | Timestamp: " ~ modules.datetime.datetime.now().isoformat(),
      info=True
  ) }}
{% endmacro %}

-- Usage in model
{{ config(
    materialized='incremental',
    pre_hook="{{ log_execution(this.name, 'start') }}",
    post_hook="{{ log_execution(this.name, 'complete') }}"
) }}
```

## Python Models with Structured Logging

Python models in dbt can use custom logging, but output integrates with dbt's logging:

```python
# models/my_python_model.py
import json
from datetime import datetime

def model(dbt, session):
    # Log structured data as JSON strings that dbt captures
    dbt.config(materialized="table")

    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "model": "my_python_model",
        "action": "start",
    }
    print(f"STRUCTLOG: {json.dumps(log_entry)}")

    # Model logic
    df = session.table("source_table")

    log_entry["action"] = "complete"
    log_entry["row_count"] = len(df)
    print(f"STRUCTLOG: {json.dumps(log_entry)}")

    return df
```

## Event Tracking with Artifacts

Use dbt artifacts for structured tracking:

```python
# scripts/parse_dbt_artifacts.py
import json
from pathlib import Path

def extract_run_results():
    """Parse dbt run_results.json for structured logging."""
    results_path = Path("target/run_results.json")

    if not results_path.exists():
        return

    with results_path.open() as f:
        results = json.load(f)

    for result in results["results"]:
        log_entry = {
            "timestamp": result["timing"][0]["started_at"],
            "model": result["unique_id"],
            "status": result["status"],
            "execution_time": result["execution_time"],
            "rows_affected": result.get("adapter_response", {}).get("rows_affected"),
        }
        # Send to your logging system
        logger.info("dbt_model_run", **log_entry)
```

## Hooks for Observability

```sql
-- macros/observability_hooks.sql
{% macro on_run_start() %}
  {% set run_started_at = modules.datetime.datetime.now() %}
  {{ log("Run started at: " ~ run_started_at.isoformat(), info=True) }}

  {% if target.name == 'prod' %}
    -- Log to external system via API call in Python macro
    {{ log_to_external_system('run_start', run_started_at) }}
  {% endif %}
{% endmacro %}

{% macro on_run_end(results) %}
  {% set run_ended_at = modules.datetime.datetime.now() %}
  {{ log("Run ended at: " ~ run_ended_at.isoformat(), info=True) }}

  {% set summary = {
      'total': results | length,
      'passed': results | selectattr('status', 'equalto', 'success') | list | length,
      'failed': results | selectattr('status', 'equalto', 'error') | list | length,
      'skipped': results | selectattr('status', 'equalto', 'skipped') | list | length,
  } %}

  {{ log("Summary: " ~ summary | string, info=True) }}
{% endmacro %}
```

## Integration with External Logging

For true structured logging, emit dbt logs to an external system:

```python
# scripts/dbt_log_forwarder.py
import json
import structlog
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

logger = structlog.get_logger(__name__)

class DBTLogHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith("dbt.log"):
            self.process_log_file(event.src_path)

    def process_log_file(self, log_path):
        """Parse dbt.log and forward to structured logging."""
        with open(log_path) as f:
            for line in f:
                if line.startswith("STRUCTLOG:"):
                    # Extract structured logs from dbt output
                    structured_data = json.loads(line.replace("STRUCTLOG: ", ""))
                    logger.info("dbt_event", **structured_data)

# Run as daemon alongside dbt
observer = Observer()
observer.schedule(DBTLogHandler(), path="logs", recursive=False)
observer.start()
```

## Testing Macros

```sql
-- tests/test_log_context.sql
{% test log_context_macro() %}
    -- Test that macro executes without error
    {{ log_execution('test_model', 'test_action') }}
    select 1 as result
{% endtest %}
```

## Limitations

1. **dbt Controls Logging Framework**: Cannot replace dbt's native logging
2. **Limited Context**: Less flexibility than direct structlog integration
3. **Workarounds Required**: Must use print statements or external log parsing
4. **Artifact Parsing**: Best structured data comes from parsing run artifacts after execution

**Recommendation**: For production dbt deployments, parse `run_results.json` and `manifest.json` artifacts post-execution and forward to your observability platform.
