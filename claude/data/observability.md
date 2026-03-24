# Data Observability

Data lineage, pipeline metrics, and data integrity monitoring using OpenTelemetry-style patterns.

## Observability Principles

**Data pipelines are production systems:**
- Monitor health and performance
- Track data lineage (where did this come from?)
- Measure data integrity (freshness, completeness, correctness)
- Alert on failures and anomalies
- Debug issues quickly

**OpenTelemetry-style observability:**
- **Traces** - Pipeline execution lineage (what transformed what)
- **Metrics** - Quantitative measurements (duration, row counts, lag, integrity scores)
- **Logs** - Structured events with context (pipeline started, quality check failed)

**Three pillars:**
1. **Lineage** - Where data came from and where it goes
2. **Pipeline Metrics** - Run statistics (duration, rows processed, status)
3. **Data Integrity Metrics** - Freshness, Completeness, Correctness

**Quality vs Observability:**
- **Data Quality** (point-in-time) - Validation logic: what to check and how (`quality.md`)
- **Data Observability** (over time) - Measuring quality trends: monitoring validation failure rates, tracking metrics, alerting on anomalies

Data quality metrics measured over time make up a core part of the data observability suite.

**Tool-agnostic approach:**
Emit standardized metrics and logs that can be consumed by any observability platform (DataDog, Prometheus, Grafana, custom dashboards).

## Data Lineage

### Why Lineage Matters

**Answer critical questions:**
- Where did this data come from?
- What transformations were applied?
- Which downstream systems depend on this?
- What was the impact of a data issue?

**Use cases:**
- Impact analysis (if I change X, what breaks?)
- Debugging (why is this value wrong?)
- Compliance (audit trail for regulations)
- Understanding dependencies

### Column-Level Lineage

**Track transformations at column level:**
- Target table and column
- Source tables and columns
- Transformation logic description
- Timestamp of when lineage was recorded

### Table-Level Lineage

**Track dependencies between tables:**
- Target table
- Source tables
- Transformation type (join, aggregate, filter)
- Pipeline name
- Store in lineage table for querying

### Automatic Lineage Capture

**Use metadata to build lineage automatically:**
- Parse query execution plans
- Extract source table references
- Log lineage metadata
- Integrate with pipeline orchestration

### Lineage Visualization

**Query lineage for visualization:**

```sql
-- Find all upstream dependencies
with recursive upstream as (
    select target_table, source_tables
    from lineage.tables
    where target_table = 'domain.analytics.user_metrics'

    union all

    select l.target_table, l.source_tables
    from lineage.tables l
    inner join upstream u
      on l.target_table = any(u.source_tables)
)
select distinct target_table, unnest(source_tables) as source_table
from upstream;
```

## Pipeline Metrics

### Core Metrics

**Track for every pipeline run:**

```python
from dataclasses import dataclass

@dataclass
class PipelineMetrics:
    """Pipeline run metrics."""
    pipeline_name: str
    run_id: str
    started_at: datetime
    completed_at: datetime
    duration_seconds: float
    rows_read: int
    rows_written: int
    rows_filtered: int
    status: str  # "success", "failed", "partial"
    error_message: str = None

def record_metrics(metrics: PipelineMetrics):
    """Record pipeline metrics."""
    metrics_df = spark.createDataFrame([asdict(metrics)])
    metrics_df.write.format("delta").mode("append").save("/metrics/pipelines")

    log.info("pipeline_completed", **asdict(metrics))
```

### Usage Pattern

```python
import time
from uuid import uuid4

def run_pipeline(pipeline_name: str):
    """Run pipeline with metrics tracking."""
    run_id = str(uuid4())
    started_at = datetime.now()

    try:
        # Read data
        input_df = spark.read.format("delta").load("/landing/events")
        rows_read = input_df.count()

        # Transform
        output_df = transform_data(input_df)
        rows_written = output_df.count()
        rows_filtered = rows_read - rows_written

        # Write
        output_df.write.format("delta").mode("append").save("/cleaned/events")

        # Record success
        metrics = PipelineMetrics(
            pipeline_name=pipeline_name,
            run_id=run_id,
            started_at=started_at,
            completed_at=datetime.now(),
            duration_seconds=(datetime.now() - started_at).total_seconds(),
            rows_read=rows_read,
            rows_written=rows_written,
            rows_filtered=rows_filtered,
            status="success"
        )

    except Exception as e:
        # Record failure
        metrics = PipelineMetrics(
            pipeline_name=pipeline_name,
            run_id=run_id,
            started_at=started_at,
            completed_at=datetime.now(),
            duration_seconds=(datetime.now() - started_at).total_seconds(),
            rows_read=0,
            rows_written=0,
            rows_filtered=0,
            status="failed",
            error_message=str(e)
        )
        raise
    finally:
        record_metrics(metrics)
```

### Metric Aggregations

**Analyze pipeline health over time:**

```sql
-- Average pipeline duration by day
select
    date(started_at) as run_date
    , pipeline_name
    , avg(duration_seconds) as avg_duration
    , count(*) as run_count
    , sum(case when status = 'failed' then 1 else 0 end) as failure_count
from metrics.pipelines
where started_at >= current_date - interval '30 days'
group by 1, 2
order by 1 desc, 2;

-- Detect duration anomalies
select
    pipeline_name
    , avg(duration_seconds) as avg_duration
    , stddev(duration_seconds) as stddev_duration
from metrics.pipelines
where started_at >= current_date - interval '7 days'
  and status = 'success'
group by 1;
```

## Data Integrity Metrics

**Measure data quality between layers in the pipeline.**

### Freshness

**Measure lag between source changes and target reflection.**

Freshness is not "how old is the data" but "how current is it" - the time delta between a change in the source and that change being reflected in the target.

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum

class FreshnessStatus(Enum):
    GREEN = "green"
    AMBER = "amber"
    RED = "red"

@dataclass
class FreshnessMetric:
    """Freshness measurement between source and target."""
    source_layer: str
    target_layer: str
    lag_seconds: float
    measured_at: datetime
    status: FreshnessStatus

    green_threshold_seconds: float = 300  # <5 min
    amber_threshold_seconds: float = 600  # <10 min

def measure_freshness(
    source_table: str,
    target_table: str,
    timestamp_column: str = "updated_at"
) -> FreshnessMetric:
    """Measure freshness lag between source and target."""
    # Get latest timestamp from source
    source_latest = spark.sql(f"""
        select max({timestamp_column}) as latest
        from {source_table}
    """).collect()[0]["latest"]

    # Get latest timestamp from target
    target_latest = spark.sql(f"""
        select max({timestamp_column}) as latest
        from {target_table}
    """).collect()[0]["latest"]

    # Calculate lag
    lag_seconds = (source_latest - target_latest).total_seconds()

    # Determine status
    if lag_seconds < 300:
        status = FreshnessStatus.GREEN
    elif lag_seconds < 600:
        status = FreshnessStatus.AMBER
    else:
        status = FreshnessStatus.RED

    return FreshnessMetric(
        source_layer=source_table,
        target_layer=target_table,
        lag_seconds=lag_seconds,
        measured_at=datetime.now(),
        status=status
    )

# Emit metric (tool-agnostic)
metric = measure_freshness("landing.events", "cleaned.events")
log.info(
    "freshness_measured",
    source=metric.source_layer,
    target=metric.target_layer,
    lag_seconds=metric.lag_seconds,
    status=metric.status.value
)
```

**Multi-layer measurement:**

```python
# Measure across entire pipeline
layers = [
    ("source_system", "landing.events"),
    ("landing.events", "cleaned.events"),
    ("cleaned.events", "structured.customers"),
    ("structured.customers", "domain.marketing.customers")
]

for source, target in layers:
    metric = measure_freshness(source, target)
    # Emit to observability platform
    emit_metric("data.freshness.lag_seconds", metric.lag_seconds, {
        "source": source,
        "target": target,
        "status": metric.status.value
    })
```

### Completeness

**Verify all expected records are present.**

Completeness checks account for architectural transformations (e.g., Type-2 SCD creates multiple rows per entity).

```python
@dataclass
class CompletenessMetric:
    """Completeness measurement."""
    source_layer: str
    target_layer: str
    source_count: int
    target_count: int
    expected_ratio: float  # Expected target/source ratio
    actual_ratio: float
    is_complete: bool
    measured_at: datetime

def measure_completeness(
    source_table: str,
    target_table: str,
    expected_ratio: float = 1.0,  # 1:1 by default
    tolerance: float = 0.02  # 2% tolerance
) -> CompletenessMetric:
    """Measure completeness between source and target."""
    # Count records
    source_count = spark.table(source_table).count()
    target_count = spark.table(target_table).count()

    actual_ratio = target_count / source_count if source_count > 0 else 0

    # Check if within tolerance
    is_complete = abs(actual_ratio - expected_ratio) <= tolerance

    return CompletenessMetric(
        source_layer=source_table,
        target_layer=target_table,
        source_count=source_count,
        target_count=target_count,
        expected_ratio=expected_ratio,
        actual_ratio=actual_ratio,
        is_complete=is_complete,
        measured_at=datetime.now()
    )

# Example: Type-2 SCD expects more rows than source
metric = measure_completeness(
    "cleaned.user_events",
    "structured.users",
    expected_ratio=1.3,  # Expect 30% more rows due to history
    tolerance=0.1
)

log.info(
    "completeness_measured",
    source=metric.source_layer,
    target=metric.target_layer,
    source_count=metric.source_count,
    target_count=metric.target_count,
    is_complete=metric.is_complete
)
```

### Correctness

**Track data validation failures over time.**

Correctness measures whether data conforms to expectations:
- Value ranges (amounts, IDs)
- Referential integrity (foreign keys)
- Business logic rules
- Schema compliance

**Implementation:** Quality validation logic is defined in `quality.md`. Observability tracks validation failure rates over time.

```python
# Emit correctness metric from quality checks
log.info(
    "correctness_checked",
    check_name="order_total_in_range",
    table="structured.orders",
    passed=True,
    failed_count=0,
    total_count=1000,
    measured_at=datetime.now()
)
```

### Integrity Dashboard

**Track integrity metrics over time:**

```python
# Store integrity metrics for trending
integrity_metrics = spark.createDataFrame([
    {
        "metric_type": "freshness",
        "source": "landing.events",
        "target": "cleaned.events",
        "value": lag_seconds,
        "status": status.value,
        "measured_at": datetime.now()
    }
])

# Emit to observability platform (tool-agnostic)
integrity_metrics.write.format("delta").mode("append").save("/metrics/integrity")
```

## Monitoring and Alerting

### Health Checks

**Monitor pipeline health:**

```python
def check_pipeline_health(pipeline_name: str, hours: int = 24):
    """Check if pipeline is healthy."""
    cutoff = datetime.now() - timedelta(hours=hours)

    recent_runs = spark.sql(f"""
        select status, count(*) as count
        from metrics.pipelines
        where pipeline_name = '{pipeline_name}'
          and started_at >= '{cutoff}'
        group by 1
    """).collect()

    total_runs = sum(row["count"] for row in recent_runs)
    failed_runs = sum(
        row["count"] for row in recent_runs if row["status"] == "failed"
    )

    if total_runs == 0:
        raise ValueError(f"Pipeline {pipeline_name} has not run in {hours} hours")

    failure_rate = failed_runs / total_runs
    if failure_rate > 0.1:
        raise ValueError(
            f"Pipeline {pipeline_name} failure rate too high: {failure_rate:.1%}"
        )

    return {"total_runs": total_runs, "failed_runs": failed_runs}
```

### Alerting Patterns

**Emit structured logs and metrics for alerting:**

```python
# Tool-agnostic alerting via structured logging and metrics
def emit_alert(
    alert_name: str,
    severity: str,  # "error", "warning", "info"
    message: str,
    **context
):
    """Emit alert via structured logging and metrics."""
    # Structured log (picked up by log aggregation)
    log.error(
        alert_name,
        severity=severity,
        message=message,
        alert=True,  # Flag for alert routing
        **context
    )

    # Emit metric (picked up by observability platform)
    emit_metric(
        f"alert.{alert_name}",
        1,  # Increment counter
        {
            "severity": severity,
            **context
        }
    )

# Usage with integrity checks
metric = measure_freshness("landing.events", "cleaned.events")
if metric.status == FreshnessStatus.RED:
    emit_alert(
        "data_freshness_sla_breach",
        severity="error",
        message=f"Freshness SLA breached: {metric.lag_seconds}s lag",
        source=metric.source_layer,
        target=metric.target_layer,
        lag_seconds=metric.lag_seconds
    )

# Usage with pipeline health
try:
    check_pipeline_health("user_metrics", hours=24)
except ValueError as e:
    emit_alert(
        "pipeline_health_check_failed",
        severity="error",
        message=str(e),
        pipeline="user_metrics"
    )
```

**Observability platforms handle alert routing:**
- DataDog: Create monitors on log patterns and metrics
- Prometheus: Use Alertmanager rules
- Custom: Query logs/metrics and route to Slack/PagerDuty

## Debugging Strategies

### Structured Logging

**Log with context for debugging.**

Structured logging enables powerful query and analysis capabilities:

```python
import structlog

log = structlog.get_logger()

def process_batch(batch_id: str, df):
    """Process batch with structured logging."""
    log.info("batch_processing_started", batch_id=batch_id, row_count=df.count())

    try:
        # Transform
        result_df = transform(df)

        log.info(
            "batch_processing_completed",
            batch_id=batch_id,
            input_rows=df.count(),
            output_rows=result_df.count(),
            duration_seconds=elapsed_time
        )

        return result_df

    except Exception as e:
        log.error(
            "batch_processing_failed",
            batch_id=batch_id,
            error=str(e),
            error_type=type(e).__name__,
            exc_info=True
        )
        raise
```

**Benefits:**
- **Searchable** - Query logs: "Show all batches with >10k rows that failed"
- **Aggregatable** - Measure P95 processing time by pipeline
- **Correlatable** - Track a single run through entire pipeline with `run_id`

### File-Level Debugging

**Track input files for granular debugging.**

At the landing layer, track which files produced errors for targeted investigation:

```python
def ingest_file(file_path: str):
    """Ingest file with tracking."""
    log.info("file_ingestion_started", file_path=file_path)

    try:
        df = spark.read.json(file_path)
        row_count = df.count()

        # Process
        result = process(df)

        log.info(
            "file_ingestion_completed",
            file_path=file_path,
            row_count=row_count,
            status="success"
        )

        return result

    except Exception as e:
        log.error(
            "file_ingestion_failed",
            file_path=file_path,
            error=str(e),
            error_type=type(e).__name__,
            exc_info=True
        )
        raise

# When errors occur, query logs to find problematic files
# Then debug against specific files without processing entire dataset
```

**Why file-level tracking:**
- Debug specific files without reprocessing entire dataset
- Identify patterns ("all files from source X fail")
- Replay individual files for testing fixes

### Error Context Capture

**Capture DataFrame state when errors occur.**

Error context capture saves detailed metadata about the DataFrame state at failure time, enabling async debugging and pattern detection:

```python
def process_with_context(df, pipeline_name: str, run_id: str):
    """Process with error context capture."""
    try:
        return transform(df)

    except Exception as e:
        # Capture comprehensive context
        context = {
            "pipeline_name": pipeline_name,
            "run_id": run_id,
            "timestamp": datetime.now(),
            "error_type": type(e).__name__,
            "error_message": str(e),
            "stack_trace": traceback.format_exc(),
            # DataFrame metadata
            "row_count": df.count(),
            "column_count": len(df.columns),
            "columns": df.columns,
            "schema": df.schema.json(),
            # Sample data (first 5 rows)
            "sample_data": df.limit(5).toPandas().to_json(),
            # Column statistics
            "null_counts": {col: df.filter(F.col(col).isNull()).count() for col in df.columns},
        }

        # Emit structured log
        log.error("transformation_failed", **context)

        # Persist error context for analysis
        error_df = spark.createDataFrame([{
            "pipeline_name": pipeline_name,
            "run_id": run_id,
            "timestamp": context["timestamp"],
            "error_type": context["error_type"],
            "error_message": context["error_message"],
            "context_json": json.dumps(context)
        }])
        error_df.write.format("delta").mode("append").save("/metrics/error_context")

        raise

# Query error context for pattern analysis
"""
-- Find all errors with schema changes
select
    pipeline_name,
    count(*) as error_count,
    collect_set(columns) as unique_schemas
from error_context
where date(timestamp) >= current_date - 7
group by pipeline_name
having size(unique_schemas) > 1;

-- Find errors correlated with high row counts
select
    pipeline_name,
    avg(row_count) as avg_rows,
    count(*) as error_count
from error_context
group by pipeline_name
order by avg_rows desc;
"""
```

**Why error context matters:**
- **Async debugging** - Error at 2am, debug in the morning with full context
- **Pattern detection** - "Always fails when row_count > 10M"
- **Root cause analysis** - "New column added, downstream transform didn't handle it"
- **Incident response** - Understand impact without reproducing error

## Observability Dashboard

### Key Metrics to Track

**Pipeline health:**
- Success rate (by pipeline)
- Average duration (by pipeline)
- Recent failures (last 24h)

**Data quality:**
- Null percentages (by table/column)
- Duplicate counts (by table)
- Volume trends (by table)

**Data freshness:**
- Latest timestamp (by table)
- Age in hours (by table)
- Staleness alerts

### Example Dashboard Queries

```sql
-- Pipeline success rate (last 7 days)
select
    pipeline_name
    , count(*) as total_runs
    , sum(case when status = 'success' then 1 else 0 end) as successful_runs
    , sum(case when status = 'success' then 1 else 0 end) * 1.0 / count(*) as success_rate
from metrics.pipelines
where started_at >= current_date - interval '7 days'
group by 1
order by 4 asc;

-- Data freshness by table
select
    table_name
    , max(created_at) as latest_data
    , datediff(hour, max(created_at), current_timestamp()) as age_hours
from metadata.tables
group by 1
having age_hours > 24
order by 3 desc;

-- Volume trends
select
    date(created_at) as date
    , count(*) as row_count
from cleaned.events
where created_at >= current_date - interval '30 days'
group by 1
order by 1 desc;
```

## Best Practices

**Make observability part of the pipeline:**
- Log at key checkpoints
- Record metrics automatically
- Track lineage by default

**Alert on what matters:**
- Pipeline failures
- Data quality degradation
- Freshness violations
- Volume anomalies

**Make debugging easy:**
- Structured logging with context
- Save intermediate results
- Sample data for inspection

**Review regularly:**
- Weekly dashboard reviews
- Monthly pipeline health audits
- Quarterly lineage validation

---

**Last Updated**: 2026-03-24
