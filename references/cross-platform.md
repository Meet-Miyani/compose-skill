# Cross-Platform (KMP) Specifics

## Table of Contents

- [Sharing Strategy](#sharing-strategy)
- [Placement Guide](#placement-guide)
- [Interfaces vs expect/actual](#interfaces-vs-expectactual)
- [Platform Bridge Patterns](#platform-bridge-patterns)
- [Lifecycle](#lifecycle)
- [State Restoration](#state-restoration)
- [Keyboard, Focus, and Input](#keyboard-focus-and-input)
- [Safe Area and Layout](#safe-area-and-layout)
- [Platform Capabilities](#platform-capabilities)
- [Navigation](#navigation)
- [Resources](#resources)
- [Accessibility](#accessibility)
- [Code Examples](#code-examples)

## Sharing Strategy

Share these first: reducers, ViewModels, validators, calculators, formatting policies, screen state models, most screen UI.

Keep these platform-specific until proven otherwise: permissions, share sheets, clipboard APIs, haptics, file pickers, notifications, deep-link registration, app review prompts, platform-only input traits, OS-specific navigation shell integration.

## Placement Guide

### What belongs in `commonMain`

Feature state models, intents and messages, reducer/ViewModel logic, calculators, validators, eligibility engines, repository interfaces, use cases only when they earn their keep, shared screen composables, presentation mapping, semantic navigation effects, semantic error/message keys.

### What should remain platform-specific

Runtime permissions, system share/open sheet, platform haptics, clipboard, URL opening, native purchase/billing integrations, notification registration, biometrics, deep-link registration in app manifests/app delegates, OS widgets/shortcuts.

### Placement Table

| Concern | Default placement | Why |
|---|---|---|
| reducer/ViewModel | `commonMain` | pure, testable, reusable |
| validator/calculator | `commonMain` | pure domain logic |
| repository contract | `commonMain` | shared dependency boundary |
| haptics/share/clipboard | interface + platform impl | app capability, easy to fake |
| locale/number/date formatter | interface or shared library | locale-sensitive behavior |
| resource identifiers | `commonMain` UI | shared UI uses shared resources |
| permission prompt flow | platform-specific | OS-specific behavior |
| safe-area / keyboard handling | route/UI boundary | platform behavior differs |
| navigation controller binding | platform/UI shell | ViewModel should not know controller type |
| analytics SDK integration | platform or shared facade | real implementation differs |

### Dependency Verification for commonMain

**Before claiming any dependency works in `commonMain`, verify it actually publishes multiplatform artifacts.** Many Jetpack/AndroidX libraries remain Android-only. A subset now publish KMP artifacts (e.g., `lifecycle-viewmodel`, `datastore-preferences`), but availability and API surface vary by version.

**Verification steps:**
1. Check Maven Central or Google Maven for the artifact — look for `-jvm`, `-iosarm64`, `-iosX64`, or similar classifier suffixes
2. Consult the library's official documentation for KMP support status
3. If context7 MCP is available, use `resolve-library-id` then `query-docs` to confirm multiplatform support

**If verification is not possible**, state this explicitly and note the dependency may require platform-specific placement or wrapper interfaces.

## Interfaces vs expect/actual

### Default recommendation

Use **interfaces** for app capabilities: haptics, clipboard, share, URL opener, analytics, date/number formatting, file opener.

Use **`expect/actual`** for thin low-level platform facts or tiny helpers when an interface buys little.

### Practical rule

- **Interface** when the capability has lifetime, DI, fakes, or multiple implementations
- **`expect/actual`** when it is a tiny platform hook with no domain meaning

### Dependency Injection

For complex, asynchronous, or hardware-bound platform services (GPS, biometrics, secure keystore), define a pure Kotlin interface in `commonMain` and inject platform-specific implementations using a framework like Koin. Reserve `expect/actual` strictly for lightweight, synchronous, procedural primitives (UUID generation, system date formatting, clipboard access).

### Resource Formatting

Never resolve localized strings within the reducer. Reducers should process mathematical values, leaving translation and formatting entirely to the composable execution context:

```kotlin
// BAD: Reducer sets state.payment = "Payment: $100"
// GOOD: Reducer sets state.paymentAmount = 100.00
//       UI applies: stringResource(Res.string.payment_label, state.paymentAmount)
```

## Platform Bridge Patterns

The rules above say *when* to use interfaces vs `expect/actual`. This section shows *how* to implement each approach.

### Choosing the Right Bridge

| Need | Pattern | Why |
|---|---|---|
| Service with lifecycle, state, or async (player, auth, payments, analytics) | Interface + DI | Testable, fakeable, swappable impls |
| Stateless platform fact (UUID, platform name, default locale) | `expect/actual` function | No DI overhead for a one-liner |
| Reuse existing platform type in common signature | `expect class` + `actual typealias` | Rare — prefer interface when possible |

### Pattern 1: Interface + DI (Primary)

Define the contract in `commonMain`. Platform modules provide implementations. DI wires them. ViewModel depends only on the interface — never imports platform types.

```kotlin
// commonMain
interface Player {
    fun play(uri: String)
    fun pause()
    fun release()
}

// androidMain
class AndroidPlayer(private val context: Context) : Player {
    private val mediaPlayer = MediaPlayer()
    override fun play(uri: String) { mediaPlayer.setDataSource(context, uri.toUri()); mediaPlayer.start() }
    override fun pause() { mediaPlayer.pause() }
    override fun release() { mediaPlayer.release() }
}

// iosMain
class IosPlayer : Player {
    private var avPlayer: AVPlayer? = null
    override fun play(uri: String) { avPlayer = AVPlayer(uRL = NSURL(string = uri)); avPlayer?.play() }
    override fun pause() { avPlayer?.pause() }
    override fun release() { avPlayer = null }
}
```

Wire via platform Koin modules (see [koin.md](koin.md) for full Koin setup):

```kotlin
// androidMain
val androidModule = module { single<Player> { AndroidPlayer(get()) } }

// iosMain
val iosModule = module { single<Player> { IosPlayer() } }

// commonMain — ViewModel depends only on the interface
class PlayerViewModel(private val player: Player) : ViewModel() {
    fun onEvent(event: PlayerEvent) {
        when (event) {
            is PlayerEvent.Play -> player.play(event.uri)
            PlayerEvent.Pause -> player.pause()
        }
    }
}
```

Testing is trivial — create `FakePlayer : Player` with no platform dependencies.

### Pattern 2: expect/actual for Thin Primitives

No DI, no interface — for stateless one-liners with no test-double needs:

```kotlin
// commonMain
expect fun randomUUID(): String

// androidMain
actual fun randomUUID(): String = java.util.UUID.randomUUID().toString()

// iosMain
actual fun randomUUID(): String = platform.Foundation.NSUUID().UUIDString()
```

### Pattern 3: expect/actual with Typealias

When an existing platform type already fits your contract exactly:

```kotlin
// commonMain
expect class PlatformDate {
    fun toEpochMillis(): Long
}

// jvmMain — existing type matches, use typealias
actual typealias PlatformDate = java.time.Instant

// nativeMain — no matching type, implement directly
actual class PlatformDate(private val nsDate: NSDate) {
    actual fun toEpochMillis(): Long = (nsDate.timeIntervalSince1970 * 1000).toLong()
}
```

Prefer interface+DI when you need fakes or when the platform type doesn't match 1:1.

### Bridge Anti-Patterns

- `expect/actual` class for anything with lifecycle, state, or async behavior — use interface+DI instead
- Platform `import` leaking into `commonMain` — compiler catches this, but flag it in review
- Fat `expect/actual` with significant logic — keep them thin, push logic into the interface impl
- Skipping the interface when the service will need fakes in tests

## Lifecycle

**Some** AndroidX Lifecycle artifacts publish multiplatform support in latest artifacts. `androidx.lifecycle:lifecycle-viewmodel` and `lifecycle-runtime-compose` publish KMP targets, enabling `ViewModel`, `viewModelScope`, and `collectAsStateWithLifecycle` in `commonMain`.

**Caveat:** Shared lifecycle support depends on the project's chosen androidx/KMP setup. Not all lifecycle extensions are multiplatform. Before assuming any lifecycle API works in `commonMain`, verify:
1. The specific artifact version publishes KMP targets (check Maven Central for `-jvm`, `-iosarm64`, etc.)
2. The API you need exists in the multiplatform artifact (some APIs remain Android-only)
3. Your project's KMP configuration includes the required targets

**Always verify the current stable version** via context7 MCP or official AndroidX release notes before recommending a specific version. Do not assume versions mentioned in this skill are current.

When verification is not possible, state this explicitly and consider wrapping platform-specific lifecycle behavior behind interfaces.

**Commonly available in `commonMain` (verify version support):**
- `ViewModel`, `viewModelScope` — shared coroutine scope management
- `collectAsStateWithLifecycle` — lifecycle-aware state collection
- `koinViewModel()` — lifecycle-managed ViewModel injection via Koin

**Default patterns:**
- Route owns collection
- ViewModel owns coroutine work
- ViewModel survives as long as the screen flow should survive
- Do not scatter collection logic into leaves

## State Restoration

- `rememberSaveable` is for small local UI state
- Draft restoration across Android/iOS should come from persisted draft rehydration, not from hoping platform restoration semantics align
- Keep ViewModel state serializable only when there is a real restoration requirement

## Keyboard, Focus, and Input

- Test text input on real iOS devices
- Isolate input quirks at the UI/platform boundary
- Do not put platform keyboard workaround flags into reducer state
- Use insets/safe-area aware layout in shared UI
- Keep selection/composition handling local if a text field needs it

## Safe Area and Layout

Use shared insets-aware layouts, but test: top/bottom safe areas, keyboard overlap, sheet presentation, navigation chrome differences.

Do not encode "iOS safe area adjustment required" into feature state.

## Platform Capabilities

Model haptics, clipboard, share as semantic effects.

```kotlin
enum class HapticType { Confirm, Error, Selection }

interface Haptics {
    fun perform(type: HapticType)
}

sealed interface EstimateEffect {
    data class TriggerHaptic(val type: HapticType) : EstimateEffect
    data class ShareQuote(val text: String) : EstimateEffect
}
```

Route/platform shell executes the effect.

```kotlin
interface ShareText {
    suspend fun share(text: String)
}
```

## Navigation

Reducers emit semantic navigation effects; the route/navigation layer executes them.

Good: `EstimateEffect.NavigateBack`, `EstimateEffect.OpenDetails(id)`

Bad: reducer calling navigation controller directly, composable deciding destination rules ad hoc.

## Resources

Use Compose Multiplatform shared resources for strings, images, fonts, localization, and environment qualifiers. For the complete API reference — directory structure, Gradle setup, all resource type APIs (`Res.string`, `Res.drawable`, fonts, plurals, raw files), qualifiers, localization, and the Android `R` vs CMP `Res` comparison — see **[Multiplatform Resources](resources.md)**.

### Default rules

- Keep static UI strings in shared resources
- Keep semantic message keys in state
- Resolve strings close to UI
- Use theme/localization qualifiers
- Keep icons/images/fonts in shared resources when shared
- Keep platform-only assets platform-side

### Resource access pattern

```kotlin
enum class ValidationMessageKey { Required, InvalidNumber, MustBePositive }

@Composable
fun ValidationMessage(messageKey: ValidationMessageKey?) {
    val text = when (messageKey) {
        ValidationMessageKey.Required -> stringResource(Res.string.error_required)
        ValidationMessageKey.InvalidNumber -> stringResource(Res.string.error_invalid_number)
        ValidationMessageKey.MustBePositive -> stringResource(Res.string.error_must_be_positive)
        null -> return
    }
    Text(text = text, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
}
```

This keeps reducer state semantic, resources in UI, and tests simpler.

## Accessibility

Treat accessibility as a first-class part of shared UI:

- Error communication must not rely on color only
- Important controls need semantic labels
- Result changes that matter should be accessible
- Focus order must remain logical
- Dense calculator/forms still need usable touch targets

## Code Examples

### GOOD: shared calculator domain logic

```kotlin
class EstimateCalculator {
    fun calculate(draft: EstimateDraft): EstimateDerived {
        val wasteMultiplier = if (draft.includeWaste) 1.10 else 1.0
        val materialCost = draft.area * draft.materialRate * wasteMultiplier
        val laborCost = draft.area * draft.laborRate
        val subtotal = materialCost + laborCost
        val tax = subtotal * (draft.taxPercent / 100.0)
        return EstimateDerived(materialCost = materialCost, laborCost = laborCost, subtotal = subtotal, tax = tax, total = subtotal + tax)
    }
}
```

### BAD: platform concerns in shared reducer state

```kotlin
@Immutable
data class EstimateState(
    val input: EstimateInput = EstimateInput(),
    val iosKeyboardInsetHack: Int = 0,
    val androidHapticPattern: String = "",
    val shareSheetPresented: Boolean = false,
)
```

That is platform leakage.
