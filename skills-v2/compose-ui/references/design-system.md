# Design System

Load this when adding, changing, or reviewing theme tokens, shared components, icons, sheets, dialogs, or snackbar chrome.

Contents:

- Semantic color tokens and the no-hex rule
- Type scale: defaults first, branded slots only
- Where shared components live
- Reuse-inventory habit before writing anything new
- Sheet choice, visibility, and chrome ownership
- Dialog choice and visibility
- Snackbar and error chrome ownership
- Icon homes for stock and project-drawn glyphs
- Shared-component API shape: slots and defaults

## Semantic color tokens

1. **Read every color from a semantic theme token; never write a hex literal in feature code.** A hardcoded note-badge color misses every theme change. *Prevents:* theme breakage the guard catches. (SKILL.md rule 5; brief §11.3)
2. **When no token fits, grow the theme instead of hardcoding.** A new notes surface carries no hardcoded styling; the missing value becomes a new semantic token in the design-system module. *Prevents:* one-off colors that drift between themes. (AND-88)
3. **Keep raw tonal ramps inside the design-system module.** Only its internal token sub-package may name raw ramp values; feature code reads the semantic alias. *Prevents:* features depending on palette mechanics. (brief §11.3)

## Type scale

4. **Use the default type scale; override only branded slots.** The design-system module owns the type scale. A notes list screen uses its styles as-is; a branded note-editor title overrides one slot instead of redefining the scale. *Prevents:* five screens with five title sizes. (brief §1.1)

## Where shared components live

5. **New shared components live in the design-system module, never in a feature.** A tag chip used by the notes list and the note editor belongs to the design system; a row owned by one destination stays in that feature. The module stays Koin-free. *Prevents:* reinvented components and feature-to-feature imports. (SKILL.md rule 6; brief §1.1; F-01)
6. **Never nest one scaffold inside another.** Fill the outer top-bar, bottom-bar, and host slots instead of mounting a second scaffold for a notes section. *Prevents:* doubled bars and measure-pass waste. (SKY-70)

## Reuse-inventory habit

7. **Search the design-system module for components, formatters, and tokens before writing anything.** The inventory step in the workflow exists because a second tag chip is cheaper to write than to find and more expensive to keep. *Prevents:* duplicate components. (SKILL.md rule 6)
8. **Copy the conditions with the component.** A list-detail divider gated on "not in a sheet" keeps its gate in its new home; without the gate the note detail sheet renders a stray edge line. *Prevents:* precedent-gated UI breaking in its new home. (F-04)
9. **Verify every helper before calling it.** A plausible formatter name is not a verified one; the name you call was seen in this project during this task. *Prevents:* invented APIs that fail compile. (F-03)

## Sheets

10. **Choose `ModalBottomSheet` for overlays and `BottomSheetScaffold` for persistent sheets.** The note editor is an overlay; a persistent tag panel is a scaffold. *Prevents:* an undismissable overlay or a floating persistent panel. (MTRL-38)
11. **Drive sheet visibility from an effect through the Route's sheet state.** The ViewModel emits the intent; the Route calls show or hide. *Prevents:* sheets that survive the state that opened them. (MTRL-39)
12. **Chrome belongs to the scene, not the content.** The handle, close affordance, and scrim are owned by the scene; sheet content renders the body only. One modal-sheet host per app. *Prevents:* every sheet reinventing dismiss chrome. (brief §7.7; brief §11.6)
13. **A sheet the user navigated to is a destination, not a nullable state field.** It opens through the back stack so Back, deep link, and restore all reach it. Navigation mechanics belong to the `compose-architecture` skill. *Prevents:* sheets unreachable after restore. (brief §7.7)

## Dialogs

14. **Use `AlertDialog` for simple confirm or dismiss and `Dialog` plus `Card` for complex content.** Deleting a note is an alert; a tag picker with a form is a card dialog. *Prevents:* custom chrome around a two-button question. (MTRL-42)
15. **Drive dialog visibility from state; confirm and dismiss dispatch events.** The note-delete dialog reads a state flag and its buttons dispatch dismiss or confirm actions. *Prevents:* dialogs no event can close. (MTRL-43)

## Snackbar and error chrome

16. **Remember `SnackbarHostState` in the Route and pass it to the `Scaffold` slot.** Content never owns the host. *Prevents:* a snackbar host per section. (MTRL-40)
17. **Collect snackbar effects in the Route and route action taps back to `onAction`.** The "Undo" tap on a note-archive snackbar dispatches an action; the ViewModel decides what undo means. *Prevents:* UI-layer business decisions. (MTRL-41)
18. **Popup-tier errors go through the single app-level error host; every Route forwards its errors flow to it.** The composition root hosts the collector above the navigation display. Which tier a failure takes belongs to the `compose-architecture` skill. *Prevents:* dropped or doubled error popups. (brief §3.5; brief §4.4)

## Icon homes

19. **Stock Material glyphs stay at the call site.** The notes search bar uses the stock search glyph directly; never wrap or re-home it. *Prevents:* a wrapper that shadows the platform set. (F-20)
20. **Project-drawn glyphs live on the shared icon set in the design-system module.** A Figma-drawn sort-swap glyph for the notes list lives there, tinted by a semantic token. *Prevents:* one icon per feature package. (F-20)
21. **Never a feature icon package, never a feature wrapper around Material.** No `presentation/icons` package beside the five package roots. *Prevents:* a second icon home per feature. (F-20)

## Shared-component API shape

22. **Prefer named composable slots over boolean shape flags and unconstrained primitives.** Keep parameters that enforce a semantic, design-system, constrained-type, or measured fast-path contract. *Prevents:* flag matrices no caller can satisfy. (CB-51; CB-56)
23. **Make an optional slot nullable with a null default.** When the notes card has no trailing action, its container and spacing disappear entirely. *Prevents:* empty boxes reserving space. (CB-52)
24. **Add a layout-scope receiver only for an explicit public layout contract.** An internal row arrangement never justifies one. *Prevents:* callers depending on layout internals. (CB-53)
25. **Collect repeated defaults and tokens in a `Defaults` holder per component.** *Prevents:* default drift across call sites. (CB-54)
26. **Name free-form slots with a `Content` suffix; constrained regions get a semantic noun.** Ordinary trailing slots stay plain; scope receivers are reserved for public action regions whose children control allocation. *Prevents:* ambiguous slot contracts. (CB-55)

## Adaptive and navigation chrome

27. **Compute the window size class once at the app root and pass it down.** Screens receive the derived decision, never recompute it. *Prevents:* disagreeing breakpoints per screen. (MTRL-45)
28. **Compact width gets a bottom bar, medium and expanded a side rail.** Default to the auto-switching suite scaffold for three to five top-level notes destinations. *Prevents:* a phone bar stretched across a tablet. (MTRL-11)

## Styles API boundaries

29. **Use the Styles API only when the project has already opted in; its mechanics live in the android/skills `styles` skill, if installed.** Clicks, gestures, and semantics stay in modifiers. Confirm the opt-in in current docs and `libs.versions.toml` before relying on it. *Prevents:* production code written against an experimental alpha API. (AND-55; AND-56; AND-65)

## Gotchas

- Pair colors only in their intended roles (`on-primary` on `primary`, never crossed); intended pairs hold a minimum 3:1 contrast, crossed pairs break it. Source: https://m3.material.io/styles/color/roles (MTRL-31)
- Hold dismiss closed during in-flight mutations with the block-dismiss guard; a swipe that cancels a note save loses the write. (brief §11.6)
- A slot-scope receiver on an internal layout leaks the layout contract to every caller of the notes card. (CB-53)

## Red flags

| Thought | Reality |
|---|---|
| "I'll hardcode this badge color; the tokens don't have it." | No. Rule 5: feature code holds no hex. Name the missing token as an open gap and grow the theme. |
| "I'll park this shared tag chip in my feature for now and move it later." | No. Rule 6: shared components live in the design-system module from the first use. |
| "I'll copy this divider; the gate was specific to that screen." | No. Rule 6: copy the condition with the component, or the sheet gets a stray edge line. (F-04) |
| "I'll wrap the stock search glyph with my icons so they're all in one place." | No. Rule 6: stock glyphs stay at the call site; only drawn glyphs join the shared set. (F-20) |
| "I'll own the snackbar host inside the Screen content; fewer params." | No. Rule 1: only the Route wires hosts. Content is stateless. |
| "I'll draw the sheet handle inside the sheet content." | No. Rule 1: chrome belongs to the scene. Content renders the body only. |
| "I'll gate this editor sheet on a nullable state field; simpler." | No. Rule 1: a navigated-to sheet is a destination opened through the back stack. |
| "I'll nest a Scaffold here for this section's own bar." | No. Rule 1: structure belongs to the owning host. Fill the outer top-bar, bottom-bar, and host slots instead of mounting a second scaffold. |
| "I'll add a boolean flag to reshape this card." | No. Rule 6: named slots over boolean shape flags. |

## Verification

- [ ] `rg -n "Color\(0x" --glob '*.kt' <feature-root>` is empty outside the design-system module.
- [ ] No `presentation/*/icons` or feature `ui` icon package exists: yes or no.
- [ ] `SnackbarHostState` appears only in `*Route.kt` files: yes or no.
- [ ] Sheet handle, close, and scrim code appears only in scene files, never in sheet content: yes or no.
- [ ] Every shared composable used by two destinations lives in the design-system module: yes or no.
- [ ] Every repeated component default is collected in that component's `Defaults` holder: yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
