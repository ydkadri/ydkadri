# Data Modeling

Data modeling principles, schema design, and database selection.

## Choosing Data Stores

### OLTP (Online Transaction Processing)

**For operational application databases.**

- Normalized schemas (3NF)
- Write-optimized
- ACID transactions
- Row-oriented storage
- Use: Application databases, transactional systems
- Example: PostgreSQL, MySQL

**Key characteristics:**
- Event-first with append-only facts
- Type-2 SCDs for dimension tracking
- Strong consistency requirements

### OLAP (Online Analytical Processing)

**For analytical data warehouses.**

- Denormalized schemas
- Read-optimized
- Eventual consistency acceptable
- Columnar storage
- Use: Data warehouses, analytics
- Example: Databricks, Snowflake, BigQuery

**Key characteristics:**
- Four-layer architecture (Landing/Cleaned/Structured/Domain)
- Optimized for aggregations and complex queries
- Historical analysis

### Event Streaming

**For real-time event processing.**

- Append-only logs
- Time-ordered events
- Immutable records
- Use: Real-time processing, audit trails, pub/sub architectures
- Example: Kafka, Kinesis

**Key characteristics:**
- Services produce events
- Consumers decide their own patterns
- Events land in warehouse for historical analysis

### Graph Databases

**When relationships are central.**

- Relationships as first-class citizens
- Traversal-optimized
- Pattern matching
- Use: Social networks, knowledge graphs, recommendations
- Example: Neo4j

**Key characteristics:**
- Variable-depth traversals
- Path finding
- Pattern matching across relationships

See `data/databases/neo4j.md` for detailed graph modeling patterns.

## Modeling Approach

### For Operational Systems (OLTP)

**Event-first with Type-2 SCDs.**

Operational databases should:
- Store facts as events (append-only)
- Use 3NF for transactional data
- Track dimension changes with Type-2 SCDs

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

**Example: Normalized schema**

```sql
create table users (
    user_id bigint primary key
    , email varchar(255) not null unique
    , name varchar(255) not null
);

create table addresses (
    address_id bigint primary key
    , user_id bigint not null references users(user_id)
    , street varchar(255) not null
    , city varchar(100) not null
    , country varchar(100) not null
);

create table orders (
    order_id bigint primary key
    , user_id bigint not null references users(user_id)
    , shipping_address_id bigint references addresses(address_id)
    , created_at timestamp not null
);
```

**Benefits:**
- Update user name once, reflects everywhere
- No duplicate address data
- Clear data relationships

**Trade-offs:**
- More joins for queries
- Slightly slower reads

### When to Denormalize

**Data warehouses (OLAP) - Domain layer:**
- Denormalize for analytical workloads
- Wide tables, aggregates, or custom structures
- Optimize for read performance
- Pre-compute common joins
- Let consumption patterns drive structure

**Example: Denormalized schema**

```sql
create table order_facts (
    order_id bigint primary key
    , user_id bigint not null
    , user_email varchar(255) not null
    , user_name varchar(255) not null
    , shipping_street varchar(255) not null
    , shipping_city varchar(100) not null
    , shipping_country varchar(100) not null
    , created_at timestamp not null
    , total_amount decimal(10, 2) not null
);
```

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

**Example: E-commerce (relational makes sense)**

```sql
-- Simple joins, clear relationships
select
    usr.user_id
    , usr.email
    , ord.order_id
    , ord.total_amount
from users usr
inner join orders ord
  on usr.user_id = ord.user_id
where ord.created_at >= '2024-01-01';
```

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

**Example: Social network (graph makes sense)**

```cypher
// Find friends of friends who like the same movies
match (me:User {user_id: 123})-[:FRIENDS_WITH*1..2]-(friend:User)
match (friend)-[:LIKES]->(movie:Movie)
match (me)-[:LIKES]->(movie)
return distinct friend.name, count(movie) as shared_interests
order by shared_interests desc
limit 10;
```

**This query in SQL would be very complex or impossible.**

### Graph Capabilities Impossible in Relational

**Graph databases unlock:**

1. **Multi-hop relationship queries** - Variable depth traversals
   ```cypher
   // Find all transitive dependencies (any depth)
   match (pkg:Package {name: 'myapp'})-[:DEPENDS_ON*]->(dep:Package)
   return dep.name
   ```

2. **Shortest path algorithms**
   ```cypher
   // Shortest path between two users
   match path = shortestPath(
     (u1:User {email: 'alice@example.com'})-[:KNOWS*]-(u2:User {email: 'bob@example.com'})
   )
   return path
   ```

3. **Community detection**
   ```cypher
   // Find clusters of related entities
   call gds.louvain.stream('myGraph')
   yield nodeId, communityId
   return communityId, collect(nodeId) as members
   ```

4. **Recommendation engines**
   ```cypher
   // Collaborative filtering
   match (me:User {user_id: 123})-[:PURCHASED]->(p:Product)
   match (p)<-[:PURCHASED]-(other:User)
   match (other)-[:PURCHASED]->(rec:Product)
   where not (me)-[:PURCHASED]->(rec)
   return rec.name, count(*) as score
   order by score desc
   limit 10;
   ```

**Graph thinking changes how you model:**
- Relationships become first-class entities
- Traversals replace joins
- Pattern matching replaces complex SQL

## Schema Design

### Naming Conventions

**Follow SQL naming conventions (see `claude/languages/sql.md`):**

- Tables: lowercase, plural, snake_case (`users`, `order_items`)
- Columns: lowercase, snake_case (`user_id`, `created_at`)
- Primary keys: `{table_singular}_id` (`user_id`, `order_id`)
- Foreign keys: `{referenced_table_singular}_id` (matches referenced PK)
- Timestamps: `_at` suffix (`created_at`, `updated_at`)
- Dates: `_date` suffix (`birth_date`, `expected_delivery_date`)
- Booleans: `is_` prefix (`is_active`, `is_verified`)

### Essential Timestamps

**Always add created_at and updated_at:**

```sql
create table users (
    user_id bigint primary key
    , email varchar(255) not null
    , created_at timestamp not null default current_timestamp
    , updated_at timestamp not null default current_timestamp
);

-- Update trigger for updated_at (PostgreSQL)
create trigger update_users_updated_at
before update on users
for each row
execute function update_updated_at_column();
```

**Why timestamps matter:**
- Debugging (when was this record created?)
- Auditing (track changes over time)
- Analytics (temporal analysis)
- Incremental processing (load only new records)

### Indexing Strategy

**Index strategically for common queries:**

```sql
-- Foreign keys (always index)
create index orders_user_id_idx on orders(user_id);

-- Frequent filters
create index users_email_idx on users(email);
create index orders_status_idx on orders(status);

-- Sort columns
create index orders_created_idx on orders(created_at);

-- Composite indexes for common query patterns
create index orders_user_created_idx on orders(user_id, created_at);
```

**Index considerations:**
- Every index speeds reads but slows writes
- More indexes = more storage
- Index columns in WHERE, JOIN, ORDER BY
- Composite indexes: put high-cardinality columns first
- Monitor query performance and add indexes as needed

### Constraints

**Enforce data integrity at database level:**

```sql
-- Primary key
create table users (
    user_id bigint primary key
);

-- Foreign key
create table orders (
    order_id bigint primary key
    , user_id bigint not null references users(user_id)
);

-- Unique constraint
alter table users
add constraint users_email_unique
    unique (email);

-- Check constraint
alter table orders
add constraint orders_positive_total
    check (total_amount > 0);

-- Not null
alter table users
alter column email set not null;
```

**Benefits:**
- Prevent invalid data at source
- Self-documenting schema
- Catch bugs early

## Entity Relationships

### One-to-One

**Rare, usually indicates separate concerns:**

```sql
create table users (
    user_id bigint primary key
    , email varchar(255) not null
);

create table user_profiles (
    user_id bigint primary key references users(user_id)
    , bio text
    , avatar_url varchar(500)
);
```

**When to use:**
- Separate frequently vs rarely accessed data
- Different security requirements
- Optional extensions

### One-to-Many

**Most common relationship:**

```sql
create table users (
    user_id bigint primary key
    , email varchar(255) not null
);

create table orders (
    order_id bigint primary key
    , user_id bigint not null references users(user_id)
    , created_at timestamp not null
);
```

### Many-to-Many

**Use junction table:**

```sql
create table students (
    student_id bigint primary key
    , name varchar(255) not null
);

create table courses (
    course_id bigint primary key
    , name varchar(255) not null
);

create table enrollments (
    enrollment_id bigint primary key
    , student_id bigint not null references students(student_id)
    , course_id bigint not null references courses(course_id)
    , enrolled_at timestamp not null
    , unique (student_id, course_id)
);
```

**Junction table benefits:**
- Can add relationship metadata (enrolled_at)
- Enforce uniqueness
- Query efficiently both directions

## Tracking History

### OLTP Pattern: Current State + Events

**For operational databases, separate current state from history:**

```sql
-- Current state table - fast operational queries
create table users (
    user_id bigint primary key
    , email varchar(255) not null
    , name varchar(255) not null
    , created_at timestamp not null
    , updated_at timestamp not null
);

-- Events table - append-only audit trail
create table user_events (
    event_id bigint primary key
    , user_id bigint not null
    , event_type varchar(50) not null  -- 'user_created', 'user_updated', etc.
    , email varchar(255)
    , name varchar(255)
    , created_at timestamp not null
);

-- Update current state, log event
begin;
    update users
    set email = 'newemail@example.com'
        , updated_at = current_timestamp
    where user_id = 123;

    insert into user_events (user_id, event_type, email, created_at)
    values (123, 'user_updated', 'newemail@example.com', current_timestamp);
commit;
```

**Benefits:**
- Fast operational queries (no `is_current` filter)
- Complete audit trail
- Analysts transform events into Type-2 SCD in warehouse

### OLAP Pattern: Type-2 SCD from Events

**For analytical systems, transform events into Type-2 SCD:**

```python
# Structured layer: Build Type-2 SCD from events
from pyspark.sql import Window
from pyspark.sql.functions import col, lead

cleaned_events = spark.read.format("delta").load("/cleaned/app/user_events")

users_scd = (
    cleaned_events
    .filter(col("event_type").isin(["user_created", "user_updated"]))
    .withColumn("active_from", col("created_at"))
    .withColumn("active_to", lead("created_at").over(
        Window.partitionBy("user_id").orderBy("created_at")
    ))
    .withColumn("is_current", col("active_to").isNull())
    .select(
        "user_id",
        "email",
        "name",
        "active_from",
        "active_to",
        "is_current"
    )
)

# Materialize as Type-2 SCD table in Structured layer
users_scd.write.format("delta").mode("overwrite").save("/structured/users")
```

**Benefits:**
- Events are the source of truth
- Can reprocess if business logic changes
- Natural fit for event-first architecture
- Optimized for analytical queries with history

### Type-2 SCD Querying

**Current state:**
```sql
select * from structured.users where is_current = true;
```

**Historical state:**
```sql
select *
from structured.users
where user_id = 123
  and active_from <= '2024-01-01'
  and (active_to > '2024-01-01' or active_to is null);
```

**All history:**
```sql
select * from structured.users where user_id = 123 order by active_from;
```

---

**Last Updated**: 2026-03-24
