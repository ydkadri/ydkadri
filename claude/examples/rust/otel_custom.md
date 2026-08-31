# Custom OpenTelemetry Spans and Metrics (Rust)

## Custom Spans with Tracing

### Basic Span

```rust
use tracing::{info, instrument, span, Level};

#[instrument(fields(user_id = %user_id, data_size = data.len()))]
fn process_data(user_id: u64, data: &[u8]) -> Vec<u8> {
    info!("Processing data");
    let result = process(data);
    info!(result_count = result.len(), "Processing complete");
    result
}
```

### Manual Span Creation

```rust
use tracing::span;

fn process_order(order_id: u64) {
    let span = span!(Level::INFO, "process_order", order_id = %order_id);
    let _enter = span.enter();

    // Work happens in span context
    validate_order(order_id);
    fulfill_order(order_id);
}
```

### Nested Spans

```rust
#[instrument]
fn batch_process(items: &[Item]) {
    for item in items {
        let span = span!(Level::INFO, "process_item", item_id = %item.id);
        let _enter = span.enter();

        process_item(item);
    }
}
```

### Span Events and Attributes

```rust
use tracing::{event, Level};

#[instrument]
async fn fetch_data(url: &str) -> Result<String, Error> {
    event!(Level::INFO, "Starting request");

    let response = reqwest::get(url).await?;

    event!(
        Level::INFO,
        status_code = response.status().as_u16(),
        "Request completed"
    );

    Ok(response.text().await?)
}
```

### Error Recording

```rust
#[instrument(err)]
async fn database_query(query: &str) -> Result<Vec<Row>, DatabaseError> {
    match execute_query(query).await {
        Ok(rows) => {
            event!(Level::INFO, row_count = rows.len(), "Query successful");
            Ok(rows)
        }
        Err(e) => {
            event!(Level::ERROR, error = %e, "Query failed");
            Err(e)
        }
    }
}
```

## Custom Metrics

### Counter

```rust
use opentelemetry::{global, KeyValue};

fn track_request(method: &str, endpoint: &str) {
    let meter = global::meter("my-service");

    let counter = meter
        .u64_counter("http_requests_total")
        .with_description("Total HTTP requests")
        .init();

    counter.add(
        1,
        &[
            KeyValue::new("method", method.to_string()),
            KeyValue::new("endpoint", endpoint.to_string()),
        ],
    );
}
```

### Histogram

```rust
use std::time::Instant;

fn record_latency(duration: f64, method: &str) {
    let meter = global::meter("my-service");

    let histogram = meter
        .f64_histogram("http_request_duration_seconds")
        .with_description("HTTP request duration")
        .init();

    histogram.record(
        duration,
        &[KeyValue::new("method", method.to_string())],
    );
}

// Usage
let start = Instant::now();
handle_request();
let duration = start.elapsed().as_secs_f64();
record_latency(duration, "POST");
```

### Gauge (Observable)

```rust
use opentelemetry::metrics::Observer;

fn setup_memory_gauge() {
    let meter = global::meter("my-service");

    let _gauge = meter
        .f64_observable_gauge("system_memory_usage_percent")
        .with_description("System memory usage")
        .with_callback(|observer: &Observer<f64>| {
            let memory_usage = get_memory_usage();
            observer.observe(memory_usage, &[]);
        })
        .init();
}

fn get_memory_usage() -> f64 {
    // Implementation to get memory usage
    42.0
}
```

### UpDownCounter

```rust
struct ConnectionTracker {
    counter: opentelemetry::metrics::UpDownCounter<i64>,
}

impl ConnectionTracker {
    fn new() -> Self {
        let meter = global::meter("my-service");
        let counter = meter
            .i64_up_down_counter("active_connections")
            .with_description("Number of active connections")
            .init();

        Self { counter }
    }

    fn connection_opened(&self, conn_type: &str) {
        self.counter.add(1, &[KeyValue::new("type", conn_type.to_string())]);
    }

    fn connection_closed(&self, conn_type: &str) {
        self.counter.add(-1, &[KeyValue::new("type", conn_type.to_string())]);
    }
}
```

## Async Context Propagation

```rust
use tracing::Instrument;

async fn handle_request(request: Request) {
    let span = span!(Level::INFO, "handle_request", request_id = %request.id());

    async {
        fetch_data().await;
        process_data().await;
    }
    .instrument(span)
    .await
}
```

## Axum Integration

```rust
use axum::{
    extract::Request,
    middleware::{self, Next},
    response::Response,
};

async fn trace_middleware(req: Request, next: Next) -> Response {
    let span = span!(
        Level::INFO,
        "http_request",
        method = %req.method(),
        uri = %req.uri(),
    );

    async {
        let response = next.run(req).await;
        event!(Level::INFO, status = %response.status(), "Request completed");
        response
    }
    .instrument(span)
    .await
}

// Add to router
let app = Router::new()
    .route("/", get(handler))
    .layer(middleware::from_fn(trace_middleware));
```
