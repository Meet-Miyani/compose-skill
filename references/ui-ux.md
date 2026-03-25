# UI/UX Patterns for Utility Apps

## Core Principles

Utility apps are trust products. The UI must feel: stable, immediate, precise, reversible, non-destructive.

## Loading States

### Decision Rule

| Situation | Best default |
|---|---|
| First load, known result card layout | skeleton |
| Small inline refresh of one section | keep content + small inline indicator |
| Whole-screen blocking startup with no known structure | spinner, but rare |
| Recalculating quote while old result exists | keep old result + "updating" affordance |
| Empty but idle state | empty-state hint, not spinner |

### Default Recommendation

- **Skeleton**: default for known layout with missing data
- **Subtle shimmer over skeleton**: optional polish, not the primary strategy
- **Spinner**: only for small unknown-layout operations or blocking tasks with no stable placeholder shape

### Stable Layout During Loading

Never wipe content during refresh. Never cause height jumps, flicker, or lost context.

## Inline Validation

Default behavior:

- Validate format/range as user edits for fields where feedback is obvious
- Avoid screaming errors on untouched fields
- Show errors inline, next to the field they belong to
- Do not collapse layout when error appears/disappears
- Disable submit when impossible, but also explain why

### Good inline validation behavior

- Field keeps its value during error
- Error appears under field
- Submit remains disabled only when necessary
- No modal dialog for every invalid keystroke
- No full-form red error wall

## Disabled States

Disabled is fine only when:

- The reason is obvious from nearby context
- The screen is still readable
- User input is preserved

Bad disabled state: button disabled with no visible reason, form cleared during loading, entire screen grayed out for a small refresh.

## Preserving User Input

Non-negotiable rules:

- **Never clear edited fields on refresh**
- **Never clear last good result while fetching a new one**
- **Never wipe the screen because one request failed**

## Progressive Disclosure

For dense forms:

- Hide advanced options by default
- Keep main path obvious
- Reveal secondary controls progressively
- Do not split trivial forms into too many steps

## Partial Results

Good pattern:

- Compute instant local estimate from current draft
- Show local estimate immediately
- Fetch remote refinement in background
- Keep old refined quote until new one arrives
- Label refreshed state clearly

## Perceived Performance

For form-heavy screens:

- Apply local field state changes instantly
- Recalculate cheap deterministic outputs immediately
- Debounce only expensive async work
- Keep layout stable
- Animate only meaningful content changes

## Accessibility

- Error messages must be text, not color only
- Loading indicators should not hide context unnecessarily
- Support logical keyboard/focus order
- Avoid rapid flashing/sweeping shimmer
- Keep controls large enough for data-entry reliability

## Code Examples

### BAD: disappearing content and layout jumps

```kotlin
@Composable
fun QuoteSection(quote: QuoteUi?, isLoading: Boolean) {
    if (isLoading) {
        CircularProgressIndicator()
    } else if (quote != null) {
        QuoteContent(quote = quote, refreshing = false)
    }
}
```

### GOOD: stable layout with old content preserved

```kotlin
@Composable
fun QuoteSection(quote: QuoteUi?, isLoading: Boolean) {
    ResultCardSlot {
        when {
            quote != null -> QuoteContent(quote = quote, refreshing = isLoading)
            isLoading -> QuoteCardSkeleton()
            else -> QuoteEmptyState()
        }
    }
}
```

### GOOD: stable placeholder slot

```kotlin
@Composable
fun ResultCardSlot(content: @Composable BoxScope.() -> Unit) {
    Box(modifier = Modifier.fillMaxWidth().heightIn(min = 180.dp)) { content() }
}
```

### GOOD: skeleton with shimmer

```kotlin
@Composable
fun QuoteCardSkeleton(modifier: Modifier = Modifier) {
    val alpha by rememberInfiniteTransition(label = "skeleton").animateFloat(
        initialValue = 0.35f,
        targetValue = 0.60f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 800),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "alpha",
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 180.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = alpha))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.fillMaxWidth(0.4f).height(20.dp).clip(RoundedCornerShape(8.dp)).background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)))
        Box(Modifier.fillMaxWidth().height(36.dp).clip(RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)))
        Box(Modifier.fillMaxWidth(0.7f).height(20.dp).clip(RoundedCornerShape(8.dp)).background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)))
    }
}
```
