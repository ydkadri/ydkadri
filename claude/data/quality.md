# Data Quality

Data validation, contracts, and quality checks.

## Data Quality Principles

**Quality is not optional:**
- Bad data in = bad insights out
- Catch issues early (landing → cleaned transition)
- Fail fast when quality checks fail
- Make quality checks explicit and visible

**Data quality vs observability:**
- **Quality (this file):** Validation logic - what to check and how
- **Observability:** Measuring quality trends over time - monitoring and alerting

See `observability.md` for integrity metrics (freshness, completeness, correctness) and monitoring patterns.

## Types of Data Quality Issues

**1. Schema Violations**
- Missing required columns
- Wrong data types
- Null values in non-nullable fields

**2. Value Constraint Violations**
- Out of range (negative amounts, invalid IDs)
- Invalid formats (email without @, malformed phone)
- Unexpected duplicates
- Enum violations (inconsistent categorical values: male/female/m/f/MALE)

**3. Business Logic Violations**
- Data relationship inconsistencies (order total ≠ sum of items)
- Temporal logic (updated_at < created_at, future dates)
- Referential integrity (order references non-existent user)

**4. State Transition Violations**
- Invalid state changes (delivered → pending)
- State machine rules broken

**5. Business Rule Violations**
- Domain-specific policy violations
- Age requirements, geographic restrictions
- Trial/subscription rules

## Data Contracts

### Schema Contracts

**Define expected schema explicitly from cleaned layer onwards:**

Schema contracts should be enforced starting at the cleaned layer. The landing layer should remain maximally permissive to accept whatever arrives from sources.

**Why contracts matter:**
- Schema drift detection
- Prevent silent failures
- Self-documenting pipelines
- Easier debugging

### Data Contracts

**Define expected data properties:**
- Specify required fields
- Define constraints (valid email format, positive IDs, date ranges)
- Document data expectations as code

## Validation Patterns

### Input Validation

**Validate at landing → cleaned transition:**

Avoid over-validating landed data. The landing layer should accept whatever arrives. Validation should happen when moving to the cleaned layer.

**Validation types:**
- Check required columns exist
- Validate no null values in required fields
- Enforce correct data types (cast and filter invalid)
- Check values are within expected ranges
- Validate string formats (email, phone, enums)

## Quality Checks

### Completeness Checks

**Check for missing data:**
- Verify expected row counts
- Check null percentages in important columns
- Alert if missing data exceeds thresholds

### Uniqueness Checks

**Check for unexpected duplicates:**
- Verify unique constraints on key columns
- Count duplicates and fail if found

### Business Logic Checks

**Check data relationships and temporal logic:**
- Data relationship consistency (e.g., order total = sum of items)
- Temporal logic (updated_at > created_at, no future dates)
- Referential integrity (foreign keys reference existing records)

### State Transition Checks

**Validate state machine flows:**
- Define valid state transitions
- Join current and previous states to detect changes
- Flag invalid transitions (e.g., delivered → pending)
- Fail fast on state machine violations

### Business Rules Checks

**Validate domain-specific policies:**
- Age requirements (e.g., adult accounts require age ≥ 18)
- Geographic restrictions (shipping rules, service availability)
- Subscription rules (trial expiration, payment status)
- Domain-specific constraints unique to business logic

## Quality Assertions

### Assertion Frameworks

**Use frameworks to define expectations:**

Many teams use assertion frameworks like Great Expectations, dbt tests, or custom solutions. The key is to make quality checks explicit, automated, and part of the pipeline.

**Common approaches:**
- Framework-based (Great Expectations, dbt tests)
- Custom assertion functions
- Check result objects with pass/fail status
- Aggregate and report failed checks

## Anomaly Detection

### Statistical Anomalies

**Detect outliers using statistics:**
- Calculate mean and standard deviation
- Flag values beyond N standard deviations
- Log warnings for outlier counts

### Volume Anomalies

**Detect unexpected volume changes:**
- Compare current row count to historical mean
- Alert on significant deviations (e.g., >20%)
- Track volume trends over time

### Pattern Anomalies

**Detect unexpected patterns:**
- Check distribution of categorical columns
- Alert on unusual proportions (e.g., high error rates)
- Monitor pattern shifts over time

## Quality Metrics

### Calculating Metrics

**Calculate quality metrics during validation:**
- Row counts (total, duplicates, nulls)
- Validation failure percentages
- Quality scores by dimension
- Emit as structured logs for monitoring

### Monitoring Quality Trends

**For monitoring quality over time, see `observability.md`.**

Quality metrics should be emitted as structured logs/metrics and tracked over time:

- **Freshness**: How current is the data (lag between source and target)
- **Completeness**: Are transformations accounting correctly (e.g., Type-2 SCD multiplication)
- **Correctness**: Are validation rules being violated

The boundary:
- **Quality (this file)**: Validation logic - what to check and how
- **Observability**: Measuring quality trends over time - monitoring and alerting

## Best Practices

**Fail fast at landing → cleaned transition:**
- Stop pipeline on critical quality failures
- Don't propagate bad data downstream
- Catch issues early in the pipeline

**Emit structured metrics:**
- Log what checks ran and their results
- Include context for failures (counts, examples)
- Emit metrics for monitoring trends over time

**Make validation explicit:**
- Define data contracts and expectations
- Write validation logic as code
- Tests for validation functions

**Incremental improvement:**
- Add checks as issues discovered
- Review failed checks regularly
- Refine thresholds based on observed data patterns

---

**Last Updated**: 2026-03-24
