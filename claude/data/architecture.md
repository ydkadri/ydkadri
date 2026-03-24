# Data Architecture

High-level data architecture patterns and design principles.

## Four-Layer Architecture

**Preferred approach for data warehouse/lakehouse systems.**

This architecture organizes data into four layers:

1. **Landing** - Raw ingestion, maximally permissive
2. **Cleaned** - Validated and typed events
3. **Structured** - Type-2 SCD business entities
4. **Domain** - Domain-specific marts optimized for consumption

Each layer serves a distinct purpose in the data journey from raw ingestion to business consumption.

> **Note:** Industry often refers to similar patterns as "Medallion Architecture" or "Bronze/Silver/Gold." Our four-layer approach provides more granular separation of concerns.

### Landing Layer

**Raw data ingestion - maximally permissive.**

- **Event-style, append-only** - Preserve everything, immutable
- **Unopinionated** - No type enforcement, no schema validation, no business logic
- **Limited structure for querying**:
  - Partition by ingestion date/time (e.g., `/landing/events/date=2024-01-01/`)
  - Organize by source system (e.g., `/landing/stripe/`, `/landing/postgres/`)
  - Add metadata: `_ingested_at` timestamp, `_source_system` identifier, `_source_file` (or ingestion job identifier) to track what produced the data for targeted issue investigation
- **Schema evolution friendly** - Accept changes from source systems without failures

**Purpose:** Historical record of truth. Accept whatever arrives from sources. Handle schema drift and quality issues downstream.

**Why permissive?** Changes in source systems shouldn't break ingestion. Better to accept malformed data and handle it at the Landing → Cleaned transition.

```python
# Landing layer ingestion - permissive, with metadata
raw_events = (
    spark.read.json("s3://source/events/")
    .withColumn("_ingested_at", current_timestamp())
    .withColumn("_source_system", lit("stripe"))
)

(
    raw_events
    .write
    .format("delta")
    .mode("append")
    .partitionBy("date")  # Partition by ingestion date
    .save("/landing/stripe/events")
)
```

### Cleaned Layer

**Validated and typed events - still append-only.**

- **Event-style, append-only** - Cleaned version of events
- **Type enforcement** - Cast to proper types (integers, timestamps, etc.)
- **Data quality checks** - Validate schema, completeness, formats
- **Deduplicated** - Remove duplicate events
- **Standardized** - Consistent naming, formats
- **Often implemented as views** - No need to materialize if transformations are simple (common pattern in dbt-style warehouses)

**Purpose:** Clean, validated events ready for business transformation. This is where failures should happen (reject bad data).

```python
# Cleaned layer: validate, type, deduplicate
landing_df = spark.read.format("delta").load("/landing/stripe/events")

cleaned_df = (
    landing_df
    .dropDuplicates(["event_id"])
    .filter(col("created_at").isNotNull())
    .withColumn("event_id", col("event_id").cast("bigint"))
    .withColumn("created_at", col("created_at").cast("timestamp"))
    .withColumn("event_type", lower(trim(col("event_type"))))
)

# Can be a view if transformations are simple
cleaned_df.write.format("delta").mode("append").save("/cleaned/stripe/events")
```

### Structured Layer

**Type-2 SCD business entities - canonical truth.**

- **Type-2 Slowly Changing Dimensions** - Track history with effective dates
- **Business-conformed entities** - Single source of truth for business concepts (customers, orders, products)
- **Materialized tables** - Storage is cheap, compute is expensive
- **Complete data** - Full business entity with all attributes
- **Reusable foundation** - Used by multiple domains

**Purpose:** Canonical, historical view of business entities. The authoritative version of business data.

```python
# Structured layer: build Type-2 SCD entities
cleaned_events = spark.read.format("delta").load("/cleaned/stripe/events")

# Transform events into Type-2 SCD for customers
customers_scd = (
    cleaned_events
    .filter(col("event_type") == "customer_updated")
    .withColumn("active_from", col("created_at"))
    .withColumn("active_to", lead("created_at").over(
        Window.partitionBy("customer_id").orderBy("created_at")
    ))
    .withColumn("is_current", col("active_to").isNull())
)

# Materialize - reused by many domains
customers_scd.write.format("delta").mode("overwrite").save("/structured/customers")
```

### Domain Layer

**Domain-specific marts - optimized for consumption.**

- **Domain-specific views** - Marketing, finance, analytics, etc.
- **Governance applied** - PII filtering, access control per domain
- **Structure varies by use case**:
  - Wide denormalized tables for self-service BI
  - Star schema (fact + dimensions) for complex analytics
  - Aggregate tables for dashboards
  - Feature tables for ML models
- **Multiple marts for same entity** - `marketing.customers` vs `analytics.customers`

**Purpose:** Consumption layer with governance boundaries. Optimized for specific business outcomes.

```python
# Domain layer: marketing mart with governance
structured_customers = spark.read.format("delta").load("/structured/customers")

# Marketing needs email/name but analytics doesn't
marketing_customers = (
    structured_customers
    .filter(col("is_current") == True)
    .select(
        "customer_id",
        "email",      # PII - marketing has access
        "name",       # PII - marketing has access
        "segment",
        "created_at"
    )
)

marketing_customers.write.format("delta").mode("overwrite").save("/domain/marketing/customers")

# Analytics gets aggregated, anonymized view
analytics_customers = (
    structured_customers
    .filter(col("is_current") == True)
    .select(
        "customer_id",
        "segment",
        "created_at"
        # No PII
    )
)

analytics_customers.write.format("delta").mode("overwrite").save("/domain/analytics/customers")
```

## Architecture Principles

### Event-First for Operational Data

**Append-only facts provide auditability.**

Operational systems should produce events (facts) that record what happened. These events are immutable and provide a permanent audit trail. Changes to entities are represented as new events, not updates to existing records.

**Why events?**
- Complete history for debugging and auditing
- Can reprocess data if business logic changes
- Natural fit for event-driven architectures
- Supports both operational and analytical needs

### Type-2 SCDs for Dimensions

**Track history, don't overwrite.**

Dimensional data should use Type-2 Slowly Changing Dimensions with effective dates. This preserves historical context for analysis and auditing.

**Example:** When a customer changes their email, keep both versions with `active_from` and `active_to` dates rather than overwriting the old value.

### Always Build for Scale

**No shortcuts for "small" projects.**

Build systems that scale from the start. The cost of building scalable architecture upfront is minimal compared to the cost of rebuilding later. Storage is cheap, compute is expensive, and tech debt is costly.

**Why?** What starts small often grows. Building for scale from day one prevents painful migrations later.

### Schema Isolation

**Clear boundaries between concerns.**

Maintain schema boundaries in databases and clear layer boundaries in data pipelines. Different domains, services, and transformation stages should have isolated schemas.

**Examples:**
- Microservices: Each service owns its schema
- Data warehouse: Clear Landing/Cleaned/Structured/Domain boundaries
- Domain marts: Separate schemas for marketing, finance, analytics

### Domain Layer Design

**Structure varies by business outcome.**

The Domain layer should be designed based on the specific needs of each business domain:

- **Wide denormalized tables** - For self-service BI and simple analysis
- **Aggregate tables** - For dashboards and reporting
- **Feature tables** - For ML models
- **Custom structures** - Whatever best serves the domain's use cases

**Key principle:** Let the consumption pattern drive the structure, not a prescribed schema pattern.

See `data/modeling.md` for guidance on choosing database types and schema design patterns.

## Data Pipeline Patterns

### ELT Pattern

**Extract, Load, Transform - the preferred approach:**

```
Source → Landing (load raw) → Cleaned (validate) → Structured (transform) → Domain (aggregate)
```

**Why ELT:**
- Load first, transform later (flexibility)
- Raw data preserved (can reprocess)
- Leverages warehouse compute power
- Schema evolution friendly
- Event-first approach enables audit trails

### Batch vs Streaming

**Batch processing:**
- Process data in scheduled intervals
- Higher latency, higher throughput
- Simpler error handling
- Use: Daily reports, historical analysis

**Streaming processing:**
- Process data as it arrives
- Lower latency, lower throughput per event
- Complex error handling
- Use: Real-time dashboards, alerting

**Recommendation:** Start with batch, add streaming only when latency requirements demand it.

### Incremental vs Full Refresh

**Incremental processing (preferred):**
- Process only new/changed data
- Efficient use of compute
- Faster pipelines
- Requires watermarking/checkpointing

**Full refresh:**
- Reprocess all data every run
- Simpler logic
- Slower, more expensive
- Use: Small datasets or when incremental is complex

See `data/warehouses/spark-databricks.md` for incremental processing patterns with Delta Lake.

## Data Lifecycle

**Typical data flow:**

1. **Ingestion** - Load raw data to landing layer (events, append-only)
2. **Validation** - Check quality, schema, completeness at cleaned layer
3. **Transformation** - Build Type-2 SCD entities in structured layer
4. **Consumption** - Create domain-specific marts with governance
5. **Analytics** - Reports, dashboards, ML models consume from domain layer

---

**Last Updated**: 2026-03-24
