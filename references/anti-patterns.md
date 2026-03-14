# Anti-Patterns

Comprehensive table of patterns that hurt strict-MVI Compose Multiplatform codebases.

| Anti-pattern | Why it is harmful | How it appears in code review | Better replacement |
|---|---|---|---|
| Business logic inside composables | forks source of truth, hurts testability, reruns during composition | parsing, validation, repo calls, analytics in composable body | move logic into reducer/ViewModel/domain services |
| Giant god-ViewModel | blast radius too large, slow reasoning, hard ownership | one ViewModel owns many screens/features | one ViewModel per screen or independent flow |
| Over-modeled intents/effects | ceremony exceeds problem, reduces clarity | 5 sealed layers for simple user actions | one feature intent sealed interface, one effect type if needed |
| Base ViewModel with scattered `updateState`/`sendEffect` | state transitions untestable without full ViewModel, mutations scattered across callbacks and coroutines | `BaseViewModel` with `updateState { copy(...) }` in 10+ places | `MviViewModel` with pure `reduce()` — all state transitions in one function, testable without coroutines |
| Base class that forces extra logic shape | adds unnecessary ceremony | `BaseViewModel` with abstract `mapIntent`, `handleError`, `isLoading` helpers | `MviViewModel` only requires `reduce()`, optional `handleEvent()` |
| Unstable state models | more recomposition, harder skipping | mutable collections, lambdas, platform objects in state | immutable data classes, immutable collections |
| Duplicated derived data | bugs from drift, harder transitions | `total`, `formattedTotal`, `hasTotal`, `showTotal` all stored | keep canonical value + derive once upstream |
| Animation state in reducer for no reason | pollutes business state | `shakeCount`, `alpha`, `pulsePhase` in screen state | local composable animation state |
| Broad state reads in parent composables | recomposition cascades | every child takes `state` | slice state and pass only required props |
| Mutable state passed deep into tree | hidden writes, unpredictable flow | `MutableState<T>` or `SnapshotStateList` passed to leaves | explicit props + callbacks |
| Platform abstraction too early | unnecessary indirection, poor fit | interfaces for everything before pain exists | share business logic first, abstract real platform capabilities only |
| Full-screen loading wipes existing content | bad UX, layout jumps, lost trust | `if (isLoading) Spinner else Content` during refresh | keep old content + inline refresh |
| Reducer doing platform work directly | breaks purity, hurts tests | reducer calls share/analytics/navigation APIs | emit effects and handle them outside reducer |
| Unnecessary use case wrappers | ceremony without value | every repository method wrapped in one class | direct repo/service injection for trivial cases |
| Too many trivial composables | fragmentation, harder reading | wrappers around single `Text`/`Spacer` with no meaning | extract only meaningful boundaries |
| Poor lazy list keys | state jumps between rows, bad animations | no key or index-based key | stable key by domain ID |
| Formatting-heavy display strings stored too early | locale inflexibility, state duplication, harder reuse | reducers emitting many pre-baked strings too early | keep canonical values until presentation boundary |
| One-off events stored as consumable state | event replay bugs, stale effects | `showSnackbarOnce = true` flags in state | separate `uiEffects` flow |
| No-op reducer emissions | wasted recomposition | state copied even when same | guard unchanged values and avoid pointless emits |
