# Performance & Recomposition

## Three Phases and Primitive Specializations

Compose executes Composition, Layout, and Drawing phases per frame. State reads in later phases skip earlier phases — moving reads from Composition to Layout/Drawing eliminates recomposition for those reads. Use `Modifier.offset { }` (lambda) instead of `Modifier.offset()`. Use `mutableIntStateOf()`/`mutableFloatStateOf()` instead of `mutableStateOf<Int>()` to avoid boxing. See [compose-essentials.md](compose-essentials.md) for full explanation and code examples.

## Performance Mistakes and Fixes

| # | Issue | Fix |
|---|---|---|
| 1 | Unstable parameters (`MutableList`, lambdas in state models, anonymous objects) | Immutable data classes + immutable collections |
| 2 | Broad state observation — parent reads whole state, ripples through tree | Collect once at route, slice aggressively for leaves |
| 3 | Large state passed everywhere — many nodes observe unused fields | Pass only what each child renders |
| 4 | Callback recreation in hot paths (large lazy lists, nested rows) | `remember(key, callback)` for repeated rows |
| 5 | Expensive calculations during composition (parse, sort, filter, format) | Move upstream to ViewModel/domain |
| 6 | `remember` misuse — caching business state, hiding architecture issues | Use only for local UI state, expensive local objects, hot callback adaptation |
| 7 | `derivedStateOf` misuse — wrapping cheap expressions | Use only when derived from rapidly changing Compose state with coarse output |
| 8 | `rememberSaveable` misuse — entire screen state, large graphs | Use only for tiny UI-local values surviving recreation |
| 9 | State reads too high in tree (`LazyListState`, animation, keyboard state) | Read close to use |
| 10 | List recomposition — missing keys, unstable items, inline filters/sorts | Stable keys, immutable models, pre-computed data |
| 11 | Reducer emits excessive updates — same state, rebuilds on every keystroke | Guard identical transitions, emit only on semantic change |
| 12 | Ephemeral visual state in global screen state (shimmer alpha, pulse phase) | Keep visual-only state local |
| 13 | Equality pitfalls — lambdas in data classes, random IDs, mutable collections | No lambdas/mutables in data classes, stable IDs |
| 14 | Abusing `@Immutable`/`@Stable` to silence compiler | Use only to describe truth — `@Immutable` for truly immutable, `@Stable` rare in app code |
| 15 | Raw text input in MVI causing stutter (25+ fields) | `TextFieldState`/`BasicTextField2`, group fields into nested data classes, isolate read scopes |
| 16 | State reads in Composition phase for layout/draw values | Lambda modifiers: `Modifier.offset { IntOffset(scrollOffset, 0) }` |

## API Decision Table

| API | Use it for | Do not use it for |
|---|---|---|
| `remember` | local objects/state across recompositions | business state, repo results, derived domain data |
| `rememberSaveable` | small UI-local state needing restoration | whole screen state, large graphs, domain objects |
| `derivedStateOf` | reducing downstream updates from fast-changing Compose state | cheap string concatenation, reducer-owned derivations |
| `key` | preserving identity in dynamic children/lists | hiding bad state models |
| `LaunchedEffect` | collecting UI effects, startup event, one-shot route work | screen business logic in leaves |
| `DisposableEffect` | register/unregister listeners with cleanup | long-running business jobs |
| `produceState` | bridging external async/callback source to local Compose state | replacing a real ViewModel |
| `snapshotFlow` | turning Compose state reads into `Flow` operators | normal state rendering |
| `collectAsState` | collect `StateFlow` into Compose | collecting everywhere in the tree |
| lifecycle-aware collection | Lifecycle host integration (multiplatform since lifecycle 2.8+) | common leaf components |
| stable callbacks | hot repeated UI paths | every single callback everywhere |

## Code Examples

### BAD: calculating derived results in a composable

```kotlin
@Composable
fun CalculatorResult(state: CalculatorState) {
    val area = state.input.areaText.toDoubleOrNull() ?: 0.0
    val materialRate = state.input.materialRateText.toDoubleOrNull() ?: 0.0
    val subtotal = (area * materialRate)
    Text("Subtotal: $subtotal")
}
```

### GOOD: derive upstream, narrow reads

```kotlin
@Composable
fun CalculatorScreen(state: CalculatorState, onEvent: (CalculatorEvent) -> Unit) {
    Header(title = "Estimator")
    CalculatorForm(
        input = state.input,
        validation = state.validation,
        enabled = !state.isRefreshingQuote,
        onAreaChanged = { onEvent(CalculatorEvent.FieldChanged(FormField.Area, it)) },
    )
    ResultCard(derived = state.derived, isRefreshing = state.isRefreshingQuote)
}

@Composable
fun CalculatorResult(derived: CalculatorDerived?) {
    Text(text = derived?.subtotal?.toString() ?: "—")
}
```

### BAD: unstable list items

```kotlin
data class HistoryRowState(
    val id: String, val title: String,
    val tags: MutableList<String>,   // unstable
    val onClick: () -> Unit,         // lambda in data class
)
```

### GOOD: immutable models, stable keys, callback stability

```kotlin
@Immutable
data class HistoryRowUi(val id: String, val title: String, val subtitle: String)

@Composable
fun HistoryList(items: ImmutableList<HistoryRowUi>, onOpen: (String) -> Unit) {
    LazyColumn {
        items(items = items, key = { it.id }) { item ->
            val onClick = remember(item.id, onOpen) { { onOpen(item.id) } }
            ListItem(
                headlineContent = { Text(item.title) },
                supportingContent = { Text(item.subtitle) },
                modifier = Modifier.clickable(onClick = onClick),
            )
        }
    }
}
```

### GOOD: correct `derivedStateOf`

```kotlin
val listState = rememberLazyListState()
val showScrollToTop by remember { derivedStateOf { listState.firstVisibleItemIndex > 2 } }
```

### BAD: unnecessary `derivedStateOf`

```kotlin
val text by remember { derivedStateOf { if (canSubmit) "Submit" else "Fix errors" } }
// Just write: Text(if (canSubmit) "Submit" else "Fix errors")
```

### GOOD: guard identical transitions

```kotlin
private fun onAreaEdited(raw: String) {
    val old = _state.value
    if (old.input.areaText == raw) return
    _state.value = old.copy(input = old.input.copy(areaText = raw))
}
```

## Compiler and Build Optimizations

- **Strong Skipping Mode** — enable via compiler flags; allows composables with unstable parameters to skip based on instance equality (`===`)
- **Stability config** — use `stability_config.conf` to mark external classes as stable: `com.example.network.dto.*`, `kotlinx.datetime.Instant`
- **Compose Compiler Metrics** — audit `restartable`/`skippable` characteristics regularly

## Baseline Profiles (Android)

Pre-compile hot code paths via Jetpack Macrobenchmark to reduce startup time and jank:

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

Target <16.67ms per frame for 60fps. Use `FrameTimingMetric()` for scroll/interaction benchmarks.

### R8/ProGuard Rules for Compose (Android only)

```proguard
-keep @androidx.compose.runtime.Stable class **
-keep @androidx.compose.runtime.Immutable class **
```
