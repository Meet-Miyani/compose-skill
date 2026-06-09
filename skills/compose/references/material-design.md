# Material 3 Theming & Components

## TL;DR Defaults

| Concern | Default |
|---|---|
| Theme entry point | `MaterialTheme(colorScheme, typography, shapes)` wrapping app content |
| Dynamic color | Enable on Android 12+; fall back to brand `ColorScheme` on older APIs |
| Dark/light | Follow system via `isSystemInDarkTheme()`; expose user override if needed |
| Color pairing | Always pair `primary`/`onPrimary`, `surface`/`onSurface`, `*Container`/`on*Container` |
| Typography | Use default M3 type scale; override only specific slots for branding |
| Shapes | Use default M3 shape scale; override per-slot (`small`, `medium`, `large`) |
| Scaffold | Use `Scaffold` for screens with app bars, FAB, snackbar, or bottom bar |
| Navigation | `NavigationSuiteScaffold` auto-switches bar/rail by window size |
| Snackbar | `SnackbarHostState` in Route; show via `Effect` from ViewModel |
| Bottom sheet | `ModalBottomSheet` with `SheetState`; control via `show()`/`hide()` |
| Dialog | `AlertDialog` for simple confirm/dismiss; custom `Dialog` for complex content |
| Adaptive layout | Derive window size class once at app level; pass down as state |

## Theming Baseline

### Theme Setup

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}
```

### Key Rules

- Define `LightColorScheme` and `DarkColorScheme` using `lightColorScheme()` / `darkColorScheme()`.
- Generate brand colors via [Material Theme Builder](https://m3.material.io/theme-builder) for guaranteed tonal palettes.
- Dynamic color is Android-only; CMP projects fall back to brand schemes on non-Android targets.

## Color Roles and Dark/Light

### Role Pairing Rules

| Container | Content on it |
|---|---|
| `primary` | `onPrimary` |
| `primaryContainer` | `onPrimaryContainer` |
| `secondary` | `onSecondary` |
| `secondaryContainer` | `onSecondaryContainer` |
| `tertiary` | `onTertiary` |
| `tertiaryContainer` | `onTertiaryContainer` |
| `surface` | `onSurface` |
| `surfaceVariant` | `onSurfaceVariant` |
| `error` | `onError` |
| `errorContainer` | `onErrorContainer` |

### Accessibility Guardrails

- Always use the correct `on*` color for text/icons on a container.
- Do not mix unrelated pairs (e.g., `tertiaryContainer` background with `primaryContainer` text).
- M3 tonal palettes guarantee 3:1+ contrast when paired correctly.

### Do / Don't

| Do | Don't |
|---|---|
| `containerColor = primary`, `contentColor = onPrimary` | `containerColor = primary`, `contentColor = tertiaryContainer` |
| Access colors via `MaterialTheme.colorScheme.*` | Hardcode hex colors in components |
| Test both light and dark themes | Assume light-only usage |

## Typography and Shapes

### Typography

M3 defines 15 text styles across 5 categories:

| Category | Sizes |
|---|---|
| Display | `displayLarge`, `displayMedium`, `displaySmall` |
| Headline | `headlineLarge`, `headlineMedium`, `headlineSmall` |
| Title | `titleLarge`, `titleMedium`, `titleSmall` |
| Body | `bodyLarge`, `bodyMedium`, `bodySmall` |
| Label | `labelLarge`, `labelMedium`, `labelSmall` |

**Default**: Use M3 defaults. Override individual slots for brand fonts:

```kotlin
val AppTypography = Typography(
    titleLarge = TextStyle(fontFamily = BrandFont, fontWeight = FontWeight.SemiBold, fontSize = 22.sp)
)
```

### Shapes

M3 shape scale: `extraSmall`, `small`, `medium`, `large`, `extraLarge`.

**Default**: Use M3 defaults. Override only when brand requires specific corner radii:

```kotlin
val AppShapes = Shapes(
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp)
)
```

## Component Decision Matrix

### Scaffold

| Slot | When to use |
|---|---|
| `topBar` | Screen has a top app bar |
| `bottomBar` | Screen has bottom navigation or bottom app bar |
| `floatingActionButton` | Primary action needs FAB |
| `snackbarHost` | Screen can show snackbars |
| `content` | Main screen content; receives `PaddingValues` to apply |

**Rule**: Always apply `innerPadding` from `Scaffold` to content root.

### Top App Bar

| Variant | Use case | Scroll / default |
|---|---|---|
| `TopAppBar` (small) | Simple screens, minimal actions | Default: `pinnedScrollBehavior` unless you need collapse |
| `CenterAlignedTopAppBar` | Single primary action, centered title | Same bar family as small |
| `MediumTopAppBar` | Moderate navigation, collapsible on scroll | `exitUntilCollapsedScrollBehavior` (also `enterAlwaysScrollBehavior` where needed) |
| `LargeTopAppBar` | Hero screens, prominent title, collapsible | Same scroll behavior family as medium |

### Navigation

| Window size | Component |
|---|---|
| Compact (phones portrait) | `NavigationBar` (bottom) |
| Medium/Expanded (tablets, landscape) | `NavigationRail` (side) |
| Auto-switch | `NavigationSuiteScaffold` |

**Default**: Use `NavigationSuiteScaffold` for apps with 3-5 top-level destinations. It adapts automatically.

```kotlin
NavigationSuiteScaffold(
    navigationSuiteItems = {
        destinations.forEach { dest ->
            item(
                selected = currentDest == dest,
                onClick = { currentDest = dest },
                icon = { Icon(dest.icon, contentDescription = null) },
                label = { Text(dest.label) }
            )
        }
    }
) { DestinationContent(currentDest) }
```

### Bottom Sheet

| Type | Use case |
|---|---|
| `ModalBottomSheet` | Overlays content, dismissible |
| `BottomSheetScaffold` | Persistent sheet integrated with screen |

**State control**: Use `rememberModalBottomSheetState()` + `SheetState.show()`/`hide()`.

**MVI pattern**: ViewModel emits `Effect.ShowSheet`; Route composable calls `sheetState.show()` in `LaunchedEffect`.

### Snackbar

**Setup**: `SnackbarHostState` remembered in Route; passed to `Scaffold.snackbarHost`.

**Pattern**:
```kotlin
val snackbarHostState = remember { SnackbarHostState() }
LaunchedEffect(Unit) {
    viewModel.effects.collect { effect ->
        when (effect) {
            is Effect.ShowSnackbar -> {
                val result = snackbarHostState.showSnackbar(effect.message, effect.actionLabel)
                if (result == SnackbarResult.ActionPerformed) viewModel.onEvent(Event.SnackbarAction)
            }
        }
    }
}
Scaffold(snackbarHost = { SnackbarHost(snackbarHostState) }) { /* ... */ }
```

### Dialog

| Type | Use case |
|---|---|
| `AlertDialog` | Simple title + text + confirm/dismiss buttons |
| `Dialog` + `Card` | Complex content, forms, custom layouts |

**MVI pattern**: Dialog visibility controlled by `state.showDialog: Boolean`. Confirm/dismiss dispatch events.

## Adaptive Layout Defaults

### Window Size Classes

| Class | Width breakpoint | Typical devices |
|---|---|---|
| Compact | < 600dp | Phones portrait |
| Medium | 600dp – 840dp | Tablets portrait, large unfolded |
| Expanded | ≥ 840dp | Tablets landscape, desktop |

**Rule**: Compute `WindowSizeClass` once at app/activity level via `currentWindowAdaptiveInfo()`. Pass derived layout decisions down as state.

### Canonical Layouts

| Layout | Use case | Compose component |
|---|---|---|
| List-detail | Master list + detail pane | `ListDetailPaneScaffold`, `NavigableListDetailPaneScaffold` |
| Supporting pane | Main content + supplementary info | `SupportingPaneScaffold`, `NavigableSupportingPaneScaffold` |
| Feed | Grid of browsable content | `LazyVerticalGrid` with `GridCells.Adaptive` |

**Default**: For list-detail apps, use `NavigableListDetailPaneScaffold` which handles pane visibility and back navigation.

**Adaptive navigation:** read `windowSizeClass` (or related adaptive info) once at the root and pass derived flags (e.g. whether to show a top app bar) into your main screen composable.

## M2 to M3 Migration Notes

| M2 | M3 |
|---|---|
| `Colors` | `ColorScheme` |
| `lightColors()` / `darkColors()` | `lightColorScheme()` / `darkColorScheme()` |
| `BottomNavigation` | `NavigationBar` |
| `BottomNavigationItem` | `NavigationBarItem` |
| `ModalBottomSheetLayout` | `ModalBottomSheet` |
| `ModalDrawer` | `ModalNavigationDrawer` |
| `Scaffold` with `scaffoldState` | `Scaffold` with `snackbarHost` slot |
| `BackdropScaffold` | `BottomSheetScaffold` or custom |
| `TopAppBar` elevation | `TopAppBar` with `scrollBehavior` |

**Key change**: M3 `Scaffold` no longer has `drawerState`. Use `ModalNavigationDrawer` wrapping `Scaffold` instead.
