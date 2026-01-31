---
name: php-strict
description: PHP best practices and patterns. Use when writing any PHP code.
---

# PHP Strict Mode

## Core Rules

1. **Strict types declaration** - `declare(strict_types=1)` at file top
2. **Type declarations everywhere** - parameters, returns, properties
3. **Constructor property promotion** - clean dependency injection
4. **Small interfaces** - composition over inheritance

---

## Strict Types Declaration

### Always Enable Strict Types

```php
<?php
// WRONG - No strict types
function add($a, $b) {
    return $a + $b;
}
add("5", "3"); // Returns 8 (type coercion)

// CORRECT - Strict types enabled
<?php
declare(strict_types=1);

function add(int $a, int $b): int {
    return $a + $b;
}
add("5", "3"); // TypeError thrown
```

### Place at Very Top of File

```php
<?php
declare(strict_types=1);

namespace App\Services;

// Must be first statement (after opening tag)
// Before namespace, use statements, or any code
```

---

## Type Declarations

### Type All Parameters and Returns

```php
<?php
declare(strict_types=1);

// WRONG - Missing type declarations
class UserService {
    public function find($id) {
        return $this->repository->find($id);
    }
}

// CORRECT - Full type declarations
class UserService {
    public function find(string $id): ?User {
        return $this->repository->find($id);
    }
}
```

### Property Types (PHP 7.4+)

```php
<?php
declare(strict_types=1);

// WRONG - Using docblocks instead of types
class Order {
    /** @var string */
    private $id;
    /** @var float */
    private $total;
}

// CORRECT - Native property types
class Order {
    private string $id;
    private float $total;
    private ?Customer $customer = null;
}
```

### Readonly Properties (PHP 8.1+)

```php
<?php
declare(strict_types=1);

// WRONG - Mutable properties for immutable data
class UserId {
    private string $value;

    public function __construct(string $value) {
        $this->value = $value;
    }
}

// CORRECT - Readonly properties
class UserId {
    public function __construct(
        public readonly string $value
    ) {}
}

// CORRECT - Readonly class (PHP 8.2+)
readonly class UserId {
    public function __construct(
        public string $value
    ) {}
}
```

---

## Constructor Property Promotion

### Use for Dependencies

```php
<?php
declare(strict_types=1);

// WRONG - Verbose constructor
class OrderService {
    private OrderRepository $orderRepository;
    private PaymentGateway $paymentGateway;
    private LoggerInterface $logger;

    public function __construct(
        OrderRepository $orderRepository,
        PaymentGateway $paymentGateway,
        LoggerInterface $logger
    ) {
        $this->orderRepository = $orderRepository;
        $this->paymentGateway = $paymentGateway;
        $this->logger = $logger;
    }
}

// CORRECT - Constructor property promotion
class OrderService {
    public function __construct(
        private readonly OrderRepository $orderRepository,
        private readonly PaymentGateway $paymentGateway,
        private readonly LoggerInterface $logger
    ) {}
}
```

---

## Dependency Injection

### Constructor Injection Only

```php
<?php
declare(strict_types=1);

// WRONG - Property injection via setter
class UserService {
    private ?UserRepository $repository = null;

    public function setRepository(UserRepository $repo): void {
        $this->repository = $repo;
    }
}

// WRONG - Service locator / container access
class UserService {
    public function find(string $id): ?User {
        $repo = Container::get(UserRepository::class);
        return $repo->find($id);
    }
}

// CORRECT - Constructor injection
class UserService {
    public function __construct(
        private readonly UserRepository $repository
    ) {}

    public function find(string $id): ?User {
        return $this->repository->find($id);
    }
}
```

### No `new` Inside Services

```php
<?php
declare(strict_types=1);

// WRONG - Creating dependencies internally
class OrderService {
    public function process(Order $order): void {
        $validator = new OrderValidator();
        $gateway = new StripeGateway(config('stripe.key'));
        // ...
    }
}

// CORRECT - Inject dependencies
class OrderService {
    public function __construct(
        private readonly OrderValidator $validator,
        private readonly PaymentGateway $gateway
    ) {}

    public function process(Order $order): void {
        $this->validator->validate($order);
        $this->gateway->charge($order->total());
    }
}
```

---

## Interface Design

### Small Interfaces (1-3 Methods)

```php
<?php
declare(strict_types=1);

// WRONG - Large interface
interface UserRepository {
    public function find(string $id): ?User;
    public function findByEmail(string $email): ?User;
    public function findAll(): array;
    public function save(User $user): void;
    public function delete(string $id): void;
    public function exists(string $id): bool;
    public function count(): int;
}

// CORRECT - Small, focused interfaces
interface UserReader {
    public function find(string $id): ?User;
    public function findByEmail(string $email): ?User;
}

interface UserWriter {
    public function save(User $user): void;
    public function delete(string $id): void;
}
```

### Define Interfaces at Consumer

```php
<?php
declare(strict_types=1);

// WRONG - Interface defined with implementation
// In Infrastructure/UserRepository.php
interface UserRepositoryInterface {
    public function find(string $id): ?User;
}

class DoctrineUserRepository implements UserRepositoryInterface {}

// CORRECT - Interface defined at consumer (Domain)
// In Domain/Ports/UserReader.php
interface UserReader {
    public function find(string $id): ?User;
}

// In Infrastructure/DoctrineUserRepository.php
class DoctrineUserRepository implements UserReader {}
```

---

## Enums (PHP 8.1+)

### Use Enums Instead of Constants

```php
<?php
declare(strict_types=1);

// WRONG - Constants for fixed values
class OrderStatus {
    public const PENDING = 'pending';
    public const PROCESSING = 'processing';
    public const SHIPPED = 'shipped';
    public const DELIVERED = 'delivered';
}

// CORRECT - Backed enum
enum OrderStatus: string {
    case Pending = 'pending';
    case Processing = 'processing';
    case Shipped = 'shipped';
    case Delivered = 'delivered';

    public function label(): string {
        return match($this) {
            self::Pending => 'Awaiting Processing',
            self::Processing => 'Being Processed',
            self::Shipped => 'In Transit',
            self::Delivered => 'Delivered',
        };
    }
}

// Usage
function updateStatus(Order $order, OrderStatus $status): void {
    $order->setStatus($status);
}

updateStatus($order, OrderStatus::Shipped);
```

---

## Null Safety

### Nullable Types and Null Coalescing

```php
<?php
declare(strict_types=1);

// WRONG - Implicit null handling
function getUsername($user) {
    return $user->name; // Potential null error
}

// CORRECT - Explicit nullable handling
function getUsername(?User $user): string {
    return $user?->name ?? 'Anonymous';
}

// CORRECT - Early return for null
function processUser(?User $user): void {
    if ($user === null) {
        return;
    }

    // $user is guaranteed non-null here
    $this->sendEmail($user->email);
}
```

### Nullsafe Operator (PHP 8.0+)

```php
<?php
declare(strict_types=1);

// WRONG - Nested null checks
$country = null;
if ($user !== null && $user->address !== null) {
    $country = $user->address->country;
}

// CORRECT - Nullsafe operator
$country = $user?->address?->country;

// CORRECT - Combined with null coalescing
$country = $user?->address?->country ?? 'Unknown';
```

---

## Named Arguments (PHP 8.0+)

### Use for Optional Parameters

```php
<?php
declare(strict_types=1);

// WRONG - Positional arguments with many parameters
$mailer->send(
    'user@example.com',
    'Welcome!',
    'Hello...',
    null,
    null,
    true,
    ['marketing']
);

// CORRECT - Named arguments for clarity
$mailer->send(
    to: 'user@example.com',
    subject: 'Welcome!',
    body: 'Hello...',
    highPriority: true,
    tags: ['marketing']
);
```

---

## PSR-12 Coding Standards

### Follow PSR-12 Conventions

```php
<?php
declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Psr\Log\LoggerInterface;

// Class opening brace on same line
class UserService
{
    // Method opening brace on new line
    public function __construct(
        private readonly UserRepository $repository,
        private readonly LoggerInterface $logger
    ) {
    }

    // Visibility always declared
    public function find(string $id): ?User
    {
        $this->logger->info('Finding user', ['id' => $id]);

        return $this->repository->find($id);
    }
}
```

---

## Laravel-Specific Patterns

### Service Providers and Binding

```php
<?php
declare(strict_types=1);

namespace App\Providers;

use App\Services\PaymentGateway;
use App\Services\StripePaymentGateway;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // CORRECT - Bind interface to implementation
        $this->app->bind(PaymentGateway::class, StripePaymentGateway::class);

        // CORRECT - Singleton for shared instances
        $this->app->singleton(CacheManager::class, function ($app) {
            return new CacheManager($app['config']['cache']);
        });
    }
}
```

### Facades vs Dependency Injection

```php
<?php
declare(strict_types=1);

// WRONG - Facade in domain/service code
class OrderService
{
    public function create(array $data): Order
    {
        Cache::put('order', $data); // Facade - hidden dependency
        Log::info('Order created');  // Facade - hidden dependency
        return Order::create($data); // Facade - hidden dependency
    }
}

// CORRECT - Inject dependencies
class OrderService
{
    public function __construct(
        private readonly OrderRepository $orders,
        private readonly CacheInterface $cache,
        private readonly LoggerInterface $logger
    ) {}

    public function create(CreateOrderDto $dto): Order
    {
        $order = new Order($dto->items, $dto->customerId);
        $this->orders->save($order);
        $this->cache->put("order:{$order->id}", $order);
        $this->logger->info('Order created', ['id' => $order->id]);

        return $order;
    }
}
```

### Eloquent Model Best Practices

```php
<?php
declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Builder;

class Order extends Model
{
    // CORRECT - Use casts for type safety
    protected $casts = [
        'total' => 'decimal:2',
        'status' => OrderStatus::class, // Enum cast
        'metadata' => 'array',
        'shipped_at' => 'datetime',
    ];

    // CORRECT - Define relationships with return types
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    // CORRECT - Use query scopes
    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', OrderStatus::Pending);
    }

    public function scopeForCustomer(Builder $query, string $customerId): Builder
    {
        return $query->where('customer_id', $customerId);
    }
}

// Usage
$orders = Order::pending()->forCustomer($customerId)->get();
```

### Form Requests for Validation

```php
<?php
declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

// CORRECT - Validation in Form Request, not controller
class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'string', 'exists:customers,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'exists:products,id'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ];
    }
}

// Controller receives validated request
class OrderController
{
    public function store(CreateOrderRequest $request): JsonResponse
    {
        // $request->validated() is already validated
        $order = $this->orderService->create($request->validated());

        return response()->json($order, 201);
    }
}
```

### Resource Classes for API Responses

```php
<?php
declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

// CORRECT - Use Resources for API response shaping
class OrderResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status->value,
            'total' => $this->total,
            'items' => OrderItemResource::collection($this->whenLoaded('items')),
            'customer' => new CustomerResource($this->whenLoaded('customer')),
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}

// Usage in controller
return new OrderResource($order->load(['items', 'customer']));
```

---

## Summary Checklist

When writing PHP code, verify:

- [ ] `declare(strict_types=1)` at file top
- [ ] Type declarations on all parameters
- [ ] Return type on all methods
- [ ] Property types declared (PHP 7.4+)
- [ ] Constructor property promotion used
- [ ] Readonly properties for immutable data
- [ ] Constructor injection for dependencies
- [ ] No `new` for services inside other services
- [ ] Small interfaces (1-3 methods)
- [ ] Enums instead of string constants
- [ ] Nullsafe operator and null coalescing used appropriately
- [ ] Named arguments for optional parameters
- [ ] PSR-12 coding standards followed
- [ ] Laravel: No Facades in domain/service code
- [ ] Laravel: Form Requests for validation
- [ ] Laravel: Resources for API responses
