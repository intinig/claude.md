---
name: php-error-handling
description: PHP error handling patterns. Use when working with errors in PHP code.
---

# PHP Error Handling Patterns

## Core Principle

**Explicit error handling with meaningful context.** Use exceptions for exceptional circumstances, Result types for expected failures, and guard clauses for input validation. Never swallow exceptions silently.

---

## Exception Handling

### Never Swallow Exceptions

```php
<?php
declare(strict_types=1);

// WRONG - Empty catch block
try {
    $this->processOrder($order);
} catch (Exception $e) {
    // Silent failure - debugging nightmare
}

// WRONG - Catch and ignore
try {
    $this->processOrder($order);
} catch (Exception $e) {
    $this->logger->error('Error occurred', ['exception' => $e]);
    // Logged but not handled - caller unaware
}

// CORRECT - Handle or rethrow with context
try {
    $this->processOrder($order);
} catch (PaymentException $e) {
    $this->logger->warning('Payment failed', [
        'order_id' => $order->id,
        'exception' => $e,
    ]);
    throw new OrderProcessingException(
        "Failed to process order {$order->id}",
        previous: $e
    );
}
```

### Catch Specific Exceptions

```php
<?php
declare(strict_types=1);

// WRONG - Catching base Exception
try {
    $user = $this->repository->findOrFail($id);
} catch (Exception $e) {
    return null; // Hides all errors including bugs
}

// CORRECT - Catch specific exceptions
try {
    $user = $this->repository->findOrFail($id);
} catch (UserNotFoundException $e) {
    return null; // Expected: user not found
} catch (DatabaseException $e) {
    $this->logger->error('Database error', [
        'user_id' => $id,
        'exception' => $e,
    ]);
    throw $e; // Unexpected: let it propagate
}
```

### Preserve Exception Chain

```php
<?php
declare(strict_types=1);

// WRONG - Loses original exception
try {
    $this->processPayment($payment);
} catch (StripeException $e) {
    throw new PaymentException("Payment failed"); // Original context lost
}

// CORRECT - Preserve exception chain
try {
    $this->processPayment($payment);
} catch (StripeException $e) {
    throw new PaymentException(
        message: "Payment failed for amount {$payment->amount}",
        code: $e->getCode(),
        previous: $e
    );
}
```

---

## Custom Exceptions

### Define Domain-Specific Exceptions

```php
<?php
declare(strict_types=1);

// CORRECT - Domain exception with context
final class OrderNotFoundException extends DomainException
{
    public function __construct(
        public readonly string $orderId,
        ?Throwable $previous = null
    ) {
        parent::__construct(
            message: "Order '{$orderId}' was not found",
            previous: $previous
        );
    }
}

// CORRECT - Validation exception with details
final class ValidationException extends DomainException
{
    /** @param array<string, string[]> $errors */
    public function __construct(
        public readonly array $errors,
        ?Throwable $previous = null
    ) {
        parent::__construct(
            message: 'Validation failed',
            previous: $previous
        );
    }

    public function hasError(string $field): bool
    {
        return isset($this->errors[$field]);
    }
}
```

### Exception Hierarchy

```php
<?php
declare(strict_types=1);

// Base domain exception
abstract class DomainException extends Exception
{
    public function __construct(
        string $message,
        public readonly string $code = 'DOMAIN_ERROR',
        ?Throwable $previous = null
    ) {
        parent::__construct($message, 0, $previous);
    }
}

// Specific exceptions
final class EntityNotFoundException extends DomainException
{
    public function __construct(
        public readonly string $entityType,
        public readonly string $entityId,
        ?Throwable $previous = null
    ) {
        parent::__construct(
            message: "{$entityType} '{$entityId}' was not found",
            code: 'NOT_FOUND',
            previous: $previous
        );
    }
}

final class BusinessRuleViolationException extends DomainException
{
    public function __construct(
        string $rule,
        ?Throwable $previous = null
    ) {
        parent::__construct(
            message: $rule,
            code: 'BUSINESS_RULE_VIOLATION',
            previous: $previous
        );
    }
}

final class InsufficientPermissionsException extends DomainException
{
    public function __construct(
        public readonly string $action,
        public readonly string $resource,
        ?Throwable $previous = null
    ) {
        parent::__construct(
            message: "Cannot {$action} {$resource}: insufficient permissions",
            code: 'FORBIDDEN',
            previous: $previous
        );
    }
}
```

---

## Result Pattern

### When to Use Result vs Exception

```php
<?php
declare(strict_types=1);

// Use EXCEPTIONS for:
// - Truly exceptional conditions (network failures, database errors)
// - Programming errors (type errors, invalid state)
// - Unrecoverable errors

// Use RESULT for:
// - Expected failure cases (validation, not found)
// - When caller needs to handle success/failure differently
// - Functional composition of operations
```

### Simple Result Type

```php
<?php
declare(strict_types=1);

/**
 * @template T
 */
final readonly class Result
{
    private function __construct(
        private mixed $value,
        private ?string $error
    ) {}

    /** @return self<T> */
    public static function success(mixed $value): self
    {
        return new self($value, null);
    }

    /** @return self<T> */
    public static function failure(string $error): self
    {
        return new self(null, $error);
    }

    public function isSuccess(): bool
    {
        return $this->error === null;
    }

    public function isFailure(): bool
    {
        return $this->error !== null;
    }

    /** @return T */
    public function value(): mixed
    {
        if ($this->isFailure()) {
            throw new LogicException('Cannot get value from failed result');
        }
        return $this->value;
    }

    public function error(): ?string
    {
        return $this->error;
    }

    /**
     * @template U
     * @param callable(T): U $onSuccess
     * @param callable(string): U $onFailure
     * @return U
     */
    public function match(callable $onSuccess, callable $onFailure): mixed
    {
        return $this->isSuccess()
            ? $onSuccess($this->value)
            : $onFailure($this->error);
    }
}

// Usage
final class UserService
{
    /** @return Result<User> */
    public function find(string $id): Result
    {
        $user = $this->repository->find($id);

        return $user !== null
            ? Result::success($user)
            : Result::failure("User '{$id}' not found");
    }
}

// Consuming
$result = $userService->find('user-123');
return $result->match(
    onSuccess: fn(User $user) => response()->json($user),
    onFailure: fn(string $error) => response()->json(['error' => $error], 404)
);
```

### Result with Typed Errors

```php
<?php
declare(strict_types=1);

abstract readonly class Error
{
    public function __construct(
        public string $code,
        public string $message
    ) {}
}

final readonly class NotFoundError extends Error
{
    public function __construct(string $entityType, string $id)
    {
        parent::__construct('NOT_FOUND', "{$entityType} '{$id}' not found");
    }
}

final readonly class ValidationError extends Error
{
    /** @param array<string, string[]> $fields */
    public function __construct(
        public array $fields
    ) {
        parent::__construct('VALIDATION', 'Validation failed');
    }
}

/**
 * @template T
 * @template E of Error
 */
final readonly class TypedResult
{
    private function __construct(
        private mixed $value,
        private ?Error $error
    ) {}

    /** @return self<T, E> */
    public static function success(mixed $value): self
    {
        return new self($value, null);
    }

    /** @return self<T, E> */
    public static function failure(Error $error): self
    {
        return new self(null, $error);
    }

    // ... rest of implementation
}
```

### Combining Results

```php
<?php
declare(strict_types=1);

/**
 * @template T
 * @template U
 * @param Result<T> $result
 * @param callable(T): U $mapper
 * @return Result<U>
 */
function map(Result $result, callable $mapper): Result
{
    return $result->isSuccess()
        ? Result::success($mapper($result->value()))
        : Result::failure($result->error());
}

/**
 * @template T
 * @template U
 * @param Result<T> $result
 * @param callable(T): Result<U> $binder
 * @return Result<U>
 */
function bind(Result $result, callable $binder): Result
{
    return $result->isSuccess()
        ? $binder($result->value())
        : Result::failure($result->error());
}

// Usage - composing operations
final class OrderService
{
    /** @return Result<OrderConfirmation> */
    public function process(OrderRequest $request): Result
    {
        return bind(
            $this->validateOrder($request),
            fn($validated) => bind(
                $this->createOrder($validated),
                fn($order) => bind(
                    $this->processPayment($order),
                    fn($payment) => Result::success(
                        new OrderConfirmation($order, $payment)
                    )
                )
            )
        );
    }
}
```

---

## Guard Clauses

### Validate Early, Fail Fast

```php
<?php
declare(strict_types=1);

// WRONG - Late validation, nested checks
function processOrder(?Order $order): void
{
    if ($order !== null) {
        if ($order->items !== null) {
            if (count($order->items) > 0) {
                // Finally do something
            }
        }
    }
}

// CORRECT - Guard clauses at the start
function processOrder(?Order $order): void
{
    if ($order === null) {
        throw new InvalidArgumentException('Order cannot be null');
    }

    if (empty($order->items)) {
        throw new InvalidArgumentException('Order must have items');
    }

    // Now do the work with valid data
}
```

### Assert Class for Guards

```php
<?php
declare(strict_types=1);

final class Assert
{
    public static function notNull(mixed $value, string $name): void
    {
        if ($value === null) {
            throw new InvalidArgumentException("{$name} cannot be null");
        }
    }

    public static function notEmpty(string $value, string $name): void
    {
        if (trim($value) === '') {
            throw new InvalidArgumentException("{$name} cannot be empty");
        }
    }

    public static function positive(int|float $value, string $name): void
    {
        if ($value <= 0) {
            throw new InvalidArgumentException("{$name} must be positive");
        }
    }

    public static function inRange(
        int|float $value,
        int|float $min,
        int|float $max,
        string $name
    ): void {
        if ($value < $min || $value > $max) {
            throw new InvalidArgumentException(
                "{$name} must be between {$min} and {$max}"
            );
        }
    }

    public static function validEmail(string $email, string $name = 'email'): void
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException("{$name} is not a valid email");
        }
    }
}

// Usage
final class User
{
    public function __construct(
        public readonly string $id,
        public readonly string $name,
        public readonly string $email,
        public readonly int $age
    ) {
        Assert::notEmpty($id, 'id');
        Assert::notEmpty($name, 'name');
        Assert::validEmail($email);
        Assert::inRange($age, 0, 150, 'age');
    }
}
```

---

## Error Logging

### Structured Logging

```php
<?php
declare(strict_types=1);

// WRONG - String interpolation in log
catch (Exception $e) {
    $this->logger->error("Failed to process order {$orderId}: {$e->getMessage()}");
}

// CORRECT - Structured logging with context
catch (Exception $e) {
    $this->logger->error('Failed to process order', [
        'order_id' => $orderId,
        'customer_id' => $customerId,
        'exception' => $e,
    ]);
}
```

### Log Levels for Errors

```php
<?php
declare(strict_types=1);

// Appropriate log levels
catch (EntityNotFoundException $e) {
    $this->logger->warning('User not found', ['user_id' => $userId]);
    return null;
}
catch (ValidationException $e) {
    $this->logger->info('Validation failed', ['errors' => $e->errors]);
    throw $e;
}
catch (DatabaseException $e) {
    $this->logger->error('Database error', ['exception' => $e]);
    throw $e;
}
catch (Exception $e) {
    $this->logger->critical('Unexpected error', ['exception' => $e]);
    throw $e;
}
```

---

## Laravel-Specific Patterns

### Exception Handler Customization

```php
<?php
declare(strict_types=1);

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

final class Handler extends ExceptionHandler
{
    /** @var array<class-string<Throwable>> */
    protected $dontReport = [
        ValidationException::class,
        AuthenticationException::class,
    ];

    public function render($request, Throwable $e): JsonResponse
    {
        if ($request->expectsJson()) {
            return $this->renderJsonException($request, $e);
        }

        return parent::render($request, $e);
    }

    private function renderJsonException(Request $request, Throwable $e): JsonResponse
    {
        return match (true) {
            $e instanceof ValidationException => response()->json([
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422),

            $e instanceof EntityNotFoundException => response()->json([
                'message' => $e->getMessage(),
                'code' => $e->code,
            ], 404),

            $e instanceof BusinessRuleViolationException => response()->json([
                'message' => $e->getMessage(),
                'code' => $e->code,
            ], 422),

            default => response()->json([
                'message' => 'Internal server error',
            ], 500),
        };
    }
}
```

### Reportable and Renderable Exceptions

```php
<?php
declare(strict_types=1);

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class OrderProcessingException extends Exception
{
    public function __construct(
        public readonly string $orderId,
        string $message,
        ?Throwable $previous = null
    ) {
        parent::__construct($message, 0, $previous);
    }

    // Customize reporting (logging)
    public function report(): void
    {
        // Custom logging logic
        logger()->error('Order processing failed', [
            'order_id' => $this->orderId,
            'message' => $this->getMessage(),
        ]);
    }

    // Customize rendering (response)
    public function render(Request $request): JsonResponse
    {
        return response()->json([
            'message' => 'Order processing failed',
            'order_id' => $this->orderId,
        ], 422);
    }

    // Control whether to report
    public function shouldReport(): bool
    {
        return true;
    }
}
```

### abort() and abort_if() Patterns

```php
<?php
declare(strict_types=1);

namespace App\Http\Controllers;

final class OrderController extends Controller
{
    public function show(string $id): JsonResponse
    {
        $order = Order::find($id);

        // CORRECT - Abort with model not found
        abort_if($order === null, 404, 'Order not found');

        // CORRECT - Abort with authorization
        abort_unless($order->customer_id === auth()->id(), 403);

        return response()->json($order);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $order = Order::findOrFail($id); // Auto 404

        abort_if(
            $order->status === OrderStatus::Shipped,
            422,
            'Cannot modify shipped orders'
        );

        // ...
    }
}

// In service layer - prefer exceptions over abort()
final class OrderService
{
    public function find(string $id): Order
    {
        $order = $this->repository->find($id);

        // CORRECT - Throw exception, let controller/handler deal with response
        if ($order === null) {
            throw new OrderNotFoundException($id);
        }

        return $order;
    }
}
```

### Validation Exception Handling

```php
<?php
declare(strict_types=1);

namespace App\Http\Controllers;

use Illuminate\Validation\ValidationException;

final class UserController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        // Option 1: Let Laravel handle validation
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
        ]);

        // Option 2: Manual validation with custom handling
        $validator = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
        ]);

        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        // Option 3: Using Form Request (preferred)
        // See CreateUserRequest class
    }
}

// Form Request with custom error messages
final class CreateUserRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'name.required' => 'Please provide your name',
            'email.unique' => 'This email is already registered',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new ValidationException($validator);
    }
}
```

---

## Never Use die() or exit()

```php
<?php
declare(strict_types=1);

// WRONG - die/exit in application code
function processPayment(Payment $payment): void
{
    if (!$payment->isValid()) {
        die('Invalid payment'); // Kills entire application
    }

    if ($this->gateway->charge($payment) === false) {
        exit(1); // No chance to handle gracefully
    }
}

// CORRECT - Throw exceptions
function processPayment(Payment $payment): void
{
    if (!$payment->isValid()) {
        throw new InvalidPaymentException($payment->id);
    }

    if (!$this->gateway->charge($payment)) {
        throw new PaymentFailedException($payment->id);
    }
}
```

---

## Summary Checklist

When handling errors in PHP, verify:

- [ ] No empty catch blocks
- [ ] Specific exceptions caught, not base `Exception`
- [ ] Exception chain preserved with `previous` parameter
- [ ] Custom exceptions include context (IDs, values)
- [ ] Guard clauses at method start for validation
- [ ] Result type used for expected failures
- [ ] Exceptions used for truly exceptional cases
- [ ] Structured logging with context arrays
- [ ] No `die()` or `exit()` in application code
- [ ] Laravel: Custom Exception Handler for JSON APIs
- [ ] Laravel: Form Requests for validation
- [ ] Laravel: abort() only in controllers, exceptions in services
