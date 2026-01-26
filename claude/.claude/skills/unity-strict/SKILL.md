---
name: unity-strict
description: Unity engine best practices and patterns. Use when writing Unity/C# game code.
---

# Unity Strict Mode

## Core Rules

1. **Cache component references** - never `GetComponent` in Update
2. **Never `new MonoBehaviour()`** - use `AddComponent` or prefabs
3. **Clean up events** - unsubscribe in `OnDisable`/`OnDestroy`
4. **Use `[SerializeField]`** - for inspector fields, not `public`

---

## Component Lifecycle

### MonoBehaviour Execution Order

```csharp
// Initialization (once per instance)
Awake()        // Called when instance is created, before Start
OnEnable()     // Called when object becomes active
Start()        // Called before first Update, after all Awake calls

// Update (every frame)
FixedUpdate()  // Physics updates (fixed timestep)
Update()       // Game logic (every frame)
LateUpdate()   // After all Updates (camera follow, etc.)

// Cleanup
OnDisable()    // When object becomes inactive
OnDestroy()    // When object is destroyed
OnApplicationQuit() // When application exits
```

### Cache References in Awake

```csharp
// ❌ WRONG - GetComponent every frame
public class PlayerController : MonoBehaviour
{
    private void Update()
    {
        var rb = GetComponent<Rigidbody>(); // Expensive every frame!
        rb.AddForce(Vector3.up);
    }
}

// ✅ CORRECT - Cache in Awake
public class PlayerController : MonoBehaviour
{
    private Rigidbody _rigidbody;

    private void Awake()
    {
        _rigidbody = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        _rigidbody.AddForce(Vector3.up);
    }
}

// ✅ CORRECT - With RequireComponent for safety
[RequireComponent(typeof(Rigidbody))]
public class PlayerController : MonoBehaviour
{
    private Rigidbody _rigidbody;

    private void Awake()
    {
        _rigidbody = GetComponent<Rigidbody>();
    }
}
```

### Never Use `new` on MonoBehaviour

```csharp
// ❌ WRONG - new on MonoBehaviour
var player = new PlayerController(); // Runtime error!

// ✅ CORRECT - AddComponent
var player = gameObject.AddComponent<PlayerController>();

// ✅ CORRECT - Instantiate prefab
var playerPrefab = Resources.Load<GameObject>("Player");
var player = Instantiate(playerPrefab);

// ✅ CORRECT - Find existing
var player = FindObjectOfType<PlayerController>();
```

---

## Serialization

### Use SerializeField for Inspector Fields

```csharp
// ❌ WRONG - Public fields for inspector access
public class Enemy : MonoBehaviour
{
    public float health = 100f;      // Exposes to other scripts unnecessarily
    public GameObject target;         // Anyone can modify
    public float speed;               // No encapsulation
}

// ✅ CORRECT - SerializeField with private
public class Enemy : MonoBehaviour
{
    [SerializeField] private float _health = 100f;
    [SerializeField] private GameObject _target;
    [SerializeField] private float _speed = 5f;

    public float Health => _health;   // Read-only public access if needed
}

// ✅ CORRECT - With headers and tooltips
public class Enemy : MonoBehaviour
{
    [Header("Stats")]
    [SerializeField, Tooltip("Maximum health points")]
    private float _maxHealth = 100f;

    [SerializeField, Range(0f, 20f)]
    private float _speed = 5f;

    [Header("References")]
    [SerializeField]
    private Transform _target;
}
```

### Serialization Rules

```csharp
// Unity serializes:
// - public fields (avoid)
// - [SerializeField] private fields (preferred)
// - Primitives, strings, enums
// - Arrays and Lists of serializable types
// - Structs and classes marked [Serializable]

// ❌ NOT serialized:
// - Properties (even public)
// - Static fields
// - Readonly fields
// - Dictionaries (use SerializableDictionary or ScriptableObjects)

[Serializable]
public struct EnemyConfig
{
    public float health;
    public float damage;
    public float speed;
}

public class Enemy : MonoBehaviour
{
    [SerializeField] private EnemyConfig _config;
}
```

---

## Event Management

### Always Unsubscribe from Events

```csharp
// ❌ WRONG - Memory leak from unsubscribed event
public class UIManager : MonoBehaviour
{
    private void Start()
    {
        GameEvents.OnPlayerDied += HandlePlayerDied;
    }

    private void HandlePlayerDied()
    {
        // Update UI
    }
    // Never unsubscribes - memory leak when destroyed!
}

// ✅ CORRECT - Unsubscribe in OnDisable
public class UIManager : MonoBehaviour
{
    private void OnEnable()
    {
        GameEvents.OnPlayerDied += HandlePlayerDied;
    }

    private void OnDisable()
    {
        GameEvents.OnPlayerDied -= HandlePlayerDied;
    }

    private void HandlePlayerDied()
    {
        // Update UI
    }
}

// ✅ CORRECT - Unsubscribe in OnDestroy for persistent events
public class GameManager : MonoBehaviour
{
    private void Awake()
    {
        Application.lowMemory += HandleLowMemory;
    }

    private void OnDestroy()
    {
        Application.lowMemory -= HandleLowMemory;
    }
}
```

### UnityEvents for Inspector Configuration

```csharp
using UnityEngine.Events;

public class HealthSystem : MonoBehaviour
{
    [SerializeField] private float _maxHealth = 100f;

    // Configurable in inspector
    [SerializeField] private UnityEvent _onDeath;
    [SerializeField] private UnityEvent<float> _onHealthChanged;

    private float _currentHealth;

    public void TakeDamage(float damage)
    {
        _currentHealth = Mathf.Max(0, _currentHealth - damage);
        _onHealthChanged?.Invoke(_currentHealth);

        if (_currentHealth <= 0)
        {
            _onDeath?.Invoke();
        }
    }
}
```

---

## Finding Objects

### Avoid String-Based Methods

```csharp
// ❌ WRONG - String-based methods (no compile-time safety)
gameObject.SendMessage("TakeDamage", 10f);  // No error if method doesn't exist
Invoke("Fire", 1f);                          // String typo = silent failure
InvokeRepeating("UpdateAI", 0f, 0.5f);      // Not refactor-safe

// ✅ CORRECT - Direct method calls
var damageable = target.GetComponent<IDamageable>();
damageable?.TakeDamage(10f);

// ✅ CORRECT - Coroutines instead of Invoke
StartCoroutine(FireAfterDelay(1f));

private IEnumerator FireAfterDelay(float delay)
{
    yield return new WaitForSeconds(delay);
    Fire();
}

// ✅ CORRECT - InvokeRepeating alternative
StartCoroutine(UpdateAILoop());

private IEnumerator UpdateAILoop()
{
    while (true)
    {
        UpdateAI();
        yield return new WaitForSeconds(0.5f);
    }
}
```

### FindObjectOfType Sparingly

```csharp
// ❌ WRONG - FindObjectOfType in Update
private void Update()
{
    var player = FindObjectOfType<Player>(); // Very expensive!
    transform.LookAt(player.transform);
}

// ✅ CORRECT - Cache reference
private Player _player;

private void Start()
{
    _player = FindObjectOfType<Player>();
}

private void Update()
{
    if (_player != null)
    {
        transform.LookAt(_player.transform);
    }
}

// ✅ BETTER - Dependency injection or singleton pattern
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    public Player Player { get; private set; }

    private void Awake()
    {
        Instance = this;
    }
}

// Usage
transform.LookAt(GameManager.Instance.Player.transform);
```

---

## Null Checks in Unity

### Use Unity's Null Check Pattern

```csharp
// Unity overloads == operator for destroyed objects
// A destroyed object is not "null" in C# sense, but == null returns true

// ✅ CORRECT - Unity-style null check
if (gameObject != null)
{
    // Safe to use
}

// ✅ CORRECT - Implicit bool conversion
if (gameObject)
{
    // Safe to use (gameObject exists and not destroyed)
}

// ⚠️ CAUTION - C# null-conditional doesn't work as expected
// This can throw if gameObject is destroyed (not actually null)
var name = gameObject?.name; // May throw!

// ✅ CORRECT - Explicit check then access
string name = null;
if (gameObject != null)
{
    name = gameObject.name;
}

// ✅ CORRECT - TryGetComponent pattern
if (TryGetComponent<Rigidbody>(out var rb))
{
    rb.AddForce(Vector3.up);
}
```

---

## Transform Operations

### Cache Transform

```csharp
// ❌ WRONG - Accessing transform property repeatedly
private void Update()
{
    transform.position += Vector3.forward * Time.deltaTime;
    transform.rotation = Quaternion.Euler(0, 90, 0);
    transform.localScale = Vector3.one;
}

// ✅ CORRECT - Cache transform reference
private Transform _transform;

private void Awake()
{
    _transform = transform;
}

private void Update()
{
    _transform.position += Vector3.forward * Time.deltaTime;
}

// ✅ BETTER - Use cached for frequent access, direct for occasional
// transform is already optimized in modern Unity, but caching
// is still useful for very hot paths
```

### Prefer Local Space Operations

```csharp
// ❌ LESS EFFICIENT - World space when local would work
transform.position = transform.position + transform.forward * speed;

// ✅ CORRECT - Local space operation
transform.Translate(Vector3.forward * speed * Time.deltaTime);

// ✅ CORRECT - Explicit local/world choice
transform.Translate(Vector3.forward * speed * Time.deltaTime, Space.Self);
transform.Translate(Vector3.forward * speed * Time.deltaTime, Space.World);
```

---

## Physics

### Use Physics Callbacks Correctly

```csharp
// Physics callbacks (require collider on this object)
private void OnCollisionEnter(Collision collision) { }   // 3D
private void OnCollisionStay(Collision collision) { }
private void OnCollisionExit(Collision collision) { }

private void OnTriggerEnter(Collider other) { }          // 3D trigger
private void OnTriggerStay(Collider other) { }
private void OnTriggerExit(Collider other) { }

private void OnCollisionEnter2D(Collision2D collision) { } // 2D
private void OnTriggerEnter2D(Collider2D other) { }

// ✅ CORRECT - Check what you collided with
private void OnTriggerEnter(Collider other)
{
    // Prefer tags or layers over GetComponent for performance
    if (other.CompareTag("Player"))
    {
        // Handle player collision
    }

    // Or use layers
    if (((1 << other.gameObject.layer) & _playerLayerMask) != 0)
    {
        // Handle player collision
    }

    // GetComponent for complex interactions
    if (other.TryGetComponent<IDamageable>(out var damageable))
    {
        damageable.TakeDamage(_damage);
    }
}
```

### Physics in FixedUpdate

```csharp
// ❌ WRONG - Physics in Update (inconsistent)
private void Update()
{
    _rigidbody.AddForce(Vector3.up * _jumpForce);
}

// ✅ CORRECT - Physics in FixedUpdate
private void FixedUpdate()
{
    _rigidbody.AddForce(Vector3.up * _jumpForce);
}

// ✅ CORRECT - Input in Update, physics force in FixedUpdate
private bool _jumpRequested;

private void Update()
{
    if (Input.GetKeyDown(KeyCode.Space))
    {
        _jumpRequested = true;
    }
}

private void FixedUpdate()
{
    if (_jumpRequested)
    {
        _rigidbody.AddForce(Vector3.up * _jumpForce, ForceMode.Impulse);
        _jumpRequested = false;
    }
}
```

---

## Coroutines

### Proper Coroutine Usage

```csharp
// ✅ Store coroutine reference for stopping
private Coroutine _damageOverTimeCoroutine;

public void StartDamageOverTime()
{
    // Stop existing before starting new
    if (_damageOverTimeCoroutine != null)
    {
        StopCoroutine(_damageOverTimeCoroutine);
    }
    _damageOverTimeCoroutine = StartCoroutine(DamageOverTimeRoutine());
}

// ✅ Cache WaitForSeconds to avoid GC
private static readonly WaitForSeconds DamageInterval = new WaitForSeconds(1f);

private IEnumerator DamageOverTimeRoutine()
{
    while (_health > 0)
    {
        TakeDamage(10f);
        yield return DamageInterval;  // Reuse cached instance
    }
}

// ✅ Stop all coroutines on disable
private void OnDisable()
{
    StopAllCoroutines();
}
```

### Avoid Coroutine Allocations

```csharp
// ❌ WRONG - Allocating every yield
private IEnumerator BadRoutine()
{
    while (true)
    {
        yield return new WaitForSeconds(1f);  // Allocation every iteration
    }
}

// ✅ CORRECT - Cache wait objects
private static readonly WaitForSeconds OneSecond = new WaitForSeconds(1f);
private static readonly WaitForEndOfFrame EndOfFrame = new WaitForEndOfFrame();
private static readonly WaitForFixedUpdate FixedUpdate = new WaitForFixedUpdate();

private IEnumerator GoodRoutine()
{
    while (true)
    {
        yield return OneSecond;  // No allocation
    }
}
```

---

## Assembly Definitions

### Organize Code with Assembly Definitions

```
// Project structure with asmdef files
Assets/
├── Scripts/
│   ├── Core/
│   │   ├── Core.asmdef           // Core systems
│   │   └── ...
│   ├── Gameplay/
│   │   ├── Gameplay.asmdef       // Game logic (references Core)
│   │   └── ...
│   ├── UI/
│   │   ├── UI.asmdef             // UI code (references Core, Gameplay)
│   │   └── ...
│   └── Editor/
│       ├── Editor.asmdef         // Editor tools (Editor platform only)
│       └── ...
```

Benefits:
- Faster compilation (only recompile changed assemblies)
- Clear dependency boundaries
- Platform-specific code isolation

---

## Summary Checklist

When writing Unity code, verify:

- [ ] Component references cached in `Awake()`
- [ ] `[RequireComponent]` used for mandatory dependencies
- [ ] Never `new MonoBehaviour()` - use `AddComponent` or prefabs
- [ ] `[SerializeField] private` instead of `public` fields
- [ ] Events subscribed in `OnEnable`, unsubscribed in `OnDisable`
- [ ] No string-based methods (`SendMessage`, string `Invoke`)
- [ ] Unity null checks used (not C# null-conditional)
- [ ] Physics code in `FixedUpdate()`
- [ ] Input reading in `Update()`
- [ ] Coroutines use cached `WaitForX` objects
- [ ] `StopAllCoroutines()` in `OnDisable` if coroutines running
- [ ] Tags/layers used for collision filtering over `GetComponent`
- [ ] Assembly definitions organize large projects
