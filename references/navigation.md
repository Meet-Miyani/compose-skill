# Navigation

Shared navigation concepts for Nav 2 and Nav 3. Load first, then see version-specific references.

References:
- [Nav 3 official docs](https://developer.android.com/guide/navigation/navigation-3)
- [Nav 2 official docs](https://developer.android.com/guide/navigation/get-started)
- [Kotlin CMP Nav 3 docs](https://kotlinlang.org/docs/multiplatform/compose-navigation-3.html)

## Nav 2 vs Nav 3 Decision Guide

| Criterion | Nav 3 (NavDisplay) | Nav 2 (NavHost / NavController) |
|---|---|---|
| Back stack ownership | You own it (`SnapshotStateList`) | Library owns it (`NavController`) |
| Navigation model | List manipulation — `add()`, `removeLastOrNull()` | Imperative — `navigate()`, `popBackStack()` |
| MVI alignment | Natural — back stack is state you mutate | Requires bridging — controller calls in effect handlers |
| Deep link parsing | You parse URIs, construct back stack manually | Built-in `NavDeepLink` parsing |
| Scenes / adaptive layouts | First-class: dialog, bottom sheet, list-detail | Manual: separate composable overlays |
| CMP support | Full (Android, iOS, Desktop, Web) | Android-only (JetBrains forks exist but differ) |
| Maturity | Newer — verify artifact stability for production | Stable, battle-tested |
| Fragment interop | None | Full Fragment/Activity integration |

**When to use Nav 3:**
- New Compose projects following MVI architecture
- Compose Multiplatform projects targeting multiple platforms
- Projects wanting direct back stack control as state
- Projects needing adaptive layout scenes (list-detail, dialog, bottom sheet)

**When to use Nav 2:**
- Existing codebases already built on `NavHost`/`NavController`
- Projects requiring built-in deep link parsing via `NavDeepLink`
- Hybrid Compose + Fragment apps where Nav 2 provides Fragment integration
- Teams that prefer the declarative `NavGraph` DSL

## Navigation in MVI

The architectural rule: **ViewModels emit semantic effects; the route layer handles navigation.** This rule applies identically to both Nav 2 and Nav 3.

```kotlin
sealed interface ItemEffect {
    data object NavigateBack : ItemEffect
    data class OpenDetails(val id: String) : ItemEffect
}

// Nav 3 route layer — manipulates back stack
CollectEffect(viewModel.effect) { effect ->
    when (effect) {
        is ItemEffect.NavigateBack -> backStack.removeLastOrNull()
        is ItemEffect.OpenDetails -> backStack.add(Details(effect.id))
    }
}

// Nav 2 route layer — calls NavController
CollectEffect(viewModel.effect) { effect ->
    when (effect) {
        is ItemEffect.NavigateBack -> navController.navigateUp()
        is ItemEffect.OpenDetails -> navController.navigate(Detail(effect.id))
    }
}
```

### Rules

- Never call navigation during composition — always in `LaunchedEffect` or event handler callbacks
- Never pass the back stack (Nav 3) or `NavController` (Nav 2) to the ViewModel or leaf composables
- ViewModel emits semantic effects (`NavigateBack`, `OpenDetails(id)`)
- Route/navigation layer translates effects to navigation calls
- Keep navigation logic at the route boundary, not in screens or leaves

## Anti-Patterns

| Anti-pattern | Applies to | Why it hurts | Better replacement |
|---|---|---|---|
| Navigating during composition | Both | Triggers on every recomposition, causes infinite loops | Navigate in `LaunchedEffect` or event handler callbacks |
| Passing NavController/back stack to ViewModel | Both | Violates MVI boundary, navigation becomes business logic | ViewModel emits semantic effects; route handles navigation |
| String-based routes without type safety | Both | No compile-time checking, argument mismatch at runtime | `@Serializable` data classes/objects |
| Missing `onBack` handler | Nav 3 | System back gesture does nothing | Always provide `onBack = { backStack.removeLastOrNull() }` |
| Globally-scoped ViewModel for per-screen data | Both | Data leaks across screens, not cleared on pop | Entry-scoped VMs (Nav 3 decorators) or destination-scoped VMs (Nav 2) |
| Recreating back stacks on tab switch | Both | Loses user navigation history within tabs | Persistent per-tab stacks (Nav 3) or `saveState`/`restoreState` (Nav 2) |
| Missing entry decorators | Nav 3 | ViewModels leak, saveable state lost | Always include both `rememberSaveableStateHolderNavEntryDecorator` and `rememberViewModelStoreNavEntryDecorator` |
| Using Nav 2 in new MVI codebases | Nav 3 preferred | Nav 3's user-owned back stack aligns better with MVI state ownership | Prefer Nav 3 `NavDisplay` for new MVI-first projects; Nav 2 remains valid for existing codebases |

## Version-Specific References

Load the file that matches your task:

- **Nav 3 routes, tabs, scenes, deep links, or back stack patterns** → [navigation-3.md](navigation-3.md)
- **Nav 2 NavHost, tabs, deep links, nested graphs, or animations** → [navigation-2.md](navigation-2.md)
- **Wiring Hilt or Koin with Nav 3** → [navigation-3-di.md](navigation-3-di.md)
- **Wiring Hilt or Koin with Nav 2** → [navigation-2-di.md](navigation-2-di.md)
- **Migrating from Nav 2 to Nav 3** → [navigation-migration.md](navigation-migration.md)
