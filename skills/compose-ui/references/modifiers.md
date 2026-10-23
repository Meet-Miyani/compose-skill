# Modifiers

Load this reference when writing or reviewing a `Modifier` chain, a custom modifier, or a per-frame state read inside a modifier.

Contents:

- Order means wrapper position, and why it decides hit, paint, and size.
- Which orders break: background and padding, clip and fill, layer transforms.
- Component chains: the caller modifier goes first.
- Chain formatting and where conditionals live.
- Lambda (deferred-read) modifiers for fast-changing values.
- Never caching a chain in `remember` for speed.
- Custom `Modifier.Node` rules: when a node earns its place.
- What a node must never do.
- Red flags and verification gates.

## Order means wrapper position (SKY-100)

Read every chain top to bottom as nested wrappers. The first element is the outermost wrapper; the last sits closest to the content. (SKY-100)

Each position resolves hit area, paint, clip masking, padding subtraction, and size constraints for everything below it. Moving one call changes which pixels and which taps it affects. (SKY-100)

A note tag chip shows the effect directly: padding above a tap handler shrinks the tap area to the text, while padding below it keeps the padded area tappable. (SKY-100)

*Prevents:* tap areas, fills, and sizes that silently follow the wrong element.

## Which orders break

Default to background before padding on a filled note card with an internal inset. The fill then paints under the inset. Reverse the pair only when the fill must stay inside the margin. (SKY-101)

Gotcha: padding before background shrinks the painted fill to the padded box, so a note card loses its full-bleed fill. (SKY-101)

Place clip before background, or collapse both into the single shaped-background call, so rounded corners actually mask the fill. Background before clip lets square corners leak past the clip. (SKY-103)

Hoist layer transforms near the chain top for whole-unit fades of a note card. Layering never moves hit-test geometry: a faded card still taps where it was laid out. (SKY-104)

Per-frame visual moves follow the graphicsLayer-versus-layout-phase choice (SKY-38); this file covers only the chain contract, not the table. (SKY-38)

*Prevents:* square fills behind round cards, fades applied to half a row, and taps that drift from their visuals.

## Component chains: the caller modifier goes first (CB-47, CB-48)

Declare a modifier parameter defaulting to empty after the required parameters on every composable that emits layout. Apply it to the root layout so callers can place the component. (CB-47)

```kotlin
fun NoteTagRow(noteId: String, modifier: Modifier = Modifier)
```

Order the root chain with the caller modifier first, then intrinsic identity modifiers. Push positioning, padding, and general sizing decisions out to the caller. (CB-48)

```kotlin
NoteTagRow(noteId = id, modifier = Modifier.fillMaxWidth())
```

*Prevents:* components that cannot be placed, spaced, or sized by their callers.

## Chain formatting and conditionals (CB-49, CB-50)

Build a modifier as one fluent expression: one or two calls inline, three or more calls one per line. Use a conditional `then` segment for optional parts. (CB-49)

Hoist a condition outside a layout only when the layout holds no other content or visible container role. Keep the condition inside when the container carries semantics, layout arguments, siblings, or content in both branches. (CB-50)

Gotcha: hoisting a pin-state branch above a note row that also holds semantics drops the container role in one branch. (CB-50)

*Prevents:* chains nobody can diff, and branches that silently drop semantics or siblings.

## Lambda modifiers for fast-changing values (SKY-38, CB-37, CB-38)

Carry frame-rate values across composables as `State` objects or zero-arg provider lambdas. Read them inside the block-form layout or draw modifier at the leaf that renders them. (CB-38)

A state read invalidates the phase that reads it, so a composition-phase read re-executes the scope while a layout- or draw-phase read does not. Never write observable state from a phase that invalidates the current or an earlier phase. (CB-37)

Keep the read in composition only when it decides which composables exist, such as choosing between the notes list and the empty state. Leave the simpler value form alone when evidence shows recomposition is not the bottleneck. (CB-38, CB-43)

Gotcha: passing the read value down re-executes the parent on every tick; pass the `State` or lambda and read it at the leaf. (SKY-38, SKILL.md rule 2)

*Prevents:* per-frame parent invalidation from a value only one leaf renders.

## Never cache a chain for speed (SKY-105)

Never hoist a modifier chain into `remember` for performance without a frame-timing regression pointing at it. The framework already interns equal chains, so the cache buys nothing in the common case. (SKY-105)

*Prevents:* stale chains defended as optimization, hiding the real read-placement defect.

## Custom Modifier.Node: when a node earns its place (SKY-106, SKY-108)

Author every new custom modifier on the persistent node system. The legacy factory opens a fresh unskippable scope per composition. (SKY-106)

Build a custom node only when no composition of existing modifiers expresses the behavior, such as a note-editor gesture that needs combined draw, layout, and pointer handling in one unit. Otherwise compose existing modifiers. (SKY-106, SKILL.md rule 6)

Attach behavior through one focused node interface per concern. Past about three interfaces, compose wider modifiers from delegated children instead of growing one node. (SKY-108)

*Prevents:* unskippable scopes on every frame, and single nodes that merge unrelated concerns.

## What a node must never do

Declare every node element as a data class. Synthesized equality drives the diff; a plain class silently freezes parameters. (SKY-107)

Gotcha: a plain-class note-highlight element keeps its first color forever because the diff never fires. (SKY-107)

Run node async work on the built-in attach-bound scope. Mutate state through `update`. Release every manual resource on detach. (SKY-109)

Never retain composition-scoped objects inside a node. Accept plain parameters, plus composition-local reads through the consumer interface. (SKY-110)

Take manual control of invalidation only with the auto flag off plus an explicit draw, measure, or placement call for coroutine-driven node mutations. (SKY-111)

Read composition locals inside draw or layout node callbacks so theme changes redraw without recomposing. Prefer the local placement notifier over the global one for size reactions. (SKY-112)

Gotcha: reading the note theme token in the element constructor instead of the draw callback forces a full recompose on every theme change. (SKY-112)

*Prevents:* frozen parameters, leaked coroutines, retained composition objects, and theme changes that recompose instead of redraw.

## Red flags

| Thought | Reality |
|---|---|
| "I'll put padding above `clickable` so the note row looks airy; taps will follow." | No. Rule 2: position decides the hit area. Padding above the handler shrinks taps to the text. |
| "I'll paint background after clip; the order is cosmetic." | No. Rule 6: copy the condition and the order with the component. Clip-then-fill is part of the contract. |
| "I'll read the scroll offset at the top and pass the value into the modifier." | See SKILL.md rule 2: pass the `State` or lambda; read it in the block-form modifier at the leaf (detail above). |
| "I'll cache this chain in `remember` to stop the recomposition." | See SKILL.md rule 2 (iron law): caching never changes which scope the read invalidates. Move the read down. |
| "I'll write a custom node for this note badge; it is just padding plus fill." | No. Rule 6: reuse before writing. Compose existing modifiers unless no composition expresses it. |
| "I'll use a plain class for the node element; equality does not matter here." | No. Rule 4: equality drives skipping and diffing. A plain class freezes parameters. |
| "I'll hold the composable scope in the node so I can call back." | No. Rule 1: state and callbacks flow Route to Screen to leaf. Nodes take plain parameters. |
| "I'll hardcode this scrim color; the tokens lack it." | No. Rule 5: tokens only in feature code. Name the missing token as an open gap. |

## Verification

- [ ] `rg -n "Modifier" --glob '*.kt' <feature-root>` — every chain reads top to bottom as outer to inner with no unexplained reorder: yes or no.
- [ ] Every filled note card paints background before padding unless the fill must stay inside the margin: yes or no.
- [ ] Every rounded fill clips before painting or uses the single shaped-background call: yes or no.
- [ ] Layer transforms sit near the chain top and no tap geometry depends on them: yes or no.
- [ ] No `remember` wrapping a modifier chain for performance without a linked frame-timing regression: yes or no.
- [ ] Every composable that emits layout declares `modifier: Modifier = Modifier` after required parameters and applies it to the root layout: yes or no.
- [ ] Every root chain places the caller modifier first: yes or no.
- [ ] Fast-changing values cross composables as `State` or provider lambdas and are read inside block-form modifiers at the rendering leaf: yes or no.
- [ ] Every custom modifier is a node-system element declared as a data class with at most about three interfaces: yes or no.
- [ ] No node retains composition-scoped objects and every manual resource releases on detach: yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
