---
name: csharp-strict
description: C# best practices and patterns. Use when writing any C# code.
---

# C# Strict Mode

## Core Rules

1. **Nullable reference types enabled** - `#nullable enable` at file top
2. **No `null` returns** - where non-nullable declared
3. **Records for DTOs** - immutable data transfer objects
4. **Constructor injection only** - no property injection, no `new` for dependencies

---

## Nullable Reference Types

### Always Enable Nullable Context

```csharp
// ❌ WRONG - No nullable context
public class UserService
{
    private readonly ILogger _logger; // Could be null without warning
}

// ✅ CORRECT - Nullable enabled
#nullable enable

public class UserService
{
    private readonly ILogger _logger; // Compiler enforces non-null
}
```

### Never Return Null for Non-Nullable Types

```csharp
// ❌ WRONG - Returning null for non-nullable return type
public User GetUser(string id)
{
    var user = _repository.Find(id);
    return user; // Could be null!
}

// ✅ CORRECT - Return nullable when it can be null
public User? GetUser(string id)
{
    return _repository.Find(id);
}

// ✅ CORRECT - Or throw if null is exceptional
public User GetUserOrThrow(string id)
{
    return _repository.Find(id)
        ?? throw new UserNotFoundException(id);
}
```

### Use Null-Forgiving Operator Sparingly

```csharp
// ❌ WRONG - Overusing null-forgiving operator
var user = GetUser(id)!;  // Dangerous assumption
var name = user!.Name!;   // Multiple risky assumptions

// ✅ CORRECT - Handle nullability explicitly
var user = GetUser(id);
if (user is null)
{
    return NotFound();
}
var name = user.Name; // Safe: user is not null here

// ✅ CORRECT - Pattern matching
if (GetUser(id) is { } user)
{
    ProcessUser(user);
}
```

For detailed null handling patterns, load the `csharp-error-handling` skill.

---

## Records for Data Transfer

### Use Records for DTOs

```csharp
// ❌ WRONG - Class with mutable properties for DTO
public class UserDto
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
}

// ✅ CORRECT - Record for immutable DTO
public record UserDto(string Id, string Name, string Email);

// ✅ CORRECT - Record with init-only setters when needed
public record CreateUserRequest
{
    public required string Name { get; init; }
    public required string Email { get; init; }
    public string? PhoneNumber { get; init; }
}
```

### Records vs Classes

```csharp
// ✅ Use RECORDS for:
// - DTOs / API responses
// - Value objects
// - Immutable data containers
// - Configuration objects

public record Address(string Street, string City, string PostalCode);
public record ApiResponse<T>(T Data, string? Error = null);
public record ConnectionSettings(string Host, int Port, int TimeoutMs = 5000);

// ✅ Use CLASSES for:
// - Services with behavior
// - Entities with identity
// - Objects with mutable state
// - Framework requirements (e.g., EF Core entities)

public class UserService
{
    private readonly IUserRepository _repository;
    public UserService(IUserRepository repository) => _repository = repository;
}
```

### Record With-Expression for Updates

```csharp
// ❌ WRONG - Mutating record properties
var user = new UserDto("1", "John", "john@example.com");
user.Name = "Jane"; // Won't compile with positional records

// ✅ CORRECT - Use with-expression
var user = new UserDto("1", "John", "john@example.com");
var updated = user with { Name = "Jane" };
```

---

## Dependency Injection

### Constructor Injection Only

```csharp
// ❌ WRONG - Property injection
public class OrderService
{
    [Inject]
    public IPaymentGateway PaymentGateway { get; set; }
}

// ❌ WRONG - Creating dependencies internally
public class OrderService
{
    private readonly IPaymentGateway _paymentGateway = new StripeGateway();
}

// ❌ WRONG - Service locator pattern
public class OrderService
{
    public void ProcessOrder(Order order)
    {
        var gateway = ServiceLocator.GetService<IPaymentGateway>();
    }
}

// ✅ CORRECT - Constructor injection
public class OrderService
{
    private readonly IPaymentGateway _paymentGateway;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        IPaymentGateway paymentGateway,
        ILogger<OrderService> logger)
    {
        _paymentGateway = paymentGateway;
        _logger = logger;
    }
}
```

### Primary Constructors (C# 12+)

```csharp
// ✅ CORRECT - Primary constructor for simple DI
public class OrderService(
    IPaymentGateway paymentGateway,
    ILogger<OrderService> logger)
{
    public async Task ProcessOrderAsync(Order order)
    {
        logger.LogInformation("Processing order {OrderId}", order.Id);
        await paymentGateway.ChargeAsync(order.Total);
    }
}

// ✅ CORRECT - With field when needed for modification
public class CacheService(IMemoryCache cache)
{
    private readonly TimeSpan _defaultExpiration = TimeSpan.FromMinutes(5);

    public void Set<T>(string key, T value)
    {
        cache.Set(key, value, _defaultExpiration);
    }
}
```

### Register Services Explicitly

```csharp
// ❌ WRONG - Registration with concrete types
services.AddScoped<UserService>();

// ✅ CORRECT - Interface-based registration
services.AddScoped<IUserService, UserService>();

// ✅ CORRECT - With factory when complex initialization needed
services.AddScoped<IComplexService>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    return new ComplexService(config["ConnectionString"]);
});
```

---

## Interface Design

### Small Interfaces

```csharp
// ❌ WRONG - Large interface (too many responsibilities)
public interface IUserService
{
    Task<User> GetByIdAsync(string id);
    Task<User> GetByEmailAsync(string email);
    Task<IReadOnlyList<User>> GetAllAsync();
    Task CreateAsync(User user);
    Task UpdateAsync(User user);
    Task DeleteAsync(string id);
    Task<bool> ValidatePasswordAsync(string id, string password);
    Task ResetPasswordAsync(string email);
    Task SendVerificationEmailAsync(string id);
}

// ✅ CORRECT - Small, focused interfaces
public interface IUserReader
{
    Task<User?> GetByIdAsync(string id, CancellationToken ct = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken ct = default);
}

public interface IUserWriter
{
    Task CreateAsync(User user, CancellationToken ct = default);
    Task UpdateAsync(User user, CancellationToken ct = default);
}

public interface IPasswordService
{
    Task<bool> ValidateAsync(string userId, string password, CancellationToken ct = default);
    Task ResetAsync(string email, CancellationToken ct = default);
}
```

### Define Interfaces at Consumer

```csharp
// ❌ WRONG - Interface defined with implementation
// In Infrastructure/UserRepository.cs
public interface IUserRepository
{
    Task<User> GetByIdAsync(string id);
}

public class UserRepository : IUserRepository { }

// ✅ CORRECT - Interface defined at consumer
// In Domain/Ports/IUserReader.cs
public interface IUserReader
{
    Task<User?> GetByIdAsync(string id, CancellationToken ct = default);
}

// In Infrastructure/UserRepository.cs
public class UserRepository : IUserReader { }

// In Application/UserService.cs
public class UserService(IUserReader userReader) { }
```

---

## Naming Conventions

### Follow .NET Naming Guidelines

```csharp
// ❌ WRONG - Various naming violations
public class userService { }           // Should be PascalCase
public void getUserById() { }          // Should be PascalCase
private string Name;                   // Private field should be _camelCase
public const string default_value;     // Should be PascalCase

// ✅ CORRECT - Proper naming
public class UserService { }           // PascalCase for types
public void GetUserById() { }          // PascalCase for methods
private string _name;                  // _camelCase for private fields
public const string DefaultValue;      // PascalCase for constants
private readonly ILogger _logger;      // _camelCase for private readonly

// Interface naming
public interface IUserService { }      // I prefix for interfaces
public interface IEnumerable<T> { }    // I prefix even for generics
```

### Async Method Naming

```csharp
// ❌ WRONG - Missing Async suffix
public Task<User> GetUser(string id);
public Task SaveUser(User user);

// ✅ CORRECT - Async suffix for async methods
public Task<User> GetUserAsync(string id);
public Task SaveUserAsync(User user);

// Exception: Event handlers and interface implementations
// where the interface doesn't use Async suffix
```

---

## LINQ Best Practices

### Prefer Method Syntax

```csharp
// ✅ Both are acceptable, but method syntax often clearer
// Query syntax
var adults = from u in users
             where u.Age >= 18
             select u.Name;

// Method syntax (preferred for simple queries)
var adults = users
    .Where(u => u.Age >= 18)
    .Select(u => u.Name);
```

### Avoid Multiple Enumeration

```csharp
// ❌ WRONG - Multiple enumeration
IEnumerable<User> users = GetUsers();
var count = users.Count();           // First enumeration
var first = users.First();           // Second enumeration

// ✅ CORRECT - Materialize once
var users = GetUsers().ToList();
var count = users.Count;
var first = users[0];

// ✅ CORRECT - Or use IReadOnlyList
IReadOnlyList<User> users = GetUsers().ToList();
```

### Use Appropriate Collection Types

```csharp
// ❌ WRONG - Returning List when read-only needed
public List<User> GetUsers() { }

// ✅ CORRECT - Return most restrictive type
public IReadOnlyList<User> GetUsers() { }

// ❌ WRONG - Accepting List when only enumeration needed
public void ProcessUsers(List<User> users) { }

// ✅ CORRECT - Accept most general type
public void ProcessUsers(IEnumerable<User> users) { }
public void ProcessUsers(IReadOnlyList<User> users) { } // When count/index needed
```

---

## Expression-Bodied Members

### Use for Simple Members

```csharp
// ✅ CORRECT - Expression body for simple getters
public string FullName => $"{FirstName} {LastName}";
public bool IsAdult => Age >= 18;

// ✅ CORRECT - Expression body for simple methods
public override string ToString() => $"User({Id}, {Name})";
public User WithName(string name) => this with { Name = name };

// ❌ WRONG - Expression body for complex logic
public decimal CalculateTotal() =>
    Items.Where(i => i.IsActive)
         .Select(i => i.Price * i.Quantity)
         .Aggregate((a, b) => a + b - (a > 100 ? a * 0.1m : 0));

// ✅ CORRECT - Block body for complex logic
public decimal CalculateTotal()
{
    var activeItems = Items.Where(i => i.IsActive);
    var subtotal = activeItems.Sum(i => i.Price * i.Quantity);
    var discount = subtotal > 100 ? subtotal * 0.1m : 0;
    return subtotal - discount;
}
```

---

## Pattern Matching

### Use Modern Pattern Matching

```csharp
// ❌ WRONG - Old-style null/type checks
if (obj != null && obj is User)
{
    var user = (User)obj;
    if (user.Role == Role.Admin)
    {
        // ...
    }
}

// ✅ CORRECT - Pattern matching
if (obj is User { Role: Role.Admin } admin)
{
    // Use admin directly
}

// ✅ CORRECT - Switch expression
public string GetRoleDisplay(User user) => user.Role switch
{
    Role.Admin => "Administrator",
    Role.Moderator => "Moderator",
    Role.User => "Standard User",
    _ => "Unknown"
};

// ✅ CORRECT - Property patterns
public decimal CalculateDiscount(Order order) => order switch
{
    { Total: > 1000, Customer.IsPremium: true } => order.Total * 0.2m,
    { Total: > 1000 } => order.Total * 0.1m,
    { Customer.IsPremium: true } => order.Total * 0.05m,
    _ => 0
};
```

---

## Dispose Pattern

### Implement IDisposable Correctly

```csharp
// ❌ WRONG - Not disposing resources
public class DataProcessor
{
    private readonly HttpClient _client = new();
    // _client is never disposed!
}

// ✅ CORRECT - Proper IDisposable implementation
public class DataProcessor : IDisposable
{
    private readonly HttpClient _client = new();
    private bool _disposed;

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (_disposed) return;

        if (disposing)
        {
            _client.Dispose();
        }

        _disposed = true;
    }
}

// ✅ BETTER - Use using statement
public async Task ProcessDataAsync()
{
    using var client = new HttpClient();
    // client disposed at end of scope
}

// ✅ BEST - Inject IHttpClientFactory (no manual disposal)
public class DataProcessor(IHttpClientFactory clientFactory)
{
    public async Task ProcessDataAsync()
    {
        using var client = clientFactory.CreateClient();
        // ...
    }
}
```

### Async Dispose

```csharp
// ✅ CORRECT - IAsyncDisposable for async resources
public class AsyncDataProcessor : IAsyncDisposable
{
    private readonly SomeAsyncResource _resource;

    public async ValueTask DisposeAsync()
    {
        await _resource.CloseAsync();
        GC.SuppressFinalize(this);
    }
}

// Usage
await using var processor = new AsyncDataProcessor();
```

---

## File-Scoped Namespaces

### Use File-Scoped Namespaces

```csharp
// ❌ WRONG - Block-scoped namespace (extra indentation)
namespace MyApp.Services
{
    public class UserService
    {
        // ...
    }
}

// ✅ CORRECT - File-scoped namespace (C# 10+)
namespace MyApp.Services;

public class UserService
{
    // ...
}
```

---

## Global Usings

### Organize Global Usings

```csharp
// In GlobalUsings.cs or Directory.Build.props
global using System;
global using System.Collections.Generic;
global using System.Linq;
global using System.Threading;
global using System.Threading.Tasks;

// Project-specific
global using Microsoft.Extensions.Logging;
global using MyApp.Domain.Models;
```

---

## Summary Checklist

When writing C# code, verify:

- [ ] `#nullable enable` at file top (or in project settings)
- [ ] No `null` returned where non-nullable declared
- [ ] Records used for DTOs and value objects
- [ ] Constructor injection for all dependencies
- [ ] No `new` for services inside other services
- [ ] Interfaces are small (1-3 methods)
- [ ] Interfaces defined at consumer, not provider
- [ ] Proper naming (PascalCase types, _camelCase fields)
- [ ] `Async` suffix on async methods
- [ ] No multiple enumeration of IEnumerable
- [ ] `IReadOnlyList<T>` for return types when appropriate
- [ ] Using statements for disposables
- [ ] File-scoped namespaces
- [ ] Pattern matching used where appropriate
