# Animations

animate*AsState, Animatable, updateTransition, AnimatedVisibility, AnimatedContent, and AnimationSpec patterns. Works on all CMP targets. For shared element transitions, gesture-driven motion, and graphicsLayer, see [animations-advanced.md](animations-advanced.md).

References:
- [Choose an animation API (Android)](https://developer.android.com/develop/ui/compose/animation/choose-api)
- [Quick guide (Android)](https://developer.android.com/develop/ui/compose/animation/quick-guide)

## MVI Rules for Animation State

- Animation state is **local UI state** — keep in composables, not reducers
- Reducer state = business/UI meaning, not visual tween progress
- Never put `buttonBounceProgress`, `errorShakeCounter`, `skeletonAlpha`, `rowRemovalAnimationPhase` in ViewModel state

## Choosing the Right API

| Question | API |
|---|---|
| SVG/icon animation? | `AnimatedVectorDrawable` (Android), Lottie/Compottie (CMP) |
| Infinite repeat? | `rememberInfiniteTransition` |
| Switching composables? | `AnimatedContent` or `Crossfade` |
| Appear/disappear? | `AnimatedVisibility` |
| Size change? | `Modifier.animateContentSize()` |
| Multiple props together? | `updateTransition` |
| Different timing per prop? | `Animatable` with sequential `animateTo` |
| Single prop with target? | `animate*AsState` |
| Gesture-driven? | `Animatable` with `animateTo`/`snapTo` |
| List item insert/remove/reorder? | `Modifier.animateItem()` |

## AnimationSpec Reference

| Spec | When to use | Key detail |
|---|---|---|
| `spring` (default) | General purpose, interruption-safe | Maintains velocity on target change; `dampingRatio` (bounciness), `stiffness` (speed) |
| `tween` | Need exact duration control | `durationMillis`, `delayMillis`, `easing` (`FastOutSlowInEasing`, `LinearEasing`, etc.) |
| `keyframes` | Specific values at timestamps | `value at millis using easing` |
| `keyframesWithSplines` | Smooth 2D curved paths | `Offset at fraction` |
| `repeatable` / `infiniteRepeatable` | Looping | `iterations`, `repeatMode` (Reverse/Restart) |
| `snap` | Instant jump | Optional `delayMillis` |

**Prefer `spring`** — handles interruption smoothly. `tween` snaps to a new curve on interruption, which feels jarring.

## animate*AsState — Single Value

```kotlin
val alpha by animateFloatAsState(if (enabled) 1f else 0.5f, label = "alpha")
val color by animateColorAsState(if (selected) Color.Blue else Color.Gray, label = "color")
val padding by animateDpAsState(if (expanded) 16.dp else 0.dp, label = "padding")
val offset by animateIntOffsetAsState(if (moved) IntOffset(100, 100) else IntOffset.Zero, label = "offset")
```

Available types: `Float`, `Color`, `Dp`, `Size`, `Offset`, `Rect`, `Int`, `IntOffset`, `IntSize`. Custom types via `animateValueAsState` with `TwoWayConverter`.

**Performance tips:**
- `Modifier.drawBehind { drawRect(animatedColor) }` is more performant than `Modifier.background()` for animated colors
- `Modifier.graphicsLayer { scaleX = scale; scaleY = scale }` for transforms — Drawing phase only
- Set `textMotion = TextMotion.Animated` for smooth text scale transitions

## Animatable — Coroutine-Based Control

```kotlin
val offset = remember { Animatable(Offset.Zero, Offset.VectorConverter) }

LaunchedEffect(targetPosition) { offset.animateTo(targetPosition) }
Box(Modifier.offset { offset.value.toIntOffset() })
```

| Operation | Purpose |
|---|---|
| `animateTo(target)` | Animate to target (suspends) |
| `snapTo(value)` | Instant set (gesture sync) |
| `animateDecay(velocity, decay)` | Fling deceleration |
| `stop()` | Cancel animation |
| `updateBounds(lower, upper)` | Constrain range |

```kotlin
// Sequential
LaunchedEffect(Unit) {
    alphaAnim.animateTo(1f)
    yAnim.animateTo(100f)
}

// Concurrent
LaunchedEffect(Unit) {
    launch { alphaAnim.animateTo(1f) }
    launch { yAnim.animateTo(100f) }
}
```

New `animateTo` cancels ongoing animation and continues from current value/velocity — no jumpiness.

## updateTransition — Multi-Property State Machine

```kotlin
enum class CardState { Collapsed, Expanded }

val transition = updateTransition(cardState, label = "card")
val size by transition.animateDp(label = "size") { state ->
    when (state) { CardState.Collapsed -> 64.dp; CardState.Expanded -> 128.dp }
}
val color by transition.animateColor(label = "color") { state ->
    when (state) { CardState.Collapsed -> Color.Gray; CardState.Expanded -> Color.Red }
}
```

Per-transition timing: `transitionSpec = { when { Expanded isTransitioningTo Collapsed -> spring(stiffness = 50f); else -> tween(500) } }`.

Start immediately: `MutableTransitionState(Collapsed).apply { targetState = Expanded }`.

Coordinated children: `transition.AnimatedVisibility(visible = { it == Expanded }) { ... }` and `transition.AnimatedContent { ... }`.

## rememberInfiniteTransition

Shimmer, pulsing indicators, loading spinners:

```kotlin
val infiniteTransition = rememberInfiniteTransition(label = "infinite")
val alpha by infiniteTransition.animateFloat(
    initialValue = 0.3f, targetValue = 1f,
    animationSpec = infiniteRepeatable(tween(800), RepeatMode.Reverse),
    label = "alpha",
)
```

## AnimatedVisibility

```kotlin
AnimatedVisibility(
    visible = isVisible,
    enter = fadeIn() + slideInVertically { -40.dp.roundToPx() },
    exit = slideOutVertically() + fadeOut(),
) { Text("Hello") }
```

| Enter | Exit |
|---|---|
| `fadeIn` | `fadeOut` |
| `slideIn` / `slideInHorizontally` / `slideInVertically` | `slideOut` / `slideOutHorizontally` / `slideOutVertically` |
| `scaleIn` | `scaleOut` |
| `expandIn` / `expandHorizontally` / `expandVertically` | `shrinkOut` / `shrinkHorizontally` / `shrinkVertically` |

Combine with `+`. Per-child: `Modifier.animateEnterExit(enter = ..., exit = ...)`. Use `EnterTransition.None`/`ExitTransition.None` on parent to let children define their own.

## AnimatedContent

```kotlin
AnimatedContent(
    targetState = uiState,
    transitionSpec = {
        if (targetState > initialState)
            slideInVertically { it } + fadeIn() togetherWith slideOutVertically { -it } + fadeOut()
        else
            slideInVertically { -it } + fadeIn() togetherWith slideOutVertically { it } + fadeOut()
        using SizeTransform(clip = false)
    },
    label = "content",
) { target ->
    when (target) {
        UiState.Loading -> LoadingScreen()
        UiState.Success -> SuccessScreen()
        UiState.Error -> ErrorScreen()
    }
}
```

`SizeTransform` controls size animation between states. Always use the lambda parameter (`target`), not the outer variable.

## Performance Rules

- `spring` as default — handles interruption, physically natural
- `Modifier.offset { }` (lambda) defers to Layout phase
- `graphicsLayer { }` for visual transforms — Drawing phase only, cheapest
- `drawBehind` for animated colors instead of `background()`
- `animateContentSize` BEFORE size modifiers in chain
- In `AnimatedContent`/`AnimatedVisibility`: use lambda parameter, not outer variable

## Anti-Patterns

| Anti-pattern | Why | Fix |
|---|---|---|
| Animation state in ViewModel | Pollutes business state | Local `animate*AsState` or `Animatable` |
| `Modifier.scale()`/`.offset()` | Recomposition every frame | `graphicsLayer { scaleX = ...; translationX = ... }` |
| Animating every change | Jittery UI | Animate meaningful transitions only |
| `animateContentSize` after size modifiers | No effect | Place BEFORE `size`/`fillMaxWidth` |
| Outer variable in AnimatedContent | Stale during exit | Use lambda parameter |
| `tween`/`snap` everywhere | Jarring interruption | Prefer `spring` |
| Animating padding/size every frame | Expensive Layout phase | Prefer `graphicsLayer` transforms |

## Advanced Patterns

For shared element transitions, gesture-driven animations, Canvas, and graphicsLayer optimization, see [animations-advanced.md](animations-advanced.md).
