# Keyboard and Focus

Load this when a note editor field, tag input, or any focusable control needs arrival focus, IME behavior, dismissal, or traversal order.

Contents:

- Minimal focus hooks: which hook each target gets
- Focus on arrival: effect-keyed request plus once-per-visit guard
- Focus-derived side work without body conditionals
- IME actions and keyboard options for the note editor
- Dismiss rules: helper first, never manual clearing
- Traversal order and when to encode explicit edges
- Hardware and directional key handling
- Focus restoration by semantic identity
- Gotchas, red flags, verification

All examples use the Notes app (note editor with title, body, and tags fields).

## Minimal focus hooks

Start from controls that already participate in focus and add only the requested hook (CB-67):

| Situation | Hook |
|---|---|
| Normal note editor text field, tag chip, save button | Nothing extra; the component already participates (CB-67) |
| Note editor title must take focus on arrival or after process death | One requester owned by the editor composable, requested from an effect (CB-67) (CB-68) |
| Tag row reacts visually to focus (border, label) | A focus-change observer for that visual reaction only (CB-67) |
| Custom tag chip surface with click handling but no built-in focus | Focusable plus semantics for the custom surface only (CB-67) |

Never attach a requester, observer, and custom focusable to one control when one hook answers the request (CB-67).

Requesters and observers are runtime UI objects. They live in composition, never in `UiState` and never in the ViewModel (CB-04) (SKL-46).

## Focus on arrival

Request initial or restored focus from an effect keyed on the condition that makes the target present, never from the composable body (CB-68) (CB-73).

```kotlin
val titleRequester = remember { FocusRequester() }
var arrived by remember { mutableStateOf(false) }
LaunchedEffect(noteId) {
    if (!arrived) {
        titleRequester.requestFocus()
        arrived = true
    }
}
```

The `arrived` flag is UI-local state: it guards one visit, it is not business state, and it never enters `UiState` (SKL-46).

Key late-appearing targets to the condition that makes them present (dialog open, tag sheet expanded), not to a constant key (CB-73).

In a lazy notes list, keep one requester per stable item id and request only after composition, never during item composition (CB-68).

Inside animated content, use the lambda target consistently for identity, test tags, requester ownership, and the effect key, never the outer captured value (CB-68).

## Focus-derived side work

Drive focus-derived side work with a keyed effect or a snapshot flow, never with a bare conditional in the composable body (CB-23).

A tag suggestion fetch that reacts to the tags field gaining focus belongs in an effect keyed on the focus state, not in an `if (focused)` branch that launches work during composition (CB-23).

## IME actions and keyboard options

Match the keyboard to the note editor field: text entry for the title and body, the matching entry variant for the tags field. Confirm the variant names in the current text-field guide before relying on them (https://developer.android.com/develop/ui/compose/text/user-input).

Give every editor field the IME action its position promises: move-to-next while more fields follow, done-action on the last field (`ImeAction.Next`, `ImeAction.Done` in `KeyboardOptions`; https://developer.android.com/reference/kotlin/androidx/compose/foundation/text/KeyboardOptions).

A next-action moves focus to the next editor field; a done-action dismisses the keyboard and submits the note edit, never both at once and never neither. The framework default already moves focus on Next and closes the keyboard on Done; custom routing goes in `KeyboardActions` (https://developer.android.com/reference/kotlin/androidx/compose/foundation/text/KeyboardActions).

## Dismiss rules

Dismiss from the submit or done handler with the keyboard controller's hide call read in composition, never by manually clearing focus (`LocalSoftwareKeyboardController` plus `hide()`; https://developer.android.com/reference/kotlin/androidx/compose/ui/platform/SoftwareKeyboardController).

Never issue a focus request inside an effect for dismissal: dismissal is a hide call from the event handler, not a focus move (same reference).

Keep typed note text intact across dismissal; dismissing the keyboard never clears the title, body, or tags (SKILL.md rule 7: never clear existing content during a transition).

## Traversal order

Keep default spatial traversal and encode only concrete wrong edges, jumps, or traps with focus properties; dense hard-coded link graphs go stale on the first layout change (CB-69).

A note editor column (title, body, tags, save) keeps default order with no explicit links; an explicit edge is added only when testing shows focus jumping over the tags field or trapping inside the tag row (CB-69).

The editor reads top to bottom in a logical order that matches the visual order (CB-69).

## Hardware and directional keys

Handle keys only for behavior beyond normal click or traversal (CB-70).

Consume exactly the handled key event and let the rest propagate; over-consuming breaks traversal for the whole editor (CB-70).

Throttle rapid directional work at its expensive owner (the tag strip handling repeated moves) rather than screen-wide (CB-70).

## Focus restoration

Restore focus by semantic identity after refresh: retain the focused note or tag id when it still exists, otherwise fall back deterministically to the editor title (CB-71).

A notes list refresh that reorders rows returns focus to the same note id, never to the same positional index (CB-71).

## Gotchas

- Requesting focus from the composable body re-fires on every recomposition; the effect key is what makes it once-per-arrival (CB-73).
- A requester stored in `UiState` leaks a runtime object into business state and breaks restoration (CB-04).
- A bare `if (focused)` branch launching tag work runs during composition and repeats unpredictably (CB-23).
- Hard-coded traversal for the whole editor rots when the tag row wraps; encode only the broken edge (CB-69).
- Consuming unhandled key events traps keyboard users inside the tag row (CB-70).
- Restoring focus by list position lands on the wrong note after an insert (CB-71).
- A done-action with no dismiss leaves the keyboard covering the saved note (https://developer.android.com/reference/kotlin/androidx/compose/ui/platform/SoftwareKeyboardController).

## Red flags

| Thought | Reality |
|---|---|
| "I'll stash the title `FocusRequester` in `UiState` so it survives rotation." | No. Rule 1: runtime objects stay in composition; the Screen takes state plus callbacks, never requesters. |
| "I'll request focus right in the body so it happens immediately." | No. Rule 2: the body re-executes on every invalidation; side work belongs in a keyed effect. |
| "I'll wipe the editor content to force the keyboard closed on save." | No. Rule 7: never clear existing content during a transition; dismiss with the helper and keep the text. |
| "I'll tint the focused tag with a hardcoded highlight; tokens lack it." | No. Rule 5: colors come from theme tokens only; name the missing token as an open gap. |
| "I'll hardcode the tag hint string inline; translation comes later." | No. Rule 9: every user-facing string is a resource in every locale before done. |
| "I'll restore editor focus by row index; the list rarely reorders." | No. Rule 8: identity comes from domain id with a stable key, never the index. |

## Verification

- [ ] `rg -n "FocusRequester|focusRequester|FocusManager|keyboardController" --glob '*.kt' <feature-root>` shows requesters created only in composables, never in `*ViewModel.kt` or `*Contract.kt`: yes or no.
- [ ] No focus request call sits in a composable body; every request sits in an effect keyed on the presence condition: yes or no.
- [ ] The once-per-visit guard is UI-local (`remember`, not `UiState`): yes or no.
- [ ] Every editor field declares the keyboard variant and IME action its position promises; the last field dismisses on done: yes or no.
- [ ] Dismissal uses the keyboard helper from the event handler; no `clearFocus()` dismissal and no focus request for dismissal: yes or no.
- [ ] No hard-coded traversal graph except named wrong edges, jumps, or traps: yes or no.
- [ ] Key handlers consume only handled events: yes or no.
- [ ] Post-refresh focus resolves by note or tag id with a deterministic fallback: yes or no.

## Where this stops

Insets and keyboard-overlap padding are not covered here; this file covers focus and dismissal only. Shared editor state across destinations belongs to the `compose-architecture` skill. Desktop and web keyboard specifics belong to the `compose-platform` skill.
