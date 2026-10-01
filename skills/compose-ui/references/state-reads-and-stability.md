# State Reads and Stability

Load this when a screen re-executes too often, when a stability report flags a model, or when ticking, scroll, or animation state feeds a composable.

Contents:

- Read depth: the nearest enclosing scope pays (F-15)
- Deferred reads: State and lambda providers into layout and draw (CB-37, CB-38)
- Clock-driven state stays at the leaf (F-15)
- derivedStateOf against remember (SKY-45, SKY-46)
- Stable UiModels and immutable collections (ANTI-04, SKY-13)
- When @Immutable is a lie (F-16)
- Third-party unstable types stop at the boundary (F-17)
- collectAsStateWithLifecycle at the Route (CESS-10)
- Snapshot discipline and no body back-writes (CB-11, CB-12, SKY-43)
- What the compiler report cannot tell you (F-15 stop rule)

## 1. Read depth decides cost

1. **A state read invalidates the nearest enclosing composable scope, not the reading line.** Move the read down to the leaf that renders the value. Never wrap the scope in `remember` to dodge the cost. *Prevents:* per-tick screen invalidation (F-15).
2. **Never read ticking or fast-changing state in a screen body, a `Scaffold` content lambda, or a lazy-list builder scope and pass the snapshot value down.** A notes-list clock read above the list re-executes the refresh box, the builder, and every visible item lambda on every tick. *Prevents:* per-tick list invalidation (F-15).
3. **Pass `State` or a zero-arg lambda across scopes, not the read value.** The caller then never subscribes; the leaf reads where it renders. Keep the read in composition only when it selects which composable to emit. *Prevents:* cost moved upward by value passing (CB-38, CB-43).
4. **Guard identical emissions in the ViewModel: early-return when the edited value is unchanged.** A note title keystroke that changes nothing must not emit. *Prevents:* wasted recomposition on no-op edits (PERF-10).

## 2. Deferred reads into layout and draw

5. **Push hot reads as low as the phase allows: composition, then layout, then draw.** A read at one phase invalidates that phase and everything below it. Scroll position, swipe offset, and per-frame animation values belong in layout or draw, never in composition. *Prevents:* full recomposition for per-frame values (SKY-37, CB-37).
6. **Prefer lambda-form modifiers for hot values: lambda offset over value offset, lambda graphics layer over value graphics layer, painted color through a draw modifier.** Match the pixel arithmetic of the value form, then confirm the parent stops re-executing per frame. *Prevents:* per-frame parent recomposition (SKY-38).
7. **Fold several per-frame transforms into one graphics-layer block.** One leaf-scope transform write replaces a chain of per-frame recompositions. *Prevents:* multiplied per-frame cost (SKY-38).
8. **Cross-row measurement stays in the measure phase: one note row measures, the consumer applies the result during measure.** Never read that measurement from a sibling composable body. Keep a fixed fallback size while unknown, and compare before writing the captured size. *Prevents:* layout-to-composition cascades across sibling rows (CB-41, CB-42).

## 3. Clock-driven state at the leaf

9. **`UiState` carries the `Instant`; the leaf reads the clock and formats at display.** A per-second formatted countdown string ticked from the ViewModel invalidates every collector each second. A note detail countdown reads the clock inside the chip that renders it and memoizes the gate flip. Read the clock through a ticker that re-emits: `produceState` with a delay, or a shared ticker flow. A one-shot read renders once and never updates. *Prevents:* whole-screen per-second invalidation (F-15; brief §8.2).
10. **Animation-only flags stay out of screen `UiState` unless business logic depends on them.** A tag-chip pulse phase is leaf-local. *Prevents:* business-state pollution by visual state (brief §8.2).

## 4. derivedStateOf against remember

11. **Reach for derived state only when input updates vastly outnumber output changes.** A scroll position that changes every frame feeding a show-scroll-to-top boolean is the shape; a cheap label pick from a note flag is not, and plain `remember` keyed on inputs covers read-only derivations. The canonical clock gate is that shape: `derivedStateOf` over the ticking `now` → `isDueSoon` (the input ticks every second; the output flips once), or a `produceState` that sleeps until the flip instant. Otherwise the derivation adds a subscription with no filtering benefit. *Prevents:* subscriptions that filter nothing (SKY-45).
12. **Always wrap the derivation in `remember`.** A bare derivation is recreated every composition and filters nothing. *Prevents:* derivations that never stabilize (SKY-46).

WRONG/RIGHT: the due-soon gate (rules 9, 11).

```kotlin
// WRONG because: the clock is read once; the badge never flips.
val now = clock.instant()
DueSoonBadge(visible = due.minus(now) < 24.hours)
```

```kotlin
// RIGHT: the leaf observes a ticking source; the gate flips once.
val clock: State<Instant> = tickingClock() // produceState with a delay, or a shared ticker flow
val isDueSoon by remember(due) { derivedStateOf { due.minus(clock.value) < 24.hours } }
DueSoonBadge(visible = isDueSoon)
```

## 5. Stable UiModels

13. **[Default] State models are immutable data classes with read-only stdlib collections; no lambdas, no mutable holders, no platform objects.** A `NoteUiModel` holds `val`s and `List`/`Set`/`Map`, never `MutableList`/`ArrayList`; callbacks travel as separate parameters. *Prevents:* lost skipping (ANTI-04).
14. **[Default] `kotlin.collections.*` is declared in the project's Compose stability configuration file, next to the domain-model packages (M-11).** Read-only stdlib collections are then compared by `equals`; kotlinx immutable collections stay acceptable where the project already uses them. The official fix guide gives both options (https://developer.android.com/develop/ui/compose/performance/stability/fix, verified 2026-09-25). A recorded project decision wins with no argument (M-12). *Prevents:* unstable list parameters (SKY-13).
15. **Add a UiModel only on a named M-11 trigger: derived or formatted values computed every recomposition, several sources merged into one row, UI-only per-item fields, or hidden domain fields.** A note row merging note plus tag names plus sync status names the merge trigger in a one-line comment. Otherwise `UiState` holds the domain model directly. *Prevents:* wrapper sprawl (brief §5.1).
16. **Prefer an inline value class for a single-field domain distinction; a data class for multiple fields or different equality.** A `NoteId` wrapper distinguishes the type without ceremony. *Prevents:* over-shaped wrappers at the boundary (CB-107).
17. **Never use an `@Immutable` wrapper only for type distinction, and never change serialization or API contracts to silence a stability report.** A value class carries the distinction; the wire contract stays untouched. *Prevents:* contract churn for report cosmetics (CB-108).

## 6. When @Immutable is a lie

18. **`@Immutable` is a promise the compiler believes without checking: apply it only when every property is a `val` of an immutable type.** A `MutableList` field mutated in place changes rendering without invalidating anything, so stale UI results. Stale UI is worse than over-recomposition. *Prevents:* silent UI desync (F-16).
19. **Never annotate from a report alone.** The annotation decision with its immutability contract belongs to the fixing step: make the type genuinely immutable or snapshot-observable first, verify, then decide whether any annotation is still truthfully needed. *Prevents:* false stability promises (F-16).
20. **Never list a mutable JDK type in the stability configuration file.** Domain-model packages from modules built without the Compose compiler go in the configuration file; that validity rests on genuinely immutable models. If the class can mutate, stop: no annotation, no wrapper. *Prevents:* config-certified mutability (brief §5.1 stability-config rule; SKILL.md rule 4).

## 7. Third-party unstable types stop at the boundary

21. **Convert third-party unstable types at the boundary into a type the kit owns.** `LoadState.Error` holds a `Throwable`, so placing it on `UiState` marks the whole class unstable and every consumer loses skipping. Present `AppError` instead; the mapping lives in the paging mapping, not at the render site. Never add a wrapper only for stability. *Prevents:* lost skipping from leaked foreign types (F-17).

## 8. Collection at the Route

22. **Collect flows with `collectAsStateWithLifecycle()` at the Route, never with bare collection deep in the tree.** Collection then tracks STARTED and stops while the destination is covered. Leaves receive sliced values, never the ViewModel. *Prevents:* background collection and entry-point duplication (CESS-10).
23. **For in-place observable collection edits use snapshot-aware list or map holders; with a list wrapped in single-value state, replace the list instead of mutating it.** A tag-selection toggle replaces the selected-tags list. *Prevents:* mutations no snapshot observes (CB-11).

## 9. Snapshot discipline

24. **Never mutate snapshot state from the composable body to rebuild derived data.** Derive read-only results with `remember` keyed on inputs; events and effects own mutations. *Prevents:* composition-pass write loops (CB-12).
25. **Never write to snapshot state already read in the same composition pass.** Move the write into an effect handler or a derived computation. *Prevents:* same-pass invalidation loops (SKY-43).

## 10. Composition-local and the report's blind spot

26. **Prefer tracked composition locals over static ones for values under active iteration.** A static provision invalidates the whole provider content on change. A note-theme override that changes often is tracked. *Prevents:* provider-wide invalidation (SKY-136).
27. **A skippable composable that reads ticking state is not fast.** The compiler report proves classification, not cost: a green report plus rising recomposition counts proves a runtime-only invalidation source. When the leaf reads the clock every second, the leaf re-executes every second regardless of flags. Fix the read depth first; stabilize types second. *Prevents:* report-chasing while the clock stays hoisted (F-15; rule 2). The diagnose-to-verify loop lives in the `compose-ui` skill.

## Gotchas

- Passing `now` down as a value moves per-tick cost up; pass the `State` and read at the leaf. (F-15)
- A one-shot clock read renders once and never updates; observe a ticker. (rule 9)
- A formatted countdown in `UiState` invalidates every collector per second; carry the `Instant`. (F-15)
- `remember` caches a value; it changes no scope's invalidation. Find the read. (F-15)
- `@Immutable` on a mutable holder silences the report and desyncs the UI; describe truth only. (F-16)
- A foreign `Throwable` holder on state kills skipping for every consumer; convert at the boundary. (F-17)
- A bare derivation filters nothing; wrap it in `remember` or drop it. (SKY-46)
- Mutating a single-value-state list in place notifies nothing; replace the list. (CB-11)
- Writing state read in the same pass loops; move the write to an effect. (SKY-43)
- Static provision for a churning value invalidates all consumers; track it. (SKY-136)
- Bumping `kotlinx.collections.immutable` to 0.5.x renames every copy-returning method to participial form (`add` to `adding`); drive from compiler warnings, never blind find-replace, because Builders keep imperative names. Migration depth: the Kotlin/kotlin-agent-skills `kotlin-tooling-immutable-collections-0-5-x-migration` skill, if installed.

## Red flags

| Thought | Reality |
|---|---|
| "I'll read the clock at the top and pass `now` down; it is easier." | See SKILL.md rule 2: the value carries the subscription upward. Pass the `State` or read at the leaf. |
| "I'll tick a formatted countdown string from the ViewModel; simpler." | See SKILL.md rule 3: the string invalidates every collector each second. Carry the `Instant`; read the clock at the leaf. |
| "I'll wrap it in `remember` to fix the recomposition." | See SKILL.md rule 2 (iron law): `remember` caches; it does not change which scope re-executes. Move the read. |
| "Adding `@Immutable` will make it skippable." | No. Rule 4: only when genuinely immutable, or mutation renders stale UI no recomposition fixes. |
| "Every feature needs a UiModel for consistency." | No. Rule 4: consistency means the same trigger rule, not the same files. Name the M-11 trigger or hold the domain model. |
| "I'll put this foreign error type on state; the report flag is just noise." | No. Rule 4: convert at the boundary into a kit-owned type. Never add a wrapper only for stability. |
| "I'll derive this cheap label with derivedStateOf to be safe." | No. Rule 11 (§4 in this file, not SKILL.md rule 11): derivation pays when inputs vastly outnumber output changes. The ticking-clock gate (`now` → `isDueSoon`) is that shape; a cheap label from stable inputs uses plain `remember`. |
| "I'll mutate the list in place inside the item lambda; it is local." | No. Rule 8: in-place mutation of single-value-state lists notifies nothing. Replace the list. |
| "Index keys are fine; the list never reorders today." | No. Rule 8: keys come from domain identity, plus `contentType`. |

## Verification

- [ ] No clock, scroll, or animation read sits in a screen body, `Scaffold` content lambda, or lazy-list builder scope: yes or no.
- [ ] Hot per-frame values use lambda-form modifiers; the parent shows no per-frame re-execution: yes or no.
- [ ] No formatted countdown or clock string on `UiState`; the clock is read at the rendering leaf: yes or no.
- [ ] Every derivation is wrapped in `remember` and its inputs change far more often than its output: yes or no.
- [ ] No `MutableList`, `MutableState`, lambda, or platform object sits in `UiState` or UiModels: yes or no.
- [ ] Every `@Immutable` holds only `val`s of immutable types; no wrapper exists only for stability: yes or no.
- [ ] No third-party `Throwable`-holding type appears on `UiState`; the kit-owned error type is presented instead: yes or no.
- [ ] State collection uses `collectAsStateWithLifecycle()` at the Route only: yes or no.
- [ ] No snapshot write targets state read in the same composition pass: yes or no.
- [ ] `rg -n "rememberNow|currentTimeMillis|System.nanoTime" --glob '*.kt' <feature-root>` shows reads only inside leaf composables: yes or no.
