---
name: unity-patterns
description: Unity architecture patterns including ScriptableObjects, events, and state machines. Use when designing Unity game systems.
---

# Unity Architecture Patterns

## Core Principle

**Decouple systems through data and events.** Use ScriptableObjects for shared data, events for communication, and state machines for complex behavior. Favor composition over inheritance.

---

## ScriptableObject Architecture

### Data Containers

```csharp
// ✅ ScriptableObject for game data
[CreateAssetMenu(fileName = "NewWeapon", menuName = "Game/Weapon Data")]
public class WeaponData : ScriptableObject
{
    [Header("Basic Stats")]
    public string weaponName;
    public Sprite icon;
    public float damage = 10f;
    public float attackSpeed = 1f;

    [Header("Advanced")]
    public DamageType damageType;
    public AudioClip attackSound;
    public GameObject hitEffect;

    // Computed property
    public float DamagePerSecond => damage * attackSpeed;
}

// Usage - reference in inspector
public class WeaponController : MonoBehaviour
{
    [SerializeField] private WeaponData _weaponData;

    public void Attack()
    {
        DealDamage(_weaponData.damage);
        PlaySound(_weaponData.attackSound);
    }
}
```

### Shared Variables (Runtime Data)

```csharp
// ✅ ScriptableObject as shared variable
[CreateAssetMenu(menuName = "Variables/Float")]
public class FloatVariable : ScriptableObject
{
    public float value;

    public void SetValue(float newValue)
    {
        value = newValue;
    }

    public void Add(float amount)
    {
        value += amount;
    }
}

// Usage - Multiple objects share same data
public class PlayerHealth : MonoBehaviour
{
    [SerializeField] private FloatVariable _healthVariable;

    public void TakeDamage(float damage)
    {
        _healthVariable.Add(-damage);
    }
}

public class HealthUI : MonoBehaviour
{
    [SerializeField] private FloatVariable _healthVariable;
    [SerializeField] private Slider _healthSlider;

    private void Update()
    {
        _healthSlider.value = _healthVariable.value;
    }
}
```

### Observable Variables

```csharp
// ✅ ScriptableObject with change events
[CreateAssetMenu(menuName = "Variables/Observable Float")]
public class ObservableFloat : ScriptableObject
{
    [SerializeField] private float _value;

    public event Action<float> OnValueChanged;

    public float Value
    {
        get => _value;
        set
        {
            if (Math.Abs(_value - value) > float.Epsilon)
            {
                _value = value;
                OnValueChanged?.Invoke(_value);
            }
        }
    }
}

// UI automatically updates
public class HealthBar : MonoBehaviour
{
    [SerializeField] private ObservableFloat _playerHealth;
    [SerializeField] private Slider _slider;

    private void OnEnable()
    {
        _playerHealth.OnValueChanged += UpdateSlider;
        UpdateSlider(_playerHealth.Value);
    }

    private void OnDisable()
    {
        _playerHealth.OnValueChanged -= UpdateSlider;
    }

    private void UpdateSlider(float health)
    {
        _slider.value = health;
    }
}
```

---

## Event Architecture

### ScriptableObject Events

```csharp
// ✅ Game Event - decoupled communication
[CreateAssetMenu(menuName = "Events/Game Event")]
public class GameEvent : ScriptableObject
{
    private readonly List<GameEventListener> _listeners = new();

    public void Raise()
    {
        // Iterate backwards to allow removal during iteration
        for (var i = _listeners.Count - 1; i >= 0; i--)
        {
            _listeners[i].OnEventRaised();
        }
    }

    public void RegisterListener(GameEventListener listener)
    {
        if (!_listeners.Contains(listener))
        {
            _listeners.Add(listener);
        }
    }

    public void UnregisterListener(GameEventListener listener)
    {
        _listeners.Remove(listener);
    }
}

// Listener component
public class GameEventListener : MonoBehaviour
{
    [SerializeField] private GameEvent _event;
    [SerializeField] private UnityEvent _response;

    private void OnEnable() => _event.RegisterListener(this);
    private void OnDisable() => _event.UnregisterListener(this);

    public void OnEventRaised() => _response.Invoke();
}

// Usage - trigger from anywhere
public class Player : MonoBehaviour
{
    [SerializeField] private GameEvent _onPlayerDeath;

    public void Die()
    {
        _onPlayerDeath.Raise();  // All listeners respond
    }
}
```

### Typed Events

```csharp
// ✅ Generic event with data
public abstract class GameEvent<T> : ScriptableObject
{
    private readonly List<IGameEventListener<T>> _listeners = new();

    public void Raise(T value)
    {
        for (var i = _listeners.Count - 1; i >= 0; i--)
        {
            _listeners[i].OnEventRaised(value);
        }
    }

    public void RegisterListener(IGameEventListener<T> listener)
    {
        if (!_listeners.Contains(listener))
        {
            _listeners.Add(listener);
        }
    }

    public void UnregisterListener(IGameEventListener<T> listener)
    {
        _listeners.Remove(listener);
    }
}

public interface IGameEventListener<T>
{
    void OnEventRaised(T value);
}

// Concrete implementations
[CreateAssetMenu(menuName = "Events/Int Event")]
public class IntEvent : GameEvent<int> { }

[CreateAssetMenu(menuName = "Events/Float Event")]
public class FloatEvent : GameEvent<float> { }

[CreateAssetMenu(menuName = "Events/String Event")]
public class StringEvent : GameEvent<string> { }
```

### Event Channel Pattern

```csharp
// ✅ Event channels for specific game systems
[CreateAssetMenu(menuName = "Events/Damage Event Channel")]
public class DamageEventChannel : ScriptableObject
{
    public event Action<DamageInfo> OnDamageDealt;

    public void RaiseDamageDealt(DamageInfo damageInfo)
    {
        OnDamageDealt?.Invoke(damageInfo);
    }
}

public struct DamageInfo
{
    public GameObject Source;
    public GameObject Target;
    public float Amount;
    public DamageType Type;
    public Vector3 HitPoint;
}

// Damage dealer
public class Weapon : MonoBehaviour
{
    [SerializeField] private DamageEventChannel _damageChannel;

    public void DealDamage(GameObject target, float amount, Vector3 hitPoint)
    {
        _damageChannel.RaiseDamageDealt(new DamageInfo
        {
            Source = gameObject,
            Target = target,
            Amount = amount,
            HitPoint = hitPoint
        });
    }
}

// Damage number spawner listens
public class DamageNumberSpawner : MonoBehaviour
{
    [SerializeField] private DamageEventChannel _damageChannel;

    private void OnEnable()
    {
        _damageChannel.OnDamageDealt += SpawnDamageNumber;
    }

    private void OnDisable()
    {
        _damageChannel.OnDamageDealt -= SpawnDamageNumber;
    }

    private void SpawnDamageNumber(DamageInfo info)
    {
        // Spawn floating damage number at hit point
    }
}
```

---

## State Machine Pattern

### Simple State Machine

```csharp
// ✅ Enum-based state machine
public class EnemyAI : MonoBehaviour
{
    public enum State { Idle, Patrol, Chase, Attack, Dead }

    [SerializeField] private State _currentState = State.Idle;

    private void Update()
    {
        switch (_currentState)
        {
            case State.Idle:
                UpdateIdle();
                break;
            case State.Patrol:
                UpdatePatrol();
                break;
            case State.Chase:
                UpdateChase();
                break;
            case State.Attack:
                UpdateAttack();
                break;
            case State.Dead:
                // No update
                break;
        }
    }

    public void ChangeState(State newState)
    {
        if (_currentState == newState) return;

        ExitState(_currentState);
        _currentState = newState;
        EnterState(_currentState);
    }

    private void EnterState(State state)
    {
        switch (state)
        {
            case State.Chase:
                // Start chase animation
                break;
            case State.Attack:
                // Start attack animation
                break;
        }
    }

    private void ExitState(State state)
    {
        // Cleanup for exited state
    }
}
```

### ScriptableObject State Machine

```csharp
// ✅ Modular state machine with ScriptableObjects
public abstract class State : ScriptableObject
{
    public abstract void Enter(StateMachine stateMachine);
    public abstract void Execute(StateMachine stateMachine);
    public abstract void Exit(StateMachine stateMachine);
}

[CreateAssetMenu(menuName = "AI/States/Patrol State")]
public class PatrolState : State
{
    [SerializeField] private float _patrolSpeed = 3f;

    public override void Enter(StateMachine sm)
    {
        sm.Agent.speed = _patrolSpeed;
        sm.Animator.SetBool("Walking", true);
    }

    public override void Execute(StateMachine sm)
    {
        if (sm.CanSeeTarget())
        {
            sm.ChangeState(sm.ChaseState);
            return;
        }

        sm.Patrol();
    }

    public override void Exit(StateMachine sm)
    {
        sm.Animator.SetBool("Walking", false);
    }
}

public class StateMachine : MonoBehaviour
{
    [SerializeField] private State _initialState;

    public State ChaseState;
    public State AttackState;
    public State PatrolState;

    public NavMeshAgent Agent { get; private set; }
    public Animator Animator { get; private set; }

    private State _currentState;

    private void Awake()
    {
        Agent = GetComponent<NavMeshAgent>();
        Animator = GetComponent<Animator>();
    }

    private void Start()
    {
        ChangeState(_initialState);
    }

    private void Update()
    {
        _currentState?.Execute(this);
    }

    public void ChangeState(State newState)
    {
        _currentState?.Exit(this);
        _currentState = newState;
        _currentState?.Enter(this);
    }
}
```

### Hierarchical State Machine

```csharp
// ✅ States with sub-states
public abstract class HierarchicalState : State
{
    [SerializeField] protected State _defaultSubState;
    protected State _currentSubState;

    public override void Enter(StateMachine sm)
    {
        if (_defaultSubState != null)
        {
            _currentSubState = _defaultSubState;
            _currentSubState.Enter(sm);
        }
    }

    public override void Execute(StateMachine sm)
    {
        _currentSubState?.Execute(sm);
    }

    public override void Exit(StateMachine sm)
    {
        _currentSubState?.Exit(sm);
    }

    public void ChangeSubState(State newSubState, StateMachine sm)
    {
        _currentSubState?.Exit(sm);
        _currentSubState = newSubState;
        _currentSubState?.Enter(sm);
    }
}
```

---

## Component Pattern

### Composition Over Inheritance

```csharp
// ❌ WRONG - Deep inheritance hierarchy
public class Entity { }
public class Character : Entity { }
public class Player : Character { }
public class Mage : Player { }
public class FireMage : Mage { }  // Where does it end?

// ✅ CORRECT - Composition with components
public class Entity : MonoBehaviour
{
    // Core components added as needed
}

// Separate, reusable components
public class HealthComponent : MonoBehaviour
{
    [SerializeField] private float _maxHealth = 100f;
    private float _currentHealth;

    public event Action<float> OnHealthChanged;
    public event Action OnDeath;

    public void TakeDamage(float amount)
    {
        _currentHealth = Mathf.Max(0, _currentHealth - amount);
        OnHealthChanged?.Invoke(_currentHealth);

        if (_currentHealth <= 0)
        {
            OnDeath?.Invoke();
        }
    }
}

public class MoveComponent : MonoBehaviour
{
    [SerializeField] private float _speed = 5f;

    public void Move(Vector3 direction)
    {
        transform.position += direction * _speed * Time.deltaTime;
    }
}

// Compose entities from components
// Player: Entity + HealthComponent + MoveComponent + PlayerInput
// Enemy: Entity + HealthComponent + MoveComponent + AIController
```

### Interface-Based Components

```csharp
// ✅ Interfaces for component contracts
public interface IDamageable
{
    void TakeDamage(float amount, DamageType type);
    bool IsDead { get; }
}

public interface IInteractable
{
    string InteractionPrompt { get; }
    void Interact(GameObject interactor);
}

public interface IPoolable
{
    void OnSpawn();
    void OnDespawn();
}

// Components implement interfaces
public class HealthComponent : MonoBehaviour, IDamageable
{
    public bool IsDead => _currentHealth <= 0;

    public void TakeDamage(float amount, DamageType type)
    {
        // Apply damage modifiers based on type
        var modifiedDamage = CalculateDamage(amount, type);
        _currentHealth -= modifiedDamage;
    }
}

// Systems work with interfaces
public class DamageSystem : MonoBehaviour
{
    public void ApplyDamage(GameObject target, float damage, DamageType type)
    {
        if (target.TryGetComponent<IDamageable>(out var damageable))
        {
            if (!damageable.IsDead)
            {
                damageable.TakeDamage(damage, type);
            }
        }
    }
}
```

---

## Service Locator Pattern

### Lightweight Service Locator

```csharp
// ✅ Simple service locator for game services
public static class Services
{
    private static readonly Dictionary<Type, object> _services = new();

    public static void Register<T>(T service) where T : class
    {
        _services[typeof(T)] = service;
    }

    public static T Get<T>() where T : class
    {
        if (_services.TryGetValue(typeof(T), out var service))
        {
            return (T)service;
        }
        throw new InvalidOperationException($"Service {typeof(T)} not registered");
    }

    public static bool TryGet<T>(out T service) where T : class
    {
        if (_services.TryGetValue(typeof(T), out var obj))
        {
            service = (T)obj;
            return true;
        }
        service = null;
        return false;
    }

    public static void Clear()
    {
        _services.Clear();
    }
}

// Registration at game start
public class GameBootstrap : MonoBehaviour
{
    [SerializeField] private AudioManager _audioManager;
    [SerializeField] private SaveSystem _saveSystem;

    private void Awake()
    {
        Services.Register<IAudioManager>(_audioManager);
        Services.Register<ISaveSystem>(_saveSystem);
    }

    private void OnDestroy()
    {
        Services.Clear();
    }
}

// Usage anywhere
public class PlayerDeath : MonoBehaviour
{
    public void Die()
    {
        Services.Get<IAudioManager>().PlaySound("death");
        Services.Get<ISaveSystem>().SaveGame();
    }
}
```

---

## Command Pattern

### Input Command System

```csharp
// ✅ Command pattern for input/undo
public interface ICommand
{
    void Execute();
    void Undo();
}

public class MoveCommand : ICommand
{
    private readonly Transform _transform;
    private readonly Vector3 _direction;
    private readonly float _distance;
    private Vector3 _previousPosition;

    public MoveCommand(Transform transform, Vector3 direction, float distance)
    {
        _transform = transform;
        _direction = direction;
        _distance = distance;
    }

    public void Execute()
    {
        _previousPosition = _transform.position;
        _transform.position += _direction * _distance;
    }

    public void Undo()
    {
        _transform.position = _previousPosition;
    }
}

public class CommandInvoker
{
    private readonly Stack<ICommand> _undoStack = new();
    private readonly Stack<ICommand> _redoStack = new();

    public void Execute(ICommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear();
    }

    public void Undo()
    {
        if (_undoStack.Count > 0)
        {
            var command = _undoStack.Pop();
            command.Undo();
            _redoStack.Push(command);
        }
    }

    public void Redo()
    {
        if (_redoStack.Count > 0)
        {
            var command = _redoStack.Pop();
            command.Execute();
            _undoStack.Push(command);
        }
    }
}
```

---

## Singleton Pattern (Use Sparingly)

### Lazy Singleton

```csharp
// ✅ Thread-safe lazy singleton (use sparingly)
public class GameManager : MonoBehaviour
{
    private static GameManager _instance;
    private static readonly object _lock = new();

    public static GameManager Instance
    {
        get
        {
            if (_instance == null)
            {
                lock (_lock)
                {
                    _instance = FindObjectOfType<GameManager>();

                    if (_instance == null)
                    {
                        var go = new GameObject("GameManager");
                        _instance = go.AddComponent<GameManager>();
                        DontDestroyOnLoad(go);
                    }
                }
            }
            return _instance;
        }
    }

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }

        _instance = this;
        DontDestroyOnLoad(gameObject);
    }
}
```

### Generic Singleton Base

```csharp
// ✅ Reusable singleton base class
public abstract class Singleton<T> : MonoBehaviour where T : MonoBehaviour
{
    private static T _instance;
    private static readonly object _lock = new();
    private static bool _applicationIsQuitting;

    public static T Instance
    {
        get
        {
            if (_applicationIsQuitting)
            {
                return null;
            }

            lock (_lock)
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<T>();

                    if (_instance == null)
                    {
                        var go = new GameObject(typeof(T).Name);
                        _instance = go.AddComponent<T>();
                    }
                }
                return _instance;
            }
        }
    }

    protected virtual void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }

        _instance = this as T;
        DontDestroyOnLoad(gameObject);
    }

    private void OnApplicationQuit()
    {
        _applicationIsQuitting = true;
    }
}

// Usage
public class AudioManager : Singleton<AudioManager>
{
    public void PlaySound(string soundName) { }
}
```

---

## Summary Checklist

When designing Unity systems, verify:

- [ ] ScriptableObjects for shared data and configuration
- [ ] Observable variables for reactive UI updates
- [ ] ScriptableObject events for decoupled communication
- [ ] Event channels for system-specific messaging
- [ ] State machines for complex behavior
- [ ] Composition over inheritance
- [ ] Interfaces for component contracts
- [ ] Service locator only for truly global services
- [ ] Command pattern for undo/redo or input buffering
- [ ] Singletons used sparingly and with clear ownership
- [ ] Systems communicate through events, not direct references
