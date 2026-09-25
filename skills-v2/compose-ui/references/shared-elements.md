# Shared Elements

Load this when a task adds a shared-element transition between two destinations: element choice, keys, modifier order, or overlay chrome.

Contents: element choice, shared keys, modifier order, overlay and resize hooks.

## Element choice (ANADV-03)

Use shared elements for the note list to note detail transition: the tapped note cover travels instead of crossfading.

| Situation | Choice (ANADV-03) |
|---|---|
| Same cover art on both screens | `sharedElement` hero |
| Card morphing into a different detail layout | `sharedBounds` container transform |
| Note title text that changes size | `sharedBounds`, never `sharedElement` |

## Keys (ANADV-05)

Build each shared key from domain identity plus origin and type, so two notes never collide on one key. A note cover key reads as note id plus list origin plus cover type. (ANADV-05)

*Prevents:* key collisions that teleport the wrong cover.

## Modifier order and overlay (ANADV-11, ANADV-10, ANADV-07)

Size modifiers go after `sharedElement`; mismatched modifier order between the matched pair causes visual jumps. (ANADV-11)

Gotcha: pick `ScaleToBounds` for note title text and remeasure-based resizing for covers with different aspect ratios; confirm against current official docs before relying on either default. (ANADV-07)

Gotcha: keep chrome (note list bottom bar, detail FAB) above the transition with the shared-transition overlay hook, clip the element to parent bounds when it bleeds, and freeze title measurement so text does not reflow mid-flight; confirm each hook name against current official docs. (ANADV-10)

*Prevents:* chrome sliding under the hero.

## Verification

- [ ] Shared-element keys embed domain identity; matched pairs use identical modifier order: yes or no.
- [ ] Shared-transition overlay hooks and resize-mode choices verified against current official docs: yes or no.
