# UX States

Load this when choosing loading, empty, error, validation, or disabled visuals for a Notes screen.

Contents:

- Principles: trust-first UI (UX-01)
- Loading decision table: skeleton vs keep-content vs spinner (UX-17–UX-21)
- Skeleton and shimmer rules (UX-18, UX-28)
- Layout stability during loads (UX-23)
- Inline validation (UX-05, UX-06)
- Disabled vs hidden (UX-07)
- Preserve edited fields and last good results (UX-24, UX-25)
- Failure vs business state: error vs empty vs missing (F-05, F-14)
- Partial results, perceived speed, disclosure (UX-09–UX-11)
- Animated state branches (CB-61); config testing gotcha (AND-96)

## Principles

A notes app is a trust product. Every state choice keeps the screen stable,
immediate, precise, reversible, and non-destructive. (UX-01)

## Loading decision table

Pick exactly one row. No judgment calls; the situation names the visual. (UX-17–UX-21, ANTI-10)

| Situation | Visual |
|---|---|
| First load of the notes list or note detail, layout is known, no data yet | Skeleton matching the card shape |
| Refresh of one section while its notes are visible | Keep content plus a small inline indicator |
| Whole-screen blocking start with no known structure | Spinner; use rarely |
| Recalculating a derived value while the previous note summary exists | Keep the previous summary plus an "updating" affordance |
| Idle screen with genuinely no notes | Empty-state hint, never a spinner |

Never wipe existing content during a refresh or a load. (UX-17)

A failed refresh keeps the notes on screen and surfaces the error with a
Retry that holds the failure it retries. (UX-17, brief §4.4 D2-1)

## Skeleton rules

Use a skeleton only for a cold load whose layout is already known. (UX-18)

Shimmer over a skeleton is optional polish. It is never the loading
strategy by itself. (UX-28)

Gotcha: a shimmer that sweeps rapidly reads as flashing; keep the pulse
slow and low-contrast. (UX-28)

## Layout stability

The notes list keeps its height while loading. No jumps, no flicker, no
lost scroll position. (UX-23)

Gotcha: give the loading slot a minimum height so the first notes do not
push the screen down when they arrive. (UX-23)

## Inline validation

Validate the note title and tag fields for format and range while the user
edits, wherever the feedback is obvious. (UX-05)

- Stay silent on untouched fields. Never flag a field the user has not reached. (UX-05)
- Render each error inline, beside the field it belongs to. (UX-05)
- Keep the layout fixed when an error appears or clears. (UX-05)
- Disable Save only when saving is impossible, and explain why next to the control. (UX-05)
- Keep the typed value visible during the error. (UX-06)
- Show the error under the field. (UX-06)
- Never open a modal per keystroke. (UX-06)
- Never paint the whole form red at once. (UX-06)

## Disabled vs hidden

Disable a control only when the reason is obvious from nearby context, the
screen stays readable, and the user's input is preserved. (UX-07)

Never ship a disabled Save button with no visible reason. Never clear the
note editor during loading. Never gray out the whole notes list for a
small section refresh. (UX-07)

Prefer disabling with an explanation over hiding the control: a hidden Save
button teaches the user nothing about what is missing. (UX-07)

## Preserve user input

Never clear edited fields on refresh. A sync that lands while the user
types in the note editor must not touch the draft. (UX-24)

Never clear the last good result while fetching a new one. The previous
notes list stays until its replacement arrives. (UX-25)

## Failure vs business state

A failure and a business state travel in separate fields, in both
directions. They never collapse into one flag. (F-05, F-14)

| Screen outcome | Rendering |
|---|---|
| Notes list loaded, list is empty | Empty-state hint with a path to create the first note |
| First load failed, nothing to show | Inline error state with a Retry holding the `AppError` (brief §4.4 D2-1) |
| Refresh failed while notes are visible | Keep the notes; surface the failure as a popup through the error host (brief §4.4 D2-1) |
| Note id resolves to nothing on a successful read | Missing state (`isMissing`), never a synthetic `AppError` (F-05) |
| Read failed (timeout, no network) | `error: AppError?` holds the failure; never fold it into `isMissing` (F-14) |

Gotcha: mapping `onError` to `copy(isMissing = true)` discards the failure
and tells the user the note is gone when the network merely failed. (F-14)

Gotcha: routing "note not found" through `AppError` puts a Retry button on
a stable outcome that retrying cannot change. (F-05)

Nothing swallows a failure on its way to the user. A `catch` that leaves
stale notes with no message and no retry is a defect; transport failures
propagate to the guarded launch, which picks the tier. (F-10)

## Cold load vs reconcile vs refresh

Name the load before drawing it. The cold load is the first `ON_START`;
later starts reconcile; an explicit user pull refreshes. (brief §8.4)

- Cold load with no content: skeleton, then content, empty hint, or inline error.
- Reconcile or refresh with content visible: keep content with an indicator; a failed refresh never clears the list.
- A background poll the user did not trigger stays silent and is named as a poll. (brief §4.4 D2-1)

## Partial results and perceived speed

Show an instant local draft-derived estimate first, fetch the remote
refinement in the background, keep the previous refined value until the new
one lands, and label the refreshed state. (UX-10)

Apply local field changes instantly. Recalculate cheap deterministic
outputs immediately. Debounce only expensive async work. Keep the layout
stable. Animate only meaningful content changes. (UX-11)

## Progressive disclosure

For dense note-editor forms: hide advanced options by default, keep the
main path obvious, reveal secondary controls progressively, and never split
a trivial form into many steps. (UX-09)

## Animated state branches

When the loading, content, and error shapes crossfade, key the transition
by visual shape: separate branch keys for different shapes, stable note ids
for crossfades between payloads, one shared key when a refresh stays in the
same shape so it updates in place. (CB-61)

Gotcha: verify state-driven transitions locally across window size, font
scale, locale, and dark mode with configuration overrides joined together. (AND-96)

## Red flags

| Thought | Reality |
|---|---|
| "I'll show a full-screen spinner on refresh; it is only a second." | No. Rule 7: refresh keeps content with an indicator. Skeletons are cold-load only. |
| "I'll swap the list for a spinner while `isLoading` is true; simpler." | No. Rule 7: never clear or hide existing content during a refresh. |
| "I'll clear the editor draft when the sync lands; the server wins." | No. Rule 7: never clear edited fields on refresh. |
| "I'll fold 'note missing' into the error field; one nullable is enough." | No. Rule 7: failures and business states are separate fields. |
| "I'll hardcode this skeleton gray; the tokens do not have it." | No. Rule 5: colors come from theme tokens only in feature code. |
| "I'll put this validation string inline; translation comes later." | No. Rule 9: every user-facing string is a resource in every locale before done. |

## Verification

- [ ] `rg -n "if \(isLoading\)" --glob '*Screen.kt' <feature-root>` shows no branch that replaces visible content with a spinner: yes or no.
- [ ] Every refresh path keeps rendered notes with an inline indicator: yes or no.
- [ ] Skeletons appear only on cold loads with a known layout: yes or no.
- [ ] The loading slot holds a minimum height across load transitions: yes or no.
- [ ] Untouched editor fields show no errors; errors sit beside their field; layout does not shift on error toggle: yes or no.
- [ ] Disabled Save carries a visible nearby reason and the draft is intact: yes or no.
- [ ] `error: AppError?` and `isMissing` are separate `UiState` fields and Retry holds the error it retries: yes or no.
- [ ] No `catch` in repositories or data sources swallows a transport failure: yes or no.
- [ ] Error-tier choice matches the tier rule in the `compose-architecture` skill (inline for first load, popup for failed refresh, silent only for named polls): yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
