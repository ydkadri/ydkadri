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

**Define expected schema explicitly:**

```python
from pyspark.sql.types import StructType, StructField, StringType, TimestampType, IntegerType

# Define schema contract
user_schema = StructType([
    StructField("user_id", IntegerType(), nullable=False),
    StructField("email", StringType(), nullable=False),
    StructField("name", StringType(), nullable=False),
    StructField("created_at", TimestampType(), nullable=False),
    StructField("status", StringType(), nullable=False)
])

# Enforce schema on read
df = spark.read.schema(user_schema).json("path/to/data")
```

**Why contracts matter:**
- Schema drift detection
- Prevent silent failures
- Self-documenting pipelines
- Easier debugging

### Data Contracts

**Define expected data properties:**

```python
from typing import Protocol

class UserContract(Protocol):
    """Contract for user data."""

    # Required fields
    user_id: int
    email: str
    created_at: datetime

    # Constraints
    @property
    def is_valid_email(self) -> bool:
        """Email must contain @ symbol."""
        return "@" in self.email

    @property
    def is_positive_id(self) -> bool:
        """User ID must be positive."""
        return self.user_id > 0

    @property
    def is_recent(self) -> bool:
        """Created date must be in past year."""
        return self.created_at > datetime.now() - timedelta(days=365)
```

## Validation Patterns

### Input Validation

**Validate at ingestion (bronze layer):**

```python
def validate_input_data(df):
    """Validate raw input data."""
    # Check required columns exist
    required_cols = ["user_id", "email", "created_at"]
    missing_cols = set(required_cols) - set(df.columns)
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")

    # Check no null values in required fields
    null_counts = df.select(
        [count(when(col(c).isNull(), c)).alias(c) for c in required_cols]
    ).collect()[0]

    if any(null_counts):
        raise ValueError(f"Null values found in required fields: {null_counts}")

    return df
```

### Type Validation

**Enforce correct data types:**

```python
from pyspark.sql import functions as F

def validate_types(df):
    """Validate and cast data types."""
    return (
        df
        .withColumn("user_id", col("user_id").cast("bigint"))
        .withColumn("created_at", col("created_at").cast("timestamp"))
        .withColumn("is_active", col("is_active").cast("boolean"))
        # Drop rows that couldn't be cast
        .filter(
            col("user_id").isNotNull() &
            col("created_at").isNotNull()
        )
    )
```

### Range Validation

**Check values are within expected ranges:**

```python
def validate_ranges(df):
    """Validate data ranges."""
    return (
        df
        # IDs must be positive
        .filter(col("user_id") > 0)
        # Dates must be reasonable
        .filter(col("created_at") >= "2020-01-01")
        .filter(col("created_at") <= F.current_timestamp())
        # Amounts must be non-negative
        .filter(col("order_total") >= 0)
    )
```

### Format Validation

**Validate string formats:**

```python
def validate_formats(df):
    """Validate string formats."""
    return (
        df
        # Email must contain @
        .filter(col("email").contains("@"))
        # Phone must match pattern
        .filter(col("phone").rlike(r"^\+?[\d\s\-()]+$"))
        # Status must be in allowed values
        .filter(col("status").isin(["active", "inactive", "pending"]))
    )
```

## Quality Checks

### Completeness Checks

**Check for missing data:**

```python
def check_completeness(df, expected_count: int = None):
    """Check data completeness."""
    actual_count = df.count()

    # Check row count
    if expected_count and actual_count < expected_count * 0.95:
        raise ValueError(
            f"Incomplete data: expected ~{expected_count}, got {actual_count}"
        )

    # Check null percentages
    total_rows = df.count()
    null_percentages = {
        col_name: df.filter(col(col_name).isNull()).count() / total_rows
        for col_name in df.columns
    }

    # Alert if >5% nulls in important columns
    important_cols = ["user_id", "email", "created_at"]
    high_null_cols = {
        col_name: pct
        for col_name, pct in null_percentages.items()
        if col_name in important_cols and pct > 0.05
    }

    if high_null_cols:
        raise ValueError(f"High null percentage: {high_null_cols}")

    return df
```

### Uniqueness Checks

**Check for unexpected duplicates:**

```python
def check_uniqueness(df, unique_cols: list):
    """Check for duplicates in columns that should be unique."""
    total_rows = df.count()
    distinct_rows = df.select(unique_cols).distinct().count()

    if total_rows != distinct_rows:
        duplicates = total_rows - distinct_rows
        raise ValueError(
            f"Found {duplicates} duplicate rows on {unique_cols}"
        )

    return df
```

### Business Logic Checks

**Check data relationships and temporal logic:**

```python
def check_business_logic(df):
    """Check business logic rules."""
    # Data relationship consistency
    inconsistent_totals = (
        df
        .filter(
            col("order_total") !=
            col("item_1_total") + col("item_2_total") + col("item_3_total")
        )
    )

    if inconsistent_totals.count() > 0:
        raise ValueError(
            f"Found {inconsistent_totals.count()} rows with inconsistent totals"
        )

    # Temporal logic
    invalid_timestamps = (
        df
        .filter(col("updated_at") < col("created_at"))
    )

    if invalid_timestamps.count() > 0:
        raise ValueError(
            f"Found {invalid_timestamps.count()} rows where updated_at < created_at"
        )

    # Referential integrity (check against another table)
    orphaned_orders = (
        df.alias("orders")
        .join(
            users_df.alias("users"),
            col("orders.user_id") == col("users.user_id"),
            "left"
        )
        .filter(col("users.user_id").isNull())
    )

    if orphaned_orders.count() > 0:
        raise ValueError(
            f"Found {orphaned_orders.count()} orders referencing non-existent users"
        )

    return df
```

### State Transition Checks

**Validate state machine flows:**

```python
def check_state_transitions(current_df, previous_df):
    """Check for invalid state transitions."""
    # Define valid transitions
    valid_transitions = {
        "pending": ["processing", "cancelled"],
        "processing": ["shipped", "cancelled"],
        "shipped": ["delivered", "returned"],
        "delivered": ["returned"],
        "cancelled": [],  # Terminal state
        "returned": []    # Terminal state
    }

    # Join current and previous states
    state_changes = (
        current_df.alias("current")
        .join(
            previous_df.alias("previous"),
            col("current.order_id") == col("previous.order_id"),
            "inner"
        )
        .select(
            col("current.order_id"),
            col("previous.status").alias("previous_status"),
            col("current.status").alias("current_status")
        )
        .filter(col("previous_status") != col("current_status"))
    )

    # Check each transition is valid
    invalid_transitions = []
    for row in state_changes.collect():
        previous = row["previous_status"]
        current = row["current_status"]
        if current not in valid_transitions.get(previous, []):
            invalid_transitions.append(
                f"Order {row['order_id']}: {previous} → {current}"
            )

    if invalid_transitions:
        raise ValueError(
            f"Invalid state transitions found:\n" + "\n".join(invalid_transitions)
        )

    return current_df
```

### Business Rules Checks

**Validate domain-specific policies:**

```python
def check_business_rules(df):
    """Check business rule violations."""
    # Age requirement for account type
    invalid_age_accounts = (
        df
        .filter(
            (col("age") < 18) & (col("account_type") == "adult")
        )
    )

    if invalid_age_accounts.count() > 0:
        raise ValueError(
            f"Found {invalid_age_accounts.count()} underage users with adult accounts"
        )

    # Geographic restrictions
    invalid_shipping = (
        df
        .filter(
            (col("shipping_country") != col("billing_country")) &
            (col("shipping_restricted") == True)
        )
    )

    if invalid_shipping.count() > 0:
        raise ValueError(
            f"Found {invalid_shipping.count()} orders violating shipping restrictions"
        )

    # Subscription rules
    expired_trials = (
        df
        .filter(
            (col("trial_expired_at") < F.current_timestamp()) &
            (col("subscription_status") == "trial")
        )
    )

    if expired_trials.count() > 0:
        raise ValueError(
            f"Found {expired_trials.count()} expired trials still marked as active"
        )

    return df
```

## Quality Assertions

### Assertion Frameworks

**Use frameworks to define expectations:**

Many teams use assertion frameworks like Great Expectations, dbt tests, or custom solutions. The key is to make quality checks explicit, automated, and part of the pipeline.

**Example with Great Expectations:**

```python
import great_expectations as gx

# Create expectations
context = gx.get_context()

expectation_suite = context.add_expectation_suite(
    expectation_suite_name="user_data_suite"
)

# Define expectations
expectation_suite.expect_column_values_to_not_be_null("user_id")
expectation_suite.expect_column_values_to_be_unique("user_id")
expectation_suite.expect_column_values_to_match_regex(
    "email",
    regex=r"[^@]+@[^@]+\.[^@]+"
)
expectation_suite.expect_column_values_to_be_in_set(
    "status",
    value_set=["active", "inactive", "pending"]
)

# Validate data
batch = context.get_batch(expectation_suite_name="user_data_suite")
results = batch.validate()

if not results.success:
    raise ValueError(f"Data quality checks failed: {results}")
```

### Custom Assertions

**Write custom quality checks:**

```python
from dataclasses import dataclass

@dataclass
class QualityCheck:
    """Quality check result."""
    name: str
    passed: bool
    message: str
    count: int = 0

def assert_no_duplicates(df, columns: list) -> QualityCheck:
    """Assert no duplicates on given columns."""
    total = df.count()
    distinct = df.select(columns).distinct().count()
    duplicates = total - distinct

    return QualityCheck(
        name="no_duplicates",
        passed=(duplicates == 0),
        message=f"Found {duplicates} duplicates on {columns}",
        count=duplicates
    )

def assert_all_not_null(df, columns: list) -> QualityCheck:
    """Assert no null values in columns."""
    null_count = df.filter(
        reduce(lambda a, b: a | b, [col(c).isNull() for c in columns])
    ).count()

    return QualityCheck(
        name="all_not_null",
        passed=(null_count == 0),
        message=f"Found {null_count} null values in {columns}",
        count=null_count
    )

# Run checks
checks = [
    assert_no_duplicates(df, ["user_id"]),
    assert_all_not_null(df, ["email", "created_at"]),
]

failed_checks = [c for c in checks if not c.passed]
if failed_checks:
    for check in failed_checks:
        log.error(f"Quality check failed: {check.message}")
    raise ValueError(f"{len(failed_checks)} quality checks failed")
```

## Anomaly Detection

### Statistical Anomalies

**Detect outliers using statistics:**

```python
from pyspark.sql import functions as F

def detect_outliers(df, column: str, std_devs: float = 3):
    """Detect outliers using standard deviation."""
    # Calculate mean and stddev
    stats = df.select(
        F.mean(column).alias("mean"),
        F.stddev(column).alias("stddev")
    ).collect()[0]

    mean = stats["mean"]
    stddev = stats["stddev"]

    # Flag outliers
    outliers = (
        df
        .withColumn(
            "is_outlier",
            (col(column) < mean - std_devs * stddev) |
            (col(column) > mean + std_devs * stddev)
        )
    )

    outlier_count = outliers.filter(col("is_outlier")).count()

    if outlier_count > 0:
        log.warning(f"Found {outlier_count} outliers in {column}")

    return outliers
```

### Volume Anomalies

**Detect unexpected volume changes:**

```python
def detect_volume_anomaly(
    current_count: int,
    historical_mean: float,
    threshold: float = 0.2
):
    """Detect volume anomalies."""
    deviation = abs(current_count - historical_mean) / historical_mean

    if deviation > threshold:
        raise ValueError(
            f"Volume anomaly detected: {current_count} rows "
            f"(expected ~{historical_mean}, deviation {deviation:.1%})"
        )
```

### Pattern Anomalies

**Detect unexpected patterns:**

```python
def detect_pattern_anomaly(df):
    """Detect unusual patterns in data."""
    # Check distribution of categorical column
    status_dist = (
        df
        .groupBy("status")
        .count()
        .withColumn("pct", col("count") / df.count())
        .collect()
    )

    # Alert if unexpected distribution
    for row in status_dist:
        if row["status"] == "error" and row["pct"] > 0.01:
            raise ValueError(
                f"High error rate: {row['pct']:.1%} (expected <1%)"
            )
```

## Quality Metrics

### Calculating Metrics

**Calculate quality metrics during validation:**

```python
def calculate_quality_metrics(df):
    """Calculate quality metrics for current run."""
    total_rows = df.count()

    metrics = {
        "total_rows": total_rows,
        "null_email_pct": df.filter(col("email").isNull()).count() / total_rows,
        "duplicate_pct": (total_rows - df.dropDuplicates(["user_id"]).count()) / total_rows,
        "invalid_email_pct": df.filter(~col("email").contains("@")).count() / total_rows,
        "timestamp": datetime.now()
    }

    # Emit metrics as structured logs
    log.info("quality_metrics", **metrics)

    return metrics
```

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
