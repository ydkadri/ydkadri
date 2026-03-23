# SQL Style Guide

SQL code style and patterns.

## Query Formatting

### Capitalization

**All lowercase - keywords and identifiers:**

```sql
-- ✅ CORRECT
select
    user_id
    , email
    , created_at
from users
where status = 'active'
order by created_at desc;

-- ❌ INCORRECT - Mixed case
SELECT USER_ID, Email, Created_At
FROM Users
WHERE STATUS = 'active';
```

### Commas

**Use leading commas:**

```sql
-- ✅ CORRECT - Leading commas
select
    user_id
    , email
    , created_at
    , status
from users;

-- ❌ INCORRECT - Trailing commas
select
    user_id,
    email,
    created_at,
    status
from users;
```

Leading commas make it easier to:
- Comment out the first line
- Spot missing commas
- Add/remove lines cleanly

### Indentation and Line Length

**Use 4 spaces for indentation, 80 character maximum line length:**

```sql
-- ✅ CORRECT - Readable structure with proper alignment
select
    usr.user_id
    , usr.email
    , usr.created_at
    , count(ord.order_id) as order_count
from users usr
left outer join orders ord
  on usr.user_id = ord.user_id
where usr.status = 'active'
  and usr.created_at >= '2024-01-01'
group by 1, 2, 3
having count(ord.order_id) > 0
order by 4 desc
limit 100;

-- ❌ INCORRECT - Single line, unreadable
select usr.user_id, usr.email, usr.created_at, count(ord.order_id) as order_count from users usr left join orders ord on usr.user_id = ord.user_id where usr.status = 'active' and usr.created_at >= '2024-01-01' group by usr.user_id, usr.email, usr.created_at having count(ord.order_id) > 0 order by order_count desc limit 100;
```

### Alignment

**Select columns:** 4-space indent with leading comma

**Conditions (where/on/having):** Align to end of keyword

```sql
-- ✅ CORRECT
select
    user_id
    , email
    , status
from users
where status = 'active'
  and email_verified = true
  and created_at >= '2024-01-01';

-- Complex conditions
where (status = 'active' and email_verified = true)
   or (status = 'trial' and trial_expires_at > current_timestamp);
```

## Naming Conventions

### Tables

**Lowercase, plural nouns, snake_case:**

```sql
-- ✅ CORRECT
create table users (...);
create table order_items (...);
create table api_tokens (...);

-- ❌ INCORRECT
create table User (...);
create table OrderItem (...);
create table APITokens (...);
```

### Columns

**Lowercase, snake_case, descriptive with consistent suffixes and prefixes:**

**Suffixes:**
- `_id` for primary and foreign keys (e.g., `user_id`, `order_id`)
- `_at` for timestamps (e.g., `created_at`, `delivered_at`)
- `_date` for dates (e.g., `expected_delivery_date`, `birth_date`)

**Prefixes:**
- `is_` for booleans (e.g., `is_email_verified`, `is_active`)

```sql
-- ✅ CORRECT
create table users (
    user_id bigint primary key
    , email varchar(255) not null
    , created_at timestamp not null
    , updated_at timestamp not null
    , birth_date date
    , is_email_verified boolean default false
    , is_active boolean default true
);

create table orders (
    order_id bigint primary key
    , user_id bigint not null
    , expected_delivery_date date
    , delivered_at timestamp
    , is_paid boolean default false
);

-- ❌ INCORRECT
create table users (
    UserID bigint primary key
    , Email varchar(255) not null
    , createdAt timestamp not null
    , UpdatedAt timestamp not null
    , birthdate date
    , emailVerified boolean default false
    , active boolean default true
);
```

### Primary Keys

**Use `{table_singular}_id` pattern:**

Examples:
- `users` table → `user_id`
- `order_items` table → `order_item_id`
- `user_details` table → `user_detail_id`

Exception: Use `id` only when idiomatic (e.g., Django models).

```sql
-- ✅ CORRECT
create table users (
    user_id bigint primary key
);

create table order_items (
    order_item_id bigint primary key
    , order_id bigint references orders(order_id)
);

-- ❌ INCORRECT
create table users (
    id bigint primary key  -- Ambiguous in joins
);
```

### Foreign Keys

**Use `{referenced_table_singular}_id` pattern - must match the referenced primary key:**

```sql
-- ✅ CORRECT - Foreign key name matches referenced primary key
create table orders (
    order_id bigint primary key
    , user_id bigint references users(user_id)
);

-- ❌ INCORRECT
create table orders (
    order_id bigint primary key
    , user bigint references users(user_id)  -- Unclear that it's an ID
    , customer_id bigint references users(user_id)  -- Doesn't match referenced key name
);
```

### Constraints

**Use semantic names for complex constraints:**

For simple constraints, descriptive patterns work:
```sql
-- Foreign keys
alter table orders
add constraint orders_user_fkey
    foreign key (user_id) references users(user_id);

-- Unique constraints
alter table users
add constraint users_email_unique
    unique (email);

-- Check constraints
alter table orders
add constraint orders_positive_total
    check (total_amount > 0);
```

For composite constraints, use semantic names:
```sql
-- ✅ Semantic name describes the business rule
alter table orders
add constraint orders_valid_status_dates
    check (
        (status = 'completed' and completed_at is not null)
        or (status != 'completed' and completed_at is null)
    );
```

### Indexes

**Use semantic names for complex indexes:**

Simple indexes can be descriptive:
```sql
-- ✅ CORRECT
create index users_email_idx on users(email);
create index orders_created_idx on orders(created_at);
create index users_email_lower_idx on users(lower(email));
```

Complex indexes should have semantic names:
```sql
-- ✅ CORRECT - Semantic name describes purpose
create index orders_active_user_timeline_idx
    on orders(user_id, status, created_at, payment_method)
    where status = 'active';

-- ❌ INCORRECT - Generic or overly long name
create index orders_user_id_status_created_at_payment_method_idx
    on orders(user_id, status, created_at, payment_method);
```

## Query Patterns

### CTEs over Subqueries

**Prefer CTEs for clarity and reusability.**

CTEs make queries more readable and maintainable:

```sql
-- ✅ CORRECT - Clear, readable
with active_users as (
    select
        user_id
        , email
    from users
    where status = 'active'
      and email_verified = true
),
user_orders as (
    select
        user_id
        , count(*) as order_count
        , sum(total_amount) as total_spent
    from orders
    where created_at >= '2024-01-01'
    group by 1
)
select
    usr.user_id
    , usr.email
    , coalesce(ord.order_count, 0) as order_count
    , coalesce(ord.total_spent, 0) as total_spent
from active_users usr
left outer join user_orders ord
  on usr.user_id = ord.user_id
order by 4 desc;

-- ❌ AVOID - Nested subqueries
select
    usr.user_id
    , usr.email
    , coalesce(ord.order_count, 0)
    , coalesce(ord.total_spent, 0)
from (
    select user_id, email
    from users
    where status = 'active' and email_verified = true
) usr
left outer join (
    select
        user_id
        , count(*) as order_count
        , sum(total_amount) as total_spent
    from orders
    where created_at >= '2024-01-01'
    group by user_id
) ord on usr.user_id = ord.user_id;
```

### CTE Guidelines

**Structure CTEs for clarity and maintainability:**

1. **Descriptive names** - Name CTEs after what they produce:
   - `active_users` not `users_filtered`
   - `user_order_counts` not `aggregated_data`

2. **Single logical transformation** - Each CTE does one thing:
   ```sql
   with active_users as (
       -- Filter to active users
       select user_id, email
       from users
       where status = 'active'
   ),
   user_orders as (
       -- Aggregate orders per user
       select
           user_id
           , count(*) as order_count
       from orders
       group by 1
   )
   -- Join results
   select usr.*, ord.order_count
   from active_users usr
   left outer join user_orders ord
     on usr.user_id = ord.user_id;
   ```

3. **Aggregate before joining** - Reduce dataset size early:
   ```sql
   -- ✅ CORRECT - Aggregate first, then join
   with user_order_counts as (
       select
           user_id
           , count(*) as order_count
       from orders
       group by 1
   )
   select
       usr.user_id
       , usr.email
       , ord.order_count
   from users usr
   left outer join user_order_counts ord
     on usr.user_id = ord.user_id;

   -- ❌ AVOID - Join then aggregate (slower)
   select
       usr.user_id
       , usr.email
       , count(ord.order_id) as order_count
   from users usr
   left outer join orders ord
     on usr.user_id = ord.user_id
   group by 1, 2;
   ```

### Explicit JOINs

**Always use explicit JOIN syntax and specify join type:**

Use `inner join`, `left outer join`, `right outer join`, `full outer join`.

```sql
-- ✅ CORRECT
select
    usr.user_id
    , usr.email
    , ord.order_id
    , ord.total_amount
from users usr
inner join orders ord
  on usr.user_id = ord.user_id
where usr.status = 'active';

-- ❌ INCORRECT - Implicit joins
select
    usr.user_id
    , usr.email
    , ord.order_id
    , ord.total_amount
from users usr, orders ord
where usr.user_id = ord.user_id
  and usr.status = 'active';
```

### Table Aliases

**Use 3-character contractions:**

```sql
-- ✅ CORRECT
select
    usr.user_id
    , usr.email
    , ord.order_id
    , itm.product_id
    , itm.quantity
from users usr
inner join orders ord
  on usr.user_id = ord.user_id
inner join order_items itm
  on ord.order_id = itm.order_id;
```

**For similar table names, use the unrelated part:**
```sql
-- ✅ CORRECT - Distinguish related tables
select
    ord.order_id
    , itm.product_id
    , sta.status_name
from orders ord
inner join order_items itm
  on ord.order_id = itm.order_id
inner join order_status sta
  on ord.status_id = sta.status_id;
```

### GROUP BY and ORDER BY

**Use positional references:**

```sql
-- ✅ CORRECT
select
    usr.user_id
    , usr.email
    , count(ord.order_id) as order_count
from users usr
left outer join orders ord
  on usr.user_id = ord.user_id
group by 1, 2
order by 3 desc;
```

**List grouped columns first in select:**
```sql
-- ✅ CORRECT - Grouped columns first
select
    user_id
    , status
    , count(*) as user_count
    , sum(total_spent) as total_revenue
from users
group by 1, 2;

-- ❌ INCORRECT - Aggregates mixed with grouped columns
select
    count(*) as user_count
    , user_id
    , sum(total_spent) as total_revenue
    , status
from users
group by 2, 4;  -- Hard to understand which columns are grouped
```

**Avoid long group by lists - refactor into CTEs:**
```sql
-- ❌ AVOID - Too many grouped columns
select
    region
    , country
    , state
    , city
    , category
    , subcategory
    , product_type
    , count(*) as sale_count
from sales
group by 1, 2, 3, 4, 5, 6, 7;

-- ✅ CORRECT - Use CTE to separate grouping logic
with regional_products as (
    select
        region
        , country
        , state
        , city
        , category
        , subcategory
        , product_type
    from sales
    group by 1, 2, 3, 4, 5, 6, 7
)
select
    reg.region
    , count(*) as unique_combinations
from regional_products reg
group by 1;
```

### UNION

**Prefer `union all` over `union`:**

```sql
-- ✅ CORRECT - union all (no deduplication)
select user_id, email from active_users
union all
select user_id, email from inactive_users;

-- Only use union when you need to remove duplicates
select user_id from orders
union
select user_id from refunds;
```

### Window Functions

**Window functions vs GROUP BY serve different purposes.**

Window functions keep all rows while adding calculated context:

```sql
-- Window function - keeps all order rows
select
    user_id
    , order_id
    , total_amount
    , row_number() over (
        partition by user_id
        order by created_at desc
    ) as order_rank
    , sum(total_amount) over (
        partition by user_id
    ) as user_total_spent
from orders
where created_at >= '2024-01-01';
```

GROUP BY reduces rows to aggregates:

```sql
-- GROUP BY - one row per user
select
    user_id
    , count(*) as order_count
    , sum(total_amount) as total_spent
from orders
where created_at >= '2024-01-01'
group by 1;
```

## Safety

### Parameterized Queries

**Always use parameterized queries, never string concatenation:**

```python
# ✅ CORRECT - Python with psycopg2
cursor.execute(
    "select * from users where email = %s and status = %s",
    (email, status)
)

# ❌ INCORRECT - SQL injection vulnerability
cursor.execute(
    f"select * from users where email = '{email}' and status = '{status}'"
)
```

```rust
// ✅ CORRECT - Rust with sqlx
sqlx::query!(
    "select * from users where email = $1 and status = $2",
    email,
    status
)
.fetch_all(&pool)
.await?;

// ❌ INCORRECT - SQL injection vulnerability
let query = format!(
    "select * from users where email = '{}' and status = '{}'",
    email, status
);
```

### Input Validation

**Validate before querying:**

```python
# ✅ CORRECT
def get_user_by_email(email: str) -> User | None:
    """Get user by email address."""
    # Validate input
    if not email or "@" not in email:
        raise ValueError("Invalid email format")

    # Parameterized query
    cursor.execute(
        "select * from users where email = %s",
        (email,)
    )
    return cursor.fetchone()
```

### Least Privilege

**Use read-only connections for queries:**

```python
# ✅ CORRECT - Separate connections
readonly_conn = psycopg2.connect(
    host="replica.db.example.com",
    user="readonly_user",
    password=password,
)

readwrite_conn = psycopg2.connect(
    host="primary.db.example.com",
    user="app_user",
    password=password,
)

# Use readonly_conn for select queries
# Use readwrite_conn only when necessary
```

## Performance

### Indexing Strategy

**Index foreign keys, frequently filtered columns, and sort columns:**

```sql
-- ✅ CORRECT - Strategic indexes
create index orders_user_id_idx on orders(user_id);
create index orders_status_idx on orders(status);
create index orders_created_idx on orders(created_at);

-- Composite index for common query patterns
create index orders_user_created_idx on orders(user_id, created_at);

-- ❌ AVOID - Over-indexing
create index orders_every_column_idx on orders(
    order_id, user_id, status, created_at, updated_at, total_amount
);
```

### Avoid SELECT *

**Select only needed columns:**

```sql
-- ✅ CORRECT
select
    user_id
    , email
    , created_at
from users
where status = 'active';

-- ❌ INCORRECT - Fetches unnecessary data
select *
from users
where status = 'active';
```

### Limit Results

**Always use limit for potentially large result sets:**

```sql
-- ✅ CORRECT
select
    user_id
    , email
from users
order by created_at desc
limit 100;

-- ❌ AVOID - Could return millions of rows
select
    user_id
    , email
from users
order by created_at desc;
```

### EXPLAIN for Complex Queries

**Use explain to understand query plans:**

```sql
-- Check query performance
explain analyze
select
    usr.user_id
    , usr.email
    , count(ord.order_id) as order_count
from users usr
left outer join orders ord
  on usr.user_id = ord.user_id
where usr.status = 'active'
group by 1, 2
having count(ord.order_id) > 10;
```

### Batch Operations

**Use batch inserts/updates instead of individual operations:**

```python
# ✅ CORRECT - Batch insert
cursor.executemany(
    "insert into users (email, status) values (%s, %s)",
    [(email1, 'active'), (email2, 'active'), (email3, 'active')]
)

# ❌ INCORRECT - Individual inserts
for email in emails:
    cursor.execute(
        "insert into users (email, status) values (%s, %s)",
        (email, 'active')
    )
```

## Migrations

### Version Control

**All schema changes must be in migration files:**

- Use migration tool (Alembic, Flyway, sqlx-cli)
- Never modify database manually
- Migrations are sequential and immutable
- Include rollback logic

### Safe Migrations

**Make migrations backward compatible:**

```sql
-- ✅ CORRECT - Add column as nullable first
alter table users add column phone_number varchar(20);
-- Later migration can add not null after backfilling

-- ❌ RISKY - Adding not null immediately
alter table users add column phone_number varchar(20) not null;
```

### Data Migrations

**Separate schema and data migrations:**

```sql
-- Migration 001: Add column
alter table users add column email_verified boolean;

-- Migration 002: Backfill data
update users set email_verified = false where email_verified is null;

-- Migration 003: Add constraint
alter table users alter column email_verified set not null;
alter table users alter column email_verified set default false;
```

## Transactions

**Use transactions for multi-statement operations that must be atomic.**

Default isolation level is sufficient for most cases.

```python
# ✅ CORRECT - Transaction ensures atomicity
with conn:
    with conn.cursor() as cursor:
        cursor.execute(
            "insert into orders (user_id, total_amount) values (%s, %s) returning order_id",
            (user_id, total_amount)
        )
        order_id = cursor.fetchone()[0]

        cursor.executemany(
            "insert into order_items (order_id, product_id, quantity) values (%s, %s, %s)",
            [(order_id, product_id, qty) for product_id, qty in items]
        )
# Commits automatically on success, rolls back on error

# ❌ INCORRECT - No transaction
cursor.execute(
    "insert into orders (user_id, total_amount) values (%s, %s) returning order_id",
    (user_id, total_amount)
)
order_id = cursor.fetchone()[0]

cursor.executemany(
    "insert into order_items (order_id, product_id, quantity) values (%s, %s, %s)",
    [(order_id, product_id, qty) for product_id, qty in items]
)
# If second insert fails, order is left in inconsistent state
```

---

**Last Updated**: 2026-03-23
