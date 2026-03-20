# Compose Essentials

Foundational Compose patterns that complement MVI architecture. Consult this when working with Compose APIs directly.

## Table of Contents

- [Three Phases Model](#three-phases-model)
- [State Primitives](#state-primitives)
- [Side Effects](#side-effects)
- [Modifier Ordering](#modifier-ordering)
- [Slot Pattern](#slot-pattern)
- [Composable Extraction Guidelines](#composable-extraction-guidelines)
- [CompositionLocal](#compositionlocal)

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

**Pitfall — wrong key selection:**

```kotlin
// BAD: won't re-run when query changes
LaunchedEffect(Unit) { viewModel.search(query) }

// GOOD: re-runs when query changes
LaunchedEffect(query) { viewModel.search(query) }
```

In MVI, `LaunchedEffect` belongs at the route level for collecting UI effects. Do not use it for business logic in leaf composables.

### DisposableEffect — For Cleanup

Runs after composition and requires an `onDispose` cleanup block:

```kotlin
DisposableEffect(lifecycle) {
    val observer = LifecycleEventObserver { _, event -> /* handle */ }
    lifecycle.addObserver(observer)
    onDispose { lifecycle.removeObserver(observer) }
}
```

**Rule:** Always pair resource registration with `onDispose` cleanup.

### rememberCoroutineScope — From Event Handlers

Provides a coroutine scope for launching work from click handlers and gestures:

```kotlin
val scope = rememberCoroutineScope()
Button(onClick = { scope.launch { fetchData() } }) { Text("Fetch") }
```

In MVI, prefer dispatching events to the ViewModel instead. Use `rememberCoroutineScope` only for UI-local async work (e.g., scroll animation, snackbar).

### rememberUpdatedState — Capturing Latest Values

For long-running effects that need the latest value without restarting:

```kotlin
// BAD: effect restarts when callback changes
LaunchedEffect(onSuccess) { val result = expensiveOp(); onSuccess(result) }

// GOOD: captures latest without restarting
val updatedOnSuccess = rememberUpdatedState(onSuccess)
LaunchedEffect(Unit) { val result = expensiveOp(); updatedOnSuccess.value(result) }
```

### SideEffect — After Every Composition

Runs after every successful composition. No keys, no cleanup:

```kotlin
SideEffect { analytics.logScreenView(screenName) }
```

Use sparingly — only for simple, stateless synchronization.

### produceState — Bridging External Sources

Converts imperative state sources into Compose state:

```kotlin
val user by produceState<User?>(initialValue = null, userId) {
    value = fetchUser(userId)
}
```

In MVI, the ViewModel already bridges external data via `StateFlow`. Use `produceState` only at route-edge integration points.

### Effect Ordering

Effects execute in declaration order after composition. `SideEffect` runs after every composition, `DisposableEffect` setup runs after composition, `LaunchedEffect` coroutines are scheduled asynchronously.

### collectAsStateWithLifecycle

Use `collectAsStateWithLifecycle()` instead of `collectAsState()` to collect only when the composable is in STARTED state:

```kotlin
val state by viewModel.state.collectAsStateWithLifecycle()
```

This prevents collection during background states and avoids unnecessary work. `collectAsStateWithLifecycle` is available in both Android and Compose Multiplatform via `androidx.lifecycle:lifecycle-runtime-compose`. Verify your project's lifecycle version supports your KMP targets before using it in `commonMain`.

### CollectEffect — Lifecycle-Aware Effect Collection

A reusable composable for collecting one-off effects (navigation, snackbar, haptics) from a `Channel` or `Flow` in a lifecycle-aware manner. Effects are only processed when the UI is at least STARTED. `LocalLifecycleOwner` and `repeatOnLifecycle` are multiplatform. This works in both Android and CMP `commonMain`:

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

Usage at the route level:

```kotlin
@Composable
fun EstimateRoute(viewModel: EstimateViewModel) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    CollectEffect(viewModel.effect) { effect ->
        when (effect) {
            is EstimateEffect.ShowMessage -> snackbarHostState.showSnackbar(effect.message)
            is EstimateEffect.NavigateBack -> navigator.goBack()
        }
    }

    EstimateScreen(state = state, onEvent = viewModel::onEvent)
}
```

This keeps effect collection consistent across all routes without a base class — just call `CollectEffect` wherever you need it. Note that `collectAsStateWithLifecycle()` matches the recommendation above and `viewModel.effect` uses the singular naming convention from the ViewModel pattern in [clean-code.md](clean-code.md).

## Modifier Ordering

Order matters. Modifiers apply left-to-right in the chain:

```kotlin
// Red background wraps padded content
Modifier.background(Color.Red).padding(16.dp).size(100.dp)

// Padding is inside the sized box, then background wraps everything
Modifier.size(100.dp).padding(16.dp).background(Color.Red)
```

### Common patterns

```kotlin
// Clip before background to keep background inside the shape
Modifier.clip(RoundedCornerShape(8.dp)).background(Color.Blue)

// fillMaxWidth before padding for full-width background
Modifier.fillMaxWidth().background(Color.Blue).padding(16.dp)

// Conditional modifiers with then()
Modifier.padding(16.dp).then(if (isSelected) Modifier.background(Color.Blue) else Modifier)
```

### Modifier.Node vs composed

New custom modifiers should use `Modifier.Node` (more efficient, no composition scope). `Modifier.composed` is deprecated but still supported.

### graphicsLayer for Animations

`graphicsLayer` applies transformations at the rendering level without recomposition:

```kotlin
Box(modifier = Modifier.graphicsLayer(
    scaleX = 1.2f, rotationZ = 45f, alpha = 0.8f
))
```

Use for: scale, rotation, translation, alpha animations. Much more efficient than animating state that triggers recomposition.

### Always accept Modifier parameter

```kotlin
// GOOD: composable accepts modifier for caller customization
@Composable
fun ResultCard(derived: EstimateDerived?, modifier: Modifier = Modifier) {
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
    content = { EstimateBreakdownContent(derived) },
)
```

Slots accept `@Composable` lambdas, not pre-composed values. This ensures composition is deferred and scope-aware.

## Composable Extraction Guidelines

### Extract when

- Reused in multiple places
- Single responsibility — handles one visual/behavioral concern
- Easier to test as an isolated unit
- Enables independent recomposition skipping

### Don't extract when

- Single use with no reuse potential
- Trivial wrapper around a single `Text` or `Icon`
- Would require passing more parameters than the inline code
- Tightly coupled logic that's clearer inline

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
