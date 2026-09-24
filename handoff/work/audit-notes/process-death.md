# Process-death audit — brief decisions vs current official docs

Date verified: 2026-09-24. All URLs below were fetched or returned in search results on that date.
Scope: CONTRACT_BRIEF §§3.7, 7.4, 8.1, 8.3; FEAT-01 (items 4–6), FEAT-03, DATA-02 (1–5), UI-01 (2–4), UI-04; EXTERNAL_LEDGER rows AND-01, CMP-26, CMP-30, CB-04.
Rule applied per decision: STANDARDS §1.5 evidence order — evidence first, then the ponytail ladder (simplest rung that holds), then scalability.

---

## (a) No SavedStateHandle in ViewModels; typed input loss on process death is by design

**Verdict: OPEN — official docs recommend SavedStateHandle for exactly this case; the kit needs a commonMain-compatible answer before it can bless input loss.**

**Evidence FOR (brief's side):**

- https://developer.android.com/topic/libraries/architecture/saving-states — saved state must stay minimal ("such as an ID, to recreate the data"); complex/large data belongs in local persistence, not in saved state. Supports identity-on-key plus refetch as the primary restore path.
- https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-viewmodel.html — common-code `viewModel()` has no reflection on non-JVM targets; every instance needs an explicit initializer. SavedStateHandle is an AndroidX-lifecycle, Android-scoped mechanism, so a `commonMain` BaseViewModel cannot take it the way an Android-only ViewModel can. This is the brief's strongest real constraint.
- https://developer.android.com/kotlin/multiplatform/viewmodel — the official KMP ViewModel sample (`MainViewModel`) takes a repository only, no SavedStateHandle, wired via `viewModelFactory { initializer { … } }`.

**Evidence AGAINST (official guidance contradicts "loss by design"):**

- https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate — "if you need to handle system-initiated process death, you might want to use the SavedStateHandle API as backup"; rule: "For state that is used in business logic, hold it in a ViewModel and save it using SavedStateHandle"; `getStateFlow` / `getMutableStateFlow` (lifecycle 2.9.0+) and the `saved` delegate with kotlinx-serialization exist precisely to preserve typed ViewModel state across process death.
- https://developer.android.com/topic/libraries/architecture/saving-states — "Usually, data stored in saved instance state is transient state that depends on user input or navigation. Examples … input in text fields." Typed-input loss is therefore NOT the officially simplest correct form; it is a documented gap.
- Caution on the same page: SavedStateHandle only persists writes made while the host Activity is started/stopped normally — writes while stopped can be lost. A kit rule must carry this gotcha if it adopts the handle.

**Samples practice:** Could NOT verify per-file whether Now in Android ViewModels use SavedStateHandle, or what kotlinconf-app / KMP-App-Template do for input restore (no per-file fetch in this phase). Verified only: KMP-App-Template (shared UI) uses Compose Navigation (Nav2-era) + Koin, not Nav3 (https://github.com/Kotlin/KMP-App-Template). Treat any "samples don't use SavedStateHandle" claim as UNVERIFIED.

**Ladder input:** Rung 1 (platform) already holds on Android — `getMutableStateFlow` / `saved` delegate preserve typed input with ~5 lines. The brief stops *below* the first rung that holds. Simplest correct form is: SavedStateHandle for business-logic-held input on Android; the open question is only the commonMain mechanism (expect/actual handle, nav-key-carried draft id, or an explicit documented carve-out scoping loss to non-Android targets).

**Scalability note:** At 50 modules the cost of SavedStateHandle is per-ViewModel constructor plumbing (DI must supply the handle — Koin `stateViewModel` history shows this is a real integration point), not architecture. Input loss, by contrast, scales into a per-screen UX defect no guard can catch. Prefer the plumbing.

---

## (b) No rememberSaveable mirror of UiState

**Verdict: KEEP — the ban is exactly what official docs prescribe; the brief's carve-out matches theirs.**

**Evidence FOR:**

- https://developer.android.com/topic/libraries/architecture/saving-states — key rule: "For state that is used in business logic, hold it in a ViewModel and save it using SavedStateHandle. For state that is used in UI logic, use rememberSerializable or rememberSaveable." A `rememberSaveable` copy of ViewModel-owned state is neither; it is two owners by the docs' own split.
- https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate — "UI state is usually stored or referenced in ViewModel objects, so using rememberSaveable in Compose requires some boilerplate that the saved state module can handle for you." The docs steer ViewModel-owned state to the handle, not to a composable mirror.
- Failure story F-08 (mirror stays empty forever because `TitleChanged` updates state, never the mirror) is consistent with the docs' ownership split.

**Evidence AGAINST:** None found. The only adjacent risk is over-reading the ban: official docs still bless `rememberSaveable`/`rememberSerializable` for genuinely UI-owned state — which the brief already carves out (§3.7/§8.1: sheet expansion toggle, once-per-visit focus guard). No conflict as long as the carve-out stays.

**Samples practice:** android/skills navigation-3 `basicsaveable.md` recipe (https://github.com/android/skills/blob/main/navigation/navigation-3/references/android/guide/navigation/navigation-3/recipes/basicsaveable.md) persists the *back stack* via `rememberNavBackStack` over `@Serializable NavKey`s — never a `rememberSaveable` mirror of screen state. Matches the brief.

**Ladder input:** Rung 1 holds — one owner per value with the docs' own ViewModel-vs-UI split. Nothing simpler exists; the rule IS the simplest form. Keep verbatim.

**Scalability note:** Zero ceremony cost; the ban removes code (no sync effects). Holds at any module count. Guard-worthy: a `rememberSaveable` + `LaunchedEffect`-sync pattern is statically detectable.

---

## (c) Detail destinations fetch by identity from the nav key on a cold cache

**Verdict: KEEP — directly supported by official restore guidance and the Nav3 key-as-reference model.**

**Evidence FOR:**

- https://developer.android.com/topic/libraries/architecture/saving-states — "use saved state to store a minimal amount of data necessary, such as an ID, to recreate the data necessary to restore the UI" and "Most apps should implement this to handle system-initiated process death." Identity-on-key + repository refetch is the documented pattern, not a house invention.
- https://developer.android.com/guide/navigation/navigation-3/basics — Nav3 keys are *references to content*, and "as long as the keys are serializable, the back stack can be saved … allowing it to survive configuration changes and process death." A key that resolves only against a warm in-memory list breaks the contract the key model promises.
- https://developer.android.com/guide/navigation/navigation-3/save-state — `rememberNavBackStack` restores the key (`ScreenB(val id: String)` in the doc's own example); content re-resolution is the app's job — i.e. `getNote(id)` on a cold cache.
- Failure story F-06 (cold cache returns null → permanent error) is the exact failure the docs' minimal-ID guidance prevents.

**Evidence AGAINST:** None on the rule itself. One bound from the same docs: when refetch needs the network and the device is offline at restore, identity alone is insufficient — "Use local persistence to handle process death for complex or large data." The kit's Room-cache expectation covers this, but the skill must say so (cold cache means repository cache, which may itself need disk backing).

**Samples practice:** Nav3 recipes model details as id-carrying keys (`RouteB(val id: String)`, `ProductDetail(val id: String)`) resolved at the entry site — verified in `basicsaveable.md` (URL above) and the save-state guide snippets. kotlinconf-app / KMP-App-Template detail-refetch behavior NOT verified per-file this phase.

**Ladder input:** Rung 1 (platform key model) plus existing kit rule (repository owns the source of truth) already covers it — no new mechanism needed. `suspend fun getNote(id)` is the simplest signature that survives restore. Keep.

**Scalability note:** Identity-based fetch is what makes detail destinations independent of list destinations — required for deep links and multi-pane reuse at scale. Cache-only resolution couples every detail to its list's lifetime; that coupling cost grows with feature count.

---

## (d) Nav3 back-stack persistence via rememberNavBackStack + SerializersModule with polymorphic NavKey subclasses on non-JVM targets

**Verdict: KEEP — verified verbatim in JetBrains and AndroidX docs; the per-feature sealed hierarchy + aggregated module is the documented multi-module pattern.**

**Evidence FOR (one line each):**

- https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-3.html — two `rememberNavBackStack` overloads; reflection-based serialization is Android-only; non-JVM targets MUST use the `SavedStateConfiguration` + `SerializersModule` overload with open-polymorphism registration. Multi-module pattern: one sealed NavKey hierarchy per module, aggregated via `subclassesOfSealed<…>()` in the app module.
- https://developer.android.com/reference/kotlin/androidx/navigation3/runtime/rememberNavBackStack.composable — Android overload "uses reflection internally and does not require subtypes to be registered, but it is not available on other platforms"; config overload "must" register all NavKey subtypes.
- https://developer.android.com/reference/kotlin/androidx/navigation3/runtime/NavBackStack — "prefer using rememberNavBackStack, which provides a stack that is automatically saved and restored across process death"; sealed hierarchies may use `rememberSerializable` directly, open polymorphism needs explicit `polymorphic(NavKey::class)` registration.
- https://developer.android.com/guide/navigation/navigation-3/save-state — `rememberNavBackStack` "persists across configuration changes and process death"; keys must implement `NavKey` + `@Serializable`; sealed-subtype custom-remember sample included.
- EXTERNAL_LEDGER AND-01 (rememberNavBackStack over serializable keys; never rememberSaveable/plain list), CMP-26 (config overload off-JVM), CMP-30 (per-entry scoping needs both entry decorators) all confirmed against the live docs above.

**Evidence AGAINST / bounds:**

- Android-only projects pay unneeded ceremony: the reflection overload needs no module. The kit mandates the explicit module because the kit is CMP (iOS/desktop/web targets exist), and STANDARDS §1.5 demands one canonical way — but the skill should name the Android-only escape hatch as out-of-kit scope, not pretend reflection doesn't exist.
- Version-sensitive: `subclassesOfSealed` is `@ExperimentalSerializationApi` (kotlinx-serialization ≥ 1.10.0) per the brief — re-verify the floor in `libs.versions.toml` plus release notes at skill-writing time; never pin it in prose (STANDARDS §3.2).

**Samples practice:** android/skills navigation-3 `basicsaveable.md` (URL above): `rememberNavBackStack(RouteA)` over `@Serializable … : NavKey` keys — the Android side of the contract. JetBrains doc links the CMP recipe port (terrakok/nav3-recipes) using `SavedStateConfiguration` — matches the brief's aggregation shape (`include(<name>NavSerializers)` is the kit's packaging of the same pattern).

**Ladder input:** The platform gives no simpler rung for CMP — reflection is unavailable off-JVM, so the explicit module IS rung 1 for this kit's target set. Keep; do not simplify to the Android overload.

**Scalability note:** Per-feature sealed hierarchies + app-level aggregation scale linearly (one `include` per feature); the failure mode it prevents (unregistered subtype crashing on restore when its destination is on the stack) is enforced by `check-nav-keys.sh` (brief §11.2). Keep the guard alongside the rule.

---

## Facts NOT verified (open questions for the moderator)

1. Whether Now in Android ViewModels use SavedStateHandle for input/filter state, and whether kotlinconf-app / KMP-App-Template preserve typed input across process death — no per-file sample fetch was in scope for this audit.
2. Whether android/skills `passingarguments.md` (ledger AND-03) scopes per-entry ViewModels exactly via the decorator pair — cited from the harvest ledger; the decorator pair itself was verified in the JetBrains ViewModel doc, but the recipe file was not re-fetched.
3. `subclassesOfSealed` experimental status / version floor — carried from the brief; needs a `libs.versions.toml` + release-notes check at skill-writing time.
4. No HaatPartner source was read in this phase (forbidden); all house citations above are brief-quoted, not independently re-verified.
