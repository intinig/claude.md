---
name: php-testing
description: PHP testing patterns with PHPUnit. Use when writing PHP tests or test factories.
---

# PHP Testing Patterns

## Core Principle

**Test behavior, not implementation.** Tests should verify what the code does, not how it does it. Use PHPUnit with data providers for table-driven tests and proper mocking for isolation.

---

## Test Framework Setup

### PHPUnit Configuration

```xml
<!-- phpunit.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         stopOnFailure="false">
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
</phpunit>
```

---

## Test Organization

### Arrange-Act-Assert Pattern

```php
<?php
declare(strict_types=1);

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;

final class OrderServiceTest extends TestCase
{
    public function testCreateOrderWithValidDataReturnsOrder(): void
    {
        // Arrange - Set up test data and dependencies
        $repository = new InMemoryOrderRepository();
        $service = new OrderService($repository);
        $customerId = 'cust-123';
        $items = [new OrderItem('product-1', 2)];

        // Act - Execute the behavior under test
        $order = $service->create($customerId, $items);

        // Assert - Verify the outcome
        $this->assertNotNull($order->id);
        $this->assertSame($customerId, $order->customerId);
        $this->assertCount(1, $order->items);
    }
}
```

### Test Naming Convention

```php
<?php
declare(strict_types=1);

// Pattern: test[MethodName][Scenario][ExpectedBehavior]
// Or with annotation: @test methodName_scenario_expectedBehavior

final class CalculatorTest extends TestCase
{
    public function testAddTwoPositiveNumbersReturnsSum(): void {}

    public function testDivideByZeroThrowsDivisionByZeroError(): void {}

    public function testGetUserNonExistentIdReturnsNull(): void {}

    /** @test */
    public function email_with_invalid_format_fails_validation(): void {}
}
```

---

## Data Providers

### Basic Data Provider

```php
<?php
declare(strict_types=1);

final class EmailValidatorTest extends TestCase
{
    /**
     * @dataProvider invalidEmailsProvider
     */
    public function testValidateRejectsInvalidEmails(string $email): void
    {
        $validator = new EmailValidator();

        $result = $validator->isValid($email);

        $this->assertFalse($result);
    }

    /** @return array<string, array{string}> */
    public static function invalidEmailsProvider(): array
    {
        return [
            'empty string' => [''],
            'missing @' => ['invalidemail.com'],
            'missing domain' => ['user@'],
            'missing local part' => ['@domain.com'],
            'spaces' => ['user @domain.com'],
        ];
    }

    /**
     * @dataProvider validEmailsProvider
     */
    public function testValidateAcceptsValidEmails(string $email): void
    {
        $validator = new EmailValidator();

        $result = $validator->isValid($email);

        $this->assertTrue($result);
    }

    /** @return array<string, array{string}> */
    public static function validEmailsProvider(): array
    {
        return [
            'simple' => ['user@domain.com'],
            'with subdomain' => ['user@sub.domain.com'],
            'with plus' => ['user+tag@domain.com'],
            'with dots' => ['user.name@domain.com'],
        ];
    }
}
```

### Data Provider with Expected Results

```php
<?php
declare(strict_types=1);

final class DiscountCalculatorTest extends TestCase
{
    /**
     * @dataProvider discountCasesProvider
     */
    public function testCalculateDiscount(
        float $orderTotal,
        bool $isPremium,
        float $expectedDiscount
    ): void {
        $calculator = new DiscountCalculator();

        $discount = $calculator->calculate($orderTotal, $isPremium);

        $this->assertSame($expectedDiscount, $discount);
    }

    /** @return array<string, array{float, bool, float}> */
    public static function discountCasesProvider(): array
    {
        return [
            'under threshold, regular' => [50.0, false, 0.0],
            'over threshold, regular' => [150.0, false, 15.0],
            'under threshold, premium' => [50.0, true, 5.0],
            'over threshold, premium' => [150.0, true, 30.0],
        ];
    }
}
```

---

## Test Factories

### Factory Methods Over Fixtures

```php
<?php
declare(strict_types=1);

// WRONG - Using shared state
final class OrderServiceTest extends TestCase
{
    private Order $order;
    private OrderRepository $repository;

    protected function setUp(): void
    {
        $this->order = new Order('order-1', 'customer-1', []);
        $this->repository = new InMemoryOrderRepository();
    }

    public function testProcess(): void
    {
        // Uses shared $this->order - potential coupling
    }
}

// CORRECT - Factory methods
final class OrderServiceTest extends TestCase
{
    public function testProcessValidOrderSucceeds(): void
    {
        $order = self::createOrder();
        $repository = self::createRepository($order);
        $service = new OrderService($repository);

        $result = $service->process($order->id);

        $this->assertTrue($result->isSuccess());
    }

    private static function createOrder(
        ?string $id = null,
        ?string $customerId = null,
        array $items = []
    ): Order {
        return new Order(
            id: $id ?? 'order-' . uniqid(),
            customerId: $customerId ?? 'customer-' . uniqid(),
            items: $items ?: [self::createOrderItem()]
        );
    }

    private static function createOrderItem(
        ?string $productId = null,
        int $quantity = 1
    ): OrderItem {
        return new OrderItem(
            productId: $productId ?? 'product-' . uniqid(),
            quantity: $quantity
        );
    }

    private static function createRepository(Order ...$orders): InMemoryOrderRepository
    {
        $repository = new InMemoryOrderRepository();
        foreach ($orders as $order) {
            $repository->save($order);
        }
        return $repository;
    }
}
```

### Builder Pattern for Complex Objects

```php
<?php
declare(strict_types=1);

final class OrderBuilder
{
    private string $id;
    private string $customerId;
    private array $items = [];
    private OrderStatus $status = OrderStatus::Pending;
    private ?DateTimeImmutable $createdAt = null;

    public function __construct()
    {
        $this->id = 'order-' . uniqid();
        $this->customerId = 'customer-' . uniqid();
    }

    public function withId(string $id): self
    {
        $clone = clone $this;
        $clone->id = $id;
        return $clone;
    }

    public function withCustomerId(string $customerId): self
    {
        $clone = clone $this;
        $clone->customerId = $customerId;
        return $clone;
    }

    public function withItems(array $items): self
    {
        $clone = clone $this;
        $clone->items = $items;
        return $clone;
    }

    public function withStatus(OrderStatus $status): self
    {
        $clone = clone $this;
        $clone->status = $status;
        return $clone;
    }

    public function shipped(): self
    {
        return $this->withStatus(OrderStatus::Shipped);
    }

    public function build(): Order
    {
        return new Order(
            $this->id,
            $this->customerId,
            $this->items ?: [new OrderItem('product-1', 1)],
            $this->status,
            $this->createdAt ?? new DateTimeImmutable()
        );
    }
}

// Usage
$order = (new OrderBuilder())
    ->withCustomerId('premium-customer')
    ->shipped()
    ->build();
```

---

## Mocking

### PHPUnit Mocks

```php
<?php
declare(strict_types=1);

final class OrderServiceTest extends TestCase
{
    public function testCreateOrderSavesToRepository(): void
    {
        // Arrange
        $repository = $this->createMock(OrderRepository::class);
        $repository->expects($this->once())
            ->method('save')
            ->with($this->callback(function (Order $order): bool {
                return $order->customerId === 'customer-123'
                    && count($order->items) === 1;
            }));

        $service = new OrderService($repository);

        // Act
        $service->create('customer-123', [new OrderItem('product-1', 2)]);

        // Assert - expectation verified automatically
    }

    public function testGetOrderReturnsFromRepository(): void
    {
        // Arrange
        $expectedOrder = self::createOrder();
        $repository = $this->createMock(OrderRepository::class);
        $repository->method('find')
            ->with($expectedOrder->id)
            ->willReturn($expectedOrder);

        $service = new OrderService($repository);

        // Act
        $result = $service->get($expectedOrder->id);

        // Assert
        $this->assertSame($expectedOrder, $result);
    }
}
```

### Prophecy Alternative

```php
<?php
declare(strict_types=1);

use Prophecy\PhpUnit\ProphecyTrait;

final class OrderServiceTest extends TestCase
{
    use ProphecyTrait;

    public function testCreateOrderSavesToRepository(): void
    {
        // Arrange
        $repository = $this->prophesize(OrderRepository::class);
        $repository->save(Argument::type(Order::class))->shouldBeCalled();

        $service = new OrderService($repository->reveal());

        // Act
        $service->create('customer-123', [new OrderItem('product-1', 2)]);
    }

    public function testGetOrderReturnsFromRepository(): void
    {
        $expectedOrder = self::createOrder();

        $repository = $this->prophesize(OrderRepository::class);
        $repository->find($expectedOrder->id)->willReturn($expectedOrder);

        $service = new OrderService($repository->reveal());

        $result = $service->get($expectedOrder->id);

        $this->assertSame($expectedOrder, $result);
    }
}
```

---

## Fakes Over Mocks

### When to Use Fakes

```php
<?php
declare(strict_types=1);

// PREFER - Fake implementation for complex interfaces
final class InMemoryOrderRepository implements OrderRepository
{
    /** @var array<string, Order> */
    private array $orders = [];

    public function find(string $id): ?Order
    {
        return $this->orders[$id] ?? null;
    }

    public function save(Order $order): void
    {
        $this->orders[$order->id] = $order;
    }

    public function delete(string $id): void
    {
        unset($this->orders[$id]);
    }

    // Test helpers
    public function add(Order $order): void
    {
        $this->orders[$order->id] = $order;
    }

    public function has(string $id): bool
    {
        return isset($this->orders[$id]);
    }

    public function count(): int
    {
        return count($this->orders);
    }
}

// Usage
final class OrderServiceTest extends TestCase
{
    public function testDeleteOrderRemovesFromRepository(): void
    {
        $order = self::createOrder();
        $repository = new InMemoryOrderRepository();
        $repository->add($order);
        $service = new OrderService($repository);

        $service->delete($order->id);

        $this->assertFalse($repository->has($order->id));
    }
}
```

---

## Exception Testing

### Testing Expected Exceptions

```php
<?php
declare(strict_types=1);

final class OrderServiceTest extends TestCase
{
    public function testCreateOrderWithEmptyItemsThrowsException(): void
    {
        $repository = new InMemoryOrderRepository();
        $service = new OrderService($repository);

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Order must have at least one item');

        $service->create('customer-123', []);
    }

    public function testGetOrderNotFoundThrowsException(): void
    {
        $repository = new InMemoryOrderRepository();
        $service = new OrderService($repository);

        $this->expectException(OrderNotFoundException::class);

        $service->getOrFail('nonexistent-id');
    }
}
```

### Testing Exception Properties

```php
<?php
declare(strict_types=1);

final class OrderServiceTest extends TestCase
{
    public function testNotFoundExceptionContainsOrderId(): void
    {
        $repository = new InMemoryOrderRepository();
        $service = new OrderService($repository);
        $orderId = 'order-not-found';

        try {
            $service->getOrFail($orderId);
            $this->fail('Expected OrderNotFoundException was not thrown');
        } catch (OrderNotFoundException $e) {
            $this->assertSame($orderId, $e->orderId);
            $this->assertStringContainsString($orderId, $e->getMessage());
        }
    }
}
```

---

## Laravel Testing Patterns

### Feature vs Unit Tests

```php
<?php
declare(strict_types=1);

// tests/Unit - Pure PHP, no Laravel bootstrap
namespace Tests\Unit;

use PHPUnit\Framework\TestCase;

final class OrderCalculatorTest extends TestCase
{
    public function testCalculateTotalSumsItems(): void
    {
        $calculator = new OrderCalculator();
        $items = [
            new OrderItem('product-1', 2, 10.00),
            new OrderItem('product-2', 1, 25.00),
        ];

        $total = $calculator->calculateTotal($items);

        $this->assertSame(45.00, $total);
    }
}

// tests/Feature - Full Laravel bootstrap
namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

final class OrderApiTest extends TestCase
{
    use RefreshDatabase;

    public function testCreateOrderReturnsCreatedStatus(): void
    {
        $customer = Customer::factory()->create();

        $response = $this->postJson('/api/orders', [
            'customer_id' => $customer->id,
            'items' => [
                ['product_id' => 'prod-1', 'quantity' => 2],
            ],
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'data' => ['id', 'status', 'total'],
        ]);
    }
}
```

### Database Testing with RefreshDatabase

```php
<?php
declare(strict_types=1);

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

final class OrderRepositoryTest extends TestCase
{
    use RefreshDatabase;

    public function testFindReturnsOrder(): void
    {
        $order = Order::factory()->create();

        $found = Order::find($order->id);

        $this->assertNotNull($found);
        $this->assertSame($order->id, $found->id);
    }

    public function testDeleteRemovesOrder(): void
    {
        $order = Order::factory()->create();

        $order->delete();

        $this->assertDatabaseMissing('orders', ['id' => $order->id]);
    }

    public function testCreatePersistsOrder(): void
    {
        $customer = Customer::factory()->create();

        $order = Order::create([
            'customer_id' => $customer->id,
            'status' => OrderStatus::Pending,
            'total' => 100.00,
        ]);

        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'customer_id' => $customer->id,
            'total' => 100.00,
        ]);
    }
}
```

### Model Factories

```php
<?php
declare(strict_types=1);

namespace Database\Factories;

use App\Models\Order;
use App\Models\Customer;
use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<Order> */
final class OrderFactory extends Factory
{
    protected $model = Order::class;

    /** @return array<string, mixed> */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            'status' => OrderStatus::Pending,
            'total' => $this->faker->randomFloat(2, 10, 1000),
            'notes' => $this->faker->optional()->sentence(),
        ];
    }

    public function shipped(): self
    {
        return $this->state(['status' => OrderStatus::Shipped]);
    }

    public function forCustomer(Customer $customer): self
    {
        return $this->state(['customer_id' => $customer->id]);
    }

    public function withTotal(float $total): self
    {
        return $this->state(['total' => $total]);
    }
}

// Usage in tests
$order = Order::factory()->create();
$shippedOrder = Order::factory()->shipped()->create();
$expensiveOrder = Order::factory()->withTotal(500.00)->create();

// Multiple with relationships
$customer = Customer::factory()
    ->has(Order::factory()->count(3))
    ->create();
```

### HTTP Tests and Assertions

```php
<?php
declare(strict_types=1);

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

final class OrderControllerTest extends TestCase
{
    use RefreshDatabase;

    public function testIndexReturnsOrders(): void
    {
        Order::factory()->count(3)->create();

        $response = $this->getJson('/api/orders');

        $response->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'status', 'total', 'created_at'],
                ],
            ]);
    }

    public function testShowReturnsOrder(): void
    {
        $order = Order::factory()->create();

        $response = $this->getJson("/api/orders/{$order->id}");

        $response->assertOk()
            ->assertJson([
                'data' => [
                    'id' => $order->id,
                    'status' => $order->status->value,
                ],
            ]);
    }

    public function testShowNotFoundReturns404(): void
    {
        $response = $this->getJson('/api/orders/nonexistent');

        $response->assertNotFound()
            ->assertJson([
                'message' => 'Order not found',
            ]);
    }

    public function testStoreValidationFails(): void
    {
        $response = $this->postJson('/api/orders', []);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors(['customer_id', 'items']);
    }

    public function testDestroyRequiresAuthentication(): void
    {
        $order = Order::factory()->create();

        $response = $this->deleteJson("/api/orders/{$order->id}");

        $response->assertUnauthorized();
    }
}
```

### Mocking Facades

```php
<?php
declare(strict_types=1);

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Event;
use App\Mail\OrderConfirmation;
use App\Jobs\ProcessOrder;
use App\Events\OrderCreated;

final class OrderCreationTest extends TestCase
{
    public function testCreatingOrderSendsMail(): void
    {
        Mail::fake();
        $customer = Customer::factory()->create();

        $this->postJson('/api/orders', [
            'customer_id' => $customer->id,
            'items' => [['product_id' => 'prod-1', 'quantity' => 1]],
        ]);

        Mail::assertSent(OrderConfirmation::class, function ($mail) use ($customer) {
            return $mail->hasTo($customer->email);
        });
    }

    public function testCreatingOrderQueuesJob(): void
    {
        Queue::fake();

        $this->postJson('/api/orders', [
            'customer_id' => Customer::factory()->create()->id,
            'items' => [['product_id' => 'prod-1', 'quantity' => 1]],
        ]);

        Queue::assertPushed(ProcessOrder::class);
    }

    public function testCreatingOrderDispatchesEvent(): void
    {
        Event::fake([OrderCreated::class]);

        $this->postJson('/api/orders', [
            'customer_id' => Customer::factory()->create()->id,
            'items' => [['product_id' => 'prod-1', 'quantity' => 1]],
        ]);

        Event::assertDispatched(OrderCreated::class);
    }
}
```

---

## Test Coverage Guidelines

### What to Test

```php
<?php
declare(strict_types=1);

// DO test:
// - Business logic and domain rules
// - Edge cases and boundary conditions
// - Error handling paths
// - Integration points

// DON'T test:
// - Framework code (Laravel internals)
// - Simple getters/setters
// - Third-party library behavior
// - Private methods directly
```

### Coverage Through Behavior

```php
<?php
declare(strict_types=1);

// WRONG - Testing implementation details
final class OrderServiceTest extends TestCase
{
    public function testCreateCallsValidatorFirst(): void
    {
        $validator = $this->createMock(OrderValidator::class);
        $validator->expects($this->once())->method('validate');

        $repository = $this->createMock(OrderRepository::class);
        $repository->expects($this->once())->method('save');

        // This tests HOW, not WHAT
    }
}

// CORRECT - Testing behavior/outcome
final class OrderServiceTest extends TestCase
{
    public function testCreateWithInvalidDataThrowsValidationException(): void
    {
        $repository = new InMemoryOrderRepository();
        $service = new OrderService($repository);

        $this->expectException(ValidationException::class);

        $service->create('customer-123', []); // Empty items
    }

    public function testCreateWithValidDataPersistsOrder(): void
    {
        $repository = new InMemoryOrderRepository();
        $service = new OrderService($repository);

        $order = $service->create('customer-123', [new OrderItem('prod-1', 1)]);

        $this->assertTrue($repository->has($order->id));
    }
}
```

---

## Summary Checklist

When writing PHP tests, verify:

- [ ] Test names follow `test[Method][Scenario][Expected]` pattern
- [ ] Tests use Arrange-Act-Assert structure
- [ ] Factory methods used instead of shared test state
- [ ] Data providers used for table-driven tests
- [ ] Fakes preferred over mocks for complex interfaces
- [ ] Tests verify behavior, not implementation details
- [ ] Exception testing includes message/properties
- [ ] Laravel: Feature tests use RefreshDatabase
- [ ] Laravel: Model factories used for test data
- [ ] Laravel: Facades mocked with `::fake()`
- [ ] Tests are independent and can run in any order
- [ ] No sleeping/waiting in tests
