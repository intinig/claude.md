---
name: rust-strict
description: Rust best practices and patterns. Use when writing any Rust code.
---

# Rust Strict Mode

## Core Rules

1. **Ownership is explicit** - work with the borrow checker, not against it
2. **No unwrap() in production** - use Result and proper error handling
3. **Prefer references over cloning** - only clone when semantically correct
4. **Small traits** - define at consumer, not provider

---

## Ownership and Borrowing

### When to Move vs Borrow

```rust
// ❌ WRONG - Unnecessary ownership transfer
fn process_name(name: String) {
    println!("{}", name);
}

let name = String::from("Alice");
process_name(name);
// name is moved, can't use it anymore!

// ✅ CORRECT - Borrow when you only need to read
fn process_name(name: &str) {
    println!("{}", name);
}

let name = String::from("Alice");
process_name(&name);
// name is still valid!
```

### Mutable vs Immutable References

```rust
// ❌ WRONG - Taking mutable reference when immutable is enough
fn validate_email(email: &mut String) -> bool {
    email.contains('@')
}

// ✅ CORRECT - Use immutable reference for read-only operations
fn validate_email(email: &str) -> bool {
    email.contains('@')
}

// ✅ CORRECT - Mutable reference when modification is needed
fn normalize_email(email: &mut String) {
    *email = email.to_lowercase();
}
```

### Choosing Between &T, &mut T, and T

```rust
// Use &T (immutable borrow) when:
// - You only need to read the data
// - Multiple readers are fine
fn display_user(user: &User) {
    println!("{}: {}", user.name, user.email);
}

// Use &mut T (mutable borrow) when:
// - You need to modify the data
// - You need exclusive access
fn update_email(user: &mut User, email: String) {
    user.email = email;
}

// Use T (owned) when:
// - The function needs to take ownership
// - The function consumes the value
// - You're storing it in a struct
fn store_user(storage: &mut Vec<User>, user: User) {
    storage.push(user);  // Needs ownership to store
}
```

### Avoid Unnecessary Cloning

```rust
// ❌ WRONG - Clone abuse to satisfy borrow checker
fn process_users(users: Vec<User>) {
    for user in users.clone() {
        validate(&user);
    }
    // Now use users again...
    save_users(users);
}

// ✅ CORRECT - Borrow the iterator
fn process_users(users: Vec<User>) {
    for user in &users {
        validate(user);
    }
    save_users(users);
}

// ❌ WRONG - Cloning when a reference would work
fn get_name(user: &User) -> String {
    user.name.clone()  // Unnecessary clone
}

// ✅ CORRECT - Return a reference
fn get_name(user: &User) -> &str {
    &user.name
}
```

---

## Lifetime Annotations

### When Lifetimes Are Required

```rust
// Lifetimes are elided (implicit) for simple cases
fn first_word(s: &str) -> &str {
    s.split_whitespace().next().unwrap_or("")
}

// Lifetimes required when multiple references are involved
// ❌ WRONG - Compiler can't determine which lifetime to use
fn longest(x: &str, y: &str) -> &str {
    if x.len() > y.len() { x } else { y }
}

// ✅ CORRECT - Explicit lifetime annotation
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

### Lifetimes in Structs

```rust
// ✅ CORRECT - Struct holding reference needs lifetime
struct Parser<'a> {
    input: &'a str,
    position: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a str) -> Self {
        Parser { input, position: 0 }
    }

    fn remaining(&self) -> &'a str {
        &self.input[self.position..]
    }
}

// ❌ WRONG - Returning reference to local data
fn get_greeting() -> &str {
    let s = String::from("Hello");
    &s  // Error: s is dropped here!
}

// ✅ CORRECT - Return owned String or static str
fn get_greeting() -> String {
    String::from("Hello")
}

fn get_static_greeting() -> &'static str {
    "Hello"  // String literals are 'static
}
```

### Common Lifetime Patterns

```rust
// Same lifetime for input and output - most common
fn extract_domain<'a>(email: &'a str) -> Option<&'a str> {
    email.split('@').nth(1)
}

// Different lifetimes when they're independent
fn find_in<'a, 'b>(haystack: &'a str, needle: &'b str) -> Option<&'a str> {
    haystack.find(needle).map(|i| &haystack[i..])
}

// 'static for owned data that lives forever
static ADMIN_EMAIL: &str = "admin@example.com";
```

---

## Error Handling Basics

### Never Use unwrap() in Production

```rust
// ❌ WRONG - Will panic if user not found
fn get_user_email(id: &str) -> String {
    let user = find_user(id).unwrap();
    user.email.clone()
}

// ❌ WRONG - expect() is just panic with a message
fn get_user_email(id: &str) -> String {
    let user = find_user(id).expect("user must exist");
    user.email.clone()
}

// ✅ CORRECT - Return Result and propagate errors
fn get_user_email(id: &str) -> Result<String, UserError> {
    let user = find_user(id)?;
    Ok(user.email.clone())
}

// ✅ CORRECT - Return Option if absence is expected
fn get_user_email(id: &str) -> Option<String> {
    let user = find_user(id)?;
    Some(user.email.clone())
}
```

### When unwrap() IS Acceptable

```rust
// ✅ OK - In tests
#[test]
fn test_user_creation() {
    let user = create_user("test@example.com").unwrap();
    assert_eq!(user.email, "test@example.com");
}

// ✅ OK - When you've proven it can't fail
let parsed: u32 = "42".parse().unwrap();  // Literal string, known to be valid

// ✅ OK - In example code / documentation
/// # Examples
/// ```
/// let result = calculate(10).unwrap();
/// ```

// ❌ NEVER - In library or application code paths
```

For detailed error handling patterns, load the `rust-error-handling` skill.

---

## Trait Design

### Small, Focused Traits

```rust
// ❌ WRONG - Too many methods, hard to implement and mock
trait UserService {
    fn create(&self, user: User) -> Result<User, Error>;
    fn get(&self, id: &str) -> Result<User, Error>;
    fn update(&self, user: User) -> Result<User, Error>;
    fn delete(&self, id: &str) -> Result<(), Error>;
    fn list(&self) -> Result<Vec<User>, Error>;
    fn search(&self, query: &str) -> Result<Vec<User>, Error>;
    fn authenticate(&self, email: &str, password: &str) -> Result<User, Error>;
}

// ✅ CORRECT - Small, focused traits
trait UserReader {
    fn get(&self, id: &str) -> Result<User, Error>;
}

trait UserWriter {
    fn create(&self, user: User) -> Result<User, Error>;
    fn update(&self, user: User) -> Result<User, Error>;
}

trait UserDeleter {
    fn delete(&self, id: &str) -> Result<(), Error>;
}

// Compose when needed
trait UserStore: UserReader + UserWriter + UserDeleter {}
```

### Define Traits at Consumer

```rust
// ❌ WRONG - Trait defined with the implementation
// In database module:
pub trait UserRepository {
    fn get(&self, id: &str) -> Result<User, Error>;
    fn save(&self, user: User) -> Result<(), Error>;
}

pub struct PostgresUserRepository { /* ... */ }
impl UserRepository for PostgresUserRepository { /* ... */ }

// ✅ CORRECT - Trait defined where it's used
// In service module (consumer):
pub trait UserGetter {
    fn get(&self, id: &str) -> Result<User, Error>;
}

pub struct UserService<R: UserGetter> {
    repo: R,
}

// In database module (provider) - no trait, just implementation:
pub struct PostgresUserRepository { /* ... */ }

impl UserGetter for PostgresUserRepository {
    fn get(&self, id: &str) -> Result<User, Error> {
        // Implementation
    }
}
```

### Accept Traits, Return Concrete Types

```rust
// ❌ WRONG - Returning trait object unnecessarily
fn create_service() -> Box<dyn UserService> {
    Box::new(ConcreteService::new())
}

// ✅ CORRECT - Return concrete type
fn create_service() -> ConcreteService {
    ConcreteService::new()
}

// ✅ CORRECT - Accept trait bounds in generics
fn process_users<R: UserReader>(reader: &R) -> Result<(), Error> {
    let user = reader.get("123")?;
    // ...
    Ok(())
}

// ✅ CORRECT - impl Trait for simpler signatures
fn process_users(reader: &impl UserReader) -> Result<(), Error> {
    let user = reader.get("123")?;
    // ...
    Ok(())
}
```

### Trait Bounds vs Trait Objects

```rust
// Generics with trait bounds (monomorphization, zero-cost)
// Use when: performance matters, type is known at compile time
fn notify<T: Display>(item: &T) {
    println!("{}", item);
}

// Trait objects (dynamic dispatch, runtime cost)
// Use when: heterogeneous collections, runtime polymorphism needed
fn notify_all(items: &[&dyn Display]) {
    for item in items {
        println!("{}", item);
    }
}

// ✅ Prefer generics when possible
fn process<R: UserReader>(reader: R) {}

// ✅ Use trait objects when you need heterogeneous types
struct EventHandler {
    handlers: Vec<Box<dyn Fn(&Event)>>,
}
```

---

## Naming Conventions

### Case Conventions

```rust
// ✅ CORRECT - snake_case for functions, methods, variables, modules
fn calculate_total(items: &[Item]) -> f64
let user_count = users.len();
mod user_service;

// ✅ CORRECT - PascalCase for types, traits, enums
struct UserAccount { /* ... */ }
trait Serializable { /* ... */ }
enum PaymentStatus { Pending, Completed, Failed }

// ✅ CORRECT - SCREAMING_SNAKE_CASE for constants
const MAX_CONNECTIONS: u32 = 100;
static DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);
```

### No Get Prefix

```rust
// ❌ WRONG - Get prefix is redundant
impl User {
    fn get_name(&self) -> &str { &self.name }
    fn get_email(&self) -> &str { &self.email }
    fn get_id(&self) -> &str { &self.id }
}

// ✅ CORRECT - Direct accessors without Get prefix
impl User {
    fn name(&self) -> &str { &self.name }
    fn email(&self) -> &str { &self.email }
    fn id(&self) -> &str { &self.id }
}

// ✅ CORRECT - Descriptive names for transformations
impl User {
    fn display_name(&self) -> String {
        format!("{} <{}>", self.name, self.email)
    }
}
```

### Builder and Constructor Naming

```rust
// ✅ CORRECT - new() for default constructor
impl Service {
    pub fn new(config: Config) -> Self {
        Service { config, /* ... */ }
    }
}

// ✅ CORRECT - with_* for builder methods
impl ServerBuilder {
    pub fn with_port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }

    pub fn with_timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }
}

// ✅ CORRECT - from_* for conversions
impl User {
    pub fn from_dto(dto: UserDto) -> Result<Self, ValidationError> {
        // ...
    }
}

// ✅ CORRECT - into_* for consuming conversions
impl User {
    pub fn into_dto(self) -> UserDto {
        // ...
    }
}
```

---

## Struct Patterns

### Constructor Functions

```rust
// ❌ WRONG - No constructor, caller must know internals
pub struct Service {
    pub db: Database,
    pub cache: Cache,
    pub logger: Logger,
}

// Usage requires knowing all fields
let service = Service {
    db: database,
    cache: cache,
    logger: logger,
};

// ✅ CORRECT - Constructor function with unexported fields
pub struct Service {
    db: Database,
    cache: Cache,
    logger: Logger,
}

impl Service {
    pub fn new(db: Database, cache: Cache, logger: Logger) -> Self {
        Service { db, cache, logger }
    }
}

// Clean usage
let service = Service::new(database, cache, logger);
```

### Builder Pattern

```rust
// ✅ CORRECT - Builder for complex construction
#[derive(Default)]
pub struct ServerBuilder {
    port: Option<u16>,
    timeout: Option<Duration>,
    max_connections: Option<u32>,
}

impl ServerBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn port(mut self, port: u16) -> Self {
        self.port = Some(port);
        self
    }

    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }

    pub fn max_connections(mut self, max: u32) -> Self {
        self.max_connections = Some(max);
        self
    }

    pub fn build(self) -> Result<Server, ConfigError> {
        Ok(Server {
            port: self.port.unwrap_or(8080),
            timeout: self.timeout.unwrap_or(Duration::from_secs(30)),
            max_connections: self.max_connections.unwrap_or(100),
        })
    }
}

// Usage
let server = ServerBuilder::new()
    .port(3000)
    .timeout(Duration::from_secs(60))
    .build()?;
```

### Default Trait

```rust
// ✅ CORRECT - Implement Default for sensible defaults
#[derive(Default)]
pub struct Config {
    pub port: u16,
    pub debug: bool,
    pub max_retries: u32,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            port: 8080,
            debug: false,
            max_retries: 3,
        }
    }
}

// Usage with partial override
let config = Config {
    port: 3000,
    ..Default::default()
};
```

### Newtype Pattern

```rust
// ✅ CORRECT - Type safety for primitives
pub struct UserId(String);
pub struct Email(String);
pub struct Amount(f64);

impl UserId {
    pub fn new(id: impl Into<String>) -> Self {
        UserId(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// Now these can't be confused:
fn create_order(user_id: UserId, email: Email, amount: Amount) {
    // Type system prevents mixing up parameters
}

// ❌ Compile error - can't pass Email where UserId expected
// create_order(email, user_id, amount);
```

---

## Module Organization

### Standard Layout

```
my_crate/
├── src/
│   ├── lib.rs           # Library root, pub mod declarations
│   ├── main.rs          # Binary entry point (optional)
│   ├── user/
│   │   ├── mod.rs       # Module root
│   │   ├── service.rs
│   │   └── repository.rs
│   └── order/
│       ├── mod.rs
│       ├── service.rs
│       └── types.rs
├── tests/               # Integration tests
│   └── integration.rs
└── Cargo.toml
```

### Visibility Modifiers

```rust
// pub - Public to all external users
pub struct User { /* ... */ }

// pub(crate) - Public within crate only
pub(crate) fn internal_helper() { /* ... */ }

// pub(super) - Public to parent module
pub(super) struct ModuleHelper { /* ... */ }

// Private (default) - Only within current module
struct PrivateHelper { /* ... */ }

// ✅ CORRECT - Expose clean API, hide internals
pub mod user {
    mod repository;  // Private
    mod validation;  // Private

    pub use repository::PostgresRepository;  // Re-export what's needed
    pub use validation::validate_email;

    pub struct User { /* ... */ }
}
```

### Re-exports for Clean APIs

```rust
// In lib.rs - create a clean public API
pub mod error;
pub mod user;
pub mod order;

// Re-export commonly used types at crate root
pub use error::{Error, Result};
pub use user::User;
pub use order::Order;

// Users can import simply:
// use my_crate::{User, Order, Error};
```

---

## Dependency Injection

### Inject Dependencies, Don't Create Them

```rust
// ❌ WRONG - Creating dependencies internally
pub struct OrderService {
    db: Database,
}

impl OrderService {
    pub fn new(db: Database) -> Self {
        OrderService { db }
    }

    pub fn create_order(&self, order: Order) -> Result<(), Error> {
        // Creating dependency internally - hard to test!
        let email_service = EmailService::new();
        email_service.send(&order.user_email, "Order created")?;
        self.db.save(&order)
    }
}

// ✅ CORRECT - Inject all dependencies
pub struct OrderService<E: EmailSender> {
    db: Database,
    email: E,
}

impl<E: EmailSender> OrderService<E> {
    pub fn new(db: Database, email: E) -> Self {
        OrderService { db, email }
    }

    pub fn create_order(&self, order: Order) -> Result<(), Error> {
        self.email.send(&order.user_email, "Order created")?;
        self.db.save(&order)
    }
}

// Easy to test with mock
struct MockEmailSender;
impl EmailSender for MockEmailSender {
    fn send(&self, _to: &str, _msg: &str) -> Result<(), Error> {
        Ok(())
    }
}
```

### Wire Dependencies at Main

```rust
fn main() -> Result<(), Error> {
    // Create all dependencies
    let config = Config::from_env()?;
    let db = Database::connect(&config.database_url)?;
    let email = SmtpEmailService::new(&config.smtp_config);
    let logger = Logger::new(&config.log_level);

    // Wire them together
    let user_repo = PostgresUserRepository::new(db.clone());
    let user_service = UserService::new(user_repo, logger.clone());
    let order_service = OrderService::new(db, email, logger);

    // Create application
    let app = Application::new(user_service, order_service);

    // Run
    app.run()
}
```

---

## Summary Checklist

When writing Rust code, verify:

- [ ] Borrowing preferred over cloning (only clone when semantically needed)
- [ ] No unwrap()/expect() in production code paths
- [ ] Errors propagated with ? operator
- [ ] Traits are small (1-3 methods)
- [ ] Traits defined at consumer, not provider
- [ ] snake_case for functions/variables, PascalCase for types
- [ ] No Get prefix on accessors (name() not get_name())
- [ ] Constructor functions for structs (new(), build())
- [ ] Builder pattern for complex configuration
- [ ] Dependencies injected, not created internally
- [ ] `cargo clippy` passes with no warnings
- [ ] `cargo fmt` produces no changes
