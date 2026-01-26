---
name: csharp-concurrency
description: C# async/await and concurrency patterns. Use when writing concurrent C# code.
---

# C# Concurrency Patterns

## Core Principle

**Async all the way.** Never block on async code. Use `CancellationToken` on all async methods. Prefer `Task` over `Thread` for I/O-bound work, and `Parallel` for CPU-bound work.

---

## Async/Await Fundamentals

### Async All the Way

```csharp
// ❌ WRONG - Blocking on async (deadlock risk)
public User GetUser(string id)
{
    return GetUserAsync(id).Result; // Blocks thread, potential deadlock
}

public User GetUser2(string id)
{
    return GetUserAsync(id).GetAwaiter().GetResult(); // Still blocking
}

public void Process()
{
    GetUserAsync("123").Wait(); // Deadlock in UI/ASP.NET contexts
}

// ✅ CORRECT - Async all the way
public async Task<User> GetUserAsync(string id, CancellationToken ct = default)
{
    return await _repository.GetByIdAsync(id, ct);
}

public async Task ProcessAsync(CancellationToken ct = default)
{
    var user = await GetUserAsync("123", ct);
    await ProcessUserAsync(user, ct);
}
```

### No Async Void

```csharp
// ❌ WRONG - async void (exceptions unobservable)
public async void ProcessData()
{
    await DoWorkAsync(); // Exception here crashes the app
}

// ❌ WRONG - async void event handler without try-catch
button.Click += async (s, e) =>
{
    await ProcessAsync(); // Exception unhandled
};

// ✅ CORRECT - async Task
public async Task ProcessDataAsync()
{
    await DoWorkAsync();
}

// ✅ CORRECT - async void event handler WITH try-catch
button.Click += async (s, e) =>
{
    try
    {
        await ProcessAsync();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Process failed");
    }
};
```

### Async Naming Convention

```csharp
// ❌ WRONG - Missing Async suffix
public Task<User> GetUser(string id);
public Task SaveUser(User user);

// ✅ CORRECT - Async suffix for async methods
public Task<User> GetUserAsync(string id, CancellationToken ct = default);
public Task SaveUserAsync(User user, CancellationToken ct = default);
```

---

## CancellationToken

### Always Accept CancellationToken

```csharp
// ❌ WRONG - No cancellation support
public async Task<Data> FetchDataAsync()
{
    return await _httpClient.GetFromJsonAsync<Data>(url);
}

// ✅ CORRECT - CancellationToken as last parameter with default
public async Task<Data> FetchDataAsync(CancellationToken ct = default)
{
    return await _httpClient.GetFromJsonAsync<Data>(url, ct);
}

// ✅ CORRECT - Pass token through entire call chain
public async Task ProcessOrderAsync(Order order, CancellationToken ct = default)
{
    var user = await _userService.GetUserAsync(order.UserId, ct);
    var payment = await _paymentService.ProcessAsync(order, ct);
    await _notificationService.SendAsync(user, payment, ct);
}
```

### Check Cancellation in Long Operations

```csharp
// ✅ Check cancellation in loops
public async Task ProcessItemsAsync(
    IEnumerable<Item> items,
    CancellationToken ct = default)
{
    foreach (var item in items)
    {
        ct.ThrowIfCancellationRequested();
        await ProcessItemAsync(item, ct);
    }
}

// ✅ Check cancellation in CPU-bound work
public async Task<int> CalculateAsync(int[] data, CancellationToken ct = default)
{
    return await Task.Run(() =>
    {
        var sum = 0;
        for (var i = 0; i < data.Length; i++)
        {
            if (i % 1000 == 0) // Check periodically
            {
                ct.ThrowIfCancellationRequested();
            }
            sum += data[i];
        }
        return sum;
    }, ct);
}
```

### Cancellation with Timeout

```csharp
// ✅ Using CancellationTokenSource for timeout
public async Task<Data?> FetchWithTimeoutAsync(
    string url,
    TimeSpan timeout,
    CancellationToken ct = default)
{
    using var cts = CancellationTokenSource.CreateLinkedTokenSource(ct);
    cts.CancelAfter(timeout);

    try
    {
        return await _httpClient.GetFromJsonAsync<Data>(url, cts.Token);
    }
    catch (OperationCanceledException) when (!ct.IsCancellationRequested)
    {
        // Timeout, not external cancellation
        return null;
    }
}

// ✅ Combining multiple cancellation sources
public async Task ProcessAsync(CancellationToken externalToken)
{
    using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
    using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(
        externalToken,
        timeoutCts.Token);

    await DoWorkAsync(linkedCts.Token);
}
```

---

## Task Composition

### Task.WhenAll - Concurrent Execution

```csharp
// ❌ WRONG - Sequential when could be parallel
public async Task<(User, Order, Settings)> GetDataAsync(
    string userId,
    string orderId,
    CancellationToken ct = default)
{
    var user = await _userService.GetAsync(userId, ct);
    var order = await _orderService.GetAsync(orderId, ct);  // Waits for user
    var settings = await _settingsService.GetAsync(ct);      // Waits for order
    return (user, order, settings);
}

// ✅ CORRECT - Parallel independent operations
public async Task<(User, Order, Settings)> GetDataAsync(
    string userId,
    string orderId,
    CancellationToken ct = default)
{
    var userTask = _userService.GetAsync(userId, ct);
    var orderTask = _orderService.GetAsync(orderId, ct);
    var settingsTask = _settingsService.GetAsync(ct);

    await Task.WhenAll(userTask, orderTask, settingsTask);

    return (userTask.Result, orderTask.Result, settingsTask.Result);
}

// ✅ BETTER - Using ValueTuple for cleaner code
public async Task<(User, Order, Settings)> GetDataAsync(
    string userId,
    string orderId,
    CancellationToken ct = default)
{
    return await (
        _userService.GetAsync(userId, ct),
        _orderService.GetAsync(orderId, ct),
        _settingsService.GetAsync(ct)
    ).WhenAll();
}

// Extension method for tuple of tasks
public static class TaskExtensions
{
    public static async Task<(T1, T2, T3)> WhenAll<T1, T2, T3>(
        this (Task<T1>, Task<T2>, Task<T3>) tasks)
    {
        await Task.WhenAll(tasks.Item1, tasks.Item2, tasks.Item3);
        return (tasks.Item1.Result, tasks.Item2.Result, tasks.Item3.Result);
    }
}
```

### Task.WhenAny - First to Complete

```csharp
// ✅ Race between operations
public async Task<Data> FetchWithFallbackAsync(CancellationToken ct = default)
{
    var primaryTask = _primaryService.FetchAsync(ct);
    var fallbackTask = Task.Delay(TimeSpan.FromSeconds(2), ct)
        .ContinueWith(_ => _fallbackService.FetchAsync(ct), ct)
        .Unwrap();

    var completedTask = await Task.WhenAny(primaryTask, fallbackTask);
    return await completedTask;
}
```

### Processing Results as They Complete

```csharp
// ✅ Process tasks as they complete
public async Task ProcessAllAsync(
    IReadOnlyList<string> ids,
    CancellationToken ct = default)
{
    var tasks = ids
        .Select(id => FetchAsync(id, ct))
        .ToList();

    while (tasks.Count > 0)
    {
        var completedTask = await Task.WhenAny(tasks);
        tasks.Remove(completedTask);

        try
        {
            var result = await completedTask;
            ProcessResult(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Task failed");
        }
    }
}
```

---

## Channels

### Producer-Consumer Pattern

```csharp
using System.Threading.Channels;

public class DataProcessor
{
    private readonly Channel<Data> _channel;

    public DataProcessor()
    {
        // Bounded channel with backpressure
        _channel = Channel.CreateBounded<Data>(new BoundedChannelOptions(100)
        {
            FullMode = BoundedChannelFullMode.Wait
        });
    }

    // Producer
    public async Task ProduceAsync(Data data, CancellationToken ct = default)
    {
        await _channel.Writer.WriteAsync(data, ct);
    }

    public void CompleteProduction()
    {
        _channel.Writer.Complete();
    }

    // Consumer
    public async Task ConsumeAsync(CancellationToken ct = default)
    {
        await foreach (var data in _channel.Reader.ReadAllAsync(ct))
        {
            await ProcessDataAsync(data, ct);
        }
    }
}

// Usage
var processor = new DataProcessor();

// Start consumer
var consumerTask = processor.ConsumeAsync(ct);

// Produce data
foreach (var item in items)
{
    await processor.ProduceAsync(item, ct);
}
processor.CompleteProduction();

// Wait for consumer to finish
await consumerTask;
```

### Multiple Consumers

```csharp
public async Task ProcessWithMultipleConsumersAsync(
    int consumerCount,
    CancellationToken ct = default)
{
    var channel = Channel.CreateUnbounded<WorkItem>();

    // Start multiple consumers
    var consumers = Enumerable
        .Range(0, consumerCount)
        .Select(i => ConsumeAsync(channel.Reader, i, ct))
        .ToList();

    // Producer writes to channel
    await ProduceAsync(channel.Writer, ct);
    channel.Writer.Complete();

    // Wait for all consumers
    await Task.WhenAll(consumers);
}

private async Task ConsumeAsync(
    ChannelReader<WorkItem> reader,
    int consumerId,
    CancellationToken ct)
{
    await foreach (var item in reader.ReadAllAsync(ct))
    {
        _logger.LogDebug("Consumer {Id} processing {Item}", consumerId, item);
        await ProcessAsync(item, ct);
    }
}
```

---

## Semaphore for Throttling

### Limit Concurrent Operations

```csharp
// ✅ Throttle concurrent HTTP requests
public class ThrottledHttpClient
{
    private readonly HttpClient _httpClient;
    private readonly SemaphoreSlim _semaphore;

    public ThrottledHttpClient(HttpClient httpClient, int maxConcurrency = 10)
    {
        _httpClient = httpClient;
        _semaphore = new SemaphoreSlim(maxConcurrency);
    }

    public async Task<T?> GetAsync<T>(string url, CancellationToken ct = default)
    {
        await _semaphore.WaitAsync(ct);
        try
        {
            return await _httpClient.GetFromJsonAsync<T>(url, ct);
        }
        finally
        {
            _semaphore.Release();
        }
    }
}

// ✅ Process many items with limited concurrency
public async Task ProcessManyAsync(
    IReadOnlyList<string> urls,
    int maxConcurrency = 10,
    CancellationToken ct = default)
{
    using var semaphore = new SemaphoreSlim(maxConcurrency);

    var tasks = urls.Select(async url =>
    {
        await semaphore.WaitAsync(ct);
        try
        {
            return await FetchAsync(url, ct);
        }
        finally
        {
            semaphore.Release();
        }
    });

    var results = await Task.WhenAll(tasks);
}
```

---

## Parallel Processing (CPU-Bound)

### Parallel.ForEachAsync

```csharp
// ✅ For CPU-bound parallel work with async I/O
public async Task ProcessImagesAsync(
    IEnumerable<string> imagePaths,
    CancellationToken ct = default)
{
    await Parallel.ForEachAsync(
        imagePaths,
        new ParallelOptions
        {
            MaxDegreeOfParallelism = Environment.ProcessorCount,
            CancellationToken = ct
        },
        async (path, ct) =>
        {
            var image = await LoadImageAsync(path, ct);
            var processed = ProcessImage(image); // CPU-bound
            await SaveImageAsync(processed, ct);
        });
}
```

### PLINQ for Data Parallelism

```csharp
// ✅ Parallel LINQ for CPU-bound transformations
public IReadOnlyList<ProcessedData> ProcessData(IReadOnlyList<Data> items)
{
    return items
        .AsParallel()
        .WithDegreeOfParallelism(Environment.ProcessorCount)
        .Select(item => ExpensiveTransform(item))
        .ToList();
}

// ✅ With cancellation
public IReadOnlyList<ProcessedData> ProcessData(
    IReadOnlyList<Data> items,
    CancellationToken ct)
{
    return items
        .AsParallel()
        .WithCancellation(ct)
        .Select(item => ExpensiveTransform(item))
        .ToList();
}
```

---

## Thread-Safe Collections

### Concurrent Collections

```csharp
using System.Collections.Concurrent;

// ✅ Thread-safe dictionary
public class CacheService
{
    private readonly ConcurrentDictionary<string, Data> _cache = new();

    public Data GetOrAdd(string key, Func<Data> factory)
    {
        return _cache.GetOrAdd(key, _ => factory());
    }

    public async Task<Data> GetOrAddAsync(
        string key,
        Func<Task<Data>> factory)
    {
        if (_cache.TryGetValue(key, out var cached))
        {
            return cached;
        }

        var data = await factory();
        return _cache.GetOrAdd(key, data);
    }
}

// ✅ Thread-safe queue
public class WorkQueue
{
    private readonly ConcurrentQueue<WorkItem> _queue = new();

    public void Enqueue(WorkItem item) => _queue.Enqueue(item);

    public bool TryDequeue(out WorkItem? item) => _queue.TryDequeue(out item);
}
```

### Immutable Collections

```csharp
using System.Collections.Immutable;

// ✅ Immutable list - thread-safe by nature
public class ImmutableService
{
    private ImmutableList<User> _users = ImmutableList<User>.Empty;

    public void AddUser(User user)
    {
        // Creates new list, original unchanged
        ImmutableInterlocked.Update(ref _users, list => list.Add(user));
    }

    public IReadOnlyList<User> GetUsers() => _users;
}
```

---

## Async Initialization

### Lazy Async Initialization

```csharp
// ✅ Lazy async initialization pattern
public class ServiceWithAsyncInit
{
    private readonly Lazy<Task<ExpensiveResource>> _resource;

    public ServiceWithAsyncInit()
    {
        _resource = new Lazy<Task<ExpensiveResource>>(InitializeAsync);
    }

    private async Task<ExpensiveResource> InitializeAsync()
    {
        // Only called once, even if accessed concurrently
        return await LoadResourceAsync();
    }

    public async Task<Data> GetDataAsync(CancellationToken ct = default)
    {
        var resource = await _resource.Value;
        return resource.GetData();
    }
}

// ✅ Using AsyncLazy helper
public class AsyncLazy<T>
{
    private readonly Lazy<Task<T>> _lazy;

    public AsyncLazy(Func<Task<T>> factory)
    {
        _lazy = new Lazy<Task<T>>(factory);
    }

    public Task<T> Value => _lazy.Value;
    public bool IsValueCreated => _lazy.IsValueCreated;
}
```

---

## Synchronization Primitives

### SemaphoreSlim for Async Locking

```csharp
// ✅ Async-compatible lock
public class ThreadSafeCounter
{
    private readonly SemaphoreSlim _lock = new(1, 1);
    private int _count;

    public async Task<int> IncrementAsync(CancellationToken ct = default)
    {
        await _lock.WaitAsync(ct);
        try
        {
            _count++;
            return _count;
        }
        finally
        {
            _lock.Release();
        }
    }
}

// ❌ WRONG - lock doesn't work with async
public class BrokenCounter
{
    private readonly object _lock = new();
    private int _count;

    public async Task<int> IncrementAsync()
    {
        lock (_lock) // Can't await inside lock!
        {
            await Task.Delay(100); // Compile error
            _count++;
            return _count;
        }
    }
}
```

### ReaderWriterLockSlim for Read-Heavy Scenarios

```csharp
// ✅ For synchronous read-heavy access
public class ReadHeavyCache<TKey, TValue> where TKey : notnull
{
    private readonly Dictionary<TKey, TValue> _cache = new();
    private readonly ReaderWriterLockSlim _lock = new();

    public TValue? Get(TKey key)
    {
        _lock.EnterReadLock();
        try
        {
            return _cache.TryGetValue(key, out var value) ? value : default;
        }
        finally
        {
            _lock.ExitReadLock();
        }
    }

    public void Set(TKey key, TValue value)
    {
        _lock.EnterWriteLock();
        try
        {
            _cache[key] = value;
        }
        finally
        {
            _lock.ExitWriteLock();
        }
    }
}
```

---

## ConfigureAwait

### Library Code

```csharp
// ✅ In library code - use ConfigureAwait(false)
public async Task<Data> GetDataAsync(CancellationToken ct = default)
{
    var response = await _httpClient
        .GetAsync(url, ct)
        .ConfigureAwait(false);

    var content = await response.Content
        .ReadAsStringAsync(ct)
        .ConfigureAwait(false);

    return Parse(content);
}

// Application code (ASP.NET Core, Console apps) - ConfigureAwait not needed
// ASP.NET Core has no synchronization context
```

---

## Common Pitfalls

### Avoid Task.Run for Async Methods

```csharp
// ❌ WRONG - Unnecessary Task.Run for already async method
public async Task ProcessAsync()
{
    await Task.Run(async () =>
    {
        await DoAsyncWork(); // Already async, Task.Run adds overhead
    });
}

// ✅ CORRECT - Just await async method
public async Task ProcessAsync()
{
    await DoAsyncWork();
}

// ✅ CORRECT - Task.Run for CPU-bound work only
public async Task ProcessAsync()
{
    var result = await Task.Run(() => ExpensiveCpuCalculation());
    await SaveResultAsync(result);
}
```

### Avoid Async in Constructors

```csharp
// ❌ WRONG - Async in constructor
public class BadService
{
    private Data _data;

    public BadService()
    {
        _data = LoadDataAsync().Result; // Blocks and can deadlock
    }
}

// ✅ CORRECT - Factory method pattern
public class GoodService
{
    private readonly Data _data;

    private GoodService(Data data)
    {
        _data = data;
    }

    public static async Task<GoodService> CreateAsync(CancellationToken ct = default)
    {
        var data = await LoadDataAsync(ct);
        return new GoodService(data);
    }
}

// ✅ CORRECT - Lazy initialization
public class LazyService
{
    private readonly AsyncLazy<Data> _data;

    public LazyService()
    {
        _data = new AsyncLazy<Data>(LoadDataAsync);
    }

    public async Task<Result> DoWorkAsync(CancellationToken ct = default)
    {
        var data = await _data.Value;
        return Process(data);
    }
}
```

---

## Summary Checklist

When writing concurrent C# code, verify:

- [ ] Async all the way - no `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`
- [ ] No `async void` except for event handlers (with try-catch)
- [ ] `Async` suffix on all async methods
- [ ] `CancellationToken` as last parameter on all async methods
- [ ] `CancellationToken` passed to all async calls
- [ ] Independent operations run concurrently with `Task.WhenAll`
- [ ] `ConfigureAwait(false)` in library code
- [ ] `SemaphoreSlim` for throttling concurrent operations
- [ ] `Channel<T>` for producer-consumer patterns
- [ ] `Parallel.ForEachAsync` or PLINQ for CPU-bound parallel work
- [ ] No `Task.Run` wrapping async methods
- [ ] No async in constructors - use factory methods
- [ ] Concurrent or immutable collections for shared state
