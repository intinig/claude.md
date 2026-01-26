---
name: rust-concurrency
description: Rust concurrency patterns. Use when writing concurrent Rust code.
---

# Rust Concurrency Patterns

## Core Principle

**Fearless concurrency through ownership.** The type system prevents data races at compile time. Use async/await for I/O-bound tasks, threads for CPU-bound tasks.

---

## Send and Sync Traits

### Understanding Send and Sync

```rust
// Send: Safe to transfer ownership between threads
// Sync: Safe to share references between threads (&T is Send)

// Most types are Send + Sync by default
struct User {
    name: String,  // String is Send + Sync
    age: u32,      // u32 is Send + Sync
}
// User is automatically Send + Sync

// Some types are NOT Send or Sync
use std::rc::Rc;
let rc = Rc::new(42);  // Rc is NOT Send (not thread-safe)

use std::cell::RefCell;
let cell = RefCell::new(42);  // RefCell is NOT Sync (interior mutability)
```

### Using Arc for Thread-Safe Sharing

```rust
// ❌ WRONG - Rc is not Send
use std::rc::Rc;
use std::thread;

let data = Rc::new(vec![1, 2, 3]);
thread::spawn(move || {
    println!("{:?}", data);  // Error: Rc is not Send
});

// ✅ CORRECT - Use Arc for thread-safe reference counting
use std::sync::Arc;

let data = Arc::new(vec![1, 2, 3]);
let data_clone = Arc::clone(&data);

thread::spawn(move || {
    println!("{:?}", data_clone);  // OK: Arc is Send
});
```

### !Send and !Sync Types

```rust
// Common !Send types:
// - Rc<T> - Use Arc<T> instead
// - *const T, *mut T - Raw pointers

// Common !Sync types:
// - Cell<T>, RefCell<T> - Use Mutex<T> or RwLock<T> instead
// - Rc<T> - Use Arc<T> instead

// ✅ Thread-safe equivalents
use std::sync::{Arc, Mutex, RwLock};

// Instead of Rc<RefCell<T>>, use:
let shared: Arc<Mutex<Vec<i32>>> = Arc::new(Mutex::new(vec![]));

// Instead of Rc<T> for read-only, use:
let shared: Arc<Vec<i32>> = Arc::new(vec![1, 2, 3]);
```

---

## Async/Await with Tokio

### Basic Async Functions

```rust
use tokio;

// Async function declaration
async fn fetch_user(id: &str) -> Result<User, Error> {
    let response = client
        .get(&format!("/users/{}", id))
        .send()
        .await?;

    let user: User = response.json().await?;
    Ok(user)
}

// Calling async functions
#[tokio::main]
async fn main() -> Result<(), Error> {
    let user = fetch_user("123").await?;
    println!("User: {:?}", user);
    Ok(())
}

// Async in regular function - use block_on
fn sync_fetch(id: &str) -> Result<User, Error> {
    let runtime = tokio::runtime::Runtime::new()?;
    runtime.block_on(fetch_user(id))
}
```

### Spawning Tasks

```rust
use tokio::task;

async fn process_users(ids: Vec<String>) -> Vec<Result<User, Error>> {
    let mut handles = vec![];

    for id in ids {
        // Spawn a task for each user
        let handle = task::spawn(async move {
            fetch_user(&id).await
        });
        handles.push(handle);
    }

    // Await all tasks
    let mut results = vec![];
    for handle in handles {
        let result = handle.await.unwrap();  // JoinError if task panicked
        results.push(result);
    }

    results
}

// Using join_all for cleaner code
use futures::future::join_all;

async fn process_users(ids: Vec<String>) -> Vec<Result<User, Error>> {
    let futures: Vec<_> = ids
        .into_iter()
        .map(|id| async move { fetch_user(&id).await })
        .collect();

    join_all(futures).await
}
```

### Task Spawning Patterns

```rust
// spawn - For tasks that can run independently
let handle = tokio::spawn(async {
    // This runs concurrently
    expensive_operation().await
});

// spawn_blocking - For CPU-bound work in async context
let result = tokio::task::spawn_blocking(|| {
    // This runs on a blocking thread pool
    cpu_intensive_calculation()
}).await?;

// spawn_local - For !Send futures (single-threaded runtime)
tokio::task::spawn_local(async {
    // Must stay on same thread
});
```

---

## Arc<Mutex<T>> and Arc<RwLock<T>>

### Shared Mutable State with Mutex

```rust
use std::sync::{Arc, Mutex};

struct Counter {
    count: Arc<Mutex<u64>>,
}

impl Counter {
    fn new() -> Self {
        Counter {
            count: Arc::new(Mutex::new(0)),
        }
    }

    fn increment(&self) {
        let mut count = self.count.lock().unwrap();
        *count += 1;
    }

    fn value(&self) -> u64 {
        *self.count.lock().unwrap()
    }
}

// Using with threads
fn parallel_increment() {
    let counter = Counter::new();
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Counter {
            count: Arc::clone(&counter.count),
        };
        handles.push(std::thread::spawn(move || {
            for _ in 0..100 {
                counter.increment();
            }
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    assert_eq!(counter.value(), 1000);
}
```

### RwLock for Read-Heavy Workloads

```rust
use std::sync::{Arc, RwLock};

struct Cache {
    data: Arc<RwLock<HashMap<String, String>>>,
}

impl Cache {
    fn new() -> Self {
        Cache {
            data: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    fn get(&self, key: &str) -> Option<String> {
        // Multiple readers can access simultaneously
        let data = self.data.read().unwrap();
        data.get(key).cloned()
    }

    fn set(&self, key: String, value: String) {
        // Exclusive access for writing
        let mut data = self.data.write().unwrap();
        data.insert(key, value);
    }
}
```

### Async-Aware Locks (tokio::sync)

```rust
use tokio::sync::{Mutex, RwLock};

// ✅ CORRECT - Use tokio::sync::Mutex in async code
struct AsyncCache {
    data: Mutex<HashMap<String, String>>,
}

impl AsyncCache {
    async fn get(&self, key: &str) -> Option<String> {
        let data = self.data.lock().await;  // .await, not .unwrap()
        data.get(key).cloned()
    }

    async fn set(&self, key: String, value: String) {
        let mut data = self.data.lock().await;
        data.insert(key, value);
    }
}

// ❌ WRONG - Holding std::sync::Mutex across await
async fn bad_example(mutex: &std::sync::Mutex<Data>) {
    let guard = mutex.lock().unwrap();
    some_async_operation().await;  // DON'T hold lock across await!
    drop(guard);
}

// ✅ CORRECT - Release lock before await
async fn good_example(mutex: &std::sync::Mutex<Data>) {
    let value = {
        let guard = mutex.lock().unwrap();
        guard.clone()
    };  // Lock released here
    some_async_operation().await;
}
```

---

## Channel Patterns

### std::sync::mpsc (Synchronous)

```rust
use std::sync::mpsc;
use std::thread;

fn producer_consumer() {
    let (tx, rx) = mpsc::channel();

    // Spawn producer thread
    thread::spawn(move || {
        for i in 0..10 {
            tx.send(i).unwrap();
        }
    });

    // Receive in main thread
    for received in rx {
        println!("Got: {}", received);
    }
}

// Multiple producers
fn multiple_producers() {
    let (tx, rx) = mpsc::channel();

    for i in 0..3 {
        let tx = tx.clone();
        thread::spawn(move || {
            tx.send(format!("Message from thread {}", i)).unwrap();
        });
    }
    drop(tx);  // Drop original sender

    for msg in rx {
        println!("{}", msg);
    }
}
```

### tokio Channels

```rust
use tokio::sync::mpsc;

async fn async_channel_example() {
    // Bounded channel (backpressure)
    let (tx, mut rx) = mpsc::channel::<i32>(100);

    tokio::spawn(async move {
        for i in 0..10 {
            tx.send(i).await.unwrap();
        }
    });

    while let Some(value) = rx.recv().await {
        println!("Received: {}", value);
    }
}

// Unbounded channel (no backpressure, can grow infinitely)
use tokio::sync::mpsc::unbounded_channel;

let (tx, mut rx) = unbounded_channel::<String>();
tx.send("hello".to_string()).unwrap();  // No .await needed
```

### Broadcast Channel (Multiple Receivers)

```rust
use tokio::sync::broadcast;

async fn broadcast_example() {
    let (tx, mut rx1) = broadcast::channel::<String>(16);
    let mut rx2 = tx.subscribe();

    tx.send("Hello".to_string()).unwrap();

    // Both receivers get the message
    assert_eq!(rx1.recv().await.unwrap(), "Hello");
    assert_eq!(rx2.recv().await.unwrap(), "Hello");
}
```

### Oneshot Channel (Single Value)

```rust
use tokio::sync::oneshot;

async fn oneshot_example() {
    let (tx, rx) = oneshot::channel::<String>();

    tokio::spawn(async move {
        // Compute result
        let result = expensive_computation().await;
        tx.send(result).unwrap();
    });

    // Wait for single result
    let result = rx.await.unwrap();
}
```

### Watch Channel (Latest Value)

```rust
use tokio::sync::watch;

async fn watch_example() {
    let (tx, mut rx) = watch::channel("initial".to_string());

    tokio::spawn(async move {
        loop {
            // Always gets latest value
            let value = rx.borrow().clone();
            println!("Current: {}", value);

            // Wait for changes
            rx.changed().await.unwrap();
        }
    });

    tx.send("updated".to_string()).unwrap();
}
```

---

## Cancellation with tokio::select!

### Racing Futures

```rust
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout(id: &str) -> Result<User, Error> {
    timeout(Duration::from_secs(5), fetch_user(id))
        .await
        .map_err(|_| Error::Timeout)?
}

// Using select! for more control
async fn fetch_with_cancellation(
    id: &str,
    cancel: tokio::sync::oneshot::Receiver<()>,
) -> Result<User, Error> {
    tokio::select! {
        result = fetch_user(id) => result,
        _ = cancel => Err(Error::Cancelled),
    }
}
```

### Graceful Shutdown Pattern

```rust
use tokio::signal;
use tokio::sync::broadcast;

async fn run_server() -> Result<(), Error> {
    let (shutdown_tx, _) = broadcast::channel::<()>(1);

    // Spawn workers
    for i in 0..4 {
        let mut shutdown_rx = shutdown_tx.subscribe();
        tokio::spawn(async move {
            loop {
                tokio::select! {
                    _ = do_work() => {}
                    _ = shutdown_rx.recv() => {
                        println!("Worker {} shutting down", i);
                        break;
                    }
                }
            }
        });
    }

    // Wait for shutdown signal
    signal::ctrl_c().await?;
    println!("Shutdown signal received");

    // Notify all workers
    drop(shutdown_tx);

    // Give workers time to cleanup
    tokio::time::sleep(Duration::from_secs(1)).await;

    Ok(())
}
```

### Timeout Patterns

```rust
use tokio::time::{timeout, Duration};

// Simple timeout
async fn with_timeout<T, F: Future<Output = T>>(
    duration: Duration,
    future: F,
) -> Result<T, Error> {
    timeout(duration, future)
        .await
        .map_err(|_| Error::Timeout)
}

// Retry with timeout
async fn fetch_with_retry(id: &str) -> Result<User, Error> {
    for attempt in 1..=3 {
        match timeout(Duration::from_secs(5), fetch_user(id)).await {
            Ok(Ok(user)) => return Ok(user),
            Ok(Err(e)) => {
                eprintln!("Attempt {} failed: {}", attempt, e);
            }
            Err(_) => {
                eprintln!("Attempt {} timed out", attempt);
            }
        }
        tokio::time::sleep(Duration::from_millis(100 * attempt as u64)).await;
    }
    Err(Error::MaxRetriesExceeded)
}
```

---

## Thread Pools and Rayon

### CPU-Bound Parallelism with Rayon

```rust
use rayon::prelude::*;

// Parallel iteration
fn process_items(items: Vec<Item>) -> Vec<Result> {
    items
        .par_iter()  // Parallel iterator
        .map(|item| expensive_computation(item))
        .collect()
}

// Parallel sorting
fn sort_large_dataset(mut data: Vec<i32>) -> Vec<i32> {
    data.par_sort();
    data
}

// Custom parallelism
fn parallel_sum(numbers: &[i64]) -> i64 {
    numbers
        .par_iter()
        .sum()
}

// With filter and map
fn process_valid_items(items: Vec<Item>) -> Vec<Output> {
    items
        .into_par_iter()
        .filter(|item| item.is_valid())
        .map(|item| transform(item))
        .collect()
}
```

### When to Use Threads vs Async

```rust
// ✅ Use async/await for I/O-bound work
// - Network requests
// - File I/O
// - Database queries
// - Waiting for user input
async fn io_bound_work() {
    let response = client.get(url).send().await?;
    let data = tokio::fs::read_to_string("file.txt").await?;
}

// ✅ Use threads/rayon for CPU-bound work
// - Image processing
// - Cryptography
// - Data transformation
// - Heavy computation
fn cpu_bound_work(data: &[u8]) -> Vec<u8> {
    data.par_iter()
        .map(|b| complex_transform(*b))
        .collect()
}

// ✅ Bridge async and CPU-bound with spawn_blocking
async fn mixed_workload(data: Vec<u8>) -> Result<(), Error> {
    // CPU-bound work in blocking task
    let processed = tokio::task::spawn_blocking(move || {
        cpu_bound_work(&data)
    }).await?;

    // I/O-bound work
    save_to_database(&processed).await?;
    Ok(())
}
```

---

## Common Pitfalls

### Holding Locks Across Await Points

```rust
// ❌ WRONG - Lock held across await
async fn bad(data: &Mutex<Vec<i32>>) {
    let mut guard = data.lock().await;
    guard.push(1);
    some_async_operation().await;  // Lock still held!
    guard.push(2);
}

// ✅ CORRECT - Release lock before await
async fn good(data: &Mutex<Vec<i32>>) {
    {
        let mut guard = data.lock().await;
        guard.push(1);
    }  // Lock released

    some_async_operation().await;

    {
        let mut guard = data.lock().await;
        guard.push(2);
    }
}
```

### Blocking in Async Context

```rust
// ❌ WRONG - Blocking call in async function
async fn bad() {
    std::thread::sleep(Duration::from_secs(1));  // Blocks runtime!
    std::fs::read_to_string("file.txt")?;        // Blocks runtime!
}

// ✅ CORRECT - Use async equivalents
async fn good() {
    tokio::time::sleep(Duration::from_secs(1)).await;
    tokio::fs::read_to_string("file.txt").await?;
}

// ✅ CORRECT - Use spawn_blocking for unavoidable blocking
async fn with_blocking() {
    let result = tokio::task::spawn_blocking(|| {
        std::fs::read_to_string("file.txt")
    }).await??;
}
```

### Forgetting to Handle JoinHandle

```rust
// ❌ WRONG - Spawned task ignored
async fn bad() {
    tokio::spawn(async { important_work().await });
    // Task might not complete before function returns!
}

// ✅ CORRECT - Await the JoinHandle
async fn good() {
    let handle = tokio::spawn(async { important_work().await });
    handle.await.unwrap();
}

// ✅ CORRECT - Store handle for later
struct Worker {
    handle: tokio::task::JoinHandle<()>,
}

impl Worker {
    async fn shutdown(self) {
        self.handle.await.unwrap();
    }
}
```

---

## Testing Concurrent Code

### Basic Async Test

```rust
#[tokio::test]
async fn test_async_function() {
    let result = fetch_user("123").await;
    assert!(result.is_ok());
}
```

### Testing with Timeouts

```rust
#[tokio::test]
async fn test_completes_in_time() {
    let result = tokio::time::timeout(
        Duration::from_secs(5),
        slow_operation()
    ).await;

    assert!(result.is_ok(), "Operation timed out");
}
```

### Testing Concurrent Access

```rust
#[tokio::test]
async fn test_concurrent_counter() {
    let counter = Arc::new(AtomicU64::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Arc::clone(&counter);
        handles.push(tokio::spawn(async move {
            for _ in 0..100 {
                counter.fetch_add(1, Ordering::SeqCst);
            }
        }));
    }

    for handle in handles {
        handle.await.unwrap();
    }

    assert_eq!(counter.load(Ordering::SeqCst), 1000);
}
```

### Testing with Channels

```rust
#[tokio::test]
async fn test_producer_consumer() {
    let (tx, mut rx) = mpsc::channel(10);

    let producer = tokio::spawn(async move {
        for i in 0..5 {
            tx.send(i).await.unwrap();
        }
    });

    let mut received = vec![];
    while let Some(value) = rx.recv().await {
        received.push(value);
    }

    producer.await.unwrap();
    assert_eq!(received, vec![0, 1, 2, 3, 4]);
}
```

---

## Summary Checklist

When writing concurrent Rust code, verify:

- [ ] Using Arc instead of Rc for thread-safe sharing
- [ ] Using tokio::sync::Mutex in async code (not std::sync::Mutex)
- [ ] Not holding locks across .await points
- [ ] Not blocking in async functions (use spawn_blocking)
- [ ] JoinHandles are awaited or properly stored
- [ ] Using select! for cancellation and timeouts
- [ ] Channels chosen appropriately (mpsc, broadcast, oneshot, watch)
- [ ] CPU-bound work in spawn_blocking or rayon
- [ ] I/O-bound work uses async/await
- [ ] Graceful shutdown implemented for long-running tasks
- [ ] Tests cover concurrent scenarios
