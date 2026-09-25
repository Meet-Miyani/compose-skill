# Motion

Load this reference when a task adds, changes, or reviews an animation: API choice, shared elements, gesture-driven motion, or per-frame performance.

Contents:

- Which animation API to pick for each situation.
- Animation state stays local; it never enters `UiState`.
- Spec choice: default spring, interruption behavior.
- Per-frame reads: graphicsLayer versus layout-phase modifiers.
- Shared-element transitions live in `shared-elements.md`.
- Gesture-driven patterns: drag, fling, snap-back.
- AnimatedContent identity and size rules.
- Animate only meaningful transitions.
- Red flags and verification gates.

## Which animation API to pick (CB-57)

Pick the smallest API that covers the job. One row per situation; take the first row that holds.

| Situation | API (CB-57) |
|---|---|
| Note row appears or disappears on a boolean | `AnimatedVisibility` |
| One value follows a target (note pin alpha, tag chip color) | Target-state animator (`animate*AsState`) |
| Several values move together from one note-card state | One shared transition (`updateTransition`) |
| A note editor card resizes as children change | `Modifier.animateContentSize` |
| Swapping whole trees (notes list to empty state) | `AnimatedContent` or `Crossfade` |
| Finger-driven or imperative control (swipe to archive) | `Animatable` only |
| Note list insert, remove, or reorder | `Modifier.animateItem` (ANIM-39) |

Prefer target-state APIs. Reach for `Animatable` only when gestures, interruption, or imperative control require it.

Gotcha: an alpha fade keeps the note row composed; `AnimatedVisibility` removes it after exit, so never use a fade when unmounting is required. (CB-59)

*Prevents:* overpowered animation machinery for a one-value job, and invisible rows that still occupy a slot.

## Animation state is local UI state (ANIM-01)

Keep tween progress, shake counters, skeleton alpha, and row-removal phases in the composable, never in `UiState` or the ViewModel. Screen state carries business meaning; visual progress is not business meaning. (ANIM-01)

Animation-only flags stay out of screen `UiState` unless business logic depends on them (brief §8.2). A note-archive swipe offset lives in `Animatable` at the leaf. Whether the note is archived lives in `UiState`.

Gotcha: a skeleton shimmer alpha ticked through `UiState` invalidates every collector on every frame; keep it in a leaf `rememberInfiniteTransition`. (ANIM-01)

*Prevents:* business state polluted with per-frame visuals, and whole-screen invalidation from a shimmer.

## Spec choice (ANIM-06, ANIM-10)

Default to `spring` for interruption-safe motion. A retargeted `spring` keeps velocity and continues smoothly; a retargeted `tween` snaps to a new curve, which reads as a jolt. Use `tween` only when exact duration control is the requirement. (ANIM-06)

Gotcha: a new `animateTo` call cancels the running animation and continues from the current value and velocity, so rapid note-pin toggles never jump. (ANIM-10)

*Prevents:* jarring restarts on every interrupted toggle.

## Per-frame reads: graphicsLayer versus layout-phase modifiers (ANADV-18, CB-63)

Keep frame-rate animated `State` reads inside layout- or draw-block modifiers, never in composition. (CB-63)

| What moves | Modifier | Phase |
|---|---|---|
| Note card scale, rotation, alpha, translation | `graphicsLayer` block | Drawing, cheapest, no recomposition (ANADV-18) |
| Note badge position that shifts layout | Lambda `offset` overload | Layout |
| Animated pin color on a tag chip | `drawBehind` paint | Drawing |

Gotcha: painting an animated tag color with `drawBehind` beats `background`, which re-composes the chip every frame. (ANIM-21)

Gotcha: place `animateContentSize` before size modifiers in the chain; after them it has no effect. (ANIM-22)

*Prevents:* per-frame recomposition of the whole notes list for one chip's color.

Gotcha: children inside `AnimatedVisibility` (or `AnimatedContent`) override the parent transition per child with `Modifier.animateEnterExit`; for fully per-child choreography set the parent `enter`/`exit` to `None`. Source: https://developer.android.com/develop/ui/compose/animation/composables-modifiers (ANIM-50)

*Prevents:* one parent transition flattening every child into the same motion.

## Gesture-driven patterns (ANADV-15)

Drive a swipe-to-archive note row with `Animatable`: `snapTo` during the drag so the row tracks the finger, `animateDecay` for the fling, `animateTo(0f)` for snap-back, and `VelocityTracker` to feed the fling velocity. (ANADV-15)

*Prevents:* a drag that lags the finger and a fling that ignores release velocity.

## AnimatedContent identity and size (CB-60, CB-62, ANIM-52)

Render `AnimatedContent` from its content-lambda target, never from captured outer state, so the outgoing and incoming note branches keep their own identity. (CB-60)

Gotcha: without a content key, a refreshed note payload animates as brand-new content; keep that default only when the payload change itself is the desired transition. (CB-62)

Gotcha: control the size animation between the loading, content, and error shapes with `SizeTransform`. (ANIM-52)

*Prevents:* stale exit branches and refresh flicker on every poll tick.

## Animate only meaningful transitions (ANIM-26)

Gotcha: animating every note-list change produces jitter; animate the pin, the archive swipe, and the detail hero, and let plain state updates apply instantly. (ANIM-26)

*Prevents:* a list that never sits still.

## Red flags

| Thought | Reality |
|---|---|
| "I'll tick the note countdown from the ViewModel or read the clock at the top." | See SKILL.md rules 2–3: `UiState` carries the `Instant`; the leaf reads the clock. |
| "I'll just stash the swipe offset in `UiState` so tests can see it." | No. Rule 3: animation progress is local UI state. Test the archived flag, not the offset. |
| "I'll just key the note rows by index; the list never reorders today." | No. Rule 8: keys come from domain identity, or `animateItem` binds to nothing and silently no-ops. |
| "I'll just fade the detail in with alpha; unmounting does not matter." | No. Rule 2: a fade keeps content composed. Use `AnimatedVisibility` when the tree must leave. |
| "I'll just animate every change so it feels alive." | No. Rule 2: per-frame reads belong in the smallest scope; animating everything invalidates everywhere. |

## Verification

- [ ] No tween progress, shake counter, skeleton alpha, or removal phase on any `UiState`: yes or no.
- [ ] No formatted countdown or clock string on `UiState`; the clock is read at the leaf: yes or no.
- [ ] Every `items(` call carrying `animateItem` also carries a `key` from domain identity: yes or no.
- [ ] `rg -n "Modifier\.(scale|offset)\(" --glob '*.kt' <feature-root>` shows no per-frame visual modifier outside a `graphicsLayer` or lambda-`offset` block: yes or no.
- [ ] `animateContentSize` appears before size modifiers in every chain: yes or no.
- [ ] `AnimatedContent` bodies read the lambda target parameter, never an outer variable: yes or no.

## Cross-skill pointers

- ViewModel test conventions for the archived flag belong to the `compose-feature` skill.
- Navigation-owned destination transitions belong to the `compose-architecture` skill.
- Coil placeholder and cache-key pairing for a shared cover is image-loading work in the `compose-ui` skill; this file states only that the keys must match.
