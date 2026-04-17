# Data Modeling

Data modeling principles, schema design, and database selection.

## Modeling Approach

### For Operational Systems (OLTP)

**Event-first for auditability.**

Operational databases should:
- Store facts as events (append-only)
- Use 3NF for transactional data
- Maintain current state tables alongside event logs

### For Analytical Systems (OLAP)

**Design Domain layer for consumption patterns.**

Analytical models should:
- Structured layer: Type-2 SCD business entities
- Domain layer: Structure varies by use case (wide tables, aggregates, feature tables)
- Let consumption patterns drive structure

## Normalization vs Denormalization

### When to Normalize

**Relational databases (OLTP):**
- Normalize for transactional workloads
- Third normal form (3NF) as default
- Prevents update anomalies
- Reduces data redundancy
- Easier to maintain consistency

**Benefits:**
- Update user name once, reflects everywhere
- No duplicate address data
- Clear data relationships

**Trade-offs:**
- More joins for queries
- Slightly slower reads
- Risk of losing history (e.g., user changes email, old value is lost) - hence preference for Type-2 SCD or audit events table depending on use case

### When to Denormalize

**Data warehouses (OLAP) - Domain layer:**
- Denormalize for analytical workloads
- Wide tables, aggregates, or custom structures
- Optimize for read performance
- Pre-compute common joins
- Let consumption patterns drive structure

**Benefits:**
- Fewer joins (faster queries)
- Optimized for specific use case
- Simple for analysts to query

**Trade-offs:**
- Data duplication
- Update complexity
- More storage

**Guideline:** Normalize in OLTP systems, denormalize in OLAP systems.

## Relational vs Graph Databases

### Use Relational When

**Data fits naturally into tables:**
- Entities with consistent attributes
- Straightforward relationships
- Fixed schema

**Queries are straightforward:**
- Simple joins (1-3 levels)
- Filtering and aggregation
- Standard CRUD operations

**Strong ACID guarantees needed:**
- Financial transactions
- Inventory management
- Order processing

### Use Graph When

**Relationships are first-class citizens:**
- Relationships have properties
- Multiple relationship types between entities
- Relationships are the primary focus

**Traversing connections is core functionality:**
- Multi-hop queries (friends of friends)
- Variable depth traversals
- Path finding algorithms

**Query depth is variable or unknown:**
- "All users connected within 3 degrees"
- "Shortest path between entities"
- "All downstream dependencies"

**Pattern matching across relationships:**
- Recommendation engines
- Fraud detection
- Knowledge graphs

### Graph Capabilities Impossible in Relational

**Graph databases unlock:**

1. **Multi-hop relationship queries** - Variable depth traversals across any number of hops
2. **Shortest path algorithms** - Find optimal paths between entities
3. **Community detection** - Identify clusters of related entities
4. **Recommendation engines** - Collaborative filtering across relationship networks

**Graph thinking changes how you model:**
- Relationships become first-class entities
- Traversals replace joins
- Pattern matching replaces complex SQL

## Schema Design

### Naming Conventions

**SQL naming conventions:**

- Tables: lowercase, plural, snake_case (`users`, `order_items`)
- Columns: lowercase, snake_case (`user_id`, `created_at`)
- Primary keys: `{table_singular}_id` (`user_id`, `order_id`)
- Foreign keys: `{referenced_table_singular}_id` (matches referenced PK)
- Timestamps: `_at` suffix (`created_at`, `updated_at`)
- Dates: `_date` suffix (`birth_date`, `expected_delivery_date`)
- Booleans: `is_` prefix (`is_active`, `is_verified`)

### Essential Timestamps

**Always add created_at and updated_at.**

**Why timestamps matter:**
- Debugging (when was this record created?)
- Auditing (track changes over time)
- Analytics (temporal analysis)
- Incremental processing (load only new records)

### Indexing Strategy

**Index strategically for common queries:**
- Foreign keys (always index)
- Frequent filter columns
- Sort columns
- Composite indexes for common query patterns

**Index considerations:**
- Every index speeds reads but slows writes
- More indexes = more storage
- Index columns in WHERE, JOIN, ORDER BY
- Composite indexes: put high-cardinality columns first
- Monitor query performance and add indexes as needed

### Constraints

**Enforce data integrity at database level:**
- Primary keys
- Foreign keys
- Unique constraints
- Check constraints
- Not null constraints

**Benefits:**
- Prevent invalid data at source
- Self-documenting schema
- Catch bugs early

## Entity Relationships

### One-to-One

**Rare, usually indicates separate concerns.**

**When to use:**
- Separate frequently vs rarely accessed data
- Different security requirements
- Optional extensions

### One-to-Many

**Most common relationship** - one parent entity to many child entities.

### Many-to-Many

**Use junction table** to connect two entities with a many-to-many relationship.

**Junction table benefits:**
- Can add relationship metadata (enrolled_at)
- Enforce uniqueness
- Query efficiently both directions

## Tracking History

### OLTP Pattern: Current State + Events

**For operational databases, separate current state from history:**
- Maintain current state table for fast operational queries
- Maintain separate events table as append-only audit trail
- Update both within same transaction

**Benefits:**
- Fast operational queries (no `is_current` filter)
- Complete audit trail
- Analysts transform events into Type-2 SCD in warehouse

### OLAP Pattern: Type-2 SCD from Events

**For analytical systems, transform events into Type-2 SCD:**
- Read events from cleaned layer
- Window functions to create active_from/active_to date ranges
- Mark current records with is_current flag
- Materialize as Type-2 SCD table in structured layer

**Benefits:**
- Events are the source of truth
- Can reprocess if business logic changes
- Natural fit for event-first architecture
- Optimized for analytical queries with history

### Type-2 SCD Querying

**Query patterns:**
- **Current state:** Filter on `is_current = true`
- **Historical state:** Filter on date range using active_from/active_to
- **All history:** Query all records for entity ordered by active_from

---

**Last Updated**: 2026-03-24
