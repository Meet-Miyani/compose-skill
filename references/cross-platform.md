# Cross-Platform (KMP) Specifics

## Table of Contents

- [Sharing Strategy](#sharing-strategy)
- [Placement Guide](#placement-guide)
- [Interfaces vs expect/actual](#interfaces-vs-expectactual)
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

## Lifecycle

Compose Multiplatform has shared lifecycle support. `androidx.lifecycle:lifecycle-viewmodel` and `lifecycle-runtime-compose` are multiplatform since lifecycle 2.8+. This means:

- `ViewModel`, `viewModelScope`, and `collectAsStateWithLifecycle` work in `commonMain`
- ViewModels can extend `ViewModel()` in shared code and use `viewModelScope` for coroutine management
- `koinViewModel()` works in CMP to inject lifecycle-managed ViewModels

**Default:**

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

sealed interface EstimateUiEffect {
    data class TriggerHaptic(val type: HapticType) : EstimateUiEffect
    data class ShareQuote(val text: String) : EstimateUiEffect
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

Good: `UiEffect.NavigateBack`, `UiEffect.OpenEstimateDetails(id)`

Bad: reducer calling navigation controller directly, composable deciding destination rules ad hoc.

## Resources

Use Compose Multiplatform shared resources for strings, images, fonts, localization, and environment qualifiers.

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
