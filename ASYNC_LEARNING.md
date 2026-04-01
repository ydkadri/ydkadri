# Async and Threading Patterns Learning

**Status**: Experimental - Not yet committed to style guidelines

This document explores async and threading patterns in Python and Rust to help form opinions on best practices before committing to guidelines.

**Document Structure**:
- **Part 1: Async Patterns** - Python and Rust approaches to async I/O
- **Part 2: Threading Patterns** - Python and Rust approaches to concurrency and parallelism

---

# Part 1: Async Patterns

## When to Use Async vs Sync

### Use Async For: I/O-Bound Operations

Operations that **wait** for external resources (not CPU computation):

- ✅ API calls / HTTP requests
- ✅ Database queries
- ✅ File I/O (with async libraries)
- ✅ Network operations
- ✅ Running commands across multiple environments

**Why async helps**: While waiting for one I/O operation, the program can start others instead of blocking.

### Use Threads/Multiprocessing For: CPU-Bound Operations

Operations that **compute** (not waiting for I/O):

- ✅ Data processing / transformations
- ✅ Complex calculations
- ✅ Image/video processing
- ✅ Compression/encryption

**Why async doesn't help**: Python's GIL (Global Interpreter Lock) prevents true parallelism for CPU work. Use `multiprocessing` or threads instead.

### Quick Decision Tree

```
Is this waiting for I/O (network, disk, database)?
├─ Yes → Use async
└─ No → Is this CPU-intensive computation?
    ├─ Yes → Use multiprocessing
    └─ No → Use regular sync code (simplest)
```

## Python Async Basics

### Async/Await Syntax

```python
import asyncio
import httpx  # Async HTTP library

async def fetch_url(url: str) -> str:
    """Async function - can use 'await' inside."""
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.text

# Running async code
async def main() -> None:
    result = await fetch_url("https://api.example.com/data")
    print(result)

# Entry point
asyncio.run(main())
```

**Key concepts**:
- `async def`: Defines an async function (coroutine)
- `await`: Pauses this function, lets other async work run
- `asyncio.run()`: Starts the async runtime, runs until complete

### Common Mistake: Forgetting `await`

```python
# ❌ WRONG - Creates coroutine but doesn't run it
async def wrong_example() -> None:
    result = fetch_url("https://example.com")  # Returns coroutine object
    print(result)  # Prints "<coroutine object>" not the data

# ✅ CORRECT - Actually runs the async function
async def correct_example() -> None:
    result = await fetch_url("https://example.com")
    print(result)  # Prints the actual data
```

## Multi-Environment Command Execution

**Use case**: Run a command across multiple environments and report status.

```python
import asyncio
import subprocess
from dataclasses import dataclass

@dataclass
class CommandResult:
    environment: str
    status: str  # "passed", "failed", "running", "error"
    output: str
    error: str | None = None

async def run_command_in_env(
    environment: str,
    command: list[str],
) -> CommandResult:
    """Run command in one environment asynchronously."""
    try:
        # asyncio.create_subprocess_exec runs command without blocking
        process = await asyncio.create_subprocess_exec(
            *command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env={"ENVIRONMENT": environment},  # Pass env context
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            return CommandResult(
                environment=environment,
                status="passed",
                output=stdout.decode(),
            )
        else:
            return CommandResult(
                environment=environment,
                status="failed",
                output=stdout.decode(),
                error=stderr.decode(),
            )
    
    except Exception as e:
        return CommandResult(
            environment=environment,
            status="error",
            output="",
            error=str(e),
        )

async def run_across_environments(
    environments: list[str],
    command: list[str],
) -> list[CommandResult]:
    """Run command concurrently across all environments."""
    # Create all tasks at once
    tasks = [
        run_command_in_env(env, command)
        for env in environments
    ]
    
    # Run all concurrently, wait for all to complete
    results = await asyncio.gather(*tasks)
    
    return results

async def main() -> None:
    environments = [
        "client-1-prod",
        "client-2-prod",
        "client-3-prod",
    ]
    
    command = ["./scripts/health-check.sh"]
    
    print("Running health checks across environments...")
    results = await run_across_environments(environments, command)
    
    # Report results as they come in
    for result in results:
        print(f"{result.environment}: {result.status}")
        if result.error:
            print(f"  Error: {result.error}")

if __name__ == "__main__":
    asyncio.run(main())
```

**Key patterns**:
- `asyncio.create_subprocess_exec()`: Run subprocess without blocking
- `asyncio.gather(*tasks)`: Run multiple tasks concurrently, wait for all
- Each environment runs in parallel, total time = slowest command, not sum of all

### Progress Reporting (Bonus)

```python
async def run_across_environments_with_progress(
    environments: list[str],
    command: list[str],
) -> list[CommandResult]:
    """Run commands and report progress as they complete."""
    tasks = [
        run_command_in_env(env, command)
        for env in environments
    ]
    
    results = []
    
    # Process results as they complete (not in original order)
    for coro in asyncio.as_completed(tasks):
        result = await coro
        print(f"✓ {result.environment}: {result.status}")
        results.append(result)
    
    return results
```

**Difference**:
- `gather()`: Wait for all, then return results in order
- `as_completed()`: Process each result as soon as it finishes (faster feedback)

## Stream Processing

**Use case**: Process large files or data streams chunk by chunk without loading everything into memory.

### Async File Reading

```python
import aiofiles  # pip install aiofiles

async def process_large_file(file_path: str) -> int:
    """Process file line by line asynchronously."""
    line_count = 0
    
    async with aiofiles.open(file_path, mode="r") as file:
        async for line in file:
            # Process line (e.g., parse, transform, send to API)
            await process_line(line)
            line_count += 1
    
    return line_count

async def process_line(line: str) -> None:
    """Process a single line (example: send to API)."""
    # Simulate async work
    await asyncio.sleep(0.01)
```

### Async Generators (Streaming Data)

```python
from typing import AsyncIterator

async def fetch_paginated_data(base_url: str) -> AsyncIterator[dict]:
    """Stream paginated API results without loading all pages into memory."""
    page = 1
    
    async with httpx.AsyncClient() as client:
        while True:
            response = await client.get(f"{base_url}?page={page}")
            data = response.json()
            
            # Yield each item as we get it
            for item in data["items"]:
                yield item
            
            # Stop if no more pages
            if not data.get("has_next"):
                break
            
            page += 1

async def process_all_data() -> None:
    """Process streaming data chunk by chunk."""
    async for item in fetch_paginated_data("https://api.example.com/data"):
        # Process each item as it arrives
        await process_item(item)
        # Memory usage stays constant - only one item in memory at a time
```

**Key concepts**:
- `async for`: Iterate over async iterator
- `AsyncIterator`: Stream data one item at a time
- `yield`: Produce values on demand, not all at once

### Concurrent Stream Processing

```python
async def process_multiple_streams() -> None:
    """Process multiple data streams concurrently."""
    sources = [
        "https://api.example.com/users",
        "https://api.example.com/orders",
        "https://api.example.com/products",
    ]
    
    async def process_stream(url: str) -> int:
        count = 0
        async for item in fetch_paginated_data(url):
            await process_item(item)
            count += 1
        return count
    
    # Process all streams concurrently
    tasks = [process_stream(url) for url in sources]
    counts = await asyncio.gather(*tasks)
    
    print(f"Processed: {sum(counts)} total items")
```

## Common Async Patterns

### Pattern 1: Concurrent API Calls

```python
async def fetch_all_data(urls: list[str]) -> list[dict]:
    """Fetch multiple URLs concurrently."""
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
        return [r.json() for r in responses]

# Usage
async def main() -> None:
    urls = [
        "https://api.example.com/users/1",
        "https://api.example.com/users/2",
        "https://api.example.com/users/3",
    ]
    data = await fetch_all_data(urls)
```

**Performance**: 3 URLs fetched in ~same time as 1 (if network latency dominates).

### Pattern 2: Concurrent Database Queries

```python
import asyncpg  # Async PostgreSQL driver

async def fetch_user_data(user_id: int, pool: asyncpg.Pool) -> dict:
    """Fetch user and their orders concurrently."""
    async with pool.acquire() as conn:
        # Run multiple queries concurrently
        user_task = conn.fetchrow(
            "SELECT * FROM users WHERE id = $1", user_id
        )
        orders_task = conn.fetch(
            "SELECT * FROM orders WHERE user_id = $1", user_id
        )
        
        user, orders = await asyncio.gather(user_task, orders_task)
        
        return {
            "user": dict(user),
            "orders": [dict(order) for order in orders],
        }
```

### Pattern 3: Timeouts

```python
async def fetch_with_timeout(url: str, timeout: float = 5.0) -> str:
    """Fetch URL with timeout."""
    try:
        async with asyncio.timeout(timeout):  # Python 3.11+
            async with httpx.AsyncClient() as client:
                response = await client.get(url)
                return response.text
    except asyncio.TimeoutError:
        raise TimeoutError(f"Request to {url} timed out after {timeout}s")

# Python 3.10 and earlier
async def fetch_with_timeout_old(url: str, timeout: float = 5.0) -> str:
    try:
        return await asyncio.wait_for(
            fetch_url(url),
            timeout=timeout,
        )
    except asyncio.TimeoutError:
        raise TimeoutError(f"Request timed out")
```

### Pattern 4: Error Handling in Concurrent Tasks

```python
async def fetch_all_with_error_handling(
    urls: list[str],
) -> list[str | Exception]:
    """Fetch all URLs, collect both successes and failures."""
    async def safe_fetch(url: str) -> str | Exception:
        try:
            return await fetch_url(url)
        except Exception as e:
            return e
    
    tasks = [safe_fetch(url) for url in urls]
    results = await asyncio.gather(*tasks)
    
    # Filter successes and failures
    successes = [r for r in results if isinstance(r, str)]
    failures = [r for r in results if isinstance(r, Exception)]
    
    print(f"Success: {len(successes)}, Failed: {len(failures)}")
    return results

# Alternative: return_exceptions=True in gather
async def fetch_all_continue_on_error(urls: list[str]) -> list[str | Exception]:
    """Continue even if some tasks fail."""
    tasks = [fetch_url(url) for url in urls]
    # return_exceptions=True: Don't stop on first error
    results = await asyncio.gather(*tasks, return_exceptions=True)
    return results
```

## Testing Async Code

```python
import pytest

# Mark test as async
@pytest.mark.asyncio
async def test_fetch_url():
    result = await fetch_url("https://httpbin.org/json")
    assert result is not None

@pytest.mark.asyncio
async def test_concurrent_execution():
    urls = ["https://httpbin.org/json"] * 3
    results = await fetch_all_data(urls)
    assert len(results) == 3
```

**Setup**: `pip install pytest-asyncio`

## Common Pitfalls

### Pitfall 1: Blocking in Async Code

```python
# ❌ WRONG - Blocks the async runtime
async def bad_example():
    import time
    time.sleep(5)  # Blocks everything, defeats async purpose
    return "done"

# ✅ CORRECT - Use async sleep
async def good_example():
    await asyncio.sleep(5)  # Yields to other tasks
    return "done"
```

### Pitfall 2: Using Sync Libraries in Async Code

```python
# ❌ WRONG - requests blocks
import requests
async def bad_fetch(url: str) -> str:
    response = requests.get(url)  # Blocks!
    return response.text

# ✅ CORRECT - Use async library
import httpx
async def good_fetch(url: str) -> str:
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return response.text
```

### Pitfall 3: Not Awaiting Async Functions

```python
# ❌ WRONG - Creates task but doesn't run it
async def bad_example():
    result = fetch_url("https://example.com")  # Coroutine object
    print(result)  # Prints <coroutine>, not data

# ✅ CORRECT
async def good_example():
    result = await fetch_url("https://example.com")
    print(result)  # Prints actual data
```

## When NOT to Use Async (Python)

- **Simple scripts**: If you're making 1-2 API calls, sync code is simpler
- **CPU-bound work**: Use `multiprocessing` instead
- **Library doesn't support async**: Forcing async with sync libraries loses benefits
- **Team unfamiliar with async**: Async adds complexity; sync might be better if team struggles with it

---

## Rust Async Patterns

Rust's async model is similar to Python's but has key architectural differences.

### Async/Await Syntax

```rust
use tokio; // Most popular async runtime
use reqwest; // Async HTTP client

async fn fetch_url(url: &str) -> Result<String, reqwest::Error> {
    let response = reqwest::get(url).await?;
    let body = response.text().await?;
    Ok(body)
}

// Running async code
#[tokio::main]  // Macro sets up the async runtime
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let result = fetch_url("https://api.example.com/data").await?;
    println!("{}", result);
    Ok(())
}
```

**Key concepts**:
- `async fn`: Defines an async function
- `.await`: Waits for async operation to complete
- `#[tokio::main]`: Macro that sets up the async runtime (no `asyncio.run()` equivalent needed)
- **Must choose a runtime**: tokio, async-std, or smol (tokio is most common)

### Multi-Environment Command Execution

```rust
use tokio::process::Command;
use serde::Serialize;

#[derive(Debug, Serialize)]
struct CommandResult {
    environment: String,
    status: String,  // "passed", "failed", "error"
    output: String,
    error: Option<String>,
}

async fn run_command_in_env(
    environment: &str,
    command: &str,
) -> CommandResult {
    let output = Command::new("sh")
        .arg("-c")
        .arg(command)
        .env("ENVIRONMENT", environment)
        .output()
        .await;
    
    match output {
        Ok(output) => {
            if output.status.success() {
                CommandResult {
                    environment: environment.to_string(),
                    status: "passed".to_string(),
                    output: String::from_utf8_lossy(&output.stdout).to_string(),
                    error: None,
                }
            } else {
                CommandResult {
                    environment: environment.to_string(),
                    status: "failed".to_string(),
                    output: String::from_utf8_lossy(&output.stdout).to_string(),
                    error: Some(String::from_utf8_lossy(&output.stderr).to_string()),
                }
            }
        }
        Err(e) => CommandResult {
            environment: environment.to_string(),
            status: "error".to_string(),
            output: String::new(),
            error: Some(e.to_string()),
        },
    }
}

async fn run_across_environments(
    environments: Vec<&str>,
    command: &str,
) -> Vec<CommandResult> {
    // Create futures for all environments
    let mut tasks = Vec::new();
    for env in environments {
        tasks.push(run_command_in_env(env, command));
    }
    
    // Run all concurrently
    let results = futures::future::join_all(tasks).await;
    
    results
}

#[tokio::main]
async fn main() {
    let environments = vec![
        "client-1-prod",
        "client-2-prod",
        "client-3-prod",
    ];
    
    let command = "./scripts/health-check.sh";
    
    println!("Running health checks across environments...");
    let results = run_across_environments(environments, command).await;
    
    for result in results {
        println!("{}: {}", result.environment, result.status);
        if let Some(error) = result.error {
            println!("  Error: {}", error);
        }
    }
}
```

**Key patterns**:
- `tokio::process::Command`: Async subprocess execution
- `futures::future::join_all()`: Wait for all futures to complete (like `asyncio.gather()`)
- Owned data: Rust requires explicit ownership (`.to_string()` to move data into struct)

### Stream Processing

```rust
use tokio::fs::File;
use tokio::io::{AsyncBufReadExt, BufReader};
use futures::stream::{self, StreamExt};

async fn process_large_file(file_path: &str) -> Result<usize, std::io::Error> {
    let file = File::open(file_path).await?;
    let reader = BufReader::new(file);
    let mut lines = reader.lines();
    
    let mut line_count = 0;
    while let Some(line) = lines.next_line().await? {
        process_line(&line).await;
        line_count += 1;
    }
    
    Ok(line_count)
}

async fn process_line(line: &str) {
    // Process line (e.g., parse, transform, send to API)
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
}
```

### Async Streams (Paginated API)

```rust
use futures::stream::{Stream, StreamExt};
use reqwest::Client;
use serde::Deserialize;

#[derive(Deserialize)]
struct ApiResponse {
    items: Vec<serde_json::Value>,
    has_next: bool,
}

async fn fetch_paginated_data(
    base_url: &str,
) -> impl Stream<Item = serde_json::Value> {
    let client = Client::new();
    let mut page = 1;
    
    stream::unfold(
        (client, page, true),
        move |(client, page, has_more)| async move {
            if !has_more {
                return None;
            }
            
            let url = format!("{}?page={}", base_url, page);
            let response = client.get(&url).send().await.ok()?;
            let data: ApiResponse = response.json().await.ok()?;
            
            let has_next = data.has_next;
            let items = data.items;
            
            Some((
                stream::iter(items),
                (client, page + 1, has_next),
            ))
        },
    )
    .flatten()
}

async fn process_all_data(base_url: &str) {
    let mut stream = fetch_paginated_data(base_url).await;
    
    while let Some(item) = stream.next().await {
        // Process each item as it arrives
        process_item(&item).await;
    }
}
```

### Common Async Patterns (Rust)

**Pattern 1: Concurrent HTTP Requests**

```rust
use reqwest;

async fn fetch_all_data(urls: Vec<&str>) -> Vec<Result<String, reqwest::Error>> {
    let client = reqwest::Client::new();
    
    let tasks: Vec<_> = urls
        .into_iter()
        .map(|url| {
            let client = client.clone();
            async move {
                let response = client.get(url).send().await?;
                response.text().await
            }
        })
        .collect();
    
    // Wait for all to complete
    futures::future::join_all(tasks).await
}
```

**Pattern 2: Timeouts**

```rust
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout(
    url: &str,
    timeout_secs: u64,
) -> Result<String, Box<dyn std::error::Error>> {
    let request = reqwest::get(url);
    
    match timeout(Duration::from_secs(timeout_secs), request).await {
        Ok(response) => Ok(response?.text().await?),
        Err(_) => Err(format!("Request to {} timed out", url).into()),
    }
}
```

**Pattern 3: Error Handling**

```rust
async fn fetch_all_continue_on_error(urls: Vec<&str>) -> Vec<Result<String, String>> {
    let tasks: Vec<_> = urls
        .into_iter()
        .map(|url| async move {
            match fetch_url(url).await {
                Ok(body) => Ok(body),
                Err(e) => Err(format!("Failed to fetch {}: {}", url, e)),
            }
        })
        .collect();
    
    futures::future::join_all(tasks).await
}
```

### Testing Async Code (Rust)

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]  // tokio provides test macro
    async fn test_fetch_url() {
        let result = fetch_url("https://httpbin.org/json").await;
        assert!(result.is_ok());
    }
    
    #[tokio::test]
    async fn test_concurrent_execution() {
        let urls = vec!["https://httpbin.org/json"; 3];
        let results = fetch_all_data(urls).await;
        assert_eq!(results.len(), 3);
    }
}
```

### Common Pitfalls (Rust)

**Pitfall 1: Blocking in Async Code**

```rust
// ❌ WRONG - Blocks the async runtime
async fn bad_example() {
    std::thread::sleep(std::time::Duration::from_secs(5)); // Blocks!
}

// ✅ CORRECT - Use async sleep
async fn good_example() {
    tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
}
```

**Pitfall 2: Not Choosing a Runtime**

```rust
// ❌ WRONG - No runtime to execute async code
// fn main() {
//     fetch_url("https://example.com"); // Won't compile or run
// }

// ✅ CORRECT - Use runtime macro
#[tokio::main]
async fn main() {
    fetch_url("https://example.com").await;
}
```

**Pitfall 3: Forgetting `.await`**

```rust
// ❌ WRONG - Creates future but doesn't execute it
async fn bad_example() {
    let result = fetch_url("https://example.com");  // Future, not executed
    // Compiler warning: unused future
}

// ✅ CORRECT
async fn good_example() {
    let result = fetch_url("https://example.com").await;
}
```

## When NOT to Use Async (Rust)

- **Simple scripts**: Adds runtime dependency (tokio ~500KB), might be overkill
- **CPU-bound work**: Use threads or rayon for parallelism instead
- **Library doesn't support async**: Tokio has helpers to run blocking code, but adds overhead
- **Binary size matters**: Async runtimes add significant size; consider for embedded/WASM

---

## Key Differences: Python vs Rust Async

### Runtime Model

**Python**:
- ✅ Standard library `asyncio` - batteries included
- Runtime managed automatically
- `asyncio.run()` starts event loop

**Rust**:
- ❌ No standard async runtime - must choose one
- Most common: tokio (full-featured), async-std (stdlib-like), smol (minimal)
- `#[tokio::main]` macro sets up runtime
- Must add runtime as dependency

### Error Handling

**Python**:
- Exceptions propagate normally
- `try/except` works as expected
- `asyncio.gather(return_exceptions=True)` for collecting errors

**Rust**:
- Must use `Result<T, E>` explicitly
- `?` operator for propagation
- Pattern match for handling errors
- More verbose but catches errors at compile time

### Ownership and Lifetimes

**Python**:
- Garbage collected - no ownership concerns
- Can freely share data between async tasks
- Reference counting handles cleanup

**Rust**:
- Must manage ownership explicitly
- `.clone()` or `Arc<T>` for shared data
- Borrow checker ensures safety at compile time
- More upfront complexity, zero runtime overhead

### Performance

**Python**:
- Single-threaded event loop (GIL limits parallelism)
- Good for I/O-bound workloads
- Still limited by GIL for CPU work

**Rust**:
- True parallelism - can run async tasks on multiple threads
- Work-stealing schedulers (tokio)
- Zero-cost abstractions - no runtime overhead
- Faster for both I/O and CPU-bound async work

### When to Choose Which

**Python Async**:
- ✅ Rapid prototyping
- ✅ I/O-bound scripts and tools
- ✅ Working with async libraries (aiohttp, asyncpg)
- ✅ Team familiar with Python

**Rust Async**:
- ✅ High-performance services
- ✅ Need true parallelism with async
- ✅ System-level programming
- ✅ Long-running services where performance matters

---

# Part 2: Threading Patterns

## When to Use Threading

### Use Threading For: Concurrent I/O (with blocking libraries)

When you need concurrency but libraries don't support async:

- ✅ Blocking I/O operations (if no async library available)
- ✅ Legacy code that uses sync APIs
- ✅ Simple concurrent tasks without async complexity

### Use Threading For: Parallelism (Rust only)

Rust threads can achieve true parallelism:

- ✅ CPU-bound work across multiple cores
- ✅ Parallel data processing
- ✅ Compute-intensive tasks

### Python: Threading vs Multiprocessing vs Async

```
I/O-bound (network, disk, database):
├─ Library supports async? → Use async (best performance)
└─ Library is sync-only? → Use threading (easier than multiprocessing)

CPU-bound (computation, data processing):
├─ Need true parallelism? → Use multiprocessing (bypasses GIL)
└─ Task is lightweight? → Consider threading (shared memory, less overhead)

Simple scripts:
└─ Just use sync code (simplest)
```

---

## Python Threading Patterns

### Basic Threading

```python
import threading
import requests  # Sync HTTP library
from dataclasses import dataclass

@dataclass
class Result:
    url: str
    status_code: int | None
    error: str | None = None

def fetch_url(url: str) -> Result:
    """Fetch URL using sync library (requests)."""
    try:
        response = requests.get(url, timeout=5)
        return Result(url=url, status_code=response.status_code)
    except Exception as e:
        return Result(url=url, status_code=None, error=str(e))

def fetch_all_threaded(urls: list[str]) -> list[Result]:
    """Fetch URLs concurrently using threads."""
    results = []
    threads = []
    
    def worker(url: str):
        result = fetch_url(url)
        results.append(result)
    
    # Start all threads
    for url in urls:
        thread = threading.Thread(target=worker, args=(url,))
        thread.start()
        threads.append(thread)
    
    # Wait for all to complete
    for thread in threads:
        thread.join()
    
    return results

# Usage
urls = [
    "https://api.example.com/users/1",
    "https://api.example.com/users/2",
    "https://api.example.com/users/3",
]
results = fetch_all_threaded(urls)
```

**When to use**: Blocking I/O with sync libraries (requests, standard file I/O).

### ThreadPoolExecutor (Better Pattern)

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests

def fetch_url(url: str) -> dict:
    """Fetch URL and return result."""
    response = requests.get(url, timeout=5)
    return {"url": url, "status": response.status_code}

def fetch_all_parallel(urls: list[str], max_workers: int = 10) -> list[dict]:
    """Fetch URLs with thread pool."""
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit all tasks
        futures = {executor.submit(fetch_url, url): url for url in urls}
        
        results = []
        # Process as they complete
        for future in as_completed(futures):
            url = futures[future]
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                results.append({"url": url, "error": str(e)})
        
        return results

# Usage
urls = ["https://api.example.com/data"] * 10
results = fetch_all_parallel(urls, max_workers=5)
```

**Benefits**:
- Thread pool reuses threads (efficient)
- `as_completed()` processes results as they finish
- Built-in error handling
- Limits max concurrent threads

### Thread-Safe Data Structures

```python
import threading
import queue
import time

def worker(task_queue: queue.Queue, results: list):
    """Process tasks from queue."""
    while True:
        try:
            task = task_queue.get(timeout=1)
            if task is None:  # Poison pill to stop worker
                break
            
            # Process task
            result = process_task(task)
            results.append(result)
            
            task_queue.task_done()
        except queue.Empty:
            continue

def process_with_queue(tasks: list[str], num_workers: int = 4) -> list:
    """Process tasks using worker threads and queue."""
    task_queue = queue.Queue()
    results = []
    
    # Start workers
    threads = []
    for _ in range(num_workers):
        thread = threading.Thread(target=worker, args=(task_queue, results))
        thread.start()
        threads.append(thread)
    
    # Add tasks to queue
    for task in tasks:
        task_queue.put(task)
    
    # Wait for all tasks to complete
    task_queue.join()
    
    # Stop workers
    for _ in range(num_workers):
        task_queue.put(None)  # Poison pill
    
    for thread in threads:
        thread.join()
    
    return results
```

**Use case**: Producer-consumer pattern, task queue processing.

### Common Pitfalls (Python Threading)

**Pitfall 1: GIL Limitations**

```python
# ❌ WRONG - Threading for CPU-bound work
import threading

def cpu_intensive_task(n: int) -> int:
    """Sum numbers (CPU-bound)."""
    return sum(range(n))

# Threads won't speed this up due to GIL
threads = []
for i in range(4):
    thread = threading.Thread(target=cpu_intensive_task, args=(10_000_000,))
    thread.start()
    threads.append(thread)

for thread in threads:
    thread.join()

# ✅ CORRECT - Use multiprocessing for CPU work
from multiprocessing import Pool

with Pool(processes=4) as pool:
    results = pool.map(cpu_intensive_task, [10_000_000] * 4)
```

**Pitfall 2: Race Conditions**

```python
import threading

# ❌ WRONG - Race condition
counter = 0

def increment():
    global counter
    for _ in range(100_000):
        counter += 1  # Not atomic!

threads = [threading.Thread(target=increment) for _ in range(4)]
for thread in threads:
    thread.start()
for thread in threads:
    thread.join()

print(counter)  # Likely < 400,000 due to race condition

# ✅ CORRECT - Use lock
counter = 0
lock = threading.Lock()

def increment_safe():
    global counter
    for _ in range(100_000):
        with lock:
            counter += 1

threads = [threading.Thread(target=increment_safe) for _ in range(4)]
for thread in threads:
    thread.start()
for thread in threads:
    thread.join()

print(counter)  # Always 400,000
```

---

## Rust Threading Patterns

Rust has true threading with no GIL - threads run in parallel.

### Basic Threading

```rust
use std::thread;
use std::time::Duration;

fn worker(id: usize) {
    println!("Worker {} starting", id);
    thread::sleep(Duration::from_millis(100));
    println!("Worker {} done", id);
}

fn main() {
    let mut handles = vec![];
    
    // Spawn threads
    for i in 0..4 {
        let handle = thread::spawn(move || {
            worker(i);
        });
        handles.push(handle);
    }
    
    // Wait for all threads
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("All workers complete");
}
```

**Key concepts**:
- `thread::spawn()`: Create new thread
- `move ||`: Closure moves ownership into thread
- `.join()`: Wait for thread to finish
- Ownership prevents data races at compile time

### Shared State with Arc and Mutex

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    // Arc = Atomic Reference Counting (shared ownership)
    // Mutex = Mutual exclusion (thread-safe access)
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];
    
    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
        });
        handles.push(handle);
    }
    
    for handle in handles {
        handle.join().unwrap();
    }
    
    println!("Result: {}", *counter.lock().unwrap());  // Always 10
}
```

**Rust prevents race conditions at compile time**:
- Can't access shared data without `Arc` (shared ownership)
- Can't mutate without `Mutex` (thread-safe access)
- Compiler enforces thread safety

### Thread Pool (Rayon)

```rust
use rayon::prelude::*;

fn process_item(item: &i32) -> i32 {
    // CPU-intensive work
    item * 2
}

fn main() {
    let data: Vec<i32> = (0..1000).collect();
    
    // Parallel map - automatically uses thread pool
    let results: Vec<i32> = data
        .par_iter()  // Parallel iterator
        .map(process_item)
        .collect();
    
    println!("Processed {} items", results.len());
}
```

**Rayon** is the standard library for data parallelism:
- Automatically manages thread pool
- Work-stealing scheduler
- Replace `.iter()` with `.par_iter()` for parallelism
- Perfect for CPU-bound data processing

### Channel Communication

```rust
use std::sync::mpsc;  // Multiple producer, single consumer
use std::thread;
use std::time::Duration;

fn main() {
    let (tx, rx) = mpsc::channel();
    
    // Spawn worker threads
    for id in 0..4 {
        let tx = tx.clone();
        thread::spawn(move || {
            let result = format!("Result from worker {}", id);
            tx.send(result).unwrap();
        });
    }
    drop(tx);  // Drop original sender
    
    // Receive results
    for received in rx {
        println!("Got: {}", received);
    }
}
```

**Use case**: Worker threads sending results back to main thread.

### Common Pitfalls (Rust Threading)

**Pitfall 1: Forgetting `move` in Closures**

```rust
// ❌ WRONG - Captures reference, won't compile
// fn bad_example() {
//     let data = vec![1, 2, 3];
//     thread::spawn(|| {
//         println!("{:?}", data);  // Error: data might outlive thread
//     });
// }

// ✅ CORRECT - Move ownership into thread
fn good_example() {
    let data = vec![1, 2, 3];
    thread::spawn(move || {
        println!("{:?}", data);  // OK: thread owns data
    });
}
```

**Pitfall 2: Deadlocks with Multiple Locks**

```rust
use std::sync::{Arc, Mutex};
use std::thread;

// ❌ WRONG - Potential deadlock
fn bad_example() {
    let lock1 = Arc::new(Mutex::new(0));
    let lock2 = Arc::new(Mutex::new(0));
    
    let lock1_clone = Arc::clone(&lock1);
    let lock2_clone = Arc::clone(&lock2);
    
    thread::spawn(move || {
        let _a = lock1_clone.lock().unwrap();
        let _b = lock2_clone.lock().unwrap();  // Deadlock risk
    });
    
    let _b = lock2.lock().unwrap();
    let _a = lock1.lock().unwrap();  // Deadlock if other thread has lock1
}

// ✅ CORRECT - Always acquire locks in same order
fn good_example() {
    let lock1 = Arc::new(Mutex::new(0));
    let lock2 = Arc::new(Mutex::new(0));
    
    // Both threads acquire in same order: lock1, then lock2
    let lock1_clone = Arc::clone(&lock1);
    let lock2_clone = Arc::clone(&lock2);
    
    thread::spawn(move || {
        let _a = lock1_clone.lock().unwrap();
        let _b = lock2_clone.lock().unwrap();
    });
    
    let _a = lock1.lock().unwrap();
    let _b = lock2.lock().unwrap();
}
```

---

## Key Differences: Python vs Rust Threading

### Parallelism

**Python**:
- ❌ GIL prevents true parallelism for CPU work
- Threads good for I/O, not computation
- Must use `multiprocessing` for CPU parallelism

**Rust**:
- ✅ True parallelism - threads run on multiple cores
- Threads good for both I/O and CPU work
- No GIL, no multiprocessing needed

### Thread Safety

**Python**:
- Race conditions possible - must use locks manually
- Easy to forget thread safety
- Runtime errors if you get it wrong

**Rust**:
- Compiler enforces thread safety
- Can't compile code with data races
- `Send` and `Sync` traits ensure safety
- Arc + Mutex pattern prevents races

### Performance

**Python**:
- Threading overhead from GIL contention
- Good for I/O-bound, limited for CPU-bound
- Multiprocessing has higher overhead (process creation, IPC)

**Rust**:
- Minimal threading overhead
- Linear speedup for CPU-bound parallelism
- Zero-cost abstractions

### Ergonomics

**Python**:
- ✅ Easier to get started (ThreadPoolExecutor)
- ✅ Simpler syntax
- ❌ Easy to introduce bugs (race conditions)

**Rust**:
- ❌ Steeper learning curve (ownership, Arc, Mutex)
- ✅ Compiler catches bugs early
- ✅ Rayon makes data parallelism easy

### When to Choose Which

**Python Threading**:
- ✅ I/O-bound work with blocking libraries
- ✅ Quick scripts and prototypes
- ✅ Team familiar with Python
- ❌ Avoid for CPU-bound work (use multiprocessing)

**Rust Threading**:
- ✅ CPU-bound parallelism
- ✅ High-performance servers
- ✅ Data processing pipelines
- ✅ Systems programming

---

## Next Steps

1. **Async Experiments**:
   - Build multi-environment command runner in both languages
   - Try stream processing with real data
   - Compare performance and ergonomics

2. **Threading Experiments**:
   - Python: Try ThreadPoolExecutor for concurrent API calls
   - Rust: Use rayon for parallel data processing
   - Compare GIL limitations vs true parallelism

3. **Form Opinions**:
   - Which patterns feel natural vs awkward?
   - When would you reach for async vs threading?
   - What belongs in style guide vs situational?

4. **Decide What to Commit**:
   - Extract patterns you're confident about
   - Document antipatterns to avoid
   - Keep situational guidance separate

---

**Remember**: This is for learning and experimentation. Once you have strong opinions from real-world usage, extract the patterns that work for you into the Python and Rust style guides.
