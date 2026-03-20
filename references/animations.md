# Animations

Comprehensive Compose animation reference — from simple value animations to shared element transitions, gesture-driven motion, and custom Canvas drawing. All animation APIs described here work in both Jetpack Compose (Android) and Compose Multiplatform (CMP) unless explicitly noted.

References:
- [Choose an animation API (Android)](https://developer.android.com/develop/ui/compose/animation/choose-api)
- [Quick guide (Android)](https://developer.android.com/develop/ui/compose/animation/quick-guide)
- [Animation modifiers and composables](https://developer.android.com/develop/ui/compose/animation/composables-modifiers)
- [Value-based animations](https://developer.android.com/develop/ui/compose/animation/value-based)
- [Customize animations](https://developer.android.com/develop/ui/compose/animation/customize)
- [Shared element transitions](https://developer.android.com/develop/ui/compose/animation/shared-elements)
- [Gesture-driven animations](https://developer.android.com/develop/ui/compose/animation/advanced)

## Table of Contents

- [MVI Rules for Animation State](#mvi-rules-for-animation-state)
- [Choosing the Right API](#choosing-the-right-api)
- [AnimationSpec — Customizing Timing](#animationspec--customizing-timing)
- [animate*AsState — Single Value](#animateasstate--single-value)
- [Animatable — Coroutine-Based Control](#animatable--coroutine-based-control)
- [updateTransition — Multi-Property State Machine](#updatetransition--multi-property-state-machine)
- [rememberInfiniteTransition](#reminderinfinitetransition)
- [AnimatedVisibility](#animatedvisibility)
- [AnimatedContent](#animatedcontent)
- [Shared Element Transitions](#shared-element-transitions)
- [Gesture-Driven Animations](#gesture-driven-animations)
- [Canvas and Custom Drawing](#canvas-and-custom-drawing)
- [graphicsLayer for Efficient Animation](#graphicslayer-for-efficient-animation)
- [Performance Optimization](#performance-optimization)
- [When Not to Animate](#when-not-to-animate)

## MVI Rules for Animation State

- Animation state is usually **local UI state** — keep it in composables
- Reducer state describes business/UI meaning, not visual tween progress
- Animate state changes that improve comprehension, not every change available
- Prefer simple APIs first

### What stays local

Expanded/collapsed toggles, pulse/shimmer alpha, transition progress, temporary validation highlights, local appearance/disappearance.

### What should NOT go into reducer state

`buttonBounceProgress`, `errorShakeCounter`, `skeletonAlpha`, `contentFadeInStarted`, `rowRemovalAnimationPhase` — these are render choreography, not business state.

## Choosing the Right API

| Question | API |
|---|---|
| Art-based SVG/icon animation? | `AnimatedVectorDrawable` (Android), Lottie (`airbnb/lottie-compose` on Android, `alexzhirkevich/compottie` for CMP) |
| Infinite repeat? | `rememberInfiniteTransition` |
| Switching between composables? | `AnimatedContent` or `Crossfade` |
| Appearance/disappearance? | `AnimatedVisibility` |
| Size change? | `Modifier.animateContentSize()` |
| Multiple properties changing together? | `updateTransition` |
| Multiple properties with different timing? | `Animatable` with sequential `animateTo` |
| Single property with target value? | `animate*AsState` |
| Gesture-driven, source of truth? | `Animatable` with `animateTo`/`snapTo` |
| List item insert/remove/reorder? | `Modifier.animateItem()` |
| Position change? | `animateIntOffsetAsState` + `Modifier.offset { }` |

## AnimationSpec — Customizing Timing

All animation APIs accept an `animationSpec` parameter to control timing.

### spring (default)

Physics-based. Handles interruption smoothly — maintains velocity when target changes mid-animation.

```kotlin
animationSpec = spring(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessLow,
)
```

`dampingRatio` controls bounciness (0 = no bounce, 1 = critical damping). `stiffness` controls speed toward target.

### tween

Duration-based with easing curve.

```kotlin
animationSpec = tween(
    durationMillis = 300,
    delayMillis = 50,
    easing = FastOutSlowInEasing,
)
```

Built-in easings: `FastOutSlowInEasing`, `LinearOutSlowInEasing`, `FastOutLinearInEasing`, `LinearEasing`, `CubicBezierEasing`.

### keyframes

Specific values at specific timestamps:

```kotlin
animationSpec = keyframes {
    durationMillis = 375
    0.0f at 0 using LinearOutSlowInEasing
    0.2f at 15 using FastOutLinearInEasing
    0.4f at 75
    0.4f at 225
}
```

### keyframesWithSplines

Smooth curved path between keyframes — ideal for 2D motion:

```kotlin
animationSpec = keyframesWithSpline {
    durationMillis = 6000
    Offset(0f, 0f) at 0
    Offset(150f, 200f) atFraction 0.5f
    Offset(0f, 100f) atFraction 0.7f
}
```

### repeatable and infiniteRepeatable

```kotlin
animationSpec = repeatable(iterations = 3, animation = tween(300), repeatMode = RepeatMode.Reverse)
animationSpec = infiniteRepeatable(animation = tween(1000), repeatMode = RepeatMode.Reverse)
```

### snap

Instant jump, optionally delayed:

```kotlin
animationSpec = snap(delayMillis = 50)
```

### spring vs tween interruption

`spring` is the default for a reason — when interrupted mid-animation, it continues from the current velocity. `tween` snaps to a new timing curve, which can feel jarring. Prefer `spring` unless you need exact duration control.

## animate*AsState — Single Value

The simplest animation API. Provide a target value and Compose animates to it automatically.

```kotlin
val alpha by animateFloatAsState(if (enabled) 1f else 0.5f, label = "alpha")
val color by animateColorAsState(if (selected) Color.Blue else Color.Gray, label = "color")
val padding by animateDpAsState(if (expanded) 16.dp else 0.dp, label = "padding")
val offset by animateIntOffsetAsState(if (moved) IntOffset(100, 100) else IntOffset.Zero, label = "offset")
```

Available: `Float`, `Color`, `Dp`, `Size`, `Offset`, `Rect`, `Int`, `IntOffset`, `IntSize`. Custom types via `animateValueAsState` with `TwoWayConverter`.

### Animated background color (performant)

```kotlin
val animatedColor by animateColorAsState(if (active) Color.Green else Color.Blue, label = "bg")
Column(modifier = Modifier.drawBehind { drawRect(animatedColor) }) { /* content */ }
```

`drawBehind` is more performant than `Modifier.background()` for animated colors — avoids recomposition.

### Animated text scale

```kotlin
val scale by animateFloatAsState(if (enlarged) 2f else 1f, label = "scale")
Text(
    "Hello",
    modifier = Modifier.graphicsLayer { scaleX = scale; scaleY = scale },
    style = LocalTextStyle.current.copy(textMotion = TextMotion.Animated),
)
```

Set `textMotion = TextMotion.Animated` for smooth text size transitions.

## Animatable — Coroutine-Based Control

Finer-grained control than `animate*AsState`. Suspending API for sequential, concurrent, and gesture-driven animations.

```kotlin
val offset = remember { Animatable(Offset.Zero, Offset.VectorConverter) }

LaunchedEffect(targetPosition) {
    offset.animateTo(targetPosition)
}

Box(Modifier.offset { offset.value.toIntOffset() })
```

### Key operations

| Operation | Purpose |
|---|---|
| `animateTo(target)` | Animate to target value (suspends) |
| `snapTo(value)` | Set value instantly (sync with gestures) |
| `animateDecay(velocity, decay)` | Fling deceleration |
| `stop()` | Cancel ongoing animation |
| `updateBounds(lower, upper)` | Constrain value range |

### Sequential animations

```kotlin
LaunchedEffect(Unit) {
    alphaAnim.animateTo(1f)       // first: fade in
    yAnim.animateTo(100f)          // then: slide down
    yAnim.animateTo(500f, tween(100)) // then: fast slide further
}
```

### Concurrent animations

```kotlin
LaunchedEffect(Unit) {
    launch { alphaAnim.animateTo(1f) }
    launch { yAnim.animateTo(100f) }
}
```

### Interruption

New `animateTo` cancels the ongoing animation automatically and continues from current value and velocity — no jumpiness.

## updateTransition — Multi-Property State Machine

Animate multiple properties simultaneously based on a state enum:

```kotlin
enum class CardState { Collapsed, Expanded }

val transition = updateTransition(cardState, label = "card")

val size by transition.animateDp(label = "size") { state ->
    when (state) { CardState.Collapsed -> 64.dp; CardState.Expanded -> 128.dp }
}
val color by transition.animateColor(label = "color") { state ->
    when (state) { CardState.Collapsed -> Color.Gray; CardState.Expanded -> Color.Red }
}
val borderWidth by transition.animateDp(
    transitionSpec = {
        when { CardState.Expanded isTransitioningTo CardState.Collapsed -> spring(stiffness = 50f); else -> tween(500) }
    },
    label = "border",
) { state ->
    when (state) { CardState.Collapsed -> 1.dp; CardState.Expanded -> 0.dp }
}
```

### Start animation immediately

```kotlin
val state = remember { MutableTransitionState(CardState.Collapsed).apply { targetState = CardState.Expanded } }
val transition = rememberTransition(state, label = "card")
```

### Coordinated child transitions

```kotlin
transition.AnimatedVisibility(visible = { it == CardState.Expanded }) {
    Text("Expanded content")
}
transition.AnimatedContent { targetState ->
    if (targetState == CardState.Expanded) ExpandedView() else CollapsedView()
}
```

### Encapsulate as reusable pattern

```kotlin
private class TransitionData(color: State<Color>, size: State<Dp>) {
    val color by color
    val size by size
}

@Composable
private fun updateCardTransitionData(state: CardState): TransitionData {
    val transition = updateTransition(state, label = "card")
    val color = transition.animateColor(label = "color") { /* ... */ }
    val size = transition.animateDp(label = "size") { /* ... */ }
    return remember(transition) { TransitionData(color, size) }
}
```

## rememberInfiniteTransition

Animations that never stop — shimmer, pulsing indicators, loading spinners:

```kotlin
val infiniteTransition = rememberInfiniteTransition(label = "infinite")
val alpha by infiniteTransition.animateFloat(
    initialValue = 0.3f, targetValue = 1f,
    animationSpec = infiniteRepeatable(tween(800), RepeatMode.Reverse),
    label = "alpha",
)
val color by infiniteTransition.animateColor(
    initialValue = Color.Red, targetValue = Color.Blue,
    animationSpec = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
    label = "color",
)
```

Note: `infiniteRepeatable` animations are not run in Compose tests by default.

## AnimatedVisibility

Animate appearance and disappearance of composables:

```kotlin
AnimatedVisibility(
    visible = isVisible,
    enter = fadeIn() + slideInVertically { -40.dp.roundToPx() } + expandVertically(expandFrom = Alignment.Top),
    exit = slideOutVertically() + shrinkVertically() + fadeOut(),
) {
    Text("Hello")
}
```

### Enter/exit transitions

| Enter | Exit |
|---|---|
| `fadeIn` | `fadeOut` |
| `slideIn` / `slideInHorizontally` / `slideInVertically` | `slideOut` / `slideOutHorizontally` / `slideOutVertically` |
| `scaleIn` | `scaleOut` |
| `expandIn` / `expandHorizontally` / `expandVertically` | `shrinkOut` / `shrinkHorizontally` / `shrinkVertically` |

Combine with `+`: `fadeIn() + slideInVertically()`.

### Per-child animations

```kotlin
AnimatedVisibility(visible = visible, enter = fadeIn(), exit = fadeOut()) {
    Box(Modifier.fillMaxSize().background(Color.DarkGray)) {
        Box(Modifier.animateEnterExit(enter = slideInVertically(), exit = slideOutVertically()))
    }
}
```

Use `EnterTransition.None` / `ExitTransition.None` on parent to let children define their own.

## AnimatedContent

Animate content swaps based on target state:

```kotlin
AnimatedContent(
    targetState = uiState,
    transitionSpec = {
        if (targetState > initialState) {
            slideInVertically { it } + fadeIn() togetherWith slideOutVertically { -it } + fadeOut()
        } else {
            slideInVertically { -it } + fadeIn() togetherWith slideOutVertically { it } + fadeOut()
        }.using(SizeTransform(clip = false))
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

`SizeTransform` controls how size animates between states. `slideIntoContainer` / `slideOutOfContainer` calculate slide distance from content sizes automatically.

## Shared Element Transitions

Seamless transitions between composables that share visual content (e.g., list item -> detail screen). Available in both Jetpack Compose and Compose Multiplatform (since CMP 1.7+).

### Core setup

```kotlin
SharedTransitionLayout {
    AnimatedContent(showDetails, label = "shared") { targetState ->
        if (!targetState) {
            ListItem(
                sharedTransitionScope = this@SharedTransitionLayout,
                animatedVisibilityScope = this@AnimatedContent,
            )
        } else {
            DetailScreen(
                sharedTransitionScope = this@SharedTransitionLayout,
                animatedVisibilityScope = this@AnimatedContent,
            )
        }
    }
}
```

### sharedElement vs sharedBounds

| | `sharedElement` | `sharedBounds` |
|---|---|---|
| Content | Same content in both states | Visually different content |
| Rendering | Only target content rendered during transition | Both entering and exiting content visible |
| Use for | Hero transitions (same image/icon) | Container transforms (card -> full screen) |
| Text | Avoid (use `sharedBounds`) | Preferred (handles font changes) |

### Modifier usage

```kotlin
Image(
    modifier = Modifier.sharedElement(
        rememberSharedContentState(key = "image-$id"),
        animatedVisibilityScope = animatedVisibilityScope,
    )
)

Box(
    modifier = Modifier.sharedBounds(
        rememberSharedContentState(key = "bounds-$id"),
        animatedVisibilityScope = animatedVisibilityScope,
        enter = fadeIn(), exit = fadeOut(),
        resizeMode = SharedTransitionScope.ResizeMode.ScaleToBounds(),
    )
)
```

### Unique keys

```kotlin
data class SharedElementKey(val id: Long, val origin: String, val type: SharedElementType)
enum class SharedElementType { Bounds, Image, Title, Background }
```

### Customize transitions

```kotlin
Modifier.sharedElement(
    state = rememberSharedContentState(key = "image"),
    animatedVisibilityScope = scope,
    boundsTransform = BoundsTransform { initial, target ->
        keyframes {
            durationMillis = 300
            initial at 0 using ArcMode.ArcBelow using FastOutSlowInEasing
            target at 300
        }
    },
)
```

### resizeMode

- `ScaleToBounds()` — scales child layout graphically. Recommended for `Text`.
- `RemeasureToBounds` — re-measures child each frame. Recommended for different aspect ratios.

### With Navigation

Wrap `NavHost` in `SharedTransitionLayout`. Pass both scopes to screens:

```kotlin
SharedTransitionLayout {
    NavHost(navController, startDestination = "list") {
        composable("list") {
            ListScreen(this@SharedTransitionLayout, this@composable)
        }
        composable("detail/{id}") {
            DetailScreen(this@SharedTransitionLayout, this@composable)
        }
    }
}
```

### Async images (Coil)

For full Coil 3 guidance (API choice, caching strategy, SVG, and CMP resource loading), see [Image Loading](image-loading.md).

```kotlin
AsyncImage(
    model = ImageRequest.Builder(LocalPlatformContext.current)
        .data(url)
        .placeholderMemoryCacheKey("image-$id")
        .memoryCacheKey("image-$id")
        .build(),
    modifier = Modifier.sharedElement(
        rememberSharedContentState(key = "image-$id"),
        animatedVisibilityScope = scope,
    ),
)
```

### Overlays and clipping

- `renderInSharedTransitionScopeOverlay()` — keep elements (bottom bar, FAB) on top during transition
- `clipInOverlayDuringTransition` — clip shared element to parent bounds
- `skipToLookaheadSize()` — prevent text reflow during size transitions

### Modifier order

Size modifiers AFTER `sharedElement()`. Inconsistent modifier order between matched elements causes visual jumps.

## Gesture-Driven Animations

### Tap to animate

```kotlin
val offset = remember { Animatable(Offset.Zero, Offset.VectorConverter) }

Box(modifier = Modifier.fillMaxSize().pointerInput(Unit) {
    coroutineScope {
        while (true) {
            awaitPointerEventScope {
                val position = awaitFirstDown().position
                launch { offset.animateTo(position) }
            }
        }
    }
}) {
    Circle(modifier = Modifier.offset { offset.value.toIntOffset() })
}
```

Interruption: tapping during animation cancels current and starts new, maintaining velocity.

### Swipe to dismiss

```kotlin
fun Modifier.swipeToDismiss(onDismissed: () -> Unit) = composed {
    val offsetX = remember { Animatable(0f) }
    pointerInput(Unit) {
        val decay = splineBasedDecay<Float>(this)
        coroutineScope {
            while (true) {
                val velocityTracker = VelocityTracker()
                offsetX.stop()
                awaitPointerEventScope {
                    val pointerId = awaitFirstDown().id
                    horizontalDrag(pointerId) { change ->
                        launch { offsetX.snapTo(offsetX.value + change.positionChange().x) }
                        velocityTracker.addPosition(change.uptimeMillis, change.position)
                    }
                }
                val velocity = velocityTracker.calculateVelocity().x
                val targetOffsetX = decay.calculateTargetValue(offsetX.value, velocity)
                offsetX.updateBounds(-size.width.toFloat(), size.width.toFloat())
                launch {
                    if (targetOffsetX.absoluteValue <= size.width) {
                        offsetX.animateTo(0f, initialVelocity = velocity)
                    } else {
                        offsetX.animateDecay(velocity, decay)
                        onDismissed()
                    }
                }
            }
        }
    }.offset { IntOffset(offsetX.value.roundToInt(), 0) }
}
```

Key patterns: `snapTo` during drag (sync with finger), `animateDecay` for fling, `animateTo(0f)` for snap-back, `VelocityTracker` for fling velocity.

## Canvas and Custom Drawing

### Canvas composable

```kotlin
Canvas(modifier = Modifier.fillMaxSize()) {
    drawCircle(color = Color.Blue, radius = 100f, center = center)
    drawRect(color = Color.Red, topLeft = Offset(50f, 50f), size = Size(200f, 200f))
    drawLine(Color.Green, start = Offset.Zero, end = Offset(size.width, size.height), strokeWidth = 4f)
}
```

### Drawing modifiers

```kotlin
Modifier.drawBehind { drawRect(animatedColor) }
Modifier.drawWithContent { drawContent(); drawCircle(Color.Red, 5.dp.toPx(), center + Offset(64.dp.toPx(), -32.dp.toPx())) }
```

`drawBehind` draws behind composable content. `drawWithContent` draws over (or around) it.

### Brush for gradients

```kotlin
val brush = Brush.linearGradient(colors = listOf(Color.Red, Color.Blue))
Canvas(Modifier.size(200.dp)) { drawRect(brush = brush) }

Brush.radialGradient(colors = listOf(Color.Yellow, Color.Transparent))
Brush.sweepGradient(colors = listOf(Color.Cyan, Color.Magenta, Color.Cyan))
```

### Custom shapes

```kotlin
val triangleShape = GenericShape { size, _ ->
    moveTo(size.width / 2f, 0f)
    lineTo(size.width, size.height)
    lineTo(0f, size.height)
    close()
}
Box(Modifier.size(100.dp).clip(triangleShape).background(Color.Blue))
```

### Animate canvas content

```kotlin
val progress by animateFloatAsState(if (active) 1f else 0f, label = "progress")
Canvas(Modifier.size(200.dp)) {
    drawArc(Color.Blue, startAngle = -90f, sweepAngle = 360f * progress, useCenter = false, style = Stroke(8.dp.toPx()))
}
```

Canvas draws in the Drawing phase — no recomposition needed for visual updates.

## graphicsLayer for Efficient Animation

`graphicsLayer` transforms at the Drawing phase level, avoiding recomposition entirely:

```kotlin
Box(modifier = Modifier.graphicsLayer {
    scaleX = animatedScale.value
    rotationZ = animatedRotation.value
    alpha = animatedAlpha.value
    translationX = animatedOffset.value
    shadowElevation = animatedElevation.value.toPx()
})
```

```kotlin
// BAD: recomposes every frame
Box(Modifier.scale(scaleX))

// GOOD: transforms in draw phase
Box(Modifier.graphicsLayer { scaleX = animatedScale.value })
```

## Performance Optimization

- Use `spring` as default — handles interruption gracefully, physically natural
- Use lambda modifiers: `Modifier.offset { }` instead of `Modifier.offset()` — defers read to Layout phase
- Use `graphicsLayer { }` for all visual-only transforms — runs in Drawing phase only
- Use `drawBehind` for animated colors instead of `Modifier.background()`
- Animations in Drawing phase are cheapest; Layout phase is moderate; Composition phase is most expensive
- `animateContentSize` must be placed BEFORE size modifiers in the modifier chain
- In `AnimatedContent`/`AnimatedVisibility`: always use the lambda parameter (`targetState`), not the outer variable

## Anti-Patterns

| Anti-pattern | Why it hurts | Better replacement |
|---|---|---|
| Animation state in ViewModel (`shakeCount`, `alpha`, `pulsePhase`) | pollutes business state, couples ViewModel to render timing | local composable animation state via `animate*AsState` or `Animatable` |
| `Modifier.scale()`/`.offset()` instead of `graphicsLayer` | triggers recomposition every frame | `Modifier.graphicsLayer { scaleX = ...; translationX = ... }` (Drawing phase only) |
| Animating every keystroke or every state change | UI feels jittery and unstable | animate meaningful transitions only (appear/disappear, navigation, user-initiated) |
| `animateContentSize` after size modifiers | has no effect — size already resolved | place `animateContentSize()` BEFORE `size`/`fillMaxWidth` modifiers |
| Reading outer variable inside `AnimatedContent`/`AnimatedVisibility` | stale value during exit animation | use the lambda parameter (`targetState`) inside the content block |
| Hardcoded `tween`/`snap` everywhere | feels mechanical, handles interruption poorly | prefer `spring` as default; use `tween` only for precise timing needs |
| Animating layout-heavy properties (padding, size) on every frame | expensive Layout phase work each frame | prefer `graphicsLayer` transforms (translation, scale, alpha) |

## When Not to Animate

- Every keystroke-driven total update
- Every loading indicator appearance
- Large section changes that make forms feel unstable
- Repeated list row changes in dense data-entry screens
- Error states that need immediate clarity more than flourish
- Every calculator result on every keystroke
