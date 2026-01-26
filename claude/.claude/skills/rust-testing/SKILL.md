---
name: rust-testing
description: Rust testing patterns. Use when writing Rust tests or test factories.
---

# Rust Testing Patterns

## Core Principle

**Test behavior, not implementation.** Tests verify WHAT the code does through its public API, not HOW it does it internally.

---

## Test Organization

### Unit Tests in Same File

```rust
// In src/user/service.rs
pub struct UserService { /* ... */ }

impl UserService {
    pub fn create(&self, email: &str) -> Result<User, UserError> {
        // Implementation
    }
}

// Unit tests at the bottom of the same file
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn creates_user_with_valid_email() {
        let service = UserService::new(MockRepo::new());
        let result = service.create("test@example.com");
        assert!(result.is_ok());
    }

    #[test]
    fn rejects_invalid_email() {
        let service = UserService::new(MockRepo::new());
        let result = service.create("invalid");
        assert!(matches!(result, Err(UserError::InvalidEmail(_))));
    }
}
```

### Integration Tests in tests/ Directory

```rust
// In tests/integration.rs
use my_crate::{UserService, User};

#[test]
fn full_user_workflow() {
    // Integration tests can only access public API
    let service = UserService::new(/* ... */);

    let user = service.create("test@example.com").unwrap();
    let fetched = service.get(&user.id).unwrap();

    assert_eq!(user.email, fetched.email);
}
```

### Doc Tests

```rust
/// Creates a new user with the given email.
///
/// # Examples
///
/// ```
/// use my_crate::User;
///
/// let user = User::new("test@example.com").unwrap();
/// assert_eq!(user.email, "test@example.com");
/// ```
///
/// # Errors
///
/// Returns `UserError::InvalidEmail` if email format is invalid:
///
/// ```
/// use my_crate::{User, UserError};
///
/// let result = User::new("invalid");
/// assert!(matches!(result, Err(UserError::InvalidEmail(_))));
/// ```
pub fn new(email: &str) -> Result<User, UserError> {
    // Implementation
}
```

---

## Test Factory Pattern

### Basic Factory with Default Trait

```rust
#[cfg(test)]
mod test_factories {
    use super::*;

    pub fn test_user() -> User {
        User {
            id: "user-123".to_string(),
            email: "test@example.com".to_string(),
            name: "Test User".to_string(),
            role: Role::User,
            created_at: chrono::Utc::now(),
        }
    }

    pub fn test_user_with_email(email: &str) -> User {
        User {
            email: email.to_string(),
            ..test_user()
        }
    }

    pub fn test_user_with_role(role: Role) -> User {
        User {
            role,
            ..test_user()
        }
    }
}

// Usage in tests
#[test]
fn admin_can_delete_users() {
    let admin = test_factories::test_user_with_role(Role::Admin);
    let service = UserService::new(admin);

    assert!(service.can_delete_users());
}
```

### Builder Pattern for Complex Test Data

```rust
#[cfg(test)]
mod test_factories {
    use super::*;

    #[derive(Default)]
    pub struct TestUserBuilder {
        id: Option<String>,
        email: Option<String>,
        name: Option<String>,
        role: Option<Role>,
    }

    impl TestUserBuilder {
        pub fn new() -> Self {
            Self::default()
        }

        pub fn id(mut self, id: impl Into<String>) -> Self {
            self.id = Some(id.into());
            self
        }

        pub fn email(mut self, email: impl Into<String>) -> Self {
            self.email = Some(email.into());
            self
        }

        pub fn name(mut self, name: impl Into<String>) -> Self {
            self.name = Some(name.into());
            self
        }

        pub fn role(mut self, role: Role) -> Self {
            self.role = Some(role);
            self
        }

        pub fn admin(self) -> Self {
            self.role(Role::Admin)
        }

        pub fn build(self) -> User {
            User {
                id: self.id.unwrap_or_else(|| "user-123".to_string()),
                email: self.email.unwrap_or_else(|| "test@example.com".to_string()),
                name: self.name.unwrap_or_else(|| "Test User".to_string()),
                role: self.role.unwrap_or(Role::User),
                created_at: chrono::Utc::now(),
            }
        }
    }

    pub fn test_user() -> TestUserBuilder {
        TestUserBuilder::new()
    }
}

// Usage
#[test]
fn admin_user_has_elevated_permissions() {
    let admin = test_factories::test_user()
        .email("admin@example.com")
        .admin()
        .build();

    assert!(admin.can_manage_users());
}
```

### Factory Composition

```rust
#[cfg(test)]
mod test_factories {
    pub fn test_order() -> Order {
        Order {
            id: "order-123".to_string(),
            user_id: "user-123".to_string(),
            items: vec![test_order_item()],
            total: 100.00,
            status: OrderStatus::Pending,
        }
    }

    pub fn test_order_item() -> OrderItem {
        OrderItem {
            id: "item-123".to_string(),
            product_id: "product-123".to_string(),
            quantity: 1,
            price: 25.00,
        }
    }

    pub fn test_order_with_items(items: Vec<OrderItem>) -> Order {
        Order {
            items,
            total: items.iter().map(|i| i.price * i.quantity as f64).sum(),
            ..test_order()
        }
    }
}

// Usage
#[test]
fn calculates_order_total_from_items() {
    let items = vec![
        OrderItem { price: 100.00, quantity: 2, ..test_order_item() },
        OrderItem { price: 50.00, quantity: 1, ..test_order_item() },
    ];
    let order = test_factories::test_order_with_items(items);

    assert_eq!(order.total, 250.00);
}
```

---

## Assertion Patterns

### Basic Assertions

```rust
#[test]
fn basic_assertions() {
    // Equality
    assert_eq!(2 + 2, 4);
    assert_ne!(2 + 2, 5);

    // Boolean
    assert!(result.is_ok());
    assert!(!list.is_empty());

    // With custom message
    assert_eq!(
        user.email, "test@example.com",
        "user email should be test@example.com, got {}",
        user.email
    );
}
```

### Pattern Matching with matches!

```rust
#[test]
fn error_type_assertions() {
    let result = validate_email("invalid");

    // Check error variant
    assert!(matches!(result, Err(UserError::InvalidEmail(_))));

    // Check Ok with condition
    assert!(matches!(result, Ok(email) if email.contains('@')));

    // Check enum variant with value
    assert!(matches!(
        status,
        Status::Error { code, .. } if code == 500
    ));
}
```

### Testing Result and Option

```rust
#[test]
fn testing_result() {
    let result: Result<User, Error> = create_user("test@example.com");

    // Check success
    assert!(result.is_ok());
    let user = result.unwrap();  // OK in tests
    assert_eq!(user.email, "test@example.com");

    // Check failure
    let result: Result<User, Error> = create_user("invalid");
    assert!(result.is_err());
    let error = result.unwrap_err();
    assert!(error.to_string().contains("invalid email"));
}

#[test]
fn testing_option() {
    let option: Option<User> = find_user("123");

    assert!(option.is_some());
    let user = option.unwrap();
    assert_eq!(user.id, "123");

    let none: Option<User> = find_user("nonexistent");
    assert!(none.is_none());
}
```

### Float Comparisons

```rust
#[test]
fn float_assertions() {
    let result = calculate_average(&[1.0, 2.0, 3.0]);

    // ❌ WRONG - Floating point equality is unreliable
    // assert_eq!(result, 2.0);

    // ✅ CORRECT - Use approximate comparison
    assert!((result - 2.0).abs() < f64::EPSILON);

    // Or use a crate like approx
    // assert_relative_eq!(result, 2.0);
}
```

---

## Mocking with Traits

### Interface-Based Mocking

```rust
// Define trait at consumer
trait UserRepository {
    fn get(&self, id: &str) -> Result<User, Error>;
    fn save(&self, user: &User) -> Result<(), Error>;
}

// Mock implementation for tests
#[cfg(test)]
struct MockUserRepository {
    users: std::collections::HashMap<String, User>,
    save_error: Option<Error>,
}

#[cfg(test)]
impl MockUserRepository {
    fn new() -> Self {
        Self {
            users: std::collections::HashMap::new(),
            save_error: None,
        }
    }

    fn with_user(mut self, user: User) -> Self {
        self.users.insert(user.id.clone(), user);
        self
    }

    fn with_save_error(mut self, error: Error) -> Self {
        self.save_error = Some(error);
        self
    }
}

#[cfg(test)]
impl UserRepository for MockUserRepository {
    fn get(&self, id: &str) -> Result<User, Error> {
        self.users
            .get(id)
            .cloned()
            .ok_or(Error::NotFound)
    }

    fn save(&self, _user: &User) -> Result<(), Error> {
        if let Some(ref error) = self.save_error {
            return Err(error.clone());
        }
        Ok(())
    }
}

// Usage
#[test]
fn returns_user_when_found() {
    let user = test_factories::test_user();
    let repo = MockUserRepository::new().with_user(user.clone());
    let service = UserService::new(repo);

    let result = service.get_user(&user.id);

    assert!(result.is_ok());
    assert_eq!(result.unwrap().email, user.email);
}

#[test]
fn returns_not_found_when_missing() {
    let repo = MockUserRepository::new();  // Empty
    let service = UserService::new(repo);

    let result = service.get_user("nonexistent");

    assert!(matches!(result, Err(Error::NotFound)));
}
```

### Using mockall Crate

```rust
use mockall::{automock, predicate::*};

#[automock]
trait UserRepository {
    fn get(&self, id: &str) -> Result<User, Error>;
    fn save(&self, user: &User) -> Result<(), Error>;
}

#[test]
fn saves_user_to_repository() {
    let mut mock = MockUserRepository::new();

    // Expect save to be called once with any user
    mock.expect_save()
        .times(1)
        .returning(|_| Ok(()));

    let service = UserService::new(mock);
    let result = service.create_user("test@example.com");

    assert!(result.is_ok());
}

#[test]
fn handles_save_failure() {
    let mut mock = MockUserRepository::new();

    mock.expect_save()
        .returning(|_| Err(Error::Database("connection failed".into())));

    let service = UserService::new(mock);
    let result = service.create_user("test@example.com");

    assert!(matches!(result, Err(Error::Database(_))));
}
```

### When NOT to Mock

```rust
// ❌ DON'T mock the code under test
// ❌ DON'T mock simple data structures
// ❌ DON'T mock standard library types (usually)

// ✅ DO mock external services (HTTP, database)
// ✅ DO mock time-dependent code
// ✅ DO mock file system operations
// ✅ DO mock random number generation
```

---

## Async Testing

### Basic Async Tests with tokio

```rust
#[tokio::test]
async fn fetches_user_from_api() {
    let client = MockApiClient::new();
    let service = UserService::new(client);

    let user = service.fetch_user("123").await.unwrap();

    assert_eq!(user.id, "123");
}
```

### Testing with Timeouts

```rust
use tokio::time::{timeout, Duration};

#[tokio::test]
async fn operation_completes_within_timeout() {
    let result = timeout(
        Duration::from_secs(5),
        slow_operation()
    ).await;

    assert!(result.is_ok(), "Operation timed out");
}

#[tokio::test]
async fn slow_operation_times_out() {
    let result = timeout(
        Duration::from_millis(100),
        very_slow_operation()
    ).await;

    assert!(result.is_err(), "Expected timeout");
}
```

### Testing Cancellation

```rust
use tokio::sync::oneshot;

#[tokio::test]
async fn respects_cancellation() {
    let (tx, rx) = oneshot::channel();

    let handle = tokio::spawn(async move {
        tokio::select! {
            _ = long_running_task() => panic!("Should have been cancelled"),
            _ = rx => Ok(()),
        }
    });

    // Cancel after short delay
    tokio::time::sleep(Duration::from_millis(10)).await;
    tx.send(()).unwrap();

    let result = handle.await.unwrap();
    assert!(result.is_ok());
}
```

---

## Property-Based Testing

### Using proptest

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn parses_and_formats_round_trip(s in "[a-zA-Z0-9]+@[a-zA-Z]+\\.[a-zA-Z]+") {
        let email = Email::parse(&s).unwrap();
        assert_eq!(email.to_string(), s);
    }

    #[test]
    fn amount_is_always_positive(amount in 1i64..=i64::MAX) {
        let money = Money::new(amount);
        assert!(money.amount() > 0);
    }
}

// Custom strategies
fn user_strategy() -> impl Strategy<Value = User> {
    (
        "[a-z]{5,10}",           // name
        "[a-z]+@example\\.com",  // email
        0u32..100,               // age
    ).prop_map(|(name, email, age)| User { name, email, age })
}

proptest! {
    #[test]
    fn serializes_and_deserializes(user in user_strategy()) {
        let json = serde_json::to_string(&user).unwrap();
        let parsed: User = serde_json::from_str(&json).unwrap();
        assert_eq!(user, parsed);
    }
}
```

---

## Test Helpers

### Custom Assertion Functions

```rust
#[cfg(test)]
fn assert_user_eq(actual: &User, expected: &User) {
    assert_eq!(actual.id, expected.id, "user id mismatch");
    assert_eq!(actual.email, expected.email, "user email mismatch");
    assert_eq!(actual.name, expected.name, "user name mismatch");
}

#[test]
fn updates_user_correctly() {
    let original = test_factories::test_user();
    let updated = update_user(&original, "new@example.com").unwrap();

    assert_user_eq(&updated, &User {
        email: "new@example.com".to_string(),
        ..original
    });
}
```

### Test Fixtures with Drop

```rust
struct TempDatabase {
    path: std::path::PathBuf,
    conn: Connection,
}

impl TempDatabase {
    fn new() -> Self {
        let path = std::env::temp_dir().join(format!("test-{}.db", uuid::Uuid::new_v4()));
        let conn = Connection::open(&path).unwrap();
        TempDatabase { path, conn }
    }
}

impl Drop for TempDatabase {
    fn drop(&mut self) {
        std::fs::remove_file(&self.path).ok();
    }
}

#[test]
fn database_test() {
    let db = TempDatabase::new();  // Created
    // ... use db.conn ...
}  // Automatically cleaned up when test ends
```

---

## Coverage Commands

```bash
# Using cargo-tarpaulin
cargo install cargo-tarpaulin
cargo tarpaulin --out Html --output-dir coverage

# Using llvm-cov (requires nightly or setup)
cargo install cargo-llvm-cov
cargo llvm-cov --html

# Run specific test
cargo test test_name

# Run tests matching pattern
cargo test user_

# Run tests in specific module
cargo test user::tests::

# Run with output shown
cargo test -- --nocapture

# Run tests in parallel (default)
cargo test

# Run tests serially
cargo test -- --test-threads=1

# Run ignored tests
cargo test -- --ignored

# Run all tests including ignored
cargo test -- --include-ignored
```

---

## Anti-Patterns

### Testing Implementation Details

```rust
// ❌ WRONG - Testing internal state
#[test]
fn test_internal_cache() {
    let service = UserService::new();
    service.get_user("123");

    // Testing internal cache state
    assert!(service.cache.contains_key("123"));
}

// ✅ CORRECT - Test observable behavior
#[test]
fn second_fetch_is_faster() {
    let service = UserService::new();

    let start = Instant::now();
    service.get_user("123");
    let first_duration = start.elapsed();

    let start = Instant::now();
    service.get_user("123");
    let second_duration = start.elapsed();

    assert!(second_duration < first_duration / 2);
}
```

### Shared Mutable State

```rust
// ❌ WRONG - Shared state between tests
static mut TEST_USER: Option<User> = None;

#[test]
fn test_a() {
    unsafe {
        TEST_USER = Some(create_user());
        TEST_USER.as_mut().unwrap().name = "Modified".to_string();
    }
}

#[test]
fn test_b() {
    // TEST_USER might be modified by test_a!
}

// ✅ CORRECT - Fresh state per test
#[test]
fn test_a() {
    let user = test_factories::test_user();
    // Use user...
}

#[test]
fn test_b() {
    let user = test_factories::test_user();  // Fresh instance
    // Use user...
}
```

### Testing Trivial Code

```rust
// ❌ WRONG - Testing getters
#[test]
fn test_get_name() {
    let user = User { name: "Test".to_string(), ..Default::default() };
    assert_eq!(user.name(), "Test");  // Pointless!
}

// ✅ CORRECT - Test meaningful behavior
#[test]
fn display_name_combines_first_and_last() {
    let user = User {
        first_name: "John".to_string(),
        last_name: "Doe".to_string(),
        ..Default::default()
    };
    assert_eq!(user.display_name(), "John Doe");
}
```

---

## Summary Checklist

When writing Rust tests, verify:

- [ ] Tests verify behavior through public API (not implementation)
- [ ] Unit tests in #[cfg(test)] module in same file
- [ ] Integration tests in tests/ directory
- [ ] Factory functions create fresh test data
- [ ] Using assert!, assert_eq!, matches! appropriately
- [ ] Mocking only external dependencies
- [ ] Async tests use #[tokio::test]
- [ ] No shared mutable state between tests
- [ ] No testing of trivial code
- [ ] Coverage checked with cargo-tarpaulin or llvm-cov
- [ ] Tests run with `cargo test`
