---
name: unity-performance
description: Unity performance optimization patterns. Use when optimizing Unity game code.
---

# Unity Performance Patterns

## Core Principle

**Measure before optimizing.** Use the Profiler to identify actual bottlenecks. Focus on reducing GC allocations, caching references, and using object pooling for frequently spawned objects.

---

## Profiling First

### Unity Profiler Usage

```csharp
// ✅ Use profiler markers to identify hotspots
using Unity.Profiling;

public class GameSystem : MonoBehaviour
{
    private static readonly ProfilerMarker _updateMarker =
        new ProfilerMarker("GameSystem.Update");

    private static readonly ProfilerMarker _physicsMarker =
        new ProfilerMarker("GameSystem.Physics");

    private void Update()
    {
        using (_updateMarker.Auto())
        {
            // Update logic - shows up in Profiler
        }
    }

    private void FixedUpdate()
    {
        using (_physicsMarker.Auto())
        {
            // Physics logic
        }
    }
}
```

### Conditional Profiling

```csharp
using System.Diagnostics;

public class PerformanceCritical : MonoBehaviour
{
    // Only in development builds
    [Conditional("UNITY_EDITOR"), Conditional("DEVELOPMENT_BUILD")]
    private void ProfileThis(string section)
    {
        UnityEngine.Profiling.Profiler.BeginSample(section);
    }

    [Conditional("UNITY_EDITOR"), Conditional("DEVELOPMENT_BUILD")]
    private void EndProfile()
    {
        UnityEngine.Profiling.Profiler.EndSample();
    }
}
```

---

## Garbage Collection Avoidance

### Avoid Allocations in Update

```csharp
// ❌ WRONG - Allocations every frame
public class BadExample : MonoBehaviour
{
    private void Update()
    {
        var enemies = FindObjectsOfType<Enemy>();        // Array allocation
        var message = $"Found {enemies.Length} enemies"; // String allocation
        var positions = new List<Vector3>();             // List allocation

        foreach (var enemy in enemies)
        {
            positions.Add(enemy.transform.position);     // May resize
        }
    }
}

// ✅ CORRECT - Pre-allocated, cached
public class GoodExample : MonoBehaviour
{
    private readonly List<Enemy> _enemiesCache = new(100);
    private readonly List<Vector3> _positionsCache = new(100);
    private readonly StringBuilder _messageBuilder = new(100);

    private void Update()
    {
        // Reuse cached list
        _enemiesCache.Clear();
        FindObjectsOfType(_enemiesCache);  // Fills existing list

        _positionsCache.Clear();
        foreach (var enemy in _enemiesCache)
        {
            _positionsCache.Add(enemy.transform.position);
        }

        // Reuse StringBuilder
        _messageBuilder.Clear();
        _messageBuilder.Append("Found ");
        _messageBuilder.Append(_enemiesCache.Count);
        _messageBuilder.Append(" enemies");
    }
}
```

### String Optimization

```csharp
// ❌ WRONG - String concatenation in loops
public class BadStrings : MonoBehaviour
{
    private void Update()
    {
        string result = "";
        for (int i = 0; i < 100; i++)
        {
            result += i.ToString();  // Many allocations!
        }
    }
}

// ✅ CORRECT - StringBuilder for building strings
public class GoodStrings : MonoBehaviour
{
    private readonly StringBuilder _sb = new(256);

    private void BuildString()
    {
        _sb.Clear();
        for (int i = 0; i < 100; i++)
        {
            _sb.Append(i);
        }
        var result = _sb.ToString();  // Single allocation
    }
}

// ✅ CORRECT - Cache frequently used strings
public class CachedStrings : MonoBehaviour
{
    // Cache string keys
    private static readonly int AnimationHash = Animator.StringToHash("Running");
    private static readonly string HealthFormat = "Health: {0:F0}";

    private void UpdateUI(float health)
    {
        // Use cached format string
        _healthText.text = string.Format(HealthFormat, health);
    }

    private void PlayAnimation(Animator animator)
    {
        animator.SetBool(AnimationHash, true);  // Use hash instead of string
    }
}
```

### Boxing Avoidance

```csharp
// ❌ WRONG - Boxing value types
public class BadBoxing : MonoBehaviour
{
    private void Update()
    {
        object boxed = 42;              // Boxing
        Debug.Log("Value: " + 42);      // Boxing in string concat
        var list = new ArrayList();
        list.Add(42);                   // Boxing
    }
}

// ✅ CORRECT - Avoid boxing
public class GoodBoxing : MonoBehaviour
{
    private void Update()
    {
        int value = 42;
        Debug.Log($"Value: {value}");   // Interpolation (still allocates, use sparingly)
        var list = new List<int>();
        list.Add(42);                   // No boxing with generic list
    }
}
```

### LINQ Avoidance in Hot Paths

```csharp
// ❌ WRONG - LINQ allocates iterators
public class BadLinq : MonoBehaviour
{
    private List<Enemy> _enemies = new();

    private void Update()
    {
        // Each LINQ operation allocates!
        var activeEnemies = _enemies
            .Where(e => e.IsActive)
            .OrderBy(e => e.Distance)
            .Take(10)
            .ToList();  // Final allocation
    }
}

// ✅ CORRECT - Manual iteration for hot paths
public class GoodLinq : MonoBehaviour
{
    private readonly List<Enemy> _enemies = new();
    private readonly List<Enemy> _activeCache = new(100);

    private void Update()
    {
        _activeCache.Clear();

        // Manual filtering - no allocation
        foreach (var enemy in _enemies)
        {
            if (enemy.IsActive)
            {
                _activeCache.Add(enemy);
            }
        }

        // Sort in place - no allocation
        _activeCache.Sort((a, b) => a.Distance.CompareTo(b.Distance));
    }
}
```

---

## Object Pooling

### Simple Object Pool

```csharp
// ✅ Generic object pool
public class ObjectPool<T> where T : class, new()
{
    private readonly Stack<T> _pool = new();
    private readonly Func<T> _createFunc;
    private readonly Action<T> _onGet;
    private readonly Action<T> _onRelease;

    public ObjectPool(
        Func<T> createFunc = null,
        Action<T> onGet = null,
        Action<T> onRelease = null,
        int initialSize = 10)
    {
        _createFunc = createFunc ?? (() => new T());
        _onGet = onGet;
        _onRelease = onRelease;

        for (int i = 0; i < initialSize; i++)
        {
            _pool.Push(_createFunc());
        }
    }

    public T Get()
    {
        var item = _pool.Count > 0 ? _pool.Pop() : _createFunc();
        _onGet?.Invoke(item);
        return item;
    }

    public void Release(T item)
    {
        _onRelease?.Invoke(item);
        _pool.Push(item);
    }
}

// Usage
var bulletPool = new ObjectPool<Bullet>(
    createFunc: () => new Bullet(),
    onGet: b => b.Reset(),
    onRelease: b => b.Deactivate(),
    initialSize: 100
);

var bullet = bulletPool.Get();
// Use bullet...
bulletPool.Release(bullet);
```

### MonoBehaviour Pool

```csharp
// ✅ Pool for GameObjects
public class GameObjectPool : MonoBehaviour
{
    [SerializeField] private GameObject _prefab;
    [SerializeField] private int _initialSize = 20;

    private readonly Queue<GameObject> _pool = new();

    private void Awake()
    {
        for (int i = 0; i < _initialSize; i++)
        {
            CreateInstance();
        }
    }

    private GameObject CreateInstance()
    {
        var instance = Instantiate(_prefab, transform);
        instance.SetActive(false);
        _pool.Enqueue(instance);
        return instance;
    }

    public GameObject Get(Vector3 position, Quaternion rotation)
    {
        var instance = _pool.Count > 0 ? _pool.Dequeue() : CreateInstance();

        instance.transform.SetPositionAndRotation(position, rotation);
        instance.SetActive(true);

        if (instance.TryGetComponent<IPoolable>(out var poolable))
        {
            poolable.OnSpawn();
        }

        return instance;
    }

    public void Release(GameObject instance)
    {
        if (instance.TryGetComponent<IPoolable>(out var poolable))
        {
            poolable.OnDespawn();
        }

        instance.SetActive(false);
        instance.transform.SetParent(transform);
        _pool.Enqueue(instance);
    }
}

public interface IPoolable
{
    void OnSpawn();
    void OnDespawn();
}

// Example poolable object
public class Bullet : MonoBehaviour, IPoolable
{
    [SerializeField] private float _lifetime = 5f;
    private GameObjectPool _pool;

    public void Initialize(GameObjectPool pool)
    {
        _pool = pool;
    }

    public void OnSpawn()
    {
        StartCoroutine(ReturnAfterDelay());
    }

    public void OnDespawn()
    {
        StopAllCoroutines();
    }

    private IEnumerator ReturnAfterDelay()
    {
        yield return new WaitForSeconds(_lifetime);
        _pool.Release(gameObject);
    }
}
```

### Unity 2021+ ObjectPool

```csharp
using UnityEngine.Pool;

// ✅ Use Unity's built-in ObjectPool
public class ProjectileSpawner : MonoBehaviour
{
    [SerializeField] private Projectile _prefab;

    private ObjectPool<Projectile> _pool;

    private void Awake()
    {
        _pool = new ObjectPool<Projectile>(
            createFunc: () => Instantiate(_prefab),
            actionOnGet: p => p.gameObject.SetActive(true),
            actionOnRelease: p => p.gameObject.SetActive(false),
            actionOnDestroy: p => Destroy(p.gameObject),
            collectionCheck: true,
            defaultCapacity: 20,
            maxSize: 100
        );
    }

    public Projectile Spawn(Vector3 position)
    {
        var projectile = _pool.Get();
        projectile.transform.position = position;
        projectile.Initialize(_pool);
        return projectile;
    }
}

public class Projectile : MonoBehaviour
{
    private IObjectPool<Projectile> _pool;

    public void Initialize(IObjectPool<Projectile> pool)
    {
        _pool = pool;
    }

    public void ReturnToPool()
    {
        _pool.Release(this);
    }
}
```

---

## Physics Optimization

### Layer-Based Collision

```csharp
// ✅ Use layer masks for efficient physics queries
public class RaycastOptimization : MonoBehaviour
{
    [SerializeField] private LayerMask _enemyLayer;
    [SerializeField] private LayerMask _groundLayer;

    // Pre-allocate arrays for non-alloc methods
    private readonly RaycastHit[] _hits = new RaycastHit[10];
    private readonly Collider[] _colliders = new Collider[20];

    private void Update()
    {
        // ❌ WRONG - Allocating array
        var hits = Physics.RaycastAll(transform.position, Vector3.forward);

        // ✅ CORRECT - NonAlloc version
        int hitCount = Physics.RaycastNonAlloc(
            transform.position,
            Vector3.forward,
            _hits,
            100f,
            _enemyLayer
        );

        for (int i = 0; i < hitCount; i++)
        {
            ProcessHit(_hits[i]);
        }
    }

    private void CheckOverlap()
    {
        // ✅ NonAlloc overlap
        int count = Physics.OverlapSphereNonAlloc(
            transform.position,
            5f,
            _colliders,
            _enemyLayer
        );

        for (int i = 0; i < count; i++)
        {
            ProcessCollider(_colliders[i]);
        }
    }
}
```

### Physics Settings

```csharp
// Project Settings > Physics recommendations:

// 1. Set appropriate layer collision matrix
// - Disable collisions between layers that never interact

// 2. Use appropriate collision detection mode
// - Discrete: Default, fastest
// - Continuous: For fast-moving objects
// - Continuous Dynamic: For fast objects that hit other fast objects

// 3. Reduce fixed timestep if possible
// - Default 0.02 (50 Hz)
// - Consider 0.04 (25 Hz) for less physics-heavy games

// ✅ Set Rigidbody settings appropriately
public class OptimizedRigidbody : MonoBehaviour
{
    private void Awake()
    {
        var rb = GetComponent<Rigidbody>();

        // Sleep threshold - objects sleep faster
        rb.sleepThreshold = 0.1f;

        // Interpolation only if camera follows
        rb.interpolation = RigidbodyInterpolation.None;

        // Collision detection based on speed
        rb.collisionDetectionMode = CollisionDetectionMode.Discrete;
    }
}
```

---

## Rendering Optimization

### Batching Awareness

```csharp
// ✅ Static batching - mark non-moving objects
// In Inspector: Check "Static" for immovable objects

// ✅ Dynamic batching requirements:
// - Same material instance
// - Under 300 vertices
// - No multi-pass shaders

// ✅ GPU Instancing for many identical objects
public class InstancedRenderer : MonoBehaviour
{
    [SerializeField] private Mesh _mesh;
    [SerializeField] private Material _material;  // Must have GPU Instancing enabled

    private Matrix4x4[] _matrices = new Matrix4x4[1023];  // Max per batch
    private int _instanceCount;

    private void Update()
    {
        if (_instanceCount > 0)
        {
            Graphics.DrawMeshInstanced(_mesh, 0, _material, _matrices, _instanceCount);
        }
    }
}
```

### LOD and Culling

```csharp
// ✅ Manual LOD switching
public class ManualLOD : MonoBehaviour
{
    [SerializeField] private Mesh[] _lodMeshes;
    [SerializeField] private float[] _lodDistances;

    private MeshFilter _meshFilter;
    private Transform _cameraTransform;

    private void Awake()
    {
        _meshFilter = GetComponent<MeshFilter>();
        _cameraTransform = Camera.main.transform;
    }

    private void Update()
    {
        float distance = Vector3.Distance(transform.position, _cameraTransform.position);

        for (int i = 0; i < _lodDistances.Length; i++)
        {
            if (distance < _lodDistances[i])
            {
                _meshFilter.mesh = _lodMeshes[i];
                return;
            }
        }
    }
}

// ✅ Occlusion culling awareness
// - Bake occlusion data: Window > Rendering > Occlusion Culling
// - Mark occluders (large static objects)
// - Mark occludees (can be hidden)
```

### Camera Optimization

```csharp
public class CameraOptimization : MonoBehaviour
{
    [SerializeField] private Camera _mainCamera;

    private void Awake()
    {
        // Reduce far clip plane
        _mainCamera.farClipPlane = 500f;  // Only what's needed

        // Use culling mask
        _mainCamera.cullingMask = ~(1 << LayerMask.NameToLayer("Invisible"));
    }
}
```

---

## Update Optimization

### Spread Updates Over Frames

```csharp
// ✅ Don't update everything every frame
public class AIManager : MonoBehaviour
{
    [SerializeField] private List<Enemy> _enemies = new();
    private int _currentIndex;

    private void Update()
    {
        // Update subset each frame
        int updatesThisFrame = Mathf.Max(1, _enemies.Count / 10);

        for (int i = 0; i < updatesThisFrame; i++)
        {
            if (_enemies.Count == 0) break;

            _currentIndex = (_currentIndex + 1) % _enemies.Count;
            _enemies[_currentIndex].UpdateAI();
        }
    }
}
```

### Use Jobs for Heavy Work

```csharp
using Unity.Jobs;
using Unity.Collections;
using Unity.Burst;

// ✅ Burst-compiled job for heavy math
[BurstCompile]
public struct CalculateDistancesJob : IJobParallelFor
{
    [ReadOnly] public NativeArray<Vector3> Positions;
    public Vector3 TargetPosition;
    public NativeArray<float> Distances;

    public void Execute(int index)
    {
        Distances[index] = Vector3.Distance(Positions[index], TargetPosition);
    }
}

public class DistanceCalculator : MonoBehaviour
{
    private NativeArray<Vector3> _positions;
    private NativeArray<float> _distances;

    public void CalculateDistances(Vector3[] positions, Vector3 target)
    {
        _positions = new NativeArray<Vector3>(positions, Allocator.TempJob);
        _distances = new NativeArray<float>(positions.Length, Allocator.TempJob);

        var job = new CalculateDistancesJob
        {
            Positions = _positions,
            TargetPosition = target,
            Distances = _distances
        };

        var handle = job.Schedule(positions.Length, 64);
        handle.Complete();

        // Use results...

        _positions.Dispose();
        _distances.Dispose();
    }
}
```

---

## Memory Management

### Texture and Asset Management

```csharp
// ✅ Unload unused assets
public class SceneTransition : MonoBehaviour
{
    public async void LoadScene(string sceneName)
    {
        // Unload current scene assets
        await Resources.UnloadUnusedAssets();

        // Force garbage collection (do sparingly, causes frame spike)
        System.GC.Collect();

        // Load new scene
        await SceneManager.LoadSceneAsync(sceneName);
    }
}

// ✅ Use addressables for large assets
// - Assets can be loaded/unloaded on demand
// - Better memory control
// - Async loading
```

### Struct vs Class

```csharp
// ✅ Use structs for small, immutable data (no GC)
public struct DamageInfo
{
    public float Amount;
    public DamageType Type;
    public Vector3 HitPoint;
}

// ✅ Use ref returns to avoid copying large structs
public ref readonly Vector3 GetPosition(int index)
{
    return ref _positions[index];
}

// ❌ WRONG - Boxing struct in generic
void ProcessDamage(object damage) { }  // Boxes DamageInfo

// ✅ CORRECT - Generic constraint
void ProcessDamage<T>(T damage) where T : struct { }
```

---

## Summary Checklist

When optimizing Unity games, verify:

- [ ] Profiler used to identify actual bottlenecks
- [ ] No allocations in Update/FixedUpdate
- [ ] StringBuilder used for string building
- [ ] Collections pre-allocated and reused
- [ ] Animator parameters use hashes, not strings
- [ ] Object pooling for frequently spawned objects
- [ ] Physics uses NonAlloc methods
- [ ] Layer collision matrix optimized
- [ ] Cameras have appropriate culling masks
- [ ] Static batching for non-moving objects
- [ ] Updates spread across frames for heavy systems
- [ ] Jobs/Burst used for CPU-intensive work
- [ ] No LINQ in hot paths
- [ ] Structs used for small value types
