# Adaptive Layouts

Load this when a notes screen must look different on a tablet, foldable, desktop or browser window, or when you plan a destination's layout for those widths.

Contents:

- Choose the adaptive shape
- Size class, not device
- Layout variants and naming
- A pane gets a width, not a size class
- List-detail composition and the call-site gate
- Multi-pane hosting through a scene strategy
- Layout-choice decisions for adaptive notes UI
- Gotchas
- Red flags
- Verification

## Choose

- Does the request text or a provided design show a different arrangement on wider windows? Recorded targets or window classes are not a design.
  - No → **Reflow**: one layout whose content width is always capped, cap before fill (`Modifier.widthIn(max = …).fillMaxWidth()`): use the design-system max-width token, or a named constant in the feature when no token is visible, listed as a follow-up. Never skip the cap. Offer any wider arrangement you would add as a follow-up. Lists become adaptive grids (Layout-choice decisions below).
  - Yes → Does the second area need its own Back step or deep link?
    - Yes → **Multi-pane**: two destinations hosted by a scene strategy (rule 11). Each keeps one Screen.
    - No → **Layout variants** (rules 2–5).

## Size class, not device

1. (non-negotiable) **The window size class picks the layout. Never a device, platform, OS or screen-size check, and never a device name, even when the request names `NotesTabletScreen` or `isTablet`.** An iPad in Split View, a folded phone and a half-width desktop window are narrow windows on "tablet" and "desktop" devices, and the window changes size while the app runs. Decline the device names in the first sentence and build the size-class shape. *Prevents:* the wrong layout in multitasking, folding and resized windows.

## Layout variants and naming

2. (non-negotiable) **The composition root computes the window size class once and passes it to the Route of each destination with variants. The Route maps it to a `<Dest>Layout` value; the one `<Dest>Screen` branches on that value once.** Leaves never receive the size class. *Prevents:* breakpoints recomputed per screen and per leaf (`design-system.md` rule 27).
3. (default) **Name each variant after the smallest width class it serves: `<Dest>CompactLayout` serves Compact and Medium, `<Dest>ExpandedLayout` serves Expanded and wider.** Add `<Dest>MediumLayout` only when the request or design names a Medium arrangement. Enum values match: `NotesLayout.Compact`, `NotesLayout.Expanded`. *Prevents:* `Phone`/`Tablet` names that lie in multitasking, and variants nobody designed.
4. (non-negotiable) **Variants share their leaves, and the Screen holds list and scroll state above the branch.** Shared pieces keep real names (`NoteList`, `NoteTagSummary`), never one `<Dest>Content` steered by several boolean flags. *Prevents:* a resize that resets the scroll position, and two copies of the list drifting apart.
5. (non-negotiable) **Breakpoints come from the library's `WindowSizeClass` width constants, checked from the largest down; never a hand-typed `600.dp` or `840.dp`.** *Prevents:* breakpoints that drift from the platform's.

```kotlin
// WRONG because: device names and a device check; an iPad in Split View gets the tablet screen
if (isTablet) NotesTabletScreen(state, onNoteClick) else NotesPhoneScreen(state, onNoteClick)
```

```kotlin
// RIGHT: presentation/notes/model/NotesLayout.kt; the Route calls notesLayout(windowSizeClass)
enum class NotesLayout { Compact, Expanded }

fun notesLayout(windowSizeClass: WindowSizeClass): NotesLayout = when {
    windowSizeClass.isWidthAtLeastBreakpoint(WindowSizeClass.WIDTH_DP_EXPANDED_LOWER_BOUND) -> NotesLayout.Expanded
    else -> NotesLayout.Compact
}

// NotesScreen.kt: one Screen, one branch, list state above it
val listState = rememberLazyListState()
when (layout) {
    NotesLayout.Compact -> NotesCompactLayout(state, listState, onNoteClick, modifier)
    NotesLayout.Expanded -> NotesExpandedLayout(state, listState, onNoteClick, modifier)
}
```

## A pane gets a width, not a size class

6. (non-negotiable) **A destination that can show inside a pane picks its arrangement from the width it is given, measured once at its own root; never from the window size class.** In a list-detail scene on an Expanded window the detail pane gets only part of the width, so the window class reports room the pane does not have. Derive the threshold from the content (body minimum plus side column) and name it. *Prevents:* a two-column note detail squeezed into a narrow pane.
7. (non-negotiable) **Never read a constraint box inside a leaf or a list item to decide an arrangement.** A per-item read re-runs measure work per row, and rows can disagree with each other. *Prevents:* per-row layout churn and split decisions inside one notes list. (SKY-69; F-04)
8. (non-negotiable) **Keep the decision at the pane or Screen root, not in the detail leaf.** The notes detail leaf renders the note it is given; it never asks how wide the window is. *Prevents:* a detail leaf that shows pane chrome in the wrong host. (SKY-69; brief §7.7)

## List-detail composition and the call-site gate

9. **Compose one note detail body, hosted two ways: a sheet destination at Compact, a side pane on wider sizes.** The body stays identical; only the host changes. *Prevents:* two detail implementations drifting apart. (F-04; brief §7.7)
10. **Copy the call-site condition together with any pane component.** A pane divider that is correct beside a notes list is a stray edge line inside a note sheet, so the gate travels with the component:

```kotlin
if (presentedInBottomSheet) { Box(modifier) { body() } }
else { ListDetailPaneSplit(modifier, content = body) }
```

*Prevents:* precedent-gated UI breaking in its new home. (F-04)

## Multi-pane hosting through a scene strategy

11. **Implement multi-pane through a Navigation 3 scene strategy (list-detail or supporting pane); never mount the pane scaffolds directly.** Direct-mounted panes bypass back-stack behavior, so Back, deep link, and restore cannot reach them consistently. *Prevents:* panes unreachable after restore. (AND-72; brief §7.7)
12. **For M3 adaptive mechanics, the android/skills adaptive skill goes deeper, if installed.** This file stands alone without it; the rules above are the whole kit contract.

## Layout-choice decisions for adaptive notes UI

| Situation | Choice |
|---|---|
| Notes list must fill wider windows with more columns | Convert the column to a grid with adaptive cells at a legible minimum width (AND-75) |
| Screen structure versus a small wrapping tag group | Screen structure belongs to a grid-style layout; a small wrapping tag chip group belongs to a flow-style layout (AND-77) |
| Large homogeneous notes data versus screen structure | Lazy grids keep large homogeneous data; the non-lazy grid owns screen structure, so confirm its loading behavior in current docs before aiming it at a long notes feed (AND-76) |

## Gotchas

- Compute the class with the V2 adaptive-info function (`currentWindowAdaptiveInfoV2()`); the older `currentWindowAdaptiveInfo()` is deprecated and ignores the Large and Extra-large widths, and the `WindowWidthSizeClass` enum is deprecated. The CMP artifact group is `org.jetbrains.compose.material3.adaptive`. Confirm the names in the current docs and the version in `libs.versions.toml`.
- `fillMaxWidth()` before `widthIn(max = …)` fixes the minimum width to the full window, so the cap has no effect and the fields stretch; put the cap first.
- A landscape phone is wide but Compact in height; when a variant needs vertical room, the selector also checks the height breakpoint.
- A media-query integration flag is set once in the Application; without it queries never fire. (AND-78)
- Read window width and height through the derived media-query form so rapid resizes ride derived state instead of recomposing per pixel. (AND-79)
- Confirm supporting-pane back behavior against the current adaptive library; if Back skips the expected dismiss, the pane needs an explicit pop-until-destination-change setting. (AND-84)

## Red flags

| Thought | Reality |
|---|---|
| "The app ships on tablets and desktop, so I'll give the editor an Expanded layout with a side panel." | No. Choose: only the request text or a provided design adds a wider arrangement; recorded targets only make the cap necessary. Build Reflow and offer the side panel as a follow-up. |
| "The user named `NotesTabletScreen`, so the rename is in scope." | No. Rule 1: decline device names even when requested; build one `NotesScreen` with size-class variants and say why first. |
| "I'll keep the name `isTablet`; its meaning is width now." | No. Rule 1: a device name invites a device check. Name the value after the layout (`NotesLayout.Expanded`). |
| "I can't verify the adaptive API, so `BoxWithConstraints` in the Route with `600.dp` will do." | No. Rules 2 and 5: the root computes the class (Gotchas name the call to confirm) and the breakpoint is the library constant. |
| "The pane receives a size class, so the detail goes two-column when the window is Expanded." | No. Rule 6: a pane gets a width, not a size class. Measure the width at the pane root. |
| "I'll read a constraint box in each notes row to pick single or dual pane; it is local." | No. Rule 7: never decide inside a leaf or item scope. |
| "I'll mount the notes list and detail side by side directly; faster than a scene." | No. Rule 11 (SKILL.md rule 10): panes mount through the scene strategy so Back, deep link, and restore reach them. |
| "I'll copy this pane divider; the sheet gate was specific to that screen." | No. Rule 10: copy the condition with the component, or the note sheet gets a stray edge line. |

## Verification

- [ ] `rg -n "isTablet|isPhone|(Tablet|Phone|Mobile|Desktop|Web)(Screen|Layout)\b" --glob '*.kt' <feature-root>` is empty.
- [ ] No layout branch compares a width to a hand-typed dp breakpoint; window branches use the library constants: yes or no.
- [ ] A destination that can show inside a pane never reads the window size class: yes or no.
- [ ] `rg -n "BoxWithConstraints" --glob '*.kt' <feature-root>` shows reads only at a pane or Screen root, never inside a leaf or item scope: yes or no.
- [ ] The notes detail leaf takes the note plus callbacks and never reads window size: yes or no.
- [ ] Every pane component copied from a precedent carries its call-site gate: yes or no.
- [ ] Each layout variant renders once per tier (a preview or UI test per variant): yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
