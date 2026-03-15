# Anti-Patterns

Comprehensive table of patterns that hurt MVI Compose Multiplatform codebases.

| Anti-pattern | Why it is harmful | How it appears in code review | Better replacement |
|---|---|---|---|
| Business logic inside composables | forks source of truth, hurts testability, reruns during composition | parsing, validation, repo calls, analytics in composable body | move logic into ViewModel/domain services |
| Giant god-ViewModel | blast radius too large, slow reasoning, hard ownership | one ViewModel owns many screens/features | one ViewModel per screen or independent flow |
| Over-modeled intents/effects | ceremony exceeds problem, reduces clarity | 5 sealed layers for simple user actions, or 4-type MVI (Event/Result/State/Effect) for trivial screens | one feature event sealed interface, one effect type if needed; 3-type MVI (Event/State/Effect) is usually enough |
| Base ViewModel with scattered `updateState`/`sendEffect` and no organizing principle | state transitions hard to trace, mutations scattered across callbacks and coroutines with no clear structure | `updateState { copy(...) }` in 15+ random places across helpers, callbacks, catch blocks | disciplined `onEvent()` as single entry point with well-named helper functions for complex flows |
| Base class that forces unnecessary ceremony | adds 4th type (Result) and pure reducer for screens that don't benefit | `BaseMviViewModel<Event, Result, State, Effect>` with `handleEvent()` + `reduce()` + `dispatch()` for a 3-field form | use 3-type MVI (Event/State/Effect) with direct state updates in `onEvent()` |
| Unstable state models | more recomposition, harder skipping | mutable collections, lambdas, platform objects in state | immutable data classes, immutable collections |
| Duplicated derived data | bugs from drift, harder transitions | `total`, `formattedTotal`, `hasTotal`, `showTotal` all stored | keep canonical value + derive via computed property |
| Animation state in ViewModel for no reason | pollutes business state | `shakeCount`, `alpha`, `pulsePhase` in screen state | local composable animation state |
| Broad state reads in parent composables | recomposition cascades | every child takes `state` | slice state and pass only required props |
| Mutable state passed deep into tree | hidden writes, unpredictable flow | `MutableState<T>` or `SnapshotStateList` passed to leaves | explicit props + callbacks |
| Platform abstraction too early | unnecessary indirection, poor fit | interfaces for everything before pain exists | share business logic first, abstract real platform capabilities only |
| Full-screen loading wipes existing content | bad UX, layout jumps, lost trust | `if (isLoading) Spinner else Content` during refresh | keep old content + inline refresh indicator |
| ViewModel doing platform work in onEvent directly | breaks testability, platform coupling | `onEvent` calls share/analytics/navigation APIs directly | emit effects and handle them in the Route composable |
| Unnecessary use case wrappers | ceremony without value | every repository method wrapped in one class | direct repo/service injection for trivial cases |
| Too many trivial composables | fragmentation, harder reading | wrappers around single `Text`/`Spacer` with no meaning | extract only meaningful boundaries |
| Poor lazy list keys | state jumps between rows, bad animations | no key or index-based key | stable key by domain ID |
| Formatting-heavy display strings stored too early | locale inflexibility, state duplication, harder reuse | ViewModel emitting pre-baked display strings | keep canonical values until presentation boundary |
| One-off events stored as consumable state | event replay bugs, stale effects | `showSnackbarOnce = true` flags in state | separate `Effect` via `Channel` |
| No-op state emissions | wasted recomposition | state copied even when same | guard unchanged values and avoid pointless updates |
| Forcing MVI migration on existing codebase | churn without value, team friction | rewriting working MVVM screens to MVI when not asked | respect existing patterns, introduce MVI for new features only |
