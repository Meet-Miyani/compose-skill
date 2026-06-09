# Accessibility

## Content Descriptions

Every `Image` and `Icon` composable must have an explicit `contentDescription`:

- **Decorative** (no information conveyed): `contentDescription = null`
- **Meaningful** (conveys information): localized string via `stringResource()`

```kotlin
// Decorative — purely visual, screen reader skips it
Icon(Icons.Default.Star, contentDescription = null)

// Meaningful — screen reader announces it
Image(
    painter = painterResource(Res.drawable.profile_avatar),
    contentDescription = stringResource(Res.string.user_avatar_description)
)
```

Flag any `Image` with a non-obvious resource name and `contentDescription = null` that lacks a comment explaining why it is decorative.

## Semantics API

Use `Modifier.semantics { }` to add or override accessibility information.

| Property | Purpose | Example values |
|---|---|---|
| `contentDescription` | Override screen reader announcement | `"Profile picture of $name"` |
| `role` | Declare interactive role | `Role.Button`, `Role.Image`, `Role.Switch`, `Role.Tab`, `Role.RadioButton`, `Role.Checkbox` |
| `stateDescription` | Describe current state | `"Expanded"`, `"Selected"`, `"3 of 5"` |
| `heading` | Mark as section heading | `heading()` |

```kotlin
Box(
    modifier = Modifier.semantics {
        contentDescription = "Profile picture of ${user.name}"
        role = Role.Image
    }
)
```

Prefer built-in Material components (`Button`, `Switch`, `Checkbox`) over manual `role` assignment — they include correct semantics automatically.

## Grouping and Overriding Semantics

### mergeDescendants

Groups a composable's children into a single screen reader announcement. Use when children together form one logical unit.

```kotlin
// GOOD — screen reader announces "4.5 stars, 128 reviews" as one item
Row(modifier = Modifier.semantics(mergeDescendants = true) { }) {
    Icon(Icons.Default.Star, contentDescription = null)
    Text("4.5 stars")
    Text("(128 reviews)")
}
```

```kotlin
// BAD — screen reader stops on each child separately, fragmenting the meaning
Row {
    Icon(Icons.Default.Star, contentDescription = "Star icon")
    Text("4.5 stars")
    Text("(128 reviews)")
}
```

### clearAndSetSemantics

Replaces all auto-generated and child semantics with a single custom description. Use when the auto-generated text is verbose or misleading.

```kotlin
Row(modifier = Modifier.clearAndSetSemantics {
    contentDescription = "Rating: 4.5 stars from 128 reviews"
}) {
    StarRating(4.5f)
    Text("(128 reviews)")
}
```

| Need | Use |
|---|---|
| Group children into one announcement, keep their text | `semantics(mergeDescendants = true)` |
| Replace all child semantics with a custom string | `clearAndSetSemantics { }` |

## Touch Targets

Minimum interactive size: **48 x 48 dp**.

- Use `Modifier.minimumInteractiveComponentSize()` on custom interactive elements to enforce this automatically.
- Material components (`Button`, `IconButton`, `Switch`, etc.) handle this internally — do not add redundant padding.

```kotlin
// Custom clickable element — enforce minimum touch target
Box(
    modifier = Modifier
        .minimumInteractiveComponentSize()
        .clickable { onAction() }
) {
    Icon(Icons.Default.Add, contentDescription = "Add item")
}
```

## Color and Contrast

WCAG AA minimum contrast ratios:

| Text type | Minimum ratio |
|---|---|
| Normal text (<18sp) | 4.5 : 1 |
| Large text (18sp+ or 14sp bold+) | 3 : 1 |

Never use color as the **only** way to convey information. Always pair with an icon, text label, or pattern.

```kotlin
// BAD — only color differentiates status
Box(modifier = Modifier.background(if (isOnline) Color.Green else Color.Red))

// GOOD — icon + text + color
Row {
    Icon(
        imageVector = if (isOnline) Icons.Default.CheckCircle else Icons.Default.Cancel,
        contentDescription = null,
    )
    Text(if (isOnline) "Online" else "Offline")
}
```

Use theme tokens (`MaterialTheme.colorScheme`) rather than hardcoded colors — theme tokens are designed to meet contrast requirements across light/dark modes.

## Custom Interactive Elements

When using `Modifier.clickable` on a non-Button composable, add semantic role and click label:

```kotlin
Card(
    modifier = Modifier
        .clickable(onClickLabel = "Open book details") { onBookClick(book.id) }
        .semantics { role = Role.Button }
) {
    Text(book.title)
}
```

Prefer `Button` / `IconButton` / `TextButton` over custom clickable elements when possible — they include correct semantics, touch targets, and visual feedback out of the box.

## Custom Accessibility Actions

For composables with multiple actions (e.g., a list item with favorite, share, delete), expose named accessibility actions so screen reader users can discover and invoke them without navigating to individual buttons:

```kotlin
Modifier.semantics {
    customActions = listOf(
        CustomAccessibilityAction("Add to favorites") { onFavorite(); true },
        CustomAccessibilityAction("Share") { onShare(); true },
    )
}
```

The lambda returns `true` if the action was handled successfully.

## MVI Integration

Accessibility does not change the MVI architecture. Key placement rules:

| Concern | Where | Why |
|---|---|---|
| Semantic descriptions (`contentDescription`, `stateDescription`) | Screen / Leaf composables | These are UI-layer concerns — resolve from state close to rendering |
| Semantic keys/enums for dynamic descriptions | `State` data class | e.g., `statusLabel: StringKey` — the UI resolves to a localized string |
| `Modifier.semantics` | Composable `modifier` chains | Applied in the UI layer, never in ViewModel |
| Accessibility-triggered actions (e.g., custom action callbacks) | `onEvent` callbacks → ViewModel | Same as any user interaction — goes through the event pipeline |

Keep accessibility descriptions in the **UI layer**, not in state. State holds semantic keys (enums, string resource keys); the Screen/Leaf composable resolves them to localized strings via `stringResource()`.

## Do / Don't

### Do

- Provide `contentDescription` for every meaningful `Image` and `Icon`
- Use `mergeDescendants` for logically grouped content
- Use `clearAndSetSemantics` when auto-generated text is misleading
- Enforce 48dp minimum touch targets on custom interactive elements
- Pair color with icons/text for status indicators
- Use `MaterialTheme.colorScheme` tokens for contrast-safe colors
- Test with a screen reader on each target platform

### Don't

- Leave `contentDescription = null` on meaningful images without a comment
- Apply `role` manually when a Material component already provides it
- Add extra padding on Material components that already meet touch target requirements
- Rely on color alone to communicate state changes
- Put localized accessibility strings in ViewModel state — use semantic keys and resolve in UI
- Hardcode accessibility text — use `stringResource()` for localization
