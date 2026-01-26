---
name: unity-testing
description: Unity Test Framework patterns for Edit Mode and Play Mode tests. Use when writing Unity tests.
---

# Unity Testing Patterns

## Core Principle

**Test behavior in isolation.** Use Edit Mode tests for pure logic, Play Mode tests for MonoBehaviour integration. Separate game logic from Unity dependencies where possible.

---

## Test Framework Setup

### Unity Test Framework Structure

```
Assets/
├── Scripts/
│   ├── Runtime/
│   │   └── ...
│   └── Editor/
│       └── ...
├── Tests/
│   ├── EditMode/
│   │   ├── EditModeTests.asmdef    // Editor platform only
│   │   └── ...
│   └── PlayMode/
│       ├── PlayModeTests.asmdef    // References runtime assemblies
│       └── ...
```

### Assembly Definition Setup

```json
// EditModeTests.asmdef
{
    "name": "EditModeTests",
    "references": [
        "YourGame.Runtime"
    ],
    "includePlatforms": [
        "Editor"
    ],
    "optionalUnityReferences": [
        "TestAssemblies"
    ]
}

// PlayModeTests.asmdef
{
    "name": "PlayModeTests",
    "references": [
        "YourGame.Runtime"
    ],
    "includePlatforms": [],
    "optionalUnityReferences": [
        "TestAssemblies"
    ]
}
```

---

## Edit Mode Tests

### Pure Logic Testing

```csharp
using NUnit.Framework;

// ✅ Test pure C# logic without Unity dependencies
public class DamageCalculatorTests
{
    [Test]
    public void CalculateDamage_WithCritical_DoublesBaseDamage()
    {
        // Arrange
        var calculator = new DamageCalculator();
        var baseDamage = 10f;

        // Act
        var result = calculator.Calculate(baseDamage, isCritical: true);

        // Assert
        Assert.AreEqual(20f, result);
    }

    [Test]
    public void CalculateDamage_WithArmor_ReducesDamage()
    {
        var calculator = new DamageCalculator();

        var result = calculator.Calculate(baseDamage: 100f, armor: 25f);

        Assert.AreEqual(75f, result);
    }

    [TestCase(0f, 0f)]
    [TestCase(100f, 100f)]
    [TestCase(50f, 50f)]
    public void CalculateDamage_NoModifiers_ReturnsBaseDamage(
        float baseDamage,
        float expected)
    {
        var calculator = new DamageCalculator();

        var result = calculator.Calculate(baseDamage);

        Assert.AreEqual(expected, result);
    }
}
```

### Testing ScriptableObjects

```csharp
using NUnit.Framework;
using UnityEngine;

public class WeaponDataTests
{
    [Test]
    public void WeaponData_DamagePerSecond_CalculatesCorrectly()
    {
        // Arrange - Create ScriptableObject instance for testing
        var weapon = ScriptableObject.CreateInstance<WeaponData>();
        weapon.damage = 10f;
        weapon.attackSpeed = 2f;  // 2 attacks per second

        // Act
        var dps = weapon.DamagePerSecond;

        // Assert
        Assert.AreEqual(20f, dps);

        // Cleanup
        Object.DestroyImmediate(weapon);
    }
}

// ✅ Test data-driven weapon stats
public class WeaponDataValidationTests
{
    private WeaponData _weapon;

    [SetUp]
    public void SetUp()
    {
        _weapon = ScriptableObject.CreateInstance<WeaponData>();
    }

    [TearDown]
    public void TearDown()
    {
        Object.DestroyImmediate(_weapon);
    }

    [Test]
    public void Damage_CannotBeNegative_ClampedToZero()
    {
        _weapon.damage = -10f;

        Assert.AreEqual(0f, _weapon.Damage);
    }
}
```

### Testing Serialization

```csharp
using NUnit.Framework;
using UnityEngine;

public class SaveDataTests
{
    [Test]
    public void SaveData_SerializesToJson_Correctly()
    {
        var saveData = new SaveData
        {
            PlayerName = "TestPlayer",
            Level = 5,
            Health = 100f
        };

        var json = JsonUtility.ToJson(saveData);
        var deserialized = JsonUtility.FromJson<SaveData>(json);

        Assert.AreEqual(saveData.PlayerName, deserialized.PlayerName);
        Assert.AreEqual(saveData.Level, deserialized.Level);
        Assert.AreEqual(saveData.Health, deserialized.Health);
    }
}
```

---

## Play Mode Tests

### Testing MonoBehaviours

```csharp
using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

public class PlayerControllerTests
{
    private GameObject _playerObject;
    private PlayerController _player;

    [SetUp]
    public void SetUp()
    {
        _playerObject = new GameObject("Player");
        _player = _playerObject.AddComponent<PlayerController>();
    }

    [TearDown]
    public void TearDown()
    {
        Object.Destroy(_playerObject);
    }

    [UnityTest]
    public IEnumerator Move_WithInput_ChangesPosition()
    {
        var startPosition = _player.transform.position;

        // Simulate input (you'd typically use a mock input system)
        _player.Move(Vector3.forward);

        // Wait one frame for Update to run
        yield return null;

        Assert.AreNotEqual(startPosition, _player.transform.position);
    }

    [UnityTest]
    public IEnumerator TakeDamage_HealthReachesZero_TriggersDeathEvent()
    {
        var deathTriggered = false;
        _player.OnDeath += () => deathTriggered = true;
        _player.Initialize(health: 100f);

        _player.TakeDamage(100f);

        yield return null;

        Assert.IsTrue(deathTriggered);
    }
}
```

### Testing Coroutines

```csharp
[UnityTest]
public IEnumerator SpawnEnemy_AfterDelay_CreatesEnemy()
{
    var spawner = new GameObject().AddComponent<EnemySpawner>();

    spawner.SpawnAfterDelay(0.1f);

    // Wait for spawn delay plus buffer
    yield return new WaitForSeconds(0.15f);

    var enemy = Object.FindObjectOfType<Enemy>();
    Assert.IsNotNull(enemy);

    // Cleanup
    Object.Destroy(spawner.gameObject);
    if (enemy != null) Object.Destroy(enemy.gameObject);
}
```

### Testing Physics

```csharp
[UnityTest]
public IEnumerator Projectile_HitsTarget_DealsDamage()
{
    // Arrange
    var target = new GameObject("Target");
    target.AddComponent<BoxCollider>();
    var health = target.AddComponent<HealthComponent>();
    health.Initialize(100f);
    target.transform.position = Vector3.forward * 5f;

    var projectile = new GameObject("Projectile");
    projectile.AddComponent<SphereCollider>().isTrigger = true;
    var rb = projectile.AddComponent<Rigidbody>();
    var proj = projectile.AddComponent<Projectile>();
    proj.damage = 25f;

    // Act - fire projectile
    rb.velocity = Vector3.forward * 10f;

    // Wait for physics
    yield return new WaitForSeconds(1f);

    // Assert
    Assert.AreEqual(75f, health.CurrentHealth);

    // Cleanup
    Object.Destroy(target);
    Object.Destroy(projectile);
}
```

### Testing Scene Loading

```csharp
using UnityEngine.SceneManagement;

[UnityTest]
public IEnumerator LoadMainMenu_FromGame_LoadsCorrectScene()
{
    // Load test scene first
    yield return SceneManager.LoadSceneAsync("TestScene", LoadSceneMode.Single);

    var gameManager = Object.FindObjectOfType<GameManager>();

    // Act
    gameManager.LoadMainMenu();

    // Wait for scene load
    yield return new WaitUntil(() =>
        SceneManager.GetActiveScene().name == "MainMenu");

    // Assert
    Assert.AreEqual("MainMenu", SceneManager.GetActiveScene().name);
}
```

---

## Test Utilities

### Factory Methods for Test Objects

```csharp
public static class TestFactory
{
    public static GameObject CreatePlayer(
        float health = 100f,
        Vector3? position = null)
    {
        var go = new GameObject("TestPlayer");
        go.transform.position = position ?? Vector3.zero;

        var player = go.AddComponent<PlayerController>();
        player.Initialize(health);

        return go;
    }

    public static GameObject CreateEnemy(
        float health = 50f,
        float damage = 10f)
    {
        var go = new GameObject("TestEnemy");
        var enemy = go.AddComponent<Enemy>();
        enemy.Initialize(health, damage);
        return go;
    }

    public static T CreateScriptableObject<T>() where T : ScriptableObject
    {
        return ScriptableObject.CreateInstance<T>();
    }
}

// Usage
[UnityTest]
public IEnumerator Player_AttacksEnemy_DealsDamage()
{
    var player = TestFactory.CreatePlayer();
    var enemy = TestFactory.CreateEnemy(health: 100f);

    // ... test logic

    yield return null;

    Object.Destroy(player);
    Object.Destroy(enemy);
}
```

### Test Helpers

```csharp
public static class TestHelpers
{
    public static IEnumerator WaitForCondition(
        Func<bool> condition,
        float timeout = 5f)
    {
        var elapsed = 0f;
        while (!condition() && elapsed < timeout)
        {
            elapsed += Time.deltaTime;
            yield return null;
        }

        if (!condition())
        {
            throw new TimeoutException(
                $"Condition not met within {timeout} seconds");
        }
    }

    public static IEnumerator WaitFrames(int frameCount)
    {
        for (var i = 0; i < frameCount; i++)
        {
            yield return null;
        }
    }
}

// Usage
[UnityTest]
public IEnumerator Enemy_Dies_DropsLoot()
{
    var enemy = TestFactory.CreateEnemy(health: 1f);
    enemy.TakeDamage(10f);

    yield return TestHelpers.WaitForCondition(
        () => Object.FindObjectOfType<LootDrop>() != null,
        timeout: 2f);

    var loot = Object.FindObjectOfType<LootDrop>();
    Assert.IsNotNull(loot);
}
```

---

## Mocking Unity Dependencies

### Interface Abstraction

```csharp
// ✅ Abstract Unity dependencies behind interfaces
public interface ITimeProvider
{
    float DeltaTime { get; }
    float Time { get; }
}

public class UnityTimeProvider : ITimeProvider
{
    public float DeltaTime => Time.deltaTime;
    public float Time => Time.time;
}

public class MockTimeProvider : ITimeProvider
{
    public float DeltaTime { get; set; } = 0.016f;
    public float Time { get; set; } = 0f;
}

// Usage in tests
[Test]
public void Movement_UsesTimeProvider_CorrectSpeed()
{
    var timeProvider = new MockTimeProvider { DeltaTime = 1f };
    var movement = new MovementSystem(timeProvider);

    var distance = movement.CalculateDistance(speed: 10f);

    Assert.AreEqual(10f, distance);
}
```

### Input Abstraction

```csharp
public interface IInputProvider
{
    Vector2 MovementInput { get; }
    bool JumpPressed { get; }
    bool FirePressed { get; }
}

public class UnityInputProvider : IInputProvider
{
    public Vector2 MovementInput => new Vector2(
        Input.GetAxis("Horizontal"),
        Input.GetAxis("Vertical"));
    public bool JumpPressed => Input.GetButtonDown("Jump");
    public bool FirePressed => Input.GetButton("Fire1");
}

public class MockInputProvider : IInputProvider
{
    public Vector2 MovementInput { get; set; }
    public bool JumpPressed { get; set; }
    public bool FirePressed { get; set; }
}

// Test
[Test]
public void PlayerController_JumpInput_Jumps()
{
    var input = new MockInputProvider { JumpPressed = true };
    var controller = new PlayerController(input);

    controller.ProcessInput();

    Assert.IsTrue(controller.IsJumping);
}
```

---

## Testing Events

### UnityEvent Testing

```csharp
[UnityTest]
public IEnumerator Button_OnClick_InvokesEvent()
{
    var buttonObj = new GameObject();
    var button = buttonObj.AddComponent<CustomButton>();
    var wasInvoked = false;

    button.OnClicked.AddListener(() => wasInvoked = true);
    button.SimulateClick();

    yield return null;

    Assert.IsTrue(wasInvoked);

    Object.Destroy(buttonObj);
}
```

### C# Event Testing

```csharp
[Test]
public void HealthSystem_OnDeath_EventFired()
{
    var health = new HealthSystem(maxHealth: 100f);
    var eventFired = false;

    health.OnDeath += () => eventFired = true;
    health.TakeDamage(100f);

    Assert.IsTrue(eventFired);
}

[Test]
public void HealthSystem_OnDamage_EventContainsCorrectAmount()
{
    var health = new HealthSystem(maxHealth: 100f);
    float? receivedDamage = null;

    health.OnDamageTaken += (damage) => receivedDamage = damage;
    health.TakeDamage(25f);

    Assert.AreEqual(25f, receivedDamage);
}
```

---

## Test Categories

### Organize Tests with Categories

```csharp
[TestFixture]
[Category("Unit")]
public class DamageCalculatorTests { }

[TestFixture]
[Category("Integration")]
public class PlayerCombatTests { }

[TestFixture]
[Category("Performance")]
public class PoolingPerformanceTests { }

// Run specific categories:
// Unity Test Runner > Edit Mode/Play Mode > Filter by category
```

---

## Assertions Best Practices

### Unity-Specific Assertions

```csharp
using UnityEngine.TestTools.Utils;

[Test]
public void Position_Approximately_Equal()
{
    var expected = new Vector3(1f, 2f, 3f);
    var actual = new Vector3(1.0001f, 2.0001f, 3.0001f);

    // ✅ Use approximate comparison for floats
    Assert.That(actual, Is.EqualTo(expected).Using(Vector3EqualityComparer.Instance));
}

[Test]
public void Rotation_Approximately_Equal()
{
    var expected = Quaternion.Euler(0, 90, 0);
    var actual = Quaternion.Euler(0, 89.999f, 0);

    Assert.That(actual, Is.EqualTo(expected).Using(QuaternionEqualityComparer.Instance));
}

// Custom float tolerance
[Test]
public void Health_ApproximatelyEqual()
{
    var expected = 100f;
    var actual = 100.0001f;

    Assert.AreEqual(expected, actual, 0.001f);  // Tolerance of 0.001
}
```

### Log Assertions

```csharp
[Test]
public void InvalidOperation_LogsError()
{
    LogAssert.Expect(LogType.Error, "Invalid operation attempted");

    var system = new GameSystem();
    system.PerformInvalidOperation();

    // Test passes only if expected log message appeared
}

[UnityTest]
public IEnumerator NoErrorsLogged_DuringNormalOperation()
{
    LogAssert.NoUnexpectedReceived();

    var player = TestFactory.CreatePlayer();
    player.PerformNormalAction();

    yield return null;

    // Test fails if any errors/warnings were logged
}
```

---

## Summary Checklist

When writing Unity tests, verify:

- [ ] Edit Mode tests for pure C# logic
- [ ] Play Mode tests for MonoBehaviour integration
- [ ] Assembly definitions separate test from runtime code
- [ ] `[SetUp]` and `[TearDown]` for test isolation
- [ ] `Object.Destroy()` in TearDown to prevent leaks
- [ ] Factory methods create test objects consistently
- [ ] Interfaces abstract Unity dependencies for unit testing
- [ ] `yield return null` waits for Update cycle
- [ ] `WaitForSeconds` tests time-based behavior
- [ ] Vector/Quaternion approximate comparisons used
- [ ] `LogAssert` verifies expected logs
- [ ] Categories organize test types
