# iOS Swift Interop

## Kotlin → Swift Naming

| Kotlin construct | Swift equivalent |
|---|---|
| Top-level function `fun foo()` in `Bar.kt` | `BarKt.foo()` |
| `object AppInit` | `AppInit.shared` |
| `companion object` member | Direct on class: `MyClass.value` |
| `sealed class UiState` | Class hierarchy (or SKIE exhaustive enum) |
| `suspend fun load()` | SKIE: `async func load()` |

```swift
// Entry point — top-level function in MainViewController.kt
let controller = MainViewControllerKt.MainViewController()
```

## Nullability & Type Bridging

| Kotlin | Swift | Notes |
|---|---|---|
| `String` | `String` | Non-null bridged directly |
| `String?` | `String?` | Optional bridged directly |
| `Int` / `Long` | `Int32` / `Int64` | Not Swift `Int` — use explicit cast |
| `Unit` | `KotlinUnit` | Awkward return — avoid in public API |

**Collections:** Kotlin `List<T>` bridges to `[T]` as a read-only copy. Mutability and structural sharing are lost at the boundary. Pass collections across the boundary sparingly — batch, don't iterate.

## Coroutines → Swift Async

| Approach | When to use | Trade-off |
|---|---|---|
| **SKIE** | Default for new CMP projects | Automatic `async`/`AsyncSequence`; adds build plugin |
| **KMP-NativeCoroutines** | Existing projects already using it | Annotation-driven; SKIE preferred for greenfield |

### SKIE (recommended)

SKIE converts `suspend` functions to Swift `async` automatically:

```kotlin
// commonMain
suspend fun loadItems(): List<Item> = repository.getAll()
```
```swift
let items = try await viewModel.loadItems() // SKIE-generated async bridge
```

## Flow → Swift Observation

This is how iOS observes `StateFlow<UiState>` — the critical MVI bridge.

### SKIE: Flow → AsyncSequence

SKIE converts `Flow` to `AsyncSequence`:

```swift
func observeState() async {
    for await state in viewModel.state { self.uiState = state }
}
```

### Manual StateFlow wrapper

Without SKIE, expose a callback-based observer from Kotlin; Swift holds the returned cancel closure and invokes it in `deinit`.

```kotlin
// iosMain
class IosStateCollector<T>(private val flow: StateFlow<T>, private val scope: CoroutineScope) {
    private var job: Job? = null
    fun observe(onChange: (T) -> Unit): () -> Unit {
        job = scope.launch(Dispatchers.Main) { flow.collect { onChange(it) } }
        return { job?.cancel() }
    }
}
```

## Sealed Classes in Swift

### Without SKIE — non-exhaustive

```swift
if let loading = state as? UiState.Loading { showSpinner() }
else if let success = state as? UiState.Success { render(items: success.items) }
else if let error = state as? UiState.Error { showError(error.message) }
// No exhaustiveness check — silent bugs when a new sealed subclass is added
```

### With SKIE — exhaustive Swift enum

```swift
switch onEnum(of: state) {
case .loading: showSpinner()
case .success(let s): render(items: s.items)
case .error(let e): showError(e.message)
} // Compiler error if a new sealed subclass is added
```

### Edge cases

- **Generic sealed classes** — SKIE cannot convert generics to Swift enums; use concrete types at the iOS boundary (e.g., `ItemListState` not `ListState<Item>`)
- **Nested sealed hierarchies** — SKIE flattens names: `UiState.Error.Network` → `.errorNetwork`
- **Opt out** — annotate with `@SealedInterop.Disabled` to skip SKIE conversion for a specific class

## iOS API Design Rules

- Keep the public API surface small — use `internal` visibility + `@HiddenFromObjC` to exclude Kotlin internals from the generated ObjC header
- Avoid generics in public iOS-facing API — ObjC/Swift interop erases or boxes them unpredictably
- Prefer data classes over deep class hierarchies at the boundary — simpler Swift mapping
- Set `isStatic = true` in framework configuration for static linkage (smaller binary, faster startup)
- Minimize Kotlin↔Swift boundary crossings in hot paths — batch data, don't iterate across the boundary
- Avoid `suspend` functions that return `Unit` — Swift receives `KotlinUnit`, requiring callers to discard it explicitly
- Expose sealed classes with concrete (non-generic) type parameters for SKIE compatibility

## Compose in SwiftUI App

Use `ComposeUIViewController` to embed a Compose screen inside an existing SwiftUI application. This is the standard path for incremental adoption — add Compose features to a SwiftUI app without rewriting native screens.

### Kotlin entry point

```kotlin
// iosMain
fun MainViewController(): UIViewController = ComposeUIViewController { App() }
```

### Swift bridge

Wrap the `UIViewController` in a `UIViewControllerRepresentable` for SwiftUI:

```swift
struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MainViewControllerKt.MainViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
```

Use `ComposeView()` anywhere in SwiftUI hierarchy — `NavigationStack`, tab bar, sheet, or as the root view.

### When to use

| Scenario | Approach |
|---|---|
| Entire app is Compose | `ComposeUIViewController` as the root in `@main App` |
| Hybrid app — some screens SwiftUI, some Compose | Embed `ComposeView` per-feature inside SwiftUI navigation |
| Single Compose widget in a SwiftUI screen | Embed `ComposeView` with a fixed `frame` modifier |

## Native iOS Views in Compose

Use `UIKitView` to embed UIKit or SwiftUI components inside a Compose screen. This is how you use platform-native views (maps, camera, webview) that have no Compose equivalent on iOS.

### `UIKitView` basics

```kotlin
UIKitView(
    factory = { MKMapView() },
    modifier = Modifier.size(300.dp),
    update = { mapView -> mapView.setRegion(region, animated = true) }
)
```

- **`factory`** — creates the `UIView` instance once (like `AndroidView`'s factory)
- **`update`** — called on recomposition to sync Compose state into the native view
- **`modifier`** — standard Compose modifier for sizing and layout

### Embedding SwiftUI views

SwiftUI views can't be used directly in `UIKitView`. Wrap them in a `UIHostingController` and pass the controller to a Kotlin factory function:

```kotlin
// iosMain
@OptIn(ExperimentalForeignApi::class)
fun ComposeEntryPointWithNativeView(
    createViewController: () -> UIViewController
): UIViewController = ComposeUIViewController {
    Column(Modifier.fillMaxSize()) {
        Text("Compose content above")
        UIKitViewController(
            factory = createViewController,
            modifier = Modifier.size(300.dp)
        )
    }
}
```
```swift
MainViewControllerKt.ComposeEntryPointWithNativeView {
    UIHostingController(rootView: MySwiftUIMapView())
}
```

### Decision table

| Need | Use |
|---|---|
| UIKit view (`MKMapView`, `WKWebView`, `AVCaptureSession`) | `UIKitView(factory = { ... })` directly in Kotlin |
| SwiftUI view (`Map`, custom SwiftUI component) | Wrap in `UIHostingController`, pass via `UIKitViewController` |
| Complex native screen with its own navigation | Keep it in SwiftUI/UIKit, embed Compose screens via `ComposeUIViewController` instead |

## Anti-Patterns

- **Generic `Resource<T>` sealed class exposed to Swift** — SKIE can't convert it; use concrete result types like `ItemListResult`
- **Observing StateFlow without cancellation cleanup** — memory leak when the view controller is deallocated
- **Returning `Unit` from public API** — becomes `KotlinUnit` in Swift; use a callback or return a meaningful type
- **Crossing ObjC boundary in a loop** — each call has marshaling overhead; collect results in Kotlin, return the batch
- **Exposing mutable Kotlin collections to Swift** — mutations won't reflect; return immutable snapshots
- **Skipping `@HiddenFromObjC`** — pollutes the Swift API surface with internal helpers
- **Recreating UIKit views on every recomposition** — `factory` in `UIKitView` runs once; put state-dependent updates in `update`, not `factory`
- **Skipping `update` in `UIKitView`** — Compose state changes won't propagate to the native view; always implement `update` to sync mutable properties
