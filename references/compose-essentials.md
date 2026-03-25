# Compose Essentials

Foundational Compose patterns that complement MVI architecture. Consult this when working with Compose APIs directly.

## Three Phases Model

Every frame consists of three phases. Understanding which phase reads state prevents unnecessary recompositions.

1. **Composition** — executes composable functions, evaluates state reads. State reads here trigger recomposition of the entire scope.
2. **Layout** — calculates size and position, runs `measure` and `layout` blocks. Can read state without triggering composition recomposition.
3. **Drawing** — emits draw operations, runs `Canvas` and custom `DrawScope`.

This is why deferred state reads via lambda modifiers work:

```kotlin
// BAD: reads in composition phase, triggers recomposition on every offset change
Box(modifier = Modifier.offset(offsetX.dp, 0.dp))

// GOOD: reads in layout phase, skips composition entirely
Box(modifier = Modifier.offset { IntOffset(offsetX.value.toInt(), 0) })
```

Similarly, `Modifier.graphicsLayer { alpha = animatedAlpha.value }` reads state in the draw phase, avoiding recomposition for visual-only changes.

## State Primitives

### Primitive Specializations

Use type-specific state holders to avoid boxing overhead:

```kotlin
val count = mutableIntStateOf(0)       // no boxing
val progress = mutableFloatStateOf(0f) // no boxing
val enabled = mutableStateOf(true)     // Boolean has no specialization
val name = mutableStateOf("Alice")     // general-purpose
```

**Pitfall:** Using `mutableStateOf<Int>()` instead of `mutableIntStateOf()` causes unnecessary boxing on every read/write.

### SnapshotStateList and SnapshotStateMap

Observable collections that trigger recomposition on structural changes:

```kotlin
val items = remember { mutableStateListOf<Item>() }
items.add(Item(1, "First"))      // triggers recomposition
items[0] = items[0].copy(name = "Updated")  // triggers recomposition
items[0].name = "Updated"        // does NOT trigger recomposition (in-place mutation)
```

In MVI, prefer immutable collections (`ImmutableList`) in state models. `SnapshotStateList` is acceptable for UI-local state only.

### Saver for rememberSaveable

Custom types require explicit `Saver` for `rememberSaveable`:

```kotlin
data class FilterState(val query: String, val category: Int)

val filterSaver = Saver<FilterState, String>(
    save = { "${it.query}:${it.category}" },
    restore = { parts -> FilterState(parts.split(":")[0], parts.split(":")[1].toInt()) }
)

var filter by rememberSaveable(stateSaver = filterSaver) {
    mutableStateOf(FilterState("", 0))
}
```

In MVI, `rememberSaveable` is only for small UI-local state — screen business state belongs in the ViewModel. `rememberSaveable` is multiplatform and works in CMP `commonMain`.

## Side Effects

### LaunchedEffect — Coroutines Scoped to Composition

Launches a coroutine tied to the composable's lifecycle. Cancelled when the key changes or composable leaves composition.

```kotlin
// Key = Unit: runs once when composable enters composition
LaunchedEffect(Unit) { setupOnce() }

// Key = specific value: reruns when value changes
LaunchedEffect(userId) { loadUserData(userId) }

// Multiple keys: reruns if ANY key changes
LaunchedEffect(userId, postId) { loadUserAndPost(userId, postId) }
```

In MVI, `LaunchedEffect` belongs at the route level for collecting UI effects. Do not use it for business logic in leaf composables.

### DisposableEffect — For Cleanup

```kotlin
DisposableEffect(lifecycle) {
    val observer = LifecycleEventObserver { _, event -> /* handle */ }
    lifecycle.addObserver(observer)
    onDispose { lifecycle.removeObserver(observer) }
}
```

Always pair registration with `onDispose` cleanup.

### rememberCoroutineScope — From Event Handlers

```kotlin
val scope = rememberCoroutineScope()
Button(onClick = { scope.launch { fetchData() } }) { Text("Fetch") }
```

In MVI, prefer dispatching events to the ViewModel instead. Use `rememberCoroutineScope` only for UI-local async work (e.g., scroll animation, snackbar).

Use `rememberUpdatedState` to capture latest callback values in long-running effects without restarting them.

`SideEffect { }` runs after every successful composition — use sparingly for stateless synchronization.

`produceState` bridges imperative state sources into Compose state; prefer ViewModel's `StateFlow` in MVI.

### Effect Ordering

Effects execute in declaration order after composition. `SideEffect` runs after every composition, `DisposableEffect` setup runs after composition, `LaunchedEffect` coroutines are scheduled asynchronously.

### collectAsStateWithLifecycle

Use `collectAsStateWithLifecycle()` instead of `collectAsState()` to collect only when the composable is in STARTED state:

```kotlin
val state by viewModel.state.collectAsStateWithLifecycle()
```

This prevents collection during background states and avoids unnecessary work. `collectAsStateWithLifecycle` is available in both Android and Compose Multiplatform via `androidx.lifecycle:lifecycle-runtime-compose`. Verify your project's lifecycle version supports your KMP targets before using it in `commonMain`.

### CollectEffect — Lifecycle-Aware Effect Collection

```kotlin
@Composable
fun <E> CollectEffect(effect: Flow<E>, onEffect: (E) -> Unit) {
    val lifecycleOwner = LocalLifecycleOwner.current
    LaunchedEffect(effect, lifecycleOwner) {
        lifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
            effect.collect { onEffect(it) }
        }
    }
}
```

Collect one-off effects at the route level when STARTED; usage patterns live in [mvi.md](mvi.md).

## Modifier Ordering

Order matters. Modifiers apply left-to-right in the chain:

```kotlin
// Red background wraps padded content
Modifier.background(Color.Red).padding(16.dp).size(100.dp)

// Padding is inside the sized box, then background wraps everything
Modifier.size(100.dp).padding(16.dp).background(Color.Red)
```

### Always accept Modifier parameter

```kotlin
// GOOD: composable accepts modifier for caller customization
@Composable
fun ResultCard(derived: ProductDerived?, modifier: Modifier = Modifier) {
    Card(modifier = modifier) { /* ... */ }
}
```

## Slot Pattern

Accept `@Composable` lambda parameters for flexible, reusable containers:

```kotlin
@Composable
fun SectionCard(
    modifier: Modifier = Modifier,
    title: @Composable () -> Unit,
    content: @Composable () -> Unit,
) {
    Card(modifier = modifier) {
        Column(Modifier.padding(16.dp)) {
            title()
            Spacer(Modifier.height(8.dp))
            content()
        }
    }
}

// Usage
SectionCard(
    title = { Text("Breakdown", style = MaterialTheme.typography.titleMedium) },
    content = { ProductBreakdownContent(derived) },
)
```

Slots accept `@Composable` lambdas, not pre-composed values. This ensures composition is deferred and scope-aware.

## Composable Extraction Guidelines

| Signal | Prefer |
|--------|--------|
| Reused in multiple places, or a single clear visual/behavioral responsibility | Extract |
| Easier to test in isolation, or independent recomposition skipping helps | Extract |
| Single use, trivial wrapper around one `Text`/`Icon`, or more parameters than inline clarity | Don't extract |
| Tightly coupled logic that reads clearer inline | Don't extract |

## CompositionLocal

Provides implicit parameters without threading through the hierarchy.

### When to use

- Theming (`MaterialTheme`, `Colors`, `Typography`)
- Platform integration (`LocalDensity`, `LocalLifecycleOwner`; `LocalContext` on Android, `LocalPlatformContext` in CMP)
- Infrequently changing cross-cutting concerns

### When NOT to use

- Frequently changing values (causes widespread recomposition)
- Values only 1-2 levels deep (pass directly)
- Dependencies that should use DI

```kotlin
// GOOD: theme/density accessed via CompositionLocal
val density = LocalDensity.current

// BAD: custom CompositionLocal for a value only used in one subtree
val LocalTitle = staticCompositionLocalOf<String> { "" }
```

In MVI, avoid custom CompositionLocals for feature state. State flows through the ViewModel → route → screen → leaves via explicit parameters.
