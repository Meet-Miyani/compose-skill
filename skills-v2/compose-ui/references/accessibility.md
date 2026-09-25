# Accessibility
Load this when adding or reviewing semantics, touch targets, contrast, or screen-reader behavior in any composable.

Contents:
- Content descriptions: decorative null versus meaningful localized text (ACC-01, ACC-02).
- Grouping announcements: merge children or replace them with one string (ACC-05, ACC-07).
- Custom clickables: role plus label, built-in components first (ACC-16, ACC-17).
- Custom actions: named actions for multi-action rows (ACC-18).
- Touch targets: 48dp minimum and click-versus-padding order (ACC-09, SKY-102).
- Contrast without color-alone signals, and loading that keeps context (ACC-13, UX-32).
- RTL, MVI placement of descriptions, and test selectors (ACC-19, AND-97).
- Screen-reader checklist, red flags, verification.

## Content descriptions

- Give every note icon and image an explicit `contentDescription`: `null` when the graphic carries no information, a localized resource string when it does (ACC-01).
- Resolve the meaningful string at render from resources; never inline the announcement text (ACC-01, ACC-35).
- When a note thumbnail resource name does not make its decorative status obvious and the description is `null`, leave a one-line comment saying why a screen reader should skip it (ACC-02).
- State holds the semantic key for a dynamic label (for example a saved-state key); the Screen or leaf resolves that key to words at render time (ACC-19).

## Grouping announcements

- Prefer a built-in component (`Button`, `Switch`, `Checkbox`) over hand-assigning a role; the component already announces itself correctly (ACC-04).
- Apply `semantics(mergeDescendants = true)` when one note row's children form a single idea, such as a pinned glyph plus a title plus a tag count read as one item (ACC-05).
- Gotcha: a labeled decorative glyph inside an unmerged row splits one note into several screen-reader stops (ACC-06).
- Apply `clearAndSetSemantics` with a single custom string when the composed children would announce something verbose or misleading, such as a star-rating graphic plus a count (ACC-07).
- Rule of thumb: merge keeps the children's words in one announcement; clear-and-set replaces them with the custom string (ACC-07).

## Custom clickables

- Give a custom clickable note card both a role and an `onClickLabel` (for example role button plus "Open note") so the action is announced (ACC-16).
- Prefer `Button`, `IconButton`, or `TextButton` over a hand-rolled clickable whenever the design allows; the built-in carries semantics, target size, and feedback together (ACC-17).
- Keep the clickable's announcement words in resources and resolve them at render, matching the content-description rule above (ACC-35).

## Custom actions

- Expose each secondary row action on a multi-action note item (such as pin, share, archive) as a named custom accessibility action so it stays discoverable without extra focus stops (ACC-18).
- Gotcha: the action lambda reports `true` only when it actually handled the tap (ACC-18).

## Touch targets

- Keep every interactive element at least 48 by 48 dp (ACC-09).
- Call `minimumInteractiveComponentSize()` on custom interactive note controls instead of guessing padding values (ACC-10).
- Add no extra padding around Material components to reach the minimum; they already meet it, and added padding shifts the visual rhythm (ACC-11).
- Order click handling against padding deliberately: place the tap handler outside padding when the padded area should respond, inside it when only the visual note glyph should respond (SKY-102).

## Contrast and status signals

- Never signal a note state by color alone; pair the hue with an icon, a text label, or a pattern (ACC-13).
- Draw status colors from theme tokens only, so the note list stays legible in light and dark themes with no hex literals in feature code (ACC-15).
- Keep loading indicators visible without hiding the surrounding note context, and skip rapid shimmer that flashes over content (UX-32).

## RTL

- Write note rows so direction comes from the layout system, not from hardcoded start/end assumptions; mirrored arrangement follows automatically (SKILL_SPECS §3 scope).
- Keep leading/trailing icons and tag order meaningful after mirroring; a pinned glyph that must stay fixed gets an explicit placement, never a hardcoded offset (SKILL_SPECS §3 scope).

## MVI placement

- Put resolved descriptions and `stateDescription` values in Screen and leaf composables, close to rendering (ACC-19).
- Keep `Modifier.semantics` calls in composable modifier chains; no semantics object is built inside the ViewModel (ACC-19).
- Route accessibility-triggered callbacks through the same action pipeline as any other tap; a custom action dispatches an action the ViewModel already handles (ACC-19).

## Test selectors

- Gotcha: match test finders against semantics first and add a test tag only when matching needs more than about three matchers; never tag a node just to expose a visual property (AND-97).

## Screen-reader checklist

- Every meaningful note icon announces a localized description; every decorative one is explicitly `null` with a reason where the name is unclear (ACC-01, ACC-02).
- Grouped note rows announce once; replaced announcements carry one accurate custom string (ACC-05, ACC-07).
- Custom note cards announce a role and an action label; secondary row actions appear as named actions (ACC-16, ACC-18).
- All interactive note controls meet the 48dp minimum with no redundant Material padding (ACC-09, ACC-11).
- No note state relies on color alone, and all status colors come from theme tokens (ACC-13, ACC-15).
- No accessibility wording is hardcoded or stored resolved in state; everything resolves from resources at render (ACC-35, ACC-19).
- The notes flow passes a live screen-reader pass on each target platform before done (ACC-29).

## Red flags

| Thought | Reality |
|---|---|
| "I'll hardcode this saved-state color; the tokens don't have it." | No. Rule 5: theme tokens only in feature code. Name the missing token as an open gap. |
| "I'll inline this announcement string; translation comes later." | No. Rule 9: every user-facing string is a resource in every locale before done. |
| "I'll cover the notes list with a full spinner on refresh; it's brief." | No. Rule 7: refresh keeps content with an indicator, never wipes it. |
| "I'll hand-roll this note button instead of checking the design system." | No. Rule 6: search the design-system module first and copy the call-site conditions with the component. |
| "I'll read the per-note saved flag at the screen and pass values into rows." | No. Rule 2: read fast-changing values in the smallest scope that renders them; pass state or a lambda down. |
| "I'll key note rows by index; the list never reorders today." | No. Rule 8: keys come from domain identity, plus a content type. |

## Verification

- [ ] Every meaningful `Image`/`Icon` in the touched files carries a non-null resource description and every `null` one is decorative: yes or no.
- [ ] No hardcoded announcement text remains: `rg -n "contentDescription = \"" --glob '*.kt' <feature-root>` is empty.
- [ ] No hex color literal remains outside the design-system module: `rg -n "Color\(0x" --glob '*.kt' <feature-root>` is empty.
- [ ] Each custom clickable carries a role and an `onClickLabel`, or is a built-in button component: yes or no.
- [ ] Each custom interactive control enforces the minimum target size and no Material component carries redundant target padding: yes or no.
- [ ] Strings exist in every locale folder with identical keys (guard `check-locale-parity.sh`): yes or no.
- [ ] A live screen-reader pass over the changed notes flow on each target platform announces each row once and exposes every action: yes or no.
