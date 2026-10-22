# Edge-to-Edge and Insets

Load this when a notes screen draws edge to edge behind system bars or must clear the keyboard.

Contents:

- Edge-to-edge with insets applied exactly once
- Keyboard and IME handling without double padding
- Gotchas
- Red flags
- Verification

## Edge-to-edge with insets applied exactly once

1. **Apply WindowInsets exactly once per screen: either the Scaffold inner padding or manual padding, never both.** Double application stacks system-bar offsets twice. *Prevents:* notes content pushed twice as far from the bars as intended. (AND-21)
2. **Feed the Scaffold inner padding into the lazy contentPadding parameter, never into Modifier padding on the notes list container.** Padding the container clips the draw-behind background the list should keep. *Prevents:* a notes list that loses edge-to-edge drawing. (AND-22)
3. **Chain consumeWindowInsets after the padding that applies the inner padding, so descendants do not re-consume the same insets.** *Prevents:* inner notes sections padding twice against one bar. (AND-23)
4. **Inset each notes screen itself; never pad the suite-scaffold parent.** Adaptive suite scaffolds never forward padding values, so parent padding never reaches the screens. *Prevents:* insets applied nowhere while looking applied. (AND-27)

## Keyboard and IME handling without double padding

5. **Declare adjustResize in the manifest for keyboard activities; never the deprecated runtime resize constant.** *Prevents:* a note editor field hidden behind the keyboard. (AND-20)
6. **Place imePadding before verticalScroll in the modifier chain, or the keyboard still covers the note field.** *Prevents:* an editor that scrolls but never clears the keyboard. (AND-24)
7. **Never stack imePadding over contentWindowInsets that already carry IME insets; prefer the fitInside IME ruler there, after confirming the ruler name in the current edge-to-edge docs and the version in `libs.versions.toml`.** Two IME applications pad the note editor twice whenever the keyboard opens. *Prevents:* the IME double-padding trap. (AND-25)
8. **Prefer fitInside with the IME ruler over bare imePadding, after confirming the ruler name in the current edge-to-edge docs and the version in `libs.versions.toml`.** It trims jank from unconsumed upstream insets on the way up. *Prevents:* a jumpy note editor on keyboard transitions. (AND-26)

## Gotchas

- The host Activity manages icon contrast itself, so manual light-bar flags belong only to the compat path. (AND-28)
- Whenever a bottom bar must reach the screen edge, confirm the navigation-bar contrast-enforcement flag in current docs before changing it. (AND-29)
- Keep status icons legible with a translucent gradient scrim sized from the status-bars inset, not a solid block. (AND-31)
- Platform safe-area specifics, including any iOS keyboard overlap behavior, belong to the `compose-platform` skill. (XPLAT-15; XPLAT-16)

## Red flags

| Thought | Reality |
|---|---|
| "I'll pad the Scaffold and the notes screen; safer twice." | No. Rule 1 (SKILL.md rule 10): insets apply exactly once per screen, either inner padding or manual padding. |
| "I'll stack imePadding over the content insets that already carry IME; more room." | No. Rule 7: one IME application only, preferably the fitInside IME ruler. |
| "I'll pad the suite-scaffold parent so every notes destination inherits it." | No. Rule 4: suite scaffolds never forward padding values, so each screen insets itself. |
| "I'll put the animated inset offset in the ViewModel so both panes share it." | No. SKILL.md rule 2: fast-changing values are read in the smallest scope that renders them, never hoisted. |

## Verification

- [ ] `rg -n "innerPadding|WindowInsets|consumeWindowInsets" --glob '*.kt' <feature-root>` shows exactly one application per screen: yes or no.
- [ ] Scaffold inner padding flows into `contentPadding`, never into Modifier padding on the list container: yes or no.
- [ ] `consumeWindowInsets` is chained after the padding that applies inner padding: yes or no.
- [ ] No screen pads the suite-scaffold parent: yes or no.
- [ ] `rg -n "imePadding" --glob '*.kt' <feature-root>` shows at most one IME application per chain, placed before scrolling, and no chain stacks it over IME-carrying content insets: yes or no.
- [ ] The manifest declares adjustResize for keyboard activities: yes or no.
- [ ] Every Activity, every text field, the first and last notes list items, and FAB clearance were checked edge to edge, followed by a Gradle build: yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
