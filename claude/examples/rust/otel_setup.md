# OpenTelemetry Setup (Rust)

## Dependencies

```toml
[dependencies]
opentelemetry = "0.21"
opentelemetry_sdk = { version = "0.21", features = ["rt-tokio"] }
opentelemetry-otlp = { version = "0.14", features = ["grpc-tonic"] }
tracing = "0.1"
tracing-subscriber = "0.3"
tracing-opentelemetry = "0.22"
```

## Basic Setup

```rust
use opentelemetry::{global, KeyValue};
use opentelemetry_sdk::{runtime, trace, Resource};
use opentelemetry_otlp::WithExportConfig;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

fn init_tracer() -> Result<(), Box<dyn std::error::Error>> {
    // Configure resource
    let resource = Resource::new(vec![
        KeyValue::new("service.name", "my-service"),
        KeyValue::new("environment", "production"),
        KeyValue::new("version", "1.0.0"),
    ]);

    // Setup OTLP exporter
    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint("http://localhost:4317"),
        )
        .with_trace_config(trace::config().with_resource(resource))
        .install_batch(runtime::Tokio)?;

    // Setup tracing subscriber
    tracing_subscriber::registry()
        .with(tracing_opentelemetry::layer().with_tracer(tracer))
        .with(tracing_subscriber::fmt::layer())
        .init();

    Ok(())
}
```

## Metrics Setup

```rust
use opentelemetry::metrics::MeterProvider as _;
use opentelemetry_sdk::metrics::reader::{DefaultAggregationSelector, DefaultTemporalitySelector};

fn init_metrics() -> Result<(), Box<dyn std::error::Error>> {
    let export_config = opentelemetry_otlp::ExportConfig {
        endpoint: "http://localhost:4317".to_string(),
        ..Default::default()
    };

    let meter_provider = opentelemetry_otlp::new_pipeline()
        .metrics(runtime::Tokio)
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_export_config(export_config),
        )
        .with_resource(resource)
        .with_period(std::time::Duration::from_secs(5))
        .with_aggregation_selector(DefaultAggregationSelector::new())
        .with_temporality_selector(DefaultTemporalitySelector::new())
        .build()?;

    global::set_meter_provider(meter_provider);

    Ok(())
}
```

## Complete Initialization

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize telemetry
    init_tracer()?;
    init_metrics()?;

    // Run application
    run_app().await?;

    // Shutdown providers
    global::shutdown_tracer_provider();

    Ok(())
}
```

## Environment Variables

```bash
export OTEL_SERVICE_NAME="my-service"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
export OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
```
