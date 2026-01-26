---
name: csharp-testing
description: C# testing patterns with xUnit/NUnit. Use when writing C# tests or test factories.
---

# C# Testing Patterns

## Core Principle

**Test behavior, not implementation.** Tests should verify what the code does, not how it does it. Use xUnit or NUnit with FluentAssertions for readable assertions and Moq/NSubstitute for test doubles.

---

## Test Framework Setup

### xUnit (Recommended)

```csharp
// ✅ xUnit test class - no attributes needed on class
public class UserServiceTests
{
    [Fact]
    public void CreateUser_WithValidData_ReturnsUser()
    {
        // Arrange, Act, Assert
    }

    [Theory]
    [InlineData("", false)]
    [InlineData("a", false)]
    [InlineData("valid@email.com", true)]
    public void ValidateEmail_ReturnsExpectedResult(string email, bool expected)
    {
        var result = EmailValidator.IsValid(email);
        Assert.Equal(expected, result);
    }
}
```

### NUnit Alternative

```csharp
// NUnit equivalent
[TestFixture]
public class UserServiceTests
{
    [Test]
    public void CreateUser_WithValidData_ReturnsUser()
    {
        // Arrange, Act, Assert
    }

    [TestCase("", false)]
    [TestCase("a", false)]
    [TestCase("valid@email.com", true)]
    public void ValidateEmail_ReturnsExpectedResult(string email, bool expected)
    {
        var result = EmailValidator.IsValid(email);
        Assert.That(result, Is.EqualTo(expected));
    }
}
```

---

## Test Organization

### Arrange-Act-Assert Pattern

```csharp
[Fact]
public async Task GetUserAsync_ExistingUser_ReturnsUser()
{
    // Arrange - Set up test data and dependencies
    var userId = "user-123";
    var expectedUser = new User(userId, "John Doe", "john@example.com");
    var repository = new FakeUserRepository();
    repository.Add(expectedUser);
    var service = new UserService(repository);

    // Act - Execute the behavior under test
    var result = await service.GetUserAsync(userId);

    // Assert - Verify the outcome
    Assert.NotNull(result);
    Assert.Equal(expectedUser.Id, result.Id);
    Assert.Equal(expectedUser.Name, result.Name);
}
```

### Test Naming Convention

```csharp
// Pattern: MethodName_Scenario_ExpectedBehavior

[Fact]
public void Add_TwoPositiveNumbers_ReturnsSum() { }

[Fact]
public void GetUser_NonExistentId_ReturnsNull() { }

[Fact]
public async Task CreateOrder_InsufficientStock_ThrowsInvalidOperationException() { }

[Fact]
public void Email_WithInvalidFormat_FailsValidation() { }
```

---

## FluentAssertions

### Basic Assertions

```csharp
using FluentAssertions;

[Fact]
public void User_Properties_AreSetCorrectly()
{
    var user = new User("1", "John", "john@example.com");

    // ❌ xUnit assertions (less readable)
    Assert.Equal("1", user.Id);
    Assert.Equal("John", user.Name);
    Assert.NotNull(user.Email);

    // ✅ FluentAssertions (more readable)
    user.Id.Should().Be("1");
    user.Name.Should().Be("John");
    user.Email.Should().NotBeNull();
    user.Email.Should().Contain("@");
}
```

### Collection Assertions

```csharp
[Fact]
public void GetUsers_ReturnsExpectedUsers()
{
    var users = service.GetUsers();

    // ✅ Collection assertions
    users.Should().HaveCount(3);
    users.Should().Contain(u => u.Name == "John");
    users.Should().NotContainNulls();
    users.Should().BeInAscendingOrder(u => u.Name);
    users.Should().AllSatisfy(u => u.IsActive.Should().BeTrue());
}
```

### Object Graph Assertions

```csharp
[Fact]
public void CreateUser_ReturnsCorrectUser()
{
    var result = service.CreateUser("John", "john@example.com");

    // ✅ Assert entire object structure
    result.Should().BeEquivalentTo(new
    {
        Name = "John",
        Email = "john@example.com",
        IsActive = true
    }, options => options.ExcludingMissingMembers());

    // ✅ Excluding specific properties
    result.Should().BeEquivalentTo(expectedUser, options => options
        .Excluding(u => u.Id)
        .Excluding(u => u.CreatedAt));
}
```

### Exception Assertions

```csharp
[Fact]
public void CreateUser_NullName_ThrowsArgumentNullException()
{
    // ❌ Old style
    Assert.Throws<ArgumentNullException>(() => service.CreateUser(null!, "email@test.com"));

    // ✅ FluentAssertions
    var act = () => service.CreateUser(null!, "email@test.com");

    act.Should().Throw<ArgumentNullException>()
       .WithParameterName("name");
}

[Fact]
public async Task GetUserAsync_NotFound_ThrowsNotFoundException()
{
    // ✅ Async exception assertion
    var act = async () => await service.GetUserAsync("nonexistent");

    await act.Should().ThrowAsync<NotFoundException>()
             .WithMessage("*not found*");
}
```

---

## Test Data Factories

### Factory Methods Over Fixtures

```csharp
// ❌ WRONG - Using class-level state
public class UserServiceTests
{
    private User _testUser;
    private IUserRepository _repository;

    [SetUp] // or [TestInitialize]
    public void Setup()
    {
        _testUser = new User("1", "John", "john@example.com");
        _repository = new FakeUserRepository();
    }

    [Test]
    public void Test1() { /* Uses shared _testUser */ }
    [Test]
    public void Test2() { /* Uses same _testUser - potential coupling */ }
}

// ✅ CORRECT - Factory methods
public class UserServiceTests
{
    [Fact]
    public void GetUser_ExistingUser_ReturnsUser()
    {
        var user = CreateUser();
        var repository = CreateRepository(user);
        var service = new UserService(repository);

        var result = service.GetUser(user.Id);

        result.Should().BeEquivalentTo(user);
    }

    // Factory methods - isolated per test
    private static User CreateUser(
        string? id = null,
        string? name = null,
        string? email = null) =>
        new(
            id ?? Guid.NewGuid().ToString(),
            name ?? "Test User",
            email ?? "test@example.com"
        );

    private static FakeUserRepository CreateRepository(params User[] users)
    {
        var repo = new FakeUserRepository();
        foreach (var user in users)
        {
            repo.Add(user);
        }
        return repo;
    }
}
```

### Builder Pattern for Complex Objects

```csharp
public class UserBuilder
{
    private string _id = Guid.NewGuid().ToString();
    private string _name = "Test User";
    private string _email = "test@example.com";
    private Role _role = Role.User;
    private bool _isActive = true;

    public UserBuilder WithId(string id) { _id = id; return this; }
    public UserBuilder WithName(string name) { _name = name; return this; }
    public UserBuilder WithEmail(string email) { _email = email; return this; }
    public UserBuilder WithRole(Role role) { _role = role; return this; }
    public UserBuilder AsInactive() { _isActive = false; return this; }

    public User Build() => new(_id, _name, _email, _role, _isActive);
}

// Usage in tests
[Fact]
public void DeactivateUser_AdminUser_Succeeds()
{
    var admin = new UserBuilder()
        .WithRole(Role.Admin)
        .Build();

    var target = new UserBuilder()
        .Build();

    var result = service.DeactivateUser(admin, target.Id);

    result.Should().BeTrue();
}
```

---

## Mocking with Moq

### Basic Mock Setup

```csharp
using Moq;

[Fact]
public async Task GetUserAsync_ExistingUser_ReturnsUser()
{
    // Arrange
    var userId = "user-123";
    var expectedUser = new User(userId, "John", "john@example.com");

    var mockRepository = new Mock<IUserRepository>();
    mockRepository
        .Setup(r => r.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
        .ReturnsAsync(expectedUser);

    var service = new UserService(mockRepository.Object);

    // Act
    var result = await service.GetUserAsync(userId);

    // Assert
    result.Should().BeEquivalentTo(expectedUser);
}
```

### Verifying Calls

```csharp
[Fact]
public async Task CreateUserAsync_SavesUserToRepository()
{
    // Arrange
    var mockRepository = new Mock<IUserRepository>();
    var service = new UserService(mockRepository.Object);

    // Act
    await service.CreateUserAsync("John", "john@example.com");

    // Assert - Verify the repository was called
    mockRepository.Verify(
        r => r.SaveAsync(
            It.Is<User>(u => u.Name == "John" && u.Email == "john@example.com"),
            It.IsAny<CancellationToken>()),
        Times.Once);
}

// ❌ WRONG - Over-verifying (testing implementation, not behavior)
mockRepository.Verify(r => r.GetByIdAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Exactly(2));
mockRepository.VerifyNoOtherCalls();
```

### Mock Sequences

```csharp
[Fact]
public async Task RetryLogic_FailsThenSucceeds()
{
    var mockService = new Mock<IExternalService>();

    // First call fails, second succeeds
    mockService
        .SetupSequence(s => s.CallAsync())
        .ThrowsAsync(new TimeoutException())
        .ReturnsAsync(new Response { Success = true });

    var service = new ServiceWithRetry(mockService.Object);

    var result = await service.CallWithRetryAsync();

    result.Success.Should().BeTrue();
    mockService.Verify(s => s.CallAsync(), Times.Exactly(2));
}
```

---

## NSubstitute Alternative

### Basic Substitution

```csharp
using NSubstitute;

[Fact]
public async Task GetUserAsync_ExistingUser_ReturnsUser()
{
    // Arrange
    var userId = "user-123";
    var expectedUser = new User(userId, "John", "john@example.com");

    var repository = Substitute.For<IUserRepository>();
    repository.GetByIdAsync(userId, Arg.Any<CancellationToken>())
              .Returns(expectedUser);

    var service = new UserService(repository);

    // Act
    var result = await service.GetUserAsync(userId);

    // Assert
    result.Should().BeEquivalentTo(expectedUser);
}
```

### Received Calls

```csharp
[Fact]
public async Task CreateUserAsync_SavesUser()
{
    var repository = Substitute.For<IUserRepository>();
    var service = new UserService(repository);

    await service.CreateUserAsync("John", "john@example.com");

    await repository.Received(1).SaveAsync(
        Arg.Is<User>(u => u.Name == "John"),
        Arg.Any<CancellationToken>());
}
```

---

## Fakes Over Mocks

### When to Use Fakes

```csharp
// ✅ PREFER - Fake implementation for complex interfaces
public class FakeUserRepository : IUserRepository
{
    private readonly Dictionary<string, User> _users = new();

    public Task<User?> GetByIdAsync(string id, CancellationToken ct = default)
    {
        _users.TryGetValue(id, out var user);
        return Task.FromResult(user);
    }

    public Task SaveAsync(User user, CancellationToken ct = default)
    {
        _users[user.Id] = user;
        return Task.CompletedTask;
    }

    public Task DeleteAsync(string id, CancellationToken ct = default)
    {
        _users.Remove(id);
        return Task.CompletedTask;
    }

    // Test helpers
    public void Add(User user) => _users[user.Id] = user;
    public bool Contains(string id) => _users.ContainsKey(id);
}

// Usage
[Fact]
public async Task DeleteUser_RemovesFromRepository()
{
    var user = CreateUser();
    var repository = new FakeUserRepository();
    repository.Add(user);
    var service = new UserService(repository);

    await service.DeleteUserAsync(user.Id);

    repository.Contains(user.Id).Should().BeFalse();
}
```

### Fake vs Mock Guidelines

```csharp
// Use FAKES when:
// - Interface has multiple methods used together
// - Testing stateful behavior
// - Multiple tests need same setup

// Use MOCKS when:
// - Verifying specific interactions
// - Interface is simple (1-2 methods)
// - Need to test error scenarios
```

---

## Async Testing

### Proper Async Test Pattern

```csharp
// ❌ WRONG - .Result or .Wait() blocks
[Fact]
public void GetUser_Async_Wrong()
{
    var result = service.GetUserAsync("123").Result; // Blocks!
    Assert.NotNull(result);
}

// ✅ CORRECT - async Task test
[Fact]
public async Task GetUserAsync_ExistingUser_ReturnsUser()
{
    var result = await service.GetUserAsync("123");
    result.Should().NotBeNull();
}

// ✅ CORRECT - Testing cancellation
[Fact]
public async Task GetUserAsync_Cancelled_ThrowsOperationCancelledException()
{
    using var cts = new CancellationTokenSource();
    cts.Cancel();

    var act = async () => await service.GetUserAsync("123", cts.Token);

    await act.Should().ThrowAsync<OperationCanceledException>();
}
```

### Testing Timeouts

```csharp
[Fact]
public async Task LongOperation_Timeout_Throws()
{
    using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(100));

    var act = async () => await service.LongOperationAsync(cts.Token);

    await act.Should().ThrowAsync<OperationCanceledException>();
}
```

---

## Theory/Parameterized Tests

### xUnit Theory with InlineData

```csharp
[Theory]
[InlineData("", false)]
[InlineData("a", false)]
[InlineData("ab", true)]
[InlineData("valid@email.com", true)]
public void ValidateEmail_ReturnsExpected(string email, bool expected)
{
    var result = EmailValidator.IsValid(email);
    result.Should().Be(expected);
}
```

### MemberData for Complex Data

```csharp
public class DiscountCalculatorTests
{
    [Theory]
    [MemberData(nameof(DiscountTestCases))]
    public void CalculateDiscount_ReturnsExpected(
        Order order,
        decimal expectedDiscount)
    {
        var result = DiscountCalculator.Calculate(order);
        result.Should().Be(expectedDiscount);
    }

    public static IEnumerable<object[]> DiscountTestCases()
    {
        yield return new object[]
        {
            new Order { Total = 50, CustomerType = CustomerType.Regular },
            0m
        };
        yield return new object[]
        {
            new Order { Total = 150, CustomerType = CustomerType.Regular },
            15m // 10% over $100
        };
        yield return new object[]
        {
            new Order { Total = 150, CustomerType = CustomerType.Premium },
            30m // 20% for premium
        };
    }
}
```

### ClassData for Reusable Test Data

```csharp
public class ValidEmailTestData : IEnumerable<object[]>
{
    public IEnumerator<object[]> GetEnumerator()
    {
        yield return new object[] { "test@example.com" };
        yield return new object[] { "user.name@domain.co.uk" };
        yield return new object[] { "user+tag@example.com" };
    }

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}

[Theory]
[ClassData(typeof(ValidEmailTestData))]
public void ValidateEmail_ValidEmails_ReturnsTrue(string email)
{
    EmailValidator.IsValid(email).Should().BeTrue();
}
```

---

## Integration Testing

### WebApplicationFactory Pattern

```csharp
public class ApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public ApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace real services with fakes
                services.RemoveAll<IUserRepository>();
                services.AddSingleton<IUserRepository, FakeUserRepository>();
            });
        }).CreateClient();
    }

    [Fact]
    public async Task GetUser_ExistingUser_ReturnsOk()
    {
        var response = await _client.GetAsync("/api/users/123");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task GetUser_NonExistent_ReturnsNotFound()
    {
        var response = await _client.GetAsync("/api/users/nonexistent");

        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
}
```

### Custom Factory with Test Configuration

```csharp
public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Use in-memory database
            services.RemoveAll<DbContextOptions<AppDbContext>>();
            services.AddDbContext<AppDbContext>(options =>
            {
                options.UseInMemoryDatabase("TestDb");
            });
        });

        builder.UseEnvironment("Testing");
    }
}
```

---

## Test Coverage Guidelines

### What to Test

```csharp
// ✅ DO test:
// - Business logic and domain rules
// - Edge cases and boundary conditions
// - Error handling paths
// - Integration points

// ❌ DON'T test:
// - Framework code (ASP.NET, EF Core internals)
// - Simple property getters/setters
// - Third-party library behavior
// - Private methods directly
```

### Coverage Through Behavior

```csharp
// ❌ WRONG - Testing implementation details
[Fact]
public void CreateUser_CallsValidatorFirst()
{
    mockValidator.Verify(v => v.Validate(It.IsAny<User>()), Times.Once);
    mockRepository.Verify(r => r.Save(It.IsAny<User>()), Times.Once);
}

// ✅ CORRECT - Testing behavior/outcome
[Fact]
public async Task CreateUser_InvalidEmail_ThrowsValidationException()
{
    var act = async () => await service.CreateUserAsync("John", "invalid-email");

    await act.Should().ThrowAsync<ValidationException>()
             .WithMessage("*email*");
}

[Fact]
public async Task CreateUser_ValidData_PersistsUser()
{
    await service.CreateUserAsync("John", "john@example.com");

    var saved = await repository.GetByEmailAsync("john@example.com");
    saved.Should().NotBeNull();
    saved!.Name.Should().Be("John");
}
```

---

## Summary Checklist

When writing C# tests, verify:

- [ ] Test names follow `Method_Scenario_Expected` pattern
- [ ] Tests use Arrange-Act-Assert structure
- [ ] Factory methods used instead of shared test state
- [ ] FluentAssertions used for readable assertions
- [ ] Async tests use `async Task`, not `.Result`
- [ ] Mocks verify behavior, not implementation details
- [ ] Fakes used for complex interfaces
- [ ] Theories used for parameterized test cases
- [ ] Tests are independent and can run in any order
- [ ] No `Thread.Sleep` - use async delays if needed
- [ ] CancellationToken tested for cancellation scenarios
