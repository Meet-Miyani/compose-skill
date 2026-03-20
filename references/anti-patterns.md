# Anti-Patterns

Quick-reference table of cross-cutting patterns that hurt MVI Compose Multiplatform codebases. Domain-specific anti-patterns (navigation, networking, paging, DI, etc.) live in their respective reference files — see the "Detailed in" column.

For overengineering patterns (bloated base classes, unnecessary use cases, 4-type MVI), see [clean-code.md](clean-code.md).

## Cross-Cutting Anti-Patterns

| Anti-pattern | Why it is harmful | Better replacement | Detailed in |
|---|---|---|---|
| Business logic inside composables | forks source of truth, hurts testability, reruns during composition | move logic into ViewModel/domain services | [architecture.md](architecture.md) |
| Giant god-ViewModel | blast radius too large, slow reasoning, hard ownership | one ViewModel per screen or independent flow | [architecture.md](architecture.md) |
| Scattered `updateState`/`sendEffect` with no structure | state transitions hard to trace, mutations across callbacks | disciplined `onEvent()` as single entry point | [clean-code.md](clean-code.md) |
| Unstable state models (mutable collections, lambdas in state) | defeats Compose skipping, more recomposition | immutable data classes, immutable collections | [performance.md](performance.md) |
| Duplicated derived data (`total`, `formattedTotal`, `hasTotal` all stored) | bugs from drift, harder transitions | keep canonical value + derive via computed property | [architecture.md](architecture.md) |
| Broad state reads in parent composables | recomposition cascades to all children | slice state, pass only required props to each child | [performance.md](performance.md) |
| Mutable state passed deep into tree | hidden writes, unpredictable data flow | explicit props + callbacks | [compose-essentials.md](compose-essentials.md) |
| One-off events stored as consumable state (`showSnackbarOnce = true`) | event replay on config change, stale effects | separate `Effect` via `Channel` | [architecture.md](architecture.md) |
| No-op state emissions (copy state when nothing changed) | wasted recomposition cycles | guard unchanged values before updating | [performance.md](performance.md) |
| Full-screen loading wipes existing content | bad UX, layout jumps, lost user trust | keep old content + inline refresh indicator | [ui-ux.md](ui-ux.md) |
| ViewModel doing platform work directly (share, analytics, navigation) | breaks testability, platform coupling | emit effects, handle in Route composable | [architecture.md](architecture.md) |
| Animation state in ViewModel for no reason (`shakeCount`, `alpha`) | pollutes business state | local composable animation state | [animations.md](animations.md) |
| Display strings stored too early (ViewModel emits pre-baked formatted text) | locale inflexibility, state duplication, harder reuse | keep canonical values until presentation boundary | [architecture.md](architecture.md) |
| Poor lazy list keys (no key or index-based) | state jumps between rows, broken animations | stable key by domain ID | [lists-grids.md](lists-grids.md) |
| Too many trivial composables (wrappers around single `Text`/`Spacer`) | fragmentation, harder reading | extract only meaningful boundaries | [clean-code.md](clean-code.md) |
| Platform abstraction too early (interfaces for everything before pain) | unnecessary indirection, poor fit | share business logic first, abstract real platform capabilities only | [cross-platform.md](cross-platform.md) |
| Forcing MVI migration on existing codebase | churn without value, team friction | respect existing patterns, introduce MVI for new features only | [clean-code.md](clean-code.md) |

## Domain-Specific Anti-Patterns

These reference files contain their own anti-pattern sections with detailed BAD/GOOD code examples:

| Domain | Reference | What it covers |
|---|---|---|
| Architecture & MVI | [architecture.md](architecture.md) | event handling, state modeling, effect misuse, domain layer violations |
| Overengineering | [clean-code.md](clean-code.md) | bloated base classes, 4-type MVI, use case wrappers, naming |
| Coroutines & Flow | [coroutines-flow.md](coroutines-flow.md) | GlobalScope, blocking dispatchers, unbound scopes, stateIn misuse |
| Performance | [performance.md](performance.md) | recomposition, stability, state shape, read boundaries |
| Compose Essentials | [compose-essentials.md](compose-essentials.md) | side effects, modifier ordering, CompositionLocal |
| Animations | [animations.md](animations.md) | ViewModel animation state, graphicsLayer misuse, over-animating |
| Lists & Grids | [lists-grids.md](lists-grids.md) | keys, nested scrolling, contentType |
| UI/UX | [ui-ux.md](ui-ux.md) | disappearing content, layout jumps, loading states |
| Navigation | [navigation.md](navigation.md) | route design, back stack, ViewModel scoping |
| Paging | [paging.md](paging.md) | PagingData in UiState, key misuse, LoadState handling |
| Networking | [networking-ktor.md](networking-ktor.md) | client config, error handling, auth |
| Room Database | [room-database.md](room-database.md) | entity design, DAO patterns, migrations |
| DataStore | [datastore.md](datastore.md) | singleton enforcement, blocking reads, corruption |
| DI (Koin) | [koin.md](koin.md) | module organization, scoping, ViewModel injection |
| DI (Hilt) | [hilt.md](hilt.md) | module structure, scoping, testing |
| Image Loading | [image-loading.md](image-loading.md) | cache policy, transformations, placeholder usage |
| Testing | [testing.md](testing.md) | missing ViewModel tests, mocking DI, testing internals |
| Cross-Platform | [cross-platform.md](cross-platform.md) | expect/actual misuse, premature abstraction |
| iOS Interop | [ios-swift-interop.md](ios-swift-interop.md) | naming, nullability, Flow bridging |
| Resources | [resources.md](resources.md) | Android R vs CMP Res, qualifier usage |
| Material Design | [material-design.md](material-design.md) | theme setup, component choice, adaptive layouts |
| Accessibility | [accessibility.md](accessibility.md) | missing semantics, touch targets, contrast |
| Gradle & Build | [gradle-build.md](gradle-build.md) | hardcoded versions, buildSrc, convention plugin timing |
