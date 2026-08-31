# Custom OpenTelemetry Spans and Metrics (Python)

## Custom Spans

### Basic Span

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("process_data") as span:
    span.set_attribute("user_id", user_id)
    span.set_attribute("data_size", len(data))

    result = process(data)

    span.set_attribute("result_count", len(result))
    return result
```

### Nested Spans

```python
with tracer.start_as_current_span("parent_operation") as parent:
    parent.set_attribute("operation_type", "batch")

    for item in items:
        with tracer.start_as_current_span("process_item") as child:
            child.set_attribute("item_id", item.id)
            process_item(item)
```

### Span Events and Status

```python
from opentelemetry.trace import Status, StatusCode

with tracer.start_as_current_span("database_query") as span:
    span.add_event("Query started", {"query_id": query_id})

    try:
        result = execute_query(query)
        span.add_event("Query completed", {"rows": len(result)})
        span.set_status(Status(StatusCode.OK))
        return result
    except Exception as e:
        span.add_event("Query failed", {"error": str(e)})
        span.set_status(Status(StatusCode.ERROR, str(e)))
        span.record_exception(e)
        raise
```

### Async Spans

```python
async def fetch_data(user_id: int):
    with tracer.start_as_current_span("fetch_data") as span:
        span.set_attribute("user_id", user_id)

        async with httpx.AsyncClient() as client:
            response = await client.get(f"/api/users/{user_id}")
            span.set_attribute("status_code", response.status_code)
            return response.json()
```

## Custom Metrics

### Counter

```python
from opentelemetry import metrics

meter = metrics.get_meter(__name__)

# Create counter
requests_counter = meter.create_counter(
    "http_requests_total",
    description="Total HTTP requests",
    unit="1",
)

# Increment counter
requests_counter.add(1, {"method": "GET", "endpoint": "/api/users"})
```

### Histogram

```python
# Create histogram for latency
request_duration = meter.create_histogram(
    "http_request_duration_seconds",
    description="HTTP request duration",
    unit="s",
)

# Record value
import time
start = time.time()
handle_request()
duration = time.time() - start

request_duration.record(duration, {"method": "POST", "endpoint": "/api/data"})
```

### Gauge (Observable)

```python
import psutil

def get_memory_usage():
    return psutil.virtual_memory().percent

# Create observable gauge
memory_gauge = meter.create_observable_gauge(
    "system_memory_usage_percent",
    callbacks=[lambda: [(get_memory_usage(), {})]],
    description="System memory usage",
    unit="%",
)
```

### UpDownCounter

```python
# Track active connections
active_connections = meter.create_up_down_counter(
    "active_connections",
    description="Number of active connections",
    unit="1",
)

# Increment when connection opens
active_connections.add(1, {"connection_type": "websocket"})

# Decrement when connection closes
active_connections.add(-1, {"connection_type": "websocket"})
```

## Decorator Pattern

```python
from functools import wraps

def traced(span_name: str = None):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            name = span_name or f"{func.__module__}.{func.__name__}"
            with tracer.start_as_current_span(name) as span:
                span.set_attribute("function", func.__name__)
                try:
                    result = func(*args, **kwargs)
                    span.set_status(Status(StatusCode.OK))
                    return result
                except Exception as e:
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise
        return wrapper
    return decorator

@traced("process_order")
def process_order(order_id: int):
    # Function implementation
    pass
```

## Context Propagation

```python
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

# Extract context from incoming request
propagator = TraceContextTextMapPropagator()
context = propagator.extract(carrier=request.headers)

# Use context for child span
with tracer.start_as_current_span("handle_request", context=context) as span:
    handle_request()

# Inject context into outgoing request
headers = {}
propagator.inject(headers)
response = requests.get(url, headers=headers)
```
