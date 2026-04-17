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
- Use recursive queries to find upstream/downstream dependencies
- Build directed acyclic graph (DAG) of table relationships
- Visualize with tools or custom dashboards

## Pipeline Metrics

### Core Metrics

**Track for every pipeline run:**
- Pipeline name and unique run ID
- Start/end timestamps and duration
- Row counts (read, written, filtered)
- Status (success, failed, partial)
- Error messages for failures

**Emit as structured logs and store in metrics table.**

### Metric Aggregations

**Analyze pipeline health over time:**
- Average duration by pipeline and day
- Failure rates and trends
- Row count patterns
- Duration anomalies (compare to historical mean/stddev)

## Data Integrity Metrics

**Measure data quality between layers in the pipeline.**

### Freshness

**Measure lag between source changes and target reflection.**

Freshness is not "how old is the data" but "how current is it" - the time delta between a change in the source and that change being reflected in the target.

**Measurement approach:**
- Get latest timestamp from source layer
- Get latest timestamp from target layer
- Calculate lag in seconds
- Classify with thresholds: GREEN (<5 min), AMBER (<10 min), RED (>10 min)
- Emit as structured metric

**Multi-layer measurement:**
- Measure across entire pipeline (source → landing → cleaned → structured → domain)
- Track lag at each transition
- Alert on threshold violations

### Completeness

**Verify all expected records are present.**

Completeness checks account for architectural transformations (e.g., Type-2 SCD creates multiple rows per entity).

**Measurement approach:**
- Count records in source and target
- Calculate actual ratio (target_count / source_count)
- Define expected ratio based on transformation (1:1 for filters, >1 for Type-2 SCD)
- Set tolerance threshold (e.g., 2%)
- Mark as complete if within tolerance
- Emit as structured metric

### Correctness

**Track data validation failures over time.**

Correctness measures whether data conforms to expectations:
- Value ranges (amounts, IDs)
- Referential integrity (foreign keys)
- Business logic rules
- Schema compliance

**Implementation:** Quality validation logic is defined in `quality.md`. Observability tracks validation failure rates over time.

**Emit correctness metrics from quality checks:**
- Check name and table
- Pass/fail status
- Failed/total row counts
- Timestamp

### Integrity Dashboard

**Track integrity metrics over time:**
- Store metrics in time-series table
- Include metric type (freshness, completeness, correctness)
- Track source/target layers
- Record values and status
- Emit to observability platform (tool-agnostic)

## Monitoring and Alerting

### Health Checks

**Monitor pipeline health:**
- Query recent pipeline runs (e.g., last 24 hours)
- Calculate failure rate
- Alert if no runs in time window
- Alert if failure rate exceeds threshold (e.g., >10%)

### Alerting Patterns

**Emit structured logs and metrics for alerting:**
- Use tool-agnostic approach (structured logging + metrics)
- Include alert name, severity (error/warning/info), message
- Add context (source, target, values)
- Flag logs for alert routing

**Alert triggers:**
- Freshness SLA breaches (lag exceeds RED threshold)
- Pipeline health failures (no runs or high failure rate)
- Completeness violations (row count ratios out of tolerance)
- Correctness failures (validation check failures)

**Observability platforms handle alert routing:**
- DataDog: Create monitors on log patterns and metrics
- Prometheus: Use Alertmanager rules
- Custom: Query logs/metrics and route to Slack/PagerDuty

## Debugging Strategies

### Structured Logging

**Log with context for debugging.**

Structured logging enables powerful query and analysis capabilities.

**Include in logs:**
- Event name (batch_processing_started, batch_processing_completed)
- Identifiers (batch_id, run_id, pipeline_name)
- Counts (input_rows, output_rows)
- Duration and timing information
- Error details (error_type, error_message, stack trace)

**Benefits:**
- **Searchable** - Query logs: "Show all batches with >10k rows that failed"
- **Aggregatable** - Measure P95 processing time by pipeline
- **Correlatable** - Track a single run through entire pipeline with `run_id`

### File-Level Debugging

**Track input files for granular debugging.**

At the landing layer, track which files produced errors for targeted investigation.

**Track in logs:**
- File path or identifier
- Row count
- Processing status (success/failure)
- Error details on failure

**Why file-level tracking:**
- Debug specific files without reprocessing entire dataset
- Identify patterns ("all files from source X fail")
- Replay individual files for testing fixes

### Error Context Capture

**Capture DataFrame state when errors occur.**

Error context capture saves detailed metadata about the DataFrame state at failure time, enabling async debugging and pattern detection.

**Capture on errors:**
- Pipeline identifiers (name, run_id)
- Error details (type, message, stack trace)
- DataFrame metadata (row_count, columns, schema)
- Sample data (first few rows)
- Column statistics (null counts)

**Persist for analysis:**
- Store error context in dedicated table
- Query for patterns ("always fails when row_count > 10M")
- Identify schema drift issues
- Correlate errors with data characteristics

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
- Lag in seconds (by source/target pair)
- Staleness alerts

### Dashboard Implementation

**Query metrics tables for visualization:**
- Pipeline success rates (by pipeline, time window)
- Data freshness by table (latest timestamp, age)
- Volume trends (row counts over time)
- Error rates and patterns

**Visualization options:**
- Time-series graphs for trends
- Status indicators (GREEN/AMBER/RED)
- Tables for recent failures
- Alerts for threshold violations

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
