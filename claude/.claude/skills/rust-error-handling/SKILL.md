---
name: rust-error-handling
description: Rust error handling patterns. Use when working with errors in Rust code.
---

# Rust Error Handling Patterns

## Core Principle

**Errors are values, encoded in the type system.** Use `Result<T, E>` for recoverable errors, reserve `panic!` for truly unrecoverable situations.

---

## Result<T, E> Fundamentals

### Basic Usage

```rust
// Result has two variants: Ok(T) and Err(E)
enum Result<T, E> {
    Ok(T),
    Err(E),
}

// ✅ CORRECT - Return Result for operations that can fail
fn parse_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)?;
    let config: Config = toml::from_str(&content)?;
    Ok(config)
}

// ✅ CORRECT - Pattern match to handle both cases
match parse_config("config.toml") {
    Ok(config) => println!("Loaded config: {:?}", config),
    Err(e) => eprintln!("Failed to load config: {}", e),
}
```

### Converting Between Result Types

```rust
// map - Transform the Ok value
let result: Result<i32, Error> = "42".parse();
let doubled: Result<i32, Error> = result.map(|n| n * 2);

// map_err - Transform the Err value
let result: Result<i32, ParseIntError> = "abc".parse();
let result: Result<i32, MyError> = result.map_err(MyError::Parse);

// and_then - Chain operations that return Result
fn get_user(id: &str) -> Result<User, Error> { /* ... */ }
fn get_orders(user: &User) -> Result<Vec<Order>, Error> { /* ... */ }

let orders = get_user("123")
    .and_then(|user| get_orders(&user));

// ok_or / ok_or_else - Convert Option to Result
let maybe_user: Option<User> = find_user("123");
let user: Result<User, Error> = maybe_user.ok_or(Error::NotFound)?;
```

---

## The ? Operator

### Basic Error Propagation

```rust
// ❌ WRONG - Verbose manual matching
fn get_user_email(id: &str) -> Result<String, Error> {
    let user = match find_user(id) {
        Ok(u) => u,
        Err(e) => return Err(e.into()),
    };
    let profile = match get_profile(&user) {
        Ok(p) => p,
        Err(e) => return Err(e.into()),
    };
    Ok(profile.email)
}

// ✅ CORRECT - Use ? operator
fn get_user_email(id: &str) -> Result<String, Error> {
    let user = find_user(id)?;
    let profile = get_profile(&user)?;
    Ok(profile.email)
}
```

### ? Requires From Trait

```rust
// ? automatically converts errors using From trait
// This works because DatabaseError: Into<AppError>

#[derive(Debug)]
enum AppError {
    Database(DatabaseError),
    Validation(ValidationError),
}

impl From<DatabaseError> for AppError {
    fn from(err: DatabaseError) -> Self {
        AppError::Database(err)
    }
}

impl From<ValidationError> for AppError {
    fn from(err: ValidationError) -> Self {
        AppError::Validation(err)
    }
}

// Now ? works automatically
fn process_user(id: &str) -> Result<(), AppError> {
    let user = db.find_user(id)?;  // DatabaseError -> AppError
    validate_user(&user)?;          // ValidationError -> AppError
    Ok(())
}
```

### Using ? in main()

```rust
// ✅ CORRECT - main can return Result
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = load_config()?;
    let app = Application::new(config)?;
    app.run()?;
    Ok(())
}

// ✅ CORRECT - With anyhow for better ergonomics
use anyhow::Result;

fn main() -> Result<()> {
    let config = load_config()?;
    let app = Application::new(config)?;
    app.run()?;
    Ok(())
}
```

---

## Custom Error Types with thiserror

### Defining Error Enums

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UserError {
    #[error("user not found: {0}")]
    NotFound(String),

    #[error("invalid email format: {0}")]
    InvalidEmail(String),

    #[error("user already exists")]
    AlreadyExists,

    #[error("database error")]
    Database(#[from] DatabaseError),

    #[error("validation failed: {field}")]
    Validation {
        field: String,
        #[source]
        cause: ValidationError,
    },
}
```

### Using #[from] for Automatic Conversion

```rust
#[derive(Error, Debug)]
pub enum ServiceError {
    #[error("user error")]
    User(#[from] UserError),

    #[error("order error")]
    Order(#[from] OrderError),

    #[error("io error")]
    Io(#[from] std::io::Error),
}

// Now ? automatically converts
fn process() -> Result<(), ServiceError> {
    let user = get_user()?;  // UserError -> ServiceError
    let order = create_order(&user)?;  // OrderError -> ServiceError
    save_to_file(&order)?;  // io::Error -> ServiceError
    Ok(())
}
```

### Using #[source] for Error Chains

```rust
#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("failed to read config file")]
    Read(#[source] std::io::Error),

    #[error("failed to parse config")]
    Parse(#[source] toml::de::Error),

    #[error("invalid value for {key}: {message}")]
    InvalidValue {
        key: String,
        message: String,
    },
}

// The source() method returns the underlying cause
fn handle_error(err: ConfigError) {
    eprintln!("Error: {}", err);
    if let Some(source) = err.source() {
        eprintln!("Caused by: {}", source);
    }
}
```

---

## Application Errors with anyhow

### When to Use anyhow vs thiserror

```rust
// thiserror - For libraries, when callers need to match on error variants
// anyhow - For applications, when you just need to propagate and display errors

// ✅ Library code - use thiserror
// (in my_library/src/error.rs)
#[derive(Error, Debug)]
pub enum LibraryError {
    #[error("invalid input")]
    InvalidInput,
    // ...
}

// ✅ Application code - use anyhow
// (in my_app/src/main.rs)
use anyhow::{Context, Result};

fn main() -> Result<()> {
    run_app().context("application failed")?;
    Ok(())
}
```

### Adding Context with .context()

```rust
use anyhow::{Context, Result};

// ❌ WRONG - Error without context
fn load_config() -> Result<Config> {
    let content = std::fs::read_to_string("config.toml")?;
    let config: Config = toml::from_str(&content)?;
    Ok(config)
}
// Error message: "No such file or directory"

// ✅ CORRECT - Error with context
fn load_config() -> Result<Config> {
    let content = std::fs::read_to_string("config.toml")
        .context("failed to read config file")?;

    let config: Config = toml::from_str(&content)
        .context("failed to parse config")?;

    Ok(config)
}
// Error message: "failed to read config file"
// Caused by: "No such file or directory"
```

### Dynamic Context with with_context()

```rust
use anyhow::{Context, Result};

fn get_user(id: &str) -> Result<User> {
    let user = db.find_user(id)
        .with_context(|| format!("failed to fetch user {}", id))?;

    let profile = fetch_profile(&user)
        .with_context(|| format!("failed to fetch profile for user {}", id))?;

    Ok(User { profile, ..user })
}
```

### Creating Errors with anyhow!

```rust
use anyhow::{anyhow, bail, ensure, Result};

fn validate_age(age: i32) -> Result<()> {
    // bail! - return early with an error
    if age < 0 {
        bail!("age cannot be negative: {}", age);
    }

    // ensure! - assert-like macro that returns error
    ensure!(age < 150, "age {} is unrealistic", age);

    Ok(())
}

fn process(value: Option<i32>) -> Result<i32> {
    // anyhow! - create an error inline
    let value = value.ok_or_else(|| anyhow!("value is required"))?;
    Ok(value * 2)
}
```

---

## When to Use panic!

### Panic is for Bugs, Not Expected Errors

```rust
// ❌ WRONG - panic for expected error
fn get_user(id: &str) -> User {
    users.get(id).expect("user must exist")  // Don't do this!
}

// ✅ CORRECT - Return Result for expected errors
fn get_user(id: &str) -> Result<User, UserError> {
    users.get(id).cloned().ok_or(UserError::NotFound(id.to_string()))
}
```

### When panic! IS Acceptable

```rust
// ✅ OK - Invariant that indicates a bug
fn get_element(index: usize) -> &Element {
    // If index is out of bounds, it's a programming error
    &self.elements[index]  // Will panic if bug in calling code
}

// ✅ OK - Unreachable code after exhaustive handling
fn process(status: Status) -> Action {
    match status {
        Status::Active => Action::Continue,
        Status::Paused => Action::Wait,
        Status::Stopped => Action::Cleanup,
        // If new variant added without handling, this should panic
    }
}

// ✅ OK - Initialization that must succeed
fn init() {
    let regex = Regex::new(r"^\d{4}-\d{2}-\d{2}$")
        .expect("date regex is valid");  // Compile-time constant
}

// ✅ OK - In tests
#[test]
fn test_user() {
    let user = create_user().unwrap();
    assert_eq!(user.name, "Test");
}
```

---

## Error Matching Patterns

### Pattern Matching on Custom Errors

```rust
fn handle_user_error(result: Result<User, UserError>) {
    match result {
        Ok(user) => println!("Found user: {}", user.name),

        Err(UserError::NotFound(id)) => {
            println!("User {} not found, creating...", id);
            create_user(&id);
        }

        Err(UserError::InvalidEmail(email)) => {
            println!("Invalid email: {}", email);
        }

        Err(e) => {
            eprintln!("Unexpected error: {}", e);
        }
    }
}
```

### Checking Specific Error Types

```rust
// Check if error is a specific variant
if let Err(UserError::NotFound(_)) = get_user(id) {
    // Handle not found case
}

// Using matches! macro
if matches!(result, Err(UserError::NotFound(_))) {
    // Handle not found case
}

// Downcasting with anyhow
fn handle_anyhow_error(err: anyhow::Error) {
    if let Some(user_err) = err.downcast_ref::<UserError>() {
        match user_err {
            UserError::NotFound(id) => println!("Not found: {}", id),
            _ => println!("Other user error"),
        }
    }
}
```

### Handling Multiple Error Types

```rust
// Approach 1: Common error enum
#[derive(Error, Debug)]
enum ServiceError {
    #[error("user error")]
    User(#[from] UserError),
    #[error("order error")]
    Order(#[from] OrderError),
}

// Approach 2: anyhow for simplicity
use anyhow::Result;

fn process() -> Result<()> {
    get_user()?;  // UserError
    create_order()?;  // OrderError
    Ok(())
}

// Approach 3: Box<dyn Error> (less ergonomic)
fn process() -> Result<(), Box<dyn std::error::Error>> {
    get_user()?;
    create_order()?;
    Ok(())
}
```

---

## Error Handling at Boundaries

### HTTP Handler Boundaries

```rust
use axum::{response::IntoResponse, http::StatusCode};

impl IntoResponse for UserError {
    fn into_response(self) -> axum::response::Response {
        let (status, message) = match self {
            UserError::NotFound(id) => (
                StatusCode::NOT_FOUND,
                format!("User {} not found", id),
            ),
            UserError::InvalidEmail(_) => (
                StatusCode::BAD_REQUEST,
                "Invalid email format".to_string(),
            ),
            UserError::AlreadyExists => (
                StatusCode::CONFLICT,
                "User already exists".to_string(),
            ),
            _ => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Internal error".to_string(),
            ),
        };

        (status, message).into_response()
    }
}
```

### Logging vs Returning Errors

```rust
// ✅ CORRECT - Log at boundaries, propagate elsewhere
async fn handle_request(req: Request) -> Response {
    match process_request(req).await {
        Ok(data) => Response::ok(data),
        Err(e) => {
            // Log full error chain at boundary
            tracing::error!("Request failed: {:?}", e);
            // Return sanitized error to client
            Response::error(e.into())
        }
    }
}

// ❌ WRONG - Logging in inner functions
fn get_user(id: &str) -> Result<User, UserError> {
    let user = db.find(id).map_err(|e| {
        log::error!("Database error: {}", e);  // Don't log here!
        UserError::Database(e)
    })?;
    Ok(user)
}

// ✅ CORRECT - Just propagate in inner functions
fn get_user(id: &str) -> Result<User, UserError> {
    let user = db.find(id)?;
    Ok(user)
}
```

---

## Testing Error Conditions

### Testing for Specific Errors

```rust
#[test]
fn returns_not_found_for_missing_user() {
    let repo = MockUserRepository::empty();
    let result = repo.get("nonexistent");

    assert!(matches!(result, Err(UserError::NotFound(_))));
}

#[test]
fn returns_validation_error_for_invalid_email() {
    let result = User::new("invalid-email");

    let err = result.unwrap_err();
    assert!(matches!(err, UserError::InvalidEmail(_)));
}
```

### Testing Error Messages

```rust
#[test]
fn error_message_includes_user_id() {
    let result = get_user("user-123");

    let err = result.unwrap_err();
    assert!(err.to_string().contains("user-123"));
}
```

### Testing with anyhow

```rust
#[test]
fn error_has_correct_context() {
    let result = load_config_from("nonexistent.toml");

    let err = result.unwrap_err();
    assert!(err.to_string().contains("failed to read"));

    // Check the error chain
    let mut chain = err.chain();
    assert!(chain.next().unwrap().to_string().contains("failed to read"));
    assert!(chain.next().unwrap().to_string().contains("No such file"));
}
```

---

## Anti-Patterns

### Ignoring Errors

```rust
// ❌ WRONG - Ignoring Result
let _ = save_user(&user);  // Error silently ignored!

// ✅ CORRECT - Handle or propagate
save_user(&user)?;

// ✅ CORRECT - Explicit ignore with comment
let _ = cleanup();  // Best effort cleanup, ok to fail
```

### Converting to String Too Early

```rust
// ❌ WRONG - Losing type information
fn get_user(id: &str) -> Result<User, String> {
    db.find(id).map_err(|e| e.to_string())
}

// ✅ CORRECT - Keep typed errors
fn get_user(id: &str) -> Result<User, UserError> {
    db.find(id).map_err(UserError::Database)
}
```

### Overusing unwrap_or_default

```rust
// ❌ WRONG - Hiding errors with default
let user = get_user(id).unwrap_or_default();
// If get_user fails, we silently use default - bug!

// ✅ CORRECT - Handle the error explicitly
let user = get_user(id)?;
// or
let user = get_user(id).unwrap_or_else(|_| User::guest());
```

---

## Summary Checklist

When handling errors in Rust, verify:

- [ ] Using Result<T, E> for all fallible operations
- [ ] Using ? operator for error propagation
- [ ] No unwrap()/expect() in production code paths
- [ ] Custom errors defined with thiserror (for libraries)
- [ ] Application errors using anyhow with .context()
- [ ] Errors have meaningful messages with context
- [ ] Error matching done at appropriate boundaries
- [ ] panic! reserved for bugs and invariant violations
- [ ] Errors logged at boundaries, not in inner functions
- [ ] Tests verify specific error types and messages
