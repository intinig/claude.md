---
name: csharp-error-handling
description: C# error handling patterns. Use when working with errors in C# code.
---

# C# Error Handling Patterns

## Core Principle

**Explicit error handling with meaningful context.** Use exceptions for exceptional circumstances, Result types for expected failures, and guard clauses for input validation. Never swallow exceptions silently.

---

## Exception Handling

### Never Swallow Exceptions

```csharp
// ❌ WRONG - Empty catch block
try
{
    await ProcessOrderAsync(order);
}
catch (Exception)
{
    // Silent failure - debugging nightmare
}

// ❌ WRONG - Catch and ignore
try
{
    await ProcessOrderAsync(order);
}
catch (Exception ex)
{
    _logger.LogError(ex, "Error occurred"); // Logged but not handled
}

// ✅ CORRECT - Handle or rethrow with context
try
{
    await ProcessOrderAsync(order);
}
catch (PaymentException ex)
{
    _logger.LogWarning(ex, "Payment failed for order {OrderId}", order.Id);
    throw new OrderProcessingException($"Failed to process order {order.Id}", ex);
}
```

### Catch Specific Exceptions

```csharp
// ❌ WRONG - Catching base Exception
try
{
    var user = await _repository.GetByIdAsync(id);
}
catch (Exception ex)
{
    return null; // Hides all errors including bugs
}

// ✅ CORRECT - Catch specific exceptions
try
{
    var user = await _repository.GetByIdAsync(id);
}
catch (EntityNotFoundException)
{
    return null; // Expected: user not found
}
catch (DbException ex)
{
    _logger.LogError(ex, "Database error fetching user {UserId}", id);
    throw; // Unexpected: let it propagate
}
```

### Preserve Stack Trace

```csharp
// ❌ WRONG - Loses stack trace
try
{
    DoSomething();
}
catch (Exception ex)
{
    throw ex; // Stack trace starts here, original location lost
}

// ✅ CORRECT - Preserves stack trace
try
{
    DoSomething();
}
catch (Exception)
{
    throw; // Original stack trace preserved
}

// ✅ CORRECT - Wrap with inner exception
try
{
    DoSomething();
}
catch (Exception ex)
{
    throw new ApplicationException("Operation failed", ex); // ex preserved
}
```

---

## Custom Exceptions

### Define Domain-Specific Exceptions

```csharp
// ✅ CORRECT - Domain exception with context
public class OrderNotFoundException : Exception
{
    public string OrderId { get; }

    public OrderNotFoundException(string orderId)
        : base($"Order '{orderId}' was not found")
    {
        OrderId = orderId;
    }

    public OrderNotFoundException(string orderId, Exception innerException)
        : base($"Order '{orderId}' was not found", innerException)
    {
        OrderId = orderId;
    }
}

// ✅ CORRECT - Validation exception with details
public class ValidationException : Exception
{
    public IReadOnlyList<ValidationError> Errors { get; }

    public ValidationException(IEnumerable<ValidationError> errors)
        : base("Validation failed")
    {
        Errors = errors.ToList();
    }
}

public record ValidationError(string Field, string Message);
```

### Exception Hierarchy

```csharp
// ✅ Domain exception base class
public abstract class DomainException : Exception
{
    public string Code { get; }

    protected DomainException(string code, string message)
        : base(message)
    {
        Code = code;
    }

    protected DomainException(string code, string message, Exception inner)
        : base(message, inner)
    {
        Code = code;
    }
}

// Specific exceptions
public class EntityNotFoundException : DomainException
{
    public EntityNotFoundException(string entityType, string id)
        : base("NOT_FOUND", $"{entityType} with ID '{id}' was not found")
    { }
}

public class BusinessRuleViolationException : DomainException
{
    public BusinessRuleViolationException(string rule)
        : base("BUSINESS_RULE_VIOLATION", rule)
    { }
}
```

---

## Result Pattern

### When to Use Result vs Exception

```csharp
// Use EXCEPTIONS for:
// - Truly exceptional conditions (network failures, database errors)
// - Programming errors (null references, invalid arguments)
// - Unrecoverable errors

// Use RESULT for:
// - Expected failure cases (validation, not found)
// - When caller needs to handle success/failure differently
// - Functional composition of operations
```

### Simple Result Type

```csharp
// ✅ Generic Result type
public readonly struct Result<T>
{
    public T? Value { get; }
    public string? Error { get; }
    public bool IsSuccess => Error is null;
    public bool IsFailure => !IsSuccess;

    private Result(T? value, string? error)
    {
        Value = value;
        Error = error;
    }

    public static Result<T> Success(T value) => new(value, null);
    public static Result<T> Failure(string error) => new(default, error);

    public TResult Match<TResult>(
        Func<T, TResult> onSuccess,
        Func<string, TResult> onFailure) =>
        IsSuccess ? onSuccess(Value!) : onFailure(Error!);
}

// Usage
public Result<User> GetUser(string id)
{
    var user = _repository.Find(id);
    return user is not null
        ? Result<User>.Success(user)
        : Result<User>.Failure($"User '{id}' not found");
}

// Consuming
var result = GetUser("123");
return result.Match(
    user => Ok(user),
    error => NotFound(error)
);
```

### Result with Error Type

```csharp
// ✅ Result with typed errors
public abstract record Error(string Code, string Message);
public record NotFoundError(string EntityType, string Id)
    : Error("NOT_FOUND", $"{EntityType} '{Id}' not found");
public record ValidationError(string Field, string Message)
    : Error("VALIDATION", $"{Field}: {Message}");

public readonly struct Result<T, TError> where TError : Error
{
    public T? Value { get; }
    public TError? Error { get; }
    public bool IsSuccess => Error is null;

    private Result(T? value, TError? error)
    {
        Value = value;
        Error = error;
    }

    public static Result<T, TError> Success(T value) => new(value, null);
    public static Result<T, TError> Failure(TError error) => new(default, error);
}
```

### Combining Results

```csharp
// ✅ Extension methods for Result composition
public static class ResultExtensions
{
    public static Result<TOut> Map<TIn, TOut>(
        this Result<TIn> result,
        Func<TIn, TOut> mapper) =>
        result.IsSuccess
            ? Result<TOut>.Success(mapper(result.Value!))
            : Result<TOut>.Failure(result.Error!);

    public static Result<TOut> Bind<TIn, TOut>(
        this Result<TIn> result,
        Func<TIn, Result<TOut>> binder) =>
        result.IsSuccess
            ? binder(result.Value!)
            : Result<TOut>.Failure(result.Error!);

    public static async Task<Result<TOut>> MapAsync<TIn, TOut>(
        this Task<Result<TIn>> resultTask,
        Func<TIn, TOut> mapper)
    {
        var result = await resultTask;
        return result.Map(mapper);
    }
}

// Usage - composing operations
public Result<OrderConfirmation> ProcessOrder(OrderRequest request) =>
    ValidateOrder(request)
        .Bind(CreateOrder)
        .Bind(ProcessPayment)
        .Map(CreateConfirmation);
```

---

## Guard Clauses

### Validate Early, Fail Fast

```csharp
// ❌ WRONG - Late validation, nested checks
public void ProcessOrder(Order? order)
{
    if (order != null)
    {
        if (order.Items != null)
        {
            if (order.Items.Count > 0)
            {
                // Finally do something
            }
        }
    }
}

// ✅ CORRECT - Guard clauses at the start
public void ProcessOrder(Order? order)
{
    ArgumentNullException.ThrowIfNull(order);

    if (order.Items is null || order.Items.Count == 0)
    {
        throw new ArgumentException("Order must have items", nameof(order));
    }

    // Now do the work with valid data
}
```

### Built-in Guard Methods (C# 10+)

```csharp
public void ProcessUser(string id, string? name, int age)
{
    // ✅ Use built-in guards
    ArgumentNullException.ThrowIfNull(id);
    ArgumentNullException.ThrowIfNullOrEmpty(name);
    ArgumentNullException.ThrowIfNullOrWhiteSpace(name);
    ArgumentOutOfRangeException.ThrowIfNegative(age);
    ArgumentOutOfRangeException.ThrowIfZero(age);
    ArgumentOutOfRangeException.ThrowIfGreaterThan(age, 150);
}
```

### Custom Guard Class

```csharp
public static class Guard
{
    public static T NotNull<T>(T? value, [CallerArgumentExpression(nameof(value))] string? name = null)
        where T : class =>
        value ?? throw new ArgumentNullException(name);

    public static string NotNullOrEmpty(string? value, [CallerArgumentExpression(nameof(value))] string? name = null) =>
        string.IsNullOrEmpty(value)
            ? throw new ArgumentException("Value cannot be null or empty", name)
            : value;

    public static T NotDefault<T>(T value, [CallerArgumentExpression(nameof(value))] string? name = null)
        where T : struct =>
        EqualityComparer<T>.Default.Equals(value, default)
            ? throw new ArgumentException("Value cannot be default", name)
            : value;

    public static int Positive(int value, [CallerArgumentExpression(nameof(value))] string? name = null) =>
        value <= 0
            ? throw new ArgumentOutOfRangeException(name, value, "Value must be positive")
            : value;
}

// Usage
public void CreateUser(string name, string email, int age)
{
    var validName = Guard.NotNullOrEmpty(name);
    var validEmail = Guard.NotNullOrEmpty(email);
    var validAge = Guard.Positive(age);
}
```

---

## Async Error Handling

### Async Exception Patterns

```csharp
// ❌ WRONG - async void (exceptions cannot be caught)
public async void ProcessAsync()
{
    await DoWorkAsync(); // Exception here crashes the app!
}

// ✅ CORRECT - async Task
public async Task ProcessAsync()
{
    await DoWorkAsync(); // Exception can be caught
}

// ✅ Proper async try-catch
public async Task<Result<Data>> FetchDataAsync(CancellationToken ct)
{
    try
    {
        var data = await _client.GetDataAsync(ct);
        return Result<Data>.Success(data);
    }
    catch (OperationCanceledException)
    {
        throw; // Always rethrow cancellation
    }
    catch (HttpRequestException ex)
    {
        _logger.LogWarning(ex, "Failed to fetch data");
        return Result<Data>.Failure("Failed to fetch data");
    }
}
```

### Handling Multiple Async Operations

```csharp
// ✅ When all must succeed - let exceptions propagate
public async Task ProcessAllAsync(IEnumerable<Item> items, CancellationToken ct)
{
    var tasks = items.Select(item => ProcessItemAsync(item, ct));
    await Task.WhenAll(tasks); // First exception thrown after all complete
}

// ✅ When partial success is OK - handle individually
public async Task<IReadOnlyList<Result<ProcessedItem>>> ProcessAllWithResultsAsync(
    IEnumerable<Item> items,
    CancellationToken ct)
{
    var tasks = items.Select(async item =>
    {
        try
        {
            var result = await ProcessItemAsync(item, ct);
            return Result<ProcessedItem>.Success(result);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            return Result<ProcessedItem>.Failure(ex.Message);
        }
    });

    return await Task.WhenAll(tasks);
}
```

---

## Exception Filters

### Use Exception Filters for Conditional Catching

```csharp
// ✅ Exception filters - catch conditionally
try
{
    await httpClient.GetAsync(url, ct);
}
catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.NotFound)
{
    return null; // Expected - resource not found
}
catch (HttpRequestException ex) when (ex.StatusCode == HttpStatusCode.TooManyRequests)
{
    await Task.Delay(1000, ct);
    return await RetryAsync(ct); // Retry for rate limiting
}
// Other HttpRequestException types propagate

// ✅ Filter with logging (logs but doesn't catch)
try
{
    DoWork();
}
catch (Exception ex) when (LogException(ex))
{
    // Never reached - LogException returns false
}

static bool LogException(Exception ex)
{
    Console.WriteLine($"Exception: {ex}");
    return false; // Return false to not catch
}
```

---

## Logging Errors

### Structured Logging

```csharp
// ❌ WRONG - String interpolation in log
catch (Exception ex)
{
    _logger.LogError($"Failed to process order {orderId}: {ex.Message}");
}

// ✅ CORRECT - Structured logging
catch (Exception ex)
{
    _logger.LogError(
        ex,
        "Failed to process order {OrderId} for customer {CustomerId}",
        orderId,
        customerId);
}
```

### Log Levels for Errors

```csharp
// ✅ Appropriate log levels
catch (EntityNotFoundException)
{
    _logger.LogWarning("User {UserId} not found", userId);
    return NotFound();
}
catch (ValidationException ex)
{
    _logger.LogInformation("Validation failed: {Errors}", ex.Errors);
    return BadRequest(ex.Errors);
}
catch (DbException ex)
{
    _logger.LogError(ex, "Database error fetching user {UserId}", userId);
    throw;
}
catch (Exception ex)
{
    _logger.LogCritical(ex, "Unexpected error in user service");
    throw;
}
```

---

## Global Exception Handling

### ASP.NET Core Exception Handler

```csharp
// ✅ Global exception handler middleware
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext context,
        Exception exception,
        CancellationToken ct)
    {
        _logger.LogError(exception, "Unhandled exception occurred");

        var (statusCode, response) = exception switch
        {
            EntityNotFoundException ex => (
                StatusCodes.Status404NotFound,
                new ProblemDetails
                {
                    Status = 404,
                    Title = "Not Found",
                    Detail = ex.Message
                }),
            ValidationException ex => (
                StatusCodes.Status400BadRequest,
                new ProblemDetails
                {
                    Status = 400,
                    Title = "Validation Error",
                    Detail = "One or more validation errors occurred",
                    Extensions = { ["errors"] = ex.Errors }
                }),
            _ => (
                StatusCodes.Status500InternalServerError,
                new ProblemDetails
                {
                    Status = 500,
                    Title = "Internal Server Error",
                    Detail = "An unexpected error occurred"
                })
        };

        context.Response.StatusCode = statusCode;
        await context.Response.WriteAsJsonAsync(response, ct);

        return true;
    }
}

// Registration
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
app.UseExceptionHandler();
```

---

## Polly for Resilience

### Retry Pattern

```csharp
using Polly;
using Polly.Retry;

// ✅ Configure retry policy
var retryPolicy = Policy
    .Handle<HttpRequestException>()
    .Or<TimeoutException>()
    .WaitAndRetryAsync(
        retryCount: 3,
        sleepDurationProvider: attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)),
        onRetry: (exception, delay, attempt, context) =>
        {
            _logger.LogWarning(
                exception,
                "Retry {Attempt} after {Delay}ms",
                attempt,
                delay.TotalMilliseconds);
        });

// Usage
var result = await retryPolicy.ExecuteAsync(async () =>
{
    return await _httpClient.GetStringAsync(url);
});
```

### Circuit Breaker

```csharp
// ✅ Circuit breaker prevents cascading failures
var circuitBreaker = Policy
    .Handle<HttpRequestException>()
    .CircuitBreakerAsync(
        exceptionsAllowedBeforeBreaking: 3,
        durationOfBreak: TimeSpan.FromSeconds(30),
        onBreak: (ex, duration) =>
            _logger.LogWarning("Circuit opened for {Duration}", duration),
        onReset: () =>
            _logger.LogInformation("Circuit closed"),
        onHalfOpen: () =>
            _logger.LogInformation("Circuit half-open"));
```

---

## Summary Checklist

When handling errors in C#, verify:

- [ ] No empty catch blocks
- [ ] Specific exceptions caught, not base `Exception`
- [ ] Stack trace preserved (`throw;` not `throw ex;`)
- [ ] Custom exceptions include context (entity IDs, etc.)
- [ ] Guard clauses at method start for validation
- [ ] Result type used for expected failures
- [ ] Exceptions used for truly exceptional cases
- [ ] `async Task` not `async void` (except event handlers)
- [ ] Cancellation exceptions rethrown, not swallowed
- [ ] Structured logging with message templates
- [ ] Global exception handler for uncaught exceptions
- [ ] Retry/circuit breaker for external service calls
