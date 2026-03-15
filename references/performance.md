# Performance & Recomposition

## Table of Contents

- [Main Performance Mistakes](#main-performance-mistakes)
- [Text Input Performance](#text-input-performance)
- [Compiler and Build Optimizations](#compiler-and-build-optimizations)
- [API Decision Table](#api-decision-table)
- [Least Recomposition Rules](#least-recomposition-rules)
- [Diagnostic Checklist](#diagnostic-checklist)
- [Code Examples](#code-examples)

## Three Phases

Every Compose frame executes three phases. State reads in each phase only trigger work for that phase and later ones:

1. **Composition** — executes composable functions, evaluates state reads. Reads here trigger recomposition.
2. **Layout** — `measure` and `layout` blocks. State reads here skip composition. Use `Modifier.offset { }` (lambda) instead of `Modifier.offset()`.
3. **Drawing** — `Canvas`, `drawBehind`, `graphicsLayer`. Reads here skip composition and layout.

Understanding this is key: moving state reads from Composition to Layout/Drawing eliminates recomposition entirely for those reads.

## Primitive State Specializations

Use type-specific state holders to avoid boxing:

```kotlin
val count = mutableIntStateOf(0)       // no boxing
val progress = mutableFloatStateOf(0f) // no boxing
val name = mutableStateOf("Alice")     // general-purpose (no primitive specialization for String/Boolean)
```

`mutableStateOf<Int>()` boxes on every read/write. Use `mutableIntStateOf()` and `mutableFloatStateOf()` instead.

## Main Performance Mistakes

### 1. Unstable Parameters

Typical causes: `MutableList`, `MutableMap`, `SnapshotStateList` in screen state, lambdas stored inside state models, anonymous objects created during render, platform objects in state, plain lists rebuilt unnecessarily.

**Default:** use immutable data classes and immutable collections for state.

### 2. Broad State Observation

Classic MVI mistake: parent reads whole state, passes whole state to many children, any field change ripples through the tree.

**Default:** collect once at route, slice aggressively for leaves.

### 3. Large Immutable State Passed Everywhere

Large state objects are not automatically bad. **Broad reads are bad.** A `copy()` is usually shallow. The expensive part is rebuilding unstable collections, emitting pointless new instances, and making many nodes observe fields they do not use.

### 4. Unnecessary Callback Recreation

Usually small. Sometimes hot. Matters in large lazy lists, deeply nested repeated rows, and high-frequency item updates.

### 5. Expensive Calculations During Composition

Common MVI error: parse numbers in UI, compute totals in UI, filter/sort large lists in UI, build expensive formatted strings in UI on every render. Move them upstream.

### 6. `remember` Misuse

Bad reasons: hide wrong architecture, cache business state, avoid fixing state shape, memoize trivial expressions.

Good reasons: local state that survives recomposition, expensive local object creation, callback adaptation in hot paths, scroll/snackbar/focus/interaction objects.

### 7. `derivedStateOf` Misuse

Bad: wrapping cheap expressions because it "sounds performant".

Good: derived value depends on rapidly changing Compose state, downstream should update only when the derived boolean/value changes.

### 8. `rememberSaveable` Misuse

Bad: entire screen state, repository/domain objects, huge graphs, anything that belongs in the ViewModel.

Good: tiny UI-local values that should survive recreation.

### 9. State Reads Too High in the Tree

Reading `LazyListState`, keyboard state, animation state, or text input state high in the tree causes broad recomposition. Read close to use.

### 10. List Recomposition Issues

Bad defaults: missing keys, index-based identity, unstable item models, inline filters/maps/sorts inside `items`.

### 11. Reducer Emits Excessive Updates

Bad: emit on every intent even when state didn't change, rebuild lists on every keystroke, reformat everything on every small field edit, overwrite content with same content.

### 12. Ephemeral Visual State in Global Screen State

Bad examples: pulsing animation phase, local row expanded purely for a nice transition, temporary tooltip visibility, current shimmer alpha.

### 13. Equality Pitfalls in UI Models

Bad: lambdas in data classes, random IDs generated during reduction, timestamps updated for no reason, mutable collections in data classes.

### 14. Abusing `@Immutable` / `@Stable`

Use them to **describe truth**, not to silence the compiler. `@Immutable` for truly immutable models, `@Stable` rare in app code — only when the contract is correct. Do not lie.

## Text Input Performance

### The Form Input Dilemma

Forms with 25+ fields present a unique challenge in MVI. If every keystroke emits an event that forces a full state copy and full re-render, text input will stutter.

**Solutions:**

1. **Use `TextFieldState` / `BasicTextField2`** — decouple the high-frequency typing buffer from the slower global MVI reducer loop. The text field manages its own composition internally, and only syncs to the ViewModel on meaningful events (blur, submit, debounced pause).

2. **Group related fields into nested data classes** — e.g., `val contactInfo: ContactState` within root state. Update that specific slice to prevent full-screen state copies on every keystroke.

3. **Isolate text fields in their own read scopes** — break the composable so each field only reads the state it needs.

### Deferred State Reads

Use lambda modifiers to read state during Layout or Draw phases, skipping the Composition phase entirely:

```kotlin
Modifier.offset { IntOffset(scrollOffset, 0) }
```

This avoids triggering recomposition when the value changes — the layout or draw phase handles the update directly.

## Compiler and Build Optimizations

### Strong Skipping Mode

Enable Strong Skipping via compiler flags. This allows composables with unstable parameters to skip recomposition based on instance equality (`===`), significantly reducing unnecessary recompositions.

### Stability Configuration Files

Use a `stability_config.conf` file to mark external multi-module classes (network DTOs, standard library types) as stable to the Compose compiler:

```
// stability_config.conf
com.example.network.dto.*
kotlinx.datetime.Instant
```

### Compose Compiler Metrics

Regularly run Compose Compiler Metrics to audit `restartable` and `skippable` characteristics of composables. This reveals which composables are not skipping when they should be.

## API Decision Table

| API | Use it for | Do not use it for | Strict-MVI default |
|---|---|---|---|
| `remember` | local objects/state across recompositions | business state, repo results, derived domain data | `LazyListState`, `SnackbarHostState`, `FocusRequester`, hot callback adapter |
| `rememberSaveable` | small UI-local state needing restoration | whole screen state, large graphs, domain objects | expansion toggle, selected local tab, ephemeral filter query |
| `derivedStateOf` | reducing downstream updates from frequently changing Compose state | cheap string concatenation, reducer-owned derivations | scroll threshold, "show fab after index > 2" |
| `key` | preserving identity in dynamic children/lists | hiding bad state models | always key list rows by stable ID |
| `LaunchedEffect` | collecting UI effects, startup event, one-shot route work | screen business logic in leaves | route-level effect collection |
| `DisposableEffect` | register/unregister listeners with cleanup | long-running business jobs | system/UI listener binding |
| `produceState` | bridging external async/callback source to local Compose state | replacing a real ViewModel | route-edge integration only |
| `snapshotFlow` | turning Compose state reads into `Flow` operators | normal state rendering | analytics, scroll threshold collection, throttle/debounce at route edge |
| `collectAsState` | collect `StateFlow` into Compose | collecting everywhere in the tree | route-level collection default |
| lifecycle-aware collection | Lifecycle host integration (multiplatform since lifecycle 2.8+) | common leaf components | route/host entry point |
| stable callbacks | hot repeated UI paths | every single callback everywhere | optimize repeated rows and hot render paths |

## Least Recomposition Rules

1. Collect ViewModel state once at the route by default
2. Pass only the props a child actually renders
3. Do not pass whole screen state to reusable leaves
4. Keep raw text input separate from parsed/derived values
5. Run parsing/validation/calculation upstream, not in composition
6. Keep list item models immutable and keyed by stable ID
7. Do not store lambdas inside state models
8. Read `LazyListState`, animation state, and focus state close to use
9. Keep visual-only state local
10. Return the same state instance when nothing semantically changed
11. Do not rebuild whole lists for unrelated field edits
12. Use `derivedStateOf` only for fast-changing Compose state with coarse derived output
13. Use `rememberSaveable` only for small local UI values
14. Stabilize repeated-row callbacks only where hot
15. Profile before reaching for exotic abstractions
16. Isolate text field updates — use `TextFieldState` / `BasicTextField2` to decouple typing from the MVI loop
17. Enable Strong Skipping Mode via compiler flags
18. Defer state reads using lambda modifiers (`Modifier.offset { }`) to skip composition phase
19. Use `stability_config.conf` for external classes the compiler cannot infer as stable
20. Audit with Compose Compiler Metrics regularly

## Diagnostic Checklist

Use this in review or profiling:

- Does this composable read more state than it renders?
- Is any expensive parsing or formatting happening in composition?
- Is a list missing stable keys?
- Are item models immutable?
- Are callbacks recreated inside every list item?
- Is a reducer emitting identical states?
- Is a refresh wiping existing content?
- Is visual-only state in the global ViewModel state?
- Are lambdas or mutable collections embedded in state?
- Is `derivedStateOf` solving a measured problem or decorating cheap code?
- Is `rememberSaveable` holding business state that belongs in the ViewModel?
- Are compiler stability reports or inspector data showing unstable models?

## Code Examples

### BAD: calculating derived results in a composable

```kotlin
@Composable
fun EstimateResult(state: EstimateState) {
    val area = state.input.areaText.toDoubleOrNull() ?: 0.0
    val materialRate = state.input.materialRateText.toDoubleOrNull() ?: 0.0
    val laborRate = state.input.laborRateText.toDoubleOrNull() ?: 0.0
    val subtotal = (area * materialRate) + (area * laborRate)
    Text("Subtotal: $subtotal")
}
```

### GOOD: derive upstream

```kotlin
@Composable
fun EstimateResult(derived: EstimateDerived?) {
    Text(text = derived?.subtotal?.toString() ?: "—")
}
```

### BAD: entire screen subtree depends on full state

```kotlin
@Composable
fun EstimateScreen(state: EstimateState, onEvent: (EstimateEvent) -> Unit) {
    Column {
        Header(state, onEvent)
        EstimateForm(state, onEvent)
        ResultCard(state, onEvent)
        HistoryList(state, onEvent)
    }
}
```

### GOOD: narrow state reads

```kotlin
@Composable
fun EstimateScreen(state: EstimateState, onEvent: (EstimateEvent) -> Unit) {
    Header(title = "Estimator")
    EstimateForm(
        input = state.input,
        validation = state.validation,
        enabled = !state.isRefreshingQuote,
        onAreaChanged = { onEvent(EstimateEvent.FieldChanged(EstimateField.Area, it)) },
        onSubmit = { onEvent(EstimateEvent.SubmitClicked) },
    )
    ResultCard(derived = state.derived, quote = state.quote, isRefreshing = state.isRefreshingQuote)
}
```

### BAD: unstable list items

```kotlin
data class HistoryRowState(
    val id: String,
    val title: String,
    val tags: MutableList<String>,
    val onClick: () -> Unit,
)
```

### GOOD: immutable stable list models

```kotlin
@Immutable
data class HistoryRowUi(val id: String, val title: String, val subtitle: String)

@Immutable
data class HistoryListUi(val items: ImmutableList<HistoryRowUi> = persistentListOf())
```

### GOOD: list keys

```kotlin
@Composable
fun HistoryList(items: ImmutableList<HistoryRowUi>, onOpen: (String) -> Unit) {
    LazyColumn {
        items(items = items, key = { it.id }) { item ->
            HistoryRow(item = item, onOpen = onOpen)
        }
    }
}
```

### GOOD: event lambda stability strategy

```kotlin
@Composable
private fun HistoryRow(item: HistoryRowUi, onOpen: (String) -> Unit) {
    val onClick = remember(item.id, onOpen) { { onOpen(item.id) } }
    ListItem(
        headlineContent = { Text(item.title) },
        supportingContent = { Text(item.subtitle) },
        modifier = Modifier.clickable(onClick = onClick),
    )
}
```

### GOOD: correct `derivedStateOf`

```kotlin
@Composable
fun HistoryRoute() {
    val listState = rememberLazyListState()
    val showScrollToTop by remember { derivedStateOf { listState.firstVisibleItemIndex > 2 } }
    Box {
        HistoryList(items = persistentListOf(), onOpen = {})
        AnimatedVisibility(visible = showScrollToTop) {
            FloatingActionButton(onClick = { }) { Text("Top") }
        }
    }
}
```

### BAD: unnecessary `derivedStateOf`

```kotlin
@Composable
fun SubmitButton(canSubmit: Boolean) {
    val text by remember { derivedStateOf { if (canSubmit) "Submit" else "Fix errors" } }
    Button(onClick = {}, enabled = canSubmit) { Text(text) }
}
```

Just write: `Text(if (canSubmit) "Submit" else "Fix errors")`

### BAD: text field row depends on whole form state

```kotlin
@Composable
fun AreaField(state: EstimateState, onEvent: (EstimateEvent) -> Unit) {
    OutlinedTextField(
        value = state.input.areaText,
        onValueChange = { onEvent(EstimateEvent.FieldChanged(EstimateField.Area, it)) },
        isError = state.validation.area != null,
    )
}
```

### GOOD: text field depends only on its own props

```kotlin
@Composable
fun AreaField(value: String, error: FieldError?, onValueChange: (String) -> Unit) {
    OutlinedTextField(value = value, onValueChange = onValueChange, isError = error != null, label = { Text("Area") })
}
```

### BAD: reducer emits no-op states

```kotlin
private fun onAreaEdited(raw: String) {
    _state.value = _state.value.copy(input = _state.value.input.copy(areaText = raw))
}
```

### GOOD: guard identical transitions

```kotlin
private fun onAreaEdited(raw: String) {
    val old = _state.value
    if (old.input.areaText == raw) return
    _state.value = old.copy(input = old.input.copy(areaText = raw))
}
```

## Baseline Profiles (Android)

Baseline profiles instruct R8 to pre-compile hot code paths, reducing startup time and jank. Generate via Jetpack Macrobenchmark:

```kotlin
@RunWith(AndroidBenchmarkRunner::class)
class StartupBenchmark {
    @get:Rule val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun startup() = benchmarkRule.measureRepeated(
        packageName = "com.example.app",
        metrics = listOf(StartupTimingMetric()),
        iterations = 10,
        setupBlock = { pressHome(); startActivityAndWait() }
    ) { /* interact with app */ }
}
```

### Measuring Frame Timing

```kotlin
benchmarkRule.measureRepeated(
    packageName = "com.example.app",
    metrics = listOf(FrameTimingMetric()),
    iterations = 10,
) { /* scroll, click, type */ }
```

Target <16.67ms per frame for 60fps.

### R8/ProGuard Rules for Compose (Android only)

Preserve stability annotations in Android release builds. These rules apply only to Android/JVM targets; CMP iOS/Desktop/Web targets do not use R8/ProGuard:

```proguard
-keep @androidx.compose.runtime.Stable class **
-keep @androidx.compose.runtime.Immutable class **
```
