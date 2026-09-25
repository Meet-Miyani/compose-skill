# Adaptive and Insets

Load this when a notes screen must change panes with window size or draw edge to edge behind system bars.

Contents:

- Branching on the size class at the pane level
- List-detail composition and the call-site gate
- Multi-pane hosting through a scene strategy
- Edge-to-edge with insets applied exactly once
- Keyboard and IME handling without double padding
- Layout-choice decisions for adaptive notes UI
- Gotchas
- Red flags
- Verification

## Branch on the size class at the pane level

1. **Branch single versus dual pane from the size class the pane receives; never read a constraint box inside a leaf or a list item to decide panes.** A per-item constraint read re-runs measure work per row, and rows can disagree with each other. *Prevents:* per-row layout churn and split decisions inside one notes list. (SKY-69; F-04)
2. **Keep the branch at the pane boundary, not in the detail leaf.** The notes detail leaf renders the note it is given; it never asks how wide the window is. *Prevents:* a detail leaf that shows pane chrome in the wrong host. (SKY-69; brief §7.7)

## List-detail composition and the call-site gate

3. **Compose one note detail body, hosted two ways: a sheet destination at Compact, a side pane on wider sizes.** The body stays identical; only the host changes. *Prevents:* two detail implementations drifting apart. (F-04; brief §7.7)
4. **Copy the call-site condition together with any pane component.** A pane divider that is correct beside a notes list is a stray edge line inside a note sheet, so the gate travels with the component:

```kotlin
if (presentedInBottomSheet) { Box(modifier) { body() } }
else { ListDetailPaneSplit(modifier, content = body) }
```

*Prevents:* precedent-gated UI breaking in its new home. (F-04)

## Multi-pane hosting through a scene strategy

5. **Implement multi-pane through a Navigation 3 scene strategy; never mount the pane scaffolds directly.** Direct-mounted panes bypass back-stack behavior, so Back, deep link, and restore cannot reach them consistently. *Prevents:* panes unreachable after restore. (AND-72; brief §7.7)
6. **For M3 adaptive mechanics, the android/skills adaptive skill goes deeper, if installed.** This file stands alone without it; the rules above are the whole kit contract.

## Edge-to-edge with insets applied exactly once

7. **Apply WindowInsets exactly once per screen: either the Scaffold inner padding or manual padding, never both.** Double application stacks system-bar offsets twice. *Prevents:* notes content pushed twice as far from the bars as intended. (AND-21)
8. **Feed the Scaffold inner padding into the lazy contentPadding parameter, never into Modifier padding on the notes list container.** Padding the container clips the draw-behind background the list should keep. *Prevents:* a notes list that loses edge-to-edge drawing. (AND-22)
9. **Chain consumeWindowInsets after the padding that applies the inner padding, so descendants do not re-consume the same insets.** *Prevents:* inner notes sections padding twice against one bar. (AND-23)
10. **Inset each notes screen itself; never pad the suite-scaffold parent.** Adaptive suite scaffolds never forward padding values, so parent padding never reaches the screens. *Prevents:* insets applied nowhere while looking applied. (AND-27)

## Keyboard and IME handling without double padding

11. **Declare adjustResize in the manifest for keyboard activities; never the deprecated runtime resize constant.** *Prevents:* a note editor field hidden behind the keyboard. (AND-20)
12. **Place imePadding before verticalScroll in the modifier chain, or the keyboard still covers the note field.** *Prevents:* an editor that scrolls but never clears the keyboard. (AND-24)
13. **Never stack imePadding over contentWindowInsets that already carry IME insets; prefer the fitInside IME ruler there, after confirming the ruler name in the current edge-to-edge docs and the version in `libs.versions.toml`.** Two IME applications pad the note editor twice whenever the keyboard opens. *Prevents:* the IME double-padding trap. (AND-25)
14. **Prefer fitInside with the IME ruler over bare imePadding, after confirming the ruler name in the current edge-to-edge docs and the version in `libs.versions.toml`.** It trims jank from unconsumed upstream insets on the way up. *Prevents:* a jumpy note editor on keyboard transitions. (AND-26)

## Layout-choice decisions for adaptive notes UI

| Situation | Choice |
|---|---|
| Notes list must fill wider windows with more columns | Convert the column to a grid with adaptive cells at a legible minimum width (AND-75) |
| Screen structure versus a small wrapping tag group | Screen structure belongs to a grid-style layout; a small wrapping tag chip group belongs to a flow-style layout (AND-77) |
| Large homogeneous notes data versus screen structure | Lazy grids keep large homogeneous data; the non-lazy grid owns screen structure, so confirm its loading behavior in current docs before aiming it at a long notes feed (AND-76) |

## Gotchas

- The host Activity manages icon contrast itself, so manual light-bar flags belong only to the compat path. (AND-28)
- Whenever a bottom bar must reach the screen edge, confirm the navigation-bar contrast-enforcement flag in current docs before changing it. (AND-29)
- Keep status icons legible with a translucent gradient scrim sized from the status-bars inset, not a solid block. (AND-31)
- A media-query integration flag is set once in the Application; without it queries never fire. (AND-78)
- Read window width and height through the derived media-query form so rapid resizes ride derived state instead of recomposing per pixel. (AND-79)
- Confirm supporting-pane back behavior against the current adaptive library; if Back skips the expected dismiss, the pane needs an explicit pop-until-destination-change setting. (AND-84)
- Platform safe-area specifics, including any iOS keyboard overlap behavior, belong to the `compose-platform` skill. (XPLAT-15; XPLAT-16)

## Red flags

| Thought | Reality |
|---|---|
| "I'll read a constraint box in each notes row to pick single or dual pane; it is local." | No. Rule 10: the branch lives at the pane boundary from the received size class, never in a leaf or item scope. |
| "I'll mount the notes list and detail side by side directly; faster than a scene." | No. Rule 10: panes mount through the scene strategy so Back, deep link, and restore reach them. Direct-mounted panes break restore. |
| "I'll copy this pane divider; the sheet gate was specific to that screen." | No. Rule 6: copy the condition with the component, or the note sheet gets a stray edge line. |
| "I'll pad the Scaffold and the notes screen; safer twice." | No. Rule 10: insets apply exactly once per screen, either inner padding or manual padding. |
| "I'll stack imePadding over the content insets that already carry IME; more room." | No. Rule 10: one IME application only, preferably the fitInside IME ruler. |
| "I'll pad the suite-scaffold parent so every notes destination inherits it." | No. Rule 10: suite scaffolds never forward padding values, so each screen insets itself. |
| "I'll put the animated inset offset in the ViewModel so both panes share it." | No. Rule 2: fast-changing values are read in the smallest scope that renders them, never hoisted. |

## Verification

- [ ] `rg -n "BoxWithConstraints" --glob '*.kt' <feature-root>` shows no pane-branch reads inside leaf or item scopes: yes or no.
- [ ] The notes detail leaf takes the note plus callbacks and never reads window size: yes or no.
- [ ] Every pane component copied from a precedent carries its call-site gate: yes or no.
- [ ] `rg -n "innerPadding|WindowInsets|consumeWindowInsets" --glob '*.kt' <feature-root>` shows exactly one application per screen: yes or no.
- [ ] Scaffold inner padding flows into `contentPadding`, never into Modifier padding on the list container: yes or no.
- [ ] `consumeWindowInsets` is chained after the padding that applies inner padding: yes or no.
- [ ] No screen pads the suite-scaffold parent: yes or no.
- [ ] `rg -n "imePadding" --glob '*.kt' <feature-root>` shows at most one IME application per chain, placed before scrolling, and no chain stacks it over IME-carrying content insets: yes or no.
- [ ] The manifest declares adjustResize for keyboard activities: yes or no.
- [ ] Every Activity, every text field, the first and last notes list items, and FAB clearance were checked edge to edge, followed by a Gradle build: yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
