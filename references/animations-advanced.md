# Animations — Advanced Patterns

Shared element transitions, gesture-driven animations, Canvas drawing, and graphicsLayer optimization. For core animation APIs (animate*AsState, Animatable, updateTransition, AnimatedVisibility, AnimatedContent, AnimationSpec) and the animation API decision table, see [animations.md](animations.md).

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

`Modifier.drawBehind { }` draws behind child content; `Modifier.drawWithContent { drawContent(); … }` draws over or around it.

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
